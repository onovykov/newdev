public class OpportunityResolutionResult extends ResolutionResult {

    public Opportunity opportunity;

    private OpportunityResolutionResult(
        Boolean found,
        Opportunity opportunity,
        String reason
    ) {
        super(found, reason);
        this.opportunity = opportunity;
    }

    public static OpportunityResolutionResult found(Opportunity opp) {
        return new OpportunityResolutionResult(true, opp, null);
    }

    public static OpportunityResolutionResult notFound(String reason) {
        return new OpportunityResolutionResult(false, null, reason);
    }
}