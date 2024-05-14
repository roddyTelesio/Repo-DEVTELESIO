@IsTest
public with sharing class getListHazardBassinsFiltered_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Account> lstAccount;
    static List<User> lstUsers = new List<User>();
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<ReferentialHazardBassin__c> lstRHBa = new List<ReferentialHazardBassin__c>();

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
            System.debug('### MRA 0= ' + mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany)) ;

            lstAccount = new List<Account> {
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account A','C_0001'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account B','C_0002'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account PCC','C_0003')

            };
            lstAccount[0].Name = 'AGD FRANCE DA + NATIO /FR (C)' ;
            lstAccount[1].Name = 'All' ;

            insert lstAccount;
            System.debug('### MRA 1= ' + [SELECT id,RecordTypeId,RecordType.Name FROM Account WHERE Id =:lstAccount[0].Id ].RecordType.Name) ;
            System.debug('### MRA 1= ' + [SELECT id,RecordTypeId,RecordType.Name FROM Account WHERE Id =:lstAccount[1].Id ].RecordType.Name) ;
            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                        , '2018', lstAccount[2].Id, '23002','2'
                                        , '25009')
            };
            insert lstProgram;
            
            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2')

            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2'),
                TestFactory.createSection('TestSection2', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

            //create Covered Ceding Company
            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[0].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null),
                TestFactory.createCovCedCom(lstAccount[1].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null)
            };
            lstCovCedCom[0].Section__c = lstSection[0].Id ;
            lstCovCedCom[1].Section__c = lstSection[1].Id ;
            insert lstCovCedCom;

            lstRHBa = new List<ReferentialHazardBassin__c>{
                TestFactory.createRHBa('FRA','FR','',66,'Canada Ground-Shaking','GS'),
                TestFactory.createRHBa('MEX','MX','',78,'Mexico Ground-Shaking','GS'),
                TestFactory.createRHBa('DEU','DE','',81,'Republic of Korea Ground-Shaking','GS')
            } ;

            insert lstRHBa ;
            
    } 
}

    @IsTest
    public static void test_getHBAllFiltered_FR(){
        System.runAs(testUserCE) {
            getListHazardBassinsFiltered.ObjectContext obj= new getListHazardBassinsFiltered.ObjectContext() ;
            obj.recordId = lstSection[0].Id ; 
            List<getListHazardBassinsFiltered.ObjectContext> lstObj= new List<getListHazardBassinsFiltered.ObjectContext>{obj} ;
            Test.startTest();
            List<Object> lstResult = getListHazardBassinsFiltered.getHBAllFiltered(lstObj);
            Test.stopTest();
            System.assertEquals(lstResult.size(),1);
        }
    }

    @IsTest
    public static void test_getHBAllFiltered_All(){
        System.runAs(testUserCE) {
            getListHazardBassinsFiltered.ObjectContext obj= new getListHazardBassinsFiltered.ObjectContext() ;
            obj.recordId = lstSection[1].Id ; 
            List<getListHazardBassinsFiltered.ObjectContext> lstObj= new List<getListHazardBassinsFiltered.ObjectContext>{obj} ;
            Test.startTest();
            List<Object> lstResult = getListHazardBassinsFiltered.getHBAllFiltered(lstObj);
            Test.stopTest();
            System.assertEquals(lstResult.size(),1);
        }
    }


}