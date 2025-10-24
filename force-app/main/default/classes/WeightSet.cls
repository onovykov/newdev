public class WeightSet {
    public Decimal jacWeight { get; private set; }
    public Decimal levWeight { get; private set; }
    public Decimal metWeight { get; private set; }
    public Decimal dicWeight { get; private set; }
    public Decimal cosWeight { get; private set; }
    public Decimal sndWeight { get; private set; }

    public static final Decimal TOLERANCE = 0.001;
    public static final Decimal DEFAULT_WEIGHT = 0.1666;

    // --- Конструктор з валідацією ---
    public WeightSet(Decimal jac, Decimal lev, Decimal met, Decimal dic, Decimal cos, Decimal snd) {
        Decimal sum = jac + lev + met + dic + cos + snd;
        if (Math.abs(sum.setScale(3) - 1.0) > TOLERANCE) {
            System.debug('⚠️ WARNING! Weight sum ≠ 1.0, setting default values (0.2 each)');
            setDefaults();
        } else {
            this.jacWeight = jac;
            this.levWeight = lev;
            this.metWeight = met;
            this.dicWeight = dic;
            this.cosWeight = cos;
            this.sndWeight = snd;
        }
    }

    // --- Метод для встановлення значень за замовчуванням ---
    private void setDefaults() {
        this.jacWeight = DEFAULT_WEIGHT;
        this.levWeight = DEFAULT_WEIGHT;
        this.metWeight = DEFAULT_WEIGHT;
        this.dicWeight = DEFAULT_WEIGHT;
        this.cosWeight = DEFAULT_WEIGHT;
        this.sndWeight = DEFAULT_WEIGHT;
    }

    // --- Статичний метод: повертає дефолтний набір ---
    public static WeightSet getDefault() {
        return new WeightSet(DEFAULT_WEIGHT, DEFAULT_WEIGHT, DEFAULT_WEIGHT, DEFAULT_WEIGHT, DEFAULT_WEIGHT, DEFAULT_WEIGHT);
    }

    // --- Метод для валідації та повернення результату перевірки ---
    public Boolean isValid() {
        Decimal sum = jacWeight + levWeight + metWeight + dicWeight + cosWeight + sndWeight;
        return Math.abs(sum.setScale(3) - 1.0) <= TOLERANCE;
    }

    // --- Метод, що повертає загальну вагу показників ---
    public Decimal getTotalWeight() {
        return (jacWeight + levWeight + metWeight + dicWeight + cosWeight + sndWeight).setScale(3);
    }
}

/*
Як використовувати:
WeightSet weights = new WeightSet(0.3, 0.2, 0.2, 0.2, 0.1); // правильна сума = 1.0
// або
WeightSet weights = WeightSet.getDefault(); // усі по 0.2
*/