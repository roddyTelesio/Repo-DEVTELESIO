public with sharing class QuoteTableSvcHelper implements Callable {



    /***
    * @description  Generating output records for Quote Requests by re-insurerr
    * @param		QuoteTable_SVC.DataWrapper data : Wrapper containing all data
    * @param		ConfigQuoteTable__mdt config: List of current configuration for which the records must be generated
    * @param        String ongletId : Id of the excel sheet record
    * @param        Integer orderOnglet : Order of the excel sheet
    * @exception	None special (all catched and logged).
    ***/
    public static List<ClasseurOutput__c> fixedRequest(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('running QuoteTableSvcHelper : fixedRequest Start');

        List<ClasseurOutput__c> outputList = new List<ClasseurOutput__c>(); 

        System.debug('sectionOrderMap Size: ' + data.sectionOrderMap.size());
        System.debug('data.quoteDetails KeySet ==' + data.quoteDetails.KeySet() + '  ' +'data.quoteDetails values ==' + data.quoteDetails.values());
        for(String sectionOnglet : data.sectionOrderMap.keySet()){
            //get section Id
            String section = getSectionId(sectionOnglet);
            System.debug('fixedRequest : sectionOnglet ' + sectionOnglet);
            System.debug('fixedRequest : ongletId :  ' + ongletId);
            if(sectionOnglet.contains(ongletId)){
                Integer orderReinsurer = 1; 

                for(String idReinsurer: data.quoteDetails.keySet()){

                    System.debug('## ID Reinsurer fixedRequest : ' + idReinsurer);
                    System.debug('## ID Reinsurer + Id section fixedRequest: ' + idReinsurer + '_'+ section + '_' + config.ConfigIdentifier__c);
                    Request__c currentRequest = data.quoteDetails.get(idReinsurer).get(section);
                    if(currentRequest != null){
                        ClasseurOutput__c currentOutput = new ClasseurOutput__c();
                        currentOutput.SectionOrder__c = data.sectionOrderMap.get(sectionOnglet); 
                        currentOutput.ReinsurerOrder__c = orderReinsurer; 
                        currentOutput.SectionOptionId__c = section; 
                        currentOutput.ClasseurId__c = data.classeurId; 
                        currentOutput.ConfigId__c = config.ConfigIdentifier__c; 
                        currentOutput.ReinsurerAccount__c = currentRequest.Reinsurer__c; 
                        currentOutput.onglet__c = ongletId;
                        System.debug('orderOnglet : ' + orderOnglet);
                        currentOutput.OrderOnglet__c =  orderOnglet;
                        
                        // retrieve ex-1 request if any
                        Request__c oldRequest; 

                        String exSection = data.newToOldSection.get(currentRequest.Section__c);

                        if(data.exQuoteDetails.containsKey(idReinsurer)){
                            if(data.exQuoteDetails.get(idReinsurer).containsKey(exSection)){
                                oldRequest = data.exQuoteDetails.get(idReinsurer).get(exSection);
                            }else{
                                System.debug('fixedRequest : no old request found for re-insurer' + idReinsurer + ' and section ' + exSection);
                                oldRequest = new request__c(); 
                            }
                        }else{
                            System.debug('fixedRequest : no old request found for re-insurer' + idReinsurer);
                            oldRequest = new request__c(); 
                        }
                        
                        mapFields2d(currentOutput, config.DataSourceFieldMapping__c, currentRequest,oldRequest, data.fieldMetadataDetails);
                        outputList.add(currentOutput);
                    }else{
                        //idReinsurer
                        ClasseurOutput__c currentOutputNoReq = new ClasseurOutput__c();
                        currentOutputNoReq.SectionOrder__c = data.sectionOrderMap.get(sectionOnglet); 
                        currentOutputNoReq.ReinsurerOrder__c = orderReinsurer; 
                        currentOutputNoReq.SectionOptionId__c = section; 
                        currentOutputNoReq.ClasseurId__c = data.classeurId; 
                        currentOutputNoReq.ConfigId__c = config.ConfigIdentifier__c; 
                        currentOutputNoReq.ReinsurerAccount__c = idReinsurer.contains('_') ? idReinsurer.split('_')[0] : idReinsurer; 
                        currentOutputNoReq.onglet__c = ongletId;
                        currentOutputNoReq.OrderOnglet__c =  orderOnglet;

                        outputList.add(currentOutputNoReq);
                    }
                    orderReinsurer++;
                     
                }
            }else{
                System.debug('fixedRequest : sectionOnglet not found for: ' + ongletId);
            }
        }
        System.debug('fixedRequest : outputList: ' + outputList);
        System.debug('fixedRequest : outputList.size: ' + outputList.size());
        return outputList;
    }

    /***
    * @description  Generated output record for all the reinsurers present in the quotations
    * @param		QuoteTable_SVC.DataWrapper data : Wrapper containing all data
    * @param		ConfigQuoteTable__mdt config: List of current configuration for which the records must be generated
    * @param        String ongletId : Id of the excel sheet record
    * @param        Integer orderOnglet : Order of the excel sheet
    * @exception	None special (all catched and logged).
    ***/
    public static List<ClasseurOutput__c> populateReinsurerNames(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('running populateReinsurerNames : fixedRequest Start');

        List<ClasseurOutput__c> outputList = new List<ClasseurOutput__c>(); 
        Set<String> setExistedQuoteId = new Set<String>();//RRA - ticket 1727 -07112023
        
        System.debug('populateReinsurerNames : sectionOrderMap Size: ' + data.sectionOrderMap.size());
        System.debug('populateReinsurerNames : sectionOrderMap : ' + data.sectionOrderMap);
        System.debug('populateReinsurerNames data.quoteDetails : ' + data.quoteDetails);
        System.debug('populateReinsurerNames data.quoteDetails.size() : ' + data.quoteDetails.size());
        System.debug('populateReinsurerNames data.quoteDetails.keySet() :' + data.quoteDetails.keySet()  +' '+ 'data.quoteDetails values ' + data.quoteDetails.values());
        for(String sectionOnglet : data.sectionOrderMap.keySet()){

            //get section Id
            String section = getSectionId(sectionOnglet);
            System.debug('populateReinsurerNames : sectionOnglet ' + sectionOnglet);
            System.debug('populateReinsurerNames : section ' + section);
            System.debug('populateReinsurerNames : ongletId :  ' + ongletId);
            if(sectionOnglet.contains(ongletId)){
                Integer orderReinsurer = 1; 

                for(String idReinsurer: data.quoteDetails.keySet()){
                    

                    System.debug('## ID Reinsurer populateReinsurerNames : ' + idReinsurer);
                    System.debug('## ID Reinsurer + Id section populateReinsurerNames : ' + idReinsurer + '_'+ section + '_' + config.ConfigIdentifier__c);
                    Request__c currentRequest = data.quoteDetails.get(idReinsurer).get(section);
                    System.debug('## currentRequest populateReinsurerNames : ' + currentRequest);
                    if(currentRequest != null){
                        ClasseurOutput__c currentOutput = new ClasseurOutput__c();
                        System.debug('populateReinsurerNames : data.sectionOrderMap.get(sectionOnglet) ' + data.sectionOrderMap.get(sectionOnglet));
                        currentOutput.SectionOrder__c = data.sectionOrderMap.get(sectionOnglet); 
                        currentOutput.ReinsurerOrder__c = orderReinsurer; 
                        currentOutput.SectionOptionId__c = section; 
                        currentOutput.ClasseurId__c = data.classeurId; 
                        currentOutput.ConfigId__c = config.ConfigIdentifier__c; 
                        currentOutput.ReinsurerAccount__c = currentRequest.Reinsurer__c; 
                        currentOutput.broker__c = currentRequest.broker__c;
                        currentOutput.onglet__c = ongletId;
                        System.debug('orderOnglet : ' + orderOnglet);
                        System.debug('currentOutput.broker__c : ' + currentRequest.broker__c);
                        System.debug('currentOutput.Reinsurer__c : ' + currentRequest.Reinsurer__c);
                        currentOutput.OrderOnglet__c =  orderOnglet;
                        System.debug('currentOutput.SectionOrder__c : ' + currentOutput.SectionOrder__c);
                       // if(currentOutput.SectionOrder__c == 1){ //currentOutput.SectionOrder__c == 5 || 
                                                                 
                        //RRA - ticket 1727 -07112023
                        if(!setExistedQuoteId.contains(currentRequest.Broker__c + '-' + currentRequest.Reinsurer__c)){
                            setExistedQuoteId.add(currentRequest.Broker__c + '-' + currentRequest.Reinsurer__c);
                            outputList.add(currentOutput); 
                            orderReinsurer++; 
                        }
                    }
                }
            }else{
                System.debug('populateReinsurerNames : sectionOnglet not found for: ' + ongletId);
            }
            
        }
        System.debug('populateReinsurerNames : outputList: ' + outputList);
        System.debug('populateReinsurerNames : outputList.size: ' + outputList.size());
        return outputList;
    }

    /***
    * @description  Generating output records for sections. 
    * @param		QuoteTable_SVC.DataWrapper data : Wrapper containing all data
    * @param		ConfigQuoteTable__mdt config: List of current configuration for which the records must be generated
    * @param        String ongletId : Id of the excel sheet record
    * @param        Integer orderOnglet : Order of the excel sheet
    * @exception	None special (all catched and logged).
    ***/
    public static List<ClasseurOutput__c>  fixedSection(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('fixedSection : START ');

        System.debug('fixedSection : fixed section ');

        List<ClasseurOutput__c> outputList = new List<ClasseurOutput__c>(); 

        for(String sectionOnglet : data.sectionOrderMap.keySet()){

            System.debug('fixedSection: ' + data.mapSections);
            section__c currentSection = data.mapSections.get(getSectionId(sectionOnglet));
            if(getOngletId(sectionOnglet) == ongletId){
                ClasseurOutput__c currentOutput = new ClasseurOutput__c();
                currentOutput.SectionOrder__c = data.sectionOrderMap.get(sectionOnglet); 
                currentOutput.SectionOptionId__c = currentSection.Id; 
                currentOutput.ClasseurId__c = data.classeurId; 
                currentOutput.ConfigId__c = config.ConfigIdentifier__c; 
                currentOutput.onglet__c = ongletId;  
                currentOutput.OrderOnglet__c =  orderOnglet; 
                // currentOutput.LeaderColeaders__c = getLeaderColeader(data.mapLeaders, currentSection.TECH_RenewedSection_ID__r.Treaty__c);
                mapFields1d(currentOutput, config.DataSourceFieldMapping__c, currentSection, data.fieldMetadataDetails);
                outputList.add(currentOutput);
            }
        }

        System.debug('fixedSection : outputlist => ' + outputList);
        System.debug('fixedSection : END ');
        return outputList;
    }



    /***
    * @description  Generating output records for sections. 
    * @param		QuoteTable_SVC.DataWrapper data : Wrapper containing all data
    * @param		ConfigQuoteTable__mdt config: List of current configuration for which the records must be generated
    * @param        String ongletId : Id of the excel sheet record
    * @param        Integer orderOnglet : Order of the excel sheet
    * @exception	None special (all catched and logged).
    ***/
    public static List<ClasseurOutput__c>  fixedLead(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('fixedLead : START ');

        System.debug('fixedLead : fixed section ');

        List<ClasseurOutput__c> outputList = new List<ClasseurOutput__c>(); 

        for(String sectionOnglet : data.sectionOrderMap.keySet()){

            System.debug('fixedLead: ' + data.mapSections);
            section__c currentSection = data.mapSections.get(getSectionId(sectionOnglet));
            
            System.debug('currentSection: ' + currentSection);
            
            String treatySectionKey = currentSection.Treaty__r.TECH_ActorReferenceNumber__c + '_' + currentSection.sectionNumber__c; 
            
            System.debug('treatySectionKey: ' + treatySectionKey);
            
            System.debug('sectionOnglet: ' + sectionOnglet);

            // get lead info of previous year
            // String oldSectionId = data.newToOldSection.get(currentSection.Id); 
            // System.debug('fixedLead : oldSectionId ' + oldSectionId);
            
            if(getOngletId(sectionOnglet) == ongletId){
                System.debug('ongletId: ' + ongletId);
                System.debug('data.leadDetails : ' + data.leadDetails );
                if(data.leadDetails != null  && data.leadDetails.containsKey(treatySectionKey)){
                    System.debug('leadDetails : Contains');
                    Request__c leadRequest = data.leadDetails.get(treatySectionKey);
                    ClasseurOutput__c currentOutput = new ClasseurOutput__c();
                    currentOutput.SectionOrder__c = data.sectionOrderMap.get(sectionOnglet); 
                    currentOutput.SectionOptionId__c = currentSection.Id; 
                    currentOutput.ClasseurId__c = data.classeurId; 
                    currentOutput.ConfigId__c = config.ConfigIdentifier__c; 
                    currentOutput.onglet__c = ongletId;  
                    currentOutput.OrderOnglet__c =  orderOnglet; 
                    currentOutput.LeaderColeaders__c = getLeaderColeader(data.mapLeaders, currentSection.treaty__r.TECH_ActorReferenceNumber__c);
                    mapFields1dRequest(currentOutput, config.DataSourceFieldMapping__c, leadRequest, data.fieldMetadataDetails);
                    outputList.add(currentOutput);
                }else{
                    // Request__c leadRequest = data.leadDetails.get(treatySectionKey);
                    ClasseurOutput__c currentOutput = new ClasseurOutput__c();
                    currentOutput.SectionOrder__c = data.sectionOrderMap.get(sectionOnglet); 
                    currentOutput.SectionOptionId__c = currentSection.Id; 
                    currentOutput.ClasseurId__c = data.classeurId; 
                    currentOutput.ConfigId__c = config.ConfigIdentifier__c; 
                    currentOutput.onglet__c = ongletId;  
                    currentOutput.OrderOnglet__c =  orderOnglet; 
                    outputList.add(currentOutput);  
                }
            }
        }

        System.debug('fixedLead : outputlist => ' + outputList);
        System.debug('fixedLead : END ');
        return outputList;
    }


    public static List<ClasseurOutput__c> fixedHeaderInfo(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('fixedHeaderInfo : START ');
        Classeur__c classeur = data.classeur; 
        List<ClasseurOutput__c> listClasseurOutputs =  new List<ClasseurOutput__c>{
            new ClasseurOutput__c(
                SectionOrder__c = 1
                ,ClasseurId__c = data.classeurId 
                ,ConfigId__c = config.ConfigIdentifier__c 
                ,onglet__c = ongletId  
                ,OrderOnglet__c =  orderOnglet 
                ,HeaderInfo__c = classeur.cedente__r.Name
            )
            ,new ClasseurOutput__c(
                SectionOrder__c = 2
                ,ClasseurId__c = data.classeurId 
                ,ConfigId__c = config.ConfigIdentifier__c 
                ,onglet__c = ongletId  
                ,OrderOnglet__c =  orderOnglet 
                ,HeaderInfo__c = classeur.Program__r.Name
            )
        };

        System.debug('fixedHeaderInfo : ClasseurOutput generated:  ' + listClasseurOutputs);
        System.debug('fixedHeaderInfo : End ');
        return listClasseurOutputs; 
    }

    public static List<ClasseurOutput__c> createDateInfo(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('fixedHeaderInfo : START ');
        Classeur__c classeur = data.classeur; 
        List<ClasseurOutput__c> listClasseurOutputs =  new List<ClasseurOutput__c>{
            new ClasseurOutput__c(
                SectionOrder__c = 1
                ,ClasseurId__c = data.classeurId 
                ,ConfigId__c = config.ConfigIdentifier__c 
                ,onglet__c = ongletId  
                ,OrderOnglet__c =  orderOnglet 
                ,HeaderInfo__c = data.classeur.LastModifiedDate.format()
            )
        };

        System.debug('fixedHeaderInfo : ClasseurOutput generated:  ' + listClasseurOutputs);
        System.debug('fixedHeaderInfo : End ');
        return listClasseurOutputs; 
    }

    public static List<ClasseurOutput__c> createYearInfo(QuoteTable_SVC.DataWrapper data, ConfigQuoteTable__mdt config, String ongletId, Integer orderOnglet){
        System.debug('fixedHeaderInfo : START ');
        Classeur__c classeur = data.classeur; 
        List<ClasseurOutput__c> listClasseurOutputs =  new List<ClasseurOutput__c>{
            new ClasseurOutput__c(
                SectionOrder__c = 1
                ,ClasseurId__c = data.classeurId 
                ,ConfigId__c = config.ConfigIdentifier__c 
                ,onglet__c = ongletId  
                ,OrderOnglet__c =  orderOnglet 
                ,HeaderInfo__c = data.classeur.Exercise__c
            )
        };

        System.debug('fixedHeaderInfo : ClasseurOutput generated:  ' + listClasseurOutputs);
        System.debug('fixedHeaderInfo : End ');
        return listClasseurOutputs; 
    }

    /***
    * @description  Retrieves the Leader/Coleader of the previous UW 
    * @param		mapLeaders : map containing list of leaders per treaty
    * @param		treaty : Treaty for which the leader has to be fetched
    * @exception	None special (all catched and logged).
    ***/
    public static String getLeaderColeader(Map<String,Set<String>> mapLeaders, String treaty){
        System.debug('getLeaderColeader: Start');
        String leaderColeader = '';
        if(String.isNotBlank(treaty)){
            System.debug('getLeaderColeader : treaty is not null'); 
            if(mapLeaders.containsKey(treaty)){
                System.debug('getLeaderColeader : List of leaders found for the treaty'); 
                for(String leaderName: mapLeaders.get(treaty)){
                    leaderColeader += leaderName + '\r\n'; 
                }
            }
        }
        System.debug('getLeaderColeader: End Returning: ' + leaderColeader);
        return leaderColeader; 
    }

    /***
    * @description  Uses the field DataSourceFieldMapping from Configurations Quote Table metadata 
    *               to fill ClasseurOutput__c corresponding field. 

                    Mapping guideline: 
                        1. Normal mapping (current year) 
                        [
                            {
                                "<classeurOutput__c field>" : "<Request__c field>"
                            }
                        ]
                        2. Mapping with previous year
                        [
                            {
                                "<classeurOutput__c field>" : "[old]<Request__c field>"
                            }
                        ]
                    Example 
                        mapping input: [
                                {
                                "TreatyRef__c" : "Treaty__r.TreatyReference__c"
                                }
                            ]
                        Expected outcome: 
                                TreatyRef__c field of object classeurOutput__c 
                                is filled with Treaty__r.TreatyReference__c 
                                value from the object Request__c
                        Particular case: 
                                When [old] is included in the value, retrieve the field indicated from previous year's request
    * @param		currentOutput : map containing list of leaders per treaty
    * @param		mappingList : map containing list of leaders per treaty
    * @param		currentRequest : map containing list of leaders per treaty
    * @param		oldRequest : Treaty for which the leader has to be fetched
    * @exception	None special (all catched and logged).
    ***/
    public static void mapFields2d(ClasseurOutput__c currentOutput, String mappingList,  Request__c currentRequest, Request__c oldRequest, Map<String, Map<String, Object>> fieldMetadataDetails){
        System.debug('mapFields: start');
        List<Object> mapDes = (List<Object>) JSON.deserializeUntyped(mappingList);
        for(Object currentField : mapDes){
            System.debug(currentField);
            Map<String, Object> currentFields = (Map<String, Object>) currentField;

            for( String key : currentFields.keySet()){

                String currentValue = (String)currentFields.get(key); 
                Object targetValue; 

                if(currentValue.contains('[old]')){
                    targetValue = ExtractFieldValues(oldRequest,currentValue.split(']')[1] );
                    currentOutput.put(key, ExtractFieldValues(oldRequest,currentValue.split(']')[1] )); 
                }else{
                    targetValue = ExtractFieldValues(currentRequest,currentValue); 
                    currentOutput.put(key, ExtractFieldValues(currentRequest,currentValue)); 
                }  
                
                
                if(getFieldType(key, 'ClasseurOutput__c', fieldMetadataDetails) == Schema.DisplayType.Percent & targetValue != null){

                    try{
                        targetValue = (Decimal)targetValue/100; 
                        currentOutput.put(key, targetValue); 
                    }catch(Exception e){
                        System.debug('Cannot convert percentage due to blank value');
                    }
                    
                }
                
            }

            system.debug('currentOutput: ' + currentOutput);
        }
        System.debug('mapDes: ' + mapDes);
        System.debug('mapFields: end');
    }


    /***
    * @description  Uses the field DataSourceFieldMapping__c from Configurations Quote Table metadata 
    *               to fill ClasseurOutput__c corresponding field. 

                    Mapping guideline: 
                        [
                            {
                                "<classeurOutput__c field>" : "<Section__c field>"
                            }
                        ]
                    Example: 
                        mapping input: [
                                {
                                "TreatyRef__c" : "Treaty__r.TreatyReference__c"
                                }
                            ]
                        Expected outcome: 
                                TreatyRef__c field of object classeurOutput__c 
                                is filled with Treaty__r.TreatyReference__c 
                                value from the object Section__c
    * @param		currentOutput : map containing list of leaders per treaty
    * @param		mappingList : map containing list of leaders per treaty
    * @param		currentSection : Section record
    * @exception	None special (all catched and logged).
    ***/
    public static void mapFields1d(ClasseurOutput__c currentOutput, String mappingList,  Section__c currentSection, Map<String, Map<String, Object>> fieldMetadataDetails){
        System.debug('mapFields1d: start');
        List<Object> mapDes = (List<Object>) JSON.deserializeUntyped(mappingList);
        for(Object currentField : mapDes){
            System.debug(currentField);
            Map<String, Object> currentFields = (Map<String, Object>) currentField;

            for( String key : currentFields.keySet()){

                String currentValue = (String)currentFields.get(key);
                Object targetValue =  ExtractFieldValues(currentSection,currentValue); 
                currentOutput.put(key, targetValue); 

                if(getFieldType(key, 'ClasseurOutput__c', fieldMetadataDetails) == Schema.DisplayType.BOOLEAN & targetValue == null){
                    currentOutput.put(key, false); 
                }

                if(getFieldType(key, 'ClasseurOutput__c', fieldMetadataDetails) == Schema.DisplayType.Percent & targetValue != null){

                    targetValue = (Decimal)targetValue/100; 
                    currentOutput.put(key, targetValue); 
                }
                
            }

            system.debug('mapFields1d : currentOutput generated ' + currentOutput);
        }
        System.debug('mapFields1d mapDes: ' + mapDes);
        System.debug('mapFields1d: end');
    }


    /***
    * @description  Uses the field DataSourceFieldMapping__c from Configurations Quote Table metadata 
    *               to fill ClasseurOutput__c corresponding field. 

                    Mapping guideline: 
                        [
                            {
                                "<classeurOutput__c field>" : "<Section__c field>"
                            }
                        ]
                    Example: 
                        mapping input: [
                                {
                                "TreatyRef__c" : "Treaty__r.TreatyReference__c"
                                }
                            ]
                        Expected outcome: 
                                TreatyRef__c field of object classeurOutput__c 
                                is filled with Treaty__r.TreatyReference__c 
                                value from the object Section__c
    * @param		currentOutput : map containing list of leaders per treaty
    * @param		mappingList : map containing list of leaders per treaty
    * @param		currentSection : Section record
    * @exception	None special (all catched and logged).
    ***/
    public static void mapFields1dRequest(ClasseurOutput__c currentOutput, String mappingList,  Request__c currentRequest, Map<String, Map<String, Object>> fieldMetadataDetails){
        System.debug('mapFields1d: start');
        List<Object> mapDes = (List<Object>) JSON.deserializeUntyped(mappingList);
        for(Object currentField : mapDes){
            System.debug(currentField);
            Map<String, Object> currentFields = (Map<String, Object>) currentField;

            for( String key : currentFields.keySet()){

                String currentValue = (String)currentFields.get(key);
                Object targetValue =  ExtractFieldValues(currentRequest,currentValue); 
                currentOutput.put(key, targetValue); 

                if(getFieldType(key, 'ClasseurOutput__c', fieldMetadataDetails) == Schema.DisplayType.BOOLEAN & targetValue == null){
                    currentOutput.put(key, false); 
                }

                if(getFieldType(key, 'ClasseurOutput__c', fieldMetadataDetails) == Schema.DisplayType.Percent & targetValue != null){

                    targetValue = (Decimal)targetValue/100; 
                    currentOutput.put(key, targetValue); 
                }
                
            }

            system.debug('mapFields1d : currentOutput generated ' + currentOutput);
        }
        System.debug('mapFields1d mapDes: ' + mapDes);
        System.debug('mapFields1d: end');
    }


    /***
    * @description  splits strings and returns the section Id
    * @param		concatStringSection : String with the format sectionId_ClasseurOngletId
    * @exception	None special (all catched and logged).
    ***/
    public static string getSectionId(String concatStringSection){
        return concatStringSection.split('_')[0];
    }

    /***
    * @description  splits strings and returns the section Id
    * @param		concatStringSection : String with the format sectionId_ClasseurOngletId
    * @exception	None special (all catched and logged).
    ***/
    public static string getOngletId(String concatStringSection){
        return concatStringSection.split('_')[1];
    }

    /***
    * @description  Interface method that retrieves the config method name and calls the appropriate method
    * @param		String action : action name of the method to be called 
    * @param        Map<String, Object> args : args containing all data that may be used in the method.
    * @exception	None special (all catched and logged).
    ***/
    public Object call(String action, Map<String, Object> args) {

        switch on action {

            when 'fixedRequest' {
                // It is best to keep the naming consistent with the original method signature, no error checking is
                // made for simplicity:
                return fixedRequest(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
                // call() expects an object to be returned, null is returned for void function, other types can be used as needed:
            }

            when 'fixedSection'{

                return fixedSection(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
            }

            when 'fixedHeaderInfo'{

                return fixedHeaderInfo(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
            }

            when 'createDateInfo'{

                return createDateInfo(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
            }

            when 'createYearInfo'{

                return createYearInfo(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
            }

            when 'populateReinsurerNames'{

                return populateReinsurerNames(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
            }

            when 'fixedLead'{
                return fixedLead(
                    (QuoteTable_SVC.DataWrapper)args.get('data'), 
                    (ConfigQuoteTable__mdt)args.get('config'),
                    (String)args.get('ongletId'), 
                    (Integer)args.get('orderOnglet')
                );
            }

            when else {
                // A standard Salesforce exception is used for simplicity:
                throw new CalloutException('Method not implemented');
            }
        }
    }


    /***
    * @description  static method which can be used to fetch field values.
                    You need to pass sObject and fieldAPIName to get field value
    * @param		sObject sb : sObject name
    * @param        String fieldAPIName: API name of the field
    * @exception	None special (all catched and logged).
    ***/
    public static Object ExtractFieldValues(sObject sb, string fieldAPIName){
        Object fvalue;

        System.debug('ExtractFieldValues: Start ');
        System.debug('ExtractFieldValues: Debug input: ' + fieldAPIName);
        if(fieldAPIName.contains('.')){
            List<string> splitedFields = fieldAPIName.split('\\.');
            try{
                for(integer i=0;i<splitedFields.size()-1;i++){
                    sb=sb.getSobject(splitedFields[i]);   
                }
                fvalue = sb.get(splitedFields[splitedFields.size()-1]);
            }catch(exception ex){
            system.debug('ExtractFieldValues:  exception '+fieldAPIName+'  value is blank.'+ex.getmessage()); 
            fvalue=null;
            }
            
        }else if(sb.get(fieldAPIName)!=null){
            fvalue = sb.get(fieldAPIName);
        }
        return fvalue;
    }

    /***
    * @description  Returns the type of the field by passing the objectname and fieldname
    * @param		String fieldName : field api name
    * @param        String sObjectName : sObject api name
    * @exception	None special (all catched and logged).
    ***/
    public static Schema.DisplayType getFieldType(String fieldName, String sObjectName, Map<String, Map<String, Object>> fieldMetadataDetails){
        System.debug('getFieldType  Start ' + fieldName + ' and  ' + sObjectName);

        Map<String, Object> fieldDetail = (Map<string, Object>)fieldMetadataDetails.get(sObjectName).get(fieldName); 
        System.debug('getFieldType returning ' + fieldDetail.get('type'));
        return (Schema.DisplayType)fieldDetail.get('type');
    }

}