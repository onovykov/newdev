public class ApexUtil {
    //--- Util Methods
    /** return the unique values for a given field in a list of records. Null is not included. */
    public static Set<String> getFieldValues(SObject[] objects, SObjectField field) {
        return getFieldValues(objects, field.getDescribe().getName());
    }

    public static Set<String> getFieldValues(SObject[] objects, String field) {
        Set<String> result = new Set<String> ();
        if (!objects.isEmpty()) {
            for (SObject o : objects) {
                result.add(String.valueOf(o.get(field)));
            }
            result.remove(null);
        }
        return result;
    }

    /** return the unique Ids in a list of records. */
    public static Set<String> getIds(SObject[] objects) {
        return getFieldValues(objects, Case.Id);
    }

    /** return the specified string page parameter, or 'defaultValue' */
    public static String getPageParam(String key, String defaultValue) {
        final String param = ApexPages.currentPage().getParameters().get(key);
        return(null == param) ? defaultValue : param;
    }

    /** return the specified integer page parameter, or 'defaultValue' */
    public static Integer getPageParam(String key, Integer defaultValue) {
        try {
            if (ApexPages.currentPage().getParameters().containsKey(key)) {
                return Integer.valueOf(ApexPages.currentPage().getParameters().get(key));
            }
        } catch(Exception e) {
        }

        return defaultValue;
    }

    public static Map<String, String> getPicklistFieldMap(String objectName, String fieldName) {
        Map<String, String> resultMap = new Map<String, String> ();
        SObjectType obj = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fields = obj.getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry v : values) {
            resultMap.put(v.getLabel(), v.getValue());
        }
        return resultMap;
    }

    public static String getCreatableFieldsSOQL(String objectName, String recordId) {
        String selects = '';
        if (recordId == null || recordId == '') {
            return null;
        }
                // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string> ();

        if (fMap != null) {
            for (Schema.SObjectField ft : fMap.values()) { // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()) { // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }

        if (!selectFields.isEmpty()) {
            for (string s : selectFields) {
                selects += s + ',';
            }
            if (selects.endsWith(',')) { selects = selects.substring(0, selects.lastIndexOf(',')); }

        }
        String query = 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ID=\'' + recordId + '\'';
        System.debug(query);
        return query;
    }
    
    //--- Перевіряємо, чи є рядок числом
    public static Boolean isNumber(String s) {
        if (String.isBlank(s)) return false;
        try {
            Decimal d = Decimal.valueOf(s);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    //--- Повертає текстове подання числа без кінцевих нулів для Decimal
    public static String formatDecimal(Decimal d) {
        return d == null ? null : d.stripTrailingZeros().toPlainString();
    }
    
}