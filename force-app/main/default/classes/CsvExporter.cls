/**********************************************************************************
* Перенесення довідників параметрів та характеристик продукції з об'єктів до CMDT * 
***********************************************************************************/
// Утиліта експорту даних з об'єктів до CSV (CSV-backup)
public with sharing class CsvExporter {
    // Повертає CSV і, якщо save=true, створює ContentVersion
    public static String exportTubeOD(Boolean save){
        List<TubeOD__c> rows = [SELECT Id, ID_ERP__c, Name, OD_mm__c, H_mm__c, L_mm__c, NPS__c, IsRound__c FROM TubeOD__c ORDER BY Name];
        String csv = 'Id,ID_ERP__c,Name,OD_mm__c,H_mm__c,L_mm__c,NPS__c,IsRound__c\n';
        for (TubeOD__c r: rows){
            csv += String.format('{0},{1},"{2}",{3},{4},{5},{6},{7}\n',
                new List<Object>{r.Id, wrap(r.ID_ERP__c), wrap(r.Name), r.OD_mm__c, r.H_mm__c, r.L_mm__c, r.NPS__c, r.IsRound__c});
        }
        if (save) saveCsv(csv, 'TubeOD_export.csv');
        return csv;
    }
    public static String exportTubeWT(Boolean save){
        List<TubeWT__c> rows = [SELECT Id, ID_ERP__c, Name, WT_mm__c FROM TubeWT__c ORDER BY Name];
        String csv = 'Id,ID_ERP__c,Name,WT_mm__c\n';
        for (TubeWT__c r: rows){
            csv += String.format('{0},{1},"{2}",{3}\n',
                new List<Object>{r.Id, wrap(r.ID_ERP__c), wrap(r.Name), r.WT_mm__c});
        }
        if (save) saveCsv(csv, 'TubeWT_export.csv');
        return csv;
    }
    public static String exportSch(Boolean save){
        List<OD_SCH_WT__c> rows = [SELECT TubeOD__r.OD_mm__c, TubeWT__r.WT_mm__c, SCH__c FROM OD_SCH_WT__c WHERE TubeOD__c!=null AND TubeWT__c!=null ORDER BY SCH__c];
        String csv = 'OD_mm__c,WT_mm__c,SCH__c\n';
        for (OD_SCH_WT__c r: rows){
            csv += String.format('{0},{1},"{2}"\n', new List<Object>{r.TubeOD__r.OD_mm__c, r.TubeWT__r.WT_mm__c, wrap(r.SCH__c)});
        }
        if (save) saveCsv(csv, 'SCH_OD_WT_export.csv');
        return csv;
    }
    private static String wrap(String s){ return (s==null)?'':s.replace('"','\''); }
    private static void saveCsv(String csv, String fname){
        ContentVersion cv = new ContentVersion();
        cv.Title = fname; cv.PathOnClient = fname;
        cv.VersionData = Blob.valueOf(csv); insert cv;
    }
}