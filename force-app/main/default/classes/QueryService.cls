public with sharing class QueryService {

    public static List<SObject> selectRecords(
        String sObjectApi,
        List<String> fields,
        String whereClause,
        Integer limitSize
    ) {
        if (String.isBlank(sObjectApi)) {
            throw new AsyncConfigException('sObjectApi is required');
        }

        if (fields == null || fields.isEmpty()) {
            throw new AsyncConfigException('fields are required');
        }

        String soql =
            'SELECT ' + String.join(fields, ',') +
            ' FROM ' + sObjectApi;

        if (!String.isBlank(whereClause)) {
            soql += ' WHERE ' + whereClause;
        }

        if (limitSize != null && limitSize > 0) {
            soql += ' LIMIT ' + limitSize;
        }

        return Database.query(soql);
    }
}