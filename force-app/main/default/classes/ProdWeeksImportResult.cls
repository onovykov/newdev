// File: ProdWeeksImportResult.cls
public with sharing class ProdWeeksImportResult {
    public Integer inserted;
    public Integer updated;
    public List<String> warnings;
    public List<String> errors;

    public static ProdWeeksImportResult fail(String msg) {
        ProdWeeksImportResult r = new ProdWeeksImportResult();
        r.inserted = 0;
        r.updated  = 0;
        r.warnings = new List<String>();
        r.errors   = new List<String>{ msg };
        return r;
    }
}