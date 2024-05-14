public with sharing class CreateClasseurs {
    
    
    @AuraEnabled
    public static List<programsData> fetchPrograms(String accountId, String uwYear) {
        System.debug('fetchRecords: Start');
        List<programsData> recordsDataList = new List<programsData>();
        for(Program__c p: [SELECT Id, Name FROM Program__c WHERE PrincipalCedingCompany__c = :accountId AND UwYear__c = :uwYear ORDER BY Name]){
            recordsDataList.add( new programsData((String)p.get('Name'), (String)p.get('id')) );
        }

        return recordsDataList;        
    }


    @AuraEnabled
    public static List<treatyData> fetchTreatys(String programId) {
        System.debug('fetchRecords: Start');
        List<treatyData> recordsDataList = new List<treatyData>();
        for(Treaty__c p: [SELECT Id, name,TreatyReference__c, TypeofTreaty__c  FROM Treaty__c WHERE Program__c = :programId ORDER BY Layer__c,Name]){
            recordsDataList.add( new treatyData((String) (p.name + ' ' + p.TreatyReference__c), (String)p.get('id'), p.TypeofTreaty__c) );
        }

        return recordsDataList;        
    }


    @AuraEnabled
    public static Map<String, Object> fetchSections(String programId, String treatyId, String uwYear, String accountId) {
        System.debug('fetchSections: Start');

        Map<String, Object> returnedValue  = new Map<String, Object>(); 

        List<SectionsData> recordsDataList = new List<SectionsData>();
        Map<String, List<Id>> sectionsPerTreaty = new Map<String, List<Id>>(); 
        Map<String, List<SectionsData>> sectionsInfoPerTreaty = new Map<String, List<SectionsData>>();
        Map<String, SectionsData> mapSections = new Map<String, SectionsData>(); 

        for(Section__c p: [SELECT Id, NAME, SectionNumber__c, Treaty__c, Treaty__r.TypeofTreaty__c    
                            FROM Section__c 
                            WHERE Program__c = :programId
                            AND Program__r.UwYear__c = :uwYear
                            AND Program__r.PrincipalCedingCompany__c = :accountId
                            ORDER BY Treaty__r.Layer__c, Treaty__r.Name, SectionNumber__c]){

            SectionsData currentSection = new SectionsData(
                (String) (p.SectionNumber__c + ' ' + p.name), 
                (String)p.get('id'), 
                p.Treaty__c,
                p.Treaty__r.TypeofTreaty__c               
            );                    
            recordsDataList.add(currentSection);

            if(sectionsPerTreaty.containsKey(p.Treaty__c)){
                sectionsPerTreaty.get(p.Treaty__c).add(p.Id);
                sectionsInfoPerTreaty.get(p.Treaty__c).add(currentSection);
            }else{
                sectionsPerTreaty.put(p.Treaty__c , new List<Id>{p.Id});
                sectionsInfoPerTreaty.put(p.Treaty__c , new List<SectionsData>{currentSection});
            }

            mapSections.put(p.Id, currentSection);
        }

        returnedValue.put('data', recordsDataList);
        returnedValue.put('sectionsPerTreaty', sectionsPerTreaty);
        returnedValue.put('sectionsInfoPerTreaty', sectionsInfoPerTreaty);
        returnedValue.put('mapSections', mapSections);

        return returnedValue;        
    }


    @AuraEnabled
    public static Map<String, Object> refreshClasseur(String ClasseurId, String fileId) {
        System.debug('refreshClasseur: Start');
        System.debug('refreshClasseur: ClasseurId : ' + ClasseurId);
        System.debug('refreshClasseur: Start fileId : ' + fileId);

        if(fileId == null){
            throw new QtException('No File Uploaded');
        }

        if(ClasseurId == null){
            throw new QtException('No Classeur Record Selected');
        }


        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = fileId
            , LinkedEntityId = QuoteTable_CST.ID_DFUSER
            , ShareType = 'C'
        );

        insert cdl; 

        Classeur__c c = [SELECT Id, InitialClasseurRecord__c FROM classeur__c WHERE Id =:ClasseurId limit 1];

        Map<String, Object> result = new Map<String, Object>(); 
        

        QuoteTable_SVC quoteOutputService = new QuoteTable_SVC(ClasseurId, true, fileId, c.InitialClasseurRecord__c);
        Map<String, object> responseService = quoteOutputService.refreshClasseur(); 
        
        if(responseService == null){
            System.debug('refreshClasseur : refresh failed, new classeur Id not generated');
            throw new QtException('refresh failed, new classeur Id not generated');
        }
        result.put('status', 'ok');
        result.put('classeurId' , responseService.get('classeurId'));
        System.debug('refreshClasseur: End');
        return result;
    }
    @AuraEnabled
    public static Map<String, Object> insertClasseurs(String tabs, String basic, String tabDetails) {
        System.debug('insertClasseurs: Start');
        Map<String, Object> result = new Map<String, Object>();
        Map<String, Object> tabSectionDetails = (Map<String, Object>) JSON.deserializeUntyped(tabs);
        Map<String, Object> basicDetails = (Map<String, Object>) JSON.deserializeUntyped(basic);

        // Create classeur Records
        Classeur__c c = new Classeur__c(); 
        c.name = (String) basicDetails.get('name'); 
        c.Exercise__c = (String) basicDetails.get('uwYear'); 
        c.Cedente__c = (String) basicDetails.get('principalCedingCompany'); 
        c.Program__c = (String) basicDetails.get('program'); 
        c.CurrentUser__c = UserInfo.getUserId();
        insert c;
        result.put('classeur', c);
        System.debug('insertClasseurs: classeur Inserted ' + c.Id);

    
        Integer tabOrder = 1;
        List<ClasseurOngletSections__c> listCos = new List<ClasseurOngletSections__c>(); 

        for(String key: tabSectionDetails.keySet()){
            String rowAsString = JSON.serialize(tabSectionDetails.get(key));  
            InputRow row = (inputRow) JSON.deserializeStrict(rowAsString, inputRow.class); 
            
            System.debug('row: ' + row);

            // create tab records
            ClassseurOnglets__c co = new ClassseurOnglets__c(); 
            co.Classeur__c = c.Id; 
            co.Type__c = row.type;  
            co.Order__c = tabOrder; 
            co.Name = key; 
            Insert co; 
            tabOrder++; 

            // initialise tab section records
            Integer sectionOrder = 1; 
            for(String s: row.sectionsSelected){
                listCos.add(new ClasseurOngletSections__c(
                    Name = (c.name + ' ' + co.Name + ' ' + sectionOrder)
                    , ClassseurOnglet__c = co.Id
                    , Section__c = s
                    , Order__c = sectionOrder
                ));
                sectionOrder++; 
            }
        }

        if(!listCos.isEmpty()){
            insert listCos; 

            // create output records
            QuoteTable_SVC quoteOutputService = new QuoteTable_SVC(c.Id);
            quoteOutputService.generateOutput(); 
            quoteOutputService.DFPCalloutCreate(); 
        }

        
        System.debug('insertClasseurs: End');
        return result; 
    }

    @AuraEnabled(cacheable=true)
   public static List<Classeur__c> getClasseurs( String searchKey, String sortBy, String sortDirection , String fields, String selectedUwYear, String cedingCompany, String defaultCedingComps) {
      
        String query = 'SELECT '+ fields +' FROM Classeur__c WHERE ';
        system.debug('query---'+query);

        Boolean firstAdded = false; 
        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            query += 'Name LIKE :key';
            firstAdded = true; 
        }

        if(selectedUwYear != '' && selectedUwYear != null){
            if(firstAdded == true){
                query += ' AND ';
            }
            query += 'Exercise__c = :selectedUwYear';
            firstAdded= true; 
        }

        if(cedingCompany != '' && cedingCompany != null){
            if(firstAdded == true){
                query += ' AND ';
            }
            query += 'Cedente__c = :cedingCompany'; 
            firstAdded= true; 
        }else if(defaultCedingComps != '' && defaultCedingComps != null){
            if(firstAdded == true){
                query += ' AND ';
            }
            query += 'Cedente__c IN ('+defaultCedingComps+')'; 
            firstAdded= true; 
        }

        if ( sortBy != null && sortDirection != null ) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        // query = query + ' LIMIT 10';
        System.debug('getClasseurs : Query ' + query);

        List<classeur__c> listClasseursRetrieved = Database.query( query );

        // contains the latest classeur version with the key being the initial classeur record
        Map<Id, Classeur__c> mapLatestClasseur = new Map<id,Classeur__c>(); 

        for(Classeur__c c : listClasseursRetrieved ){
            System.debug('processing : classeur c ' + c );
            if(c.InitialClasseurRecord__c != null){

                if(!mapLatestClasseur.containsKey(c.InitialClasseurRecord__c)){
                    System.debug('Adding to latest record for the first time : ' + c.Id  + ' init version ' +c.InitialClasseurRecord__c  );
                    mapLatestClasseur.put(c.InitialClasseurRecord__c, c);
                }else if(mapLatestClasseur.containsKey(c.InitialClasseurRecord__c) 
                    && c.Version__c > mapLatestClasseur.get(c.InitialClasseurRecord__c).Version__c)
                {
                    System.debug('populating latest classeur with latest versionf or classeur : ' + c.Id + ' init version ' +c.InitialClasseurRecord__c );
                    mapLatestClasseur.put(c.InitialClasseurRecord__c, c);
                }
            }
        }

        List<Classeur__c> listClasseurToDisplay = new List<Classeur__c>();
        for(Classeur__c c : listClasseursRetrieved){
            if(!mapLatestClasseur.isEmpty()){
                if(!mapLatestClasseur.containsKey(c.Id) && c.Version__c == 0){
                    listClasseurToDisplay.add(c);
                }
                else if(mapLatestClasseur.containsKey(c.InitialClasseurRecord__c) && mapLatestClasseur.get(c.InitialClasseurRecord__c).Id == c.Id){
                    listClasseurToDisplay.add(c);
                }
            }else{
                listClasseurToDisplay.add(c);
            }  
        }
        System.debug('listClasseursRetrieved : ' + listClasseursRetrieved);

        return listClasseurToDisplay;
    }

    @AuraEnabled(cacheable=true)
    public static string getFileList(List<String> classeurIds){
        System.debug('getFileList : Start with ' + classeurIds);
        String classeurList = '';
        for(ContentDocumentLink cdl : [SELECT id, ContentDocumentId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink where LinkedEntityId IN :classeurIds]){
            System.debug(cdl.ContentDocument.LatestPublishedVersionId);
            System.debug(cdl);
            classeurList += (cdl.ContentDocument.LatestPublishedVersionId + '/');
        }

        System.debug('classeurList :'+ classeurList ); 
        System.debug('getFileList : End');
        classeurList = classeurList.removeEnd('/');
        return classeurList + '?'; 
    }

    @AuraEnabled
    public static Map<String, Object> fetchClasseur(String Id){
        System.debug('fetchClasseur: start');
        // retrieve all infos for the classeurs
        Map<String, Object> results = new Map<String, Object>(); 

        Classeur__c c = [SELECT Id, Name, Cedente__c, Exercise__c, Program__c FROM Classeur__c WHERE id = :Id LIMIT 1];

        results.put('classeur' , c);

        Map<string, Object> mapSelectedSections = new Map<String, Object>(); 
        // selection of onglets and sections
        List<ClassseurOnglets__c> lstClasseurOnglets = [SELECT Type__c, Id, Name, (SELECT Id, NAME, Section__r.Id, Section__r.NAME, Section__r.SectionNumber__c, Section__r.Treaty__c, Section__r.Treaty__r.TypeofTreaty__c FROM Classeur_Onglet_Sections__r) FROM ClassseurOnglets__c WHERE Classeur__c = :c.Id]; 
        List<tab> tabList = new List<tab>(); 

        for(ClassseurOnglets__c co: lstClasseurOnglets){
            System.debug('fetchClasseur: classeurOnglet ' + co);

            List<String> sectionsSelected = new List<String>(); 
            for(ClasseurOngletSections__c cos: co.Classeur_Onglet_Sections__r){
                System.debug('fetchClasseur: cos '+ cos);
                sectionsSelected.add(cos.Section__c);
            }
            InputRow row = new InputRow(); 
            row.sectionsSelected = sectionsSelected; 
            row.type = co.Type__c; 
            System.debug('fetchClasseur: ' + row);
            mapSelectedSections.put(co.Name, row);
            
            // create tab 
            Tab t =  new Tab(); 
            t.name = co.name; 
            t.type = co.Type__c; 
            tabList.add(t);

        }

        results.put('mapSelectedSections', mapSelectedSections);
        results.put('tabs', tabList); 
        System.debug('fetchClasseur: End');

        return results;
    }




    
    public class tab {  
        @AuraEnabled public String name {get;set;} 
        @AuraEnabled public String type {get;set;}  
    }
    public class inputRow{
        @AuraEnabled public String treatySelected{get;set;} 
        @AuraEnabled public List<SectionsData> sectionsUnselected {get;set;}
        @AuraEnabled public List<String> sectionsSelected {get;set;} 
        @AuraEnabled public String type {get;set;}
    }
    


    public class programsData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public programsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class treatyData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String type;
        public treatyData(String label, String value, String type) {
            this.label = label;
            this.value = value;
            this.type = type; 
        }
    }

    public class SectionsData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String treatyId; 
        @AuraEnabled public String type; 
        public SectionsData(String label, String value, String treatyId, String type) {
            this.label = label;
            this.value = value;
            this.treatyId =treatyId;  
            this.type = type;
        }
    }

    public class TabsData{
        String name;
        String type;
    }

    public class QtException extends Exception {
        
    }
}