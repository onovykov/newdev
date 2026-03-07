public class AccountTeamCanonicalMigrationResult {
    public Integer segmentationProcessed;
    public Integer bosProcessed;
    public Integer skippedOwner;
    public Integer skippedInactive;
    public Integer skippedDuplicate;
    public Integer preparedInsert;
    public Integer preparedUpgrade;
    public Integer inserted;
    public Integer upgraded;
    public Integer failed;
    public List<String> errors;

    public AccountTeamCanonicalMigrationResult() {
        segmentationProcessed = 0;
        bosProcessed = 0;
        skippedOwner = 0;
        skippedInactive = 0;
        skippedDuplicate = 0;
        preparedInsert = 0;
        preparedUpgrade = 0;
        inserted = 0;
        upgraded = 0;
        failed = 0;
        errors = new List<String>();
    }

    public void mergeATCM(AccountTeamCanonicalMigrationResult otherATCM) {
        if (otherATCM == null) {
            return;
        }

        segmentationProcessed += otherATCM.segmentationProcessed;
        bosProcessed += otherATCM.bosProcessed;
        skippedOwner += otherATCM.skippedOwner;
        skippedInactive += otherATCM.skippedInactive;
        skippedDuplicate += otherATCM.skippedDuplicate;
        preparedInsert += otherATCM.preparedInsert;
        preparedUpgrade += otherATCM.preparedUpgrade;
        inserted += otherATCM.inserted;
        upgraded += otherATCM.upgraded;
        failed += otherATCM.failed;

        if (otherATCM.errors != null && !otherATCM.errors.isEmpty()) {
            errors.addAll(otherATCM.errors);
        }
    }

    public String toPrettyString() {
        return JSON.serializePretty(this);
    }
}