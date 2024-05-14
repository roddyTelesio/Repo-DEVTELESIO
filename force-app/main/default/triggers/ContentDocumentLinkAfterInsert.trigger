trigger ContentDocumentLinkAfterInsert on ContentDocumentLink (after insert) {
    /**************************************************************************************
    -- - Author        : Telesio
    -- - Description   : Trigger on ContentDocumentLink
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 12-feb-2024  SBH   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
    ContentDocumentLink_DMN.markForDeletion(Trigger.new);
}