public with sharing class StageEngine {

    private static StageEngine instance;

    private Map<String,Integer> stageBits;
    private String[] maskToStage;

    private StageEngine() {

        stageBits = OrderStageMetadataCache.getStageBits();
        maskToStage = OrderStageMetadataCache.getMaskRules();

        validateRules();
    }

    public static StageEngine get() {

        if (instance == null) {
            instance = new StageEngine();
        }

        return instance;
    }

    @TestVisible
    static void reset() {

        instance = null;
        OrderStageMetadataCache.reset();
    }

    private void validateRules() {

        for (Integer mask = 0; mask < maskToStage.size(); mask++) {

            if (maskToStage[mask] == null) {

                throw new StageEngineConfigurationException(
                    'Missing OrderStageBitmaskRule for mask: ' + mask
                );
            }
        }
    }

    public Integer buildMask(List<String> stages) {
        Integer mask = 0;
        for (String s : stages) {
            Integer bit = stageBits.get(s);
            if (bit != null) {
                mask |= bit;
            }
        }
        return mask;
    }

    public String resolveOrderStage(Integer mask) {

        if (mask == null) {
            return 'Draft';
        }

        if (mask < 0 || mask >= maskToStage.size()) {
            return 'Draft';
        }

        String stage = maskToStage[mask];

        return stage != null ? stage : 'Draft';
    }
}