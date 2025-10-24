@isTest
private class SyncUsersSchedulerTest {

    // Inner class to mock the callout
    private class MockHttpCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"USERID": "VRYBAK", "Date_Of_Dismissal": "2024-12-13T12:32:22.6787225+02:00"}, {"USERID": "SGAGARKOVA", "Date_Of_Dismissal": "2024-12-11T12:32:22.6787225+02:00"}]');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSyncUsersScheduler() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());

        Test.startTest();
        String cronExpr = '0 0 17 * * ?'; 
        String jobName = 'Sync Users to ERP Job';
        SyncUsersScheduler.scheduleJob();
        Test.stopTest();

        // Assert - ensure that the job has been scheduled correctly
        List<CronTrigger> jobs = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                                  FROM CronTrigger 
                                  WHERE CronExpression = :cronExpr 
                                  AND TimesTriggered = 0];
        
        System.assertEquals(1, jobs.size(), 'Job not scheduled properly');
        System.assertEquals(cronExpr, jobs[0].CronExpression, 'Cron Expression does not match expected value');
    }
}