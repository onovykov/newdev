public with sharing class EDI_ORDERS05_Parser implements IEdiParser {

    // =====================================
    // INTERFACE METHOD (єдиний parse)
    // =====================================
    public Object parse(String xmlString) {
        return parseInternal(xmlString);
    }

    // =====================================
    // STATIC (BACKWARD COMPATIBILITY)
    // =====================================
    public static EDI_ORDERS05_DTO parseToDto(String xmlString) {
        return parseInternal(xmlString);
    }

    // =====================================
    // CORE LOGIC
    // =====================================
    private static EDI_ORDERS05_DTO parseInternal(String xmlString) {

        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);

        Dom.XmlNode root = doc.getRootElement(); // ORDERS05
        Dom.XmlNode idoc = root.getChildElement('IDOC', null);

        EDI_ORDERS05_DTO dto = new EDI_ORDERS05_DTO();

        // =====================================
        // HEADER
        // =====================================
        for (Dom.XmlNode node : idoc.getChildElements()) {

            String name = node.getName();

            if (name == 'EDI_DC40') {
                dto.documentNumber = getChildText(node, 'ARCKEY');
            }

            if (name == 'E1EDK03') {
                String iddat = getChildText(node, 'IDDAT');

                if (iddat == '002') {
                    String dateStr = getChildText(node, 'DATUM');
                    dto.requestedDeliveryDate = parseDate(dateStr);
                }
            }
        }

        // =====================================
        // ITEMS
        // =====================================
        for (Dom.XmlNode node : idoc.getChildElements()) {

            if (node.getName() != 'E1EDP01') continue;

            EDI_ORDERS05_DTO.Item item =
                new EDI_ORDERS05_DTO.Item();

            item.sapItemNumber = getChildText(node, 'POSEX');

            String qty = getChildText(node, 'MENGE');
            if (qty != null) {
                item.quantity = Decimal.valueOf(qty);
            }

            for (Dom.XmlNode child : node.getChildElements()) {

                if (child.getName() == 'E1EDP19') {

                    String qualf = getChildText(child, 'QUALF');
                    String idtnr = getChildText(child, 'IDTNR');

                    if (qualf == '001') {
                        item.materialNumber = idtnr;
                    }

                    if (qualf == 'ZIT') {
                        item.extKey = idtnr;
                    }
                }
            }

            dto.items.add(item);
        }

        return dto;
    }

    // =====================================
    // HELPERS
    // =====================================
    private static String getChildText(Dom.XmlNode node, String name) {
        Dom.XmlNode child = node.getChildElement(name, null);
        return child != null ? child.getText() : null;
    }

    private static Date parseDate(String sapDate) {

        if (String.isBlank(sapDate) || sapDate.length() != 8) {
            return null;
        }

        Integer year  = Integer.valueOf(sapDate.substring(0, 4));
        Integer month = Integer.valueOf(sapDate.substring(4, 6));
        Integer day   = Integer.valueOf(sapDate.substring(6, 8));

        return Date.newInstance(year, month, day);
    }
}
