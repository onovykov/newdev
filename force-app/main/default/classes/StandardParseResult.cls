public class StandardParseResult {
    public String raw;
    public String canonicalCode;   // EN_13262, API_5L, GOST_10791
    public String editionCode;     // PSL2, 2018, A2:2011, ISO3183
    public Integer year;
    public Integer part;
    public String subSpec;
    public StandardResolutionType type;
    public Decimal confidence;
    public String rule;

    public static StandardParseResult base(String raw, String code, String rule) {
        StandardParseResult r = new StandardParseResult();
        r.raw = raw;
        r.canonicalCode = code;
        r.type = StandardResolutionType.BASE;
        r.confidence = 0.8;
        r.rule = rule;
        return r;
    }

    public static StandardParseResult edition(String raw, String code, String edition, String rule) {
        StandardParseResult r = base(raw, code, rule);
        r.type = StandardResolutionType.EDITION;
        r.editionCode = edition;
        r.confidence = 0.95;
        return r;
    }

    public static StandardParseResult trash(String raw, String rule) {
        StandardParseResult r = new StandardParseResult();
        r.raw = raw;
        r.type = StandardResolutionType.TRASH;
        r.confidence = 1.0;
        r.rule = rule;
        return r;
    }
}