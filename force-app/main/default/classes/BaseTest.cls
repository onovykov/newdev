/**
 * This class should be extended by all test classes. It contains utilities and
 * methods for use in unit tests
 */
public virtual class BaseTest {
    //--------------------------------------------------------------------------
    // Constants
    public Decimal BULK_TEST_SIZE = 200;
    private static final String SYS_ADMIN_ROLE = 'System_Administrator';

    //--------------------------------------------------------------------------
    // Properties

    /** Initialize this to your new test class, then use it to access properties & methods */
    public static BaseTest t;

    /** all test code should execute under a user we can control so as to avoid
     * surprises when deploying to different environments.
     */
    public UserRole adminRole {
        get {
            if (null == adminRole) {
                UserRole[] roles = [SELECT Id FROM UserRole WHERE DeveloperName = :SYS_ADMIN_ROLE];
                if (roles.isEmpty()) {
                    roles.add(new UserRole(DeveloperName = SYS_ADMIN_ROLE, Name = 'r0'));
                    insert roles;
                }
                adminRole = roles[0];
            }
            return adminRole;
        }
        private set;
    }

    /** a default user to use in System.runAs() */
    public User adminUser {
        get {
            if (null == adminUser) {
                adminUser = newUser('admin@sf.com');
                adminUser.UserRoleId = adminRole.Id;
                insert adminUser;
            }
            return adminUser;
        }
        private set;
    }

    //--------------------------------------------------------------------------
    // Methods

    /** use this instead of Test.startTest() to provide extra functionality */
    public void start() {
        Test.startTest();
    }

    /** use this instead of Test.stopTest() to provide extra functionality */
    public void stop() {
        Test.stopTest();
    }

    //--------------------------------------------------------------------------
    // Methods for creating SObjects
    public Account[] newAccounts(String name) {
        return this.newSObjects(Account.SObjectType, name, null);
    }

    /* public Account__c[] newCustomAccounts(String name) {
        return this.newSObjects(Account__c.SObjectType, name, null);
    } */

    public Contact[] newContacts(String firstName, String lastName) {
        Contact[] result = this.newSObjects(Contact.sObjectType, null, null);
        for (Integer i = 0; i < result.size(); ++i) {
            result[i].FirstName = firstName + i;
            result[i].LastName = lastName + i;
        }
    
        return result;
    }

    public Opportunity[] newOpportunities(String name, Id accountId, String stage, Date closeDate) {
        Opportunity[] result = this.newSObjects(Opportunity.sObjectType, name, null);
        for (Opportunity o : result) {
            o.AccountId = accountId;
            o.StageName = stage;
            o.CloseDate = closeDate;
        }
    
        return result;
    }
 
    public Product2[] newProducts(String name, String code) {
        Product2[] result = this.newSObjects(Product2.sObjectType, null, null);
        for (Integer i = 0; i<result.size();++ i) {
            result[i].Name  = name + i;
            result[i].ProductCode = code + i;
            result[i].IsActive = true;
        }
    
        return result;
    }

    public OpportunityLineItem[] newOpportunityProducts(Id pricebookEntryId, Id opportunityId) {
        OpportunityLineItem[] result = this.newSObjects(OpportunityLineItem.sObjectType, null, null);
        for (OpportunityLineItem oppProd : result) {
            oppProd.PricebookEntryId  = pricebookEntryId;
            oppProd.OpportunityId = opportunityId;
        }
    
        return result;
    }


    public Task[] newTasks() {
        Task[] result = this.newSObjects(Task.sObjectType, null, null);
        return result;
    }

    public Event[] newEvents() {
        Event[] result = this.newSObjects(Event.sObjectType, null, null);
        return result;
    }

    public List<Lead> createLeads() {
        List<Lead> result = (List<Lead>) this.newSObjects(Lead.sObjectType, null, null);
        for (Integer i = 0; i<result.size();++ i) {
            result[i].LastName = 'Lead' + i;
            result[i].Company = 'Company ' + i;
            result[i].Status = 'New';
        }
        return result;
    }

    public Ignored_Emails__c newIgroredEmails(String emailAdress) {
        Ignored_Emails__c result = new Ignored_Emails__c();
        result.Email_address__c = emailAdress;
        
        return result;
    }

    public List<ContentDocumentLink> createContentDocumentLinks(Id entityId, List<ContentDocument> contentDocuments) {
        List<ContentDocumentLink> result = this.newSObjects(ContentDocumentLink.SObjectType, null, null);
        for (Integer i = 0; i<result.size();++ i) {
            result[i].ContentDocumentId = contentDocuments[i].Id;
            result[i].ShareType = 'V';
            result[i].Visibility = 'AllUsers';
            result[i].LinkedEntityId = entityId;
        }
        return result;
    }

    public virtual List<ContentVersion> createContentVersion(String title, String pathOnClient, String versionOfData, Id idParent) {
        List<ContentVersion> result = this.newSObjects(ContentVersion.SObjectType, null, null);
        for (Integer i = 0; i<result.size();++ i) {
            result[i].Title = title + i;
            result[i].PathOnClient = pathOnClient + i;
            result[i].VersionData = Blob.valueOf(versionOfData + i);
            result[i].IsMajorVersion = true;
        }
        return result;
    }

    public List<EmailMessage> newEmailMessages(){
      List<EmailMessage> result = (List<EmailMessage>) this.newSObjects(EmailMessage.SObjectType, null, null);
      return result;
    }
    public List<Attachment> newAttachments(String parentId){
      List<Attachment> result = (List<Attachment>) this.newSObjects(Attachment.SObjectType, 'TestAttach',null);
      for (integer i = 0; i < result.size(); i++){
        result[i].Name += i;
        result[i].ParentId = parentId;
        result[i].Body = Blob.valueOf(result[i].Name);
      }
      return result;
    }
    /* public virtual List<X1C_Account__c> newAccounts1C(String name) {
        List<X1C_Account__c> result = this.newSObjects(X1C_Account__c.SObjectType, null, null);
        for (Integer i = 0; i < result.size(); i++) {
            result[i].GUID__c = 'TEST-GUID-' + i;
            result[i].ID__c = '' + i;
            result[i].Name__c = name + i;

        }
        return result;
    } */

    /* public virtual List<X1C_Invoice__c> newInvoices1C(String accGuid) {
      List<X1C_Invoice__c> result = this.newSObjects(X1C_Invoice__c.SObjectType, null, null);
      for (Integer i = 0; i < result.size(); i++) {
        result[i].AccountGUID__c = accGuid;
        result[i].InvoiceGUID__c = 'TEST-GUID-' + i;
        result[i].Date__c = '2016-11-21T10:22:53.256Z';
        result[i].DateFrom__c = '2016-11-21T10:22:53.256Z';
        result[i].DateTo__c = '2016-11-21T10:22:53.256Z';
        result[i].Number__c = 'NUM-' + i;
        result[i].Sum__c = '100.2';
        result[i].SumPayment__c = '0';
      }
      return result;
    } */

    public virtual User newUser(String username) {
        final Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        return createUser(username, profileId);
    }

    /* public virtual List<Videe_TV_Outstream_User__c> newOutstreamUsers(){
        List<Videe_TV_Outstream_User__c> result;
        result = this.newSObjects(Videe_TV_Outstream_User__c.SObjectType, null, null);
        for (Integer i = 0; i < result.size(); i++) {
            result[i].id__c = String.valueOf(i) + System.currentTimeMillis();
            result[i].first_name__c = 'testFirst' + i;
            result[i].last_name__c = 'testLast' + i;
            result[i].email__c = 'test@test.' + i;
            result[i].company__c = 'companyName';
            result[i].Sync_Status__c = 'New';
        }
        return result;
    } */

    /* public virtual List<Videe_TV_Outstream__c> newOutstreams(String outstreamType, String creatorUserId) {
        List<Videe_TV_Outstream__c> result;
        result = this.newSObjects(Videe_TV_Outstream__c.SObjectType, null, null);
        for (Integer i = 0 ; i < result.size(); i++) {
            result[i].id__c = String.valueOf(i) + System.currentTimeMillis();
            result[i].type__c = outstreamType;
            result[i].creator_user_id__c = creatorUserId;
        }
        return result;
    } */

    /* public virtual List<VideeTV_Statistic__c> newStatistic(String creatorUserId) {
        List<VideeTV_Statistic__c> result = this.newSObjects(VideeTV_Statistic__c.SObjectType, null, null);
        for (Integer i = 0; i < result.size(); i++) {
            result[i].ad_opportunities__c = i;
            result[i].ad_requests__c = i;
            result[i].country__c = 'FR';
            result[i].country_name__c = 'France';
            result[i].date__c = Date.today();
            result[i].id__c = creatorUserId;
            result[i].idcountry__c = String.valueOf(i);
            result[i].impressions__c = i;
            result[i].unique_id__c = String.valueOf(i) + System.currentTimeMillis();
        }
        return result;
    } */
    //--------------------------------------------------------------------------
    // Helpers
    private SObject[] newSObjects(SObjectType type, String name, Id recordTypeId) {
        SObject[] result = new SObject[] { };
        for (Integer i = 0; i<BULK_TEST_SIZE;++ i) {
            // create a record with default field values
            SObject o = type.newSObject(null, true);
            if (null != name) {
                o.put('Name', name + i);
            }

            if (null != recordTypeId) {
                o.put('RecordTypeId', recordTypeId);
            }

            result.add(o);
        }

        return result;
    }

    private User createUser(String username, Id profileId) {
        string randomVal = String.valueOf(System.currentTimeMillis());
		
        
        return new User(
            ProfileId = [SELECT Id FROM Profile WHERE Id = :profileId LIMIT 1].Id,
            LastName = 'last',
            Email = 'user@sf.com' + System.currentTimeMillis(),
            Username = username + System.currentTimeMillis(),
            CompanyName = 'Vertamedia',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            BusinesDivision__c = 'Pipes',
            SalesDivision__c= '00004',
            EmployeeNumber = randomVal,
            ID_ERP__c= randomVal
            
            
        );
    }
}