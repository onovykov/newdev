public with sharing class RecordTypeResolver {

    private static String apiName(SObjectType typeToken) {
        return String.valueOf(typeToken);
    }

    public static Id getId(SObjectType sObjectType, String developerName) {
        return RecordTypeCache.getOrThrow(apiName(sObjectType), developerName, false);
    }

    public static Id getOrThrow(SObjectType sObjectType, String developerName) {
        return RecordTypeCache.getOrThrow(apiName(sObjectType), developerName, false);
    }

    public static Id getIncludingInactive(SObjectType sObjectType, String developerName) {
        return RecordTypeCache.getOrThrow(apiName(sObjectType), developerName, true);
    }

    public static Map<String, Id> getMap(SObjectType sObjectType) {
        return RecordTypeCache.getMapFor(apiName(sObjectType));
    }

    public static Boolean exists(SObjectType sObjectType, String developerName) {
        Map<String, Id> mapRt = getMap(sObjectType);
        return mapRt.containsKey(developerName);
    }
}