public abstract class BaseResolver implements IResolver {

    public ResolverResult resolve(ResolverRequest request) {

        if (request == null) {
            return ResolverResult.empty('Request is null');
        }

        normalizeInputs(request);

        return doResolve(request);
    }

    protected abstract ResolverResult doResolve(ResolverRequest request);

    private void normalizeInputs(ResolverRequest request) {
        for (String key : request.rawInputs.keySet()) {
            request.normalizedInputs.put(
                key,
                CanonicalKeyService.normalize(request.rawInputs.get(key))
            );
        }
    }
}