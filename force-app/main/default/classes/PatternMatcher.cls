public class PatternMatcher {
    public static Boolean matches(String input, String regex) {
        if (String.isBlank(input) || String.isBlank(regex)) return false;
        try {
            Pattern p = Pattern.compile(regex);
            Matcher m = p.matcher(input);
            return m.find();
        } catch (Exception e) {
            System.debug('Invalid regex: ' + regex);
            return false;
        }
    }
}