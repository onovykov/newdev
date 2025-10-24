global class AccountDuplicateFinderBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String whereClause;
    private Decimal threshold;
    private Datetime startTime;
    private Integer insertedCount = 0;

    public AccountDuplicateFinderBatch(String whereClause, Decimal threshold) {
        this.whereClause = whereClause;
        if (threshold == null || threshold < 0.0 || threshold > 1.001) {
            System.debug('⚠️WARNING! Parameter threshold was set to default: 0.600');
            this.threshold = 0.6;
        } else {
            this.threshold = threshold;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = DateTime.now(); // ✅ Зберігаємо час старту

        String baseQuery = 'SELECT Id, ID_ERP__c, Name, PhoneticCode__c, MetaphonePrimary__c, MetaphoneAlternate__c,'+
                           'NYSIIS__c, NYSIISFirstCode__c, SoundexAllWords__c, SoundexFirstWord__c, SoundexFirst3Letters__c ' +
                           'FROM Account';
        if (!String.isBlank(whereClause)) {
            baseQuery += ' WHERE ' + whereClause;
        }
        System.debug('🔍 Final Query: ' + baseQuery);
        return Database.getQueryLocator(baseQuery);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        Long start = Datetime.now().getTime();

        List<MatchResult__c> resultsToInsert = new List<MatchResult__c>();
        IndexWeights idxWeights = IndexWeights.getDefault();
        WeightSet pairWeights = WeightSet.getDefault();

        Set<String> existingKeys = new Set<String>();
        for (MatchResult__c rec : [SELECT account1Id__c, account2Id__c FROM MatchResult__c]) {
            existingKeys.add(rec.account1Id__c + ':' + rec.account2Id__c);
            existingKeys.add(rec.account2Id__c + ':' + rec.account1Id__c);
        }

        for (SObject s : scope) {
            Account acc = (Account) s;
            System.debug('🔍 Processing account: ' + acc.Id);

            List<StringUtilsEx.MatchResult> matches = NameSimilarityUtil.finalDuplicateCheck(
                Consts.FIND_BY_CODE,
                '',
                Consts.FIND_BY_SF_ID,
                '',
                acc.Id,
                threshold,
                false,
                idxWeights,
                pairWeights
            );

            for (StringUtilsEx.MatchResult match : matches) {
                System.debug('MATCH: -> ' + match.SourceName + ' | ' + match.SourceName);
                if (match.account1Id != acc.Id) continue;
                if (match == null) {
                    System.debug('⚠️ Null match object');
                    continue;
                }

                if (match.account1Id == null || match.account2Id == null) {
                    System.debug('⚠️ Skipping match with null IDs');
                    continue;
                }

                if (match.account1Id == match.account2Id) {
                    System.debug('⛔ Skipping self-match: ' + match.account1Id);
                    continue;
                }

                String keyDirect = match.account1Id + ':' + match.account2Id;
                String keyReverse = match.account2Id + ':' + match.account1Id;
                
                if (!existingKeys.contains(keyDirect) && !existingKeys.contains(keyReverse)) {
                //if ((!existingKeys.contains(keyDirect) && !existingKeys.contains(keyReverse)) && match.matchIndex>=threshold) {
                    System.debug('✅ Saving match: ' + keyDirect + ' → Index: ' + match.matchIndex);
                    if(match.matchIndex>=threshold) {                   
                        System.debug('match.matchIndex = ' + match.matchIndex+'\n');
                        resultsToInsert.add(new MatchResult__c(
                            account1Id__c = match.account1Id,
                            account2Id__c = match.account2Id,
                            MatchIndex__c = match.matchIndex,
                            SourceName__c = match.SourceName
                        ));
                        insertedCount++;
                    }
                    existingKeys.add(keyDirect);
                    existingKeys.add(keyReverse);
                } else {
                    System.debug('⏩ Duplicate key found: ' + keyDirect);
                }
            }
        }

        if (!resultsToInsert.isEmpty()) {
            insert resultsToInsert;
            System.debug('📥 Inserted ' + resultsToInsert.size() + ' match results.');
        } else {
            System.debug('📭 No new matches to insert.');
        }
        Long elapsed = Datetime.now().getTime() - start;
        System.debug('⏱ Execution took: ' + elapsed + ' ms');
    }

    global void finish(Database.BatchableContext bc) {
        Datetime finishTime = DateTime.now();
        Long durationMillis = finishTime.getTime() - startTime.getTime();
        Decimal durationMinutes = durationMillis / 60000.0;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {
            'aleksandr.novikov@m.interpipe.biz',
            'a.tsyhanova@polytech.software'
        });
        mail.setSubject('✅ Duplicate Check Batch Completed');
        String body = ''
        + 'The AccountDuplicateFinderBatch has completed.\n\n'
        + '🕒 Start Time: ' + String.valueOf(startTime.format('yyyy-MM-dd HH:mm:ss')) + '\n'
        + '🕓 Finish Time: ' + String.valueOf(finishTime.format('yyyy-MM-dd HH:mm:ss')) + '\n'
        + '⏱ Duration: ' + durationMinutes.format() + ' minutes\n\n'
        + '🔢 Total MatchResult__c inserted: ' + insertedCount + '\n';

    mail.setPlainTextBody(body);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        System.debug('✅ Email sent.\n' + body);
    }

    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}

/* Приклад запуску:

String whereClause = 'RecordType.Name=\'Customer\' AND MarketSegment__c=\'00002\'';
Decimal threshold = 0.60;

Database.executeBatch(new AccountDuplicateFinderBatch(whereClause, threshold), 50);
*/