public with sharing class WebhookChannel implements NotificationChannel {
    public NotificationTypes.ChannelResult send(
        NotificationTypes.NotificationPayload p,
        NotificationTypes.RecipientBundle r,
        NotificationTypes.NotificationEventCfg cfg
    ) {
        String path = SettingsService.webhookPath();
        if (String.isBlank(path)) return NotificationResultFactory.none();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Generic_Webhook' + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String,Object> body = new Map<String,Object>{
            'eventKey' => p.eventKey,
            'contextId' => p.context != null ? String.valueOf(p.context.get('Id')) : null,
            'vars'      => p.vars,
            'channel'   => cfg.channel,
            'timestamp' => String.valueOf(Datetime.now())
        };
        req.setBody(JSON.serialize(body));

        HttpResponse res = new Http().send(req);

        NotificationTypes.ChannelResult cr = new NotificationTypes.ChannelResult();
        cr.ok = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
        cr.sentCount = cr.ok ? 1 : 0;
        cr.message = res.getBody();
        return cr;
    }
}