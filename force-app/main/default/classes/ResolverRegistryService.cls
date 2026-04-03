public with sharing class ResolverRegistryService {

    private static Map<String, ResolverRegistry__mdt> cache;

    public static IResolver get(String resolverKey, String domain, String orderType) {
        ensureLoaded();

        String key = resolverKey + '|' + domain + '|' + orderType;

        ResolverRegistry__mdt rec = cache.get(key);

        if (rec == null || !rec.IsActive__c) {
            throw new ResolverException('Resolver not found: ' + key);
        }

        return instantiate(rec.ApexClass__c);
    }

    private static void ensureLoaded() {
        if (cache != null) return;

        cache = new Map<String, ResolverRegistry__mdt>();

        for (ResolverRegistry__mdt rec : [
            SELECT ResolverKey__c, ApexClass__c, Domain__c, OrderType__c, IsActive__c
            FROM ResolverRegistry__mdt
        ]) {
            String key = rec.ResolverKey__c + '|' + rec.Domain__c + '|' + rec.OrderType__c;
            cache.put(key, rec);
        }
    }

    private static IResolver instantiate(String className) {
        System.debug('INSTANTIATE: ' + className);

        Type t = Type.forName(className);

        System.debug('TYPE: ' + t);

        return (IResolver)t.newInstance();
    }

    public class ResolverException extends Exception {}
}