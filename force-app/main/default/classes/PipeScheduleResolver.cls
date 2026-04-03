public with sharing class PipeScheduleResolver extends BaseResolver {

    protected override ResolverResult doResolve(ResolverRequest request) {
    /*
        String dimp = request.normalizedInputs.get('DIMP');

        if (String.isBlank(dimp)) {
            return ResolverResult.empty('DIMP is empty');
        }

        Boolean isCarbonSteel = (Boolean)request.attributes.get('isCarbonSteel');
    */
        String dimp = MapUtils.getIgnoreCase(
            request.normalizedInputs,
            'DIMP'
        );

        Boolean isCarbonSteel = MapUtils.getBoolean(
            request.attributes,
            'isCarbonSteel'
        );
        
        List<PipeScheduleMap__mdt> candidates =
            PipeScheduleMapRepository.getByDimp(dimp);

        if (candidates == null || candidates.isEmpty()) {
            return ResolverResult.empty('No records for DIMP=' + dimp);
        }

        List<PipeScheduleMap__mdt> filtered = new List<PipeScheduleMap__mdt>();

        for (PipeScheduleMap__mdt rec : candidates) {
            if (rec.ForCarbonSteel__c == isCarbonSteel) {
                filtered.add(rec);
            }
        }

        if (filtered.isEmpty()) {
            return ResolverResult.empty('No records after material filter');
        }

        filtered.sort(new ComparatorImpl());

        PipeScheduleMap__mdt best = filtered[0];

        return ResolverResult.success(best.SCH__c, (Integer)best.Priority__c);
    }

    private class ComparatorImpl implements Comparator<PipeScheduleMap__mdt> {
        public Integer compare(PipeScheduleMap__mdt a, PipeScheduleMap__mdt b) {
            return (Integer)a.Priority__c - (Integer)b.Priority__c;
        }
    }
}