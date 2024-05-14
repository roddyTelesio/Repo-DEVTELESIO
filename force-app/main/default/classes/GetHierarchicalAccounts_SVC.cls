public with sharing class GetHierarchicalAccounts_SVC extends sfpegListQuery_SVC {
            
    public override List<Object> getData(final Object input, final String query) {
        System.debug('getData: START GetHierarchicalAccounts_SVC implementation =' + input);
        
        Map<Object,Object> inputData = (Map<Object,Object>) input;
        ID recordId = (ID)(inputData.get('CurrID'));
        Id AccId ; 

        if (recordId != null) {
            Account acc= [SELECT Id,Name,AccountUltimateParent__c,TECH_ReferentialId__c FROM Account WHERE Id= :recordId] ;
            if (acc != null) {
                if (acc.TECH_ReferentialId__c.startsWith('RGC_')) {
                    System.debug('starts with RGC');
                    AccId = recordId ;
                }
                else{
                    System.debug('does not start with RGC');
                    AccId = acc.AccountUltimateParent__c ;
                }
            }
        }
        Account parentAcc= [SELECT Id,Name,AccountUltimateParent__c,TECH_ReferentialId__c FROM Account WHERE Id= :AccId] ;

        Map<ID,Object> resultMap = fetchDetails(AccId,recordId,parentAcc);

        System.debug('getData: END with #records on 1st level ' + resultMap.size());
        
        return resultMap.values();
    }
    
    private Map<ID,Object> fetchDetails(ID AccId,Id recordId, Account parentAcc) {
        System.debug('fetchDetails: START GetHierarchicalAccounts_SVC implementation');
        Map<Id,Account> accMap = new Map<ID,Account>([SELECT Id,Name,ParentId,IsActive__c,IsRiskCarrier__c,IsILS__c,IsLloyd__c,(SELECT Id,Name,IsILS__c,IsLloyd__c,IsActive__c,IsRiskCarrier__c FROM ChildAccounts WHERE  IsRiskCarrier__c=true ) FROM Account WHERE ParentId =:AccId]);
        System.debug('accMap' + accMap);
        if(accMap == null){
        throw new AuraHandledException('No Account for  ' + AccId + ' !');
        }

        Map<ID,Object> resultMap = new Map<ID,Object>();
        System.debug('ResultMap > ');
        for (ID iter : accMap.keySet()) {
            Account iterAcc = accMap.get(iter); 
            
            Map<Object,Object> iterObj = new Map<Object,Object>{ 
                'Id' => iterAcc.Id, 
                'Name' => addLittleIconOnName(iterAcc.Name,iterAcc.Id,recordId)
            }; 
            if (iterAcc.ChildAccounts == null) {
                System.debug('Account has no children'); 
            }
            else{
                System.debug('Account: processing children'); 
                List<Object> accChildren = new List<Object>(); 
                for (Account iterChildAcc : iterAcc.ChildAccounts) 
                { 
                    System.debug('fetchDetails: processing child ' + iterChildAcc); 
                    
                    Map<Object,Object> iterChildObj = new Map<Object,Object>{ 
                        'Id' => iterChildAcc.Id,
                        'Name' => addLittleIconOnName(iterChildAcc.Name,iterChildAcc.Id,recordId),
                        'islLOYD' => iterChildAcc.IsLloyd__c,
                        'isILS' =>iterChildAcc.IsILS__c, 
                        'Active' => iterChildAcc.isActive__c
                    }; 
                        accChildren.add(iterChildObj); 
                } 
                    iterObj.put('ChildAccounts',(Object)(accChildren)); 
                } 
            resultMap.put(iter,(Object)(iterObj)); 
        }

        Map<Object,Object> parentObj = new Map<Object,Object>{ 
            'Id' => parentAcc.Id, 
            'Name' => addLittleIconOnName(parentAcc.Name,parentAcc.Id,recordId),
            'ChildAccounts' => (Object)(resultMap.values())
        }; 
        resultMap = new Map<Id, Object>() ;
        resultMap.put(parentAcc.Id, (Object)(parentObj)) ;

        System.debug('fetchDetails: END GetHierarchicalAccounts_SVC implementation : ' + resultMap); 

    return resultMap ;
    }

    private static String addLittleIconOnName(String accName,Id accId,Id recordId){
        if (accId == recordId) {
            return accName + ' ⬅' ;
        }
        return accName ;
    }
    
}