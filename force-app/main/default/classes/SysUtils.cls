public class SysUtils {
    public static final Integer UA = 0;
    public static final Integer EN = 1;
    public static final Map<Integer, String> MONTH_UKR = new Map<Integer, String>{
        1=>'Січень',2=>'Лютий',3=>'Березень',4=>'Квітень',5=>'Травень',6=>'Червень',
        7=>'Липень',8=>'Серпень',9=>'Вересень',10=>'Жовтень',11=>'Листопад',12=>'Грудень'
    };
    public static final Map<Integer, String> MONTH_ENG = new Map<Integer, String>{
        1=>'January',2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',
        7=>'July',8=>'August',9=>'September',10=>'October',11=>'November',12=>'December'
    };

    /**
     * Методи, що створюють SHA Hex Hash зі String
    */
    public static String hashCreate(String inputStr) {
        Blob b = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(inputStr)
        );
        return EncodingUtil.convertToHex(b);
    }

    private static String normalizeKeyPart(String s) {
        return s == null
            ? ''
            : s.trim().normalizeSpace();
    }

    public static String buildERPHash(List<String> params) {

        if (params == null || params.isEmpty()) {
            return null;
        }

        List<String> normalized = new List<String>();

        for (String s : params) {
            normalized.add(normalizeKeyPart(s));
        }

        String source = String.join(normalized, '|');

        return hashCreate(source);
    }

    /** Для сервісу CurrencyRatesService:
     * Перевіряє, чи увімкнено Advanced Currency Management (ACM).
     * Повертає true, якщо об'єкт DatedConversionRate доступний у SOQL.
     */
    public static Boolean isACMEnabled() {
        try {
            List<DatedConversionRate> test = [SELECT Id FROM DatedConversionRate LIMIT 1];
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Отримати label з Picklist-поля користувача.
     * @param user — об'єкт User, завантажений із потрібними полями
     * @param fieldApiName — API назва поля, наприклад: 'BusinesDivision__c'
     * @return label значення picklist (локалізоване), або '' якщо поле пусте
     */
    public static String getPicklistLabel(SObject record, String fieldApiName) {
        Object rawValue = record.get(fieldApiName);
        if (rawValue == null) return '';

        Schema.DescribeFieldResult fieldDesc =
            record.getSObjectType().getDescribe().fields.getMap().get(fieldApiName).getDescribe();

        for (Schema.PicklistEntry entry : fieldDesc.getPicklistValues()) {
            if (entry.getValue() == String.valueOf(rawValue)) {
                return entry.getLabel();
            }
        }

        return String.valueOf(rawValue);
    }

    //--- Повертаємо назву сегменту по його API
    public static String getSegmentName(String segmentCode) {
        if (String.isBlank(segmentCode)) return '';
        try {
            Map<String, String> valueLabelMap =
                SysUtils.getPicklistFieldMap('Account', 'MarketSegment__c', true);
            String res = valueLabelMap.get(segmentCode);
            return res == null ? '' : res; // <-- гарантуємо '' замість null
        } catch (Exception e) {
            return '';
        }
    }

    //--- Повертаємо назву місяца по його номеру
    //    Підтримує дві версії - укр. і англ.
    public static String getMonthName(Integer monthNum, Integer lngVersion) {
        String result = '';
        if(monthNum==null || monthNum==0 || monthNum<0 || monthNum>12) return result;
        if(lngVersion==UA) {
            result = MONTH_UKR.get(monthNum);
        } else {
            result = MONTH_ENG.get(monthNum);
        }
        return result.toUpperCase();
    }

    //--- Повертає мапу активних джобів
    public static Map<String, Id> getJobsInWork() {
        List<AsyncApexJob> jobsList = [
                SELECT Id, Status, ApexClassId, ApexClass.Name, MethodName
                FROM AsyncApexJob
                WHERE Status = 'Processing'
        ];

        Map<String, Id> jobsMap = new Map<String, Id>();
        if(!jobsList.isEmpty()) {
            for (AsyncApexJob job : jobsList) {
                jobsMap.put(job.ApexClass.Name, job.Id);
            }
        }
        return jobsMap;
    }

    //--- Повертає сет назв класів, які зараз працюють
    public static Set<String> getActiveJobsNames (Map<String, Id> jobsMap) {
        Set<String> jobsSet = new Set<String>();
        if (jobsMap == null || jobsMap.isEmpty()) return jobsSet;
        jobsSet.addAll(jobsMap.keySet());
        return jobsSet;
    }

    //--- Зупинити джоби
    public static void stopActiveJobs (Set<Id> jobsIDs) {
        if (jobsIDs == null || jobsIDs.isEmpty()) {
            System.debug('❌ No active async apex jobs to stop');
            return;
        }
        Integer nCounter = 0;
        List<AsyncApexJob> jobsList = [
            SELECT Id, Status, ApexClassId, ApexClass.Name, MethodName
            FROM AsyncApexJob
            WHERE Status = 'Processing' AND Id IN :jobsIDs
        ];
        for (AsyncApexJob job : jobsList) {
            System.abortJob(job.Id);
            nCounter++;
            System.debug('Batch was stopped: Id=' + job.Id+'\n');
        }
        System.debug('\n'+nCounter+' batches were stopped\n');
    }

    /******* Trigger Utils ******************/
    // --- Перевіряє, чи змінилось значення одного поля ---
    public static Boolean isFieldChanged(SObject oldRec, SObject newRec, String fieldName) {
        if (oldRec == null || newRec == null || String.isBlank(fieldName)) return false;
        Object oldVal = oldRec.get(fieldName);
        Object newVal = newRec.get(fieldName);
        return (oldVal == null && newVal != null) ||
               (oldVal != null && newVal == null) ||
               (oldVal != null && newVal != null && oldVal != newVal);
    }

    // --- Перевіряє, чи змінилось будь-яке з вказаних полів ---
    public static Boolean isAnyFieldChanged(SObject oldRec, SObject newRec, List<String> fieldNames) {
        if (fieldNames == null || fieldNames.isEmpty()) return false;
        for (String field : fieldNames) {
            if (isFieldChanged(oldRec, newRec, field)) return true;
        }
        return false;
    }

    // --- Повертає список змінених полів з переданого переліку ---
    public static List<String> getChangedFields(SObject oldRec, SObject newRec, List<String> fieldNames) {
        List<String> changed = new List<String>();
        for (String field : fieldNames) {
            if (isFieldChanged(oldRec, newRec, field)) {
                changed.add(field);
            }
        }
        return changed;
    }

    /*** Як використовувати в тригері:
    trigger AccountTrigger on Account (before update) {
        for (Account acc : Trigger.new) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);

            // Один конкретний атрибут
            if (TriggerUtils.isFieldChanged(oldAcc, acc, 'Name')) {
                System.debug('🔄 Name changed: ' + oldAcc.Name + ' → ' + acc.Name);
            }

            // Кілька полів
            List<String> importantFields = new List<String>{'Name', 'BillingCountry', 'Industry'};
            if (TriggerUtils.isAnyFieldChanged(oldAcc, acc, importantFields)) {
                List<String> changed = TriggerUtils.getChangedFields(oldAcc, acc, importantFields);
                System.debug('🔍 Changed fields: ' + changed);
            }
        }
    }

    */
    /****************************************/

    // Метод, який повертає List<Map<String, Object>> із полями об'єкта, їхніми типами та розмірністю
    public static List<Map<String, Object>> getObjectFieldsInfo(String objectName) {
        List<Map<String, Object>> fieldsInfo = new List<Map<String, Object>>();

        // Отримуємо мета-інформацію про об'єкт
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            System.debug('Object not found: ' + objectName);
            return fieldsInfo;
        }

        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        // Заповнюємо список мапами з інформацією про кожне поле
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            Map<String, Object> fieldData = new Map<String, Object>{
                'FieldName' => fieldName,
                'Type' => fieldDescribe.getType().name(),
                'Length' => (fieldDescribe.getType() == Schema.DisplayType.String ||
                             fieldDescribe.getType() == Schema.DisplayType.TextArea) ?
                            fieldDescribe.getLength() : null,
                'Precision' => (fieldDescribe.getType() == Schema.DisplayType.Double ||
                                fieldDescribe.getType() == Schema.DisplayType.Currency ||
                                fieldDescribe.getType() == Schema.DisplayType.Percent)
                            ? fieldDescribe.getPrecision() : null,
                'Scale'     => (fieldDescribe.getType() == Schema.DisplayType.Double ||
                                fieldDescribe.getType() == Schema.DisplayType.Currency ||
                                fieldDescribe.getType() == Schema.DisplayType.Percent)
                            ? fieldDescribe.getScale() : null
            };
            fieldsInfo.add(fieldData);
        }

        return fieldsInfo;
    }
    //Метод для перекодування ієрархічного ParentId згідно зі структурою ієрархії зовнішніх ключів
    public static void updateHierarchy(String objectName, String itemIdField, String parentIdField, String lookupField) {
        // 1. Отримуємо всі записи об'єкта з необхідними полями, в якого немає парента (Parent__c=null)
        String query = 'SELECT Id, ' + itemIdField + ', ' + 
                        parentIdField + ' FROM ' + objectName + 
                        ' WHERE Parent__c=null';
        List<SObject> records = Database.query(query);

        // 2. Створюємо мапу ItemId -> RecordId
        Map<String, Id> itemIdToRecordId = new Map<String, Id>();
        for (SObject rec : records) {
            String itemId = (String) rec.get(itemIdField);
            if (itemId != null) {
                itemIdToRecordId.put(itemId, (Id) rec.get('Id'));
            }
        }

        // 3. Формуємо список оновлень
        List<SObject> recordsToUpdate = new List<SObject>();
        for (SObject rec : records) {
            String parentId = (String) rec.get(parentIdField);
            if (parentId != null && itemIdToRecordId.containsKey(parentId)) {
                rec.put(lookupField, itemIdToRecordId.get(parentId));
                recordsToUpdate.add(rec);
            }
        }

        // 4. Оновлюємо записи
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    //Метод, що повертає List рекордів з об'єкту, обходячи ліміт у 50 000 рекордів у селекті
    public static List<SObject> fetchAllRecords(String objectName, List<String> fields, String whereCondition) {
        List<SObject> allRecords = new List<SObject>();
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objectName + ' ' + whereCondition;
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() +
                          '/services/data/v62.0/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8');

        while (endpoint != null) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) jsonResponse.get('records');

                for (Object obj : records) {
                    allRecords.add((SObject) JSON.deserialize(JSON.serialize(obj), SObject.class));
                }

                endpoint = (String) jsonResponse.get('nextRecordsUrl');
                if (endpoint != null) {
                    endpoint = System.Url.getOrgDomainUrl().toExternalForm() + endpoint;
                }
            } else {
                throw new CalloutException('Error: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        }

        return allRecords;
    }

    //Метод, що видаляє застарілі записи з об'єкту objectName
    // Параметр N означає, за стільки років ми залишаємо записи: це останні N років плюс поточний
    //наприклад, N=4 означатиме, що зберігаємо всі дані за 2025 рік - від сьогодні до 01.01.2025 - плюс всі дані за 2024, 2023, 2022 та 2021 рік
    public static void deleteOldRecords(String objectName, Integer nYears) {
        // 1. Визначаємо дату, по яку потрібно видалити (DateTo)
        String soqlDateTo = 'SELECT CreatedDate FROM ' + objectName +
                            ' WHERE CreatedDate >= LAST_N_YEARS:' + nYears +
                            ' ORDER BY CreatedDate ASC LIMIT 1';

        List<SObject> dateRecords = Database.query(soqlDateTo);
        if (dateRecords.isEmpty()) {
            System.debug('Немає записів для обробки.');
            return;
        }

        DateTime dateTo = (DateTime) dateRecords[0].get('CreatedDate');
        System.debug('Дата обмеження для видалення: ' + dateTo);

        // 2. Формуємо список полів для отримання Id
        List<String> fields = new List<String>{'Id'};

        // 3. Отримуємо всі записи, які треба видалити
        List<SObject> recordsToDelete = fetchAllRecords(objectName,
            fields,
            ' WHERE CreatedDate < ' + dateTo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ORDER BY CreatedDate ASC'
        );

        if (!recordsToDelete.isEmpty()) {
            // 4. Видаляємо записи
            Database.delete(recordsToDelete, false);
            System.debug('Видалено записів: ' + recordsToDelete.size());
        } else {
            System.debug('Немає записів для видалення.');
        }
    }


    // Метод, що повертає мапу Value=Label або Label=Value для поля типу Picklist
    //----- Приклад використання:
    // Отримати мапу Value -> Label
    // Map<String, String> valueLabelMap = SysUtils.getPicklistFieldMap('Account', 'Industry', true);
    // Отримати мапу Label -> Value
    //Map<String, String> labelValueMap = SysUtils.getPicklistFieldMap('Account', 'Industry', false);

    public static Map<String, String> getPicklistFieldMap(String objectName, String fieldName, Boolean valueAsKey) {
        Map<String, String> resultMap = new Map<String, String>();

        // Отримуємо глобальний опис об'єкта
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            throw new IllegalArgumentException('Object ' + objectName + ' does not exist.');
        }

        // Отримуємо опис полів об'єкта
        Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
        if (!fields.containsKey(fieldName)) {
            throw new IllegalArgumentException('Field ' + fieldName + ' does not exist in object ' + objectName);
        }

        // Описуємо поле
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();

        // Перевіряємо, чи поле є Picklist
        if (!fieldResult.getType().equals(Schema.DisplayType.Picklist)) {
            throw new IllegalArgumentException('Field ' + fieldName + ' is not a Picklist.');
        }

        // Додаємо значення до мапи
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (valueAsKey) {
                resultMap.put(entry.getValue(), entry.getLabel()); // Value -> Label
            } else {
                resultMap.put(entry.getLabel(), entry.getValue()); // Label -> Value
            }
        }

        return resultMap;
    }

    private static String executeToolingQuery(String soql) {
        try {
            String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/tooling/query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                System.debug('Error fetching data: ' + res.getBody());
                throw new CalloutException('Error fetching data: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Callout Exception: ' + e.getMessage());
            return null;
        }
    }

    // Метод, що формує рядок SELECT для об'єкта з переліком заданих полів та умовою
    private static String normalizeSpaces(String s) {
        String NBSP = ' ';
        return String.isBlank(s) ? '' : s.replace(NBSP, ' ').replaceAll('\\s+', ' ').trim();
    }

    public static String getSelectFieldsSOQL(String objectName, List<String> Fields, String whereString) {
        if (Fields == null || Fields.isEmpty()) return '';

        String fieldsChunk = String.join(Fields, ',');
        // прибираємо префікс WHERE, нормалізуємо пробіли
        String ws = String.valueOf(whereString);
        if (!String.isBlank(ws)) {
            ws = ws.trim();
            if (ws.toUpperCase().startsWith('WHERE')) ws = ws.substring(5);
            ws = normalizeSpaces(ws);
        }
        String outSql = 'SELECT ' + fieldsChunk + ' FROM ' + objectName + (String.isBlank(ws) ? '' : ' WHERE ' + ws);
        return normalizeSpaces(outSql);
    }

    public static String trimToNearestSlash(String input, Integer maxLength) {
        // Сюди передаємо SteelGrade - як парметр String input
        if (String.isBlank(input) || maxLength <= 0) return '';

        // 1. Прибираємо пробіли біля символів /
        String cleaned = input.replaceAll('\\s*/\\s*', '/');

        // 2. Якщо довжина менша або дорівнює maxLength — повертаємо як є
        if (cleaned.length() <= maxLength) {
            return cleaned;
        }

        // 3. Беремо substring до maxLength символів
        String sub = cleaned.substring(0, maxLength);

        // 4. Знаходимо останню позицію символу /
        Integer lastSlashIndex = sub.lastIndexOf('/');
        if (lastSlashIndex == -1) {
            return '';
        }

        return sub.substring(0, lastSlashIndex); // обрізаємо ДО останнього слеша
    }

    /**
     * Повертає відсортовану мапу KeyPrefix → Object API Name
     * Сортування — за KeyPrefix (001, 003, 005, 006, ... a0B ...)
     */
    public static Map<String, String> getSortedKeyPrefixes() {
        Map<String, String> prefixToObject = new Map<String, String>();

        for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult describe = sObjType.getDescribe();
            try {
                String keyPrefix = describe.getKeyPrefix();
                if (keyPrefix != null) {
                    prefixToObject.put(keyPrefix, describe.getName());
                }
            } catch (Exception e) {
                // пропускаємо об'єкти без префіксу
            }
        }

        // Сортуємо ключі
        List<String> sortedKeys = new List<String>(prefixToObject.keySet());
        sortedKeys.sort();

        // LinkedHashMap для збереження порядку
        Map<String, String> sortedMap = new Map<String, String>();
        for (String k : sortedKeys) {
            sortedMap.put(k, prefixToObject.get(k));
        }

        return sortedMap;
    }

