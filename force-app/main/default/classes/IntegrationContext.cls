public class IntegrationContext {

    // =========================================================
    // Metadata
    // =========================================================
    public String messageType;
    public String direction;
    public String handlerKey;

    // =========================================================
    // Raw payload
    // =========================================================
    public String rawJson;
    public Object parsedMessage;

    // =========================================================
    // Results
    // =========================================================
    private Map<String, Object> results = new Map<String, Object>();

    public void putResult(String key, Object value) {
        results.put(key, value);
    }

    public Object getResult(String key) {
        return results.get(key);
    }

    public Map<String, Object> getAllResults() {
        return new Map<String, Object>(results);
    }

    // =========================================================
    // Response (🔥 NEW STANDARD)
    // =========================================================
    private IntegrationHandlerResponse response;

    public void setResponse(IntegrationHandlerResponse r) {
        this.response = r;
    }

    public IntegrationHandlerResponse getResponse() {
        return this.response;
    }

    // =========================================================
    // Errors
    // =========================================================
    private List<String> errors = new List<String>();

    public void addError(String error) {
        if (String.isNotBlank(error)) {
            errors.add(error);
            stopProcessing = true;
        }
    }

    public Boolean hasErrors() {
        return !errors.isEmpty();
    }

    public List<String> getErrors() {
        return new List<String>(errors);
    }

    public String getErrorsAsString() {
        return String.join(errors, '; ');
    }

    // =========================================================
    // Control flags
    // =========================================================
    public Boolean stopProcessing = false;
}