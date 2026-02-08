@IsTest
private class OppBidGuaranteeInboundServiceTest {

    // ---------- Helpers ----------
    private static User createErpUser() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'ERP',
            LastName = 'User',
            Alias = 'erpusr',
            Email = 'erp.user@test.com',
            Username = 'erp.user.' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Warsaw',
            LocaleSidKey = 'pl_PL',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pl',
            LoginERP__c = 'ERP_USER'
        );
        insert u;
        return u;
    }

    private static Opportunity prepareOpp() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // ERP-поля — тільки через UPDATE
        opp.ID_ERP__c = 'ERP-123';
        opp.BidGuarantees__c = 'Yes';
        update opp;

        return opp;
    }

    private static Field_Audit_Log__c createAudit(
        Id oppId,
        Datetime changedAt,
        String oldVal,
        String newVal
    ) {
        Field_Audit_Log__c log = new Field_Audit_Log__c(
            ObjectApiName__c = 'Opportunity',
            RecordId__c = oppId,
            FieldApiName__c = 'BidGuarantees__c',
            ChangedAt__c = changedAt,
            OldValue__c = oldVal,
            NewValue__c = newVal,
            AuditKey__c = 'Opportunity.' + oppId + '.BidGuarantees__c'
        );
        insert log;
        return log;
    }

    private static ERPBidGuaranteeInboundDTO buildDto(
        String erpId,
        String bidGuarantees,
        Datetime changedAt
    ) {
        ERPBidGuaranteeInboundDTO dto =
            new ERPBidGuaranteeInboundDTO();
        dto.idErp = erpId;
        dto.bidGuarantees = bidGuarantees;
        dto.changedAt = changedAt;

        ERPBidGuaranteeInboundDTO.ERPUserDTO u =
            new ERPBidGuaranteeInboundDTO.ERPUserDTO();
        u.login = 'ERP_USER';

        dto.changedBy = u;
        return dto;
    }

    // ---------- tests ----------

    @IsTest
    static void testErpOlderThanSf_changeRejected() {
        createErpUser(); 
        Opportunity opp = prepareOpp();

        // SF має новіший audit
        Field_Audit_Log__c audit =
            createAudit(
                opp.Id,
                Datetime.now(),
                'No',
                'Yes'
            );

        ERPBidGuaranteeInboundDTO dto =
            buildDto(
                'ERP-123',
                'No',
                Datetime.now().addMinutes(-10)
            );

        Test.startTest();
        ERPBidGuaranteeInboundResponseDTO resp =
            OpportunityBidGuaranteeInboundService.handle(dto);
        Test.stopTest();

        System.assertEquals(
            false,
            resp.applied,
            'ERP older change must be rejected'
        );
        System.assertEquals(
            'STALE_ERP_DATA',
            resp.reason,
            'Rejection reason must be set'
        );

        System.assertNotEquals(
            null,
            resp.audit,
            'Audit snapshot must be returned'
        );
        System.assertEquals(
            audit.OldValue__c,
            resp.audit.oldValue
        );
        System.assertEquals(
            audit.NewValue__c,
            resp.audit.newValue
        );
    }

    @IsTest
    static void testErpNewerThanSf_changeApplied() {
        createErpUser(); 
        Opportunity opp = prepareOpp();

        createAudit(
            opp.Id,
            Datetime.now().addMinutes(-30),
            'No',
            'Yes'
        );

        ERPBidGuaranteeInboundDTO dto =
            buildDto(
                'ERP-123',
                'No',
                Datetime.now()
            );

        Test.startTest();
        ERPBidGuaranteeInboundResponseDTO resp =
            OpportunityBidGuaranteeInboundService.handle(dto);
        Test.stopTest();

        System.assertEquals(
            true,
            resp.applied,
            'ERP newer change must be applied'
        );
        System.assertEquals(
            null,
            resp.reason,
            'No rejection reason when applied'
        );

        Opportunity reloaded =
            [SELECT BidGuarantees__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(
            'No',
            reloaded.BidGuarantees__c,
            'BidGuarantees must be updated'
        );
    }
}
