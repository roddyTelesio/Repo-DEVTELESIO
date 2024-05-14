/**
 * @description       : 
 * @author            : Telesio
 * @group             : 
 * @last modified on  : 08-16-2022
 * @last modified by  : Telesio (RRA)
**/
public without sharing class CreateEditSubsection {
    public class ObjectContext {     
        @InvocableVariable(required=false label='Subsection record' )//MRA NEREE Correctif 23/08/2023 : START
        public Subsection__c subsection;

        @InvocableVariable(required=false label='Value Type Reinstatment' )//MRA NEREE Correctif 23/08/2023 : START
        public String typeReins;

        @InvocableVariable(required=true label='Subsection New record' )
        public Subsection__c subsectionNewRecord;

        @InvocableVariable(required=true label='Section Id' )
        public String sectionId;

        @InvocableVariable(required=false label='Type Reinstatement (On Section)' )
        public String type;

        @InvocableVariable(required=false  label='Selected Hazard Bassins')
        public List<ReferentialHazardBassin__c> HBs;
        
        //RRA - ticket 1665 - 14122023
        @InvocableVariable(required=false  label='UnSelected Hazard Bassins')
        public List<ReferentialHazardBassin__c> unHBs;
        
        //RRA - ticket 1665 - 14122023
        @InvocableVariable(required=false  label='UnSelected PorfolioSegments')
        public List<PortFolioSegment__c> unPS;

        @InvocableVariable(required=false  label='Selected Portfolio segments')
        public List<PortFolioSegment__c> PSegs;

        @InvocableVariable(required=false  label='Selected Reinstatements')
        public List<Reinstatement__c> Reinst;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Upserted subsection')
        public Subsection__c subsection;

        @InvocableVariable(required=false label='Error message')
        public String errMsg;

        public Result(Boolean isSuccess, Subsection__c subsection, String errMsg){
            this.isSuccess = isSuccess;
            this.subsection = subsection;
            this.errMsg = errMsg;
        }
    }

    /***
    * @description	Method to prepare callout to retrieve slots 
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[NERE] Create/Edit Subsections' description='Create/ Edit subsections + add junctions records' callout=false)
    public static List<Result> createEditSub(List<ObjectContext> obj) {
        System.debug(LoggingLevel.DEBUG, 'createEditSub START with : ' + obj);

        List<PortfolioSubsection__c> HBsJunctionsToInsert = new List<PortfolioSubsection__c>();
        List<PortfolioSubsection__c> PSegsJunctionsToInsert = new List<PortfolioSubsection__c>();
        List<Reinstatement__c> lstInsertReinst = new  List<Reinstatement__c>();
        List<Reinstatement__c> lstUpdateReinst = new  List<Reinstatement__c>();
        List<Reinstatement__c> lstDeleteReinstTypeChanged = new  List<Reinstatement__c>();
        List<Reinstatement__c> lstDeleteDupliReinstTypeOther = new  List<Reinstatement__c>();
        List<Reinstatement__c> lstReinsCreatedType_FreeLimit_None = new  List<Reinstatement__c>();
        List <Reinstatement__c> lstReinsWithOrder = new  List<Reinstatement__c>();
        List<String> lstKeyUnHB = new List<String>(); //RRA - ticket 1665 - 15122023
        List<String> lstKeyUnPS = new List<String>(); //RRA - ticket 1665 - 15122023

        Set<String> setUpsertReinst = new Set<String>();
        String HBsNames = '';
        String HBsIds = '';
        String HBsIdsUpdate = '';
        String PSegNames = '';
        String PSegIds = '';
        String PSegIdsUpdate = '';
        String key36charachers ;

        Subsection__c selectedSubsection = new Subsection__c() ;
        List<Reinstatement__c> lstReinsNull = new List<Reinstatement__c> ();

        //MRA NEREE Correctif 23/08/2023 : START
        if(obj[0].subsection != null) 
            selectedSubsection = obj[0].subsection;
        //MRA NEREE Correctif 23/08/2023 : END

        Subsection__c newRecordSubSec = obj[0].subsectionNewRecord;

        System.debug(LoggingLevel.DEBUG, 'createEditSub selectedSubsection: ' + selectedSubsection);
        System.debug(LoggingLevel.DEBUG, 'newRecordSubSec : ' + newRecordSubSec);
        System.debug(LoggingLevel.DEBUG, 'selectedSubsection.Id : ' + selectedSubsection.Id);

        Savepoint sp = Database.setSavepoint();

        try{
            //Insert subsection from UI => Id is null
            if(selectedSubsection.Id == null){
                selectedSubsection.AAL__c = newRecordSubSec.AAL__c;
                selectedSubsection.AAD__c = newRecordSubSec.AAD__c;
                selectedSubsection.Deductible__c = newRecordSubSec.Deductible__c;
                selectedSubsection.Limit__c = newRecordSubSec.Limit__c;
                selectedSubsection.LimitType__c = newRecordSubSec.LimitType__c;
                selectedSubsection.TAL__c = newRecordSubSec.TAL__c;
                 selectedSubsection.Section__c = obj[0].sectionId;
                selectedSubsection.Unlimited__c = newRecordSubSec.Unlimited__c;

                insert selectedSubsection;
            //Insert subsection from DB => Id is not null
            }else if (selectedSubsection.Id != null){
                System.debug(LoggingLevel.DEBUG, 'Begin Update SubSection :');
                selectedSubsection.AAL__c = newRecordSubSec.AAL__c;
                selectedSubsection.AAD__c = newRecordSubSec.AAD__c;
                selectedSubsection.Deductible__c = newRecordSubSec.Deductible__c;
                selectedSubsection.Limit__c = newRecordSubSec.Limit__c;
                selectedSubsection.LimitType__c = newRecordSubSec.LimitType__c;
                selectedSubsection.TAL__c = newRecordSubSec.TAL__c;
                selectedSubsection.Section__c = obj[0].sectionId;
                selectedSubsection.Unlimited__c = newRecordSubSec.Unlimited__c;
                update selectedSubsection;
                System.debug(LoggingLevel.DEBUG, 'Update selectedSubsection :' + selectedSubsection);
            }else{
                //Delete existing junctions 
                deleteJunctionsHBassins(selectedSubsection.Id);
                deleteJunctionsPSegments(selectedSubsection.Id);
            }
    
            //Insert Junctions: Ref. Hazard Bassins
            List<String> lstIdHB = new List<String>();
            System.debug('obj[0].HBs == '+ obj[0].HBs);
            if(obj[0].HBs != null){
                for(ReferentialHazardBassin__c HB : obj[0].HBs){
                    lstIdHB.add(HB.Id);
                    HBsNames += HB.Peril__c + '\n';
                    HBsIds += HB.Id__c + '-';
                    HBsIdsUpdate = HBsIds.removeEnd('-');
    
                    HBsJunctionsToInsert.add(
                        new PortfolioSubsection__c(
                            SubSection__c = selectedSubsection.Id, 
                            Referential_Hazard_Bassin__c = HB.Id,
                            Key_Insert_Update_PortFolioSubSection__c  = selectedSubsection.Id + '_' + HB.Id //RRA - ticket 1665 - 02112023
                        )
                    );
                }
                upsert HBsJunctionsToInsert Key_Insert_Update_PortFolioSubSection__c ; //RRA - ticket 1665 - 02112023
            }
            if (obj[0].unHBs != null){
                System.debug('unHBs == '+ obj[0].unHBs);
                for (ReferentialHazardBassin__c hb : obj[0].unHBs){
                    lstKeyUnHB.add(selectedSubsection.Id + '_' + hb.Id);
                }
                if (lstKeyUnHB.size()>0){
                    deleteJunctionsPSHBassins(lstKeyUnHB);
                }
            }
                
            //insert HBsJunctionsToInsert;
            
    
            //Insert Junctions: Portfolio segments
            if(obj[0].PSegs != null){
                for(PortFolioSegment__c PSeg : obj[0].PSegs){
                    PSegNames += PSeg.PortfolioSegment__c + '\n';
                    PSegIds += PSeg.Id__c + '-';
                    PSegIdsUpdate = PSegIds.removeEnd('-');
                    
                    PSegsJunctionsToInsert.add(
                        new PortfolioSubsection__c(
                            SubSection__c = selectedSubsection.Id, 
                            PortfolioSegment__c = PSeg.Id,
                            Key_Insert_Update_PortFolioSubSection__c  = selectedSubsection.Id + '_' + PSeg.Id //RRA - ticket 1665 - 02112023
                        )
                    );
                }
                upsert PSegsJunctionsToInsert Key_Insert_Update_PortFolioSubSection__c ; //RRA - ticket 1665 - 02112023
            }
            
            if (obj[0].unPS != null){
                System.debug('unPS == '+ obj[0].unPS);
                for (PortFolioSegment__c ps : obj[0].unPS){
                    lstKeyUnPS.add(selectedSubsection.Id + '_' + ps.Id);
                }
                if (lstKeyUnPS.size()>0){
                    deleteJunctionsPSPSegments(lstKeyUnPS);
                }
            }
            //insert PSegsJunctionsToInsert;
           


            System.debug(LoggingLevel.DEBUG, 'HBsNames :' + HBsNames);
            System.debug(LoggingLevel.DEBUG, 'HBsIds :' + HBsIds);
            System.debug(LoggingLevel.DEBUG, 'HBsIdsUpdate :' + HBsIdsUpdate);
            System.debug(LoggingLevel.DEBUG, 'PSegNames :' + PSegNames);
            System.debug(LoggingLevel.DEBUG, 'PSegIds :' + PSegIds);
            System.debug(LoggingLevel.DEBUG, 'PSegIdsUpdate :' + PSegIdsUpdate);

    
            selectedSubsection.lstNameReferentialHazardBassin__c = HBsNames;
            selectedSubsection.lstIdReferentialHazardBassin__c = HBsIdsUpdate;
            selectedSubsection.lstIdPortFolioSegment__c = PSegIdsUpdate;
            selectedSubsection.lstPortFolioSegment__c = PSegNames;
            update selectedSubsection;

            // Upsert Reins if : 
            System.debug('Reinst: ' + obj[0].Reinst);
            System.debug('typeReins: ' + obj[0].typeReins);
            System.debug('reinsType: ' + obj[0].type);

            // init object obj[0].Reinst to empty if reinstatment don't Exists
            obj[0].Reinst = obj[0].Reinst !=null ? obj[0].Reinst : new List<Reinstatement__c>();

            System.debug('Reinst 2222: ' + obj[0].Reinst);

            if(obj[0].Reinst.size() > 0 && !obj[0].Reinst.contains(null)){
                System.debug('Begin');
                for(Reinstatement__c reins : obj[0].Reinst){
                    //Case 1 :Id Reins is null => New Reins 
                    if (reins.Id == null && reins.Sub_Section__c  == null){
                        System.debug('Begin 11');
                        reins.Type__c = obj[0].typeReins;
                        reins.TECH_SectionSubSection__c ='SubSection'; //is Reins attached on SubSection
                        reins.Sub_Section__c = selectedSubsection.Id;
                        reins.Key_Insert_Update_Reinstatement__c = obj[0].sectionId + selectedSubsection.Id + reins.Order__c;
                        lstInsertReinst.add(reins);
                        
                     //Case 2 :Id Reins is not null but SubSection is null (cas retrieve data from section) => data Old Reins value from section 
                    }else if (reins.Id != null && reins.Sub_Section__c  == null){
                        System.debug('Begin 21');
                            System.debug('update');
                            reins.Id = null;
                            reins.Type__c = obj[0].typeReins;
                            reins.Sub_Section__c = selectedSubsection.Id;
                            reins.TECH_SectionSubSection__c ='SubSection'; //is Reins attached on SubSection
                            reins.Key_Insert_Update_Reinstatement__c =  obj[0].sectionId + selectedSubsection.Id + reins.Order__c ;
                            reins.TECH_ExistingReinstatementOnSection__c = true;
                            // Avoid duplication on insertion
                            String keyUpsertReins = obj[0].sectionId + selectedSubsection.Id + reins.Order__c;
                            if(!setUpsertReinst.contains(keyUpsertReins)){
                                setUpsertReinst.add(keyUpsertReins);
                                lstInsertReinst.add(reins);
                            }
                    // Case 3 : existing on database after insert  => Id / Sub_Section__c are not null 
                    }else if (reins.Id != null && reins.Sub_Section__c != null ){
                        System.debug('Begin 23');
                            System.debug('update 3');
                            reins.Id = null;
                            reins.Type__c = obj[0].typeReins;
                            reins.Sub_Section__c = selectedSubsection.Id;
                            reins.TECH_ExistingReinstatementOnSection__c = false;
                            reins.TECH_SectionSubSection__c ='SubSection'; //is Reins attached on SubSection
                            reins.Key_Insert_Update_Reinstatement__c =  obj[0].sectionId + selectedSubsection.Id + reins.Order__c ;
                            //lstInsertReinst.add(reins);

                            String keyUpsertReinsUpdate = obj[0].sectionId + selectedSubsection.Id + reins.Order__c ;
                            if(!setUpsertReinst.contains(keyUpsertReinsUpdate)){
                                setUpsertReinst.add(keyUpsertReinsUpdate);
                                lstInsertReinst.add(reins);
                            }
                    }
                }

            }else{
                System.debug('Begin null List Reins');
                Reinstatement__c reins = new Reinstatement__c ();
                //reins.Id = null;
                reins.Type__c = obj[0].typeReins;
                reins.TECH_SectionSubSection__c ='SubSection'; //is Reins attached on SubSection
                reins.Sub_Section__c = selectedSubsection.Id;
                reins.Section__c =  obj[0].sectionId;
                reins.Key_Insert_Update_Reinstatement__c = obj[0].sectionId + selectedSubsection.Id + reins.Order__c;
                lstInsertReinst.add(reins);
            }

            System.debug(LoggingLevel.DEBUG, 'lstInsertReinst == ' + lstInsertReinst);

            List<String> lstKeyExistingOnBD = new List<String>();
            List<String> recordNoOrder = new List<String>();
            List<Decimal> lstOrder = new List<Decimal>();
            List<Reinstatement__c> lstReinsUpdated = new List<Reinstatement__c>();
            List<Reinstatement__c> lstDeleteReinsSectionExistingInDB = new List<Reinstatement__c>();

            // Step 1 : Delete and Recreate if Type is changed to Freeandlimited or None from others OR is changed to Others from  Freeandlimited or None => Case to avoid issue duplication during upsert 
            if (lstInsertReinst.size() > 0){

                 // For type = 'Others'
                //******************** */

                //1- Delete phase for "others" type 
                List<Reinstatement__c> deletAllOther = [SELECT Id,Type__c, Key_Insert_Update_Reinstatement__c FROM  Reinstatement__c WHERE Type__c = '3' AND Sub_Section__c =: selectedSubsection.Id AND Section__c =: obj[0].sectionId ];

                delete deletAllOther;

                //2- Create or Update phase for others type
                upsert lstInsertReinst Key_Insert_Update_Reinstatement__c;

                for (Reinstatement__c reins : lstInsertReinst){
                    lstKeyExistingOnBD.add(reins.Key_Insert_Update_Reinstatement__c);
                    lstOrder.add(reins.Order__c);
                    lstReinsUpdated.add(reins);
                    key36charachers = reins.Key_Insert_Update_Reinstatement__c.substring(0,36);
                    System.debug(LoggingLevel.DEBUG, 'reins.Type__c == ' + reins.Type__c);
                    System.debug(LoggingLevel.DEBUG, 'reins.Key_Insert_Update_Reinstatement__c == ' + reins.Key_Insert_Update_Reinstatement__c);
                    System.debug(LoggingLevel.DEBUG, 'key36charachers == ' + key36charachers);
                    if ((reins.Type__c == '1' || reins.Type__c == '2') && reins.Key_Insert_Update_Reinstatement__c !=null){
                        lstDeleteReinstTypeChanged.add(reins);
                    } 

                    if (reins.Order__c == null){
                        recordNoOrder.add(reins.Sub_Section__c);
                    } 
                }

                System.debug(LoggingLevel.DEBUG, 'lstDeleteReinstTypeChanged == ' + lstDeleteReinstTypeChanged);

                //Delete the record FreeAndLimited or None if Key_Insert_Update_Reinstatement__c is the same for type Others 
                List<Reinstatement__c> lstReinsFreeLimitedNoneKeyequalToOther = [SELECT Id,Type__c, Key_Insert_Update_Reinstatement__c FROM  Reinstatement__c WHERE Key_Insert_Update_Reinstatement__c =:key36charachers AND TECH_SectionSubSection__c = 'SubSection' AND (Type__c = '1' OR Type__c = '2')];

                if (lstReinsFreeLimitedNoneKeyequalToOther.size() > 0){
                    delete lstReinsFreeLimitedNoneKeyequalToOther;
                }

                System.debug(LoggingLevel.DEBUG, 'lstReinsFreeLimitedNoneKeyequalToOther == ' + lstReinsFreeLimitedNoneKeyequalToOther);

                //Case when changing from None / FreedAndLimited type to Others => Keeping the record with no order and Delete Records with order is not null of lstReinstatement => these additional (the reinstatement records of the sub-section have been initialized by the records of those of the section) records will have to be deleted

                // Delete recordList additionnal 
                if (recordNoOrder != null){
                    lstReinsWithOrder = [SELECT Id,Type__c, Sub_Section__c FROM  Reinstatement__c WHERE Sub_Section__c =:recordNoOrder AND TECH_SectionSubSection__c = 'SubSection' AND Type__c = '3' AND Order__c != NULL];
                }
                if(lstReinsWithOrder.size() > 0 ){
                    delete lstReinsWithOrder;
                }
            }

            if (lstUpdateReinst.size() > 0){
                update lstUpdateReinst;
            }

                 // For type = 'Free and Limited' / 'None'
                //******************** *********************/
                //Delete records for"others" Type  and re-create freeandLimited or none for this same records
            if (lstDeleteReinstTypeChanged.size() > 0){
                delete lstDeleteReinstTypeChanged;
                System.debug(LoggingLevel.DEBUG, 'Del OK == ' + lstDeleteReinstTypeChanged);
                Reinstatement__c reinsCreatedType_FreeLimit_None = new Reinstatement__c ();
                reinsCreatedType_FreeLimit_None.Type__c = obj[0].typeReins;
                reinsCreatedType_FreeLimit_None.TECH_SectionSubSection__c ='SubSection'; //is Reins attached on SubSection
                reinsCreatedType_FreeLimit_None.Sub_Section__c = selectedSubsection.Id;
                reinsCreatedType_FreeLimit_None.Section__c =  obj[0].sectionId;
                reinsCreatedType_FreeLimit_None.Key_Insert_Update_Reinstatement__c = obj[0].sectionId + selectedSubsection.Id;
                lstReinsCreatedType_FreeLimit_None.add(reinsCreatedType_FreeLimit_None);
            }

            //Step 2 :  Delete and Recreate if Type is changed to others from freeandLimited or none
            if (lstReinsCreatedType_FreeLimit_None.size() > 0){
                 //Create or Update Freeandlimited or None
                upsert lstReinsCreatedType_FreeLimit_None Key_Insert_Update_Reinstatement__c;
                System.debug(LoggingLevel.DEBUG, 'lstReinsCreatedType_FreeLimit_None == ' + lstReinsCreatedType_FreeLimit_None);
            }

            System.debug(LoggingLevel.DEBUG, 'createEditSub END');
            return new List<Result>{new Result(true, selectedSubsection, null)};

        }catch(Exception e){
            Database.rollback( sp );
            System.debug(LoggingLevel.DEBUG, 'createEditSub Exception occured: ' + e.getMessage());
            return new List<Result>{new Result(false, null, e.getMessage())};
        }
    }



    public static void deleteJunctionsHBassins(String subsectionId){
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsHazardBassins START with subsectionId : ' + subsectionId);
        delete [
            SELECT Id 
            FROM  PortfolioSubsection__c 
            WHERE SubSection__c=: subsectionId 
            AND   Referential_Hazard_Bassin__c != NULL
            AND   PortfolioSegment__c = NULL];
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsHazardBassins END');
    }

    public static void deleteJunctionsPSegments(String subsectionId){
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSegments START with subsectionId : ' + subsectionId);
        delete [
            SELECT Id 
            FROM  PortfolioSubsection__c 
            WHERE SubSection__c=: subsectionId 
            AND   Referential_Hazard_Bassin__c = NULL
            AND   PortfolioSegment__c != NULL];
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSegments END');
    }
    
    
    public static void deleteJunctionsPSHBassins(List<String> lstkeyHB){
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSHBassins START with lstkeyHB : ' + lstkeyHB);
        delete [
            SELECT Id 
            FROM  PortfolioSubsection__c 
            WHERE Key_Insert_Update_PortFolioSubSection__c  IN: lstkeyHB 
            AND   Referential_Hazard_Bassin__c != NULL
            AND   PortfolioSegment__c = NULL];
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSHBassins END');
    }
    
    public static void deleteJunctionsPSPSegments(List<String> lstKeyPS){
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSPSegments START with lstKeyPS : ' + lstKeyPS);
        delete [
            SELECT Id 
            FROM  PortfolioSubsection__c 
            WHERE Key_Insert_Update_PortFolioSubSection__c In: lstKeyPS 
            AND   Referential_Hazard_Bassin__c = NULL
            AND   PortfolioSegment__c != NULL];
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSPSegments END');
    }


}