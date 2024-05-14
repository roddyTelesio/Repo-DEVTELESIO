public with sharing class initSubSectionFromSection {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Record Id From Section' )
        public Id recordId;    // recordId for Section
    }

    public class Result{
        @InvocableVariable(required=true label='Init conditions from section values')
        public SubSection__c ConditionValue;

        @InvocableVariable(required=true label='type of Reinstatement')
        public Reinstatement__c reinsType;

        public Result(SubSection__c ConditionValue, Reinstatement__c reinsType){
            this.ConditionValue = ConditionValue;
            this.reinsType = reinsType;
        }
    }

         /***
    * @description	// 
    * @param	    NONE
    * @return		//
    * @exception   	Nones
    ***/   
        @InvocableMethod(label='Init Conditions' description='' callout=false)
        public static List<Result> initCondition (List<ObjectContext> obj){
            List<SubSection__c> lstSubSecNew = new   List<SubSection__c> ();
            SubSection__c subSection = new SubSection__c();
            Reinstatement__c reins = new Reinstatement__c();
            String strTypeReins;
                for (Section__c sec:[SELECT AAD__c, AAL__c, TAL__c, Deductible__c, LimitType__c,Limit__c, Unlimited__c FROM Section__c WHERE Id=:obj[0].recordId]){
                    subSection.Id = null;
                    subSection.AAD__c = sec.AAD__c;
                    subSection.AAL__c = sec.AAL__c;
                    subSection.TAL__c = sec.TAL__c;
                    subSection.Section__c = obj[0].recordId;
                    subSection.Deductible__c = sec.Deductible__c;
                    subSection.LimitType__c = sec.LimitType__c;
                    subSection.Limit__c = sec.Limit__c;
                    subSection.Unlimited__c = sec.Unlimited__c;
                    //lstSubSecNew.add(subSection);
                }

                for (Reinstatement__c r:[SELECT Type__c, Section__c FROM Reinstatement__c WHERE Section__c=:obj[0].recordId]){
                    reins.Id = null;
                    reins.Type__c = r.Type__c;
                    
                }
            Result r = new Result(subSection, reins);
            return new List<Result>{r};
        }
}