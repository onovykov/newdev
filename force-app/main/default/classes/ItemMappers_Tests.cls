@IsTest
private class ItemMappers_Tests {

    private static String sampleTubesJson() {
        // one valid, one missing PC to trigger skipped
        return ''
        + '{'
        + '  "Metadata": {"MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":1.0,"MsgTimestamp":"2025-10-13T12:20:35.117Z","PartNumber":1,"TotalParts":1},'
        + '  "Data": {'
        + '    "OrderType":"Tubes","OrderCurrency":"USD","Header": { "Undoc": 111 },'
        + '    "Items": ['
        + '      {'
        + '        "Undoc": 111, "Npp": 1, "IteNumber": "10",'
        + '        "ProductGroup": {"Name":"Tubes","Id":"PG1"},'
        + '        "ProductCharacteristic": {'
        + '          "Diameter": {"OD_mm": 114.0, "Name":"114","FacetCode":"DIA","Id":"D1"},'
        + '          "Thickness": {"Wt_mm": 6.0, "Name":"6","FacetCode":"WT","Id":"W1"}'
        + '        }'
        + '      },'
        + '      {'
        + '        "Undoc": 111, "Npp": 2, "IteNumber": "11"'
        + '      }'
        + '    ]'
        + '  }'
        + '}';
    }

    private static String sampleWheelsJson() {
        return ''
        + '{'
        + '  "Metadata": {"MsgType":"ERP-SF_OpportunityData","MsgTypeVersion":1.0,"MsgTimestamp":"2025-10-13T12:20:35.117Z","PartNumber":1,"TotalParts":1},'
        + '  "Data": {'
        + '    "OrderType":"Wheels","OrderCurrency":"EUR","Header": { "Undoc": 222 },'
        + '    "Items": ['
        + '      {'
        + '        "Undoc": 222, "Npp": 1, "IteNumber": "20",'
        + '        "ProductGroup": {"Name":"Wheels","Id":"PG2"},'
        + '        "ProductCharacteristic": {'
        + '          "Specification": 7,'
        + '          "Hub": {"Wt_mm": 110.0, "Name":"110","FacetCode":"HUB","Id":"H1"}'
        + '        }'
        + '      }'
        + '    ]'
        + '  }'
        + '}';
    }

    @IsTest static void tubes_mapper_counts() {
        OppDtoFactory.Parsed pt = OppDtoFactory.parse(sampleTubesJson());
        TubesData td = (TubesData) pt.data;
        ItemMapperResult r = TubesItemMapper.upsertItems(td.Items, pt.data.Header, pt.data.OrderCurrency);
        System.assertEquals(2, td.Items.size());
        System.assertEquals(1, r.itemsProcessed, 'one valid');
        System.assertEquals(1, r.itemsSkipped, 'one skipped due to missing PC');
        System.assertEquals(1, r.warnings.size(), 'one warning expected');
    }

    @IsTest static void wheels_mapper_counts() {
        OppDtoFactory.Parsed pw = OppDtoFactory.parse(sampleWheelsJson());
        WheelsData wd = (WheelsData) pw.data;
        ItemMapperResult r = WheelsItemMapper.upsertItems(wd.Items, pw.data.Header, pw.data.OrderCurrency);
        System.assertEquals(1, r.itemsProcessed);
        System.assertEquals(0, r.itemsSkipped);
    }

    @IsTest static void service_wires_mappers() {
        // Ensure service returns processed/skipped as mapper does
        OppProcessingService.Result r1 = OppProcessingService.processIncoming(sampleTubesJson());
        System.assertEquals('Tubes', r1.orderType);
        System.assertEquals(1, r1.processed);
        System.assertEquals(1, r1.skipped);

        OppProcessingService.Result r2 = OppProcessingService.processIncoming(sampleWheelsJson());
        System.assertEquals('Wheels', r2.orderType);
        System.assertEquals(1, r2.processed);
        System.assertEquals(0, r2.skipped);
    }
}