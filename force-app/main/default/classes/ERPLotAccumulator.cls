public class ERPLotAccumulator {

    private String iteNumber;

    private Decimal producedSum = 0;
    private Decimal dispatchedSum = 0;
    private Decimal shippedSum = 0;

    private Date producedMaxDate;
    private Date dispatchedMaxDate;
    private Date shippedMaxDate;

    public ERPLotAccumulator(String iteNumber) {
        this.iteNumber = iteNumber;
    }

    public void add(ERPMessageParser.ERPObject_ProductLot lotDto) {
        if (lotDto == null) {
            return;
        }

        Date lotDate = ERPLotParseUtil.parseDateFromDateTimeString(lotDto.lotDate);

        if (lotDate == null) {
            return;
        }

        Decimal produced = ERPLotParseUtil.parseDecimal(lotDto.produced, 2);
        Decimal dispatched = ERPLotParseUtil.parseDecimal(lotDto.dispatched, 2);
        Decimal shipped = ERPLotParseUtil.parseDecimal(lotDto.shipped, 2);

        if (produced != 0) {
            producedSum += produced;
            producedMaxDate = maxDate(producedMaxDate, lotDate);
        }

        if (dispatched != 0) {
            dispatchedSum += dispatched;
            dispatchedMaxDate = maxDate(dispatchedMaxDate, lotDate);
        }

        if (shipped != 0) {
            shippedSum += shipped;
            shippedMaxDate = maxDate(shippedMaxDate, lotDate);
        }
    }

    public List<ERPLotAggregate> toAggregates() {
        List<ERPLotAggregate> result = new List<ERPLotAggregate>();

        addAggregateIfValid(result, 'Produced', producedSum, producedMaxDate);
        addAggregateIfValid(result, 'Shipped', dispatchedSum, dispatchedMaxDate);
        addAggregateIfValid(result, 'Delivered', shippedSum, shippedMaxDate);

        return result;
    }

    private void addAggregateIfValid(
        List<ERPLotAggregate> result,
        String lotType,
        Decimal qty,
        Date lotDate
    ) {
        if (qty == 0 || lotDate == null) {
            return;
        }

        Id prodWeekId = ProdWeekCache.getByDate(lotDate);

        if (prodWeekId == null) {
            return;
        }

        result.add(new ERPLotAggregate(
            iteNumber,
            lotType,
            qty,
            lotDate,
            prodWeekId
        ));
    }

    private static Date maxDate(Date currentValue, Date newValue) {
        if (currentValue == null || newValue > currentValue) {
            return newValue;
        }
        return currentValue;
    }
}