/**
 * @description       : Test Data
 * @author            : Spoon Consulting
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-10-2019   MBE                      Initial Version
**/
@IsTest
public with sharing class TestFactory {

   //get for system administrator profile id
   public static Id getProfileAdminId(){
       return ([SELECT Id FROM Profile
                WHERE Name = 'Administrateur système'
                OR Name = 'System Administrator'
                OR Name = 'Amministratore del sistema'
                OR Name = 'Systemadministrator'
                OR Name = 'Systemadministratör'
                OR Name = 'Administrador do sistema'
                OR Name = 'Systeembeheerder'
                OR Name = 'Systemadministrator'].Id);
   }
   public static Id getProfileCEId(){
    return ([SELECT Id FROM Profile
             WHERE Name = 'AGRE_Actor C.E'].Id);
   }
   public static Id getProfileExternalId(){
    return ([SELECT Id FROM Profile
             WHERE Name = 'AGRE_Community External User'].Id);
   }

   public static Id getProfileInternalId(){
    return ([SELECT Id FROM Profile
             WHERE Name = 'AGRE_Community Internal User'].Id);
   }

   //get random unique string
   public static String randomizeString(String name){
       String charsForRandom = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
       String randStr = '';
       while (randStr.length() < 6) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), charsForRandom.length());
           randStr += charsForRandom.substring(idx, idx+1);
       }
       return name+randStr;
   }

   //create admin user
   public static User createUser(String name, Id profId){
       return new User(
               Username = TestFactory.randomizeString(name) +'@test.com',
               LastName = 'Ballack',
               FirstName = 'Jean',
               Email = 'Jean@test.com',
               Alias = 'JBAL',
               LanguageLocaleKey = 'en_US',
               TimeZoneSidKey = 'Europe/Paris',
               LocaleSidKey = 'en_US',
               EmailEncodingKey = 'UTF-8',
               ProfileId = profId
       );
   }

   //create User with a role
   public static User createUserWithRole(String name, Id profId, Id roleId){
        return new User(
                Username = TestFactory.randomizeString(name) +'@test.com',
                LastName = 'Philippe',
                FirstName = 'Jean',
                Email = 'Jean@Philippe.com',
                Alias = 'JPHI',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'Europe/Paris',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = profId,
                UserRoleId  = roleId
        );
    }

    public static Id getHeadUGPRoleId(){
        return ([SELECT Id 
                 FROM UserRole
                 WHERE DeveloperName =: AP_Constant.HeadUGP].Id);
    }

    public static Id getCERoleId(){
        return ([SELECT Id 
                 FROM UserRole
                 WHERE DeveloperName =: AP_Constant.ClientExecutive].Id);
    }

   //create an Account
   public static Account createAccount(Id recTypeId, String name, String referentialId){
       return new Account(
               RecordTypeId= recTypeId,
               Name = TestFactory.randomizeString(name),
               TECH_ReferentialId__c = referentialId,
               IsActive__c = true
       );
   }

   //create an IntObj
   public static IntermediateACRRequest__c createIntermediateObject(String name, Id pcc, Id broker, Id reinsurer,String nature, String macrolob, Id user, Id contact){
    return new IntermediateACRRequest__c(
            Name = TestFactory.randomizeString(name),
            Pcc__c = pcc,
            Broker__c = broker,
            Reinsurer__c = reinsurer,
            Nature__c = nature,
            Macrolob__c = macrolob,
            User__c = user,
            Contact__c = contact
            
    );
}


   //create a Group Member
   public static GroupMember createGroupMember(Id groupId, Id userOrGroupId){
       return new GroupMember(
               GroupId = groupId,
               UserOrGroupId = userOrGroupId
       );
   }

   //create a Program
   public static Program__c createProgram(String programName, String status, String stlt, Date inceptionDate, Date expiryDate,
                                          String lta, Date LTAInceptionDate, Date LTAExpiryDate, String uwYear, String principalCedingCompany,
                                          String nature, String lossDeposit, String macroLob){
       return new Program__c(
               Name = programName,
               Status__c = status,
               STLT__c = stlt,
               InceptionDate__c = inceptionDate,
               Expirydate__c = expiryDate,
               LTA__c = lta,
               LTAInceptionDate__c = LTAInceptionDate,
               LTAExpiryDate__c = LTAExpiryDate,
               UwYear__c = uwYear,
               PrincipalCedingCompany__c = principalCedingCompany,
               Nature__c = nature,
               LossDeposit__c = lossDeposit,
               Macro_L_O_B__c = macroLob
       );
   }

   //create a Treaty
   public static Treaty__c createTreaty(String treatyName, Integer layer, String webXLReference, String typeOfTreaty
                                        , Id programId, String status, Decimal placementSharePercent, String typeOfReinsurance
                                        , String actorRef, String lossAttachment, String LTA, String tacitRenewal, String isPooled, String deduc){
       return new Treaty__c(
               Name = treatyName,
               Layer__c = layer,
               WebXLReference__c = webXLReference,
               TypeofTreaty__c = typeOfTreaty,
               Program__c = programId,
               Status__c = status,
               PlacementShare_Perc__c = placementSharePercent,
               TypeofReinsurance__c = typeOfReinsurance,
               Actor_Reference__c = actorRef,
               TreatyReference__c = actorRef,
               LossAttachment__c = lossAttachment,
               LTA__c = LTA,
               TacitRenewal__c = tacitRenewal,
               IsPooled__c = isPooled,
               Deductions__c = deduc,
               AGRe_Cession__c = 0
       );
   }

   //create a Section
   public static Section__c createSection(String name, String sectionNumber,String lob, String subLob, String currencyVal
                                            , Integer limitVal, Decimal retention, Id programId, Id treatyId, String techTypeOfTreaty
                                            , String status, Boolean retainedToLead, String quoteType
                                            , String relatedSectionId, String techNature, String nonTradRein, String nature, String InclusionOfCatastrophicGuarantees, String ExclusionOfCatastrophicGuarantees){
       return new Section__c(
               Name = name,
               SectionNumber__c = sectionNumber,
               LoB__c = lob,
               Currency__c = currencyVal,
               Limit__c = limitVal,
               Retention__c = retention,
               Program__c = programId,
               Treaty__c = treatyId,
               TECH_TypeofTreaty__c = techTypeOfTreaty,
               Status__c = status,
               Retained_to_lead__c = retainedToLead,
               QuoteType__c = quoteType,
               RelatedSection__c = relatedSectionId,
               SubLoB__c = subLob,
               TECH_NatureProgram__c = techNature,
               NonTraditionalReinsuranceAndOrFinit__c = nonTradRein,
               Nature__c = nature,
               InclusionOfCatastrophicGuarantees__c = InclusionOfCatastrophicGuarantees,
               ExclusionOfCatastrophicGuarantees__c = ExclusionOfCatastrophicGuarantees
       );
   }

   //create a Covered Ceding Company
   public static CoveredCedingCompany__c createCovCedCom(String accId, Id programId, Boolean programIsSelected, Id treatyId
                                                       , Boolean treatyIsSelected, Id sectionId, Boolean sectionIsSelected
                                                       , Integer epi, Decimal allocationKey){
       return new CoveredCedingCompany__c(
               Account__c = accId,
               Program__c = programId,
               ProgramIsSelected__c = programIsSelected,
               Treaty__c = treatyId,
               TreatyIsSelected__c = treatyIsSelected,
               Section__c = sectionId,
               SectionIsSelected__c = sectionIsSelected,
               EPI__c = epi,
               AllocationKey__c = allocationKey
       );
   }

   //create a Pool
   public static Pool__c createPool(String name, Decimal shareRate, String year, String assignedTo){
       return new Pool__c(
               Name = name,
               ShareRate__c = shareRate,
               Year__c = year,
               AssignedTo__c = assignedTo
       );
   }

   //create a Pool Treaty Section
   public static PoolTreatySection__c createPoolTreatySection(Id poolId, Id treatyId, Id sectionId, Boolean sectionIsSelected,
                                               Boolean treatyIsSelected, Decimal treatyShareRate, Decimal sectionShareRate){
       return new PoolTreatySection__c(
               Pool__c = poolId,
               Treaty__c = treatyId,
               Section__c = sectionId,
               SectionIsSelected__c = sectionIsSelected,
               TreatyIsSelected__c = treatyIsSelected,
               TreatyShareRate__c = treatyShareRate,
               SectionShareRate__c = sectionShareRate
       );
   }

   //create a Reinstatement
   public static Reinstatement__c createReinstatement(Id sectionId, Boolean free, Integer order, Decimal percentage,
                                                    String prorata, String type){
       return new Reinstatement__c(
               Section__c = sectionId,
               Free__c = free,
               Order__c = order,
               Percentage__c = percentage,
               Prorata__c = prorata,
               Type__c = type
       );
   }

   //create a ContentDocumentLink
   public static ContentDocumentLink createContentDocumentLink(Id contentDocId, Id linkedEntityId, String shareType){
       return new ContentDocumentLink(
               ContentDocumentId = contentDocId,
               LinkedEntityId = linkedEntityId,
               ShareType = shareType
       );
   }

   //create a ContentVersion
   public static ContentVersion createContentVersion(String documentType, String groupType,String phase
                                                   , String title, Blob versionData, String pathOnClient){
       return new ContentVersion(
           DocumentType__c = documentType,
           GroupType__c = groupType,
           Phase__c = phase,
           Title = title,
           VersionData = versionData,
           PathOnClient = pathOnClient
       );
   }

      //create a Special Acceptance
   public static SpecialAcceptance__c createSpecialAcceptance(String RecordTypeId, Id programId, Id principalCedingCompany,String saName, String uwYear, String internalStatus, String portalStatus, String reference, Boolean legalEntity, Boolean naturePerson, String bound, Id renewedFromSpecialAcceptance, Id sentAgreFromSpecialAcceptance, String type, String subLob, String reason, String covCedCom){
       return new SpecialAcceptance__c(
           RecordTypeId = RecordTypeId,
           Program__c = programId,
           PrincipalCedingCompany__c = principalCedingCompany,
           SpecialAcceptanceName__c = saName,
           UnderWrittingYear__c = uwYear,
           InternalStatus__c = internalStatus,
           PortalStatus__c = portalStatus,
           Reference__c = reference,
           LegalEntity__c = legalEntity,
           NaturalPerson__c = naturePerson,
           Bound__c = bound,
           RenewedFromSpecialAcceptance__c = renewedFromSpecialAcceptance,
           SentAgreFromSpecialAcceptance__c = sentAgreFromSpecialAcceptance,
           Type__c = type,
           SubLoB__c = subLob,
           Reason__c = reason,
           CoveredCedingCompany__c = covCedCom
       );
   }

   //create a Request
   public static Request__c createRequest(Id programId, Id treatyId, Id brokerId, Id reinsurerId, String requestType, String phaseType, String recordTypeId, String status, String reinsurerStatus, Id sectionId){
       return new Request__c(
           Program__c = programId,
           Treaty__c = treatyId,
           Broker__c = brokerId,
           Reinsurer__c = reinsurerId,
           QuoteType__c = requestType,
           TECH_PhaseType__c = phaseType,
           ActiveStatus__c = status,
           RecordTypeId = RecordTypeId,
           ReinsurerStatus__c = reinsurerStatus,
           Section__c = sectionId
       );
   }

   //Create Lead request
     public static Request__c createLeadRequest(Id programId, Id treatyId, Id brokerId, Id reinsurerId, String requestType, String phaseType, String recordTypeId, String status, String reinsurerStatus, Id sectionId){
         //create parent request
         Request__c parentRequest = new Request__c();
         parentRequest.Program__c = programId;
         parentRequest.Treaty__c = treatyId;
         parentRequest.Broker__c = brokerId;
         parentRequest.Reinsurer__c = reinsurerId;
         parentRequest.QuoteType__c = requestType;
         parentRequest.TECH_PhaseType__c = phaseType;
         parentRequest.ActiveStatus__c = status;
         parentRequest.RecordTypeId = RecordTypeId;
         parentRequest.ReinsurerStatus__c = reinsurerStatus;
         parentRequest.Section__c = sectionId;
         insert parentRequest;

         //create child request
         Request__c childRequest = new Request__c();
         childRequest.Program__c = programId;
         childRequest.Treaty__c = treatyId;
        //  childRequest.Broker__c = brokerId;
        childRequest.Reinsurer__c = null;
         childRequest.QuoteType__c = requestType;
         childRequest.TECH_PhaseType__c = phaseType;
         childRequest.ActiveStatus__c = status;
         childRequest.RecordTypeId = RecordTypeId;
         childRequest.ReinsurerStatus__c = reinsurerStatus;
         childRequest.Section__c = sectionId; //MRA 935 4/08/2022 test class correction : START
         childRequest.FixedRate__c = 2 ;
         childRequest.MinRate__c = 2;
         childRequest.MaxRate__c= 2;
         childRequest.ProvisionalRate__c= 2;
         childRequest.FlatPremium__c= 2000;
         childRequest.MDP__c= 2;
         childRequest.FixedCommission__c= 2;
         childRequest.MinVarCommission__c= 2;
         childRequest.MaxVarCommission__c= 2;
         childRequest.ProvisionalCommission__c= 2;
         childRequest.PerHeadPremium__c= 2;
         childRequest.MinPerHeadAmount__c= 2;
         childRequest.MaxPerHeadAmount__c= 2;
         childRequest.ProvisionalPerHeadPremium__c= 2;
         childRequest.EstimatedInsurancePremium__c= 2;
         childRequest.PerHeadPremium__c= 2;
         childRequest.EstimatedReinsurancePremium__c = 3000000 ; //MRA 935 4/08/2022 test class correction : END
         insert childRequest;

         //create junction object
         LeadRequestSelection__c leadReqSelection = new LeadRequestSelection__c();
         leadReqSelection.LeadRequestChild__c = childRequest.Id;
         leadReqSelection.LeadRequestParent__c = parentRequest.Id;
         insert leadReqSelection;

         return parentRequest;
    }

    public static Contact createContact( String firstName, String lastName, Id accountId, String nature, String macroLOB){
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = accountId,
            Nature__c = nature,
            MacroLoB__c = macroLOB
        );
    }

    public static AccountContactRelation createAccountContactRelation( Id accountId, Id contactId, String roles, Boolean isActive){
        return new AccountContactRelation(
            AccountId = accountId,
            ContactId = contactId,
            Roles = roles,
            IsActive = isActive
        );
    }

    public static DocumentVisibility__c createDocumentVisibility(Id brokerId, Id reinsurerId, Id contentVersionId, Id program){
        return new DocumentVisibility__c(
            Broker__c = brokerId,
            Tech_BrokerId__c = brokerId,
            Tech_ReinsurerId__c = reinsurerId,
            Reinsurer__c = reinsurerId,
            ContentVersionId__c =  contentVersionId,
            Program__c = program
        );
    }

    public static NACECode__c createNaceCode(String naceCode, String originalInsuredAct){
        return new NACECode__c(
            NACECode__c = naceCode,
            OriginalInsuredActivity__c = originalInsuredAct
        );
    }

    public static SubSection__c createSubSection(Id sectionId, Integer limitValue, String limitType ){
        return new SubSection__c(
            Section__c = sectionId,
            Limit__c = limitValue,
            LimitType__c=limitType
        ) ;
    }

    public static ReferentialHazardBassin__c createRHBa(String codeRegion, String codeRegion2, String hazardCode, Decimal idExt,String peril, String type){
        return new ReferentialHazardBassin__c(
            CodeRegion__c = codeRegion,
            CodeRegion2Characters__c = codeRegion2,
            HazardCode__c = hazardCode,
            Id__c = IdExt,
            Peril__c = peril,
            Type__c = type
        ) ;
    }

    public static Apttus__APTS_Agreement__c createAgreement(String Name){
        return new Apttus__APTS_Agreement__c(
            Name = Name
        ) ;
    }

    public static Apttus__DocumentVersionDetail__c createDocumentVersionDetail(String Name, Id docVerId, String title, Integer verMajor, Integer verMinor, Integer verRev){
        return new Apttus__DocumentVersionDetail__c(
            Name = Name,
            Apttus__DocumentVersionId__c = docVerId,
            Apttus__Title__c = title,
            Apttus__VersionMajor__c = verMajor,
            Apttus__VersionMinor__c = verMinor,
            Apttus__VersionRevision__c = verRev
        ) ;
    }

    public static Apttus__DocumentVersion__c createDocumentVersion(String Name,String latestVersion,String title){
        return new Apttus__DocumentVersion__c(
            Name = Name,
            Apttus__LatestVersion__c = latestVersion, 
            Apttus__Title__c =title
        ) ;
    }

    public static EmailTemplate createEmailTemplate(String developerName, String TemplateType, String Name){
        return new EmailTemplate(
            developerName = developerName,
            TemplateType = TemplateType, 
            Name =Name,
            FolderId =UserInfo.getUserId(),
            isActive = true
        ) ;
    }

    public static Apttus__APTS_Template__c createTemplate(String Name){
        return new Apttus__APTS_Template__c(
            Name =Name
        ) ;
    }

    public static Universign_Transaction__c createUniversignTransaction(String Name){
        return new Universign_Transaction__c(
            //Name =Name
        ) ;
    }

    public static Attachment createAttachment(String Name,Id templateId,Blob body){
        return new Attachment(
            Name = Name,
            ParentId = templateId, 
            Body = body
        ) ;
    }

    public static Universign_signer__c createUniversignsigner(Id UniversignTransactionId){
        return new Universign_signer__c(
            UniversignTransaction__c = UniversignTransactionId,
            FirstName__c = 'First',
            LastName__c = 'Last',
            Email__c ='test@example.com'
        ) ;
    } 

    public static User createAdminUserWithCLMAdminPermissionSet() {
        // Create a new user
        User adminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id, // Set the profile to 'System Administrator' or the appropriate profile
            LastName = 'Admin',
            FirstName = 'Test',
            Email = 'admin@test.com',
            Alias = 'adm',
            Username = 'testadminclm1234566@test.com',
            CommunityNickname = 'admin123',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    
        // Insert the user
        insert adminUser;
    
        // Query the "CLM_Admin" permission set
        PermissionSet clmAdminPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'CLM_Admin' LIMIT 1];
    
        // Assign the "CLM_Admin" permission set to the user
        PermissionSetAssignment psAssignment = new PermissionSetAssignment(
            AssigneeId = adminUser.Id,
            PermissionSetId = clmAdminPermissionSet.Id
        );
    
        // Insert the permission set assignment
        insert psAssignment;
    
        return adminUser;
    }
}