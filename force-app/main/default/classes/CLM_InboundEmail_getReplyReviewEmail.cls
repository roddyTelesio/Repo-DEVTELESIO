/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

// Import the namespace of the managed package
//import Namespace.ClassName;

global class CLM_InboundEmail_getReplyReviewEmail implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        System.debug('email.authenticationResults : ' + email.authenticationResults);
        System.debug('email.binaryAttachments : ' + email.binaryAttachments);
        System.debug('email.ccAddresses : ' + email.ccAddresses);
        System.debug('email.fromAddress : ' + email.fromAddress);
        System.debug('email.fromName : ' + email.fromName);
        System.debug('email.headers : ' + email.headers);
        System.debug('email.htmlBody : ' + email.htmlBody);
        System.debug('email.htmlBodyIsTruncated : ' + email.htmlBodyIsTruncated);
        System.debug('email.inReplyTo : ' + email.inReplyTo);
        System.debug('email.messageId : ' + email.messageId);
        System.debug('email.references : ' + email.references);
        System.debug('email.plainTextBody : ' + email.plainTextBody);
        System.debug('email.plainTextBodyIsTruncated : ' + email.plainTextBodyIsTruncated);
        System.debug('email.replyTo : ' + email.replyTo);
        System.debug('email.replyTo : ' + email.replyTo);
        System.debug('envelope : ' + envelope.fromAddress);
        System.debug('envelope : ' + envelope.toAddress);

        try{

            List<EmailMessage> relatedEM = [
                SELECT  ActivityId, MessageIdentifier, RelatedToId
                FROM EmailMessage
                WHERE MessageIdentifier = :email.inReplyTo
            ];

    
            if(!relatedEM.isEmpty()){
                System.debug('relatedEM '+ relatedEM);
                EmailMessage em      = new EmailMessage();
                //em.ActivityId        = relatedEM[0].ActivityId;
                em.ToAddress         = email.toAddresses[0];
                em.Subject           = email.subject;
                em.ThreadIdentifier  = email.inReplyTo;
                em.MessageIdentifier = email.messageId;
                em.RelatedToId       = relatedEM[0].RelatedToId;
                em.FromAddress       = envelope.fromAddress;
                em.HtmlBody          = email.HtmlBody;
                em.Incoming          = true;
                em.MessageDate       = Datetime.now();
                em.TextBody          = email.plainTextBody;
                em.fromName          = email.fromName;
                em.Status            = '3';
                System.debug('relatedEM em '+ em);
                
                insert em;

                if(email.binaryAttachments != null){
                    System.debug('contain binaryAttachments ');
        
                    List<ContentVersion> contentVersions = new List<ContentVersion>();
        
                    for (Messaging.InboundEmail.BinaryAttachment binAttachment : email.binaryAttachments) {
                        ContentVersion contentVersionObj = new ContentVersion();
                        contentVersionObj.title = binAttachment.fileName;
                        contentVersionObj.VersionData = binAttachment.body;
                        contentVersionObj.PathOnClient = '/'+ binAttachment.fileName;
                        contentVersions.add(contentVersionObj);
                    }
                    System.debug('contentVersions ' + contentVersions);
                    insert contentVersions;
        
                    List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
                    contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions];
        
                    for(ContentVersion contentVersion : contentVersions){
                        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
                        contentDocumentLink.LinkedEntityId = em.Id;
                        contentDocumentLink.ShareType = 'V'; // Inferred permission
                        contentDocumentLink.Visibility = 'InternalUsers';
                        contentDocumentLinks.add(contentDocumentLink);
                    }
                    System.debug('contentDocumentLinks ' + contentDocumentLinks);
                    insert contentDocumentLinks;
                }
            }else{
                System.debug('relatedEM is Empty ');
            }
        }catch(Exception e){
            System.debug('Exception  ' + e.getMessage());
        }

        //Call Conga
        Apttus.AgreementEndParallelReviewByEmail x = new Apttus.AgreementEndParallelReviewByEmail();
        return x.handleInboundEmail(email, envelope);
    }
}