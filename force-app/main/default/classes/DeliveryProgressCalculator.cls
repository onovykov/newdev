public class DeliveryProgressCalculator {

    public static Integer calculate(
        Datetime startDate,
        Datetime estimatedArrivalDate,
        Datetime nowDt
    ) {
        if (startDate == null || estimatedArrivalDate == null) {
            return null;
        }

        if (nowDt == null) {
            nowDt = System.now();
        }

        if (nowDt <= startDate) {
            return 0;
        }

        if (nowDt >= estimatedArrivalDate) {
            return 100;
        }

        Long totalMs =
            estimatedArrivalDate.getTime() - startDate.getTime();

        Long elapsedMs =
            nowDt.getTime() - startDate.getTime();

        if (totalMs <= 0) {
            return 100;
        }

        Decimal percent =
            (Decimal.valueOf(elapsedMs) / Decimal.valueOf(totalMs)) * 100;

        return Integer.valueOf(
            Math.min(100, Math.max(0, percent.setScale(0)))
        );
    }
}