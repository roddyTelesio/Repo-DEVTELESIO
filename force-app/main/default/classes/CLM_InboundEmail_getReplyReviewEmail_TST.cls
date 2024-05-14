/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 03-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   02-11-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
private class CLM_InboundEmail_getReplyReviewEmail_TST {

    @testSetup
    static void setupTestData() {
        // Create a new EmailMessage object and populate its fields
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject = 'Test Subject';
        emailMessage.TextBody = 'This is the plain text body of the email.';
        emailMessage.HtmlBody = '<p>This is the HTML body of the email.</p>';
        emailMessage.FromAddress = 'testuser@example.com';
        emailMessage.FromName = 'Test User';
        emailMessage.ToAddress = 'recipient@example.com';
        emailMessage.MessageIdentifier = 'example_in_reply_to';

        insert emailMessage;
    }

    @isTest
    static void testInboundEmailProcessing() {
        CLM_InboundEmail_getReplyReviewEmail emailHandler = new CLM_InboundEmail_getReplyReviewEmail();

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Subject';
        email.fromAddress = 'test@example.com';
        email.inReplyTo = 'example_in_reply_to';
        email.messageId = 'example_message_id';
        email.toAddresses = new List<String>{'test@example.com1','test@example.com2'};
            
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
            
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, envelope);
    }


    
    
}