/*
    Оновлений клас ERPMessageHandlerOrderItemStage
    Cигнатури залишились ті самі, лише змінено внутрішню логіку
    -----------------------------------------------------------
    Written by O.Novykov, 04.12.2025
*/
public with sharing class ERPMessageHandlerOrderItemStage {
    /** Кеш адмін користувачів **/
    private static List<User> cachedAdmins;

    /** Кеш статусів з OrderItemStage__mdt */
    @TestVisible
    private static Map<String, String> cachedStatus;

    // Статичний ініціалізатор кешу статусів
    static {
        if (cachedStatus == null) {
            cachedStatus = SysUtils.getOrderItemStages();
        }
    }
    // Резет кешу статусів
    @TestVisible
    public static void resetCacheForTest() {
        cachedStatus = null;
    }

    /* ============================================================
       ADMIN HELPERS
       ============================================================ */
    // Адміни з групи AdminsForEmail
    public static List<User> getAdminUsers() {
        if (cachedAdmins == null) {
            cachedAdmins = [
                SELECT Id, Name, Email
                FROM User
                WHERE Id IN (
                    SELECT UserOrGroupId
                    FROM GroupMember
                    WHERE Group.DeveloperName = 'AdminsForEmail'
                )
            ];
        }
        return cachedAdmins;
    }

    private static List<String> getAdminEmails() {
        List<String> emails = new List<String>();
        for (User u : getAdminUsers()) {
            if (String.isNotBlank(u.Email)) {
                emails.add(u.Email);
            }
        }
        return emails;
    }
    //  Резет кешу адмінів
    @TestVisible
    public static void resetAdminCacheForTest() {
        cachedAdmins = null;
    }    
    /* ============================================================
       DTO (AS-IS)
       ============================================================ */
    public class MessageProcessingResult {
        public String messageType;
        public Integer numberOfUpdatedRecords = 0;
        public String idCancelledProduct = 'None';
        public Boolean isError = false;
        public String errorText = 'None';
    }

    /* ============================================================
       MAIN MESSAGE HANDLER (ASYNC-FRIENDLY)
       ============================================================ */
    public static MessageProcessingResult processMessage(
        ERPMessageParser.ErpToSfMessage_OrderItemStage parsedMessage,
        String requestBody
    ) {
        MessageProcessingResult res = new MessageProcessingResult();

        try {
            res.messageType = parsedMessage.metadata.MsgType;

            // ERP дані
            String erpOppId   = String.valueOf(parsedMessage.data.Undoc);
            String erpItemId  = String.valueOf(parsedMessage.data.Npp);
            String rawStage   = String.valueOf(parsedMessage.data.Stage);

            // ERP key = як в ID_ERP__c (Undoc-Npp)
            String erpKey = erpOppId + '-' + erpItemId;

            // Мапимо rawStage → SF-стадію
            String sfStage;
            Boolean isUnknown = false;

            if (cachedStatus != null && cachedStatus.containsKey(rawStage)) {
                sfStage = cachedStatus.get(rawStage);
            } else {
                sfStage = 'Processing'; // fallback
                isUnknown = true;
            }

            // Ніяких SOQL / DML по Opp/Order тут НЕ робимо
            // Лише кладемо запис у staging object
            OrderItemStageEvent__c evt = new OrderItemStageEvent__c();
            evt.ERP_Key__c           = erpKey;
            evt.ERP_Opportunity_Id__c = erpOppId;
            evt.ERP_Item_Id__c        = erpItemId;
            evt.Raw_Stage_Code__c     = rawStage;
            evt.SF_Stage__c           = sfStage;
            evt.Is_Unknown_Stage__c   = isUnknown;
            evt.Stage__c              = 'Pending';
            evt.Payload_JSON__c       = requestBody;

            insert evt;

            // Ми не знаємо, скільки реально оновиться записів потім,
            // але можемо сказати: "1 запис прийнято в чергу"
            res.numberOfUpdatedRecords = 1;

        } catch (Exception ex) {
            res.isError = true;
            res.errorText = ex.getMessage();
        }
        return res;
    }

    /* ============================================================
       RESPONSE JSON GENERATOR (AS-IS)
       ============================================================ */
    public static Blob generateResponseBody(
        Map<Integer, String> statusCodesMap,
        Integer statusCode,
        String error,
        MessageProcessingResult mpRes
    ) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('statusCode', statusCode);
        gen.writeStringField('status', statusCodesMap.get(statusCode));

        if (error == null) {
            gen.writeStringField('messageType', mpRes.messageType);
            gen.writeNumberField('updatedRecords', mpRes.numberOfUpdatedRecords);
            gen.writeStringField('cancelledProductId', mpRes.idCancelledProduct);
            gen.writeBooleanField('isError', mpRes.isError);
            gen.writeStringField('errorText', mpRes.errorText);
        } else {
            gen.writeStringField('errorMessage', error);
        }

        gen.writeEndObject();
        return Blob.valueOf(gen.getAsString());
    }

    /* ============================================================
       ADMIN EMAIL NOTIFIER — ТЕПЕР Є BULK-ВЕРСІЯ
       ============================================================ */
    // Старий метод (про всяк випадок, для сумісности)
    public static void sendEmailForAdministrators(String stageCodeIT) {
        if (String.isBlank(stageCodeIT)) return;
        Set<String> codes = new Set<String>{ stageCodeIT };
        sendEmailForAdministratorsBulk(codes);
    }

    // Нова bulk-версія емейл-нотифікатора для батчу
    public static void sendEmailForAdministratorsBulk(Set<String> stageCodesIT) {
        if (stageCodesIT == null || stageCodesIT.isEmpty()) return;

        List<String> adminEmails = getAdminEmails();
        if (adminEmails.isEmpty()) {
            System.debug('No admin emails found — skipping notification.');
            return;
        }

        String body = 'New Unknown Stages On Products:<br/><br/>';
        for (String codeIt : stageCodesIT) {
            body += codeIt + '<br/>';
        }

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.optOutPolicy = 'FILTER';
        msg.subject = 'New Unknown Stage On Product(s)';
        msg.htmlBody = body;
        msg.toAddresses = adminEmails;

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });
        } catch (Exception ex) {
            System.debug('Error sending admin email: ' + ex.getMessage());
        }
    }
}