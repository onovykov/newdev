public class CmdtDeployCallback implements Metadata.DeployCallback {

    private final String cmdtTypeName;
    private final String developerName;

    public CmdtDeployCallback(String cmdtTypeName, String developerName) {
        this.cmdtTypeName = cmdtTypeName;
        this.developerName = developerName;
    }

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

        System.debug(LoggingLevel.INFO,
            'CMDT DEPLOY RESULT: status=' + result.status +
            ' type=' + cmdtTypeName +
            ' devName=' + developerName
        );

        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug(LoggingLevel.INFO, 'CMDT update succeeded.');
            return;
        }

        // Global error (often null for component-level failures)
        if (result.errorMessage != null) {
            System.debug(LoggingLevel.ERROR, 'CMDT deploy global error: ' + result.errorMessage);
        }

        // Component-level failures (this is where the real reason usually is)
        if (result.details != null && result.details.componentFailures != null) {
            for (Metadata.DeployMessage msg : result.details.componentFailures) {
                System.debug(LoggingLevel.ERROR,
                    'CMDT component failure: fullName=' + msg.fullName +
                    ' problem=' + msg.problem +
                    (msg.lineNumber != null ? ' line=' + msg.lineNumber : '') +
                    (msg.columnNumber != null ? ' col=' + msg.columnNumber : '')
                );
            }
        } else {
            System.debug(LoggingLevel.ERROR, 'CMDT update failed but no componentFailure details were provided.');
        }
    }
}