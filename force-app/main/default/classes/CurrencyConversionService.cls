public with sharing class CurrencyConversionService {
    // ====== ПУБЛІЧНЕ API ======
    public static Decimal convert(Decimal amount, String fromIso, String toIso, Date onDate) {
        if (amount == null) return null;
        if (String.isBlank(fromIso) || String.isBlank(toIso)) {
            throw new CurrencyConversionException('ISO codes (from/to) must be provided');
        }
        if (fromIso == toIso) {
            return amount.setScale(2, System.RoundingMode.HALF_UP);
        }
        Decimal cross = getCrossRate(fromIso, toIso, onDate);
        return (amount * cross).setScale(2, System.RoundingMode.HALF_UP);
    }

    public static Decimal getCrossRate(String fromIso, String toIso, Date onDate) {
        if (String.isBlank(fromIso) || String.isBlank(toIso)) {
            throw new CurrencyConversionException('ISO codes (from/to) must be provided');
        }
        if (onDate == null) onDate = System.today();
        if (fromIso == toIso) return 1;

        Decimal fromToCorp = latestRateToCorp(fromIso, onDate); // CORP/from
        Decimal toToCorp   = latestRateToCorp(toIso,   onDate); // CORP/to

        // GBP→EUR = (CORP/GBP) / (CORP/EUR)
        return toToCorp.divide(fromToCorp, 9, System.RoundingMode.HALF_UP);
    }

    // ====== ВНУТРІШНЄ API / ІНФРА ======

    public class CurrencyConversionException extends Exception {}

    @TestVisible private static Map<String, Decimal> rateCache = new Map<String, Decimal>();
    @TestVisible private static String corpIsoCached;

    public interface RatesProvider {
        Decimal getToCorporateRate(String iso, Date onDate); // повертає CORP/ISO на дату <= onDate
        String getCorporateIso();
    }

    // Дефолтний провайдер: читає реальні дані (CurrencyType / DatedConversionRate)
    public class DefaultRatesProvider implements RatesProvider {
        public Decimal getToCorporateRate(String iso, Date onDate) {
            if (onDate == null) onDate = System.today();
            DatedConversionRate r = [
                SELECT IsoCode, ConversionRate, StartDate
                FROM DatedConversionRate
                WHERE IsoCode = :iso AND StartDate <= :onDate
                ORDER BY StartDate DESC
                LIMIT 1
            ];
            return r.ConversionRate; // CORP/ISO
        }

        public String getCorporateIso() {
            // Корпоративна валюта — там, де IsCorporate = true
            return [
                SELECT IsoCode FROM CurrencyType
                WHERE IsCorporate = true
                LIMIT 1
            ].IsoCode;
        }
    }

    @TestVisible private static RatesProvider provider = new DefaultRatesProvider();

    @TestVisible
    static void setRatesProvider(RatesProvider p) {
        provider = (p == null) ? new DefaultRatesProvider() : p;
        rateCache.clear();
        corpIsoCached = null;
    }

    private static String getCorporateIso() {
        if (corpIsoCached == null) corpIsoCached = provider.getCorporateIso();
        return corpIsoCached;
    }

    private static String cacheKey(String iso, Date onDate) {
        if (onDate == null) onDate = System.today();
        // Робимо стабільний ключ дати через GMT
        DateTime dt = DateTime.newInstanceGmt(onDate.year(), onDate.month(), onDate.day(), 0, 0, 0);
        String ymd = dt.formatGmt('yyyyMMdd');
        return iso.toUpperCase() + '|' + ymd;
    }

    private static Decimal latestRateToCorp(String iso, Date onDate) {
        if (String.isBlank(iso)) {
            throw new CurrencyConversionException('ISO code must be provided');
        }
        String key = cacheKey(iso, onDate);
        if (rateCache.containsKey(key)) return rateCache.get(key);

        Decimal rate = provider.getToCorporateRate(iso.toUpperCase(), onDate);
        if (rate == null) {
            throw new CurrencyConversionException('No conversion rate for ' + iso + ' on ' + String.valueOf(onDate));
        }
        rateCache.put(key, rate);
        return rate;
    }
}