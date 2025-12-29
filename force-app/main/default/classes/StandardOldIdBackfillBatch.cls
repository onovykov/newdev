global class StandardOldIdBackfillBatch
    implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, NormalizedName__c, ID_ERP__c, OldId__c
            FROM Standard__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        // ---- зібрати ключі ----
        Set<String> erpIds = new Set<String>();
        Set<String> normNames = new Set<String>();

        for ((Standard__c) s : scope) {
            if (!String.isBlank(s.ID_ERP__c)) {
                erpIds.add(s.ID_ERP__c);
            }
            if (!String.isBlank(s.NormalizedName__c)) {
                normNames.add(s.NormalizedName__c);
            } else if (!String.isBlank(s.Name)) {
                normNames.add(StandardNormalizer.normalize(s.Name));
            }
        }

        // ---- завантажити legacy ----
        List<ProductStandard__c> legacyRows = [
            SELECT Id, Name, ID_ERP__c
            FROM ProductStandard__c
            WHERE Name IN :normNames AND Name != null
        ];

        // ---- індекси ----
        Map<String, List<ProductStandard__c>> legacyByErp =
            new Map<String, List<ProductStandard__c>>();
        Map<String, List<ProductStandard__c>> legacyByNormName =
            new Map<String, List<ProductStandard__c>>();

        for (ProductStandard__c ps : legacyRows) {

            if (!String.isBlank(ps.ID_ERP__c)) {
                if (!legacyByErp.containsKey(ps.ID_ERP__c)) {
                    legacyByErp.put(ps.ID_ERP__c, new List<ProductStandard__c>());
                }
                legacyByErp.get(ps.ID_ERP__c).add(ps);
            }

            if (!String.isBlank(ps.Name)) {
                String norm = StandardNormalizer.normalize(ps.Name);
                if (!String.isBlank(norm)) {
                    if (!legacyByNormName.containsKey(norm)) {
                        legacyByNormName.put(norm, new List<ProductStandard__c>());
                    }
                    legacyByNormName.get(norm).add(ps);
                }
            }
        }

        // ---- матчимо 1-в-1 ----
        List<Standard__c> toUpdate = new List<Standard__c>();

        for (Standard__c s : scope) {

            ProductStandard__c match = null;
			String norm = !String.isBlank(s.NormalizedName__c)
				? s.NormalizedName__c
				: StandardNormalizer.normalize(s.Name);

			if (!String.isBlank(norm)
				&& legacyByNormName.containsKey(norm)
				&& legacyByNormName.get(norm).size() == 1) {

				match = legacyByNormName.get(norm)[0];
			}

            if (match != null) {
                s.OldId__c = match.Id;
				s.ID_ERP__c = match.ID_ERP__c;
                toUpdate.add(s);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('StandardOldIdBackfillBatch finished');
    }
}