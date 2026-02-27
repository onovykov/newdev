public class CacheSettingsProvider {

    public class CacheSettings {
        public String  cacheName;
        public String  keyPrefix;
        public Integer shardLen;
        public Integer ttlSuccess;
        public Integer ttlNegative;

        public CacheSettings() {
            this.cacheName   = 'local.OrderItemCache';
            this.keyPrefix   = 'DEFAULT_V1';
            this.shardLen    = 20;
            this.ttlSuccess  = 600;
            this.ttlNegative = 120;
        }
    }

    public static CacheSettings load(String developerName) {
        CacheSettings cfg = new CacheSettings();

        try {
            CacheSettings__mdt mdt = CacheSettings__mdt.getInstance(developerName);
            if (mdt == null) return cfg;

            if (mdt.CacheName__c != null)   cfg.cacheName   = mdt.CacheName__c;
            if (mdt.KeyPrefix__c != null)   cfg.keyPrefix   = mdt.KeyPrefix__c;
            if (mdt.ShardLen__c != null)    cfg.shardLen    = Integer.valueOf(mdt.ShardLen__c);
            if (mdt.TtlSuccess__c != null)  cfg.ttlSuccess  = Integer.valueOf(mdt.TtlSuccess__c);
            if (mdt.TtlNegative__c != null) cfg.ttlNegative = Integer.valueOf(mdt.TtlNegative__c);

        } catch (Exception e) {
            // silent fallback — cache must NEVER break business flow
        }

        return cfg;
    }
}