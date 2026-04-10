public class IntegrationHandlerResponse {

    public Integer httpStatus;
    public Object body;
    public String payload;

    public IntegrationHandlerResponse(Integer httpStatus, Object body, String payload) {
        this.httpStatus = httpStatus;
        this.body = body;
        this.payload =payload;
    }
}
