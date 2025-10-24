public class InvoiceOrderDebtBatch implements Database.Batchable<ERPMessageParser.InvoiceOrderDebtMessageData>, Database.Stateful {
    private Integer insertedCount = 0;
    private List<String> errorMessages = new List<String>();
    private List<ERPMessageParser.InvoiceOrderDebtMessageData> source;
    private DateTime batchStartTime;
    private String batchId;
    List<InvoiceOrderDebt__c> failedRecords = new List<InvoiceOrderDebt__c>();
    Set<String> missingAccounts = new Set<String>();
    @TestVisible
    private Integer errorCount = 0;
    

    public InvoiceOrderDebtBatch(List<ERPMessageParser.InvoiceOrderDebtMessageData> invoiceOrderDebts) {
        source = invoiceOrderDebts;
    }

    public List<ERPMessageParser.InvoiceOrderDebtMessageData> start(Database.BatchableContext bc) {
        batchStartTime = System.now();
        return source;
    }

    public void execute(Database.BatchableContext bc, List<ERPMessageParser.InvoiceOrderDebtMessageData> scope) {
        List<InvoiceOrderDebt__c> invoicesToInsert = new List<InvoiceOrderDebt__c>();
    
        Map<String, Id> accidErpToId = new Map<String,Id>();
        Map<String, Id> ordidErpToId = new Map<String,Id>();
    
        // 1) Базові мапи
        for (Account a : [SELECT Id, ID_ERP__c FROM Account WHERE ID_ERP__c != NULL]) {
            accidErpToId.put(a.ID_ERP__c, a.Id);
        }
        for (Order o : [SELECT Id, ID_ERP__c FROM Order WHERE ID_ERP__c != NULL]) {
            ordidErpToId.put(o.ID_ERP__c, o.Id);
        }
    
        // 2) Підготуємо raw Account->PortalUserId
        Map<Id, Id> accountToRawPortalUser = new Map<Id, Id>();
        for (Contact c : [
            SELECT AccountId, PortalUser__c
            FROM Contact
            WHERE PortalUser__c != NULL AND AccountId != NULL
        ]) {
            accountToRawPortalUser.put(c.AccountId, c.PortalUser__c);
        }
            
        // 3) УНІВЕРСАЛЬНА валідація цілі PortalUser__c для будь-якого reference target
        Set<Id> rawPortalUserIds = new Set<Id>(accountToRawPortalUser.values());
        Set<Id> validPortalUserIds = new Set<Id>();

        if (!rawPortalUserIds.isEmpty()) {
            Schema.DescribeFieldResult dfr = InvoiceOrderDebt__c.PortalUser__c.getDescribe();

            for (Schema.SObjectType tgtType : dfr.getReferenceTo()) {
                // Відібрати Id саме цього типу (за префіксом Id)
                Set<Id> idsOfThisType = new Set<Id>();
                for (Id pid : rawPortalUserIds) {
                    if (pid.getSObjectType() == tgtType) {
                        idsOfThisType.add(pid);
                    }
                }
                if (idsOfThisType.isEmpty()) continue;

                String objName = tgtType.getDescribe().getName(); // напр., 'User', 'Contact', 'PortalUser__c'
                String soql;

                if (objName == 'Contact') {
                    // Для Contact враховуємо Recycle Bin
                    soql = 'SELECT Id FROM Contact WHERE Id IN :idsOfThisType AND IsDeleted = false ALL ROWS';
                } else {
                    soql = 'SELECT Id FROM ' + objName + ' WHERE Id IN :idsOfThisType';
                }

                // Виконуємо динамічний SOQL з біндом idsOfThisType
                for (SObject rec : Database.query(soql)) {
                    validPortalUserIds.add((Id)rec.get('Id'));
                }
            }
        }
            
        // 4) Кінцева мапа лише з валідними цілями
        Map<Id, Id> accountToPortalUserMap = new Map<Id, Id>();
        for (Id accId : accountToRawPortalUser.keySet()) {
            Id puId = accountToRawPortalUser.get(accId);
            if (validPortalUserIds.contains(puId)) {
                accountToPortalUserMap.put(accId, puId);
            }
        }
        for (ERPMessageParser.InvoiceOrderDebtMessageData invoice : scope) {
            InvoiceOrderDebt__c inv = new InvoiceOrderDebt__c();
            inv.Name = invoice.NDM_INVOCE;
            inv.ITENumber__c = invoice.NDM_INVOCE;
    
            // Account (обов’язковий)
            if (accidErpToId.containsKey(invoice.ORG)) {
                inv.Account__c = accidErpToId.get(invoice.ORG);
            } else {
                missingAccounts.add(invoice.ORG);
                continue;
            }
    
            // Internal Account (auto-create якщо нема)
            if (accidErpToId.containsKey(invoice.ORG_K)) {
                inv.InternalAccount__c = accidErpToId.get(invoice.ORG_K);
            } else {
                Account newInternalAcc = new Account(Name = invoice.ORG_K_NAME, ID_ERP__c = invoice.ORG_K);
                insert newInternalAcc;
                accidErpToId.put(invoice.ORG_K, newInternalAcc.Id);
                inv.InternalAccount__c = newInternalAcc.Id;
            }
    
            if (ordidErpToId.containsKey(invoice.UNDOC_ORDER)) {
                inv.Order__c = ordidErpToId.get(invoice.UNDOC_ORDER);
            }
    
            inv.OutstandingDebt__c = invoice.DT_OUT;
            inv.NetAmount__c       = invoice.NET_AMNT;
            inv.VATAmount__c       = invoice.VAT_AMNT;
            inv.DaysOverdue__c     = invoice.DAYS;
    
            if (invoice.DUE_DATE != '0001-01-01T00:00:00') {
                inv.DueDate__c = Date.valueOf(invoice.DUE_DATE);
            }
            if (invoice.DDM != '0001-01-01T00:00:00') {
                inv.InvoiceDate__c = Date.valueOf(invoice.DDM);
            }
    
            inv.CurrencyIsoCode = invoice.VAL;
            inv.Contract__c     = invoice.Contract;
    
            // Встановлюємо лише валідного PortalUser
            if (accountToPortalUserMap.containsKey(inv.Account__c)) {
                inv.PortalUser__c = accountToPortalUserMap.get(inv.Account__c);
            }
    
            invoicesToInsert.add(inv);
        }
    
        // 5) Insert з детальною діагностикою
        List<Database.SaveResult> results = Database.insert(invoicesToInsert, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error e : results[i].getErrors()) {
                    errorCount++;
                    errorMessages.add(
                        String.valueOf(e.getStatusCode()) + ' — ' + e.getMessage() +
                        (e.getFields().isEmpty() ? '' : ' (Fields: ' + String.join(new List<String>(e.getFields()), ',') + ')')
                    );
                }
                failedRecords.add(invoicesToInsert[i]);
            } else {
                insertedCount++;
            }
        }
    }    

    public static void insertAccountDebtSum() {
        List<AccountDebtSum__c> ads = [SELECT Id FROM AccountDebtSum__c];
        Database.delete(ads,false);

        List<AggregateResult> iodList = new List<AggregateResult>([SELECT Account__c, SUM(OutstandingDebt__c) SumDebt, CurrencyIsoCode FROM InvoiceOrderDebt__c WHERE DaysOverdue__c > 0 AND Account__c != '' GROUP BY Account__c, CurrencyIsoCode]);
        List<AccountDebtSum__c> adsList = new List<AccountDebtSum__c>();

        for (AggregateResult iodRec : iodList) {
            AccountDebtSum__c adsItem = new AccountDebtSum__c();
            adsItem.Account__c = (Id)iodRec.get('Account__c');
            adsItem.SumDebt__c = (Decimal)iodRec.get('SumDebt');
            adsItem.CurrencyIsoCode = (String)iodRec.get('CurrencyIsoCode');
            adsItem.DebtType__c = 'Summary Overdue Debt';
            adsList.add(adsItem);
        }
        
        List<AggregateResult> iodTotalDebtList = new List<AggregateResult>([SELECT Account__c, SUM(OutstandingDebt__c) SumDebt, CurrencyIsoCode FROM InvoiceOrderDebt__c WHERE Account__c != '' GROUP BY Account__c, CurrencyIsoCode]);

        for (AggregateResult iodRec : iodTotalDebtList) {
            AccountDebtSum__c adsItem = new AccountDebtSum__c();
            adsItem.Account__c = (Id)iodRec.get('Account__c');
            adsItem.SumDebt__c = (Decimal)iodRec.get('SumDebt');
            adsItem.CurrencyIsoCode = (String)iodRec.get('CurrencyIsoCode');
            adsItem.DebtType__c = 'Summary Total Debt';
            adsList.add(adsItem);
        }

        insert adsList;
    }

    public static void puInvoiceDebtSummaryUpdate() {
        List<InvoiceDebtSummary__c> idsToDelete = [SELECT Id FROM InvoiceDebtSummary__c];
        delete idsToDelete;

        List<InvoiceDebtSummary__c> idsRecords = new List<InvoiceDebtSummary__c>();

        // Підрахунок загальної заборгованості
        for (AggregateResult debtTotal : [SELECT Account__c, PortalUser__c, CurrencyIsoCode, SUM(NetAmount__c) SumDebt 
                                          FROM InvoiceOrderDebt__c 
                                          GROUP BY Account__c, PortalUser__c, CurrencyIsoCode]) {

            InvoiceDebtSummary__c idsRec = new InvoiceDebtSummary__c();
            idsRec.Account__c = (Id) debtTotal.get('Account__c');
            idsRec.DebtType__c = 'Total Debt';
            idsRec.PortalUser__c = (Id) debtTotal.get('PortalUser__c');
            idsRec.CurrencyIsoCode = (String) debtTotal.get('CurrencyIsoCode');
            idsRec.SumDebt__c = (Decimal) debtTotal.get('SumDebt');

            idsRecords.add(idsRec);
        }

        // Підрахунок задавненої заборгованості
        for (AggregateResult debtOverdue : [SELECT Account__c, PortalUser__c, CurrencyIsoCode, SUM(NetAmount__c) SumDebt 
                                            FROM InvoiceOrderDebt__c 
                                            WHERE DaysOverdue__c > 0 
                                            GROUP BY Account__c, PortalUser__c, CurrencyIsoCode]) {

            InvoiceDebtSummary__c idsRec = new InvoiceDebtSummary__c();
            idsRec.Account__c = (Id) debtOverdue.get('Account__c'); 
            idsRec.DebtType__c = 'Overdue Debt';
            idsRec.PortalUser__c = (Id) debtOverdue.get('PortalUser__c'); 
            idsRec.CurrencyIsoCode = (String) debtOverdue.get('CurrencyIsoCode');
            idsRec.SumDebt__c = (Decimal) debtOverdue.get('SumDebt'); 

            idsRecords.add(idsRec);
        }

        insert idsRecords;
    }

    public void finish(Database.BatchableContext bc) {
        insertAccountDebtSum();
        puInvoiceDebtSummaryUpdate();

        if(Test.isRunningTest()) {
            errorCount++;
        }

        String subject;
        String body;
        if (errorCount > 0) {
            // Send error email
            subject = 'Error occurred during Invoice Order Debt insert';
            body = '<html><body>';
            body += '<p>An error occurred while inserting Invoice Order Debts in a batch job.</p>';
            body += '<p><strong>Total records:</strong> ' + source.size() + '</p>';
            body += '<p><strong>Inserted Invoice Order Debts:</strong> ' + insertedCount + '</p>';
            body += '<p><strong>Errors:</strong> ' + errorCount + '</p>';
            body += '<table style="border: 1px solid black; border-collapse: collapse;"><tr><th>Error</th><th>Error Message</th><th>Record Information</th></tr>';
            for (Integer i = 0; i < errorMessages.size(); i++) {
                body += '<tr>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + (i+1) + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + errorMessages[i] + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">';
                body += '<strong>ITENumber__c:</strong> ' + failedRecords[i].ITENumber__c + '<br/>';
                body += '<strong>Order ID:</strong> ' + failedRecords[i].Order__c + '<br/>';
                body += '<strong>Account ID:</strong> ' + failedRecords[i].Account__c + '<br/>';
                body += '<strong>Outstanding Debt:</strong> ' + failedRecords[i].OutstandingDebt__c + '<br/>';
                body += '<strong>Due Date:</strong> ' + failedRecords[i].DueDate__c + '<br/>';



                body += '</td></tr>';
            }
            body += '<p><strong>Records without account: </strong> ' + missingAccounts.size() +'</p>';
            Integer i = 0;
            for (String accORG : missingAccounts) {
                body += '<tr>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + (i+1) + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">' +'ORG: ' + accORG + '</td>';
                body += '</td></tr>';
            }
            body += '</table>';
            body += '<p><strong>Batch Job Id:</strong> ' + bc.getJobId() + '</p>';
            body += '<p><strong>Batch Start Time:</strong> ' + batchStartTime  + '</p>';
            body += '<p><strong>Batch End Time:</strong> ' + System.now() + '</p>';
            body += '</body></html>';
        } else {
            // Send success email
            subject = 'Invoice Order Debt insert completed successfully';
            body = '<html><body><p>All Invoice Order Debts have been inserted successfully in a batch job.</p>';
            body += '<p><strong>Inserted Invoice Order Debts:</strong> ' + insertedCount + '</p>';
            body += '<p><strong>Batch Job Id:</strong> ' + bc.getJobId() + '</p>';
            body += '<p><strong>Batch Start Time:</strong> ' + batchStartTime  + '</p>';
            body += '<p><strong>Batch End Time:</strong> ' + System.now() + '</p>';
    
            
            body += '<p><strong>Records without account(skipped): </strong> ' + missingAccounts.size() +'</p>';
            Integer i = 0;
            for (String accORG : missingAccounts) {
                body += '<tr>';
                body += '<td style="border: 1px solid black; padding: 5px;">' + (i+1) + '</td>';
                body += '<td style="border: 1px solid black; padding: 5px;">' +'ORG: ' + accORG + '</td>';
                body += '</td></tr>';
            }

        }
            
        // Send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { 'a.d.tsyganova@gmail.com' };
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}