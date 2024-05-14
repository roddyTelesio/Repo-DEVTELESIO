@isTest
private class CLM_UpdateAgreementByAGLTest {

    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
	public static Id requestRecordTypeId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Request').getRecordTypeId();
    public static Id treatyRecordTypeId  = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Treaty').getRecordTypeId();
    public static Id leaderRecordTypeId  = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Leader').getRecordTypeId();
	public static Id cccRecordTypeId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Covered Ceding Companies').getRecordTypeId();
    

    @testSetup
    static void setupTestData() {
        // Create test data here, such as an initial agreement record
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        initialAgreement.isAmended__c = true;
        initialAgreement.TECH_TriggerSyncAGL__c =true;
        insert initialAgreement;
        
        List<Apttus__AgreementLineItem__c> AgreementLineItems = new List<Apttus__AgreementLineItem__c>();
		Apttus__AgreementLineItem__c agl1 = new Apttus__AgreementLineItem__c();
        agl1.recordTypeId = treatyRecordTypeId;
        agl1.TreatyRef__c='test';
        agl1.Order__c =1;
		agl1.PlacementShare__c =70;
        agl1.LossAttachment__c='Test';
        agl1.Apttus__AgreementId__c=initialAgreement.id;

        Apttus__AgreementLineItem__c agl2 = new Apttus__AgreementLineItem__c();
        agl2.recordTypeId = requestRecordTypeId;
        agl2.concatRiskCarrierAdresseLEICode__c='test test test';
        agl2.Deduction__c =1;
		agl2.BrokerName__c ='test';
        agl2.LossDepositMode__c='Cash';
        agl2.Apttus__AgreementId__c=initialAgreement.id;
        
        Apttus__AgreementLineItem__c agl3 = new Apttus__AgreementLineItem__c();
        agl3.recordTypeId = leaderRecordTypeId;
        agl3.LeaderName__c='Test leader name';
        agl3.Apttus__AgreementId__c=initialAgreement.id;
        
        Apttus__AgreementLineItem__c agl4 = new Apttus__AgreementLineItem__c();
        agl4.recordTypeId = cccRecordTypeId;
        agl4.CedingAccountName__c='Account name';
        agl4.Apttus__AgreementId__c=initialAgreement.id;
        
        AgreementLineItems.add(agl1);
        AgreementLineItems.add(agl2);
        AgreementLineItems.add(agl3);
        AgreementLineItems.add(agl4);
        insert AgreementLineItems;
    }
    
    @isTest
    static void testConcatFieldAGLOnAgreement(){ 
        
        // Create InputVariables
        CLM_UpdateAgreementByAGL.InputVariables inputVariables = new CLM_UpdateAgreementByAGL.InputVariables();
        inputVariables.AgreementIdList = new List<String>{ [SELECT id FROM Apttus__APTS_Agreement__c LIMIT 1].Id };

        // Create a list of InputVariables
        List<CLM_UpdateAgreementByAGL.InputVariables> inputList = new List<CLM_UpdateAgreementByAGL.InputVariables>();
        inputList.add(inputVariables);

        Test.startTest();

        // Call the method to be tested
        List<CLM_UpdateAgreementByAGL.Result> results = CLM_UpdateAgreementByAGL.concatFieldAGLOnAgreement(inputList);

        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size());
        System.assertEquals([SELECT TECH_TriggerSyncAGL__c FROM Apttus__APTS_Agreement__c LIMIT 1].TECH_TriggerSyncAGL__c, false);
        System.assertEquals('Successfull', results[0].errorMsg, 'Expected success message');
    }
    
    @isTest
    static void testConcatFieldAGLOnAgreementError(){
        Test.startTest();

        // Call the method to be tested
        List<CLM_UpdateAgreementByAGL.Result> results = CLM_UpdateAgreementByAGL.concatFieldAGLOnAgreement(null);

        Test.stopTest();
    } 
}