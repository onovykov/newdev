public with sharing class ItemMapperResult {
    public Integer itemsProcessed { get; set; }
    public Integer itemsSkipped { get; set; }
    public List<String> warnings { get; set; }

    public ItemMapperResult() {
        this.itemsProcessed = 0;
        this.itemsSkipped = 0;
        this.warnings = new List<String>();
    }
}