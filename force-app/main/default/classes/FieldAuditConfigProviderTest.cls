@IsTest
private class FieldAuditConfigProviderTest {
    @IsTest
    static void testInboundEnabled() {

        Boolean enabled =
            FieldAuditConfigProvider.isInboundEnabled(
                'Opportunity',
                'BidGuarantees__c'
            );

        System.assertEquals(
            true,
            enabled,
            'Inbound must be enabled for BidGuarantees__c'
        );
    }

    @IsTest
    static void testOutboundEnabled() {

        Boolean enabled =
            FieldAuditConfigProvider.isOutboundEnabled(
                'Opportunity',
                'BidGuarantees__c'
            );

        System.assertEquals(
            true,
            enabled,
            'Outbound must be enabled for BidGuarantees__c'
        );
    }
}