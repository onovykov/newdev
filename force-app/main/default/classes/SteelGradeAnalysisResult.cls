public class SteelGradeAnalysisResult {
    public Integer total = 0;
    public Integer pure = 0;
    public Integer composite = 0;
    public Integer multi = 0;
    public Integer garbage = 0;

    public Map<String, Integer> gradeFreq = new Map<String, Integer>();
    public Map<String, Integer> attrFreq = new Map<String, Integer>();
    public Map<String, Integer> comboFreq = new Map<String, Integer>();

    public void inc(Map<String, Integer> m, String key) {
        m.put(key, (m.containsKey(key) ? m.get(key) : 0) + 1);
    }
}