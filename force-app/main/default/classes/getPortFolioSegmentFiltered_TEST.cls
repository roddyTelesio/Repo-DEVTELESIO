/**************************************************************************************
-- - Author        : Telesio DEV (RRA)
-- - Description   : Test class for getPortFolioSegmentFiltered - Project NEREE
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 22-SEPT-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
@IsTest
public with sharing class getPortFolioSegmentFiltered_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Section__c> lstSection;
    static List<PortfolioSegment__c> lstPS;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Section__c> lstRelatedSection;
    static List<User> lstUsers = new List<User>();
    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests;AP42_DeleteDocumentVisibility';
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
             //create Account
             lstAccount = new List<Account> {
                /*TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'AXA BELGIUM /BE (C)','C_0003'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'ALL','C_0004'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account E','C_0005') //*/

                new Account(
                        RecordTypeId= mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),
                        Name = 'Account A',
                        TECH_ReferentialId__c = 'C_0001',
                        IsActive__c = true
                    ),
                new Account(
                    RecordTypeId= mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),
                    Name = 'Account B',
                    TECH_ReferentialId__c = 'C_0002',
                    IsActive__c = true
                ),

                new Account(
                    RecordTypeId= mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),
                    Name = 'AXA BELGIUM /BE (C)',
                    TECH_ReferentialId__c = 'C_0003',
                    IsActive__c = true
                ),

                new Account(
                    RecordTypeId= mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),
                    Name = 'ALL',
                    TECH_ReferentialId__c = 'C_0004',
                    IsActive__c = true
                ),

                new Account(
                    RecordTypeId= mapRecTypeId.get(AP_Constant.accRTReinsurer),
                    Name = 'Account E',
                    TECH_ReferentialId__c = 'C_0005',
                    IsActive__c = true
                )
            };
            insert lstAccount;

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

            lstSection = new List<Section__c>{
                new Section__c(
                    AAL__c = 12,
                    AAD__c = 15,
                    Deductible__c = 25,
                    Limit__c = 56,
                    LimitType__c = '1',
                    Unlimited__c = false,
                    Name = 'TestSection1',
                    SectionNumber__c = '1.1',
                    LoB__c = '22003',
                    Currency__c = '9052',
                    Retention__c = 322,
                    Program__c = lstProgram[0].Id,
                    Treaty__c = lstTreaty[0].Id,
                    TECH_TypeofTreaty__c = '3',
                    Status__c = '1',
                    Retained_to_lead__c = true,
                    QuoteType__c = '5',
                    RelatedSection__c = null,
                    SubLoB__c = '20091',
                    TECH_NatureProgram__c = '23001',
                    NonTraditionalReinsuranceAndOrFinit__c = '2',
                    Nature__c = '1',
                    InclusionOfCatastrophicGuarantees__c = '1',
                    ExclusionOfCatastrophicGuarantees__c = '1'
                )
            };
            insert lstSection; 

            lstPS = new List<PortfolioSegment__c>{
                new PortfolioSegment__c(
                    IsoCode__c = 'BE',
                    PortfolioSegment__c = 'AGRICULTURAL - AXA CORPORATE - SIMPLE RISKS - COMMERCIAL_PROPERTY',
                    Id__c = 21
                )
            };
            insert lstPS;
        }
    }

    @IsTest
    public static void testgetPSAllFiltered_NoCodeRegion_All(){
        System.runAs(testUserCE) {

            //create Covered Ceding Company
            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                ,true,lstSection[0].Id,false,null,null),
            TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, false, lstTreaty[2].Id
                ,true,lstSection[0].Id,false,null,null),
            TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                ,false, lstSection[0].Id,true,null,null)
            };
            
            insert lstCovCedCom;

            System.debug('lstCovCedCom: ' + lstCovCedCom);
            
            getPortFolioSegmentFiltered.ObjectContext obj = new getPortFolioSegmentFiltered.ObjectContext ();
            obj.recordId =  lstSection[0].Id;

            Test.startTest();
            List<getPortFolioSegmentFiltered.Result> results = getPortFolioSegmentFiltered.getPSAllFiltered(new List<getPortFolioSegmentFiltered.ObjectContext> {obj});
            Test.stopTest();
        }
    }

    @IsTest
    public static void testgetPSAllFiltered_WithCodeRegion_Existing(){
        System.runAs(testUserCE) {

            //create Covered Ceding Company
            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                            ,false,lstSection[0].Id,false,null,null),
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                            ,false,lstSection[0].Id,false,null,null),
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[1].Id
                                            ,true,lstSection[0].Id,false,null,null)
            };
            insert lstCovCedCom;

            getPortFolioSegmentFiltered.ObjectContext obj = new getPortFolioSegmentFiltered.ObjectContext ();
            obj.recordId =  lstSection[0].Id;

            Test.startTest();
            List<getPortFolioSegmentFiltered.Result> results = getPortFolioSegmentFiltered.getPSAllFiltered(new List<getPortFolioSegmentFiltered.ObjectContext> {obj});
            Test.stopTest();
        }
    }
}