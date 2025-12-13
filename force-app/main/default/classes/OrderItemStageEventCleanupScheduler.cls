global class OrderItemStageEventCleanupScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        OrderItemStageEventCleanupJob.runCleanup();
    }
}