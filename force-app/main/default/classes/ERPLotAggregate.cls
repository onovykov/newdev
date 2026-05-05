public class ERPLotAggregate {

    public String iteNumber;
    // public Id orderId;
    public Id orderItemId;
    public String lotType;
    public Decimal lotQty;
    public Date lotDate;
    public Id prodWeekId;
    public String extKey;

    public ERPLotAggregate(
        String iteNumber,
        String lotType,
        Decimal lotQty,
        Date lotDate,
        Id prodWeekId
    ) {
        this.iteNumber = iteNumber;
        this.lotType = lotType;
        this.lotQty = lotQty;
        this.lotDate = lotDate;
        this.prodWeekId = prodWeekId;
    }
}