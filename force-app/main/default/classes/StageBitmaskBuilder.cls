public with sharing class StageBitmaskBuilder {

    public static Integer build(List<String> stages) {
        Integer mask = 0;

        for (String s : stages) {
            Integer bit = StageBitRegistry.getBit(s);
            if (bit != null) {
                mask |= bit;
            }
        }
        return mask;
    }
}