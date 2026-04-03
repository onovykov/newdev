public with sharing class PipeScheduleResolverService {

    public static String resolve(String rawDimp, String material) {

        ResolverRequest req = new ResolverRequest();
        req.resolverKey = 'PIPE_SCHEDULE';
        req.domain = 'Diameter';
        req.orderType = 'Tubes';

        req.rawInputs.put('DIMP', rawDimp);

        req.attributes.put(
            'isCarbonSteel',
            MaterialClassifierService.isCarbonSteel(material)
        );

        IResolver resolver = ResolverRegistryService.get(
            req.resolverKey,
            req.domain,
            req.orderType
        );

        ResolverResult result = resolver.resolve(req);

        return result.isResolved ? result.resolvedValue : null;
    }
}