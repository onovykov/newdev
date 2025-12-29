global class SteelGradeAnalyzerBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private SteelGradeAnalysisResult res = new SteelGradeAnalysisResult();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name FROM SteelGrade__c'
        );
    }

    global void execute(Database.BatchableContext bc, List<SteelGrade__c> scope) {

        for (SteelGrade__c sg : scope) {
            res.total++;

            SteelGradeNormalizer.Result r =
                SteelGradeNormalizer.normalize(sg.Name);

            if (r.isGarbage) {
                res.garbage++;
                continue;
            }

            Integer gCount = r.grades.size();
            Integer aCount = r.attributes.size();

            if (gCount == 1 && aCount == 0) res.pure++;
            else if (gCount == 1 && aCount > 0) res.composite++;
            else if (gCount > 1) res.multi++;

            // частоти базових марок
            for (String g : r.grades) {
                res.inc(res.gradeFreq, g);
            }

            // частоти атрибутів
            for (String a : r.attributes) {
                res.inc(res.attrFreq, a);
            }

            // комбінації (grade + attr)
            if (gCount == 1 && aCount > 0) {
                String g = r.grades.iterator().next();
                for (String a : r.attributes) {
                    res.inc(res.comboFreq, g + '|' + a);
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

        System.debug('====== SteelGrade Analyzer v3 ======');
        System.debug('Total: ' + res.total);
        System.debug('PURE: ' + res.pure);
        System.debug('COMPOSITE: ' + res.composite);
        System.debug('MULTI: ' + res.multi);
        System.debug('GARBAGE: ' + res.garbage);

        System.debug('--- Base grades frequency ---');
        for (String k : res.gradeFreq.keySet()) {
            System.debug(k + ' => ' + res.gradeFreq.get(k));
        }

        System.debug('--- Attributes frequency ---');
        for (String k : res.attrFreq.keySet()) {
            System.debug(k + ' => ' + res.attrFreq.get(k));
        }

        System.debug('--- Grade+Attribute combos ---');
        for (String k : res.comboFreq.keySet()) {
            System.debug(k + ' => ' + res.comboFreq.get(k));
        }
    }
}