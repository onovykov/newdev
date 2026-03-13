public class ERPUserResolutionResult {
    public Map<String, User> resolvedUsers = new Map<String, User>();
    public Set<String> missingUsers = new Set<String>();
    public Boolean isSuccessful = true;
}