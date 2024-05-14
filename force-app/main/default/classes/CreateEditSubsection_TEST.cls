/**************************************************************************************
-- - Author        : Telesio DEV (RRA)
-- - Description   : Test class for CreateEditSubsection - Project NEREE
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 22-SEPT-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
@IsTest
public with sharing class CreateEditSubsection_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Section__c> lstSection;
    static List<Subsection__c> lstSubSectionNew;
    static List<Subsection__c> lstSubSectionUpdated;
    static List<ReferentialHazardBassin__c> lstHB;
    static List<PortfolioSubsection__c> lstPSSubHB;
    static List<PortfolioSubsection__c> lstPSSubPS;
    static List<PortfolioSegment__c> lstPS;
    static List<Reinstatement__c> lstReinsNew;
    static List<Reinstatement__c> lstReinsNewUpdated1;
    static List<Reinstatement__c> lstReinsNewUpdated2;
    static List<Reinstatement__c> lstReinsisEmpty = null;
    static List<Reinstatement__c> lstReinsOld1;
    static List<Reinstatement__c> lstReinsOld2;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
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

            lstSubSectionNew = new List<Subsection__c>{
                new Subsection__c(
                    AAL__c = lstSection[0].AAL__c,
                    AAD__c = lstSection[0].AAD__c,
                    Deductible__c = lstSection[0].Deductible__c,
                    Limit__c = lstSection[0].Limit__c,
                    LimitType__c = lstSection[0].LimitType__c,
                    Unlimited__c = lstSection[0].Unlimited__c,
                    Section__c = lstSection[0].Id
                )
            };
            insert lstSubSectionNew; 

            lstSubSectionNew[0].AAL__c = 20;
            lstSubSectionNew[0].AAD__c = 36;
            lstSubSectionNew[0].Section__c = lstSection[0].Id;
            //lstSubSectionUpdated.add(lstSubSectionNew[0]);
           

            lstHB = new List<ReferentialHazardBassin__c>{
                new ReferentialHazardBassin__c(
                    CodeRegion__c = 'CHE',
                    CodeRegion2Characters__c = 'CH',
                    HazardCode__c = null,
                    Id__c = 1,
                    Peril__c = 'Euro Atlantic High-Frequency Cyclone',
                    Type__c = 'WS'
                )
            };
            insert lstHB;

            lstPSSubHB = new List<PortfolioSubsection__c>{
                new PortfolioSubsection__c(
                    SubSection__c = lstSubSectionNew[0].Id, 
                    Referential_Hazard_Bassin__c = lstHB[0].Id
                )
            };
            insert lstPSSubHB;

            lstPS = new List<PortfolioSegment__c>{
                new PortfolioSegment__c(
                    IsoCode__c = 'BE',
                    PortfolioSegment__c = 'AGRICULTURAL - AXA CORPORATE - SIMPLE RISKS - COMMERCIAL_PROPERTY',
                    Id__c = 21
                )
            };
            insert lstPS;

            lstPSSubPS = new List<PortfolioSubsection__c>{
                new PortfolioSubsection__c(
                    SubSection__c = lstSubSectionNew[0].Id, 
                    PortfolioSegment__c = lstPS[0].Id
                )
            };
            insert lstPSSubPS;

            lstReinsNew = new List<Reinstatement__c>{
                new Reinstatement__c(
                    Id = null,
                    Free__c = false,
                    Key_Insert_Update_Reinstatement__c = lstSection[0].Id + '_' + lstSubSectionNew[0].Id + '_' + '1',
                    Order__c = 2,
                    Percentage__c = 10,
                    Prorata__c = '1',
                    Type__c = '3',
                    Section__c = lstSection[0].Id,
                    Sub_Section__c = lstSubSectionNew[0].Id,
                    TECH_SectionSubSection__c ='SubSection'
                ),

                new Reinstatement__c(
                    Id = null,
                    Free__c = true,
                    Key_Insert_Update_Reinstatement__c = lstSection[0].Id + '_' + lstSubSectionNew[0].Id + '_' + '1',
                    Type__c = '1',
                    Section__c = lstSection[0].Id,
                    Sub_Section__c = lstSubSectionNew[0].Id,
                    TECH_SectionSubSection__c ='SubSection'
                ),

                new Reinstatement__c(
                    Id = null,
                    Free__c = false,
                    Key_Insert_Update_Reinstatement__c = lstSection[0].Id + '_' + lstSubSectionNew[0].Id + '_' + '1',
                    Type__c = '2',
                    Section__c = lstSection[0].Id,
                    Sub_Section__c = lstSubSectionNew[0].Id,
                    TECH_SectionSubSection__c ='SubSection'
                )
            };
            insert lstReinsNew;
            lstReinsNew[0].Type__c = '2';
            lstReinsNew[0].TECH_ExistingReinstatementOnSection__c = true;
            //lstReinsNewUpdated1.add(lstReinsNew[0]);
            lstReinsNew[0].Sub_Section__c = null;
           

            lstReinsNew[1].Type__c = '2';
            lstReinsNew[1].TECH_ExistingReinstatementOnSection__c = false;
            //lstReinsNewUpdated2.add(lstReinsNew[0]);
            lstReinsNew[1].Sub_Section__c = lstSubSectionNew[0].Id;
            update lstReinsNew;
        }
    }

    @IsTest
    public static void testcreateEditSub_SubSecIdNull(){
        System.runAs(testUserCE) {
            CreateEditSubsection.ObjectContext obj = new CreateEditSubsection.ObjectContext ();
            obj.subsection =  new SubSection__c();
            obj.subsectionNewRecord = lstSubSectionNew[0];
            obj.sectionId =  lstSection[0].Id;
            obj.HBs =  lstHB;
            obj.PSegs =  lstPS;
            obj.Reinst = lstReinsNew;

            Test.startTest();
            List<CreateEditSubsection.Result> results = CreateEditSubsection.createEditSub(new List<CreateEditSubsection.ObjectContext> {obj});
            System.assertEquals(true, results[0].isSuccess);
            System.assert(results[0].subsection != null);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testcreateEditSub_SubSecIdNotNull(){
        System.runAs(testUserCE) {

            update lstSubSectionNew[0];

            CreateEditSubsection.ObjectContext obj = new CreateEditSubsection.ObjectContext ();
            obj.subsection =  lstSubSectionNew[0];
            obj.sectionId =  lstSection[0].Id;
            obj.HBs =  lstHB;
            obj.PSegs =  lstPS;
            obj.Reinst = lstReinsNew;

            
            Test.startTest();
            List<CreateEditSubsection.Result> results = CreateEditSubsection.createEditSub(new List<CreateEditSubsection.ObjectContext> {obj});
            //System.assertEquals(true, results[0].isSuccess);
            //System.assert(results[0].subsection != null);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testcreateEditSub_reinsIdNull(){
        System.runAs(testUserCE) {
            update lstReinsNew[0];

            CreateEditSubsection.ObjectContext obj = new CreateEditSubsection.ObjectContext ();
            obj.subsection =  lstSubSectionNew[0];
            obj.subsectionNewRecord = lstSubSectionNew[0];
            obj.sectionId =  lstSection[0].Id;
            obj.HBs =  lstHB;
            obj.PSegs =  lstPS;
            obj.Reinst = new List<Reinstatement__c> ();

            Test.startTest();
            List<CreateEditSubsection.Result> results = CreateEditSubsection.createEditSub(new List<CreateEditSubsection.ObjectContext> {obj});
            System.assertEquals(true, results[0].isSuccess);
            System.assert(results[0].subsection != null);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testcreateEditSub_reinsIdNotNullAndSubSecNull(){
        System.runAs(testUserCE) {

            update lstReinsNew[1];

            CreateEditSubsection.ObjectContext obj = new CreateEditSubsection.ObjectContext ();
            obj.subsection =  lstSubSectionNew[0];
            obj.sectionId =  lstSection[0].Id;
            obj.HBs =  lstHB;
            obj.PSegs =  lstPS;
            obj.Reinst = lstReinsNew;
            Test.startTest();
            List<CreateEditSubsection.Result> results = CreateEditSubsection.createEditSub(new List<CreateEditSubsection.ObjectContext> {obj});
            /*System.assertEquals(true, results[0].isSuccess);
            System.assert(results[0].subsection != null);*/
            Test.stopTest();
        }
    }

    @IsTest
    public static void testcreateEditSub_reinsIdNotNullAndSubSecNotNull(){
        System.runAs(testUserCE) {
            CreateEditSubsection.ObjectContext obj = new CreateEditSubsection.ObjectContext ();
            obj.subsection =  lstSubSectionNew[0];
            obj.sectionId =  lstSection[0].Id;
            obj.HBs =  lstHB;
            obj.PSegs =  lstPS;
            obj.Reinst = lstReinsNewUpdated2;
            Test.startTest();
            List<CreateEditSubsection.Result> results = CreateEditSubsection.createEditSub(new List<CreateEditSubsection.ObjectContext> {obj});
            /*System.assertEquals(true, results[0].isSuccess);
            System.assert(results[0].subsection != null);*/
            Test.stopTest();
        }
    }

    @IsTest
    public static void testcreateEditSub_lstReinsNull(){
        System.runAs(testUserCE) {
            lstReinsNew = new List <Reinstatement__c>();
            update lstReinsNew;
            CreateEditSubsection.ObjectContext obj = new CreateEditSubsection.ObjectContext ();
            obj.subsection =  lstSubSectionNew[0];
            obj.sectionId =  lstSection[0].Id;
            obj.HBs =  lstHB;
            obj.PSegs =  lstPS;
            obj.Reinst = lstReinsNew;
            Test.startTest();
            List<CreateEditSubsection.Result> results = CreateEditSubsection.createEditSub(new List<CreateEditSubsection.ObjectContext> {obj});
            /*System.assertEquals(true, results[0].isSuccess);
            System.assert(results[0].subsection != null);*/
            Test.stopTest();
        }
    }




    @IsTest
    public static void testdeleteJunctionsHBassins(){
        System.runAs(testUserCE) {
            Test.startTest();
            CreateEditSubsection.deleteJunctionsHBassins(lstPSSubHB[0].Id);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testdeleteJunctionsPSegments(){
        System.runAs(testUserCE) {
            Test.startTest();
            CreateEditSubsection.deleteJunctionsPSegments(lstPSSubPS[0].Id);
            Test.stopTest();
        }
    }

}