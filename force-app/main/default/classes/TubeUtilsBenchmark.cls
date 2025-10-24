public with sharing class TubeUtilsBenchmark {
    public class BenchResult {
        public String name;
        public Integer iterations;
        public Long ms;
        public Integer cpuMs;
        public Integer peakHeapBytes;
        public Decimal opsPerMs;
        public String notes;
    }

    public static void runAll(Integer iterations) {
        if (iterations == null || iterations <= 0) iterations = 5000; // safe default

        List<BenchResult> results = new List<BenchResult>();

        results.add(benchRoundWeight(iterations));
        results.add(benchRectWeight(iterations));
        results.add(benchMmToInches(iterations));
        results.add(benchMmToInchesFraction(iterations));
        results.add(benchValidators(iterations));

        // ——— Людський, короткий підсумок ———
        System.debug('=== TubeUtils Benchmark Results ===');
        for (BenchResult r : results) {
            System.debug(String.format(
                '{0}: iters={1}, time={2} ms, cpu={3} ms, peakHeap={4} B, throughput={5} ops/ms {6}',
                new List<Object>{
                    r.name, r.iterations, r.ms, r.cpuMs, r.peakHeapBytes, r.opsPerMs, (r.notes==null?'': '('+r.notes+')')
                }
            ));
        }
        // JSON (зручно копіпастнути кудись)
        System.debug(JSON.serializePretty(results));

        // ——— CSV для Sheets/Excel ———
        System.debug('=== CSV (copy to Sheets) ===');
        System.debug(csvHeader());
        for (BenchResult r : results) {
            System.debug(toCsv(r));
        }
    }

    // === БЕНЧ-МЕТОДИ ===

    private static BenchResult benchRoundWeight(Integer n) {
        List<Decimal> ods = new List<Decimal>{ 60.3, 88.9, 114.3, 168.28, 219.1, 244.48, 273.05 };
        List<Decimal> wts = new List<Decimal>{ 3.2, 4.0, 6.3, 7.1, 8.2, 10.0, 12.7 };
        Decimal dens = 7850;

        Long t0 = Datetime.now().getTime();
        Integer cpu0 = Limits.getCpuTime();
        Integer peakHeap = Limits.getHeapSize();

        Decimal acc = 0;
        for (Integer i = 0; i < n; i++) {
            Integer a = Math.mod(i, ods.size());
            Integer b = Math.mod(i, wts.size());
            acc += TubeUtils.calcRoundWeightKPM(ods[a], wts[b], dens);
            acc += TubeUtils.calcRoundWeightPPF(ods[a], wts[b], dens);
            peakHeap = Math.max(peakHeap, Limits.getHeapSize());
        }

        Long dt = Datetime.now().getTime() - t0;
        Integer cpu = Limits.getCpuTime() - cpu0;

        return makeResult('RoundWeight(KPM/PPF)', n * 2, dt, cpu, peakHeap, 'ODxWT combos, dens=7850');
    }

    private static BenchResult benchRectWeight(Integer n) {
        List<Decimal> widths  = new List<Decimal>{ 40, 60, 80, 100, 120, 150 };
        List<Decimal> heights = new List<Decimal>{ 20, 40, 50, 60, 80, 100 };
        List<Decimal> thicks  = new List<Decimal>{ 2, 3, 4, 5, 6 };
        Decimal dens = 7850;

        Long t0 = Datetime.now().getTime();
        Integer cpu0 = Limits.getCpuTime();
        Integer peakHeap = Limits.getHeapSize();

        Decimal acc = 0;
        for (Integer i = 0; i < n; i++) {
            Integer a = Math.mod(i, widths.size());
            Integer b = Math.mod(i, heights.size());
            Integer c = Math.mod(i, thicks.size());

            Decimal w = widths[a];
            Decimal h = heights[b];
            Decimal t = thicks[c];

            // гарантуємо валідність 2*t < min(w,h)
            if (2*t >= Math.min(w, h)) {
                Decimal halfMinus = (Math.min(w, h) - 1) / 2;
                t = Math.floor(halfMinus); // Math.floor повертає Decimal — ок
                if (t <= 0) t = 1;
            }

            acc += TubeUtils.calcRectWeightKPM(w, h, t, dens);
            acc += TubeUtils.calcRectWeightPPF(w, h, t, dens);
            peakHeap = Math.max(peakHeap, Limits.getHeapSize());
        }

        Long dt = Datetime.now().getTime() - t0;
        Integer cpu = Limits.getCpuTime() - cpu0;

        return makeResult('RectWeight(KPM/PPF)', n * 2, dt, cpu, peakHeap, 'WxHxt combos, dens=7850');
    }

    private static BenchResult benchMmToInches(Integer n) {
        List<Decimal> mms = new List<Decimal>{ 3.175, 6.35, 12.7, 25.4, 50.8, 88.9, 168.28, 244.48 };
        List<Integer> prec = new List<Integer>{ 2, 3, 4 };

        Long t0 = Datetime.now().getTime();
        Integer cpu0 = Limits.getCpuTime();
        Integer peakHeap = Limits.getHeapSize();

        Decimal acc = 0;
        for (Integer i = 0; i < n; i++) {
            Integer a = Math.mod(i, mms.size());
            Integer p = Math.mod(i, prec.size());
            acc += TubeUtils.mmToInches(mms[a], prec[p]);
            peakHeap = Math.max(peakHeap, Limits.getHeapSize());
        }

        Long dt = Datetime.now().getTime() - t0;
        Integer cpu = Limits.getCpuTime() - cpu0;

        return makeResult('mmToInches', n, dt, cpu, peakHeap, 'various precisions');
    }

    private static BenchResult benchMmToInchesFraction(Integer n) {
        List<Decimal> mms = new List<Decimal>{
            -30.1625, -12.7, 0, 3.175, 6.35, 50.8, 88.9, 168.28, 244.48, 152.3996
        };
        List<Integer> den = new List<Integer>{ 8, 16, 32 };

        Long t0 = Datetime.now().getTime();
        Integer cpu0 = Limits.getCpuTime();
        Integer peakHeap = Limits.getHeapSize();

        Integer len = mms.size();
        Integer lden = den.size();
        Integer ops = 0;

        for (Integer i = 0; i < n; i++) {
            Integer a = Math.mod(i, len);
            Integer d = Math.mod(i, lden);
            String s1 = TubeUtils.mmToInchesFraction(mms[a], den[d]);
            String s2 = TubeUtils.mmToInchesFraction(mms[a]); // дефолт 1/8"
            if (s1 != null && s2 != null && s1.length() > s2.length()) { ops++; }
            peakHeap = Math.max(peakHeap, Limits.getHeapSize());
        }

        Long dt = Datetime.now().getTime() - t0;
        Integer cpu = Limits.getCpuTime() - cpu0;

        return makeResult('mmToInchesFraction', n * 2, dt, cpu, peakHeap, 'den={8,16,32} + default');
    }

    private static BenchResult benchValidators(Integer n) {
        List<String> vals = new List<String>{ '123', '123.45', '-0.5', '', null, '1.', '.25', 'abc', '1,25' };

        Long t0 = Datetime.now().getTime();
        Integer cpu0 = Limits.getCpuTime();
        Integer peakHeap = Limits.getHeapSize();

        Integer trueCount = 0;
        for (Integer i = 0; i < n; i++) {
            Integer a = Math.mod(i, vals.size());
            if (TubeUtils.isNumber(vals[a])) trueCount++;
            if (TubeUtils.isDecimalRegex(vals[a])) trueCount++;
            peakHeap = Math.max(peakHeap, Limits.getHeapSize());
        }

        Long dt = Datetime.now().getTime() - t0;
        Integer cpu = Limits.getCpuTime() - cpu0;

        return makeResult('Validators(isNumber/isDecimalRegex)', n * 2, dt, cpu, peakHeap, 'mixed inputs');
    }

    // === ХЕЛПЕРИ ===

    private static BenchResult makeResult(String name, Integer iters, Long ms, Integer cpu, Integer peakHeap, String notes) {
        BenchResult r = new BenchResult();
        r.name = name;
        r.iterations = iters;
        r.ms = (ms <= 0 ? 1 : ms);
        r.cpuMs = cpu;
        r.peakHeapBytes = peakHeap;
        r.opsPerMs = Decimal.valueOf(String.valueOf(iters)) / Decimal.valueOf(String.valueOf(r.ms));
        r.notes = notes;
        return r;
    }

    // ==== CSV вивід ====

    private static String csvHeader() {
        return 'name,iterations,ms,cpuMs,peakHeapBytes,opsPerMs,notes';
    }

    private static String toCsv(BenchResult r) {
        // Проста екранування для CSV: подвійні лапки -> подвоїти, якщо є кома/лапки/пробіли — взяти у лапки
        List<String> cols = new List<String>{
            csvCell(r.name),
            String.valueOf(r.iterations),
            String.valueOf(r.ms),
            String.valueOf(r.cpuMs),
            String.valueOf(r.peakHeapBytes),
            // opsPerMs як строка з фіксованою шкалою (щоб у Sheets красивіше)
            (r.opsPerMs == null ? '' : String.valueOf(r.opsPerMs.setScale(6))),
            csvCell(r.notes)
        };
        return String.join(cols, ',');
    }

    private static String csvCell(String s) {
        if (s == null) return '';
        Boolean needQuotes = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
        String v = s.replace('"', '""');
        return needQuotes ? '"' + v + '"' : v;
    }
}