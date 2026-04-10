public with sharing class InboundBatchAssembler {

    public static String assemble(String batchKey) {

        List<ERP_InboundPart__c> parts = [
            SELECT PartNumber__c, Payload__c
            FROM ERP_InboundPart__c
            WHERE BatchKey__c = :batchKey
            ORDER BY PartNumber__c ASC
        ];

        if (parts.isEmpty()) {
            throw new IntegrationDomainException(
                'Assembler',
                'NO_PARTS',
                batchKey
            );
        }

        Map<String,Object> first =
            (Map<String,Object>) JSON.deserializeUntyped(parts[0].Payload__c);

        Map<String,Object> metadata =
            (Map<String,Object>) first.get('metadata');

        // Apex-варіант StringBuilder
        String payload = '';

        for (ERP_InboundPart__c p : parts) {

            Map<String,Object> root =
                (Map<String,Object>) JSON.deserializeUntyped(p.Payload__c);

            Object part = root.get('payloadPart');

            if (part != null) {
                payload += JSON.serialize(part);
            }
        }

        Map<String,Object> result = new Map<String,Object>{
            'metadata' => metadata,
            'payload'  => payload
        };

        return JSON.serialize(result);
    }
}