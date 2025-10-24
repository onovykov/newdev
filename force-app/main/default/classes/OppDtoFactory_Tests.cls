@IsTest
private class OppDtoFactory_Tests {

    private static String sampleTubesJson() {
        return ''
        + '{'
        + '  "Metadata": {'
        + '    "MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":1.0,'
        + '    "MsgTimestamp":"2025-10-13T12:20:35.117Z","PartNumber":1,"TotalParts":1'
        + '  },'
        + '  "Data": {'
        + '    "OrderType":"Tubes",'
        + '    "OrderCurrency":"USD",'
        + '    "Header": { "Undoc": 12345, "IteNumber":"IT-1" },'
        + '    "Items": ['
        + '      {'
        + '        "Undoc": 12345,'
        + '        "Npp": 1,'
        + '        "IteNumber": "10",'
        + '        "ProductGroup": {"Name":"Tubes","Id":"PG1"},'
        + '        "InqQuantity": 10.5,'
        + '        "Price_t": 520.00,'
        + '        "ProductCharacteristic": {'
        + '          "Diameter": {"OD_mm": 102.0, "Name":"102,00", "FacetCode":"DIMP", "Id":"1Y"},'
        + '          "Thickness": {"Wt_mm": 5.5, "Name":"5,5", "FacetCode":"WT", "Id":"2Z"},'
        + '          "LengthSize": {"MinLength": 6000, "MaxLength": 12000, "Name":"6-12m", "FacetCode":"LEN", "Id":"3X"},'
        + '          "Ends": {"Name":"PE","FacetCode":"END","Id":"END1"},'
        + '          "Coating": {"Name":"BW","FacetCode":"COAT","Id":"CO1"},'
        + '          "Standard": {"Name":"EN10219","Id":"STD1"},'
        + '          "SteelGrade": {"Name":"S235","FacetCode":"SG","Id":"SG1"},'
        + '          "NameForDoc": {"Id":"NFD1","Name":{"Default":"Pipe","En":"Pipe","Uk":"Труба"}}'
        + '        }'
        + '      }'
        + '    ]'
        + '  }'
        + '}';
    }

    private static String sampleWheelsJson() {
        return ''
        + '{'
        + '  "Metadata": {'
        + '    "MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":1.0,'
        + '    "MsgTimestamp":"2025-10-13T12:20:35.117Z","PartNumber":1,"TotalParts":1'
        + '  },'
        + '  "Data": {'
        + '    "OrderType":"Wheels",'
        + '    "OrderCurrency":"EUR",'
        + '    "Header": { "Undoc": 67890, "IteNumber":"IT-2" },'
        + '    "Items": ['
        + '      {'
        + '        "Undoc": 67890,'
        + '        "Npp": 1,'
        + '        "IteNumber": "20",'
        + '        "ProductGroup": {"Name":"Wheels","Id":"PG2"},'
        + '        "InqQuantity": 5,'
        + '        "Price_t": 800.00,'
        + '        "ProductCharacteristic": {'
        + '          "Specification": 7,'
        + '          "Diameter": {"OD_mm": 920.0, "Name":"920", "FacetCode":"DIA", "Id":"WD1"},'
        + '          "Hub": {"Wt_mm": 110.0, "Name":"110", "FacetCode":"HUB", "Id":"HUB1"},'
        + '          "Drawing": {"Name":"DRW-01","FacetCode":"DRAW","Id":"DR1"},'
        + '          "Standard": {"Name":"GOST","Id":"WSTD"},'
        + '          "SteelGrade": {"Name":"ER7","FacetCode":"SG","Id":"WSG"},'
        + '          "NameForDoc": {"Id":"WNFD1","Name":{"Default":"Wheel","En":"Wheel","Uk":"Колесо"}}'
        + '        }'
        + '      }'
        + '    ]'
        + '  }'
        + '}';
    }

    @IsTest static void parse_Tubes_and_Wheels() {
        // Tubes
        OppDtoFactory.Parsed pt = OppDtoFactory.parse(sampleTubesJson());
        System.assertNotEquals(null, pt, 'Parsed should not be null');
        System.assertEquals('Tubes', pt.data.OrderType, 'OrderType');
        System.assert(pt.data instanceof TubesData, 'Data should be TubesData');
        TubesData td = (TubesData) pt.data;
        System.assertEquals(1, td.Items.size(), 'Items count');
        System.assertEquals(102.0, td.Items[0].ProductCharacteristic.Diameter.OD_mm);

        // Wheels
        OppDtoFactory.Parsed pw = OppDtoFactory.parse(sampleWheelsJson());
        System.assertEquals('Wheels', pw.data.OrderType, 'OrderType');
        System.assert(pw.data instanceof WheelsData, 'Data should be WheelsData');
        WheelsData wd = (WheelsData) pw.data;
        System.assertEquals(1, wd.Items.size(), 'Items count');
        System.assertEquals(110.0, wd.Items[0].ProductCharacteristic.Hub.Wt_mm);
    }

    @IsTest static void service_process_counts() {
        OppProcessingService.Result r1 = OppProcessingService.processIncoming(sampleTubesJson());
        System.assertEquals('Tubes', r1.orderType);
        System.assertEquals(1, r1.processed);
        System.assertEquals('USD', r1.orderCurrency);

        OppProcessingService.Result r2 = OppProcessingService.processIncoming(sampleWheelsJson());
        System.assertEquals('Wheels', r2.orderType);
        System.assertEquals(1, r2.processed);
        System.assertEquals('EUR', r2.orderCurrency);
    }

    @IsTest static void invalid_type_throws() {
        Boolean thrown = false;
        try {
            OppProcessingService.processIncoming('{ "Metadata":{}, "Data": {"OrderType":"Unknown"} }');
        } catch (Exception e) {
            thrown = true;
        }
        System.assert(thrown, 'Unsupported OrderType should throw');
    }
}