public class SteelParseResult {

    // === Класифікація результату ===
    // GRADE: розпізнали базову марку (ER7, S355J2H…)
    // VARIANT: базова марка + варіант постачання (+N, TC1…)
    // STANDARD: токен схожий на стандарт/ТУ (на майбутнє)
    // TRASH: сміття (N/A, "по спецификации"...)
    // UNKNOWN: не змогли класифікувати
    public String type;

    // === Вхідний токен (після split по "/") ===
    public String rawToken;

    // === Канонічна базова марка (ключ для ProdSteelGrade__c.Code__c) ===
    public String baseCode; // напр. "S355J2H", "ER7"

    // === Варіант постачання/стан ===
    public String variantCode; // напр. "+N", "TC1", "BTG"

    // === Додаткові атрибути, якщо витягли ===
    public Integer category;   // напр. cat.1 / cat.2
    public String alias;       // те, що в дужках "(...)" або внутрішній псевдонім
    public String standardText;// якщо знайшли EN/DIN/TU тощо

    // === Службове: чому так вирішили ===
    public String rule;        // напр. "grade:whitelist", "trash:hardcoded"
    public Decimal confidence; // 0..1 (зручно для вибору "кращого" мапінгу)

    // === Посилання на цілі (коли Batch уже створив/знайшов Id) ===
    // Ці поля може заповнювати або Batch, або Factory — як тобі зручніше.
    public Id gradeId;
    public Id variantId;

    // === Для унікального LegacyKey__c ===
    // Якщо один legacy Name дає N результатів — suffix допоможе уникати колізій.
    public String hashSuffix;

    // ---------- Конструктори/фабрики ----------

    public SteelParseResult() {}

    public static SteelParseResult grade(
        String rawToken,
        String baseCode,
        String rule,
        Decimal confidence
    ) {
        SteelParseResult r = new SteelParseResult();
        r.type = 'GRADE';
        r.rawToken = rawToken;
        r.baseCode = baseCode;
        r.rule = rule;
        r.confidence = confidence;
        r.hashSuffix = shortSha12(rawToken + '|' + baseCode + '|GRADE');
        return r;
    }

    public static SteelParseResult variant(
        String rawToken,
        String baseCode,
        String variantCode,
        Integer category,
        String alias,
        String rule,
        Decimal confidence
    ) {
        SteelParseResult r = new SteelParseResult();
        r.type = 'VARIANT';
        r.rawToken = rawToken;
        r.baseCode = baseCode;
        r.variantCode = variantCode;
        r.category = category;
        r.alias = alias;
        r.rule = rule;
        r.confidence = confidence;
        r.hashSuffix = shortSha12(rawToken + '|' + baseCode + '|' + variantCode + '|VARIANT');
        return r;
    }

    public static SteelParseResult trash(
        String rawToken,
        String rule
    ) {
        SteelParseResult r = new SteelParseResult();
        r.type = 'TRASH';
        r.rawToken = rawToken;
        r.rule = rule;
        r.confidence = 1.0;
        r.hashSuffix = shortSha12(rawToken + '|TRASH');
        return r;
    }

    public static SteelParseResult unknown(
        String rawToken,
        String rule
    ) {
        SteelParseResult r = new SteelParseResult();
        r.type = 'UNKNOWN';
        r.rawToken = rawToken;
        r.rule = rule;
        r.confidence = 0.0;
        r.hashSuffix = shortSha12(rawToken + '|UNKNOWN');
        return r;
    }

    public static SteelParseResult standard(
        String rawToken,
        String standardText,
        String rule,
        Decimal confidence
    ) {
        SteelParseResult r = new SteelParseResult();
        r.type = 'STANDARD';
        r.rawToken = rawToken;
        r.standardText = standardText;
        r.rule = rule;
        r.confidence = confidence;
        r.hashSuffix = shortSha12(rawToken + '|' + standardText + '|STANDARD');
        return r;
    }

    // ---------- Helpers ----------

    public static String buildVariantKey(
        String baseCode,
        String variantCode,
        Integer category,
        String alias
    ) {
        // Стабільний ключ для ProdSteelGradeVariant__c.VariantKey__c
        String cat = (category == null ? '' : String.valueOf(category));
        String a = (alias == null ? '' : alias.trim());
        return baseCode + '|' + variantCode + '|cat:' + cat + '|a:' + a;
    }

    private static String shortSha12(String input) {
        Blob b = Blob.valueOf(input == null ? '' : input);
        Blob d = Crypto.generateDigest('SHA1', b);
        String hex = EncodingUtil.convertToHex(d);
        return hex.substring(0, 12);
    }
}