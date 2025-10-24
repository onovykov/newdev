// file: classes/CurrencyRatesDashboardCtrl.cls
public with sharing class CurrencyRatesDashboardCtrl {

    public class Row {
        @AuraEnabled public String iso;
        @AuraEnabled public Decimal rate;
        @AuraEnabled public Datetime lastModified;
        public Row(String iso, Decimal rate, Datetime lm) { this.iso = iso; this.rate = rate; this.lastModified = lm; }
    }
    public class Resp {
        @AuraEnabled public String corporateIso;
        @AuraEnabled public List<Row> rows;
        @AuraEnabled public Datetime generatedAt;
    }

    @AuraEnabled(cacheable=true)
    public static Resp getRates(List<String> excludeIsos) {
        Set<String> ex = (excludeIsos == null) ? new Set<String>() : new Set<String>(excludeIsos);
        String corporateIso = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true LIMIT 1].IsoCode;

        List<Row> rows = new List<Row>();
        for (CurrencyType c : [
            SELECT IsoCode, ConversionRate, IsActive, LastModifiedDate
            FROM CurrencyType
            WHERE IsActive = true AND IsoCode NOT IN :ex
            ORDER BY IsoCode
        ]) {
            rows.add(new Row(c.IsoCode, c.ConversionRate, c.LastModifiedDate));
        }
        Resp r = new Resp();
        r.corporateIso = corporateIso;
        r.rows = rows;
        r.generatedAt = System.now();
        return r;
    }

    // Pull from NBU and write to SF (CT and/or DCR), then return fresh data
    @AuraEnabled
    public static Resp refreshFromNbu(Boolean updateCT, Boolean updateDCR, List<String> excludeIsos) {
        try {
            List<CurrencyRatesService.RatesPayload> pl = CurrencyRatesService.getNBURates();
            if (updateCT == null || updateCT) {
                CurrencyRatesService.applyRatesViaSessionIdToCurrencyType(pl);
            }
            if (updateDCR == null || updateDCR) {
                CurrencyRatesService.applyRatesViaSessionIdToDCR(pl);
            }
            // return current view after update
            return getRates(excludeIsos);
        } catch (Exception e) {
            // surface readable error to LWC
            throw new AuraHandledException('Помилка оновлення з НБУ: ' + e.getMessage());
        }
    }
}