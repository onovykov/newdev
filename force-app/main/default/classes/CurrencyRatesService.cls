public with sharing class CurrencyRatesService implements Database.AllowsCallouts {

    // ============= Налаштування =============
    // Named Credential до власної орги (OAuth 2.0 із scope 'full')
    private static final String NC_SF_REST = 'Interpipe_Self_Org';
    // Версія REST API
    private static final String API_VER = 'v62.0';
    // Ендпойнт НБУ (JSON)
    private static final String NBU_URL = 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchangenew?json';

    // ============= DTO =============
    /** Внутрішня модель відповіді НБУ */
    public class NbuRate {
        public Integer r030;        // код валюти
        public String  txt;         // назва
        public Decimal rate;        // СКІЛЬКИ UAH за 1 одиницю цієї валюти
        public String  cc;          // ISO (USD/EUR/...)
        public String  exchangedate;// "dd.MM.yyyy"
    }

    /** Публічний payload:
     *  mainISO — корпоративна валюта,
     *  otherISO — інша валюта,
     *  rateToMainISO — СКІЛЬКИ otherISO за 1 mainISO (напр., скільки UAH за 1 USD - для логів/перевірок)
     */
    public class RatesPayload {
        public String  mainISO;
        public String  otherISO;
        public Date    rateDate;
        public Decimal rateToMainISO;

        public RatesPayload() {}
        public RatesPayload(String mainISO, String otherISO, Date d, Decimal rateToMainISO) {
            this.mainISO = mainISO;
            this.otherISO = otherISO;
            this.rateDate = d;
            this.rateToMainISO = rateToMainISO;
        }
    }

    // ============= Публічні методи =============

    /** End-to-end: витягнути курси з НБУ, показати прев’ю, записати в Salesforce (через NC або SessionId — обираємо по ситуації) */
    public static void syncFromNbu() {
        List<RatesPayload> payloads = getNBURates();
        logPreview(payloads, 15); // прев’ю в логах
        applyRates(payloads);     // запис через Named Credential (коли NC вже "Authenticated")
        // або: applyRatesViaSessionId(payloads);        // авто: DCR або CurrencyType через SessionId
        // або: applyRatesViaSessionIdToDCR(payloads);   // примусово в DCR (ACM)
        // або: applyRatesViaSessionIdToCurrencyType(payloads); // примусово в CurrencyType
    }

    /** Отримати з НБУ список у форматі "скільки OTHER за 1 MAIN (corporate) - напр., скільки UAH за 1 USD" */
    public static List<RatesPayload> getNBURates() {
        // 1) Callout до НБУ
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(NBU_URL);
        req.setTimeout(15000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException('NBU API error: ' + res.getStatusCode() + ' ' + res.getBody());
        }

        List<NbuRate> nbu = (List<NbuRate>) JSON.deserialize(res.getBody(), List<NbuRate>.class);
        if (nbu == null || nbu.isEmpty()) return new List<RatesPayload>();

        // 2) Дані з org: які маємо активні валюти й яка з них є Corporate
        Set<String> activeIsos = getActiveCurrencies();
        String corporateIso = getCorporateIso();

        // 3) Мапа: ISO -> UAH_per_ISO та дата курсу
        Map<String, Decimal> uahPerIso = new Map<String, Decimal>();
        Date nbuDate = null;
        for (NbuRate r : nbu) {
            if (String.isBlank(r.cc) || r.rate == null) continue;
            uahPerIso.put(r.cc, r.rate);
            if (nbuDate == null && !String.isBlank(r.exchangedate)) {
                nbuDate = parseNbuDate(r.exchangedate);
            }
        }
        if (nbuDate == null) nbuDate = Date.today();

        // 4) Скільки UAH за 1 корпоративну валюту
        Decimal uahPerCorporate;
        if (corporateIso == 'UAH') {
            uahPerCorporate = 1;
        } else {
            uahPerCorporate = uahPerIso.get(corporateIso);
            if (uahPerCorporate == null || uahPerCorporate <= 0) {
                throw new IllegalArgumentException('У курсах НБУ відсутній запис для корпоративної валюти ' + corporateIso);
            }
        }

        // 5) Побудувати вихідні RatesPayload ("OTHER за 1 MAIN") — як у логах
        List<RatesPayload> out = new List<RatesPayload>();

        // MAIN->MAIN = 1
        out.add(new RatesPayload(corporateIso, corporateIso, nbuDate, 1));

        // Якщо UAH активна і Main != UAH — додамо UAH за 1 MAIN
        if (activeIsos.contains('UAH') && corporateIso != 'UAH') {
            out.add(new RatesPayload(corporateIso, 'UAH', nbuDate, uahPerCorporate.setScale(4)));
        }

        for (String otherIso : activeIsos) {
            if (otherIso == corporateIso || otherIso == 'UAH') continue;
            Decimal uahPerOther = uahPerIso.get(otherIso);
            if (uahPerOther == null || uahPerOther <= 0) continue;

            Decimal otherPerMain;
            if (corporateIso == 'UAH') {
                // OTHER per 1 UAH = 1 / (UAH per OTHER)
                otherPerMain = Decimal.valueOf(1) / uahPerOther;
            } else {
                // OTHER per 1 MAIN = (UAH per MAIN) / (UAH per OTHER)
                otherPerMain = uahPerCorporate / uahPerOther;
            }
            out.add(new RatesPayload(corporateIso, otherIso, nbuDate, otherPerMain.setScale(4)));
        }
        return out;
    }

    /** Записати курси у Salesforce через Named Credential:
     *  - якщо ACM OFF -> PATCH CurrencyType.ConversionRate (через NC)
     *  - якщо ACM ON  -> POST/PATCH DatedConversionRate на дату payload.rateDate (через NC)
     *
     *  ⚠️ УВАГА: CurrencyType/DatedConversionRate очікують формат "СКІЛЬКИ ІНШОЇ за 1 КОРПОРАТИВНУ" (OTHER per 1 MAIN)
     */
    public static void applyRates(List<RatesPayload> payloads) {
        if (payloads == null || payloads.isEmpty()) return;

        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();

        // Пишемо у форматі SF (OTHER per 1 MAIN)
        Map<String, Decimal> isoToCorporatePer1Other = new Map<String, Decimal>();
        Date targetDate = null;

        for (RatesPayload p : payloads) {
            if (String.isBlank(p.otherISO)) continue;
            if (!activeIsos.contains(p.otherISO)) continue;

            Decimal conv;
            if (p.otherISO == corporateIso) {
                conv = 1; // 1 corporate per 1 corporate
            } else {
                if (p.rateToMainISO == null || p.rateToMainISO <= 0) continue;
                conv = p.rateToMainISO; // <-- ФІКС: без інверсії
            }
            isoToCorporatePer1Other.put(p.otherISO, conv);
            if (targetDate == null && p.rateDate != null) targetDate = p.rateDate;
        }
        if (isoToCorporatePer1Other.isEmpty()) return;
        if (targetDate == null) targetDate = Date.today();

        // Ознака ACM: якщо DatedConversionRate доступний для створення — вважаємо ACM ON
        Boolean acmEnabled = Schema.sObjectType.DatedConversionRate.isCreateable();

        if (!acmEnabled) {
            upsertCurrencyTypeRatesViaREST(isoToCorporatePer1Other, corporateIso);
        } else {
            upsertDatedRatesViaREST(isoToCorporatePer1Other, targetDate, corporateIso);
        }
    }

    /** Авто-запис через поточний SessionId (без NC): якщо ACM ON – у DCR, інакше – у CurrencyType */
    public static void applyRatesViaSessionId(List<RatesPayload> payloads) {
        if (payloads == null || payloads.isEmpty()) return;

        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();

        Map<String, Decimal> isoToCorporatePer1Other = new Map<String, Decimal>();
        Date targetDate = null;

        for (RatesPayload p : payloads) {
            if (String.isBlank(p.otherISO)) continue;
            if (!activeIsos.contains(p.otherISO)) continue;

            Decimal conv;
            if (p.otherISO == corporateIso) {
                conv = 1;
            } else {
                if (p.rateToMainISO == null || p.rateToMainISO <= 0) continue;
                conv = p.rateToMainISO; // <-- ФІКС: без інверсії
            }
            isoToCorporatePer1Other.put(p.otherISO, conv);
            if (targetDate == null && p.rateDate != null) targetDate = p.rateDate;
        }
        if (isoToCorporatePer1Other.isEmpty()) return;
        if (targetDate == null) targetDate = Date.today();

        Boolean acmEnabled = Schema.sObjectType.DatedConversionRate.isCreateable();

        if (!acmEnabled) {
            upsertCurrencyTypeRatesViaSessionId(isoToCorporatePer1Other, corporateIso);
        } else {
            upsertDatedRatesViaSessionId(isoToCorporatePer1Other, targetDate, corporateIso);
        }
    }

    // ---------- Примусові публічні методи через SessionId ----------

    /** Явно записати у DatedConversionRate (ACM) через SessionId */
    public static void applyRatesViaSessionIdToDCR(List<RatesPayload> payloads) {
        if (payloads == null || payloads.isEmpty()) return;
        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();

        Map<String, Decimal> isoToCorporatePer1Other = new Map<String, Decimal>();
        Date targetDate = null;

        for (RatesPayload p : payloads) {
            if (String.isBlank(p.otherISO) || !activeIsos.contains(p.otherISO)) continue;

            // ⚠️ Пропускаємо корпоративну валюту – для DCR її редагувати не можна❗
            if (p.otherISO == corporateIso) {
                if (targetDate == null && p.rateDate != null) targetDate = p.rateDate;
                continue;
            }

            Decimal conv = (p.rateToMainISO != null && p.rateToMainISO > 0)
                ? p.rateToMainISO   // <-- ФІКС: без інверсії
                : null;
            if (conv != null && conv > 0) isoToCorporatePer1Other.put(p.otherISO, conv);
            if (targetDate == null && p.rateDate != null) targetDate = p.rateDate;
        }
        if (isoToCorporatePer1Other.isEmpty()) return;
        if (targetDate == null) targetDate = Date.today();

        upsertDatedRatesViaSessionId(isoToCorporatePer1Other, targetDate, corporateIso);
    }

    /** Явно записати у CurrencyType (без дат) через SessionId. */
    public static void applyRatesViaSessionIdToCurrencyType(List<RatesPayload> payloads) {
        if (payloads == null || payloads.isEmpty()) return;
        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();

        Map<String, Decimal> isoToCorporatePer1Other = new Map<String, Decimal>();
        for (RatesPayload p : payloads) {
            if (String.isBlank(p.otherISO) || !activeIsos.contains(p.otherISO)) continue;
            Decimal conv = (p.otherISO == corporateIso) ? 1 :
                           (p.rateToMainISO != null && p.rateToMainISO > 0 ? p.rateToMainISO : null); // <-- ФІКС
            if (conv != null && conv > 0) isoToCorporatePer1Other.put(p.otherISO, conv);
        }
        if (isoToCorporatePer1Other.isEmpty()) return;

        upsertCurrencyTypeRatesViaSessionId(isoToCorporatePer1Other, corporateIso);
    }

    // ============= Перевірка (опційно) =============

    /** Прев’ю в логах у попередньому форматі */
    public static void logPreview(List<RatesPayload> payloads, Integer limitRows) {
        if (payloads == null || payloads.isEmpty()) {
            System.debug('No rates to preview.');
            return;
        }
        Integer c = 0;
        for (RatesPayload rp : payloads) {
            System.debug(
                'mainISO: ' + rp.mainISO +
                ' / otherISO: ' + rp.otherISO +
                '  rate = ' + ((rp.rateToMainISO != null) ? rp.rateToMainISO.setScale(4) : null)
            );
            c++;
            if (limitRows != null && c >= limitRows) break;
        }
    }

    /** ISO корпоративної валюти */
    public static String getCorporateIso() {
        CurrencyType corporate = [
            SELECT IsoCode
            FROM CurrencyType
            WHERE IsCorporate = true
            LIMIT 1
        ];
        return corporate.IsoCode;
    }

    /** Сет активних валют ISO */
    public static Set<String> getActiveCurrencies() {
        Set<String> isoSet = new Set<String>();
        for (CurrencyType c : [
            SELECT IsoCode
            FROM CurrencyType
            WHERE IsActive = true
        ]) {
            isoSet.add(c.IsoCode);
        }
        return isoSet;
    }
    /***
        verifyLastRun() — сам тягне дату з НБУ (робить callout) і звіряє.
        verifyLastRun(Date onDate) — перевіряє конкретну дату без callout’у.
    ***/

    // --- Справдити останнє оновлення курсів ---
    public static void verifyLastRun() {
        // Спробуємо взяти дату з НБУ (робить callout)
        Date d = null;
        try {
            List<RatesPayload> pl = getNBURates();
            if (!pl.isEmpty()) d = pl[0].rateDate;
        } catch (Exception e) {
            d = Date.today();
            System.debug('verifyLastRun: NBU call failed, falling back to Today: ' + d + ' / ' + e.getMessage());
        }
        verifyLastRun(d);
    }

    public static void verifyLastRun(Date onDate) {
        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();
        Boolean acmEnabled = Schema.sObjectType.DatedConversionRate.isCreateable();

        // Очікувані значення з НБУ (у форматі OTHER per 1 MAIN)
        Map<String, Decimal> expectedCorporatePer1Other = new Map<String, Decimal>();
        try {
            List<RatesPayload> pl = getNBURates();
            if (!pl.isEmpty()) {
                Date nbuDate = pl[0].rateDate;
                if (onDate == null) onDate = nbuDate;

                for (RatesPayload p : pl) {
                    if (!activeIsos.contains(p.otherISO)) continue;
                    Decimal exp;
                    if (p.otherISO == corporateIso) exp = 1;
                    else if (p.rateToMainISO != null && p.rateToMainISO > 0)
                        exp = p.rateToMainISO; // <-- ФІКС: без інверсії
                    else continue;
                    expectedCorporatePer1Other.put(p.otherISO, exp.setScale(6));
                }
            }
        } catch (Exception e) {
            if (onDate == null) onDate = Date.today();
            System.debug('verifyLastRun: skip expected-from-NBU (reason: ' + e.getMessage() + ')');
        }
        if (onDate == null) onDate = Date.today();

        System.debug('--- VERIFY START ---');
        System.debug('Corporate: ' + corporateIso + ', ACM enabled: ' + acmEnabled + ', Date: ' + onDate);

        if (acmEnabled) {
            // Перевіряємо DatedConversionRate на конкретну дату
            List<DatedConversionRate> rows = [
                SELECT IsoCode, StartDate, ConversionRate, LastModifiedDate, LastModifiedBy.Name
                FROM DatedConversionRate
                WHERE StartDate = :onDate AND IsoCode IN :activeIsos
                ORDER BY IsoCode
            ];
            System.debug('DCR rows for ' + onDate + ': ' + rows.size());
            for (DatedConversionRate r : rows) {
                Decimal exp = expectedCorporatePer1Other.get(r.IsoCode);
                String cmp = (exp == null) ? '' :
                    ' | expected≈' + exp.setScale(6) + ' Δ=' + (r.ConversionRate - exp).setScale(6);
                System.debug(r.IsoCode + ' => ' + r.ConversionRate.setScale(6) +
                            ' (by ' + r.LastModifiedBy.Name + ' at ' + r.LastModifiedDate + ')' + cmp);
            }
            if (rows.isEmpty()) {
                AggregateResult[] ar = [SELECT MIN(StartDate) minD, MAX(StartDate) maxD FROM DatedConversionRate];
                System.debug('No DCR on ' + onDate + '. Available range: ' + ar[0].get('minD') + ' .. ' + ar[0].get('maxD'));
            }
        } else {
            // Перевіряємо звичайні CurrencyType (без дат)
            List<CurrencyType> rows = [
                SELECT IsoCode, ConversionRate, LastModifiedDate, LastModifiedBy.Name
                FROM CurrencyType
                WHERE IsActive = true
                ORDER BY IsoCode
            ];
            System.debug('CurrencyType rows: ' + rows.size());
            for (CurrencyType c : rows) {
                Decimal exp = expectedCorporatePer1Other.get(c.IsoCode);
                String cmp = (exp == null) ? '' :
                    ' | expected≈' + exp.setScale(6) + ' Δ=' + (c.ConversionRate - exp).setScale(6);
                System.debug(c.IsoCode + ' => ' + c.ConversionRate.setScale(6) +
                            ' (by ' + c.LastModifiedBy.Name + ' at ' + c.LastModifiedDate + ')' + cmp);
            }
        }
        System.debug('--- VERIFY END ---');
    }
    /*****
        Як запускати
    
        Автодата з НБУ (callout усередині):
        CurrencyRatesService.verifyLastRun();
    
        Або вказати даємо конкретну дату:
        CurrencyRatesService.verifyLastRun(Date.newInstance(2025, 8, 19));
    
        В логах: режим (ACM on/off), дата, рядки з фактичними курсами та (якщо вдалося підтягнути очікувані з НБУ) — очікуване значення й різниця Δ.
    *****/
    
    /** Парсер дати НБУ ("dd.MM.yyyy") */
    private static Date parseNbuDate(String ddMMyyyy) {
        if (String.isBlank(ddMMyyyy)) return Date.today();
        List<String> p = ddMMyyyy.split('\\.');
        if (p.size() != 3) return Date.today();
        return Date.newInstance(Integer.valueOf(p[2]), Integer.valueOf(p[1]), Integer.valueOf(p[0]));
    }

    // ============= REST-запис у Salesforce (через Named Credential) =============

    /** Оновити CurrencyType.ConversionRate через REST (ACM OFF, через NC) */
    private static void upsertCurrencyTypeRatesViaREST(Map<String, Decimal> isoToCorporatePer1Other, String corporateIso) {
        if (isoToCorporatePer1Other == null || isoToCorporatePer1Other.isEmpty()) return;

        Map<String, Id> iso2id = new Map<String, Id>();
        for (CurrencyType ct : [SELECT Id, IsoCode FROM CurrencyType WHERE IsActive = true]) {
            iso2id.put(ct.IsoCode, ct.Id);
        }

        for (String iso : isoToCorporatePer1Other.keySet()) {
            if (!iso2id.containsKey(iso)) continue;
            Decimal conv = (iso == corporateIso) ? 1 : isoToCorporatePer1Other.get(iso);
            if (conv == null || conv <= 0) continue;

            HttpRequest req = new HttpRequest();
            req.setMethod('PATCH');
            req.setEndpoint('callout:' + NC_SF_REST + '/services/data/' + API_VER + '/sobjects/CurrencyType/' + iso2id.get(iso));
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String,Object>{ 'ConversionRate' => conv }));

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() >= 300) {
                System.debug('CurrencyType PATCH failed for ' + iso + ': ' + res.getStatus() + ' ' + res.getBody());
            }
        }
    }

    /** Вставити/оновити DatedConversionRate через REST (ACM ON, через NC) */
    private static void upsertDatedRatesViaREST(Map<String, Decimal> isoToCorporatePer1Other, Date targetDate, String corporateIso) {
        if (isoToCorporatePer1Other == null || isoToCorporatePer1Other.isEmpty()) return;
        if (targetDate == null) targetDate = Date.today();

        List<String> isos = new List<String>(isoToCorporatePer1Other.keySet());
        Map<String, Id> iso2dcrId = new Map<String, Id>();
        for (DatedConversionRate d : [
            SELECT Id, IsoCode
            FROM DatedConversionRate
            WHERE StartDate = :targetDate AND IsoCode IN :isos
        ]) {
            iso2dcrId.put(d.IsoCode, d.Id);
        }

        for (String iso : isos) {
            // ❗ Пропускаємо corporate
            if (iso == corporateIso) continue;

            Decimal conv = isoToCorporatePer1Other.get(iso);
            if (conv == null || conv <= 0) continue;

            if (iso2dcrId.containsKey(iso)) {
                HttpRequest req = new HttpRequest();
                req.setMethod('PATCH');
                req.setEndpoint('callout:' + NC_SF_REST + '/services/data/' + API_VER + '/sobjects/DatedConversionRate/' + iso2dcrId.get(iso));
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String,Object>{ 'ConversionRate' => conv }));
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() >= 300) {
                    System.debug('DCR PATCH failed for ' + iso + ': ' + res.getStatus() + ' ' + res.getBody());
                }
            } else {
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('callout:' + NC_SF_REST + '/services/data/' + API_VER + '/sobjects/DatedConversionRate');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String,Object>{
                    'IsoCode'        => iso,
                    'StartDate'      => String.valueOf(targetDate),
                    'ConversionRate' => conv
                }));
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() >= 300) {
                    System.debug('DCR POST failed for ' + iso + ': ' + res.getStatus() + ' ' + res.getBody());
                }
            }
        }
    }

    // ============= Запис через поточний SessionId (без NC) =============

    /** Будуємо базову URL частину до REST API для поточної орги (через Org Domain) */
    private static String baseApiUrlViaSession() {
        String base = URL.getOrgDomainUrl().toExternalForm(); // напр.: https://interpipe--devsand.sandbox.my.salesforce.com
        if (!base.endsWith('/')) base += '/';
        return base + 'services/data/' + API_VER + '/';
    }

    /** Оновлюємо CurrencyType.ConversionRate через REST (ACM OFF, через поточний SessionId) */
    private static void upsertCurrencyTypeRatesViaSessionId(Map<String, Decimal> isoToCorporatePer1Other, String corporateIso) {
        if (isoToCorporatePer1Other == null || isoToCorporatePer1Other.isEmpty()) return;

        Map<String, Id> iso2id = new Map<String, Id>();
        for (CurrencyType ct : [SELECT Id, IsoCode FROM CurrencyType WHERE IsActive = true]) {
            iso2id.put(ct.IsoCode, ct.Id);
        }

        String base = baseApiUrlViaSession();
        String token = 'Bearer ' + UserInfo.getSessionId();

        for (String iso : isoToCorporatePer1Other.keySet()) {
            if (!iso2id.containsKey(iso)) continue;
            Decimal conv = (iso == corporateIso) ? 1 : isoToCorporatePer1Other.get(iso);
            if (conv == null || conv <= 0) continue;

            HttpRequest req = new HttpRequest();
            req.setMethod('PATCH');
            req.setEndpoint(base + 'sobjects/CurrencyType/' + iso2id.get(iso));
            req.setHeader('Authorization', token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String,Object>{ 'ConversionRate' => conv }));

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() >= 300) {
                System.debug('Session PATCH CurrencyType failed for ' + iso + ': ' + res.getStatus() + ' ' + res.getBody());
            }
        }
    }

    /** Вставити/оновити DatedConversionRate через REST (ACM ON, через поточний SessionId) */
    private static void upsertDatedRatesViaSessionId(Map<String, Decimal> isoToCorporatePer1Other, Date targetDate, String corporateIso) {
        if (isoToCorporatePer1Other == null || isoToCorporatePer1Other.isEmpty()) return;
        if (targetDate == null) targetDate = Date.today();

        List<String> isos = new List<String>(isoToCorporatePer1Other.keySet());
        Map<String, Id> iso2dcrId = new Map<String, Id>();
        for (DatedConversionRate d : [
            SELECT Id, IsoCode
            FROM DatedConversionRate
            WHERE StartDate = :targetDate AND IsoCode IN :isos
        ]) {
            iso2dcrId.put(d.IsoCode, d.Id);
        }

        String base = baseApiUrlViaSession();
        String token = 'Bearer ' + UserInfo.getSessionId();

        for (String iso : isos) {
            // ❗ DCR для corporate заборонений – пропускаємо
            if (iso == corporateIso) continue;

            Decimal conv = isoToCorporatePer1Other.get(iso);
            if (conv == null || conv <= 0) continue;

            if (iso2dcrId.containsKey(iso)) {
                HttpRequest req = new HttpRequest();
                req.setMethod('PATCH');
                req.setEndpoint(base + 'sobjects/DatedConversionRate/' + iso2dcrId.get(iso));
                req.setHeader('Authorization', token);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String,Object>{ 'ConversionRate' => conv }));
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() >= 300) {
                    System.debug('Session PATCH DCR failed for ' + iso + ': ' + res.getStatus() + ' ' + res.getBody());
                }
            } else {
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(base + 'sobjects/DatedConversionRate');
                req.setHeader('Authorization', token);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String,Object>{
                    'IsoCode'        => iso,
                    'StartDate'      => String.valueOf(targetDate),
                    'ConversionRate' => conv
                }));
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() >= 300) {
                    System.debug('Session POST DCR failed for ' + iso + ': ' + res.getStatus() + ' ' + res.getBody());
                }
            }
        }
    }
    
    // Повертає курси з ОРГ’а (DCR) у форматі, зручному для перевірки:
    // "скільки OTHER за 1 MAIN (corporate)" на зазначену дату.
    public static List<RatesPayload> getOrgRatesFromDcr(Date onDate) {
        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();
        if (onDate == null) onDate = Date.today();

        List<RatesPayload> out = new List<RatesPayload>();

        // MAIN->MAIN = 1
        out.add(new RatesPayload(corporateIso, corporateIso, onDate, 1));

        // Читаємо DCR: ConversionRate вже в форматі OTHER per 1 MAIN → без інверсії
        for (DatedConversionRate r : [
            SELECT IsoCode, StartDate, ConversionRate
            FROM DatedConversionRate
            WHERE StartDate = :onDate AND IsoCode IN :activeIsos
            ORDER BY IsoCode
        ]) {
            if (r.IsoCode == corporateIso) continue; // корпоративну пропускаємо (вона = 1)
            if (r.ConversionRate == null || r.ConversionRate <= 0) continue;

            Decimal otherPerMain = r.ConversionRate; // <-- ФІКС: без інверсії
            out.add(new RatesPayload(corporateIso, r.IsoCode, onDate, otherPerMain.setScale(4)));
        }
        return out;
    }

    // Швидкий прев’ю цих "людських" курсів із DCR у логах
    public static void previewDcrHuman(Date onDate, Integer limitRows) {
        List<RatesPayload> pl = getOrgRatesFromDcr(onDate);
        logPreview(pl, limitRows);
    }

    // Повертає курси з DCR, які є чинними станом на onDate (беремо останній StartDate <= onDate) 
    // у форматі "скільки OTHER за 1 MAIN (corporate)".
    public static List<RatesPayload> getOrgRatesFromDcrEffective(Date onDate) {
        if (onDate == null) onDate = Date.today();
        String corporateIso = getCorporateIso();
        Set<String> activeIsos = getActiveCurrencies();

        // Тягнемо всі записи до onDate, сортуємо так, щоб першим ішов найближчий
        List<DatedConversionRate> rows = [
            SELECT IsoCode, StartDate, ConversionRate
            FROM DatedConversionRate
            WHERE StartDate <= :onDate
              AND IsoCode IN :activeIsos
            ORDER BY IsoCode ASC, StartDate DESC
        ];

        // Залишаємо по одному запису на ISO (найсвіжіший <= onDate)
        Map<String, DatedConversionRate> latestPerIso = new Map<String, DatedConversionRate>();
        for (DatedConversionRate r : rows) {
            if (!latestPerIso.containsKey(r.IsoCode)) {
                latestPerIso.put(r.IsoCode, r);
            }
        }

        List<RatesPayload> out = new List<RatesPayload>();
        // MAIN→MAIN = 1
        out.add(new RatesPayload(corporateIso, corporateIso, onDate, 1));

        for (String iso : latestPerIso.keySet()) {
            if (iso == corporateIso) continue; // корпоративну не інвертуємо
            DatedConversionRate r = latestPerIso.get(iso);
            if (r.ConversionRate == null || r.ConversionRate <= 0) continue;

            // У DCR зберігається OTHER per 1 MAIN → показуємо як є
            Decimal otherPerMain = r.ConversionRate; // <-- ФІКС: без інверсії
            out.add(new RatesPayload(corporateIso, iso, r.StartDate, otherPerMain.setScale(4)));
        }
        return out;
    }

    // Зручний прев'ю у логах ефективних курсів на дату (людський формат)
    public static void previewDcrHumanEffective(Date onDate, Integer limitRows) {
        List<RatesPayload> pl = getOrgRatesFromDcrEffective(onDate);
        logPreview(pl, limitRows);
    }
}
/*
// 1) Свіжі курси з НБУ
List<CurrencyRatesService.RatesPayload> pl = CurrencyRatesService.getNBURates();

// 2) Оновити статичні курси (для Orders/OrderItems)
CurrencyRatesService.applyRatesViaSessionIdToCurrencyType(pl);

// 3) Якщо активовано ACM — оновити й Dated Rates (для Opportunities)
CurrencyRatesService.applyRatesViaSessionIdToDCR(pl);
 */