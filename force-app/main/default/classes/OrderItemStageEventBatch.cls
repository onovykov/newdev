/*
    Batch Apex: OrderItemStageEventBatch
    Пакетне оновлення статусів, змінених у ERPMessageHandlerOrderItemStage

    Цей клас:
    - бере всі Pending з OrderItemStageEvent__c
    - масово тягне OLI + OrderItem по ID_ERP__c
    - оновлює стадії
    - оновлює статуси подій
    - накопичує невідомі стадії, і в finish() надсилає один лист

    Written by O.Novykov, 04.12.2025
*/
global class OrderItemStageEventBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // Накопичуємо всі невідомі коди стадій по всьому батчу
    global Set<String> unknownStageCodes = new Set<String>();

    /*
      Пояснення по полю Stage__c в об'єкті OrderItemStageEvent__c — службові стани черги
      -------------------------------------------------------------------------------------------------
      Статус    | Значення                             | Коли ставиться                      | Хто ставить
      -------------------------------------------------------------------------------------------------
      Pending   | Подія в черзі, очікує обробки        | Одразу після приходу JSON           | processMessage()
      -------------------------------------------------------------------------------------------------
      Processed | Подію оброблено успішно              | Після оновлення Stage__c в          | Batch Apex
                |                                      | OpportunityLineItem / OrderItem     |
      -------------------------------------------------------------------------------------------------
      Failed    | Обробка не вдалася                   | В разі exception, відсутності       | Batch Apex
                |                                      | відповідних записів або DML-помилки |
      -------------------------------------------------------------------------------------------------
    */

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Тягнемо тільки Pending, не чіпаємо Processed/Failed
        // LIMIT для безпеки, аби не тягнути мільйони записів за один прогін
        return Database.getQueryLocator([
            SELECT Id,
                   ERP_Key__c,
                   ERP_Opportunity_Id__c,
                   ERP_Item_Id__c,
                   Raw_Stage_Code__c,
                   SF_Stage__c,
                   Is_Unknown_Stage__c,
                   Stage__c,
                   Error_Message__c
            FROM OrderItemStageEvent__c
            WHERE Stage__c = 'Pending'
            ORDER BY CreatedDate
            LIMIT 50000
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<OrderItemStageEvent__c> events = (List<OrderItemStageEvent__c>)scope;

        if (events.isEmpty()) {
            return;
        }

        // 1) Збираємо всі валідні ERP Keys, паралельно відмічаємо зовсім биті події (порожній ключ)
        Set<String> erpKeys = new Set<String>();
        for (OrderItemStageEvent__c evt : events) {
            if (String.isBlank(evt.ERP_Key__c)) {
                evt.Stage__c = 'Failed';
                evt.Error_Message__c = 'Empty ERP_Key__c';
            } else {
                erpKeys.add(evt.ERP_Key__c);
            }
        }

        if (erpKeys.isEmpty()) {
            // Нема жодного валідного ключа — просто фіксуємо Failed, що вже проставлений вище
            Database.update(events, false);
            return;
        }

        // 2) Масовий SOQL по OpportunityLineItem
        Map<String, List<OpportunityLineItem>> oliByErp = new Map<String, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT Id, Stage__c, Is_Placed__c, Cancelled__c, ID_ERP__c
            FROM OpportunityLineItem
            WHERE ID_ERP__c IN :erpKeys
        ]) {
            if (String.isNotBlank(oli.ID_ERP__c)) {
                List<OpportunityLineItem> listForKey = oliByErp.get(oli.ID_ERP__c);
                if (listForKey == null) {
                    listForKey = new List<OpportunityLineItem>();
                    oliByErp.put(oli.ID_ERP__c, listForKey);
                }
                listForKey.add(oli);
            }
        }

        // 3) Масовий SOQL по OrderItem
        Map<String, List<OrderItem>> oiByErp = new Map<String, List<OrderItem>>();
        for (OrderItem oi : [
            SELECT Id, Stage__c, Is_Placed__c, Cancelled__c, ID_ERP__c
            FROM OrderItem
            WHERE ID_ERP__c IN :erpKeys
        ]) {
            if (String.isNotBlank(oi.ID_ERP__c)) {
                List<OrderItem> listForKey = oiByErp.get(oi.ID_ERP__c);
                if (listForKey == null) {
                    listForKey = new List<OrderItem>();
                    oiByErp.put(oi.ID_ERP__c, listForKey);
                }
                listForKey.add(oi);
            }
        }

        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        List<OrderItem> oiToUpdate = new List<OrderItem>();

        // Щоб не додати один і той самий запис у список кілька разів
        Set<Id> oliAdded = new Set<Id>();
        Set<Id> oiAdded  = new Set<Id>();

        // Для контролю DML-результатів
        Map<String, Boolean> keyHasTargets   = new Map<String, Boolean>(); // key → true, якщо були OLI/OrderItem
        Map<String, Boolean> keyHadDmlError  = new Map<String, Boolean>(); // key → true, якщо були DML-помилки
        Map<String, String>  keyErrorMessage = new Map<String, String>();  // key → перша DML-помилка

        // 4) Проходимо по всіх events, готуємо апдейти, але статус Processed/Failed для "знайдених" поки не ставимо
        for (OrderItemStageEvent__c evt : events) {

            // Якщо ми вже позначили event як Failed вище (порожній ключ) — пропускаємо іншу логіку
            if (evt.Stage__c == 'Failed') {
                continue;
            }

            String key   = evt.ERP_Key__c;
            String stage = evt.SF_Stage__c;

            List<OpportunityLineItem> oliList = oliByErp.get(key);
            List<OrderItem>           oiList  = oiByErp.get(key);

            Boolean hasAny = false;

            if (oliList != null && !oliList.isEmpty()) {
                hasAny = true;
                for (OpportunityLineItem oli : oliList) {
                    // Останнє значення stage в межах scope для певного ключа "перемагає"
                    oli.Stage__c     = stage;
                    oli.Is_Placed__c = (stage == 'Placed');
                    oli.Cancelled__c = (stage == 'Cancelled');

                    if (!oliAdded.contains(oli.Id)) {
                        oliAdded.add(oli.Id);
                        oliToUpdate.add(oli);
                    }
                }
            }

            if (oiList != null && !oiList.isEmpty()) {
                hasAny = true;
                for (OrderItem oi : oiList) {
                    oi.Stage__c     = stage;
                    oi.Is_Placed__c = (stage == 'Placed');
                    oi.Cancelled__c = (stage == 'Cancelled');

                    if (!oiAdded.contains(oi.Id)) {
                        oiAdded.add(oi.Id);
                        oiToUpdate.add(oi);
                    }
                }
            }

            if (hasAny) {
                keyHasTargets.put(key, true);
                // Статус поки не чіпаємо — визначимо після DML
            } else {
                evt.Stage__c = 'Failed';
                evt.Error_Message__c = 'No related OpportunityLineItem/OrderItem found for key ' + key;
            }

            // Збираємо unknown-stage коди для finish()
            if (evt.Is_Unknown_Stage__c == true && !String.isBlank(evt.Raw_Stage_Code__c)) {
                unknownStageCodes.add(evt.Raw_Stage_Code__c);
            }
        }

        // 5) Масові DML з partial processing, без exception
        if (!oliToUpdate.isEmpty()) {
            Database.SaveResult[] oliResults = Database.update(oliToUpdate, false);
            for (Integer i = 0; i < oliResults.size(); i++) {
                if (!oliResults[i].isSuccess()) {
                    String key = oliToUpdate[i].ID_ERP__c;
                    keyHadDmlError.put(key, true);
                    if (!keyErrorMessage.containsKey(key) && oliResults[i].getErrors().size() > 0) {
                        keyErrorMessage.put(key, oliResults[i].getErrors()[0].getMessage());
                    }
                }
            }
        }

        if (!oiToUpdate.isEmpty()) {
            Database.SaveResult[] oiResults = Database.update(oiToUpdate, false);
            for (Integer i = 0; i < oiResults.size(); i++) {
                if (!oiResults[i].isSuccess()) {
                    String key = oiToUpdate[i].ID_ERP__c;
                    keyHadDmlError.put(key, true);
                    if (!keyErrorMessage.containsKey(key) && oiResults[i].getErrors().size() > 0) {
                        keyErrorMessage.put(key, oiResults[i].getErrors()[0].getMessage());
                    }
                }
            }
        }

        // 6) Фінальний прохід по events — виставляємо Processed / Failed
        for (OrderItemStageEvent__c evt : events) {

            // Якщо вже Failed (порожній ключ або відсутні targets) — не чіпаємо
            if (evt.Stage__c == 'Failed') {
                continue;
            }

            String key = evt.ERP_Key__c;

            // Якщо для цього ключа взагалі не було знайдено жодних таргетів —
            // теоретично не повинно статись, але на всякий випадок:
            if (!keyHasTargets.containsKey(key)) {
                evt.Stage__c = 'Failed';
                if (String.isBlank(evt.Error_Message__c)) {
                    evt.Error_Message__c = 'No related records found or inconsistent state.';
                }
                continue;
            }

            // Якщо були DML-помилки по будь-якому з пов'язаних записів
            if (keyHadDmlError.containsKey(key) && keyHadDmlError.get(key) == true) {
                evt.Stage__c = 'Failed';
                String msg = keyErrorMessage.get(key);
                if (!String.isBlank(msg)) {
                    evt.Error_Message__c = msg;
                } else if (String.isBlank(evt.Error_Message__c)) {
                    evt.Error_Message__c = 'DML error while updating related records.';
                }
            } else {
                // Успішний апдейт усіх пов'язаних записів
                evt.Stage__c = 'Processed';
                evt.Error_Message__c = null;
            }
        }

        // 7) Оновлюємо самі event-записи (partial)
        Database.update(events, false);
    }

    global void finish(Database.BatchableContext bc) {
        // В кінці всього батчу — один лист зі всіма невідомими стадіями
        if (!unknownStageCodes.isEmpty()) {
            ERPMessageHandlerOrderItemStage.sendEmailForAdministratorsBulk(unknownStageCodes);
        }
    }
}