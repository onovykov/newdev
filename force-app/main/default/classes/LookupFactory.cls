public class LookupFactory {

    public static AccountLookup account() {
        return new AccountLookupImpl();
    }

    public static OpportunityLookup opportunity() {
        return new OpportunityLookupImpl();
    }

    public static OrderLookup order() {
        return new OrderLookupImpl();
    }
}