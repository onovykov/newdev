public with sharing class CmdtDeactivateUtil {
    // Деактивація записів, яких не було в поточному прогоні
    public static void deactivateMissing(String typeApi, Set<String> seenDevNames, Boolean dryRun){
        Set<String> existing = new Set<String>();
        if (typeApi == 'Tube_OD__mdt') existing = CmdtReadUtil.existingDevNames_OD();
        else if (typeApi == 'Tube_WT__mdt') existing = CmdtReadUtil.existingDevNames_WT();
        else if (typeApi == 'SCH_OD_WT__mdt') existing = CmdtReadUtil.existingDevNames_SCH();

        existing.removeAll(seenDevNames);
        if (existing.isEmpty()) return;

        List<Metadata.CustomMetadata> updates = new List<Metadata.CustomMetadata>();
        for (String dev : existing){
            Map<String,Object> vals = new Map<String,Object>{ 'IsActive__c' => false };
            updates.add(CmdtDeployUtil.build(typeApi, dev, dev, vals));
            if (updates.size() >= CmdtDeployUtil.BATCH_SIZE) { CmdtDeployUtil.deploy(updates, /*dryRun*/true == dryRun ? true : false); updates.clear(); }
        }
        CmdtDeployUtil.deploy(updates, dryRun);
        System.debug(LoggingLevel.INFO, 'Deactivated (soft-delete) '+typeApi+': '+existing.size()+' recs');
    }

    // Повертаємо список fullName для подальшого CLI-видалення
    public static List<String> listFullNamesByPrefix(String typeApi, String prefix){
        Set<String> devs = new Set<String>();
        if (typeApi == 'Tube_OD__mdt') devs = CmdtReadUtil.existingDevNames_OD();
        else if (typeApi == 'Tube_WT__mdt') devs = CmdtReadUtil.existingDevNames_WT();
        else if (typeApi == 'SCH_OD_WT__mdt') devs = CmdtReadUtil.existingDevNames_SCH();

        List<String> full = new List<String>();
        for (String d : devs){
            if (!String.isBlank(prefix) && d.startsWith(prefix)){
                full.add(typeApi + '.' + d);
            }
        }
        System.debug(LoggingLevel.INFO, 'Matched for delete ('+typeApi+'): '+full.size());
        return full;
    }
}