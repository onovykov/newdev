public class CurrencyRateResponseJSON {

    public Integer r030;
    public String txt;
    public Double rate;
    public String cc;
    public String exchangedate;

    public static List<CurrencyRateResponseJSON> parse(String json) {
		return (List<CurrencyRateResponseJSON>) System.JSON.deserialize(json, List<CurrencyRateResponseJSON>.class);
	}
}