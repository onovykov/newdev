public class ProdSteelStandardParser {

    // EN 13262:2004+A2:2011
    private static final Pattern EDITION_PATTERN =
        Pattern.compile('(?i)(:|\\s)(\\d{4}(?:\\+A\\d(?::\\d{4})?)?)');

    // PSL1, PSL2, ISO 3183, TC1
    private static final Pattern SUBSPEC_PATTERN =
        Pattern.compile('(?i)\\b(PSL\\s*[12]|ISO\\s*3183|TC\\d+)\\b');

    // trash
    private static final Pattern TRASH_PATTERN =
        Pattern.compile('(?i)ПО\\s*ТУ|СПЕЦИФИКАЦ|СОГЛАСОВАН');

    public static List<StandardParseResult> parse(String legacyName) {

        List<StandardParseResult> out = new List<StandardParseResult>();

        if (String.isBlank(legacyName)) {
            out.add(StandardParseResult.trash(null, 'empty'));
            return out;
        }

        // split composite standards
        List<String> tokens = legacyName.split('\\s*/\\s*');

        if (tokens.size() > 1) {
            for (String t : tokens) {
                out.addAll(parse(t));
            }
            return out;
        }

        String token = legacyName.trim();

        if (TRASH_PATTERN.matcher(token).find()) {
            out.add(StandardParseResult.trash(token, 'trash:pattern'));
            return out;
        }

        String canonical = SteelStandardAliasResolver.resolve(token);

        if (canonical == null) {
            out.add(StandardParseResult.trash(token, 'base:not-found'));
            return out;
        }

        Matcher mEdition = EDITION_PATTERN.matcher(token);
        Matcher mSub = SUBSPEC_PATTERN.matcher(token);

        String edition = null;

        if (mEdition.find()) {
            edition = mEdition.group(2);
        } else if (mSub.find()) {
            edition = mSub.group(1).replaceAll('\\s+', '');
        }

        if (edition != null) {
            out.add(StandardParseResult.edition(token, canonical, edition, 'edition:regex'));
        } else {
            out.add(StandardParseResult.base(token, canonical, 'base:alias'));
        }

        return out;
    }
}
