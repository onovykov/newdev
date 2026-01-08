public class LegacySteelRow {

    public String sourceObject;
    public Id sfId;
    public String erpId;
    public String name;
    public String shortName;
    public String facetCode; // RSMP / SGMP

    public static LegacySteelRow fromSObject(SObject s) {

        LegacySteelRow r = new LegacySteelRow();

        r.sfId = (Id)s.get('Id');
        r.erpId = (String)s.get('ID_ERP__c');
        r.name = (String)s.get('Name');
        r.shortName = (String)s.get('ShortName__c');

        r.sourceObject =
            s.getSObjectType().getDescribe().getName();

        r.facetCode =
            (r.sourceObject == 'WheelSteelGrade__c')
                ? 'RSMP'
                : 'SGMP';

        return r;
    }
}