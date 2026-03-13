public with sharing class SlackChannel implements NotificationChannel {
    public NotificationTypes.ChannelResult send(
        NotificationTypes.NotificationPayload p,
        NotificationTypes.RecipientBundle r,
        NotificationTypes.NotificationEventCfg cfg
    ) {
        String path = SettingsService.slackPath();
        if (String.isBlank(path)) return NotificationResultFactory.none();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Slack_Notifications' + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String text = SubjectBuilder.build(p, null, null) + '\n' + BodyBuilder.build(p, null, null);
        req.setBody(JSON.serialize(new Map<String,Object>{ 'text' => text })); // зверни увагу на =>

        HttpResponse res = new Http().send(req);

        NotificationTypes.ChannelResult cr = new NotificationTypes.ChannelResult();
        cr.ok = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
        cr.sentCount = cr.ok ? 1 : 0;
        cr.message = res.getBody();
        return cr;
    }
}