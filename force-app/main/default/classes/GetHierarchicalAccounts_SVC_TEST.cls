@IsTest
public with sharing class GetHierarchicalAccounts_SVC_TEST {
    static User testUserAdmin;
    static List<Account> lstAccount;
    static Account reins ;

    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        insert testUserAdmin ;

        System.runAs(testUserAdmin){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                AP_Constant.sObjectAcc
            });
            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCompanyGroup),'Parent Ultimate','RGC_0001'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCompanyGroup),'Parent Company','RG_0002')
            };
            insert lstAccount;
            lstAccount[1].AccountUltimateParent__c = lstAccount[0].Id ;
            lstAccount[1].ParentId = lstAccount[0].Id ;

            update lstAccount ; 

            reins = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Reins','C_0006') ; 
            reins.AccountUltimateParent__c = lstAccount[0].Id ;
            reins.ParentId = lstAccount[1].Id ;
            insert reins; 
        }
    }

    @IsTest
    public static void getDataUltimate_TEST(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            GetHierarchicalAccounts_SVC cls = new GetHierarchicalAccounts_SVC() ;
            Map<Object, Object> mapName = new Map<Object, Object>();
            mapName.put('CurrID',lstAccount[0].Id) ;
            cls.getData(mapName,'') ;
            Test.stopTest();
        }
    }

    @IsTest
    public static void getDataParent_TEST(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            GetHierarchicalAccounts_SVC cls = new GetHierarchicalAccounts_SVC() ;
            Map<Object, Object> mapName = new Map<Object, Object>();
            mapName.put('CurrID',lstAccount[1].Id) ;
            cls.getData(mapName,'') ;
            Test.stopTest();
        }
    }

    @IsTest
    public static void getDataReinsurer_TEST(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            GetHierarchicalAccounts_SVC cls = new GetHierarchicalAccounts_SVC() ;
            Map<Object, Object> mapName = new Map<Object, Object>();
            mapName.put('CurrID',reins.Id) ;
            cls.getData(mapName,'') ;
            Test.stopTest();
        }
    }

}