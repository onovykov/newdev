/**
 * Централізований сервіс обробки помилок.
 * Використовує Error_Classification__mdt для визначення як обробляти помилку:
 * - Завжди створює Pharos Log через Triton
 * - Відправляє Notification тільки для Critical/High рівнів
 */
public with sharing class ErrorService {

    // Test injection для Error_Classification__mdt
    @TestVisible
    private static Map<String, Error_Classification__mdt> testErrorConfigs;

    /**
     * Головний метод обробки помилки.
     * @param errorKey - DeveloperName з Error_Classification__mdt
     * @param context - SObject контекст (Opportunity, Account, тощо)
     * @param e - Exception який виник
     */
    public static void handle(String errorKey, SObject context, Exception e) {
        handle(errorKey, context, e, null);
    }

    /**
     * Обробка помилки з додатковими змінними.
     * @param errorKey - DeveloperName з Error_Classification__mdt
     * @param context - SObject контекст
     * @param e - Exception
     * @param additionalVars - додаткові змінні для notification
     */
    public static void handle(
        String errorKey,
        SObject context,
        Exception e,
        Map<String, Object> additionalVars
    ) {
        if (String.isBlank(errorKey)) {
            System.debug('ErrorService: errorKey is blank, using GENERIC_ERROR');
            errorKey = 'GENERIC_ERROR';
        }

        // 1. Завантажити конфігурацію помилки
        Error_Classification__mdt errorCfg = getErrorConfig(errorKey);

        if (errorCfg == null) {
            System.debug(LoggingLevel.ERROR,
                'ErrorService: Error_Classification not found for key: ' + errorKey);
            // Fallback: логуємо напряму в Triton з визначенням area з контексту
            TritonTypes.Area fallbackArea = getFallbackArea(context);
            Triton.instance.error(fallbackArea, e);
            return;
        }

        // 2. Створити Pharos Log (ЗАВЖДИ)
        Id pharosLogId = null;
        try {
            pharosLogId = createPharosLog(errorCfg, context, e);
        } catch (Exception tritonEx) {
            System.debug(LoggingLevel.ERROR,
                'ErrorService: Failed to create Pharos log: ' + tritonEx.getMessage());
            // Продовжуємо далі навіть якщо Pharos не створився
        }

        // 3. Перевірити чи потрібна Notification
        String criticalLevel = safeTrim(errorCfg.CriticalLevel__c);

        if (!shouldSendNotification(criticalLevel)) {
            System.debug('ErrorService: CriticalLevel=' + criticalLevel +
                ', notification skipped (not Critical/High)');
            return;
        }

        // 3.1. Перевірка User_Type__c для Opportunity Owner
        // ВАЖЛИВО: Пропускаємо перевірку для технічних помилок (SYSTEM_CALLOUT)
        if (errorKey != 'SYSTEM_CALLOUT' && !shouldSendForUserType(context)) {
            System.debug('ErrorService: Opportunity Owner is not Sales Manager, notification skipped');
            return;
        }

        // 4. Якщо є Default Notification Event → відправити
        String notificationEventKey = safeTrim(errorCfg.Default_Notification_Event__c);

        if (String.isBlank(notificationEventKey)) {
            System.debug('ErrorService: No Default_Notification_Event__c, notification skipped');
            return;
        }

        // 5. Підготувати vars для notification
        Map<String, Object> vars = buildVars(e, pharosLogId, errorCfg, additionalVars);

        // 6. Відправити notification
        try {
            NotificationService.notify(notificationEventKey, context, vars);
        } catch (Exception notifEx) {
            System.debug(LoggingLevel.ERROR,
                'ErrorService: Notification failed: ' + notifEx.getMessage());
            // Не кидаємо exception далі - помилка вже залогована в Pharos
        }

        // 7. Перевірити чи потрібна ескалація (для SYSTEM_CALLOUT)
        if (shouldEscalate(errorKey)) {
            handleEscalation(errorKey, context, pharosLogId, errorCfg, vars);
        }
    }

    /**
     * Завантажує конфігурацію помилки з Error_Classification__mdt.
     */
    private static Error_Classification__mdt getErrorConfig(String errorKey) {
        // Test injection
        if (Test.isRunningTest() && testErrorConfigs != null && testErrorConfigs.containsKey(errorKey)) {
            return testErrorConfigs.get(errorKey);
        }

        try {
            return Error_Classification__mdt.getInstance(errorKey);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ErrorService: Error loading Error_Classification: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Визначає чи потрібно відправляти notification базуючись на CriticalLevel.
     * Notification відправляється ТІЛЬКИ для Critical і High.
     */
    private static Boolean shouldSendNotification(String criticalLevel) {
        if (String.isBlank(criticalLevel)) {
            return false;
        }

        String level = criticalLevel.toUpperCase();
        return (level == 'CRITICAL' || level == 'HIGH');
    }

    /**
     * Будує Map змінних для передачі в NotificationService.
     */
    private static Map<String, Object> buildVars(
        Exception e,
        Id pharosLogId,
        Error_Classification__mdt errorCfg,
        Map<String, Object> additionalVars
    ) {
        Map<String, Object> vars = new Map<String, Object>();

        // Exception дані
        if (e != null) {
            vars.put('exceptionMessage', e.getMessage());
            vars.put('exceptionType', e.getTypeName());
            vars.put('stackTrace', e.getStackTraceString());
        }

        // Pharos Log ID
        if (pharosLogId != null) {
            vars.put('pharosLogId', pharosLogId);
        }

        // Error Classification дані
        if (errorCfg != null) {
            vars.put('errorKey', errorCfg.ErrorKey__c);
            vars.put('category', errorCfg.Category__c);
            vars.put('subCategory', errorCfg.SubCategory__c);
            vars.put('area', errorCfg.Area__c);
            vars.put('areaType', errorCfg.AreaType__c);
            vars.put('criticalLevel', errorCfg.CriticalLevel__c);
            vars.put('reactTimeHours', errorCfg.ReactTimeHours__c);
        }

        // Додаткові змінні від caller
        if (additionalVars != null && !additionalVars.isEmpty()) {
            vars.putAll(additionalVars);
        }

        return vars;
    }

    /**
     * Створює Pharos log через Triton з мапінгом Error_Classification → Triton types.
     * Додає всю Error_Classification метадату в pharos__Log__c custom поля.
     */
    private static Id createPharosLog(
        Error_Classification__mdt errorCfg,
        SObject context,
        Exception e
    ) {
        // Мапити Area з Error_Classification на TritonTypes.Area
        TritonTypes.Area area = mapToTritonArea(errorCfg.Area__c);

        // Витягти related object IDs
        Set<String> relatedObjectIds = extractRelatedObjectIds(context);

        // Витягти DML Error Type (DUPLICATE_VALUE, DELETE_OPERATION_TOO_LARGE, тощо)
        String dmlErrorType = extractDmlErrorType(e);

        // Debug: показати що записуємо
        System.debug('ErrorService: Creating Pharos log with Error_Classification data:');
        System.debug('  Category: ' + errorCfg.Category__c);
        System.debug('  SubCategory: ' + errorCfg.SubCategory__c);
        System.debug('  ErrorKey: ' + errorCfg.ErrorKey__c);
        System.debug('  CriticalLevel: ' + errorCfg.CriticalLevel__c);
        System.debug('  ReactTimeHours: ' + errorCfg.ReactTimeHours__c);
        System.debug('  AreaType: ' + errorCfg.AreaType__c);
        System.debug('  DML_Error_Type: ' + dmlErrorType);

        // Створити pharos__Log__c через LogBuilder з повною Error_Classification метадатою
        pharos__Log__c log = Triton.makeBuilder()
            .category(TritonTypes.Category.Apex.name())
            .type(String.isBlank(e.getTypeName()) ? 'Backend' : e.getTypeName())
            .area(area.name())
            .summary(e.getMessage())
            .stackTrace(e.getStackTraceString())
            .details(String.valueOf(e) + '\n\n' + e.getStackTraceString())
            .attribute('pharos__Related_Objects__c',
                relatedObjectIds?.size() > 0 ? JSON.serialize(relatedObjectIds) : null)
            .attribute('Log_Level__c', 'ERROR')
            // Маркер що лог створений через ErrorService
            .attribute('Log_Source__c', 'ErrorService')
            // Маппінг Error_Classification → pharos__Log__c custom text поля
            .attribute('Error_Classification_Category__c', safeTrim(errorCfg.Category__c))
            .attribute('Error_Classification_SubCategory__c', safeTrim(errorCfg.SubCategory__c))
            .attribute('Error_Classification_ErrorKey__c', safeTrim(errorCfg.ErrorKey__c))
            .attribute('Error_Classification_CriticalLevel__c', safeTrim(errorCfg.CriticalLevel__c))
            .attribute('ReactTimeHours__c', errorCfg.ReactTimeHours__c)
            .attribute('Classification_AreaType__c', safeTrim(errorCfg.AreaType__c))
            .attribute('Error_Type__c', dmlErrorType)
            .createIssue()
            .build();

        // Debug: перевірити чи поля Error_Classification потрапили в об'єкт
        System.debug('ErrorService: Log built, checking Error_Classification fields:');
        System.debug('  Log_Source__c: ' + log.get('Log_Source__c'));
        System.debug('  Error_Classification_Category__c: ' + log.get('Error_Classification_Category__c'));
        System.debug('  Error_Classification_SubCategory__c: ' + log.get('Error_Classification_SubCategory__c'));
        System.debug('  Error_Classification_ErrorKey__c: ' + log.get('Error_Classification_ErrorKey__c'));
        System.debug('  Error_Classification_CriticalLevel__c: ' + log.get('Error_Classification_CriticalLevel__c'));
        System.debug('  ReactTimeHours__c: ' + log.get('ReactTimeHours__c'));
        System.debug('  Classification_AreaType__c: ' + log.get('Classification_AreaType__c'));

        // Для SYSTEM_CALLOUT - синхронний insert (щоб отримати Id для WhatId в Email Template)
        // Для інших помилок - через Triton Platform Events (асинхронно)
        if (errorCfg.ErrorKey__c == 'SYSTEM_CALLOUT') {
            System.debug('ErrorService: SYSTEM_CALLOUT detected, creating pharos__Log__c synchronously');
            insert log;
            System.debug('ErrorService: Pharos log created synchronously, Id: ' + log.Id);
        } else {
            System.debug('ErrorService: Adding to Triton buffer (async via Platform Events)');
            Triton.instance.add(log);
            System.debug('ErrorService: Flushing Triton buffer');
            Triton.instance.flush();
            System.debug('ErrorService: Pharos log queued via Platform Event, Id: ' + log.Id);
        }

        return log.Id;
    }

    /**
     * Мапить Area__c з Error_Classification на TritonTypes.Area enum.
     */
    private static TritonTypes.Area mapToTritonArea(String areaName) {
        if (String.isBlank(areaName)) {
            return TritonTypes.Area.OpportunityData; // default
        }

        // Спробувати знайти exact match в enum
        try {
            return TritonTypes.Area.valueOf(areaName.trim());
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'ErrorService: Unknown Area "' + areaName + '", using OpportunityData as default');
            return TritonTypes.Area.OpportunityData;
        }
    }

    /**
     * Витягує related object IDs з контексту для Pharos log.
     */
    private static Set<String> extractRelatedObjectIds(SObject context) {
        Set<String> ids = new Set<String>();

        if (context == null) {
            return ids;
        }

        // Додати Id контекстного запису
        try {
            Object contextId = context.get('Id');
            if (contextId != null) {
                ids.add(String.valueOf(contextId));
            }
        } catch (Exception e) {
            // Поле Id не queried або не існує
        }

        // Додати related IDs залежно від типу SObject
        try {
            if (context.getSObjectType() == Opportunity.SObjectType) {
                Opportunity opp = (Opportunity) context;
                if (opp.AccountId != null) {
                    ids.add(opp.AccountId);
                }
                if (opp.OwnerId != null) {
                    ids.add(opp.OwnerId);
                }
            } else if (context.getSObjectType() == Account.SObjectType) {
                Account acc = (Account) context;
                if (acc.OwnerId != null) {
                    ids.add(acc.OwnerId);
                }
            } else if (context.getSObjectType() == Lead.SObjectType) {
                Lead l = (Lead) context;
                if (l.OwnerId != null) {
                    ids.add(l.OwnerId);
                }
                if (l.ConvertedAccountId != null) {
                    ids.add(l.ConvertedAccountId);
                }
                if (l.ConvertedOpportunityId != null) {
                    ids.add(l.ConvertedOpportunityId);
                }
                if (l.ConvertedContactId != null) {
                    ids.add(l.ConvertedContactId);
                }
            } else if (context.getSObjectType() == Case.SObjectType) {
                Case c = (Case) context;
                if (c.AccountId != null) {
                    ids.add(c.AccountId);
                }
                if (c.ContactId != null) {
                    ids.add(c.ContactId);
                }
                if (c.OwnerId != null) {
                    ids.add(c.OwnerId);
                }
            } else if (context.getSObjectType() == Contact.SObjectType) {
                Contact con = (Contact) context;
                if (con.AccountId != null) {
                    ids.add(con.AccountId);
                }
                if (con.OwnerId != null) {
                    ids.add(con.OwnerId);
                }
            }
        } catch (Exception e) {
            // Поля не queried - ігноруємо
        }

        return ids;
    }

    /**
     * Перевіряє чи потрібно відправляти notification базуючись на User_Type__c Opportunity Owner.
     * Відправляємо ТІЛЬКИ якщо Owner є Sales Manager (або якщо context не Opportunity).
     */
    private static Boolean shouldSendForUserType(SObject context) {
        // Якщо немає контексту - дозволяємо відправку
        if (context == null) {
            return true;
        }

        // Перевіряємо тільки для Opportunity
        if (context.getSObjectType() != Opportunity.SObjectType) {
            return true;
        }

        // Витягуємо OwnerId з Opportunity
        Id ownerId = null;
        try {
            ownerId = (Id) context.get('OwnerId');
        } catch (Exception e) {
            // Поле не queried - дозволяємо відправку
            return true;
        }

        if (ownerId == null) {
            // Немає Owner - дозволяємо відправку
            return true;
        }

        // Завантажуємо User з User_Type__c
        User owner = getOwnerWithUserType(ownerId);
        if (owner == null) {
            // User не знайдений - дозволяємо відправку
            return true;
        }

        // Перевіряємо User_Type__c
        if (owner.User_Type__c != 'SALES MANAGERS') {
            // Owner НЕ Sales Manager - НЕ відправляємо notification
            return false;
        }

        // Owner є Sales Manager - відправляємо notification
        return true;
    }

    /**
     * Повертає User з полем User_Type__c.
     */
    private static User getOwnerWithUserType(Id userId) {
        if (userId == null) {
            return null;
        }
        List<User> users = [
            SELECT Id, User_Type__c
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
        return users.isEmpty() ? null : users[0];
    }

    /**
     * Витягує DML Error Type з Exception message для фільтрації.
     * Приклади: DUPLICATE_VALUE, DELETE_OPERATION_TOO_LARGE, UNABLE_TO_LOCK_ROW тощо.
     *
     * Обробляє формати:
     * - "first error: DELETE_OPERATION_TOO_LARGE, details..."
     * - "DUPLICATE_VALUE, details..."
     * - "UNABLE_TO_LOCK_ROW: details..."
     */
    private static String extractDmlErrorType(Exception e) {
        if (e == null) {
            return null;
        }

        String message = e.getMessage();
        if (String.isBlank(message)) {
            return null;
        }

        String errorType = null;

        String firstErrorMarker = 'first error: ';
        Integer firstErrorIndex = message.indexOf(firstErrorMarker);

        if (firstErrorIndex >= 0) {
            // Знайдено "first error:" - витягти error code після нього
            Integer startIndex = firstErrorIndex + firstErrorMarker.length();
            String afterFirstError = message.substring(startIndex);

            // Тепер витягти error code до коми, двокрапки або semicolon
            Integer commaIndex = afterFirstError.indexOf(',');
            Integer colonIndex = afterFirstError.indexOf(':');
            Integer semicolonIndex = afterFirstError.indexOf(';');

            Integer separatorIndex = -1;

            // Знайти найближчий роздільник
            if (commaIndex > 0) separatorIndex = commaIndex;
            if (colonIndex > 0 && (separatorIndex < 0 || colonIndex < separatorIndex)) {
                separatorIndex = colonIndex;
            }
            if (semicolonIndex > 0 && (separatorIndex < 0 || semicolonIndex < separatorIndex)) {
                separatorIndex = semicolonIndex;
            }

            if (separatorIndex > 0) {
                errorType = afterFirstError.substring(0, separatorIndex);
            } else {
                errorType = afterFirstError; // Якщо немає роздільників - весь текст
            }
        } else {
            // "first error:" не знайдено - використати стару логіку
            // DML помилки зазвичай мають формат: "ERROR_TYPE, details..." або "ERROR_TYPE: details..."
            errorType = message;

            // Шукаємо кому або двокрапку
            Integer commaIndex = message.indexOf(',');
            Integer colonIndex = message.indexOf(':');

            // Беремо найближчий роздільник
            Integer separatorIndex = -1;
            if (commaIndex > 0 && colonIndex > 0) {
                separatorIndex = Math.min(commaIndex, colonIndex);
            } else if (commaIndex > 0) {
                separatorIndex = commaIndex;
            } else if (colonIndex > 0) {
                separatorIndex = colonIndex;
            }

            if (separatorIndex > 0) {
                errorType = message.substring(0, separatorIndex);
            }
        }

        // Trim і uppercase
        errorType = safeTrim(errorType);
        if (String.isBlank(errorType)) {
            return null;
        }

        errorType = errorType.toUpperCase();

        // Обмежити до 255 символів (ліміт Text поля)
        if (errorType.length() > 255) {
            errorType = errorType.substring(0, 255);
        }

        return errorType;
    }

    /**
     * Безпечний trim для String.
     */
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }

    /**
     * Визначає fallback Area для Triton на основі SObject type контексту.
     */
    private static TritonTypes.Area getFallbackArea(SObject context) {
        if (context == null) {
            return TritonTypes.Area.OpportunityData;
        }

        String sObjectType = String.valueOf(context.getSObjectType());

        if (sObjectType == 'Opportunity') {
            return TritonTypes.Area.OpportunityData;
        } else if (sObjectType == 'Account') {
            return TritonTypes.Area.Accounts;
        } else if (sObjectType == 'Lead') {
            return TritonTypes.Area.LeadConversion;
        }

        return TritonTypes.Area.OpportunityData;
    }

    /**
     * Визначає чи потрібна ескалація для errorKey.
     * Наразі ескалація підтримується тільки для SYSTEM_CALLOUT.
     */
    private static Boolean shouldEscalate(String errorKey) {
        if (String.isBlank(errorKey)) {
            return false;
        }

        // Підтримуємо ескалацію тільки для SYSTEM_CALLOUT
        return errorKey == 'SYSTEM_CALLOUT';
    }

    /**
     * Знаходить першого активного User з UserRole = 'Help Desk Admin' для OwnerId Work Item.
     * @return User ID або null якщо не знайдено
     */
    private static Id resolveHelpdeskAdminUser() {
        List<User> helpdeskUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true AND UserRole.Name = 'Help Desk Admin'
            LIMIT 1
        ];
        return helpdeskUsers.isEmpty() ? null : helpdeskUsers[0].Id;
    }

    /**
     * Обробляє ескалацію помилки:
     * - Аналізує частоту через RecurringErrorAnalyzer
     * - Якщо помилка recurring (>= 3 рази за тиждень):
     *   - Створює Notification_Work_Item__c з інформацією про всі помилки
     *   - Відправляє escalation notification на HELPDESK_ADMIN (Contacts)
     *   - Throttling 48 годин запобігає spam
     */
    private static void handleEscalation(
        String errorKey,
        SObject context,
        Id pharosLogId,
        Error_Classification__mdt errorCfg,
        Map<String, Object> vars
    ) {
        System.debug('ErrorService: Checking escalation for errorKey=' + errorKey);

        // Аналізувати частоту помилки та дістати список всіх pharos logs
        RecurringErrorAnalyzer.AnalysisResult analysis = RecurringErrorAnalyzer.analyze(errorKey);

        if (!analysis.isRecurring) {
            System.debug('ErrorService: Error is not recurring (count=' + analysis.occurrenceCount + '), escalation skipped');
            return;
        }

        System.debug('ErrorService: Error IS recurring (' + analysis.occurrenceCount + ' occurrences), proceeding with escalation');

        // Додати дані аналізу в vars для Email Template
        vars.put('isRecurring', true);
        vars.put('occurrenceCount', analysis.occurrenceCount);
        vars.put('frequencyPerWeek', analysis.frequencyPerWeek);
        vars.put('oldestOccurrence', analysis.oldestOccurrence);
        vars.put('newestOccurrence', analysis.newestOccurrence);

        // Знайти Helpdesk Admin User для OwnerId Work Item
        Id helpdeskAdminUserId = resolveHelpdeskAdminUser();
        if (helpdeskAdminUserId == null) {
            System.debug(LoggingLevel.WARN,
                'ErrorService: No Helpdesk Admin User found, using current user as Work Item owner');
            helpdeskAdminUserId = UserInfo.getUserId();
        }

        // Створити Notification_Work_Item__c з інформацією про всі помилки
        Id workItemId = null;
        try {
            workItemId = WorkItemService.createWorkItem(
                errorKey,
                pharosLogId,
                helpdeskAdminUserId, // assigneeId = Helpdesk Admin User
                errorCfg.ReactTimeHours__c,
                vars,
                analysis.logs // Передаємо список всіх pharos__Log__c за період
            );
            System.debug('ErrorService: Work Item created for escalation, Id: ' + workItemId + ', Owner: ' + helpdeskAdminUserId);

            // Додати workItemId в vars для Email Template
            vars.put('workItemId', workItemId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ErrorService: Failed to create Work Item: ' + e.getMessage());
            // Продовжуємо відправку notification навіть якщо Work Item не створився
        }

        // Відправити escalation notification на HELPDESK_ADMIN (Contacts)
        // Використовуємо workItemId як WhatId для Email Template (щоб показати посилання та merge fields)
        // Throttling 2880 хвилин (48 годин) запобігає повторній відправці
        try {
            NotificationService.notify('SYSTEM_CALLOUT_ESCALATION', context, vars);
            System.debug('ErrorService: Escalation notification sent to HELPDESK_ADMIN with workItemId=' + workItemId);
        } catch (Exception notifEx) {
            System.debug(LoggingLevel.ERROR,
                'ErrorService: Escalation notification failed: ' + notifEx.getMessage());
        }
    }

}