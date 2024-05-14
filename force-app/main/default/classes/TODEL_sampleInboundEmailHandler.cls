/**
 * @description       : The only usage of this class is to reference it in an email service
 *                      Delete it after it's no longer used (After CLM deployments)
 * @author            : Azhar Nahoor - Telesio 
 * @group             : 
 * @last modified on  : 08-28-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class TODEL_sampleInboundEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        System.debug('Sample message');
        return null;
    }
}