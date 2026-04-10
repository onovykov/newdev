public with sharing class PipeScheduleResolver extends BaseResolver {

    protected override ResolverResult doResolve(ResolverRequest request) {

        String dimp = MapUtils.getIgnoreCase(request.normalizedInputs, 'DIMP');
        String wlmp = MapUtils.getIgnoreCase(request.normalizedInputs, 'WLMP');

        if (String.isBlank(dimp) || String.isBlank(wlmp)) {
            return ResolverResult.empty('DIMP or WLMP missing');
        }

        Boolean isCarbonSteel = MapUtils.getBoolean(
            request.attributes,
            'isCarbonSteel'
        );

        String material = isCarbonSteel ? 'CS' : 'SS';

        String compositeKey = dimp + '|' + wlmp + '|' + material;

        PipeScheduleMap__mdt rec =
            PipeScheduleMapRepository.getByComposite(compositeKey);

        if (rec == null) {
            return ResolverResult.empty('No match for key=' + compositeKey);
        }

        return ResolverResult.success(rec.SCH__c, (Integer)rec.Priority__c);
    }
}