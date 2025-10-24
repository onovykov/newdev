public class ERPMessageHandlerKbSpec {

    private static Set<String> specificationIdSet = new Set<String>();
    private static Set<String> assemblyIdSet = new Set<String>();
    private static Set<String> certificateIdSet = new Set<String>();
    private static Set<String> accountIdSet = new Set<String>();
    private static Set<String> drawingBaseIdSet = new Set<String>();
    private static Set<String> drawingVersionIdSet = new Set<String>();
    private static Set<String> steelGradeIdSet = new Set<String>();
    private static Set<String> diameterIdSet = new Set<String>();
    private static Set<String> countryIdSet = new Set<String>();
    private static Set<String> nameForDocIdSet = new Set<String>();

    private static Map<String, Id> prodKindMap;
    private static Map<String, Id> prodTypeMap;
    private static Map<String, Id> plugTypeMap;
    private static Map<String, Id> existedDrawingBaseMap;
    private static Map<String, Id> wheelPurposeMap;
    private static Map<String, Id> docStageMap;
    private static Map<String, Id> existedDrawingVersionMap;
    private static Map<String, Id> steelGradeMap;
    private static Map<String, Id> axialLoadTypeMap;
    private static Map<String, Id> diameterMap;
    private static Map<String, Id> wheelHubMap;
    private static Map<String, Id> hubBoreMap;
    private static Map<String, Id> standardMap;
    private static Map<String, Id> imbalanceMap;
    private static Map<String, Id> existedSpecBaseMap;
    private static Map<String, Id> accountMap;
    private static Map<String, Id> countryMap;
    private static Map<String, Id> existedSpecVersioneMap;
    private static Map<String, Id> shapeMap;
    private static Map<String, Id> nameForDocMap;
    private static Map<String, Id> markingMap;
    private static Map<String, Id> coatingTypeMap;
    private static Map<String, Id> coatingMaterialMap;
    private static Map<String, Id> packingMap;
    private static Map<String, Id> wheelComponentMap;
    private static Map<String, Id> producerMap;
    private static Map<String, Id> inspectionMap;
    private static Map<String, Id> assemblyMap;
    private static Map<String, Id> certificateMap;

    public static MessageProcessingResult processMessage(ERPMessageParser.ErpToSfMessage_KbSpec parsedMessage) {
        MessageProcessingResult res = new MessageProcessingResult();
        res.MessageType = parsedMessage.metadata.MsgType;

        try {
            getdSets(parsedMessage.data);
            createObjectsMaps();
            Map<String, DrawingBase__c> drawingBaseMap = createDrawingBases(parsedMessage.data); 
            Map<String, DrawingVersion__c> drawingVersionMap = createDrawingVersions(parsedMessage.data, drawingBaseMap);
            Map<String, SpecificationBase__c> specBaseMap = createSpecBases(parsedMessage.data);
            Map<String, SpecVersion__c> specVersionMap = createSpecVersions(parsedMessage.data,  specBaseMap, drawingVersionMap);
            createRelatedRecords(parsedMessage.data, specVersionMap);

            return res;

        } catch (Exception e) {
            Triton.instance.error(TritonTypes.Area.NewSpecification, e);
            res.error = e.getMessage() + ' : ' + e.getLineNumber();
            return res;
        }
    }

    private static Map<String, DrawingBase__c> createDrawingBases(ERPMessageParser.SpecMessageData data) {
        Map<String, DrawingBase__c> drawingBaseToUpsertMap = new Map<String, DrawingBase__c>();

        for(ERPMessageParser.ERPObject_SpecItem specItem : data.Items) {
            DrawingBase__c drawingBase = new DrawingBase__c();
            ERPMessageParser.ERPObject_DrawingVersion drawingVersion = specItem.DrawingVersion;
            if(existedDrawingBaseMap.get(String.valueOf(drawingVersion.Id)) != null) {
                drawingBase.Id = existedDrawingBaseMap.get(String.valueOf(drawingVersion.DrawingId));
            }
            drawingBase.ID_ERP__c = String.valueOf(drawingVersion.DrawingId);
            drawingBase.Name = drawingVersion.Ndm;
            drawingBase.Revision__c = String.valueOf(drawingVersion.Revision);
            drawingBase.Version__c = String.valueOf(drawingVersion.Version);
            drawingBase.Comments__c = drawingVersion.Comments;
            drawingBase.Purpose__c = drawingVersion.Purpose != null ? wheelPurposeMap.get(drawingVersion.Purpose.Id) : null;
            drawingBase.DrawingFacet__c = drawingVersion.DrawingFacet != null ? drawingVersion.DrawingFacet.Id : null;
            drawingBase.CertGroup__c = drawingVersion.CertGroup != null ? drawingVersion.CertGroup.Id : null;
            drawingBase.ValidBefore__c = drawingVersion.CertGroup != null ? drawingVersion.CertValidBefore.date() : null;
            drawingBase.IsActive__c = drawingVersion.IsActive;
            drawingBase.Stage__c = drawingVersion.Stage != null ? docStageMap.get(drawingVersion.Stage.Id + '' + 'Draw') : null;
            drawingBase.ProductKind__c = drawingVersion.Product != null && drawingVersion.Product.ProductType != null ? prodKindMap.get(drawingVersion.Product.ProductType.Id) : null;
            drawingBase.Product__c = drawingVersion.Product != null ? prodTypeMap.get(drawingVersion.Product.Id) : null;

            drawingBaseToUpsertMap.put(drawingBase.ID_ERP__c, drawingBase);                  
        }

        upsert drawingBaseToUpsertMap.values();
        Formula.recalculateFormulas(drawingBaseToUpsertMap.values());

        return drawingBaseToUpsertMap;
    }

    private static Map<String, DrawingVersion__c> createDrawingVersions(ERPMessageParser.SpecMessageData data, Map<String, DrawingBase__c> drawingBaseMap) {
        Map<String, DrawingVersion__c> drawingVersionToUpsertMap = new Map<String, DrawingVersion__c>();

        for(ERPMessageParser.ERPObject_SpecItem specItem : data.Items) {
            DrawingVersion__c drawingVersionToUpsert = new DrawingVersion__c();
            ERPMessageParser.ERPObject_DrawingVersion drawingVersion = specItem.DrawingVersion;
            if(existedDrawingVersionMap.get(String.valueOf(drawingVersion.Id)) != null) {
                drawingVersionToUpsert.Id = existedDrawingVersionMap.get(String.valueOf(drawingVersion.Id));
            }

            drawingVersionToUpsert.ID_ERP__c = String.valueOf(drawingVersion.Id);
            drawingVersionToUpsert.DrawingBase__c = drawingBaseMap.get(String.valueOf(drawingVersion.DrawingId)).Id;
            drawingVersionToUpsert.Name = drawingBaseMap.get(String.valueOf(drawingVersion.DrawingId)).Title__c;
            drawingVersionToUpsert.SteelGrade__c = drawingVersion.SteelGrade != null ? steelGradeMap.get(drawingVersion.SteelGrade.Id) : null;
            drawingVersionToUpsert.AxLoadType__c = drawingVersion.TypeAxload != null ? axialLoadTypeMap.get(drawingVersion.TypeAxload.Id) : null;
            drawingVersionToUpsert.AxLoad_T__c = drawingVersion.Axload;
            drawingVersionToUpsert.Diameter__c = drawingVersion.Diameter != null ? diameterMap.get(drawingVersion.Diameter.Id) : null;
            drawingVersionToUpsert.Hub__c = drawingVersion.DiameterHub != null ? wheelHubMap.get(drawingVersion.DiameterHub.Id) : null;
            drawingVersionToUpsert.HubBore__c = drawingVersion.HubBore != null ? hubBoreMap.get(drawingVersion.HubBore.Id) : null;
            drawingVersionToUpsert.Groove__c = drawingVersion.Groove;
            drawingVersionToUpsert.HubOffset__c = drawingVersion.HubOffset;
            drawingVersionToUpsert.Standard__c = drawingVersion.Standard != null ? standardMap.get(drawingVersion.Standard.Id) : null;
            drawingVersionToUpsert.Imbalance__c = drawingVersion.Imbalance != null ? imbalanceMap.get(drawingVersion.Imbalance.Id) : null;
            drawingVersionToUpsert.PlugType__c = drawingVersion.TypePlug != null ? plugTypeMap.get(drawingVersion.TypePlug.Id) : null;
            drawingVersionToUpsert.WeightKG__c = drawingVersion.WeightKg;
            drawingVersionToUpsert.DiamB__c = drawingVersion.DiamB;
            drawingVersionToUpsert.DiamJ__c = drawingVersion.DiamJ;
            drawingVersionToUpsert.Length__c = drawingVersion.Length;
            drawingVersionToUpsert.Distance__c = drawingVersion.DistanceWheels;

            drawingVersionToUpsertMap.put(drawingVersionToUpsert.ID_ERP__c, drawingVersionToUpsert);                  
        }

        upsert drawingVersionToUpsertMap.values();
        return drawingVersionToUpsertMap;
    }

    private static Map<String, SpecificationBase__c> createSpecBases(ERPMessageParser.SpecMessageData data) {
        Map<String, SpecificationBase__c> specBaseToUpsertMap = new Map<String, SpecificationBase__c>();

        for(ERPMessageParser.ERPObject_SpecItem specItem : data.Items) {
            SpecificationBase__c specBase = new SpecificationBase__c();
            if(existedSpecBaseMap.get(String.valueOf(specItem.Id)) != null) {
                specBase.Id = existedSpecBaseMap.get(String.valueOf(specItem.Id));
            }

            specBase.ID_ERP__c = String.valueOf(specItem.Id);
            specBase.Name = specItem.Ndm;
            specBase.Parent__c = existedSpecBaseMap.get(String.valueOf(specItem.ParentSpecId));
            specBase.Revision__c = String.valueOf(specItem.Revision);
            specBase.Comments__c = specItem.Comments;
            specBase.Account__c = specItem.Client != null ? accountMap.get(specItem.Client.Id) : null;
            specBase.Country__c = specItem.Client != null ? countryMap.get(String.valueOf(specItem.Client.CountryId)) : null;
            specBase.ClientSpec__c = specItem.ClientSpec;
            specBase.ValidBefore__c = specItem.ValidBefore != null && String.valueOf(specItem.ValidBefore) != '0001-01-03 02:00:00' ? specItem.ValidBefore.date() : null;
            specBase.IsActive__c = specItem.IsActive;
            specBase.Stage__c = specItem.Stage != null ? docStageMap.get(specItem.Stage.Id + '' + 'Spec') : null;
            specBase.ProductKind__c = specItem.Product != null && specItem.Product.ProductType != null ? prodKindMap.get(specItem.Product.ProductType.Id) : null;
            specBase.ProductType__c = specItem.Product != null ? prodTypeMap.get(specItem.Product.Id) : null;

            specBaseToUpsertMap.put(specBase.ID_ERP__c, specBase);                  
        }

        upsert specBaseToUpsertMap.values();
        Formula.recalculateFormulas(specBaseToUpsertMap.values());

        return specBaseToUpsertMap;
    }

    private static Map<String, SpecVersion__c> createSpecVersions(ERPMessageParser.SpecMessageData data,  Map<String, SpecificationBase__c> specBaseMap, Map<String, DrawingVersion__c> drawingVersionMap) {
        Map<String, SpecVersion__c> specVersionToUpsertMap = new Map<String, SpecVersion__c>();

        for(ERPMessageParser.ERPObject_SpecItem specItem : data.Items) {
            SpecVersion__c specVersion = new SpecVersion__c();
            if(existedSpecVersioneMap.get(String.valueOf(specItem.Id)) != null) {
                specVersion.Id = existedSpecVersioneMap.get(String.valueOf(specItem.Id));
            }

            specVersion.ID_ERP__c = String.valueOf(specItem.Id);
            specVersion.Name = specBaseMap.get(String.valueOf(specItem.Id)).Title__c;
            specVersion.SpecBase__c = specBaseMap.get(String.valueOf(specItem.Id)).Id;
            specVersion.Shape__c = specItem.Shape != null ? shapeMap.get(specItem.Shape.Id) : null;
            specVersion.ExecCategory__c = specItem.ExecCategory != null ? specItem.ExecCategory.Id : null;
            specVersion.NameForDoc__c = specItem.NameForDoc != null ? nameForDocMap.get(specItem.NameForDoc.Id) : null;
            specVersion.Marking__c = specItem.Marking != null ? markingMap.get(String.valueOf(specItem.Marking.Id)) : null;
            specVersion.Imbalance__c = specItem.Imbalance != null ? imbalanceMap.get(specItem.Imbalance.Id) : null;
            specVersion.OilHole__c = specItem.OilHole;
            specVersion.PlugType__c = specItem.TypePlug != null ? plugTypeMap.get(specItem.TypePlug.Id) : null;
            specVersion.CoatingType__c = specItem.CoatingType != null ? coatingTypeMap.get(specItem.CoatingType.Id) : null;
            specVersion.Coating__c = specItem.CoatingMaterial != null ? coatingMaterialMap.get(specItem.CoatingMaterial.Id) : null;
            specVersion.Packing__c = specItem.Packing != null ? packingMap.get(specItem.Packing.Id) : null;
            specVersion.Inspection__c = specItem.Inspection != null ? inspectionMap.get(specItem.Inspection.Id) : null;
            specVersion.HasSpecReq__c = specItem.HasSpecialRequirements != null ? specItem.HasSpecialRequirements : false;
            specVersion.SteelGrade__c = specItem.SteelGrade != null ? steelGradeMap.get(specItem.SteelGrade.Id) : specItem.SteelGradeIPS != null ? steelGradeMap.get(specItem.SteelGradeIPS.Id) : null;
            specVersion.WeightKG__c = specItem.WeightKg;
            specVersion.Purpose__c = specItem.Purpose != null ? wheelPurposeMap.get(specItem.Purpose.Id) : null;
            specVersion.Axlebox__c = specItem.Axlebox != null ? wheelComponentMap.get(specItem.Axlebox.Id) : null;
            specVersion.BoxProducer__c = specItem.ProducerAxlebox != null ? producerMap.get(specItem.ProducerAxlebox.Id) : null;
            specVersion.Bearer__c = specItem.Bearer != null ? wheelComponentMap.get(specItem.Bearer.Id) : null;
            specVersion.BearerProducer__c = specItem.ProducerBearer != null ? producerMap.get(specItem.ProducerBearer.Id) : null;
            specVersion.WeightBoxKG__c = specItem.WeightAxleboxKg;
            specVersion.WeightAllKG__c = specItem.WeightAllKg;
            specVersion.DrawingVersion__c = drawingVersionMap.get(String.valueOf(specItem.DrawingVersion.Id)).Id;
            specVersion.SpecAxle__c = existedSpecVersioneMap.get(String.valueOf(specItem.SpecAxleId));
            specVersion.SpecWheel__c = existedSpecVersioneMap.get(String.valueOf(specItem.SpecWheelId));

            specVersionToUpsertMap.put(specVersion.ID_ERP__c, specVersion);                  
        }

        upsert specVersionToUpsertMap.values();
        return specVersionToUpsertMap;
    }

    private static void createRelatedRecords(ERPMessageParser.SpecMessageData data,  Map<String, SpecVersion__c> specVersionMap) {
        List<Specification_Version_to_Assembly__c> assembliesToInsert = new List<Specification_Version_to_Assembly__c>();
        List<Specification_Version_to_Certificate__c> certificatesToInsert = new List<Specification_Version_to_Certificate__c>();
        Map<String, Id> assemblyExistedMap = new Map<String, Id>();
        Map<String, Id> certificateExistedMap = new Map<String, Id>();

        List<Specification_Version_to_Assembly__c> assemblyList = [SELECT Id, Assembly__r.ID_ERP__c, Specification_Version__r.ID_ERP__c 
                                                                   FROM Specification_Version_to_Assembly__c 
                                                                   WHERE Specification_Version__r.ID_ERP__c IN :specificationIdSet AND Assembly__r.ID_ERP__c IN :assemblyIdSet];
        List<Specification_Version_to_Certificate__c> certificateList =  [SELECT Id, Certificate__r.ID_ERP__c, Specification_Version__r.ID_ERP__c 
                                                                          FROM Specification_Version_to_Certificate__c 
                                                                          WHERE Specification_Version__r.ID_ERP__c IN :specificationIdSet AND Certificate__r.ID_ERP__c IN :certificateIdSet];

        for(Specification_Version_to_Assembly__c assembly : assemblyList) {
            assemblyExistedMap.put(assembly.Specification_Version__r.ID_ERP__c + '' + assembly.Assembly__r.ID_ERP__c, assembly.Id);
        }

        for(Specification_Version_to_Certificate__c certificate : certificateList) {
            certificateExistedMap.put(certificate.Specification_Version__r.ID_ERP__c + '' + certificate.Certificate__r.ID_ERP__c, certificate.Id);
        }

        for(ERPMessageParser.ERPObject_SpecItem specItem : data.Items) {

            if(specItem.Assembly != null) {
                for(ERPMessageParser.ERPObject_BaseObject assembly : specItem.Assembly) {
                    if(assemblyExistedMap.get(String.valueOf(specItem.Id) + '' + assembly.Id) == null) {
                        Specification_Version_to_Assembly__c specVersionToAssembly = new Specification_Version_to_Assembly__c();
                        specVersionToAssembly.Assembly__c = assemblyMap.get(assembly.Id);
                        specVersionToAssembly.Specification_Version__c = specVersionMap.get(String.valueOf(specItem.Id)).Id;
                        assembliesToInsert.add(specVersionToAssembly);
                    }
                }
            }
            System.debug('certificateMap : ' + certificateMap);

            if(specItem.QualityCertificates != null) {
                for(ERPMessageParser.ERPObject_BaseObject certificate : specItem.QualityCertificates) {
                    if(certificateExistedMap.get(String.valueOf(specItem.Id) + '' + certificate.Id) == null) {
                        System.debug('certificate.Id : ' + certificate.Id);
                        Specification_Version_to_Certificate__c specVersionToCertificate = new Specification_Version_to_Certificate__c();
                        specVersionToCertificate.Certificate__c = certificateMap.get(certificate.Id);
                        specVersionToCertificate.Specification_Version__c = specVersionMap.get(String.valueOf(specItem.Id)).Id;
                        certificatesToInsert.add(specVersionToCertificate);
                    }
                }
            }                
        }

        insert assembliesToInsert;
        insert certificatesToInsert;
    }

    private static void createObjectsMaps() {
        prodKindMap = getObjectMap('ProdKind__c', null);
        prodTypeMap = getObjectMap('WheelProdType__c', null);
        plugTypeMap = getObjectMap('WheelPlugType__c', null);
        existedDrawingBaseMap = getObjectMap('DrawingBase__c', drawingBaseIdSet);
        wheelPurposeMap = getObjectMap('WheelPurpose__c', null);
        docStageMap = getStageMap();
        existedDrawingVersionMap = getObjectMap('DrawingVersion__c', drawingVersionIdSet);
        steelGradeMap = getObjectMap('WheelSteelGrade__c', steelGradeIdSet);
        axialLoadTypeMap = getObjectMap('WheelAxlialLoadType__c', null);
        diameterMap = getObjectMap('WheelDiameter__c', diameterIdSet);
        wheelHubMap = getObjectMap('WheelHub__c', null);
        hubBoreMap = getObjectMap('WheelHubBore__c', null);
        standardMap = getObjectMap('WheelProductStandard__c', null);
        imbalanceMap = getObjectMap('Wheel_Imbalance__c', null);
        existedSpecBaseMap = getObjectMap('SpecificationBase__c', specificationIdSet);
        accountMap = getObjectMap('Account', accountIdSet);
        countryMap = getObjectMap('Country__c', countryIdSet);
        existedSpecVersioneMap = getObjectMap('SpecVersion__c', specificationIdSet);
        shapeMap = getObjectMap('WheelShape__c', null);
        nameForDocMap = getObjectMap('ProdNameForDoc__c', nameForDocIdSet);
        markingMap = getObjectMap('WheelMarkType__c', null);
        coatingTypeMap = getObjectMap('WheelCoatingType__c', null);
        coatingMaterialMap = getObjectMap('WheelCover__c', null);
        packingMap = getObjectMap('WheelPackType__c', null);
        wheelComponentMap = getObjectMap('WheelsetComponent__c', null);
        producerMap = getObjectMap('WheelPartProducer__c', null);
        inspectionMap = getObjectMap('Wheel_Inspection__c', null);
        assemblyMap = getObjectMap('WheelAssembly__c', null);
        certificateMap = getObjectMap('QualityCertificates__c', null);
    }
    
    private static void getdSets(ERPMessageParser.SpecMessageData data) {
        for(ERPMessageParser.ERPObject_SpecItem specItem : data.Items) {
            specificationIdSet.add(String.valueOf(specItem.Id));
            if(specItem.SpecAxleId != null) {
                specificationIdSet.add(String.valueOf(specItem.SpecAxleId));
            }
            if(specItem.SpecWheelId != null) {
                specificationIdSet.add(String.valueOf(specItem.SpecWheelId));
            }
            drawingBaseIdSet.add(String.valueOf(specItem.DrawingVersion.DrawingId));
            drawingVersionIdSet.add(String.valueOf(specItem.DrawingVersion.Id));
            if(specItem.Client != null) {
                accountIdSet.add(specItem.Client.Id);
            }
            if(specItem.DrawingVersion.SteelGrade != null) {
                steelGradeIdSet.add(specItem.DrawingVersion.SteelGrade.Id);
            }
            if(specItem.SteelGrade != null) {
                steelGradeIdSet.add(specItem.SteelGrade.Id);
            }
            if(specItem.SteelGradeIPS != null) {
                steelGradeIdSet.add(specItem.SteelGradeIPS.Id);
            }
            if(specItem.DrawingVersion.Diameter != null) {
                diameterIdSet.add(specItem.DrawingVersion.Diameter.Id);
            }
            if(specItem.Client != null) {
                countryIdSet.add(String.valueOf(specItem.Client.CountryId));
            }
            if(specItem.NameForDoc != null) {
                nameForDocIdSet.add(specItem.NameForDoc.Id);
            }            

            if(specItem.Assembly != null) {
                for(ERPMessageParser.ERPObject_BaseObject assembly : specItem.Assembly) {
                    assemblyIdSet.add(assembly.Id);
                }
            }

            if(specItem.QualityCertificates != null) {
                for(ERPMessageParser.ERPObject_BaseObject certificate : specItem.QualityCertificates) {
                    certificateIdSet.add(certificate.Id);
                }
            }
        }
    }
    
    private static Map<String, Id> getObjectMap(String objectName, Set<String> idERPSet) {
        Map<String, Id> objectMap = new Map<String, Id>();

        String query = 'SELECT Id, ID_ERP__c FROM ' + objectName;
        if(idERPSet != null) {
            query += + ' WHERE ID_ERP__c IN :idERPSet';
        }	
		List<SObject> objList =  Database.query(query);

        for(SObject obj : objList) {
            objectMap.put((String) obj.get('ID_ERP__c'), obj.Id);
        }

        return objectMap;
    }

    private static Map<String, Id> getStageMap() {
        Map<String, Id> stageMap = new Map<String, Id>();

        List<KLWDocStage__c> stageList = [SELECT Id, ID_ERP__c, DocType__c FROM KLWDocStage__c];

        for(KLWDocStage__c stage : stageList) {
            stageMap.put(stage.ID_ERP__c + '' + stage.DocType__c, stage.Id);
        }

        return stageMap;
    }

    public static Blob generateResponseBody(Map<Integer, String> statusCodesMap, Integer statusCode, String error, MessageProcessingResult mpRes) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('Status Code', statusCode);
        gen.writeStringField('Status', statusCodesMap.get(statusCode));
        gen.writeStringField('Processed message type', mpRes.MessageType);
        if (error != NULL) {
            gen.writeStringField('Error Message', error);
        }
        gen.writeEndObject();
        
        String res = gen.getAsString();
        System.debug('Response body text generated: ' + res);
        return Blob.valueOf(res);
    }

    public class MessageProcessingResult {
        public String MessageType;		
        public String error;
    } 

    public class ExecutionException extends Exception {
    }
}