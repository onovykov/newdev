public class IntegrationResult {

    public Boolean success;
    public String message;

    public static IntegrationResult success() {
        IntegrationResult r = new IntegrationResult();
        r.success = true;
        return r;
    }

    public static IntegrationResult fail(String message) {
        IntegrationResult r = new IntegrationResult();
        r.success = false;
        r.message = message;
        return r;
    }
}