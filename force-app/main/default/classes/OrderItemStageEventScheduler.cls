/*
    Scheduler: OrderItemStageEventScheduler
    Щоб це працювало автоматично, робимо простий Schedulable-клас
    і ставимо його за розкладом (наприклад, що п'ять хвилин):
*/
global class OrderItemStageEventScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // batch size по дефолту 200 - має вистачити
        Database.executeBatch(new OrderItemStageEventBatch(), 200);
    }
}