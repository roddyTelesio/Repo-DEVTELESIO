/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 19-04-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   26-01-2024   Patrick Randrianarisoa   Initial Version
**/
public class CLM_UpdateAgreementByAGL {
    public class InputVariables{
        @InvocableVariable(required=false label='List Id Agreements' )
        public List<String> AgreementIdList;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }
    }

    @InvocableMethod(label='[CLM] Concat Field AGL On Agreement' description='Update certain fields on Agreement using fields on Agreement Line Item')
    public static List<Result> concatFieldAGLOnAgreement(List<InputVariables> lstInputVariables) {
        try{
            List<Result> lstResult = new List<Result>();
            List<String> AgreementIds = new List<String>();
            for(InputVariables inputVar: lstInputVariables){
                AgreementIds.addAll(inputVar.AgreementIdList);
                lstResult.add(new Result(true, 'Successfull')); //The number of results must match the number of interviews that were executed in a single bulk execution request.
            }
            System.debug('AgreementIds '+AgreementIds);
            if(AgreementIds.size()> 0){
                String brokerName;
                String concatCCC;
                String concatFieldOnRequest;
                String concatTreatyref;
                Decimal deduction;
                String leaderName;
                Decimal placementShare;
                String lossAttachement;
                String lossDepositMode;
                Boolean AgreementToUpdate;
                String riskCarrierId;
                
                List<Apttus__APTS_Agreement__c> lstAgreementToUpdate = new List<Apttus__APTS_Agreement__c>(); 

                for(Apttus__APTS_Agreement__c ag : [SELECT id,isAmended__c,RecordType.DeveloperName,Request__c,(SELECT id,Apttus__AgreementId__c,TECH_RecordTypeDevName__c,concatRiskCarrierAdresseLEICode__c,Deduction__c,BrokerName__c,LossDepositMode__c,TreatyRef__c,Order__c,PlacementShare__c,LossAttachment__c,Apttus__AgreementId__r.isAmended__c,CedingAccountName__c,LeaderName__c,Request__c,riskCarrierId__c FROM Apttus__AgreementLineItems__r WHERE TECH_RecordTypeDevName__c IN ('Request','Treaty','Leader','CoveredCedingCompanies') order by Layer__c,treatyName__c) FROM Apttus__APTS_Agreement__c WHERE id IN :AgreementIds]){
                    brokerName='';
                    concatCCC='';
                    concatFieldOnRequest='';
                    concatTreatyref='';
                    deduction=0;
                    leaderName='';
                    lossAttachement='';
                    lossDepositMode='';
                    placementShare=0;
                    AgreementToUpdate = false;
                    riskCarrierId = null;
                    for(Apttus__AgreementLineItem__c agl : ag.Apttus__AgreementLineItems__r){
                        if(agl.TECH_RecordTypeDevName__c =='Request'){
                            concatFieldOnRequest = agl.concatRiskCarrierAdresseLEICode__c;
                            deduction = agl.Deduction__c;
                            brokerName = agl.BrokerName__c;
                            lossDepositMode = agl.LossDepositMode__c;
                            riskCarrierId = agl.riskCarrierId__c;
                            AgreementToUpdate = true;
                        }else if(agl.TECH_RecordTypeDevName__c =='Treaty'){
                            concatTreatyref = concatTreatyref + agl.TreatyRef__c + ';';
                            if(agl.Order__c == 1){
                                placementShare = agl.PlacementShare__c;
                                lossAttachement = agl.LossAttachment__c;
                            }
                            AgreementToUpdate = true;
                        }else if(agl.TECH_RecordTypeDevName__c =='Leader'){
                            leaderName = agl.LeaderName__c;
                            AgreementToUpdate = true;
                        }else if(agl.TECH_RecordTypeDevName__c =='CoveredCedingCompanies'){
                            if(agl.Apttus__AgreementId__r.isAmended__c && String.isBlank(agl.CedingAccountName__c)){
                                concatCCC = concatCCC + agl.CedingAccountName__c +', ';
                                AgreementToUpdate = true;
                            }
                        }
                    }

                    if(AgreementToUpdate){
                        Apttus__APTS_Agreement__c newAgree = new Apttus__APTS_Agreement__c(
                            id=ag.id,
                            treaty_ref__c= (!String.isBlank(concatTreatyref) && concatTreatyref.length() > 254) ? concatTreatyref.substring(0, 254) : concatTreatyref ,
                            Concat_CCC__c= (!String.isBlank(concatCCC) && concatCCC.length() > 254) ? concatCCC.substring(0, 254) : concatCCC,
                            BrokerName__c=brokerName,
                            Concat_Field_on_Request__c= !String.isBlank(concatFieldOnRequest) ? concatFieldOnRequest.unescapeHtml4() : '',
                            Deduction__c=deduction,
                            LeaderName__c=leaderName,
                            LossDepositMode__c=lossDepositMode,
                            Loss_attachement__c=lossAttachement,
                            Placement_share__c=placementShare,
                            RiskCarrier__c=riskCarrierId,
                            TECH_TriggerSyncAGL__c=false
                        );
                        lstAgreementToUpdate.add(newAgree);
                    }

                }

                System.debug('lstAgreementToUpdate ' +lstAgreementToUpdate);
                System.debug('lstAgreementToUpdate size () ' +lstAgreementToUpdate.size());
                if(lstAgreementToUpdate.size()>0){
                    update lstAgreementToUpdate;
                }
            }
            
            return lstResult;
        }
        catch(Exception e){  
            System.debug('concatFieldAGLOnAgreement Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}