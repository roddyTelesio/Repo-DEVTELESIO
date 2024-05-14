/**
* Service class for Quote table outputs generation. 
* @author  Satveer (Telesio)
* @version 1.0
* @since   18/04/2022
*/
public with sharing class QuoteTable_SVC {

    /***
    * @description	Id of classeur record
    ***/
    public Id classeurId;
    /***
    * @description  Initial record of classeur. Used to version the records of classeur when user refreshes
    ***/
    public Id initialClasseurRecord;
    /***
    * @description	Underwriting year selected by the user on screen.
    ***/
    public String uwYear; 
    /***
    * @description	Data wrapper. The wrapper contains all the data that has to be passed from the Service layer to the helper Layer
    ***/
    public DataWrapper wrapper;
    /***
    * @description	Program selected by the user
    ***/
    public Id program; 
    /***
    * @description	Principle ceding company selected by the user in filters
    ***/
    public Id pcc; 
    /***
    * @description	Indicates whether the class has been initialised in the refresh mode
    ***/
    public boolean refreshMode;
    /***
    * @description	FileId provided by the User when refresh is requested
    ***/ 
    public String fileId; 

    /***
    * @description	Default constructor
    * @exception	None special (all catched and logged).
    ***/
    public QuoteTable_SVC() {
        System.debug('QuoteTable_SVC constructor: start');  
        // Default constructor
        System.debug('QuoteTable_SVC: End');
    }

    /***
    * @description	Constructor
    * @param		classeurId Id of classeur Record
    * @exception	None special (all catched and logged).
    ***/
    public QuoteTable_SVC(Id classeurId) {
        System.debug('QuoteTable_SVC constructor: start');
        this.classeurId = classeurId; 
        System.debug('QuoteTable_SVC: End');
    }


    /***
    * @description	Constructor
    * @param		Id Classeur : Id of the excel file
    * @param		refresh : param to indicate that it is the refresh context
    * @param        fileId : Id of ContentDocument
    * @param        classeurInitId :  ClasseurId Record of parent record
    * @exception	None special (all catched and logged).
    ***/
    public QuoteTable_SVC(Id classeurId, Boolean refresh, String fileId, Id classeurInitId) {
        System.debug('QuoteTable_SVC constructor: start');
        this.classeurId = classeurId; 
        this.initialClasseurRecord = classeurInitId; 
        this.refreshMode = refresh; 
        this.fileId = fileId; 
        System.debug('QuoteTable_SVC: End');
    }


    /***
    * @description	Method used to prepare all the data that will be used to generate the output records
                    Prepared Data include: 
                    1. Classeur Record (Classeur__c)
                    2. Classeur Onglet (Tabs per classeur)
                    3. Classeur Onglet Section (Sections selected by user per tab)
                    4. Section Records (Section__c)
                    5. Section Records of previous year (Section__c ex-1)
                    6. Quote request Records (Request__c of record type Request)
                    7. Leader / Coleader names
                    8. Quote Table Config
                    All prepared data are passed into the Wrapper variable and passed into the Helper layer. 


    * @param        None, however classeurId variable must be filled
    * @exception	None special (all catched and logged).
    ***/
    public void generateOutput(){
        System.debug('generateOutput: start');

        // #############################################
        //         VARIABLE INITIALISATION START       #
        // #############################################
        this.wrapper = new DataWrapper(); 
        wrapper.classeurId = this.classeurId; 
        // order of sections
        Map<String, Decimal> sectionOrderMap = new Map<String, Decimal>(); 
        // all sections per excel tab
        Map<String, Set<String>> sectionsPerOnglet = new Map<String, Set<String>>(); 
        // all sections
        Set<Id> setSections = new Set<Id>(); 
        Map<String, String> newToOldSection = new Map<String, String>();
        Map<String, String> oldToNewSection = new Map<String, String>();
        // key 1: Id of the reinsurer
        // Key 2: Id of the Section 
        // Quote Request details
        Map<String, Map<String, Request__c>> quoteDetails = new Map<String, Map<String, Request__c>>(); 
        // Quote request details of previous year
        Map<String, Map<String, Request__c>> exQuoteDetails = new Map<String, Map<String, Request__c>>();

        // Quote request details of previous year
        Map<String, Request__c> leadDetails = new Map<String, Request__c>();

        // List of previous year's treaties
        Set<String> oldTreaties = new Set<String>();

        Set<String> oldPrograms = new Set<String>(); 
        // Map containing leaders/coleaders names
        Map<String, Set<String>> mapLeaders = new Map<String, Set<String>>();
        // #############################################
        // #         VARIABLE INITIALISATION END       #
        // #############################################



        // #############################################
        // #          Data preparation start           #
        // #############################################
        // 1. Retrieve classeurs outputs: 
        List<Classeur__c> classeursRetrieved = [
            SELECT Id
                , Exercise__c
                , Program__c
                , Program__r.Name
                , Cedente__r.Name
                , CreatedDate
                , Cedente__c
                , LastModifiedDate
                , (SELECT Id,Order__c, Name FROM Classeur_Onglets__r) 
            FROM Classeur__c 
            WHERE Id = :this.classeurId
        ];
        System.debug('generateOutput: classeur retrieved => ' + classeursRetrieved);


        // 2. Retrieve sheets and sections
        if(!classeursRetrieved.isEmpty()){

            // adding classeur to data wrapper
            this.wrapper.classeur = classeursRetrieved[0]; 

            this.uwYear = classeursRetrieved[0].Exercise__c; 
            this.program = classeursRetrieved[0].Program__c; 
            this.pcc = classeursRetrieved[0].Cedente__c; 


            for(ClasseurOngletSections__c cs: [SELECT Id, ClassseurOnglet__c, Order__c, Section__c 
                                                FROM ClasseurOngletSections__c 
                                                WHERE ClassseurOnglet__r.Classeur__c = :classeursRetrieved[0].Id
                                                ORDER BY Order__c ASC
                                                ])
            {
                // iterate through each classeur section onglet
                sectionOrderMap.put(cs.section__c + '_' + cs.ClassseurOnglet__c, cs.Order__c);
                // populating set containing all the section
                setSections.add(cs.Section__c);
                // populating map containing all the sections contained in each Tab (onglet)
                /**
                 *  Tab (onglet)
                 *    |_Section
                 *    |_Section
                */
                if(sectionsPerOnglet.containsKey(cs.ClassseurOnglet__c)){
                    sectionsPerOnglet.get(cs.ClassseurOnglet__c).add(cs.Section__c);
                }else{
                    sectionsPerOnglet.put(cs.ClassseurOnglet__c, new Set<String>{cs.Section__c});
                }

            }

            // Retrieve all sections for current year and previous year
            // /!\ IMPORTANT ensure all fields that are present in the corresponding config is present is this query
            String uwYearQuery = this.uwYear; 
            String programQuery = this.program; 
            String pccQuery = this.pcc;
            Map<Id, Section__c> mapSections = new Map<Id, Section__c>();

            for(Section__c s : Database.query(
                'SELECT '
                    + QuoteTable_CST.allFields('Section__c')
                    + ',' + QuoteTable_CST.allParentFields('Section__c', 'TECH_RenewedSection_ID__r')
                    + ',' + QuoteTable_CST.allParentFields('Treaty__c', 'treaty__r')
                    + ' FROM Section__c'
                    + ' WHERE Id in :setSections'
                    + ' AND Treaty__r.Program__r.UwYear__c = :uwYearQuery'
                    + ' AND Treaty__r.Program__c = :programQuery'
                    + ' AND treaty__r.Program__r.PrincipalCedingCompany__c = :pccQuery'
                )
            ){
                // retrieve all sections of current year and previous year via the field TECH_RenewdSection_Id__r
                mapSections.put(s.Id, s);
            }

            // retrieving all onglets with Id as the key
            Map<ID, ClassseurOnglets__c> ongletsMap = new Map<ID, ClassseurOnglets__c>([
                SELECT Id, name, Type__c 
                FROM ClassseurOnglets__c 
                WHERE ID IN :sectionsPerOnglet.keySet()
            ]);

            System.debug('generateOutput: sectionOrderMap => ' + sectionOrderMap);

            // passing in wrapper to use in methods
            this.wrapper.mapSections = mapSections; 
            this.wrapper.sectionOrderMap = sectionOrderMap; 
            this.wrapper.sectionsPerOnglet = sectionsPerOnglet; 
            this.wrapper.ongletsMap = ongletsMap; 
        }

        // retrieve all quote request of current UW year selected by user START
        if(sectionOrderMap.size() > 0){
            // retrieving requests of current UW year
            String queryExercise = classeursRetrieved[0].Exercise__c;
            String queryProgram = this.program; 
            String queryPcc = this.pcc;
            String queryRtDn = QuoteTable_CST.RT_QUOTE;
            String queryRtLead = QuoteTable_CST.RT_LEAD;
            String forInformation =  QuoteTable_CST.quoteForInformation; 
            for(Request__c rq : Database.query(
                'SELECT ' 
                    + QuoteTable_CST.allFields('Request__c')
                    + ',' + QuoteTable_CST.allParentFields('Section__c', 'Section__r')
                    + ',Section__r.Program__r.PrincipalCedingCompany__r.name' 
                    + ',Section__r.TECH_RenewedSection_ID__r.Program__c' 
                    + ',Section__r.TECH_RenewedSection_ID__r.Treaty__c' 
                    + ' FROM Request__c'
                    + ' WHERE recordType.developerName = :queryRtDn'
                    + ' AND LastVersionAnswered__c = true' 
                    + ' AND Section__c IN :setSections' 
                    + ' AND section__r.program__r.UwYear__c = :queryExercise'
                    + ' AND Treaty__r.Program__c = :queryProgram'
                    + ' AND Program__r.PrincipalCedingCompany__c = :queryPcc'
                    + ' AND QuoteType__c = :forInformation'
                    + ' ORDER BY Reinsurer__r.name,broker__r.name'
            )){
                System.debug('generateOutput: retrieving quote requests: ' + rq);
                String reinsurerId = rq.Reinsurer__c; 
                if(rq.broker__c != null){
                    reinsurerId = reinsurerId + '_' + rq.broker__c;
                }

                if(!quoteDetails.containsKey(reinsurerId)){
                    Map<String, request__c> currentSectionRequest = new Map<String, Request__c>();
                    currentSectionRequest.put(rq.Section__c, rq); 
                    quoteDetails.put(reinsurerId, currentSectionRequest);
                }else{
                    quoteDetails.get(reinsurerId).put(rq.Section__c, rq);
                }

                // keeps a mapping of old section to new section
                newToOldSection.put(rq.Section__c, rq.Section__r.TECH_RenewedSection_ID__c );
                oldToNewSection.put(rq.Section__r.TECH_RenewedSection_ID__c, rq.Section__c);
                oldTreaties.add(rq.Section__r.TECH_RenewedSection_ID__r.Treaty__c);
                oldPrograms.add(rq.Section__r.TECH_RenewedSection_ID__r.Program__c);
            }
            this.wrapper.newToOldSection = newToOldSection; 
            this.wrapper.oldToNewSection = oldToNewSection; 
            // retrieve all quote request of current UW year selected by user End

            List<id> queryOldSectionsId = newToOldSection.values(); 
            // retrieve all quote request of previous UW year selected by user START
            for(Request__c rq : Database.query(
                'SELECT ' 
                    + QuoteTable_CST.allFields('Request__c')
                    + ',' + QuoteTable_CST.allParentFields('Section__c', 'Section__r')
                    + ',Section__r.Program__r.PrincipalCedingCompany__r.name' 
                    + ' FROM Request__c'
                    + ' WHERE recordType.developerName = :queryRtDn'
                    + ' AND Section__c IN :queryOldSectionsId' 
                    + ' AND LastVersionAnswered__c = true'  
                    + ' AND QuoteType__c = :forInformation'
                    + ' ORDER BY Program__r.PrincipalCedingCompany__r.name'
            )){ 
                System.debug('generateOutput: Retrieving uw-1 request =>' + rq);
                String reinsurerId = rq.Reinsurer__c; 
                if(rq.broker__c != null){
                    reinsurerId = reinsurerId + '_' + rq.broker__c;
                }

                if(!exQuoteDetails.containsKey(reinsurerId)){
                    Map<String, request__c> currentSectionRequest = new Map<String, Request__c>();
                    currentSectionRequest.put(rq.Section__c, rq); 
                    exQuoteDetails.put(reinsurerId, currentSectionRequest);
                }else{
                    exQuoteDetails.get(reinsurerId).put(rq.Section__c, rq);
                }
            }
            // retrieve all quote request of previous UW year selected by user END

            // retrieve all Leaders/Coleaders of previous year START
            if(!oldPrograms.isEmpty()){
                for(Request__c rq : Database.query(
                'SELECT '
                + QuoteTable_CST.allFields('Request__c') 
                + ',' + QuoteTable_CST.allParentFields('Section__c', 'Section__r')
                + ',Reinsurer__r.name, Section__r.Treaty__r.TECH_ActorReferenceNumber__c,treaty__r.TECH_ActorReferenceNumber__c' 
                    + ' FROM Request__c'
                    + ' WHERE recordType.developerName = :queryRtLead'
                    + ' AND Program__c IN :oldPrograms'
                    + ' AND LastVersionAnswered__c = true'
                    + ' ORDER BY Program__r.PrincipalCedingCompany__r.name'
                )){
                    
                    System.debug('generateOutput: TreatyId ' + rq.treaty__c);
                    System.debug('generateOutput: rq.Reinsurer__r.name ' + rq.Reinsurer__r.name);
                    if(String.isNotBlank(rq.treaty__c) && String.isNotBlank(rq.Reinsurer__r.name)){
                        if(mapLeaders.containsKey(rq.treaty__r.TECH_ActorReferenceNumber__c)){
                            mapLeaders.get(rq.treaty__r.TECH_ActorReferenceNumber__c).add(rq.Reinsurer__r.name);
                        }else{
                            mapLeaders.put(rq.treaty__r.TECH_ActorReferenceNumber__c, new Set<String>{rq.Reinsurer__r.name});
                        }
                    }

                    if(String.isNotBlank(rq.treaty__c) && String.isNotBlank(rq.Section__c)){
                        leadDetails.put(rq.Section__r.Treaty__r.TECH_ActorReferenceNumber__c + '_' + rq.Section__r.SectionNumber__c, rq);
                    }
                }
                this.wrapper.leadDetails = leadDetails; 
                System.debug('generateOutput: Lead requests found: leadDetails ' + leadDetails);
            }

            // retrieve all Leaders/Coleaders of previous year END

            System.debug('generateOutput : mapLeaders ' + mapLeaders);
            this.wrapper.mapLeaders = mapLeaders; 
            this.wrapper.exQuoteDetails = exQuoteDetails;
            this.wrapper.quoteDetails = quoteDetails; 
        }

        // Retrieve all classeur configs START
        List<ConfigQuoteTable__mdt> configurationList = [ 
            SELECT
                Args__c
                ,CellsFormat__c
                , ColumnBufferCell__c
                , ConfigIdentifier__c
                , Methodname__c
                , DataSourceType__c
                , DeveloperName
                , HeaderApiFields__c
                , HeaderBufferCells__c
                , HeaderFields__c
                , Label
                , Language
                , MasterLabel
                , MaxCol__c
                , MaxRows__c
                , ShowHeader__c
                , StartColumn__c
                , StartRow__c
                , TableDimension__c
                , DataSourceFieldMapping__c
            FROM ConfigQuoteTable__mdt
            ORDER BY DeveloperName
        ];
         // Retrieve all classeur configs End

        // retrieving sObject metadatas that will be used in field mappings: 
        Set<String> objectsToSelect = new Set<string>{
            'ClasseurOutput__c'
        }; 
        Map<String, Map<String, Object>> fieldMetadataDetails = new Map<String, Map<String, Object>>(); 
        for(String selectedObject : objectsToSelect){
          
            fieldMetadataDetails.put(selectedObject, new Map<String, Object>());
            
            List<String> reqFields = new List<String>();
            Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = gd.get(selectedObject);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
            
            for(String fieldName : MapofField.keySet()) {
                Schema.SObjectField field = MapofField.get(fieldName);
                Schema.DescribeFieldResult F = field.getDescribe();
                System.debug('field-->'+field);
                System.debug('F-->'+F.getType()); //type of field
                
                Map<String,Object> fieldMap  = new Map<String, Object>{
                            'label' => f.getLabel(),
                            'name' => f.getName(),
                            'type' => f.getType()
                        };
                fieldMetadataDetails.get(selectedObject).put(f.getName(), (Object)fieldMap);
            }
            
            System.debug('field details: ' + fieldMetadataDetails);  
        }

        this.wrapper.fieldMetadataDetails = fieldMetadataDetails; 

        // #############################################
        //                Data preparation END
        // #############################################
        
        // call helper to generate output records: 
        createOutputRecords(configurationList);
        System.debug('generateOutput: End');
    }

    /***
    * @description	Method used to prepare all the data that will be used to generate the output records
    * @param        configList - List of configuration metadatas
    * @exception	None special (all catched and logged).
    ***/
    public void createOutputRecords(List<ConfigQuoteTable__mdt> configList){
        
        System.debug('createOutputRecords : Start');

        // initilising callable class to generate the output records based on the configuration
        Callable c = (Callable) Type.forName('QuoteTableSvcHelper').newInstance();
        List<ClasseurOutput__c> listToCreate = new List<ClasseurOutput__c>(); 

        // iterating each tab
        Integer orderOnglet = 1; 
        for (Id ongletId : this.wrapper.ongletsMap.keySet()) {
            
            System.debug('createOutputRecords : ongletId ' + ongletId);
            // iterating and preparing output for onglets
            ClassseurOnglets__c currentOnglet = this.wrapper.ongletsMap.get(ongletId);
            
            // Iterating all configs
            for(ConfigQuoteTable__mdt cfg : configList){
                
                // preparing arguments to pass in methods
                Map<String, Object> args = new Map<String, Object>();

                System.debug('createOutputRecords : currentOnglet.Type__c : ' + currentOnglet.Type__c + ' vs cfg.DeveloperName ' + cfg.DeveloperName + 'Id ONGLET ' + ongletId);
                if(cfg.DataSourceType__c == 'APEX'
                    && cfg.DeveloperName.contains(currentOnglet.Type__c)
                    && cfg.Methodname__c != null
                    ){
                    
                    System.debug('createOutputRecords : valid data source '+ cfg);
                    args.put('data', this.wrapper); 
                    args.put('config', cfg);
                    args.put('ongletId', ongletId);
                    args.put('orderOnglet', orderOnglet);
                    System.debug('createOutputRecords : args ' + args);
                    Object o = c.call(cfg.Methodname__c, args);
                    
                    System.debug('createOutputRecords : returned' + o);
                    if(o != null){
                        listToCreate.addAll((List<ClasseurOutput__c>) o);
                    }
                }else{
                    System.debug('createOutputRecords : Invalid data source, skipping');
                }
            }

            orderOnglet++; 
        }

        // insert list of output generated
        if(!listToCreate.isEmpty()){
            System.debug('createOutputRecords : listToCreate: ' + listToCreate);
            System.debug('createOutputRecords :  inserting list' + listToCreate.size());
            insert listToCreate; 
            
        }
    }



    /***
    * @description	Creates new set of output for classeur and sends request to data factory for data renewal
    * @exception	None special (all catched and logged).
    ***/
    public Map<String, Object> refreshClasseur(){
        System.debug('refreshClasseur : Start');

        Map<String, Object> response = new Map<String,Object>();
        // create a new version of classeur record as a clone of this record
        Map<String, ClassseurOnglets__c> classeurOngletsMap = new Map<string, ClassseurOnglets__c>(); 
        List<ClasseurOngletSections__c> cosList = new List<ClasseurOngletSections__c>();

        // latest classeur record in the version history
        List<Classeur__c> lastClasseurVersion; 
        if(String.isNotBlank(this.initialClasseurRecord)){
            System.debug('refreshClasseur : refreshing from V0');
            lastClasseurVersion = [
                SELECT 
                    Id
                    ,Name
                    ,Commentaire__c
                    ,Cedente__c
                    ,Date_de_Prochain_MAJ__c
                    ,DerniereMajPar__c
                    ,Exercise__c
                    ,InitialClasseurRecord__c
                    ,Program__c
                    ,Status__c
                    ,Version__c
                    ,(SELECT Id, NAME, ORDER__c, Type__c, Classeur__c 
                        FROM Classeur_Onglets__r
                    )
                FROM 
                    Classeur__c
                WHERE 
                InitialClasseurRecord__c = :this.initialClasseurRecord
                ORDER BY 
                    Version__c DESC NULLS LAST
                LIMIT 1   
            ];
        }else{

            System.debug('refreshClasseur : refreshing from V1 +');
            lastClasseurVersion = [
                SELECT 
                    Id
                    ,Name
                    ,Commentaire__c
                    ,Cedente__c
                    ,Date_de_Prochain_MAJ__c
                    ,DerniereMajPar__c
                    ,Exercise__c
                    ,InitialClasseurRecord__c
                    ,Program__c
                    ,Status__c
                    ,Version__c
                    ,(SELECT Id, NAME, ORDER__c, Type__c, Classeur__c 
                        FROM Classeur_Onglets__r
                    )
                FROM 
                    Classeur__c
                WHERE 
                    Id = :this.classeurId
                    OR InitialClasseurRecord__c = :this.classeurId
                ORDER BY 
                    Version__c DESC NULLS LAST
                LIMIT 1   
            ];
        }

        // Create new version of classeur with children records (Classeurs Onglets and Classeur Onglet Sections)
        if(!lastClasseurVersion.isEmpty()){
            System.debug('refreshClasseur : last Version => ' + lastClasseurVersion);

            Classeur__c currentClasseur = lastClasseurVersion[0].clone(false, false, false, false);
            currentClasseur.Version__c = currentClasseur.Version__c + 1; 
            currentClasseur.CurrentUser__c = UserInfo.getUserId();
            currentClasseur.InitialClasseurRecord__c = String.isNotBlank(this.initialClasseurRecord) ? this.initialClasseurRecord : this.classeurId; 
            insert currentClasseur; 

            System.debug('refreshClasseur : current classeur ' + currentClasseur);
            if(!lastClasseurVersion[0].Classeur_Onglets__r.isEmpty()){
                for(ClassseurOnglets__c co : lastClasseurVersion[0].Classeur_Onglets__r){
                    // Map oldId to newly created records of classeur onglets
                    System.debug('refreshClasseur : Initialising classeurOnglets ' + co);
                    ClassseurOnglets__c coNew = co.Clone(false,false,false,false);
                    coNew.Classeur__c = currentClasseur.Id; 
                    classeurOngletsMap.put(co.Id, coNew );
                }

                if(!classeurOngletsMap.isEmpty()){
                    System.debug('refreshClasseur : Inserting classeur onglets size ' + classeurOngletsMap.values()); 
                    insert classeurOngletsMap.values(); 

                    // selecting sections to clone: 
                    for(ClasseurOngletSections__c cos: [SELECT Id, NAME, ClassseurOnglet__c, Order__c, Section__c 
                         FROM ClasseurOngletSections__c WHERE ClassseurOnglet__c IN :classeurOngletsMap.keySet()] 
                    ){
                        System.debug('refreshClasseur : Fetching classeur onglet sections: ' + cos);
                        ClasseurOngletSections__c newCos = cos.clone(false, false,false,false);
                        newCos.ClassseurOnglet__c = classeurOngletsMap.get(cos.ClassseurOnglet__c).Id;
                        cosList.add(newCos);
                    }

                    if(!cosList.isEmpty()){
                        System.debug('refreshClasseur : cosList insert' + cosList);
                        insert cosList; 
                    }
                }
            }
            this.classeurId = currentClasseur.Id; 
            response.put('classeurId' , this.classeurId);
            generateOutput(); 
            DFPCalloutCreate(); 
            System.debug('refreshClasseur : End');
            return response;
        }

        return null;

    }

    /***
    * @description	performs callout to datafactory ws to generate a new excel file
    * @exception	None special (all catched and logged).
    ***/
    public void DFPCalloutCreate(){
        System.debug('DFPCalloutCreate: Start'); 
        
        // Build json body for a new excel file
        DFPCalloutBody jsonBody = new DFPCalloutBody(); 
        jsonBody.OrgId = QuoteTable_CST.ORG_ID; 
        jsonBody.classeurId = this.classeurId; 

        if(this.refreshMode == true){
            jsonBody.ContentId = this.fileId;
        }else{
            jsonBody.TemplateId = QuoteTable_CST.TEMPLATE_ID;
        }

        jsonBody.RequesterId = UserInfo.getUserId();
        System.debug('DFPCalloutCreate: JSON BOdY ' + JSON.serialize(jsonBody));

        Map<String, Object> args = new Map<String, object>();
        
        Callout_SVC callout = new Callout_SVC(); 
        callout.targetURL = 'callout:DataFactory/AXA_RE/CreateWorkbook'; 
        callout.httpMethod = 'POST'; 
        callout.headerParams = null; 
        callout.requestBody = JSON.serialize(jsonBody);
        
        args.put('RecordId', this.classeurId);
        callout.args = args;
        

        ID jobID = System.enqueueJob(callout);
        System.debug('DFPCalloutCreate: Queuable JOB ID: ' + jobID); 
        System.debug('DFPCalloutCreate: End');        
    }


    public class DFPCalloutBody{
        public String OrgId {get;set;}
        public String trace {get;set;}
        public String debug {get;set;}
        public String ClasseurId {get;set;}
        public String TemplateId {get;set;}
        public String ContentId {get;set;}
        public String RequesterId {get;set;}
    }


    public class DataWrapper {  

        /***
        * @description	order of the section to appear in the excel generated
        ***/
        public Map<String, Decimal> sectionOrderMap {get; set;}  
        /***
        * @description Requests per section, per reinsurer
        ***/
        public Map<String, Map<String, Request__c>> quoteDetails {get;set;} 
        /***
        * @description Requests per section, per reinsurer for previous year
        ***/
        public Map<String, Map<String, Request__c>> exQuoteDetails {get;set;}

        /***
        * @description Lead details per section
        ***/
        public Map<String, Request__c> leadDetails {get;set;}

        /***
        * @description set of sections to have per excel sheet
        ***/
        public Map<String, Set<String>> sectionsPerOnglet {get;set;}
        /***
        * @description Map of all the sheet details with the Id as the key
        ***/
        public Map<ID, ClassseurOnglets__c> ongletsMap {get;set;}
        /***
        * @description Map of all sections with the Id as the key
        ***/
        public Map<Id, Section__c> mapSections {get;set;}
        /***
        * @description Id of the classeur
        ***/
        public String classeurId {get;set;}
        /***
        * @description Map relating the current year's section to it's originaal section of the year-1
        ***/
        public Map<String, String> newToOldSection {get;set;}
        /***
        * @description Map relating the last year's section to it's current section of the year
        ***/
        public Map<String, String> oldToNewSection {get;set;}

        /***
        * @description Map containing leaders/coleaders and their treaties
        ***/
        public Map<String, Set<String>> mapLeaders {get;set;}

        /* 
        * @description classeur data (displayed in the top left side of excel generated)
        */
        public Classeur__c classeur {get;set;}


        /* 
        * @description classeur data (displayed in the top left side of excel generated)
        */
        public Map<String, Map<String, Object>> fieldMetadataDetails {get;set;}


        
    }
}