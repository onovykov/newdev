public with sharing class ERPMessageHandlerProdPlanBalance {

    public static MessageProcessingResult ProcessMessage(ERPMessageParser.ErpToSfMessage_ProdPlanBalance parsedMessage, String requestBody, Boolean recreatePlans) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.msgType;
        System.debug('🔁 Start ERPMessageHandlerProdPlanBalance');
        System.debug('🗑️ Recreate Plans (Delete & Insert): ' + recreatePlans);

        System.debug('🔍 Parsed YearMonth: ' + parsedMessage.data.periodInfo.YearMonth);

        for (ERPMessageParser.OrderItemsData item : parsedMessage.data.items) {
            System.debug('📦 OrderItem: ' + item.IteNumber);
            System.debug('  ├─ Shop: ' + item.Shop);
            System.debug('  ├─ DateSnapshot: ' + item.DateSnapshot);
            System.debug('  ├─ Year: ' + item.Year);
            System.debug('  └─ Month: ' + item.Month);

            if (item.Plans == null || item.Plans.isEmpty()) {
                System.debug('  ⚠️ No plans for this item');
                continue;
            }

            for (ERPMessageParser.ProdPlan plan : item.Plans) {
                if (plan.WeekPlans == null || plan.WeekPlans.isEmpty()) {
                    System.debug('      ⚠️ No WeekPlans in this plan (logging only, plan may still be saved at month level)');
                }

                for (ERPMessageParser.WeekPlan week : plan.WeekPlans) {
                    if (week.Details == null || week.Details.isEmpty()) {
                        System.debug('        ⚠️ No Details in WeekPlan');
                    }

                    for (ERPMessageParser.WeekPlanNode detail : week.Details) {
                        System.debug('        📅 Week Detail:');
                        System.debug('          ├─ WeekNum: ' + detail.WeekNum);
                        System.debug('          ├─ DateFrom: ' + detail.DateFrom);
                        System.debug('          ├─ DateTo: ' + detail.DateTo);
                        System.debug('          └─ PlanQty_t: ' + detail.PlanQty_t);
                    }
                }
            }
        }


        try {
            List<ERPMessageParser.ItemNode> itemsToInsert = new List<ERPMessageParser.ItemNode>();

            ERPMessageParser.PeriodInfo periodInfo = parsedMessage.data.periodInfo;
            ERPMessageParser.OrderItemsData[] orderItemsData = parsedMessage.data.items;

            // Перевірка на наявність IteNumber у всіх позиціях
            List<ERPMessageParser.OrderItemsData> itemsWithoutIteNumber = new List<ERPMessageParser.OrderItemsData>();
            for (ERPMessageParser.OrderItemsData itemData : orderItemsData) {
                if (String.isBlank(itemData.IteNumber)) {
                    itemsWithoutIteNumber.add(itemData);
                }
            }

            if (!itemsWithoutIteNumber.isEmpty()) {
                System.debug('❌ ERROR: Found ' + itemsWithoutIteNumber.size() + ' items without IteNumber');
                System.debug('📋 Items without IteNumber:');
                for (ERPMessageParser.OrderItemsData item : itemsWithoutIteNumber) {
                    System.debug('  - Shop: ' + item.Shop + ', DateSnapshot: ' + item.DateSnapshot +
                            ', Year: ' + item.Year + ', Month: ' + item.Month +
                            ', MonthPlanQty_t: ' + item.MonthPlanQty_t);
                }
                System.debug('📄 Full request body with items without IteNumber:');
                System.debug(requestBody);

                res.error = 'Found ' + itemsWithoutIteNumber.size() + ' items without IteNumber. Processing aborted. Check logs for details.';
                res.jobStatus = 'Failed - missing IteNumber';
                return res;
            }

            Set<String> itemNumbers = new Set<String>();
            for (ERPMessageParser.OrderItemsData itemData : orderItemsData) {
                itemNumbers.add(itemData.IteNumber);
            }
            System.debug('itemNumbers: ' + itemNumbers);

            for (ERPMessageParser.OrderItemsData rawItem : parsedMessage.data.items) {
                ERPMessageParser.ItemNode itemNode = new ERPMessageParser.ItemNode();
                itemNode.IteNumber = rawItem.IteNumber;
                itemNode.Shop = rawItem.Shop;
                itemNode.monthPlans = new List<ERPMessageParser.MonthPlanNode>();

                // Якщо Plans пустий або null, створюємо місячний план без тижневих деталей
                if (rawItem.Plans == null || rawItem.Plans.isEmpty()) {
                    System.debug('📅 No weekly plans for Ite: ' + rawItem.IteNumber + ', creating month-level plan only');

                    ERPMessageParser.MonthPlanNode monthPlan = new ERPMessageParser.MonthPlanNode();
                    monthPlan.ProdPlanType        = '253';
                    monthPlan.MonthPlanQty_t      = rawItem.MonthPlanQty_t;
                    monthPlan.MonthProdBalance_t  = rawItem.MonthProdBalance_t;
                    monthPlan.DateSnapshot        = toDate(rawItem.DateSnapshot);
                    monthPlan.Year                = rawItem.Year;
                    monthPlan.Month               = rawItem.Month;
                    monthPlan.ValidDate           = null;
                    monthPlan.monthWeeks          = new List<ERPMessageParser.WeekPlanNode>();

                    itemNode.monthPlans.add(monthPlan);
                } else {
                    // Обробляємо Plans як раніше
                    for (ERPMessageParser.ProdPlan plan : rawItem.Plans) {

                        Date latestWeekDateTo = null;
                        if (plan.WeekPlans != null) {
                            for (ERPMessageParser.WeekPlan weekPlan : plan.WeekPlans) {
                                if (weekPlan != null && weekPlan.Details != null) {
                                    for (ERPMessageParser.WeekPlanNode detail : weekPlan.Details) {
                                        Date dTo = toDate(detail.DateTo);
                                        if (dTo != null && (latestWeekDateTo == null || dTo > latestWeekDateTo)) {
                                            latestWeekDateTo = dTo;
                                        }
                                    }
                                }
                            }
                        }

                        Date validDate = toDate(plan.ValidDate);
                        if (validDate != null && latestWeekDateTo != null && validDate < latestWeekDateTo) {
                            System.debug('⚠️ Skipping plan due to invalid ValidDate: ' + plan.ValidDate);
                            continue;
                        }

                        ERPMessageParser.MonthPlanNode monthPlan = new ERPMessageParser.MonthPlanNode();
                        monthPlan.ProdPlanType        = '253';
                        monthPlan.MonthPlanQty_t      = rawItem.MonthPlanQty_t;
                        monthPlan.MonthProdBalance_t  = rawItem.MonthProdBalance_t;
                        monthPlan.DateSnapshot        = toDate(rawItem.DateSnapshot);
                        monthPlan.Year                = rawItem.Year;
                        monthPlan.Month               = rawItem.Month;
                        monthPlan.ValidDate           = validDate;
                        monthPlan.monthWeeks          = new List<ERPMessageParser.WeekPlanNode>();

                        if (plan.WeekPlans != null) {
                            for (ERPMessageParser.WeekPlan weekPlan : plan.WeekPlans) {
                                if (weekPlan == null || weekPlan.Details == null || weekPlan.Details.isEmpty()) {
                                    // просто пропускаємо цей тиждень, НЕ пропускаємо план
                                    continue;
                                }
                                for (ERPMessageParser.WeekPlanNode detail : weekPlan.Details) {
                                    ERPMessageParser.WeekPlanNode weekNode = new ERPMessageParser.WeekPlanNode();
                                    weekNode.ProdPlanType = '253';
                                    weekNode.ValidDate    = validDate;
                                    weekNode.WeekNum      = detail.WeekNum;
                                    weekNode.PlanQty_t    = detail.PlanQty_t;
                                    weekNode.DateFrom     = detail.DateFrom;
                                    weekNode.DateTo       = detail.DateTo;
                                    monthPlan.monthWeeks.add(weekNode);
                                }
                            }
                        }

                        // Додаємо план навіть якщо monthWeeks пустий
                        itemNode.monthPlans.add(monthPlan);
                    }
                }

                itemsToInsert.add(itemNode);
                System.debug('✅ ItemNode added: ' + JSON.serialize(itemNode));
            }

            if (!itemsToInsert.isEmpty()) {
                // Перевірка кількості jobs у черзі перед запуском нового batch
                Integer queuedJobs = [
                        SELECT COUNT()
                        FROM AsyncApexJob
                        WHERE JobType = 'BatchApex'
                        AND (Status = 'Holding' OR Status = 'Queued' OR Status = 'Preparing' OR Status = 'Processing')
                ];

                System.debug('📊 Current queued batch jobs: ' + queuedJobs);

                if (queuedJobs >= 90) {
                    System.debug('⚠️ WARNING: Too many batch jobs in queue (' + queuedJobs + '). Skipping batch execution to avoid flex queue limit.');
                    res.error = 'Too many batch jobs in queue (' + queuedJobs + '/100). Message will be retried later.';
                    res.jobStatus = 'Queued - will retry';
                } else {
                    InsertProdPlanBatch batch = new InsertProdPlanBatch();
                    batch.items = itemsToInsert;
                    batch.itemNumbers = itemNumbers;
                    batch.orderItemsPeriodInfo = periodInfo;
                    batch.recreatePlans = recreatePlans;
                    Database.executeBatch(batch, 200);

                    System.debug('🚀 Batch InsertProdPlanBatch launched with items: ' + itemsToInsert.size());
                    res.jobStatus = 'Batch launched with ' + itemsToInsert.size() + ' items';
                }
            }
        } catch (Exception e) {
            res.error = e.getMessage();
            System.debug('❌ Error in handler: ' + e.getMessage());
        }

        System.debug('✅ End ERPMessageHandlerProdPlanBalance');
        return res;
    }

    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
        System.debug('!!!!' + error);
        JSONGenerator gen = JSON.createGenerator(true);


        String res = gen.getAsString();
        System.debug('Response body text generated: ' + res);
        return Blob.valueOf(res);
    }

    public class MessageProcessingResult {
        public String MessageType;
        public String error;
        public String jobStatus;
    }

    private static Date toDate(String iso) {
        if (String.isBlank(iso) || iso == '0001-01-01T00:00:00') return null;
        try {
            if (iso.contains('T')) return Datetime.valueOf(iso).date();
            return Date.valueOf(iso);
        } catch (Exception e) { return null; }
    }
}