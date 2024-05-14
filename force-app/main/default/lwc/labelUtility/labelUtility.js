import signingReqSaved from '@salesforce/label/c.signingReqSaved';
import FormEntriesInvalid from '@salesforce/label/c.FormEntriesInvalid';
import phasesClosed from '@salesforce/label/c.phasesClosed';
import NoChanges from '@salesforce/label/c.NoChanges';
import NoRequest from '@salesforce/label/c.NoRequest';
import emailSent from '@salesforce/label/c.emailSent';
import requestSelected from '@salesforce/label/c.requestSelected';
import writtenShare from '@salesforce/label/c.writtenShare';
import requestDeleted from '@salesforce/label/c.requestDeleted';
import requestReopened from '@salesforce/label/c.requestReopened';
import NoSigningRequestSetupPresent from '@salesforce/label/c.NoSigningRequestSetupPresent';
import SigningRequestNoFXRate from '@salesforce/label/c.SigningRequestNoFXRate';
import SigningRequestNoSignedShare from '@salesforce/label/c.SigningRequestNoSignedShare';
import Premium_exceeds_authorization_for_signing from '@salesforce/label/c.Premium_exceeds_authorization_for_signing';
import SignedShareNotMatchingPlacementS from '@salesforce/label/c.SignedShareNotMatchingPlacementS';
import NoContractualDocumentAttached from '@salesforce/label/c.NoContractualDocumentAttached';
import NoSigningRequestSelected from '@salesforce/label/c.NoSigningRequestSelected';
import SigningRequestStatusSetup from '@salesforce/label/c.SigningRequestStatusSetup';
import NoSigningRequest_ReinsurerStatus_Sent_or_Timeout from '@salesforce/label/c.NoSigningRequest_ReinsurerStatus_Sent_or_Timeout';
import SomeQuoteRequestAssociatedCancelTreatySection from '@salesforce/label/c.SomeQuoteRequestAssociatedCancelTreatySection';//RRA - ticket 585 
import askValidationImpossible from '@salesforce/label/c.askValidationImpossible';
import CannotRemind_RequestNotSent from '@salesforce/label/c.CannotRemind_RequestNotSent';
import NoNeedToAskForValidation from '@salesforce/label/c.NoNeedToAskForValidation';
import CloseSigningErrorMsg from '@salesforce/label/c.CloseSigningErrorMsg';
import errorMsg from '@salesforce/label/c.errorMsg';

const label = {
    signingReqSaved: signingReqSaved,
    FormEntriesInvalid: FormEntriesInvalid,
    phasesClosed: phasesClosed,
    NoChanges: NoChanges,
    NoRequest: NoRequest,
    emailSent: emailSent,
    requestSelected: requestSelected,
    writtenShare: writtenShare,
    requestDeleted: requestDeleted,
    requestReopened: requestReopened,
    NoSigningRequestSetupPresent: NoSigningRequestSetupPresent,
    SigningRequestNoFXRate: SigningRequestNoFXRate,
    SigningRequestNoSignedShare: SigningRequestNoSignedShare,
    Premium_exceeds_authorization_for_signing: Premium_exceeds_authorization_for_signing,
    SignedShareNotMatchingPlacementS: SignedShareNotMatchingPlacementS,
    NoContractualDocumentAttached: NoContractualDocumentAttached,
    NoSigningRequestSelected: NoSigningRequestSelected,
    SigningRequestStatusSetup: SigningRequestStatusSetup,
    NoSigningRequest_ReinsurerStatus_Sent_or_Timeout: NoSigningRequest_ReinsurerStatus_Sent_or_Timeout,
    SomeQuoteRequestAssociatedCancelTreatySection: SomeQuoteRequestAssociatedCancelTreatySection,
    CannotRemind_RequestNotSent: CannotRemind_RequestNotSent,
    NoNeedToAskForValidation: NoNeedToAskForValidation,
    CloseSigningErrorMsg: CloseSigningErrorMsg,
    errorMsg: errorMsg
};
export {label};