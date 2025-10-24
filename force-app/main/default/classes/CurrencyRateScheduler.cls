public class CurrencyRateScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        updateCurrencyRates();
    }
    
    @future(callout=true)
    public static void updateCurrencyRates() {
        CurrencyRateCallout callout = new CurrencyRateCallout();
    }
    
    public static void scheduleJob() {
        // Schedule the job to run every day at 07:00 AM GMT+2
        String cron = '0 0 5 * * ? *'; // 07:00 AM GMT+2 = 05:00 AM GMT
        CurrencyRateScheduler job = new CurrencyRateScheduler();
        System.schedule('Currency Rate Update Job', cron, job);
    }
    
}