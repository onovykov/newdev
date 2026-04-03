public class ResolverRequest {
    public String resolverKey;
    public String domain;
    public String orderType;

    public Map<String, String> rawInputs = new Map<String, String>();
    public Map<String, String> normalizedInputs = new Map<String, String>();
    public Map<String, Object> attributes = new Map<String, Object>();
}