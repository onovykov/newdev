// OpportunityResolution.cls
public class OpportunityResolution extends IntegrationResolution {

    public Opportunity opportunity { get; private set; }

    private OpportunityResolution(Boolean found, Opportunity opp, String reason) {
        super(found, reason);
        this.opportunity = opp;
    }

    public static OpportunityResolution found(Opportunity opp) {
        return new OpportunityResolution(true, opp, null);
    }

    public static OpportunityResolution notFound(String reason) {
        return new OpportunityResolution(false, null, reason);
    }
}