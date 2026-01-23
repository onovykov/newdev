public with sharing class AsyncConfigProvider {

    /**
     * Alias for default config
     */
    public static AsyncConfig get() {
        return getDefault();
    }

    /**
     * Default config (IsDefault__c = true)
     */
    public static AsyncConfig getDefault() {
        List<Async_Config__mdt> cfgs = [
            SELECT SyncLimit__c, QueueLimit__c, BatchSize__c
            FROM Async_Config__mdt
            WHERE IsDefault__c = true
            LIMIT 1
        ];

        if (cfgs.isEmpty()) {
            throw new AsyncConfigException(
                'No default Async_Config__mdt found (IsDefault__c = true)'
            );
        }

        return toConfig(cfgs[0]);
    }

    /**
     * Config by DeveloperName
     */
    public static AsyncConfig getByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return getDefault();
        }

        Async_Config__mdt cfg =
            Async_Config__mdt.getInstance(developerName);

        if (cfg == null) {
            throw new AsyncConfigException(
                'Async_Config__mdt not found: ' + developerName
            );
        }

        return toConfig(cfg);
    }

    /**
     * CMDT → DTO
     */
    private static AsyncConfig toConfig(Async_Config__mdt cfg) {
        AsyncConfig c = new AsyncConfig();

        c.syncLimit  = (Integer) cfg.SyncLimit__c;
        c.queueLimit = (Integer) cfg.QueueLimit__c;
        c.batchSize  = (Integer) cfg.BatchSize__c;

        validate(c);
        return c;
    }

    /**
     * Safety validation
     */
    private static void validate(AsyncConfig c) {
        if (c.syncLimit <= 0 || c.queueLimit <= 0 || c.batchSize <= 0) {
            throw new AsyncConfigException(
                'AsyncConfig values must be > 0'
            );
        }

        if (c.syncLimit >= c.queueLimit) {
            throw new AsyncConfigException(
                'syncLimit must be < queueLimit'
            );
        }
    }
}