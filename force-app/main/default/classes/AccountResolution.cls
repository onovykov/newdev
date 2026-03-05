public class AccountResolution extends IntegrationResolution {

    public Account account { get; private set; }

    private AccountResolution(Boolean found, Account account, String reason) {
        super(found, reason);
        this.account = account;
    }

    public static AccountResolution found(Account acc) {
        return new AccountResolution(true, acc, null);
    }

    public static AccountResolution notFound(String reason) {
        return new AccountResolution(false, null, reason);
    }
}