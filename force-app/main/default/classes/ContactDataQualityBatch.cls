global class ContactDataQualityBatch extends DataQualityBatchBase {

    global ContactDataQualityBatch(Boolean dryRun) {
        super('Contact', dryRun);
    }

    // тут робимо не execute, а hook з DataQualityBatchBase
    public override void afterStandardChecks(List<SObject> scope) {
        handleDuplicateEmails((List<Contact>) scope);
    }

    /* =========================
       DUPLICATE EMAIL LOGIC
       ========================= */
    private void handleDuplicateEmails(List<Contact> scope) {

        Set<String> emails = new Set<String>();
        for (Contact c : scope) {
            if (String.isNotBlank(c.Email)) {
                emails.add(c.Email.toLowerCase());
            }
        }
        if (emails.isEmpty()) return;

        List<Contact> existing = [
            SELECT Id, Email, AccountId, OwnerId
            FROM Contact
            WHERE Email IN :emails
        ];

        Map<String, List<Contact>> byEmail = new Map<String, List<Contact>>();
        for (Contact c : existing) {
            String key = c.Email.toLowerCase();
            if (!byEmail.containsKey(key)) {
                byEmail.put(key, new List<Contact>());
            }
            byEmail.get(key).add(c);
        }

        for (Contact c : scope) {
            if (String.isBlank(c.Email)) continue;

            List<Contact> others = byEmail.get(c.Email.toLowerCase());
            if (others == null) continue;

            for (Contact o : others) {
                if (o.Id == c.Id) continue;

                Boolean sameAccount =
                    c.AccountId != null && c.AccountId == o.AccountId;
                Boolean sameOwner =
                    c.OwnerId == o.OwnerId;

                if (sameAccount || sameOwner) {

                    DataQualityFinding f = new DataQualityFinding();
                    f.objectApi = 'Contact';
                    f.recordId  = c.Id;
                    f.fieldApi  = 'Email';
                    f.value     = c.Email;
                    f.level     = 'Suspicious';
                    f.ownerId  = c.OwnerId;

                    findings.add(f);

                    if (!dryRun) {
                        c.Email_Is_Suspicious__c = true;
                    }
                    break;
                }
            }
        }
    }
}