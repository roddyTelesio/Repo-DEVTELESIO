@IsTest
public with sharing class LWC01_HomePageActions_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_HomePageActions
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 03-DEC-2019  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
   static User testUserAdmin;
   static User testUserCE;
   static List<Program__c> lstProgram;
   static List<CoveredCedingCompany__c> lstCovCedCom;
   static List<Treaty__c> lstTreaty;
   static List<PoolTreatySection__c> lstPoolTreatySections;
   static List<Section__c> lstSection;
   static List<Section__c> lstRelatedSection;
   static List<Reinstatement__c> lstReinstatement;
   static List<SObject> lstSelectedRecord;
   static List<Account> lstAccount;
   static List<Pool__c> lstPool;
   static List<Request__c> lstQuoteRequests;
   static List<Request__c> lstLeadRequests;
   static List<User> lstUsers = new List<User>();
   static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
   static List <ContentVersion> lstContentVersion;
   static String fileContent = 'This is an example.';
   static Blob fileContentInBlob = Blob.valueOf(fileContent);
   static List <ContentDocumentLink> lstContentDocumentLink;
   static{
       //create User
       testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
       testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
       User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
       lstUsers.add(testUserAdmin);
       lstUsers.add(assignedToUser);
       lstUsers.add(testUserCE);
       insert lstUsers;

       System.runAs(testUserAdmin){
           Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

           //create Account
           lstAccount = new List<Account> {
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account E','C_0005')
           };
           insert lstAccount;

           lstPool = new List<Pool__c>{
                   TestFactory.createPool('Pool A', 78, '2018', lstUsers[1].Id),
                   TestFactory.createPool('Pool B', 78, '2018', lstUsers[1].Id)
           };
           insert lstPool;

           //create Program
           lstProgram = new List<Program__c> {
               TestFactory.createProgram('TestProg1', '1', '1'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                       , '2018', lstAccount[0].Id, '23002','2'
                                       , '25009'),

               TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                       , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                                       , lstAccount[1].Id, '23001', '2', '25001'),

               TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                       , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                       , lstAccount[1].Id, '23001', '1', '25001')
           };
           insert lstProgram;

           lstTreaty = new List<Treaty__c> {
               TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                       , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

               TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                                       , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

               TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                       , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2'),

               TestFactory.createTreaty('TestTreaty4', 3, 'ref03', '3'
                                       , lstProgram[2].Id, '2', 89, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty5', 3, 'ref03', '3'
                                       , lstProgram[2].Id, '1', 89, '10', '2020-00000222', '1', '2', '2', '2', '2')
           };
           insert lstTreaty;

           lstSection = new List<Section__c> {
               TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                       , 322, 34, lstProgram[0].Id, lstTreaty[4].Id, '3', '1'
                                       , true, '5', null, '23001', '1', '5', '2', '2'),

               TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                       , 23, 5, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                       , false, '5', null, '23001', '1', '5', '2', '2'),

               TestFactory.createSection('TestSection3', '3.1', '22003', '20006', '9052'
                                       , 76, 43, lstProgram[0].Id, lstTreaty[1].Id, '1', '1'
                                       , true, '1',null, '23001', '1', '5', '2', '2'),

               TestFactory.createSection('TestSection4', '4.1', '22003', '20006', '9052'
                                       , 55, 87, lstProgram[1].Id, lstTreaty[3].Id, '1', '1'
                                       , true, '1',null, '23001', '1', '5', '2', '2'),

               TestFactory.createSection('TestSection5', '4.1', '22003', '20006', '9052'
                                       , 55, 87, lstProgram[2].Id, lstTreaty[3].Id, '3', '1'
                                       , true, '5',null, '23001', '1', '5', '2', '2')
           };
           insert lstSection;

           lstRelatedSection = new List<Section__c>{
               TestFactory.createSection('TestRelatedSection1', '3.2', '22003', '20006', '9052'
                                       , 322, 34, lstProgram[2].Id, lstTreaty[3].Id, '3', '1'
                                       , true, '5', lstSection[4].Id, '23001', '1', '5', '2', '2')
           };
           insert lstRelatedSection;

           //create Covered Ceding Company
           lstCovCedCom = new List<CoveredCedingCompany__c> {
               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                           ,false,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                           ,false,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[1].Id
                                           ,true,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                           ,true,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, false, lstTreaty[2].Id
                                           ,true,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                           ,false, lstSection[0].Id,true,null,null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, false, lstTreaty[3].Id
                                           ,false, lstSection[4].Id,true,null,null)
           };
           insert lstCovCedCom;

           //create Pool Treaty Section
           lstPoolTreatySections = new List<PoolTreatySection__c> {
               TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, null
                                           , false,true, 32, null),

               TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                                           , false,true, 40, null),

               TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[3].Id, lstSection[4].Id
                                           , true,false, null, 32)
           };
           insert lstPoolTreatySections;

           //create reinstatement for treaty type XL
           lstReinstatement = new List<Reinstatement__c> {
               TestFactory.createReinstatement(lstSection[2].Id, true, 40, 39, '1'
                                               , '3'),

               TestFactory.createReinstatement(lstSection[2].Id, true, 34, 4, '1'
                                               , '3'),

               TestFactory.createReinstatement(lstSection[3].Id, true, 420, 9, '1'
                                               , '3'),

               TestFactory.createReinstatement(lstSection[3].Id, true, 3, 54, '1'
                                               , '3'),

               TestFactory.createReinstatement(lstSection[4].Id, true, 3, 54, '1'
                                               , '3')
           };
           insert lstReinstatement;

           //create request
           lstQuoteRequests = new List<Request__c>{
               // recordTypeId + status required
               TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[0].Id, lstAccount[4].Id, '1', '3',
                                             mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[1].Id),

               TestFactory.createRequest(lstProgram[1].Id, lstTreaty[4].Id, lstAccount[2].Id, lstAccount[4].Id, '2', '1',
                                         mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Answered',lstSection[2].Id)
            };
            insert lstQuoteRequests;

            lstLeadRequests = new List<Request__c>{
               TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[1].Id, lstAccount[2].Id, lstAccount[4].Id, '2', '1',
                                             mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Setup',lstSection[4].Id),
               TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[1].Id, lstAccount[2].Id, lstAccount[4].Id, '2', '1',
                                             mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Answered',lstSection[1].Id)
            };

            //create documents
           lstContentVersion = new List<ContentVersion>{
               TestFactory.createContentVersion('2','1'
                                               , '1', 'CV1', fileContentInBlob, 'CV1'),
               TestFactory.createContentVersion('2','1'
                                               , '1', 'CV2', fileContentInBlob, 'CV2')
           };
           insert lstContentVersion;

           List<Id> lstContentVersionId = new List<Id>();
           for(ContentVersion contentVersion : lstContentVersion){
               lstContentVersionId.add(contentVersion.Id);
           }

           lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :lstContentVersionId];

           lstContentDocumentLink = new List<ContentDocumentLink>{
                   TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstProgram[0].Id, 'V')
           };
           insert lstContentDocumentLink;
    }
   }

   @IsTest
   public static void testReactivateDeactivate(){
       System.runAs(testUserAdmin){
           Test.startTest();
               //Deactivate Program
               lstSelectedRecord = new List<SObject>{lstProgram[0],lstProgram[1]};
               Map<String, Object> mapResultProgram = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Program', '2', true);

               Map<String, Object> mapResultProgram1 = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Program', '2', false);

               //Activate Treaty
               lstSelectedRecord = new List<SObject>{lstTreaty[0]};
               Map<String, Object> mapResultTreaty = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Treaty', '1', true);
               Map<String, Object> mapResultTreaty2 = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Treaty', '1', false);

               //Deactivate Section
               lstSelectedRecord = new List<SObject>{lstSection[4]};
               Map<String, Object> mapResultSection = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Section', '2', true);
               Map<String, Object> mapResultSection3 = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Section', '2', false);

               //activate requests
               lstSelectedRecord = new List<SObject>{lstQuoteRequests[0]};
               Map<String, Object> mapResultRequest = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Request', '1', true);
               Map<String, Object> mapResultRequest4 = (Map<String, Object>) LWC01_HomePageActions.reactivateDeactivate(lstSelectedRecord, 'Request', '1', false);
           Test.stopTest();

           for(Program__c program : new List<Program__c>{lstProgram[0], lstProgram[1]}){
               System.assertEquals('2', program.Status__c);
           }

           for(Treaty__c treaty : new List<Treaty__c>{lstTreaty[0]}){
               System.assertEquals('1', treaty.Status__c);
           }

           for(Section__c section : new List<Section__c>{lstSection[0]}){
               System.assertEquals('1', section.Status__c);
           }
           System.assertEquals('Records successfully Deactivated.', mapResultProgram.get('Success'));
           //System.assertEquals('Records successfully Reactivated.', mapResultTreaty.get('Success'));
           System.assertEquals('Records successfully Deactivated.', mapResultSection.get('Success'));
       }
   }

   @IsTest
   public static void testDeleteRecords() {
       System.runAs(testUserAdmin) {
           Test.startTest();
               //Delete Program Record
               lstSelectedRecord = new List<SObject>{lstProgram[0]};
               Map<String, Object> mapResultProgram = (Map<String, Object>) LWC01_HomePageActions.deleteRecords(lstSelectedRecord, 'Program__c');

               //Delete Treaty Record
               lstSelectedRecord = new List<SObject>{lstTreaty[4]};
               Map<String, Object> mapResultTreaty = (Map<String, Object>) LWC01_HomePageActions.deleteRecords(lstSelectedRecord, 'Treaty__c');
               lstSelectedRecord = new List<SObject>{lstTreaty[2]};
               Map<String, Object> mapResultTreaty1 = (Map<String, Object>) LWC01_HomePageActions.deleteRecords(lstSelectedRecord, 'Treaty__c');

               //Delete Program Record
               lstSelectedRecord = new List<SObject>{lstSection[4]};
               Map<String, Object> mapResultSection = (Map<String, Object>) LWC01_HomePageActions.deleteRecords(lstSelectedRecord, 'Section__c');

               //Delete Request Record
               lstSelectedRecord = new List<SObject>{lstLeadRequests[1]};
               Map<String, Object> mapResultRequest = LWC01_HomePageActions.deleteRecords(lstSelectedRecord, 'Request__c');

               lstSelectedRecord = new List<SObject>{lstQuoteRequests[1]};
               Map<String, Object> mapResultRequest2 = LWC01_HomePageActions.deleteRecords(lstSelectedRecord, 'Request__c');

           Test.stopTest();

           lstProgram = [SELECT Id, (SELECT Id FROM Treaties__r), (SELECT Id FROM Sections__r)
                         FROM Program__c WHERE Id = :lstProgram[0].Id];

           lstTreaty = [SELECT Id FROM Treaty__c WHERE Id = :lstTreaty[2].Id];

           lstSection = [SELECT Id FROM Section__c WHERE Id = :lstSection[4].Id];
       }
   }

   @IsTest
   public static void testRecalculateSectionNumbers(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           Set<Id> setTreatyIds = new Set<Id>();
           setTreatyIds.add(lstTreaty[3].Id);

           LWC01_HomePageActions.recalculateSectionNumbers(setTreatyIds);
           Test.stopTest();

           List <Section__c> lstUptSections = [SELECT SectionNumber__c, Treaty__c FROM Section__c WHERE Treaty__c IN :setTreatyIds AND RelatedSection__c = null];
           System.assertEquals('1.1', lstUptSections[0].SectionNumber__c);
       }
   }

   @IsTest
   public static void testCheckRequestExist(){
       System.runAs(testUserAdmin) {
        Test.startTest();
            //Deactivate Program
            lstSelectedRecord = new List<SObject>{lstProgram[0],lstProgram[1]};
            Map<String, Object> mapResultProgram = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Program', '2', true);

            Map<String, Object> mapResultProgram1 = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Program', '2', false);

            //Activate Treaty
            lstSelectedRecord = new List<SObject>{lstTreaty[0]};
            Map<String, Object> mapResultTreaty = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Treaty', '1', true);
            Map<String, Object> mapResultTreaty2 = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Treaty', '1', false);

            //Deactivate Section
            lstSelectedRecord = new List<SObject>{lstSection[4]};
            Map<String, Object> mapResultSection = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Section', '2', true);
            Map<String, Object> mapResultSection3 = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Section', '2', false);

            //activate requests
            lstSelectedRecord = new List<SObject>{lstQuoteRequests[0]};
            Map<String, Object> mapResultRequest = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Request', '1', true);
            Map<String, Object> mapResultRequest4 = (Map<String, Object>) LWC01_HomePageActions.checkRequestExist(lstSelectedRecord, 'Request', '1', false);
            Test.stopTest();
       }
   }
}