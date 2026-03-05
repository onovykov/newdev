public abstract class ResolutionResult {

    public Boolean found;
    public String reason;

    protected ResolutionResult(Boolean found, String reason) {
        this.found = found;
        this.reason = reason;
    }
}