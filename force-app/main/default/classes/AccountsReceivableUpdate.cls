global without sharing class AccountsReceivableUpdate implements Database.Batchable<SObject> {

    // ------- Вхідні дані з ERP (typed + raw) -------
    global Long messageTimeStamp;
    global Set<String> accIdErpSet = new Set<String>();
    global Map<String, ERPMessageParser.AccountsReceivableItem> accErpId_To_Ari_Map =
        new Map<String, ERPMessageParser.AccountsReceivableItem>();
    // raw-айтеми на випадок, якщо typed-моделі не співпадуть з фактом
    global Map<String, Map<String, Object>> accErpId_To_RawItem =
        new Map<String, Map<String, Object>>();

    // ------- Ретраї / розміри порцій -------
    private static final Integer MAX_RETRIES   = 3;
    private static final Integer SLICE_SIZE    = 25; // дрібніші під-чанки = менше колізій

    // ------- Конструктор з JSON (back-compat + гнучкий парсинг) -------
	global AccountsReceivableUpdate(String requestBody) {
		ERPMessageParser.ErpToSfMessage_AccountsReceivable parsed = null;

		// 1) Пробуємо typed JSON → якщо впаде (через "Y"/"N" тощо) — ловимо і працюємо лише з raw
		try {
			parsed =
				(ERPMessageParser.ErpToSfMessage_AccountsReceivable)
					JSON.deserialize(requestBody, ERPMessageParser.ErpToSfMessage_AccountsReceivable.class);
		} catch (Exception e) {
			// залишаємо parsed = null, підемо raw-шляхом нижче
			System.debug(LoggingLevel.WARN, 'Typed deserialize failed, switching to raw: ' + e.getMessage());
		}

		// 2) msgTimestamp: typed → raw → now()
		Long tsMs = null;
		try {
			if (parsed != null && parsed.metadata != null && parsed.metadata.msgTimestamp != null) {
				tsMs = parsed.metadata.msgTimestamp.getTime();
			}
		} catch (Exception ignore) {}
		if (tsMs == null) tsMs = extractMsgTimestampMsFromRawJson(requestBody);
		if (tsMs == null) tsMs = Datetime.now().getTime();
		messageTimeStamp = tsMs;

		// 3) Підготуємо raw items
		Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
		List<Object> rawItems = new List<Object>();
		if (raw != null &&
			raw.containsKey('data') && raw.get('data') instanceof Map<String, Object> &&
			((Map<String, Object>)raw.get('data')).containsKey('items')) {
			Object itemsObj = ((Map<String, Object>)raw.get('data')).get('items');
			if (itemsObj instanceof List<Object>) rawItems = (List<Object>) itemsObj;
		}

		// 4) Якщо typed є — проіндексуємо typed items; паралельно — raw items
		Integer idx = 0;
		if (parsed != null && parsed.data != null && parsed.data.items != null) {
			for (ERPMessageParser.AccountsReceivableItem ari : parsed.data.items) {
				String erpId = (ari != null && ari.account != null && ari.account.id != null)
					? ari.account.id.trim() : null;
				if (!String.isBlank(erpId)) {
					accIdErpSet.add(erpId);
					accErpId_To_Ari_Map.put(erpId, ari);
				}
				if (idx < rawItems.size() && rawItems[idx] instanceof Map<String, Object>) {
					Map<String, Object> rawItem = (Map<String, Object>) rawItems[idx];
					String rawErpId = objToString(getPath(rawItem, 'account.id'));
					if (!String.isBlank(rawErpId)) {
						accErpId_To_RawItem.put(rawErpId.trim(), rawItem);
					}
				}
				idx++;
			}
		} else {
			// 5) Typed недоступний — індексуємо лише raw items
			for (Object o : rawItems) {
				if (!(o instanceof Map<String, Object>)) continue;
				Map<String, Object> rawItem = (Map<String, Object>) o;
				String rawErpId = objToString(getPath(rawItem, 'account.id'));
				if (String.isBlank(rawErpId)) continue;
				rawErpId = rawErpId.trim();
				accIdErpSet.add(rawErpId);
				accErpId_To_RawItem.put(rawErpId, rawItem);
			}
		}
	}

    // ------- Batchable -------
    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            'SELECT Id, ID_ERP__c, Name, ' +
            'AccountsReceivableExchangeTimestamp__c, AccountsReceivableLastSync__c, ' +
            'Balance__c, PastDueDebt__c, PastDueDebt15More__c, ' +
            'GroupPastDueDebt__c, GroupPastDueDebt15More__c, ' +
            'BlockDate__c, CurrentMonthReceipts__c, StopListRisk__c, ' +
            'PermissionDate__c, PermittedProductionAmount__c, PermittedShipmentAmount__c, ' +
            'PermissionComment__c, DealingStatus__c ' +
            'FROM Account ' +
            'WHERE ID_ERP__c IN :accIdErpSet ' +
            'ORDER BY Id'
        );
    }

    global void execute(Database.BatchableContext context, List<Account> scope) {
        List<Account> toUpdate = new List<Account>();

        for (Account acc : scope) {
            String erpId = acc.ID_ERP__c;
            ERPMessageParser.AccountsReceivableItem ari = accErpId_To_Ari_Map.get(erpId);
            Map<String, Object> rawItem = accErpId_To_RawItem.get(erpId);

            // Гнучко знімаємо кожне поле: спочатку беремо typed, якщо null — raw
            Boolean changed = false;

            // timestamps
			changed |= setIfChanged(
				acc,
				'AccountsReceivableExchangeTimestamp__c',
				(Object) Decimal.valueOf(String.valueOf(messageTimeStamp)) // гарантія типу Decimal
			);
            changed |= setIfChanged(acc, 'AccountsReceivableLastSync__c',
                                    (Object)Datetime.newInstance(messageTimeStamp));

            // decimals
            changed |= setIfChanged(acc, 'Balance__c',
                coalesceDecimal(ari == null ? null : ari.balance, getDecimal(rawItem, 'balance')));

            changed |= setIfChanged(acc, 'PastDueDebt__c',
                coalesceDecimal(ari == null ? null : ari.pastDueDebt, getDecimal(rawItem, 'pastDueDebt')));

            changed |= setIfChanged(acc, 'PastDueDebt15More__c',
                coalesceDecimal(ari == null ? null : ari.pastDueDebt15More, getDecimal(rawItem, 'pastDueDebt15More')));

            changed |= setIfChanged(acc, 'GroupPastDueDebt__c',
                coalesceDecimal(ari == null ? null : ari.groupPastDueDebt, getDecimal(rawItem, 'groupPastDueDebt')));

            changed |= setIfChanged(acc, 'GroupPastDueDebt15More__c',
                coalesceDecimal(ari == null ? null : ari.groupPastDueDebt15More, getDecimal(rawItem, 'groupPastDueDebt15More')));

            // dates
            changed |= setIfChanged(acc, 'BlockDate__c',
                coalesceDate(ari == null ? null : (ari.dueDate == null ? null : ari.dueDate.date()),
                             getDate(rawItem, 'dueDate')));

            // decimals
            changed |= setIfChanged(acc, 'CurrentMonthReceipts__c',
                coalesceDecimal(ari == null ? null : ari.receipts, getDecimal(rawItem, 'receipts')));

            // booleans
            changed |= setIfChanged(acc, 'StopListRisk__c',
                coalesceBoolean(ari == null ? null : ari.toBlock, getBoolean(rawItem, 'toBlock')));

            // dates
            changed |= setIfChanged(acc, 'PermissionDate__c',
                coalesceDate(ari == null ? null : (ari.permissionDate == null ? null : ari.permissionDate.date()),
                             getDate(rawItem, 'permissionDate')));

            // decimals
            changed |= setIfChanged(acc, 'PermittedProductionAmount__c',
                coalesceDecimal(ari == null ? null : ari.permittedProductionAmount, getDecimal(rawItem, 'permittedProductionAmount')));

            changed |= setIfChanged(acc, 'PermittedShipmentAmount__c',
                coalesceDecimal(ari == null ? null : ari.permittedShipmentAmount, getDecimal(rawItem, 'permittedShipmentAmount')));

            // strings
            changed |= setIfChanged(acc, 'PermissionComment__c',
                coalesceString(ari == null ? null : ari.permissionComment, objToString(getPath(rawItem, 'permissionComment'))));

            // status
            Boolean toBlockVal = coalesceBoolean(ari == null ? null : ari.toBlock, getBoolean(rawItem, 'toBlock'));
            String statusVal = objToString(
                (ari == null) ? getPath(rawItem, 'status') : ari.status
            );
            String newStatus = (toBlockVal == true) ? '40' : (String.isBlank(statusVal) ? null : statusVal);
            changed |= setIfChanged(acc, 'DealingStatus__c', (Object)newStatus);

            if (changed) toUpdate.add(acc);
        }

        if (!toUpdate.isEmpty()) {
            updateWithRetries(toUpdate);
        }
    }

    global void finish(Database.BatchableContext context) {
        if (!Test.isRunningTest()) {
            try {
                AccountsBlockedUpdate abu = new AccountsBlockedUpdate(accIdErpSet);
                Database.executeBatch(abu);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'AccountsBlockedUpdate failed: ' + e.getMessage());
            }
        }
    }

    // ------- Helpers: safe set/diff -------

    private static Boolean setIfChanged(SObject sobj, String fieldApi, Object newVal) {
        Object oldVal = sobj.get(fieldApi);
        if (!isEqualApex(oldVal, newVal)) {
            sobj.put(fieldApi, newVal);
            return true;
        }
        return false;
    }

    private static Boolean isEqualApex(Object a, Object b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        if (a instanceof Decimal && b instanceof Decimal) {
            return String.valueOf((Decimal)a) == String.valueOf((Decimal)b);
        }
        return String.valueOf(a) == String.valueOf(b);
    }

    // ------- Helpers: гнучке читання raw значень -------

    private static Object getPath(Map<String, Object> m, String path) {
        if (m == null || String.isBlank(path)) return null;
        List<String> parts = path.split('\\.');
        Object cur = m;
        for (String p : parts) {
            if (!(cur instanceof Map<String, Object>)) return null;
            Map<String, Object> mm = (Map<String, Object>) cur;
            if (!mm.containsKey(p)) return null;
            cur = mm.get(p);
        }
        return cur;
    }

    private static String objToString(Object o) {
        return (o == null) ? null : String.valueOf(o);
    }

    private static Decimal coalesceDecimal(Decimal a, Decimal b) {
        return (a != null) ? a : b;
    }
    private static Date coalesceDate(Date a, Date b) {
        return (a != null) ? a : b;
    }
    private static Boolean coalesceBoolean(Boolean a, Boolean b) {
        return (a != null) ? a : b;
    }
    private static String coalesceString(String a, String b) {
        return (a != null) ? a : b;
    }

    private static Decimal getDecimal(Map<String, Object> m, String path) {
        Object v = getPath(m, path);
        if (v == null) return null;
        if (v instanceof Decimal) return (Decimal) v;
        if (v instanceof Integer) return Decimal.valueOf((Integer) v);
        if (v instanceof Long)    return Decimal.valueOf((Long) v);
        if (v instanceof String) {
            String s = ((String) v).trim();
            if (String.isBlank(s)) return null;
            try { return Decimal.valueOf(s); } catch (Exception ignore) {}
        }
        return null;
    }

    private static Boolean getBoolean(Map<String, Object> m, String path) {
        Object v = getPath(m, path);
        if (v == null) return null;
        if (v instanceof Boolean) return (Boolean) v;
        if (v instanceof String) {
            String s = ((String) v).trim().toLowerCase();
            if (s == 'true' || s == '1' || s == 'y' || s == 'yes') return true;
            if (s == 'false' || s == '0' || s == 'n' || s == 'no')  return false;
        }
        if (v instanceof Integer) return ((Integer)v) != 0;
        if (v instanceof Long)    return ((Long)v)    != 0;
        if (v instanceof Decimal) return ((Decimal)v) != 0;
        return null;
    }

    private static Date getDate(Map<String, Object> m, String path) {
        Datetime dt = getDatetime(m, path);
        return (dt == null) ? null : dt.date();
    }

    private static Datetime getDatetime(Map<String, Object> m, String path) {
        Object v = getPath(m, path);
        return parseFlexibleDatetime(v);
    }

	private static Datetime parseFlexibleDatetime(Object v) {
		try {
			if (v == null) return null;
			if (v instanceof Datetime) return (Datetime) v;
			if (v instanceof Date)     return Datetime.newInstance((Date)v, Time.newInstance(0,0,0,0));
			if (v instanceof Decimal)  return Datetime.newInstance(((Decimal) v).longValue());
			if (v instanceof Long)     return Datetime.newInstance((Long) v);
			if (v instanceof Integer)  return Datetime.newInstance(Decimal.valueOf((Integer) v).longValue());
			if (v instanceof String) {
				String s = ((String)v).trim();
				if (String.isBlank(s)) return null;

				// Якщо у рядку тільки цифри — трактуємо як epoch ms
				Boolean isNumeric = true;
				for (Integer i = 0; i < s.length(); i++) {
					String ch = s.substring(i, i+1);
					if (ch < '0' || ch > '9') { isNumeric = false; break; }
				}
				if (isNumeric) {
					Long epoch = Long.valueOf(s);
					return Datetime.newInstance(epoch);
				}

				// ISO normalizer → "yyyy-MM-dd HH:mm:ss" (GMT)
				String norm = s;
				Integer dot = norm.indexOf('.');
				if (dot > 0) {
					Integer zPos = norm.indexOf('Z', dot);
					if (zPos > 0) norm = norm.substring(0, zPos);
					norm = norm.substring(0, dot);
				}
				norm = norm.replace('T', ' ');
				if (norm.endsWith('Z')) norm = norm.substring(0, norm.length() - 1);

				Integer plusIdx = norm.indexOf('+');
				Integer tzIdx = -1;
				if (plusIdx > 10) tzIdx = plusIdx;
				Integer lastMinus = norm.lastIndexOf('-'); // може бути у даті; беремо лише «хвостовий» зсув
				if (lastMinus > 10) tzIdx = (tzIdx == -1 ? lastMinus : Math.min(tzIdx, lastMinus));
				if (tzIdx > 0) norm = norm.substring(0, tzIdx);

				if (norm.length() == 10) norm += ' 00:00:00';
				return Datetime.valueOfGmt(norm);
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, 'parseFlexibleDatetime failed: ' + e.getMessage());
		}
		return null;
	}

    // msgTimestamp raw (number | ISO string)
	private static Long extractMsgTimestampMsFromRawJson(String body) {
		try {
			Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(body);
			if (raw == null) return null;
			Map<String, Object> metadata = (Map<String, Object>) raw.get('metadata');
			if (metadata == null) return null;
			Object ts = metadata.get('msgTimestamp');
			if (ts == null) return null;

			if (ts instanceof Decimal) return ((Decimal) ts).longValue();
			if (ts instanceof Long)    return (Long) ts;
			if (ts instanceof Integer) return Decimal.valueOf((Integer) ts).longValue();
			if (ts instanceof String) {
				Datetime dt = parseFlexibleDatetime((String) ts);
				return dt == null ? null : dt.getTime();
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, 'extractMsgTimestampMsFromRawJson failed: ' + e.getMessage());
		}
		return null;
	}

    // ------- update з ретраями + FOR UPDATE -------
    private static void updateWithRetries(List<Account> records) {
        Integer attempt = 0;
        List<Account> pending = records;

        while (!pending.isEmpty() && attempt <= MAX_RETRIES) {
            List<Account> toRetry = new List<Account>();

            for (Integer i = 0; i < pending.size(); i += SLICE_SIZE) {
                Integer toIdx = Math.min(i + SLICE_SIZE, pending.size());
                List<Account> slice = new List<Account>();
                Set<Id> ids = new Set<Id>();
                for (Integer j = i; j < toIdx; j++) {
                    slice.add(pending[j]);
                    ids.add(pending[j].Id);
                }

                // беремо ексклюзивний лок
                List<Account> locks = [SELECT Id FROM Account WHERE Id IN :ids FOR UPDATE];

                Database.SaveResult[] sr = Database.update(slice, false);
                for (Integer k = 0; k < sr.size(); k++) {
                    if (!sr[k].isSuccess()) {
                        Boolean isLock = false;
                        for (Database.Error e : sr[k].getErrors()) {
                            if (e.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { isLock = true; break; }
                        }
                        if (isLock) toRetry.add(slice[k]);
                        else System.debug(LoggingLevel.WARN, 'Update error (no retry): ' + sr[k].getErrors());
                    }
                }
            }

            if (toRetry.isEmpty()) break;
            attempt++;
            pending = toRetry; // наступна спроба — лише для залочених
        }

        if (!pending.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Update skipped after retries (lock): ' + pending.size() + ' records');
        }
    }
}