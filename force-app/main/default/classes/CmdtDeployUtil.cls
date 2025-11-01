/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
//===  1. База (загальні утиліти CmdtDeploy, CmdtImportLogger тощо)
//     1.1. Основна утиліта деплою CMDT CmdtDeployUtil
public with sharing class CmdtDeployUtil {
    public static final Integer BATCH_SIZE = 100;

    public class DeployCb implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult res, Metadata.DeployCallbackContext ctx) {
            if (res.status == Metadata.DeployStatus.Succeeded) {
                System.debug(LoggingLevel.INFO, 'CMDT deploy OK');
            } else {
                System.debug(LoggingLevel.ERROR, 'CMDT deploy FAILED: ' + res.errorMessage);
                System.debug(LoggingLevel.ERROR, JSON.serialize(res.details));
            }
        }
    }

    public static void deploy(List<Metadata.CustomMetadata> mdRecords, Boolean dryRun) {
        if (mdRecords == null || mdRecords.isEmpty()) return;
        if (dryRun) {
            System.debug(LoggingLevel.INFO, 'DRY-RUN: would deploy ' + mdRecords.size() + ' CMDT recs');
            System.debug(LoggingLevel.DEBUG, JSON.serialize(mdRecords));
            return;
        }
        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        for (Metadata.CustomMetadata rec : mdRecords) dc.addMetadata(rec);
        Id jobId = Metadata.Operations.enqueueDeployment(dc, new DeployCb());
        System.debug(LoggingLevel.INFO, 'CMDT deploy enqueued: ' + jobId + ' (' + mdRecords.size() + ')');
    }

    public static Metadata.CustomMetadata build(
        String typeApiName, String developerName, String label, Map<String, Object> fieldValues
    ) {
        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = typeApiName + '.' + developerName;
        cmd.label = String.isBlank(label) ? developerName : label;
        for (String f : fieldValues.keySet()) {
            Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
            v.field = f; v.value = fieldValues.get(f);
            cmd.values.add(v);
        }
        return cmd;
    }

    public static String devName(String raw) {
        String s = (raw == null ? 'N' : raw).trim().replaceAll('[^A-Za-z0-9_\\-]+', '_').toUpperCase();
        if (String.isBlank(s)) s = 'N'; if (s.length() > 255) s = s.substring(0,255);
        return s;
    }
    public static String devNameForOd(Decimal odMm){ return devName('OD_' + (odMm==null?'N':String.valueOf(odMm).replace('.','_'))); }
    public static String devNameForWt(Decimal wtMm){ return devName('WT_' + (wtMm==null?'N':String.valueOf(wtMm).replace('.','_'))); }
    public static String devNameForSch(String odDev,String wtDev,String sch){ return devName(odDev+'__'+wtDev+'__SCH_'+(String.isBlank(sch)?'N':sch)); }
}