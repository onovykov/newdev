public class InvoiceOrderDebtJobConfig {

    public final List<ERPMessageParser.InvoiceOrderDebtMessageData> source;
    public final String origin;
    public final Integer retry;
    public final Integer retryMax;

    public InvoiceOrderDebtJobConfig(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel,
        Integer retry,
        Integer retryMax
    ) {
        this.source   = src;
        this.origin   = String.isBlank(originLabel) ? 'unknown' : originLabel;
        this.retry    = (retry    == null) ? 0 : retry;
        this.retryMax = (retryMax == null) ? 6 : retryMax;
    }
}