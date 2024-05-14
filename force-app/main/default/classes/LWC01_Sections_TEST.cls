@IsTest
public with sharing class LWC01_Sections_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_Sections
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-OCT-2019  NBI   1.0      Initial version
-- 02-DEC-2019  MBE   1.1      New Test Method Added
-- 11-SEP-2020  SAU   1.2      Modified
--------------------------------------------------------------------------------------
**************************************************************************************/
   static User testUserAdmin;
   static User testUserCE;
   static List<Program__c> lstProgram;
   static List<Treaty__c> lstTreaty;
   static List<Section__c> lstSection;
   static List<CoveredCedingCompany__c> lstCovCedCom;
   static List<Account> lstAccount;
   static List<Request__c> lstLeadRequests;
   static List<Request__c> lstQuoteRequests;
   static List<User> lstUsers = new List<User>();
   static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

   static{
       //create User
       testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
       testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
       User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
       lstUsers.add(testUserAdmin);
       lstUsers.add(assignedToUser);
       lstUsers.add(testUserCE);
       insert lstUsers;

       System.runAs(testUserCE){
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

           //create Program
           lstProgram = new List<Program__c> {
               TestFactory.createProgram('TestProg1', '1', '1'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                       , '2018', lstAccount[0].Id, '23002','2', '25009'),

               TestFactory.createProgram('TestProg2', '2', '2'
                                       , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1)
                                       , '2018', lstAccount[1].Id, '23001', '2', '25001'),

               TestFactory.createProgram('TestProg3', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001')
           };
           insert lstProgram;

           //create Treaty
           lstTreaty = new List<Treaty__c> {
               TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

               TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                                        , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                         , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
           };
           insert lstTreaty;

           //create Section
           lstSection = new List<Section__c> {
               TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                                       , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                       , true, '5', null, '23001', '1', '5', '2', '2'),

               TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                                       , 23, 5, lstProgram[0].Id, lstTreaty[1].Id, '3', '1'
                                       , false, '5', null, '23001', '1', '5', '2', '2'),

               TestFactory.createSection('TestSection3', '3.0', '22003', '20006', '9052'
                                       , 76, 43, lstProgram[1].Id, lstTreaty[2].Id, '1', '1'
                                       , true, '1',null, '23001', '1', '5', '2', '2')
           };
           insert lstSection;

           //create Covered Ceding Company
           lstCovCedCom = new List<CoveredCedingCompany__c> {
               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                            ,false, lstSection[0].Id,true,null,null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                            ,false, lstSection[0].Id,true,null,null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[1].Id
                                            ,false ,lstSection[2].Id,true,null,null)
           };
           insert lstCovCedCom;

            //create lead requests
            lstLeadRequests = new List<Request__c>{
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[4].Id, '2', '4',
                                              mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Sent',lstSection[0].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[4].Id, '2', '4',
                                              mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Sent',lstSection[2].Id)
            };
            lstLeadRequests[0].LastVersionSent__c=true;
            lstLeadRequests[0].LastVersionAnswered__c=true;
            lstLeadRequests[1].LastVersionSent__c=true;
            lstLeadRequests[1].LastVersionAnswered__c=true;
            update lstLeadRequests;

             //create quote requests
             lstQuoteRequests = new List<Request__c>{
                new Request__c(
                Program__c = lstProgram[0].Id,
                Treaty__c = lstTreaty[1].Id,
                Broker__c = lstAccount[4].Id,
                Reinsurer__c = lstAccount[4].Id,
                QuoteType__c = '2',
                TECH_PhaseType__c = '3',
                ActiveStatus__c = '1',
                RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTQuote),
                ReinsurerStatus__c = 'Answered',
                Section__c = lstSection[0].Id),

                new Request__c(
                Program__c = lstProgram[1].Id,
                Treaty__c = lstTreaty[2].Id,
                Broker__c = lstAccount[4].Id,
                Reinsurer__c = lstAccount[4].Id,
                QuoteType__c = '2',
                TECH_PhaseType__c = '3',
                ActiveStatus__c = '1',
                RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTQuote),
                ReinsurerStatus__c = 'Answered',
                Section__c = lstSection[2].Id)
            };
            insert lstQuoteRequests;

            lstQuoteRequests[0].LastVersionSent__c=true;
            lstQuoteRequests[0].LastVersionAnswered__c=true;

            lstQuoteRequests[1].LastVersionSent__c=true;
            lstQuoteRequests[1].LastVersionAnswered__c=true;

            update lstQuoteRequests;
       }
   }

   @IsTest
   public static void testGetSections(){
       System.runAs(testUserCE) {
           Test.startTest();
               List<Id> lstTreatyId = new List<Id>();
               for(Treaty__c treaty : [SELECT Id FROM Treaty__c WHERE Program__c = :lstProgram[0].Id]) {
                   lstTreatyId.add(treaty.Id);
               }
               lstSection = LWC01_Sections.getSections(lstTreatyId);
           Test.stopTest();

           System.assertEquals(2, lstSection.size());
       }
   }

   @IsTest
   public static void testGetCoveredCedingCompanies(){
       System.runAs(testUserCE) {
           Test.startTest();
               lstCovCedCom = LWC01_Sections.getCoveredCedingCompanies(lstSection[0].Id);
           Test.stopTest();
           System.assertEquals(2, lstCovCedCom.size());
       }
   }

   @IsTest
   public static void testGetSectionNumber(){
       System.runAs(testUserCE) {
           Test.startTest();
               Section__c section = [SELECT Id, SectionNumber__c FROM Section__c ORDER BY SectionNumber__c DESC LIMIT 1];
               Decimal sectionNum = Decimal.valueOf(section.SectionNumber__c) + 1.1;
               String sectionNumber = LWC01_Sections.getSectionNumber();
               System.assertEquals(String.valueOf(sectionNum), sectionNumber);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testGetTreatiesForExistedLeadRequest(){
       System.runAs(testUserAdmin) {
           Test.startTest();
              List <Id> lstprogramIds = new List <Id>{lstProgram[0].Id, lstProgram[1].Id};
              List<Id> lstResult = LWC01_Sections.getTreatiesForExistedLeadRequest(lstProgramIds);
              System.assertEquals(2, lstResult.size());
           Test.stopTest();
       }
   }

   @IsTest
   public static void testSaveRetainedToLeadSection(){
       System.runAs(testUserAdmin) {
           Test.startTest();
              List <Id> lstSectionIds = new List <Id>{lstSection[0].Id, lstSection[1].Id};
              List <Id> lstSelectedTreaties = new List <Id> {lstTreaty[0].Id, lstTreaty[1].Id};
              Map<String, Object> mapResults = LWC01_Sections.saveRetainedToLeadSection(lstSectionIds, lstSelectedTreaties);

              System.assertEquals('Success', mapResults.get('Success'));
           Test.stopTest();
       }
   }

   @IsTest
   public static void testGetSelectedTreatyDetail(){
       System.runAs(testUserAdmin) {
           Test.startTest();
                Treaty__c result = LWC01_Sections.getSelectedTreatyDetail(lstTreaty[0].Id);
                System.assertEquals(lstTreaty[0].Name, result.Name);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testCheckStatusRequestQuoteLeadSetupSectionExistsTreatyNull(){
       System.runAs(testUserAdmin) {
           Test.startTest();
            lstLeadRequests[0].ReinsurerStatus__c='Setup';
            lstQuoteRequests[0].ReinsurerStatus__c='Setup';
            lstLeadRequests[1].ReinsurerStatus__c='Setup';
            lstQuoteRequests[1].ReinsurerStatus__c='Setup';

            update lstLeadRequests;
            update lstQuoteRequests;
           List <Id> lstSectionIds = new List <Id>{lstSection[0].Id, lstSection[2].Id};
           Map<String, Object> mapResults = LWC01_Sections.checkStatusRequestQuoteLead(lstSectionIds, null);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testCheckStatusRequestQuoteLeadSetupSectionNullTreatyExists(){
       System.runAs(testUserAdmin) {
           Test.startTest();
            lstLeadRequests[0].ReinsurerStatus__c='Setup';
            lstQuoteRequests[0].ReinsurerStatus__c='Setup';
            lstLeadRequests[1].ReinsurerStatus__c='Setup';
            lstQuoteRequests[1].ReinsurerStatus__c='Setup';

            update lstLeadRequests;
            update lstQuoteRequests;
           List <Id> lstTreatyIds = new List <Id>{lstTreaty[0].Id, lstTreaty[2].Id};
           Map<String, Object> mapResults = LWC01_Sections.checkStatusRequestQuoteLead(null, lstTreatyIds);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testCheckStatusRequestQuoteLeadSentSectionExistsTreatyNull(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           lstLeadRequests[0].ReinsurerStatus__c='Sent';
           lstQuoteRequests[0].ReinsurerStatus__c='Sent';
           lstLeadRequests[1].ReinsurerStatus__c='Sent';
           lstQuoteRequests[1].ReinsurerStatus__c='Sent';

           update lstLeadRequests;
           update lstQuoteRequests;
           List <Id> lstSectionIds = new List <Id>{lstSection[0].Id, lstSection[2].Id};
           Map<String, Object> mapResults = LWC01_Sections.checkStatusRequestQuoteLead(lstSectionIds, null);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testCheckStatusRequestQuoteLeadSentSectionNullTreatyExists(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           lstLeadRequests[0].ReinsurerStatus__c='Sent';
           lstQuoteRequests[0].ReinsurerStatus__c='Sent';
           lstLeadRequests[1].ReinsurerStatus__c='Sent';
           lstQuoteRequests[1].ReinsurerStatus__c='Sent';

           update lstLeadRequests;
           update lstQuoteRequests;
           List <Id> lstTreatyIds = new List <Id>{lstTreaty[0].Id, lstTreaty[2].Id};
           Map<String, Object> mapResults = LWC01_Sections.checkStatusRequestQuoteLead(null, lstTreatyIds);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testCheckStatusRequestQuoteLeadAnsweredSectionExistsTreatyNull(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           lstLeadRequests[0].ReinsurerStatus__c='Answered';
           lstQuoteRequests[0].ReinsurerStatus__c='Answered';
           lstLeadRequests[1].ReinsurerStatus__c='Answered';
           lstQuoteRequests[1].ReinsurerStatus__c='Answered';

           update lstLeadRequests;
           update lstQuoteRequests;
           List <Id> lstSectionIds = new List <Id>{lstSection[0].Id, lstSection[2].Id};
           Map<String, Object> mapResults = LWC01_Sections.checkStatusRequestQuoteLead(lstSectionIds, null);
           Test.stopTest();
       }
   }

   @IsTest
   public static void testCheckStatusRequestQuoteLeadAnsweredSectionNullTreatyExists(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           lstLeadRequests[0].ReinsurerStatus__c='Answered';
           lstQuoteRequests[0].ReinsurerStatus__c='Answered';
           lstLeadRequests[1].ReinsurerStatus__c='Answered';
           lstQuoteRequests[1].ReinsurerStatus__c='Answered';

           update lstLeadRequests;
           update lstQuoteRequests;
           List <Id> lstTreatyIds = new List <Id>{lstTreaty[0].Id, lstTreaty[2].Id};
           Map<String, Object> mapResults = LWC01_Sections.checkStatusRequestQuoteLead(null, lstTreatyIds);
           Test.stopTest();
       }
   }
   
   
   @IsTest
   public static void testupdateRetainToLeadDeactivationProgram(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           List <Id> lstprogramIds = new List <Id>{lstProgram[0].Id, lstProgram[1].Id};
           String strRes = LWC01_Sections.updateRetainToLeadDeactivation(lstprogramIds, 'Program');
           Test.stopTest();
       }
   }
   
   @IsTest
   public static void testupdateRetainToLeadDeactivationTreaty(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           List <Id> lstTreatyIds = new List <Id>{lstTreaty[0].Id, lstTreaty[2].Id};
           String strRes = LWC01_Sections.updateRetainToLeadDeactivation(lstTreatyIds, 'Treaty');
           Test.stopTest();
       }
   }
   
   @IsTest
   public static void testcheckCCC(){
       System.runAs(testUserAdmin) {
           Test.startTest();
           Boolean isCheck  = LWC01_Sections.checkCCC(lstSection[0].Id);
           Test.stopTest();
       }
   }
}