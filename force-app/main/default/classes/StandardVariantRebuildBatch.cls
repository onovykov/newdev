global class StandardVariantRebuildBatch
implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        // Чистимо таблицю (в сенді можна так)
        List<StandardVariant__c> existing = [
            SELECT Id FROM StandardVariant__c
        ];
        if (!existing.isEmpty()) {
            delete existing;
        }

        // Повертаємо QueryLocator
        return Database.getQueryLocator([
            SELECT ID_ERP__c, FullName__c
            FROM ProductStandard__c
            WHERE FullName__c != null
              AND FullName__c != 'N/A'
              AND (NOT FullName__c LIKE '%протокол%')
              AND (NOT FullName__c LIKE '%чертеж%')
              AND (NOT FullName__c LIKE 'ТС%')
              AND (NOT FullName__c LIKE 'ТП%')
              AND (NOT FullName__c LIKE '%Трубы стальные%')
              AND (NOT FullName__c LIKE '%проект%')
              AND (NOT FullName__c LIKE '%по спецификации%')
              AND (NOT FullName__c LIKE '%П № 1-2017%')
              AND (NOT FullName__c LIKE '%Нестандартное изделие%')
              AND (NOT FullName__c LIKE '%Квота%')
              AND (NOT FullName__c LIKE '%КБ%')
            ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<StandardVariant__c> toInsert = new List<StandardVariant__c>();

        for (SObject sob : scope) {

            ProductStandard__c p = (ProductStandard__c)sob;

            if (String.isBlank(p.ID_ERP__c)) continue;

            for (String raw : p.FullName__c.split('/')) {

                String name = raw != null ? raw.trim() : null;
                if (String.isBlank(name)) continue;

                toInsert.add(new StandardVariant__c(
                    ID_ERP__c = p.ID_ERP__c,
                    Name = name
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('StandardVariant__c rebuild completed.');
    }
}

/*
Запуск з Anonymous
Database.executeBatch(new StandardVariantRebuildBatch(), 200);
*/