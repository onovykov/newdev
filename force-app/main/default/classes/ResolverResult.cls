public class ResolverResult {
    public Boolean isResolved;
    public String resolvedValue;
    public Integer matchedPriority;
    public String diagnosticMessage;

    public static ResolverResult success(String value, Integer priority) {
        ResolverResult r = new ResolverResult();
        r.isResolved = true;
        r.resolvedValue = value;
        r.matchedPriority = priority;
        return r;
    }

    public static ResolverResult empty(String msg) {
        ResolverResult r = new ResolverResult();
        r.isResolved = false;
        r.diagnosticMessage = msg;
        return r;
    }
}