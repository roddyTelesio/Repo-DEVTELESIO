@IsTest
public with sharing class LWC18_SendEmailForLead_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC18_SendEmailForLead
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 08-NOV-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

   static User testUserAdmin;
   static User testUserCE;
   static User testUserCEWithContact;
   static List<CoveredCedingCompany__c> lstCovCedCom;
   public static List<Account> lstAccount;
   static List<Program__c> lstProgram;
   static List<Treaty__c> lstTreaty;
   static List<Request__c> lstRequest;
   static List<Section__c> lstSection;
   static List<Contact> lstContact;
   static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
   static List<User> lstUsers = new List<User>();
   static List<User> lstUsers2 = new List<User>();
   static List<Request__c> lstLeadRequests;
   static List<ContentVersion> lstContentVersion;
   static List<ContentDocumentLink> lstContentDocumentLink;
   static String fileContent = 'This is an example.';
   static Blob fileContentInBlob = Blob.valueOf(fileContent);
   public static List<AccountContactRelation> lstAccContactRelation;
   static List<Pool__c> lstPool;
   static List<PoolTreatySection__c> lstPoolTreatySections;
   static List<DocumentVisibility__c> lstDocumentVisibility;

    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        //testUserCEWithContact = TestFactory.createUserWithContact('testUserCEWithContact');
        lstUsers.add(testUserAdmin);
        lstUsers.add(assignedToUser);
        lstUsers.add(testUserCE);
        //lstUsers.add(testUserCEWithContact);
        insert lstUsers;

         
        System.runAs(testUserCE){
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
 
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

            lstAccount[0].EmailPCLife__c = 'test1@gmail.com;test2@gmail.com';
            lstAccount[1].EmailPCLife__c = 'test1@gmail.com;test2@gmail.com';
            insert lstAccount;
 

            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                        , '2018', lstAccount[0].Id, '23002','3'
                                        , '25009'),
    
                TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                        , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                                        , lstAccount[1].Id, '23002', '3', '25009'),
    
                TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                        , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                        , lstAccount[1].Id, '23002', '3', '25009')
            };

            lstProgram[0].TECH_StageName__c = 'Quote';
            insert lstProgram;

            //Create pools
            lstPool = new List<Pool__c>{
                TestFactory.createPool('Pool A', 78, '2018', lstUsers[1].Id),
                TestFactory.createPool('Pool B', 78, '2018', lstUsers[1].Id)
            };
            insert lstPool;


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

                TestFactory.createSection('TestSection2', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[1].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection3', '2.1', '22003', '20006', '9052'
                                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;
     
           //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, null
                                            , false,true, 32, null),

                TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[1].Id, lstSection[1].Id
                                            , true,false, null, 32)
            };
            insert lstPoolTreatySections;

            //create Request
            lstRequest = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),
    
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                                             mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),
    
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),
                                            
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent',lstSection[1].Id),
               
                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, lstAccount[5].Id, '1', '5',
                                             mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[0].Id),
 
                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[7].Id, lstAccount[8].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),
                
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent',lstSection[0].Id)
            };

            insert lstRequest;

            lstRequest[2].OriginalRequest__c = lstRequest[0].Id;
            lstRequest[3].OriginalRequest__c = lstRequest[1].Id;
            lstRequest[6].Pool__c = lstPool[0].Id;
            lstRequest[8].Pool__c = lstPool[1].Id;
            lstRequest[8].SignedShare__c = 0;

            lstRequest[0].Program__r = lstProgram[0];
            lstRequest[1].Program__r = lstProgram[0];
            lstRequest[2].Program__r = lstProgram[1];
            lstRequest[3].Program__r = lstProgram[1];
            lstRequest[4].Program__r = lstProgram[1];
            lstRequest[5].Program__r = lstProgram[1];
            lstRequest[6].Program__r = lstProgram[0];
            lstRequest[6].Pool__r = lstPool[0];
            lstRequest[7].Program__r = lstProgram[0];
            lstRequest[8].Program__r = lstProgram[0];
            lstRequest[8].Pool__r = lstPool[1];

            lstRequest[9].Program__r = lstProgram[0];
            lstRequest[10].Program__r = lstProgram[0];
            lstRequest[10].OriginalRequest__c = lstRequest[9].Id;

            lstRequest[11].Program__r = lstProgram[0];
            lstRequest[12].Program__r = lstProgram[0];
            lstRequest[12].OriginalRequest__c = lstRequest[11].Id;

            lstRequest[13].Program__r = lstProgram[0];
            lstRequest[14].Program__r = lstProgram[0];
            lstRequest[14].OriginalRequest__c = lstRequest[13].Id;

            lstRequest[15].Program__r = lstProgram[0];
            lstRequest[16].Program__r = lstProgram[0];

            for(Request__c req : lstRequest){
                req.LastVersionSent__c = true;
                req.LastVersionAnswered__c = true;
            }

            update lstRequest;
 
            //create lead 
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[0].Id),
    
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[0].Id),
                
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[0].Id),
    
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, null, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[0].Id)
            };


            lstLeadRequests[0].Program__r = lstProgram[0];
            lstLeadRequests[1].Program__r = lstProgram[0];
            lstLeadRequests[0].LastVersionSent__c = true;
            lstLeadRequests[1].LastVersionSent__c = true;
            lstLeadRequests[0].LastVersionAnswered__c = true;
            lstLeadRequests[1].LastVersionAnswered__c = true;

            lstLeadRequests[0].OriginalRequest__c = lstLeadRequests[2].Id;
            lstLeadRequests[1].OriginalRequest__c = lstLeadRequests[3].Id;
            update lstLeadRequests;

            List<Request__c> lstAllLeadRequest = [SELECT Id, LastVersionAnswered__c, LastVersionSent__c, ReinsurerStatus__c FROM Request__c WHERE RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTLead) AND Program__c = :lstProgram[0].Id];

            for(Request__c leadReq : lstAllLeadRequest){
                leadReq.LastVersionSent__c = true;
                leadReq.LastVersionAnswered__c = true;
                leadReq.ReinsurerStatus__c = 'Sent';
            }

            update lstAllLeadRequest;

            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                TestFactory.createContentVersion('2','1'
                                                , '5', 'CV1', fileContentInBlob, 'CV1'),
                TestFactory.createContentVersion('2','1'
                                                , '5', 'CV2', fileContentInBlob, 'CV2'),
                TestFactory.createContentVersion('2','1'
                                                , '5', 'CV3', fileContentInBlob, 'CV3'),
                TestFactory.createContentVersion('1','1'
                                                , '5', 'CV4', fileContentInBlob, 'CV4'),
                TestFactory.createContentVersion('1','1'
                                                , '5', 'CV5', fileContentInBlob, 'CV5'),
                TestFactory.createContentVersion('1','1'
                                                , '5', 'CV6', fileContentInBlob, 'CV6')
            };

            lstContentVersion[0].DocumentID__c = '00001';
            lstContentVersion[1].DocumentID__c = '00001';
            lstContentVersion[2].DocumentID__c = '00002';
            lstContentVersion[3].DocumentID__c = '00002';
            lstContentVersion[0].FromThemis__c = true;
            lstContentVersion[1].FromThemis__c = true;
            lstContentVersion[2].FromThemis__c = true;
            lstContentVersion[3].FromThemis__c = true;
            insert lstContentVersion;

            List<Id> lstContentVersionId = new List<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :lstContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[3].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[1].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[4].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[5].ContentDocumentId, lstProgram[0].Id, 'V')
            };
            insert lstContentDocumentLink;

            //Create contact
            lstContact = new List<Contact>{
                TestFactory.createContact('Test', 'TestName', lstAccount[4].Id, '2', '25010;25009'),
                TestFactory.createContact('Jean', 'Ballack', lstAccount[5].Id, '3', '25010;25009'),
                TestFactory.createContact('Test3', 'TestName3', lstAccount[8].Id, '3', '25010;25009'),
                TestFactory.createContact('Test3', 'TestName4', lstAccount[7].Id, '3', '25010;25009')
            };

            lstContact[0].Email = 'Test@gmail.com';
            lstContact[1].Email = 'Jean@test.com';
            lstContact[2].Email = 'Test3@gmail.com';
            lstContact[3].Email = 'Test3@gmail.com';
            insert lstContact;

            //testUserCE.ContactId = lstContact[0].Id;
            //update testUserCE;

            //create AccountContactRelation
            lstAccContactRelation = new List<AccountContactRelation>{
                TestFactory.createAccountContactRelation(lstAccount[0].Id, lstContact[0].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[0].Id, lstContact[1].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[0].Id, lstContact[2].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[0].Id, lstContact[3].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[1].Id, lstContact[0].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[1].Id, lstContact[1].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[1].Id, lstContact[2].Id, 'PrincipalCedingCompany', true),
                TestFactory.createAccountContactRelation(lstAccount[1].Id, lstContact[3].Id, 'PrincipalCedingCompany', true)
            };
            insert lstAccContactRelation; 

            lstAccContactRelation = [SELECT Id, AccountId, Account.RecordTypeId
                                        , Contact.Account.RecordTypeId, Roles
                                        , ContactId, Contact.MacroLoB__c
                                        , Contact.Nature__c, IsDirect, Contact.Email, Contact.AccountType__c
                                     FROM AccountContactRelation];

            for(AccountContactRelation accCon : lstAccContactRelation){
                accCon.IsActive = true;

                if(accCon.AccountId == lstAccount[4].Id || accCon.AccountId == lstAccount[7].Id){
                    accCon.Roles = 'Broker';
                }
                else if(accCon.AccountId == lstAccount[5].Id){
                    accCon.Roles = 'RiskCarrier';
                }
                else if(accCon.AccountId == lstAccount[0].Id){
                    accCon.Roles = 'PrincipalCedingCompany';
                }
            }
            update lstAccContactRelation;

            //create doc visibility
            lstDocumentVisibility = new List<DocumentVisibility__c>{
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[1].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[2].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[3].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[4].Id, lstProgram[0].Id),
                // TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[5].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(null, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(null, lstAccount[5].Id,lstContentVersion[1].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(null, lstAccount[5].Id,lstContentVersion[2].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(null, lstAccount[5].Id,lstContentVersion[3].Id, lstProgram[0].Id),
                TestFactory.createDocumentVisibility(null, lstAccount[5].Id,lstContentVersion[4].Id, lstProgram[0].Id)
                // TestFactory.createDocumentVisibility(null, lstAccount[5].Id,lstContentVersion[5].Id, lstProgram[0].Id)
            };
            insert lstDocumentVisibility;

            EmailTemplate remindPool = new EmailTemplate (DeveloperName = 'remindPool', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateSignForPoolRemind); // plus any other fields that you want to set
            remindPool.body = '<html><body><b>Hello</b></body></html>';
            insert remindPool;

            EmailTemplate remind = new EmailTemplate (DeveloperName = 'remind', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateRemindReq); // plus any other fields that you want to set
            remind.body = '<html><body><b>Hello</b></body></html>';
            insert remind;

            EmailTemplate mRetainedBroker = new EmailTemplate (DeveloperName = 'RetainedBroker', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateSendRetainedBroker); // plus any other fields that you want to set
            mRetainedBroker.htmlValue = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            mRetainedBroker.body = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            insert mRetainedBroker;

            EmailTemplate mRetainedReinsurer = new EmailTemplate (DeveloperName = 'RetainedReinsurer', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateSendRetainedReinsurer); // plus any other fields that you want to set
            mRetainedReinsurer.htmlValue = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            mRetainedReinsurer.body = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            insert mRetainedReinsurer;

            EmailTemplate mNonRetainedBroker = new EmailTemplate (DeveloperName = 'NonRetainedBroker', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateSendNonRetainedBroker); // plus any other fields that you want to set
            mNonRetainedBroker.htmlValue = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            mNonRetainedBroker.body = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            insert mNonRetainedBroker;

            EmailTemplate mNonRetainedReinsurer = new EmailTemplate (DeveloperName = 'NonRetainedReinsurer', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateSendNonRetainedReinsurer); // plus any other fields that you want to set
            mNonRetainedReinsurer.htmlValue = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            mNonRetainedReinsurer.body = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            insert mNonRetainedReinsurer;

            EmailTemplate mUpdateReq = new EmailTemplate (DeveloperName = 'update', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = AP_Constant.emailTemplateUpdateReq); // plus any other fields that you want to set
            mUpdateReq.htmlValue = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            mUpdateReq.body = 'Dear Madam / Sir, We regret to advise that you have not been retained as leader on the program {{{Request__c.Program__c}}} of {{{Request__c.PrincipalCedingCompany__c}}}.{ListTreatysListReinsurers. Best regards,Your contact: {emailP_C_LIFE} Direct link to ACTOR: {InternetLink}';
            insert mUpdateReq;
        }
    }

    @IsTest
    public static void testSendUpdateLead(){
        System.runAs(testUserAdmin) {
            List<Request__c> lstReq = new List<Request__c>{lstLeadRequests[0], lstLeadRequests[1]};
            List<Id> lstReqId = new List<Id>{lstLeadRequests[0].Id, lstLeadRequests[1].Id};
            List<DocumentVisibility__c> lstDocVisibility = new List<DocumentVisibility__c>{lstDocumentVisibility[0]};

            Request__c objRequest = new Request__c();
            objRequest.Comments__c = 'Test comment';
            objRequest.ExpectedResponseDate__c = Date.today().addDays(7);

            List<DocumentVisibility__c> lstNewDocVisibilityToInsert = new List<DocumentVisibility__c>();

            DocumentVisibility__c docVis1 = new DocumentVisibility__c();
            docVis1.Broker__c = lstAccount[4].Id;
            docVis1.Reinsurer__c = lstAccount[5].Id;
            docVis1.ContentVersionId__c = lstContentVersion[5].Id;
            docVis1.Program__c = lstProgram[0].Id;
            lstNewDocVisibilityToInsert.add(docVis1);

            DocumentVisibility__c docVis2 = new DocumentVisibility__c();
            docVis2.Broker__c = null;
            docVis2.Reinsurer__c = lstAccount[5].Id;
            docVis2.ContentVersionId__c = lstContentVersion[5].Id;
            docVis2.Program__c = lstProgram[0].Id;
            lstNewDocVisibilityToInsert.add(docVis2);

            // List<ContentVersion> lstContractDoc = new List<ContentVersion>{lstContentVersion[0], lstContentVersion[1]};
            // List<ContentVersion> lstRenewDoc = new List<ContentVersion>{lstContentVersion[2]};

            List<AccountContactRelation> lstAccContact = [SELECT Id, AccountId, Contact.Email,Contact.AccountType__c FROM AccountContactRelation WHERE AccountId =: lstAccount[4].Id AND Roles =: AP_Constant.contactBroker];

            //Lead
            Test.startTest();

                for(Request__c req : lstRequest){
                    if(req.RecordTypeId == mapRecTypeIdRequest.get(AP_Constant.reqRTQuote)){
                        req.ReinsurerStatus__c = 'Answered';
                    }
                }

                update lstRequest;

                lstReqId = new List<Id> {lstLeadRequests[0].Id, lstLeadRequests[1].Id};
                // lstDocVisibility = new List<DocumentVisibility__c> { lstDocumentVisibility[2]};
                lstDocVisibility = new List<DocumentVisibility__c>();
                // lstContractDoc = new List<ContentVersion>();
                // lstRenewDoc = new List<ContentVersion>();
                List<ContentVersion> lstContractDoc = new List<ContentVersion>{lstContentVersion[0], lstContentVersion[1], lstContentVersion[5]};
                List<ContentVersion> lstRenewDoc = new List<ContentVersion>{lstContentVersion[2], lstContentVersion[5]};
                Date expectedResponseDate = Date.today().addDays(1);
                Map<String, Object> mapResultSendLead = LWC18_SendUpdateRemind.sendUpdateRequest(expectedResponseDate, lstLeadRequests, lstDocVisibility, lstReqId, objRequest, lstAccContact, lstContractDoc, lstRenewDoc, 'Send', 'Lead', false, null, null, null, lstProgram[0].Id);
                
                // lstDocVisibility = new List<DocumentVisibility__c> { lstDocumentVisibility[3]};
                Map<String, Object> mapResultUpdateLead = LWC18_SendUpdateRemind.sendUpdateRequest(expectedResponseDate,lstLeadRequests, lstNewDocVisibilityToInsert, lstReqId, objRequest, lstAccContact, lstContractDoc, lstRenewDoc, 'Update', 'Lead', false, null, null, null, lstProgram[0].Id);
            Test.stopTest();

            System.assertEquals(null, mapResultSendLead.get('Error'));
            System.assertEquals(null, mapResultUpdateLead.get('Error'));

            for(Request__c req : [SELECT Id, LastSentDate__c, TECH_LastSendUpdRemDate__c FROM Request__c WHERE Id IN :lstReqId OR OriginalRequest__c IN :lstReqId]){
                System.assertEquals(Date.today(), req.LastSentDate__c);
                System.assertEquals(Date.today(), req.TECH_LastSendUpdRemDate__c);
            }
        }
    }
}