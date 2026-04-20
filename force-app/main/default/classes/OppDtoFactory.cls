public with sharing class OppDtoFactory {

    public class Parsed {
        public OppEnvelope.Metadata metadata;
        public OppEnvelope.DataBase data;
    }

    public static Parsed parse(String rawJson) {
        if (String.isBlank(rawJson)) {
            throw new AuraHandledException('Empty JSON');
        }

        Object rootObj = JSON.deserializeUntyped(rawJson);
        if (!(rootObj instanceof Map<String, Object>)) {
            throw new AuraHandledException('Root JSON must be an object');
        }

        Map<String, Object> root = (Map<String, Object>) rootObj;
        trimRecursively(root);

        if (!root.containsKey('Metadata')) {
            throw new AuraHandledException('JSON has no Metadata node');
        }
        if (!root.containsKey('Data')) {
            throw new AuraHandledException('JSON has no Data node');
        }

        Object metadataObj = root.get('Metadata');
        Object dataObj = root.get('Data');

        if (!(metadataObj instanceof Map<String, Object>)) {
            throw new AuraHandledException('Metadata must be an object');
        }
        if (!(dataObj instanceof Map<String, Object>)) {
            throw new AuraHandledException('Data must be an object');
        }

        Map<String, Object> metadataNode = (Map<String, Object>) metadataObj;
        Map<String, Object> dataNode = (Map<String, Object>) dataObj;

        OppEnvelope.Metadata metadata = buildMetadata(metadataNode);

        String orderType = asString(dataNode.get('OrderType'));
        if (String.isBlank(orderType)) {
            throw new AuraHandledException('Data.OrderType is blank');
        }

        OppEnvelope.DataBase dataDto;
        String dataJson = JSON.serialize(dataNode);

        if (orderType.equalsIgnoreCase('Tubes')) {
            TubesData tubes = (TubesData) JSON.deserialize(dataJson, TubesData.class);
            backfillTubesLocalizedNames(tubes, dataNode);
            normalizeTubesData(tubes);
            dataDto = tubes;
        } else if (orderType.equalsIgnoreCase('Wheels')) {
            dataDto = (WheelsData) JSON.deserialize(dataJson, WheelsData.class);
        } else {
            throw new AuraHandledException('Unsupported OrderType: ' + orderType);
        }

        Parsed result = new Parsed();
        result.metadata = metadata;
        result.data = dataDto;
        return result;
    }

    private static OppEnvelope.Metadata buildMetadata(Map<String, Object> mdNode) {
        OppEnvelope.Metadata md = new OppEnvelope.Metadata();

        md.MsgType = asString(mdNode.get('MsgType'));
        md.MsgTypeVersion = asString(mdNode.get('MsgTypeVersion'));
        md.MsgTimestampRaw = asString(mdNode.get('MsgTimestamp'));
        md.MsgTimestamp = normalizeDatetime(md.MsgTimestampRaw);
        md.PartNumber = toInteger(mdNode.get('PartNumber'));
        md.TotalParts = toInteger(mdNode.get('TotalParts'));

        return md;
    }

    private static void backfillTubesLocalizedNames(TubesData tubes, Map<String, Object> dataNode) {
        if (tubes == null || tubes.Items == null || dataNode == null) {
            return;
        }

        Object itemsObj = dataNode.get('Items');
        if (!(itemsObj instanceof List<Object>)) {
            return;
        }

        List<Object> rawItems = (List<Object>) itemsObj;
        Integer limitSize = Math.min(tubes.Items.size(), rawItems.size());

        for (Integer i = 0; i < limitSize; i++) {
            TubesData.Item dtoItem = tubes.Items[i];
            Object rawItemObj = rawItems[i];

            if (dtoItem == null || !(rawItemObj instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> rawItem = (Map<String, Object>) rawItemObj;

            Object pcObj = rawItem.get('ProductCharacteristic');
            if (!(pcObj instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> rawPc = (Map<String, Object>) pcObj;

            Object nameForDocObj = rawPc.get('NameForDoc');
            if (!(nameForDocObj instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> rawNameForDoc = (Map<String, Object>) nameForDocObj;

            Object localizedNameObj = rawNameForDoc.get('Name');
            if (!(localizedNameObj instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> rawLocalized = (Map<String, Object>) localizedNameObj;

            if (dtoItem.ProductCharacteristic == null) {
                continue;
            }
            if (dtoItem.ProductCharacteristic.NameForDoc == null) {
                continue;
            }
            if (dtoItem.ProductCharacteristic.NameForDoc.Name == null) {
                dtoItem.ProductCharacteristic.NameForDoc.Name = new TubesData.LocalizedName();
            }

            dtoItem.ProductCharacteristic.NameForDoc.Name.defaultLng =
                trimToNull(asString(rawLocalized.get('Default')));
            dtoItem.ProductCharacteristic.NameForDoc.Name.En =
                trimToNull(asString(rawLocalized.get('En')));
            dtoItem.ProductCharacteristic.NameForDoc.Name.Uk =
                trimToNull(asString(rawLocalized.get('Uk')));
        }
    }

    private static void normalizeTubesData(TubesData data) {
        if (data == null) {
            return;
        }

        data.OrderType = trimToNull(data.OrderType);
        data.OrderCurrency = trimToNull(data.OrderCurrency);

        if (data.Header != null) {
            normalizeHeader(data.Header);
        }

        if (data.Items == null) {
            return;
        }

        for (TubesData.Item item : data.Items) {
            normalizeTubesItem(item);
        }
    }

    private static void normalizeHeader(OppEnvelope.Header header) {
        if (header == null) {
            return;
        }

        header.IteNumber = trimToNull(header.IteNumber);
        header.AltNumber = trimToNull(header.AltNumber);
        header.PONumber = trimToNull(header.PONumber);
        header.ID_SF = trimToNull(header.ID_SF);
        header.BusinessSegmentId = trimToNull(header.BusinessSegmentId);
        header.RegionId = trimToNull(header.RegionId);
        header.CountryId = trimToNull(header.CountryId);
        header.CrossMarket_BusinessSegment = trimToNull(header.CrossMarket_BusinessSegment);

        if (header.Account != null) {
            header.Account.Name = trimToNull(header.Account.Name);
            header.Account.CountryId = trimToNull(header.Account.CountryId);
            header.Account.Address = trimToNull(header.Account.Address);
            header.Account.Id = trimToNull(header.Account.Id);
        }

        if (header.PaymentTerms != null) {
            header.PaymentTerms.Name = trimToNull(header.PaymentTerms.Name);
            header.PaymentTerms.Id = trimToNull(header.PaymentTerms.Id);
        }

        if (header.DeliveryTerms != null) {
            header.DeliveryTerms.Name = trimToNull(header.DeliveryTerms.Name);
            header.DeliveryTerms.Incoterms = trimToNull(header.DeliveryTerms.Incoterms);
            header.DeliveryTerms.Id = trimToNull(header.DeliveryTerms.Id);
        }

        normalizeUserRef(header.SalesRep);
        normalizeUserRef(header.BoSpecialist);
        normalizeUserRef(header.CrossMarket_SalesRep);
    }

    private static void normalizeUserRef(OppEnvelope.UserRef userRef) {
        if (userRef == null) {
            return;
        }

        userRef.Name = trimToNull(userRef.Name);
        userRef.UId = trimToNull(userRef.UId);
        userRef.UserId = trimToNull(userRef.UserId);
        userRef.Email = trimToNull(userRef.Email);
        userRef.Id = trimToNull(userRef.Id);
    }

    private static void normalizeTubesItem(TubesData.Item item) {
        if (item == null) {
            return;
        }

        item.IteNumber = trimToNull(item.IteNumber);
        item.KMAT = trimToNull(item.KMAT);
        item.InqUnit = trimToNull(item.InqUnit);
        item.FinStatus = trimToNull(item.FinStatus);
        item.Stage = trimToNull(item.Stage);
        item.CoatingSpec = trimToNull(item.CoatingSpec);
        item.NPS = trimToNull(item.NPS);
        item.SCH = trimToNull(item.SCH);
        item.Mark1 = trimToNull(item.Mark1);

        if (item.ProductGroup != null) {
            item.ProductGroup.Name = trimToNull(item.ProductGroup.Name);
            item.ProductGroup.Id = trimToNull(item.ProductGroup.Id);
        }

        if (item.QuotaType != null) {
            item.QuotaType.Name = trimToNull(item.QuotaType.Name);
            item.QuotaType.Id = trimToNull(item.QuotaType.Id);

            if (item.QuotaType.Shop != null) {
                item.QuotaType.Shop.Name = trimToNull(item.QuotaType.Shop.Name);
                item.QuotaType.Shop.Id = trimToNull(item.QuotaType.Shop.Id);
            }
        }

        if (item.Shop != null) {
            item.Shop.Name = trimToNull(item.Shop.Name);
            item.Shop.Id = trimToNull(item.Shop.Id);

            if (item.Shop.Mill != null) {
                item.Shop.Mill.Name = trimToNull(item.Shop.Mill.Name);
                item.Shop.Mill.Id = trimToNull(item.Shop.Mill.Id);
            }
        }

        if (item.ShippingPoint != null) {
            item.ShippingPoint.spType = trimToNull(item.ShippingPoint.spType);
            item.ShippingPoint.Id = trimToNull(item.ShippingPoint.Id);
            item.ShippingPoint.Name = trimToNull(item.ShippingPoint.Name);
        }

        if (item.SpecLevel != null) {
            item.SpecLevel.Name = trimToNull(item.SpecLevel.Name);
            item.SpecLevel.Id = trimToNull(item.SpecLevel.Id);
        }

        if (item.ProductCharacteristic != null) {
            normalizeProductCharacteristic(item.ProductCharacteristic);
        }
    }

    private static void normalizeProductCharacteristic(TubesData.ProductCharacteristic pc) {
        if (pc == null) {
            return;
        }

        normalizeDiameter(pc.Diameter);
        normalizeThickness(pc.Thickness);
        normalizeLengthSize(pc.LengthSize);
        normalizeProductOption(pc.Ends);
        normalizeProductOption(pc.Coating);
        normalizeSteelGrade(pc.SteelGrade);
        normalizeStandard(pc.Standard);

        if (pc.NameForDoc != null) {
            pc.NameForDoc.Id = trimToNull(pc.NameForDoc.Id);

            if (pc.NameForDoc.Name != null) {
                pc.NameForDoc.Name.defaultLng = trimToNull(pc.NameForDoc.Name.defaultLng);
                pc.NameForDoc.Name.En = trimToNull(pc.NameForDoc.Name.En);
                pc.NameForDoc.Name.Uk = trimToNull(pc.NameForDoc.Name.Uk);
            }
        }
    }

    private static void normalizeDiameter(TubesData.Diameter dto) {
        if (dto == null) {
            return;
        }

        dto.Name = trimToNull(dto.Name);
        dto.FacetCode = trimToNull(dto.FacetCode);
        dto.Id = trimToNull(dto.Id);

        if (dto.Facet == null) {
            dto.Facet = buildFacet(dto.FacetCode, dto.Id);
        } else {
            dto.Facet.Code = trimToNull(dto.Facet.Code);
            dto.Facet.Id = trimToNull(dto.Facet.Id);
        }
    }

    private static void normalizeThickness(TubesData.Thickness dto) {
        if (dto == null) {
            return;
        }

        dto.Name = trimToNull(dto.Name);
        dto.FacetCode = trimToNull(dto.FacetCode);
        dto.Id = trimToNull(dto.Id);

        if (dto.Facet == null) {
            dto.Facet = buildFacet(dto.FacetCode, dto.Id);
        } else {
            dto.Facet.Code = trimToNull(dto.Facet.Code);
            dto.Facet.Id = trimToNull(dto.Facet.Id);
        }
    }

    private static void normalizeLengthSize(TubesData.LengthSize dto) {
        if (dto == null) {
            return;
        }

        dto.Name = trimToNull(dto.Name);
        dto.FacetCode = trimToNull(dto.FacetCode);
        dto.Id = trimToNull(dto.Id);

        if (dto.Facet == null) {
            dto.Facet = buildFacet(dto.FacetCode, dto.Id);
        } else {
            dto.Facet.Code = trimToNull(dto.Facet.Code);
            dto.Facet.Id = trimToNull(dto.Facet.Id);
        }
    }

    private static void normalizeProductOption(TubesData.ProductOption dto) {
        if (dto == null) {
            return;
        }

        dto.Name = trimToNull(dto.Name);
        dto.FacetCode = trimToNull(dto.FacetCode);
        dto.Id = trimToNull(dto.Id);

        if (dto.Facet == null) {
            dto.Facet = buildFacet(dto.FacetCode, dto.Id);
        } else {
            dto.Facet.Code = trimToNull(dto.Facet.Code);
            dto.Facet.Id = trimToNull(dto.Facet.Id);
        }
    }

    private static void normalizeSteelGrade(TubesData.SteelGrade dto) {
        if (dto == null) {
            return;
        }

        dto.Name = trimToNull(dto.Name);
        dto.FacetCode = trimToNull(dto.FacetCode);
        dto.Id = trimToNull(dto.Id);

        if (dto.Facet == null) {
            dto.Facet = buildFacet(dto.FacetCode, dto.Id);
        } else {
            dto.Facet.Code = trimToNull(dto.Facet.Code);
            dto.Facet.Id = trimToNull(dto.Facet.Id);
        }
    }

    private static void normalizeStandard(TubesData.Standard dto) {
        if (dto == null) {
            return;
        }

        dto.Id = trimToNull(dto.Id);
        dto.Name = trimToNull(dto.Name);
        dto.FacetCode = trimToNull(dto.FacetCode);
        dto.FacetId = trimToNull(dto.FacetId);

        if (dto.Facet == null) {
            dto.Facet = buildFacet(dto.FacetCode, dto.FacetId);
        } else {
            dto.Facet.Code = trimToNull(dto.Facet.Code);
            dto.Facet.Id = trimToNull(dto.Facet.Id);
        }

        if (dto.StdNameRef == null) {
            dto.StdNameRef = buildNameRef(dto.Id, dto.Name);
        } else {
            dto.StdNameRef.Id = trimToNull(dto.StdNameRef.Id);
            dto.StdNameRef.Name = trimToNull(dto.StdNameRef.Name);
        }
    }

    private static TubesData.FacetRef buildFacet(String code, String idVal) {
        String cleanCode = trimToNull(code);
        String cleanId = trimToNull(idVal);

        if (cleanCode == null && cleanId == null) {
            return null;
        }

        TubesData.FacetRef facet = new TubesData.FacetRef();
        facet.Code = cleanCode;
        facet.Id = cleanId;
        return facet;
    }

    private static TubesData.NameRef buildNameRef(String idVal, String nameVal) {
        String cleanId = trimToNull(idVal);
        String cleanName = trimToNull(nameVal);

        if (cleanId == null && cleanName == null) {
            return null;
        }

        TubesData.NameRef ref = new TubesData.NameRef();
        ref.Id = cleanId;
        ref.Name = cleanName;
        return ref;
    }

    private static Datetime normalizeDatetime(String raw) {
        String value = trimToNull(raw);
        if (value == null) {
            return null;
        }

        if (value.length() >= 19) {
            value = value.substring(0, 19);
        } else if (value.length() == 10) {
            value = value + 'T00:00:00';
        }

        value = value.replace('T', ' ');
        return Datetime.valueOf(value);
    }

    private static Integer toInteger(Object raw) {
        if (raw == null) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(raw)).intValue();
    }

    private static String asString(Object raw) {
        return raw == null ? null : String.valueOf(raw).trim();
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();
        return trimmed == '' ? null : trimmed;
    }

    private static void trimRecursively(Object node) {
        if (node == null) {
            return;
        }

        if (node instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) node;
            List<String> keys = new List<String>(m.keySet());

            for (String key : keys) {
                Object val = m.get(key);

                if (val instanceof String) {
                    m.put(key, ((String) val).trim());
                } else {
                    trimRecursively(val);
                }
            }
            return;
        }

        if (node instanceof List<Object>) {
            List<Object> items = (List<Object>) node;

            for (Integer i = 0; i < items.size(); i++) {
                Object val = items[i];

                if (val instanceof String) {
                    items[i] = ((String) val).trim();
                } else {
                    trimRecursively(val);
                }
            }
        }
    }
}