public class IndexWeights {
    public Decimal phoneticWeight { get; private set; }
    public Decimal metaphoneWeight { get; private set; }
    public Decimal nysiisWeight { get; private set; }
    public Decimal soundexWeight { get; private set; }  

    public static final Decimal TOLERANCE = 0.001;
    public static final Decimal DEFAULT_WEIGHT = 0.250;

    // --- Конструктор з валідацією ---
    public IndexWeights(Decimal phonetic, Decimal metaphone, Decimal nysiis, Decimal snd) {
        Decimal sum = phonetic + metaphone + nysiis + snd;
        if (Math.abs(sum.setScale(3) - 1.0) > TOLERANCE) {
            System.debug('⚠️ WARNING! Weight sum ≠ 1.0, setting default values (0.25 each)');
            setDefaults();
        } else {
            this.phoneticWeight = phonetic;
            this.metaphoneWeight = metaphone;
            this.nysiisWeight = nysiis;
            this.soundexWeight = snd;
        }
    }

    // --- Метод для встановлення значень за замовчуванням ---
    private void setDefaults() {
        this.phoneticWeight = DEFAULT_WEIGHT;
        this.metaphoneWeight = DEFAULT_WEIGHT;
        this.nysiisWeight = DEFAULT_WEIGHT;
        this.soundexWeight = DEFAULT_WEIGHT;
    }

    // --- Статичний метод: повертає дефолтний набір ---
    public static IndexWeights getDefault() {
        return new IndexWeights(DEFAULT_WEIGHT, DEFAULT_WEIGHT, DEFAULT_WEIGHT, DEFAULT_WEIGHT);
    }

    // --- Метод для валідації та повернення результату перевірки ---
    public Boolean isValid() {
        Decimal sum = phoneticWeight + metaphoneWeight + nysiisWeight + soundexWeight;
        return Math.abs(sum.setScale(3) - 1.0) <= TOLERANCE;
    }

    // --- Метод, що повертає загальну вагу показників ---
    public Decimal getTotalWeight() {
        return (phoneticWeight + metaphoneWeight + nysiisWeight + soundexWeight).setScale(3);
    }
}

/*
Як використовувати:
IndexWeights weights = new IndexWeights(0.3, 0.1, 0.3, 0.3); // правильна сума = 1.0
 або
IndexWeights weights = IndexWeights.getDefault(); // усі по 0.25
*/