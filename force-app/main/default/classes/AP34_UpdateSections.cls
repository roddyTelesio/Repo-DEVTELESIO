public with sharing class AP34_UpdateSections {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update Sections
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
--15-JUN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Update TECH_Reinstatement__c field with particular format
    * @param List<Reinstatement__c> lstReins
    * @return void
    */
    @future //RRA - 1238 - HotFix - add @future to avoid Recursivity for operation updating for Section triggerred on Process Builder ANG_LimitReportingFlags and Classe AP34_UpdteSection line 104 
    public static void updateSections(Set<Id> setId){
        //Set<Id> setSectionId = new Set<Id>();
        Map<Id, List<Reinstatement__c>> mapReinstatementBySectionId = new Map<Id, List<Reinstatement__c>>();
        Map<Id, String> mapReinstatementStrBySectionId = new Map<Id, String>();

       /* for(Reinstatement__c reins : lstReins){
            setSectionId.add(reins.Section__c);
        }*/

        List<Reinstatement__c> lstReinstatements = [SELECT Id, Order__c, Percentage__c, Free__c, toLabel(Prorata__c), Section__c
                                                    FROM Reinstatement__c
                                                    WHERE Id IN :setId
                                                    ORDER BY Order__c ASC];

        for(Reinstatement__c reins : lstReinstatements) {
           // List<Reinstatement__c> lstReinstatement = new List<Reinstatement__c>();

           if (mapReinstatementBySectionId.containsKey(reins.Section__c)){
                mapReinstatementBySectionId.get(reins.Section__c).add(reins);
            }else{
                
                mapReinstatementBySectionId.put(reins.Section__c, new List<Reinstatement__c>{reins});
            }

           /* if (mapReinstatementBySectionId.containsKey(reins.Section__c)) {
                lstReinstatement = mapReinstatementBySectionId.get(reins.Section__c);
            }
            lstReinstatement.add(reins);
            mapReinstatementBySectionId.put(reins.Section__c, lstReinstatement);*/
        }

        for(String sectionId:mapReinstatementBySectionId.keySet()){
            List<Reinstatement__c> lstReinstatementForSection = mapReinstatementBySectionId.get(sectionId);
            String strAllReins = '';
            Reinstatement__c testReinstatement = null;
            String strReins;
            Integer numReins;

            for(Integer i = 0; i < lstReinstatementForSection.size(); i++){
                if(testReinstatement == null){
                    testReinstatement = lstReinstatementForSection[i];
                    numReins = 1;
                    if(lstReinstatementForSection[i].Free__c == true){
                        strReins = 'Free';
                    }
                    else{
                        strReins = lstReinstatementForSection[i].Percentage__c + '% - ' + lstReinstatementForSection[i].Prorata__c;
                    }

                    if(lstReinstatementForSection.size() == 1){
                        strAllReins = numReins + ' @ ' + strReins + '; ';
                    }
                }
                else{
                    if(lstReinstatementForSection[i].Free__c == testReinstatement.Free__c && lstReinstatementForSection[i].Percentage__c == testReinstatement.Percentage__c && lstReinstatementForSection[i].Prorata__c == testReinstatement.Prorata__c){
                        numReins = numReins + 1;
                    }
                    else{
                        if(strAllReins == ''){
                            strAllReins = numReins + ' @ ' + strReins + '; ';
                        }
                        else{
                            strAllReins += numReins + ' @ ' + strReins + '; ';
                        }

                        strReins = null;
                        numReins = 1;
                        testReinstatement = lstReinstatementForSection[i];
                        if(lstReinstatementForSection[i].Free__c == true){
                            strReins = 'Free';
                        }
                        else{
                            strReins = lstReinstatementForSection[i].Percentage__c + '% - ' + lstReinstatementForSection[i].Prorata__c;
                        }
                    }

                    if(i == (lstReinstatementForSection.size() - 1)){
                        strAllReins += numReins + ' @ ' + strReins + '; ';
                    }
                }
            }

            mapReinstatementStrBySectionId.put(sectionId, strAllReins);

            List<Section__c> lstSections = [SELECT Id, Name, TECH_Reinstatement__c, Reinstatements__c FROM Section__c WHERE Id IN :mapReinstatementBySectionId.keySet()];

                for(Section__c sections : lstSections){
                    if(sections.Reinstatements__c == '1'){
                        sections.TECH_Reinstatement__c = 'None';
                    }
                    else if(sections.Reinstatements__c == '2'){
                        sections.TECH_Reinstatement__c = 'Free and Unlimited';
                    }
                    else if(sections.Reinstatements__c == '3'){
                        //Others
                        sections.TECH_Reinstatement__c = mapReinstatementStrBySectionId.get(sections.Id);
                    }
                }
    
                update lstSections;
            
        }
    }
}