@IsTest
public with sharing class BAT004_RemiQuoteValidity_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequest;
    static List<Section__c> lstSection;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static List<User> lstUsers = new List<User>();
    
    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserAdmin){
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

             //Create EmailTemplate
             EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = 'AGRE BATCH- Quote Reminder email 2 days before Quote Validity'); // plus any other fields that you want to set 
             insert e;
            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A','C_0007'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B','C_0008'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A','C_0009')
            };
            insert lstAccount;
            lstAccount[0].EmailPCLife__c = 'test@gmail.com';
            update lstAccount;

            //create Program
            lstProgram = new List<Program__c> {
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[0].Id, '23002','2'
                            , '25009'),

                    TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                            , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                            , lstAccount[0].Id, '23001', '2', '25001')
            };
            insert lstProgram;

            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TECH_ShowClosePreviousPhaseBtn__c =  '1';
            lstProgram[1].TypeOfRenew__c = 'LTA/TR Identical Renew';
            update lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000221', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000223', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                            , true, '5', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                            , false, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;


            //create Request
            lstRequest = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '5',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[1].Id)
            };

            lstRequest[0].Quote__c = '1';
            lstRequest[0].VersionMinor__c = 1;
            lstRequest[0].ProfitCommission__c = 10;
            lstRequest[0].fixedCommission__c = 11;
            lstRequest[0].QuoteDeadline__c = Date.today() + 2;
            lstRequest[0].FixedRate__c = 12;
            lstRequest[0].MinRate__c = 13;
            lstRequest[0].MaxRate__c = 14;
            lstRequest[0].ProvisionalRate__c = 15;
            lstRequest[0].FlatPremium__c = 16;
            lstRequest[0].MDP__c = 17;
            lstRequest[0].MinVarCommission__c = 18;
            lstRequest[0].MaxVarCommission__c = 19;
            lstRequest[0].ProvisionalCommission__c = 20;
            lstRequest[0].PerHeadPremium__c = 21;
            lstRequest[0].MinPerHeadAmount__c = 22;
            lstRequest[0].MaxPerHeadAmount__c = 23;
            lstRequest[0].ProvisionalPerHeadPremium__c = 24;
            lstRequest[0].EstimatedReinsurancePremium__c = 25;
            lstRequest[0].isChk2DaysEmailReminder__c = true;
            lstRequest[0].ReinsurerStatus__c = 'Sent';
            lstRequest[0].LastVersionSent__c = true;
            lstRequest[0].LastVersionAnswered__c = true;

            lstRequest[1].Quote__c = '2';
            lstRequest[1].VersionMinor__c = 1;
            lstRequest[1].ProfitCommission__c = 10;
            lstRequest[1].fixedCommission__c = 11;
            lstRequest[1].QuoteDeadline__c = Date.today() + 2;
            lstRequest[1].FixedRate__c = 12;
            lstRequest[1].MinRate__c = 13;
            lstRequest[1].MaxRate__c = 14;
            lstRequest[1].ProvisionalRate__c = 15;
            lstRequest[1].FlatPremium__c = 16;
            lstRequest[1].MDP__c = 17;
            lstRequest[1].isChk2DaysEmailReminder__c = true;
            lstRequest[1].MinVarCommission__c = 18;
            lstRequest[1].MaxVarCommission__c = 19;
            lstRequest[1].ProvisionalCommission__c = 20;
            lstRequest[1].PerHeadPremium__c = 21;
            lstRequest[1].MinPerHeadAmount__c = 22;
            lstRequest[1].MaxPerHeadAmount__c = 23;
            lstRequest[1].ProvisionalPerHeadPremium__c = 24;
            lstRequest[1].EstimatedReinsurancePremium__c = 25;
            lstRequest[1].EstimatedInsurancePremium__c = 26;
            lstRequest[1].LastVersionSent__c = true;
            lstRequest[1].LastVersionAnswered__c = true;
            lstRequest[1].ReinsurerStatus__c = 'Sent';


            lstRequest[2].Quote__c = '1';
            lstRequest[2].VersionMinor__c = 2;
            lstRequest[2].ProfitCommission__c = 10;
            lstRequest[2].fixedCommission__c = 11;
            lstRequest[2].FixedRate__c = 12;
            lstRequest[2].QuoteDeadline__c = Date.today() + 2;
            lstRequest[2].MaxRate__c = 14;
            lstRequest[2].ProvisionalRate__c = 15;
            lstRequest[2].FlatPremium__c = 16;
            lstRequest[2].MDP__c = 17;
            lstRequest[2].MinVarCommission__c = 18;
            lstRequest[2].MaxVarCommission__c = 19;
            lstRequest[2].ProvisionalCommission__c = 20;
            lstRequest[2].PerHeadPremium__c = 21;
            lstRequest[2].MinPerHeadAmount__c = 22;
            lstRequest[2].MaxPerHeadAmount__c = 23;
            lstRequest[2].ProvisionalPerHeadPremium__c = 24;
            lstRequest[2].EstimatedReinsurancePremium__c = 25;
            lstRequest[2].EstimatedInsurancePremium__c = 26; 
            lstRequest[2].LastVersionSent__c = true;
            lstRequest[2].LastVersionAnswered__c = true;
            lstRequest[2].ReinsurerStatus__c = 'Sent';
            insert lstRequest;

        }
    }
    
    @IsTest
    public static void testSendEmailQuoteReminder(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Database.executeBatch(new BAT004_ReminderQuoteValidity()); 
            Test.stopTest();
        }
    }

}