public class IntegrationDomainException extends Exception {

    public String handlerName;
    public String code;
    public String contextValue;

    public IntegrationDomainException(
        String handlerName,
        String code,
        String contextValue
    ) {
        this.handlerName = handlerName;
        this.code = code;
        this.contextValue = contextValue;
    }
}