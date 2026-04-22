public class OppDataErrors {

    public String iteNumber;
    public String altNumber;

    public String salesRepEmail;
    public String bosEmail;

    public List<String> errors = new List<String>();
    public List<String> warnings = new List<String>();

    public Datetime timestamp = System.now();
    public String correlationId;

    public Boolean hasErrors() {
        return errors != null && !errors.isEmpty();
    }

    public OppDataErrors () {
        this.iteNumber = '';
        this.altNumber = '';

        this.salesRepEmail='';
        this.bosEmail = '';

        this.errors = new List<String>();
        this.warnings = new List<String>();

        this.timestamp = System.now();
        this.correlationId = '';
    }
}