@IsTest
public with sharing class LWC01_NewSection_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_NewSection
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 02-DEC-2019  MBE   1.0      Initial version
-- 10-SEP-2020  SAU   1.1      Modified
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<CoveredCedingCompany__c> lstCovCedComEdit;
    static List<Section__c> lstSection;
    static List<Section__c> lstSectionEdit;
    static List<Reinstatement__c> lstReinstatement;
    static List<Reinstatement__c> lstReinstatementEdit;
    static List<Section__c> lstRelatedSection;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<Account> lstAccount;
    static List<Pool__c> lstPool;
    static List<User> lstUsers = new List<User>();
    static List<Request__c> lstQuoteRequests;
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

            //create Pool
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

            lstProgram[1].RenewedFromProgram__c = lstProgram[2].Id;
            update lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                                        , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                        , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty4', 3, 'ref03', '3'
                                        , lstProgram[2].Id, '2', 89, '10', '2020-00000222', '1', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
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

            lstSectionEdit = new List<Section__c>{
                TestFactory.createSection('TestSection6Change', '4.1', '22003', '20006', '9052'
                                        , 76, 43, lstProgram[0].Id, lstTreaty[1].Id, '1', '1'
                                        , true, '1',null, '23001', '1', '5', '2','2'),

                TestFactory.createSection('TestSection7Change', '4.1', '22003', '20006', '9052'
                                        , 55, 87, lstProgram[1].Id, lstTreaty[2].Id, '1', '1'
                                        , true, '1',null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection8', '4.1', '22003', '20006', '9052'
                                        , 55, 87, lstProgram[2].Id, lstTreaty[3].Id, '3', '1'
                                        , true, '5',null, '23001', '1', '5', '2', '2')

            };

            lstRelatedSection = new List<Section__c>{

                TestFactory.createSection('TestRelatedSection1', '3.2', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[2].Id, lstTreaty[3].Id, '3', '2'
                                        , true, '5', lstSection[4].Id, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestRelatedSection1', '3.2', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[2].Id, lstTreaty[3].Id, '3', '2'
                                        , true, '5', lstSection[3].Id, '23001', '1', '5', '2', '2')
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
                                            ,false, lstSection[4].Id,true,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                            ,false, lstRelatedSection[1].Id,true,null,null)
            };
            insert lstCovCedCom;

            lstCovCedComEdit = new List<CoveredCedingCompany__c>{

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, false, lstTreaty[2].Id
                                            ,false, null,false,23,11),

                TestFactory.createCovCedCom(lstAccount[2].Id, null, false, null
                                            ,false, null,false,23,11)
            };

            lstReinstatementEdit = new List<Reinstatement__c>{
                TestFactory.createReinstatement(lstSection[2].Id, true, 40, 39, '1', '3'),

                TestFactory.createReinstatement(lstSection[2].Id, true, 34, 4, '1', '3'),

                TestFactory.createReinstatement(lstSection[3].Id, true, 420, 9, '1', '3')
            };

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, null
                                            , false,true, 32, null),

                TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                                            , false,true, 40, null),

                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[3].Id, lstSection[4].Id
                                            , true,false, null, 32),

                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, lstRelatedSection[1].Id
                                            , true,false, null, 32)
            };
            insert lstPoolTreatySections;

            //create reinstatement for treaty type XL
            lstReinstatement = new List<Reinstatement__c> {

                TestFactory.createReinstatement(lstSection[2].Id, true, 40, 39, '1', '3'),

                TestFactory.createReinstatement(lstSection[2].Id, true, 34, 4, '1', '3'),

                TestFactory.createReinstatement(lstSection[3].Id, true, 420, 9, '1', '3'),

                TestFactory.createReinstatement(lstSection[3].Id, true, 3, 54, '1', '3'),

                TestFactory.createReinstatement(lstSection[4].Id, true, 3, 54, '1', '3'),

                TestFactory.createReinstatement(lstRelatedSection[1].Id, true, 3, 54, '1', '3')
            };
            insert lstReinstatement;

            //create quote requests
            lstQuoteRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[4].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Answered',lstSection[0].Id)
            };
            insert lstQuoteRequests;
        }
    }

    @IsTest
    public static void testSaveSectionRecord(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Section__c> lstNewSection = new List<Section__c>();
                lstCovCedCom = new List<CoveredCedingCompany__c>{lstCovCedComEdit[1]};
                List<CoveredCedingCompany__c> lstNewCovCedCom = new List<CoveredCedingCompany__c>{
                    new CoveredCedingCompany__c(EPI__c = 34, AllocationKey__c = 32, Account__c = lstAccount[2].Id),
                    new CoveredCedingCompany__c(EPI__c = 32, AllocationKey__c = 43, Account__c = lstAccount[3].Id)
                };
                //miss ispool, + list of pools
                Map<String, Object> mapSaveResult = (Map<String, Object>) LWC01_NewSection.saveSectionRecord(lstSectionEdit[0], lstCovCedComEdit, new List<Reinstatement__c>{lstReinstatementEdit[0]}, false, null, false, true, lstPoolTreatySections);
                lstNewSection = [SELECT Id, Name FROM Section__c WHERE Name = :lstSectionEdit[0].Name];

                for(Section__c section : lstNewSection){
                    System.assertEquals('TestSection6Change', section.Name);
                }

                Map<String, Object> mapSaveResultEdit = (Map<String, Object>) LWC01_NewSection.saveSectionRecord(lstSectionEdit[1], new List<CoveredCedingCompany__c>{lstNewCovCedCom[0]}, new List<Reinstatement__c>{lstReinstatementEdit[1]}, true, lstSection[3].Id, false, true, lstPoolTreatySections);
                lstNewSection = [SELECT Id, Name FROM Section__c WHERE Name = :lstSectionEdit[1].Name];

                for(Section__c section : lstNewSection){
                    System.assertEquals('TestSection7Change', section.Name);
                }

                Map<String, Object> mapSaveResultCopy = (Map<String, Object>) LWC01_NewSection.saveSectionRecord(lstSectionEdit[2], new List<CoveredCedingCompany__c>{lstNewCovCedCom[1]}, new List<Reinstatement__c>{lstReinstatementEdit[2]}, false, lstSection[3].Id, false, true, lstPoolTreatySections);
                lstNewSection = [SELECT Id, Name FROM Section__c WHERE Name = :lstSectionEdit[2].Name];
                System.assertEquals(1, lstNewSection.size());

            Test.stopTest();

            System.assertEquals('Success', mapSaveResult.get('Success'));
            //System.assertEquals('Success', mapSaveResultEdit.get('Success'));
            System.assertEquals('Success', mapSaveResultCopy.get('Success'));
        }
    }

    @IsTest
    public static void testGetProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstProgram =  LWC01_NewSection.getProgram(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(lstProgram[0].Nature__c, '23002');
        }
    }

    @IsTest
    public static void testGetSectionNumber(){
        System.runAs(testUserCE) {
            Test.startTest();
                Section__c section = [SELECT Id, SectionNumber__c, Treaty__c FROM Section__c ORDER BY SectionNumber__c DESC LIMIT 1];
                Decimal sectionNum = Decimal.valueOf(section.SectionNumber__c) + 1.0;
                String sectionNumber =  LWC01_NewSection.getSectionNumber(section.Treaty__c);
                System.assertEquals(String.valueOf(sectionNum), sectionNumber);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetCoveredCedingCompanies(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<CoveredCedingCompany__c> lstCovCedCom =  LWC01_NewSection.getCoveredCedingCompaniesByTreatyId(String.valueOf(lstProgram[0].Id), String.valueOf(lstTreaty[0].Id));
            Test.stopTest();
            System.assertEquals(1, lstCovCedCom.size());
        }
    }

    @IsTest
    public static void testGetReinstatements(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Reinstatement__c> lstReinstatements =  LWC01_NewSection.getReinstatements(lstSection[2].Id);
            Test.stopTest();
            System.assertEquals(2, lstReinstatements.size());
        }
    }

    @IsTest
    public static void testGetCovCedCompBySectionId(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<CoveredCedingCompany__c> lstCovCedCom =  LWC01_NewSection.getCovCedCompBySectionId(lstSection[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstCovCedCom.size());
        }
    }

    @IsTest
    public static void testGetOptionSectionNumber(){
        System.runAs(testUserCE) {
            Test.startTest();
                String optionSectionNum =  LWC01_NewSection.getOptionSectionNumber(lstSection[0].Id, '4.1');
            Test.stopTest();
            System.assertEquals('4.2', optionSectionNum);
        }
    }

    @IsTest
    public static void testGetProgramDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Program__c program =  LWC01_NewSection.getProgramDetails(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals('2018', program.UwYear__c);
        }
    }

    @IsTest
    public static void testGetSectionDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Section__c section =  LWC01_NewSection.getSectionDetails(lstSection[0].Id);
            Test.stopTest();
            System.assertEquals('2018', section.Program__r.UwYear__c);
        }
    }

    @IsTest
    public static void testGetTreatyDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Treaty__c treaty =  LWC01_NewSection.getTreatyDetails(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals('2018', treaty.Program__r.UwYear__c);
        }
    }

    @IsTest
    public static void testGetPoolsTreatyDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<PoolTreatySection__c> lstPoolTreatySections =  LWC01_NewSection.getPoolsTreatyDetails(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(2, lstPoolTreatySections.size());
        }
    }

    @IsTest
    public static void testGetPoolsSectionDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<PoolTreatySection__c> lstPoolTreatySections =  LWC01_NewSection.getPoolsSectionDetails(lstSection[4].Id);
            Test.stopTest();
            System.assertEquals(1, lstPoolTreatySections.size());
        }
    }

    @IsTest
    public static void testCheckIfQuoteRequestPresent(){
        System.runAs(testUserCE) {
            Test.startTest();
            Boolean result = LWC01_NewSection.checkIfQuoteRequestPresent(lstProgram[0].Id, lstSection[0].Id);
            Boolean result2 = LWC01_NewSection.checkIfQuoteRequestPresent(lstProgram[2].Id, lstSection[4].Id);
            Test.stopTest();
            System.assertEquals(true, result);
            System.assertEquals(false, result2);
        }
    }
   
    @IsTest
    public static void testDisableQuoteTypeForRenewProg(){
        System.runAs(testUserCE) {
            Test.startTest();
            Boolean result = LWC01_NewSection.disableQuoteTypeForRenewProg(lstTreaty[0].Id);
            Boolean result2 = LWC01_NewSection.disableQuoteTypeForRenewProg(lstTreaty[1].Id);
            Test.stopTest();
            System.assertEquals(true, result);
            System.assertEquals(false, result2);
        }
    }

    @IsTest
    public static void testGetAllSectionOption(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResult = LWC01_NewSection.getAllSectionOption(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals('Success', mapResult.get('Success'));
        }
    }
}