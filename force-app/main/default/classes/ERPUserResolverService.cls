public with sharing class ERPUserResolverService {

    /*
     * Основний метод для resolution по OwnersId
     */
    public static ERPUserResolutionResult resolveFromOwnersId(
        String ownersId,
        Boolean strictMode
    ) {
        Set<String> loginSet = extractLoginSet(ownersId);
        return resolveFromLoginSet(loginSet, strictMode);
    }

    /*
     * Універсальний метод (можна викликати з будь-якого місця)
     */
    public static ERPUserResolutionResult resolveFromLoginSet(
        Set<String> loginSet,
        Boolean strictMode
    ) {

        ERPUserResolutionResult result =
            new ERPUserResolutionResult();

        if(loginSet == null || loginSet.isEmpty()){
            return result;
        }

        Map<String, User> resolved =
            UserRepository.getByLoginERPSet(loginSet);

        result.resolvedUsers = resolved;

        for(String login : loginSet){
            if(!resolved.containsKey(login)){
                result.missingUsers.add(login);
            }
        }

        if(!result.missingUsers.isEmpty()){

            logMissingUsers(result.missingUsers);

            if(strictMode){
                result.isSuccessful = false;
                throw new ERPUserResolutionException(
                    'Missing ERP Users: ' +
                    String.join(new List<String>(result.missingUsers), ',')
                );
            }
        }

        sendTelemetry(loginSet.size(), result.missingUsers.size());

        return result;
    }

    /*
     * Витягує Set<String> з OwnersId
     */
    private static Set<String> extractLoginSet(String ownersId){

        Set<String> result = new Set<String>();

        if(String.isBlank(ownersId)){
            return result;
        }

        for(String raw : ownersId.split(',')){
            if(String.isBlank(raw)) continue;
            result.add(raw.trim());
        }

        return result;
    }

    /*
     * Логування missing users
     */
    private static void logMissingUsers(Set<String> missing){

        System.debug(LoggingLevel.ERROR,
            'ERPUserResolver → Missing ERP Users: ' +
            String.join(new List<String>(missing), ',')
        );

        // Можна тут:
        // - IntegrationLogService.log(...)
        // - Platform Event
        // - Custom Object
    }

    /*
     * Telemetry hook
     */
    private static void sendTelemetry(Integer total, Integer missing){

        System.debug(
            'ERPUserResolver Telemetry → total=' +
            total + ', missing=' + missing
        );

        // Hook для:
        // - Pharos Triton
        // - Platform Event
        // - Future monitoring
    }

    public class ERPUserResolutionException extends Exception {}

}