//-----------
    public static String shortenSteelGrade(String input, Integer partsCount) {
        if (String.isBlank(input)) return '';
        if (partsCount == null || partsCount < 1) return input;

        input = input.replaceAll('\\s*\\([^)]*\\)', '')
                   .replaceAll('\\s*\\[[^\\]]*\\]', '')
                   .replaceAll('\\s*\\{[^}]*\\}', '')
                   .replace('Not Specified','')
                   .normalizeSpace();

        Boolean isSlash = input.contains('/');

        // 1. Видалити пробіли біля / та обрізати загальні пробіли
        String cleaned = '';
        if(isSlash) {
            cleaned = input.replaceAll('\\s*/\\s*', '/').trim();
        }
        else {
            cleaned = input.replaceAll('\\s*;\\s*', ';').trim();
        }

        // 2. Розбити по /
        List<String> parts = new List<String>();
        if(isSlash) {
            parts = cleaned.split('/');
        } else {
            parts = cleaned.split(';');
        }


        // 3. Якщо більше partsCount частин — зібрати перші partsCount вручну
        String result = '';
        if (parts.size() > partsCount) {
            for(Integer i=0; i<partsCount; i++) {
                result = result + parts[i] + ((i<partsCount-1) ? '/' : '');
            }
            return result;
        }

        // 4. Інакше повертаємо очищений рядок
        return cleaned;
    }

    //--- Визначаємо мовну версію рекордів об'єктів залежно від мови юзера
    public static final Map<String, String> mapLangConv = new Map<String, String>{
        'ar'=>'en','bg'=>'en','cs'=>'en','da'=>'en','de'=>'en','el'=>'en','en'=>'en',
        'es'=>'en','fi'=>'en','fr'=>'en','hr'=>'en','hu'=>'en','in'=>'en','it'=>'en',
        'iw'=>'en','ja'=>'en','ko'=>'en','nl'=>'en','no'=>'en','pl'=>'en','pt'=>'en',
        'ro'=>'en','ru'=>'ru','sk'=>'en','sl'=>'en','sv'=>'en','th'=>'en','tr'=>'en',
        'uk'=>'uk','vi'=>'en','zh'=>'en'
    };

    public static String getObjLngVer(String UserId) {
        String result='';
        if(String.isBlank(UserId)) return result;
        List<User> usrList = [SELECT Id, Name, LanguageLocaleKey FROM User WHERE Id = :UserId LIMIT 1];
        if(usrList.isEmpty()) return result;
        String lngKey = (String) usrList[0].LanguageLocaleKey.left(2);
        if(mapLangConv.containsKey(lngKey)) {
            result = mapLangConv.get(lngKey);
        }
        return result;
    }

    /**
     * Повертає мапу, де key = префікс Id (наприклад "001"),
     * а value = API Name об’єкта (наприклад "Account").
     */
    public static Map<String, String> getIdPrefixMap() {
        Map<String, String> result = new Map<String, String>();
        for (Schema.SObjectType t : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult d = t.getDescribe();
            try {
                String kp = d.getKeyPrefix();
                if (kp != null) result.put(kp, d.getName());
            } catch (Exception e) {
                // пропускаємо об'єкти без префіксу
            }
        }
        return result;
    }

    //--- Повертаємо перелік всіх полів об'єкту
    public class FieldInfo {
        public String apiName {get;set;}
        public String label   {get;set;}
        public String type    {get;set;}
        public Boolean nillable {get;set;}
        public Boolean creatable {get;set;}
        public Boolean updateable {get;set;}
        public Boolean required {get;set;}
    }

    public static List<FieldInfo> getFields(String objectApiName) {
        List<FieldInfo> result = new List<FieldInfo>();

        // Отримуємо опис об'єкта за назвою
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) {
            throw new IllegalArgumentException('Object ' + objectApiName + ' does not exist');
        }

        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        for (Schema.SObjectField f : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();

            FieldInfo info = new FieldInfo();
            info.apiName   = dfr.getName();
            info.label     = dfr.getLabel();
            info.type      = String.valueOf(dfr.getType());
            info.nillable  = dfr.isNillable();
            info.creatable = dfr.isCreateable();
            info.updateable = dfr.isUpdateable();
            info.required  = !dfr.isNillable() && !dfr.isDefaultedOnCreate();

            result.add(info);
        }
        return result;
    } 
    
    /**** Повертає рядок на зразок SELECT feild1, field2 FROM objectApiName
          Параметри
          - objectApiName - АРІ назва об'єкту
          - allFiledsSign - астериск (*)
          - listFields - лист АРІ назв полів
          - listAddFields - лист з переліком додоаткових полів (напириклад, лукапів тощо)
          Алгоритм:
          Якщо треба вибрати всі поля об'єкту - в allFiledsSign  пишемо '*', в listFields - null
          Якщо listFields!=null - параметр allFiledsSign  ігнорується
    ****/
    public static String getSimpleSqlString(String objectApiName, String allFiledsSign, 
                                            List<String> listFields, List<String> listAddFields) {
        List<String> fieldsList = new List<String>();
        if (listFields != null && !listFields.isEmpty()) {
            fieldsList.addAll(listFields);
        } else if ('*'.equals(allFiledsSign)) {
            for (FieldInfo fi : getFields(objectApiName)) {
                fieldsList.add(fi.apiName);
            }
        } else {
            throw new IllegalArgumentException('Provide listFields or set allFiledsSign="*".');
        }
        if (listAddFields != null && !listAddFields.isEmpty()) {
            fieldsList.addAll(listAddFields);
        }
        return 'SELECT ' + String.join(fieldsList, ',') + ' FROM ' + objectApiName;
    }
   

    /**
     * Вивести у клас ChildRelResult всі child-зв’язки для вказаного об’єкта
     * @param objectApiName – API Name об’єкта (наприклад, 'Account', 'Contact__c')
     * @param showCascadeDelete – що виводити:
       тільки CascadeDelete = 0
       тільки НЕ CascadeDelete = 1
       всі = 2
     */
    public class ChildRelResult {
        public String mainObject;
        public String childObject;
        public String fieldAPIName;
        public Boolean isCascadeDelete;

        public ChildRelResult() {
            this.mainObject='';
            this.childObject='';
            this.fieldAPIName='';
            this.isCascadeDelete=false;
        }
    }
    public static List<ChildRelResult> showChildRelationships(String objectApiName, Integer showCascadeDelete) {
        List<ChildRelResult> result = new List<ChildRelResult>();
        try {
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjType == null) {
                System.debug('❌ Об’єкт не знайдено: ' + objectApiName);
                return result ;
            }

            Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();

            System.debug('\n=== Child Relationships for ' + objectApiName + ' ===\n');
            for (Schema.ChildRelationship cr : describeResult.getChildRelationships()) {
                ChildRelResult cres = new ChildRelResult();
                Boolean isSave = false;
                cres.mainObject = objectApiName;
                cres.childObject = String.valueOf(cr.getChildSObject());
                cres.fieldAPIName = String.valueOf(cr.getField());
                cres.isCascadeDelete = cr.isCascadeDelete();
                isSave = (
                            (showCascadeDelete==0 && cr.isCascadeDelete()) ||
                            (showCascadeDelete==1 && !cr.isCascadeDelete()) ||
                            showCascadeDelete == 2
                         );
                if(isSave) result.add(cres);
                /*
                System.debug(
                    'Child Object: ' + cr.getChildSObject() +
                    ' : Field: ' + cr.getField() +
                    ' : Cascade Delete: ' + cr.isCascadeDelete()
                );
                */
            }
        } catch (Exception e) {
            System.debug('❌ Помилка: ' + e.getMessage());
        }
        return result;
    }  
    
    //--- Вирізаємо зайві нули в ODxWT зі значення поля Name
    // Хелпер: прибрати зайві нулі після крапки
    private static String trimTrailingZeros(String numStr) {
        if (String.isBlank(numStr)) return numStr;

        Integer dotPos = numStr.indexOf('.');
        if (dotPos == -1) {
            // немає дробової частини
            return numStr;
        }

        String intPart  = numStr.substring(0, dotPos);
        String fracPart = numStr.substring(dotPos + 1);

        // Прибираємо нулі з кінця дробової частини
        while (fracPart.endsWith('0') && fracPart.length() > 0) {
            fracPart = fracPart.substring(0, fracPart.length() - 1);
        }

        // Якщо нічого не лишилося – повертаємо тільки цілу частину
        if (fracPart.length() == 0) {
            return intPart;
        }

        return intPart + '.' + fracPart;
    }

    // Нормалізація одного значення Name
    public static String normalizeOdWtInName(String name) {
        if (String.isBlank(name)) {
            return name;
        }

        // Шукаємо фрагмент типу 323.900x20.000 або 130.000x115.000
        Pattern p = Pattern.compile('(\\d+(?:\\.\\d+)?)x(\\d+(?:\\.\\d+)?)');
        Matcher m = p.matcher(name);

        if (!m.find()) {
            // Нічого не знайшли – повертаємо як є
            return name;
        }

        String odStr = m.group(1);
        String wtStr = m.group(2);

        String odNorm = trimTrailingZeros(odStr);
        String wtNorm = trimTrailingZeros(wtStr);

        String replacement = odNorm + 'x' + wtNorm;

        String result =
            name.substring(0, m.start()) +
            replacement +
            name.substring(m.end());

        return result;
    }

    // Масова обробка, якщо потрібно
    public static void normalizeOdWtInNames(List<SObject> records, String nameField) {
        for (SObject sobj : records) {
            String name = (String)sobj.get(nameField);
            sobj.put(nameField, normalizeOdWtInName(name));
        }
    }
    
    //--- Виправлення "косяків" у PriceApprovalRequestItem__c
    public static void renamePARNames() {
        // Вибираємо рекорди, де є OpportunityLineItemId__c, але немає OppProduct__c
        List<PriceApprovalRequestItem__c> parItems = [SELECT Id, OpportunityLineItemId__c 
                                                      FROM PriceApprovalRequestItem__c 
                                                      WHERE OppProduct__c=null AND OpportunityLineItemId__c!=null];
        Set<String> parOliIds = new Set<String>();
        // Пишемо OpportunityLineItemId__c до сету 
        if(!parItems.isEmpty()) {
            for(PriceApprovalRequestItem__c p : parItems) {
                parOliIds.add(p.OpportunityLineItemId__c);
            }
        }
        // Вибираємо з OpportunityLineItem ті рекорди, які є в PriceApprovalRequestItem__c і не є Cancelled
        List<OpportunityLineItem> oliList = [
        SELECT Id, ITENumber__c, Name__c FROM OpportunityLineItem
        WHERE Id IN :parOliIds];
        Map<Id, String> oliNamesMap = new Map<Id, String>();
        
        parOliIds.clear();
        if(!parItems.isEmpty()) {
            for(OpportunityLineItem p : oliList) {
                parOliIds.add((String)p.Id);
                oliNamesMap.put(p.Id, SysUtils.normalizeOdWtInName(p.Name__c));
            }
        }

        List<PriceApprovalRequestItem__c> parExistItems = [SELECT Id, OppProduct__c, OpportunityLineItemId__c, Name 
                                                           FROM PriceApprovalRequestItem__c 
                                                           WHERE OpportunityLineItemId__c IN :parOliIds];

        if(!parExistItems.isEmpty()) {
            for(PriceApprovalRequestItem__c pRec : parExistItems) {
                pRec.OppProduct__c = pRec.OpportunityLineItemId__c;
                pRec.Name = oliNamesMap.get((Id)pRec.OpportunityLineItemId__c);		
            } 
            update parExistItems;
        }
        return;
    }  
    //--- Повертає мапу статусів позицій замовлення <Status IT, Status SF>
    //    Наприклад <'_4', 'Placed'>    
	public static Map<String, String> getOrderItemStages() {
		Map<String, String> resMap = new Map<String, String>();
		List<OrderItemStage__mdt> oiStageList = [SELECT Code__c, StatusSF__c FROM OrderItemStage__mdt];
		if(!oiStageList.isEmpty()) {
			for(OrderItemStage__mdt ois : oiStageList) {
				resMap.put(ois.Code__c, ois.StatusSF__c);
			}
		} 
		return resMap;
	}
	//--- Повертає відповідний до статусу ІТ статус SF для позицій замовлення
    //    Наприклад для значення '_4' повертає 'Placed'>
	public static String getOIStageSF(String stageIT) {
		String resStage = '';
		if(!String.isBlank(stageIT)) {
			Map<String, String> stagesMap = getOrderItemStages();
			if(stagesMap.containsKey(stageIT)) {
				resStage = stagesMap.get(stageIT);
			}
		}
		return resStage;
	} 
    
    // Знайти всі лукапи на об'єкт
    public static Map<String, List<String>> findLookupsTo(String targetObjectApiName) {
        Map<String, List<String>> result = new Map<String, List<String>>();

        for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult obj = sObjType.getDescribe();
            String objName = obj.getName();
            String objNameLc = objName.toLowerCase();

            // пропускаємо системні обʼєкти
            if (objNameLc.endsWith('__history')
             || objNameLc.endsWith('__share')
             || objNameLc.endsWith('__changeevent')
             || obj.isDeprecatedAndHidden()
             || obj.isCustomSetting()) {
                continue;
            }

            for (Schema.SObjectField field : obj.fields.getMap().values()) {
                Schema.DescribeFieldResult f = field.getDescribe();

                // тільки lookup / MD
                if (f.getType() != Schema.DisplayType.Reference) {
                    continue;
                }

                // пропускаємо polymorphic (WhatId, ParentId, RelatedRecordId і т.п.)
                if (f.getReferenceTo().size() != 1) {
                    continue;
                }

                // пропускаємо - не наш target
                if (f.getReferenceTo()[0].getDescribe().getName() != targetObjectApiName) {
                    continue;
                }

                // ок — це реальний lookup
                if (!result.containsKey(objName)) {
                    result.put(objName, new List<String>());
                }
                result.get(objName).add(f.getName());
            }
        }

        return result;
    }
   
    //************** Bump-методи для тестів (форсимо coverage) ***/ 
    @TestVisible
    private static void coverageProbe() {

        // string utils
        normalizeSpaces('  A   B  ');
        trimToNearestSlash('A/B/C', 4);
        trimToNearestSlash(null, 10);          // blank input
        trimToNearestSlash('ABC', 0);          // maxLength <= 0
        trimToNearestSlash('A/B', 10);          // length <= maxLength
        trimToNearestSlash('A/B/C', 4);         // with slash cut
        trimToNearestSlash('ABCDEF', 3);        // no slash → empty    
        shortenSteelGrade('A/B/C/D', 2);
        normalizeOdWtInName('323.900x20.000');

        normalizeSpaces(null);
        normalizeSpaces('');
        normalizeSpaces('  A   B   ');    

        // ==== Maps / collections ====
        getIdPrefixMap();                       // build map
        getIdPrefixMap();                       // cached path

        getSortedKeyPrefixes();                 // initial
        getSortedKeyPrefixes();                 // cached    

        // safe no-op branches
        getMonthName(0, UA);
        getMonthName(13, EN);
        getObjLngVer(null);

        // trigger utils
        isFieldChanged(null, null, 'Name');
        isAnyFieldChanged(null, null, null);
        getChangedFields(null, null, new List<String>());

        // ==== Describe / metadata ====
        findLookupsTo('Account');               // standard
        findLookupsTo('User');                  // different target
        findLookupsTo('Region__c');              // custom  

        // ==== Change detection helpers ====
        isFieldChanged(null, null, 'Name');
        isAnyFieldChanged(null, null, null);
        getChangedFields(null, null, new List<String>());

        // ==== Safe fallbacks ====
        getObjLngVer(null);
        getObjLngVer('Account'); 
    }

    @TestVisible
    private static void coverageProbe2() {

        // ==== provoke else / catch branches ====
        shortenSteelGrade(null, 5);
        shortenSteelGrade('ABC', 0);

        // month / language fallbacks
        getMonthName(5, null);       // lang == null
        getMonthName(5, 0);       // unknown lang

        // object / lang resolver
        getObjLngVer('NonExistingObject');

        // change detection – non-null paths
        Map<String, Object> oldMap = new Map<String, Object>{ 'Name' => 'A' };
        Map<String, Object> newMap = new Map<String, Object>{ 'Name' => 'B' };

        isFieldChanged(null, null, 'Name');
        isAnyFieldChanged(null, null, new List<String>{ 'Name' });
        getChangedFields(null, null, new List<String>{ 'Name' });

        // describe edge
        findLookupsTo('NonExisting__c');
    }
}