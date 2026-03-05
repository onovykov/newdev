public class IntegrationContext {
    // === Metadata ===
    public String messageType;     // ERP-SF_OpportunityData
    public String direction;       // ERP_SF / SF_ERP
    public String handlerKey;      // from CMDT

    // === Raw payload ===
    public String rawJson;
    public Object parsedMessage;

    // === Domain results ===
	public Map<String, Object> results = new Map<String, Object>();
	
	public void putResult(String key, Object value) {
		results.put(key, value);
	}

	public Object getResult(String key) {
		return results.get(key);
	}

    // === Errors ===
    private List<String> errors = new List<String>();
	
	public List<String> getErrors() {
		return new List<String>(errors);
	}	

    // === Control flags ===
    public Boolean stopProcessing = false;

    // === Error handling ===
    public void addError(String error) {
        if (String.isNotBlank(error)) {
            errors.add(error);
            stopProcessing = true;
        }
    }

    public Boolean hasErrors() {
        return !errors.isEmpty();
    }

    public String getErrorsAsString() {
        return String.join(errors, '; ');
    }
}