public with sharing class OrderStageProvider {

public static String resolveFromItemStages(List<String> stages) {
    
    if (stages == null || stages.isEmpty()) {
        return 'Draft';
    }

    StageEngine engine = StageEngine.get();

    Integer mask = engine.buildMask(stages);

    String stage = engine.resolveOrderStage(mask);

    return stage != null ? stage : 'Draft';
}
}