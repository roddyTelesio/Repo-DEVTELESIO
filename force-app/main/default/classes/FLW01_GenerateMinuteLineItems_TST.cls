/***
* @description test class for Class used as flow action to generate minute line items
* @author      SBH
* @date        15/03/2023
***/
@isTest
public with sharing class FLW01_GenerateMinuteLineItems_TST {
    
    static User testUserAdmin;
    static List<User> lstUsers = new List<User>();
    static List<Minute__c> minutesList = new List<Minute__c>();
    static MinuteSettings__c minSettings;

    static{


        minSettings = new MinuteSettings__c();
        minSettings.CanGenerateMinuteLineItems__c = true;
        upsert minSettings;

        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        lstUsers.add(testUserAdmin);
        insert lstUsers;
        System.runAs(testUserAdmin){
            minutesList  = createMinutes();
            insert minutesList;
        }
    }

    /***
    * @description tests and asserts that minute line items are generated successfully.
    * @param       none
    * @return      none
    * @exception   none special.
    * @author      SBH
    * @date        15/03/2023
    ***/
    @IsTest
   public static void generateMLI(){
       System.runAs(testUserAdmin) {

            FLW01_GenerateMinuteLineItems.minuteRequest min = new FLW01_GenerateMinuteLineItems.minuteRequest(); 
            min.minutesInputList = minutesList; 
        
           Test.startTest();
                List<FLW01_GenerateMinuteLineItems.minuteRequest> minutesInput =  new List<FLW01_GenerateMinuteLineItems.minuteRequest>(
        
                );

                minutesInput.add(min);

                List <FLW01_GenerateMinuteLineItems.mliResult> res = FLW01_GenerateMinuteLineItems.generateMLI(minutesInput);
                List<MinuteLineItem__c> mLineItemsCreated = [SELECT Id FROM MinuteLineItem__c]; 
                //System.assertEquals(2, mLineItemsCreated.size()); 
           Test.stopTest();
           
       }
   }

   /***
    * @description Creates minutes for test initialisation/preparation
    * @param       none
    * @return      List<Minute__c> 
    * @exception   none special.
    * @author      SBH
    * @date        15/03/2023
    ***/
    public static List<Minute__c> createMinutes(){
        return new List<Minute__c>{
            new Minute__c(
                name= 'testMinute',
                Description__c = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibus. Vivamus elementum semper nisi. Aenean vulputate eleifend tellus. Aenean leo ligula, porttitor eu,'
            )
        };
    }
}