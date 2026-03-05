public with sharing class OrderStageRuleEngine {

    public static String resolve(Integer mask) {

        Integer drafting  = StageBitRegistry.getBit('Drafting');
        Integer hold      = StageBitRegistry.getBit('Hold');
        Integer placed    = StageBitRegistry.getBit('Placed');
        Integer closed    = StageBitRegistry.getBit('Closed');
        Integer cancelled = StageBitRegistry.getBit('Cancelled');

        Boolean hasDrafting  = (mask & drafting)  != 0;
        Boolean hasHold      = (mask & hold)      != 0;
        Boolean hasPlaced    = (mask & placed)    != 0;
        Boolean hasClosed    = (mask & closed)    != 0;
        Boolean hasCancelled = (mask & cancelled) != 0;

        // 1. всі Cancelled
        if (mask == cancelled) {
            return 'Freezed';
        }

        // 2. Cancelled + Closed/Placed
        if (hasCancelled && (hasClosed || hasPlaced)) {
            return 'Refused';
        }

        // 3. Cancelled + Drafting/Hold
        if (hasCancelled && !hasClosed && !hasPlaced) {
            return 'Draft';
        }

        // 4. Closed
        if (hasClosed) {
            return 'Closed';
        }

        // 5. Placed
        if (hasPlaced) {
            return 'Active';
        }

        // 6. Hold
        if (hasHold) {
            return 'Progress';
        }

        return 'Draft';
    }
}