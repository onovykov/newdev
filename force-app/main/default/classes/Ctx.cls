public with sharing class Ctx {
    public SObject ctx;
    public Account acc;
    public Opportunity opp;
    public static Ctx of(SObject s) {
        Ctx c = new Ctx();
        c.ctx = s;
        if (s.getSObjectType() == Opportunity.SObjectType) {
            c.opp = (Opportunity)s;
            if (c.opp.AccountId != null) c.acc = AccountRepository.getById(c.opp.AccountId);
        } else if (s.getSObjectType() == Account.SObjectType) {
            c.acc = AccountRepository.getById((Id)s.get('Id'));
        }
        return c;
    }
}