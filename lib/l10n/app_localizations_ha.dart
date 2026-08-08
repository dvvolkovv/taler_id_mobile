// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Bincike';

  @override
  String get appSubtitle => 'Hadin kai na asalin yanayi';

  @override
  String get login => 'Shiga';

  @override
  String get loginButton => 'Shiga';

  @override
  String get register => 'Ƙirƙiri Asusun';

  @override
  String get registerButton => 'Ƙirƙiri Asusun';

  @override
  String get email => 'Imel';

  @override
  String get password => 'Kalmar wucewa';

  @override
  String get confirmPassword => 'Tabbatar da Kalmar wucewa';

  @override
  String get firstName => 'Sunan Farko';

  @override
  String get lastName => 'Sunan Karshe';

  @override
  String get noAccount => 'Ba ku da asusu?';

  @override
  String get createOne => 'Ƙirƙiri ɗaya';

  @override
  String get haveAccount => 'Kuna da asusu?';

  @override
  String get signIn => 'Shiga';

  @override
  String get passwordMinLength => 'Akalla haruffa 8';

  @override
  String get invalidEmail => 'Shigar da ingantaccen imel';

  @override
  String get fieldRequired => 'Filin da ake bukata';

  @override
  String get twoFATitle => 'Tabbatarwa Mai Matakai Biyu';

  @override
  String get twoFASubtitle =>
      'Shigar da lambar 6-dijit daga manhajar tabbatarwa';

  @override
  String get twoFACode => 'Lambar 2FA';

  @override
  String get verify => 'Tabbatar';

  @override
  String get tabProfile => 'Bayanin Kai';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Ƙungiya';

  @override
  String get tabSettings => 'Saituna';

  @override
  String get profile => 'Bayanin Kai';

  @override
  String get editProfile => 'Gyara Bayanai';

  @override
  String get phone => 'Waya';

  @override
  String get country => 'Ƙasa';

  @override
  String get dateOfBirth => 'Ranar Haihuwa';

  @override
  String get documents => 'Takardu';

  @override
  String get addDocument => 'Ƙara Takarda';

  @override
  String get noDocuments => 'Babu takardu da aka loda';

  @override
  String get save => 'Ajiye';

  @override
  String get profileUpdated => 'An sabunta bayanin kai';

  @override
  String get personalData => 'Bayanai na Kai';

  @override
  String get passport => 'Fasfo';

  @override
  String get drivingLicense => 'Lasisin Tuƙi';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'Katin Shaida';

  @override
  String get certificate => 'Takardar Shaida';

  @override
  String get notSpecified => 'Ba a bayyana ba';

  @override
  String get notSpecifiedFemale => 'Ba a bayyana ba';

  @override
  String get documentType => 'Nau\'in Takarda';

  @override
  String get passportId => 'Fasfo / Katin Shaida';

  @override
  String get diplomaCertificate => 'Diploma / Takardar Shaida';

  @override
  String get loadError => 'Kuskuren lodawa';

  @override
  String get verification => 'Tabbatarwa';

  @override
  String get countryAustria => 'Austria';

  @override
  String get countryGermany => 'Jamus';

  @override
  String get countryRussia => 'Rasha';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryKazakhstan => 'Kazakhstan';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryOther => 'Sauran';

  @override
  String get kycTitle => 'Tabbatar da KYC';

  @override
  String get kycVerified => 'An Tabbatar';

  @override
  String get kycPending => 'Ana jira';

  @override
  String get kycRejected => 'An ƙi';

  @override
  String get kycUnverified => 'Ba a Tabbatar ba';

  @override
  String get kycVerifiedDesc =>
      'An tabbatar da shaidarka. Kana da cikakken damar amfani da dukkan fasalolin tsarin Taler.';

  @override
  String get kycPendingDesc =>
      'Ana duba takardunka. Yawanci yana ɗaukar kwanaki 1-2 na kasuwanci.';

  @override
  String get kycRejectedDesc =>
      'Tabbatarwa ta kasa. Da fatan za a duba dalilin kuma sake gabatar da takardun.';

  @override
  String get kycUnverifiedDesc =>
      'Kammala tabbatarwa don buɗe cikakken damar amfani da fasalolin kuɗi na tsarin Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Fara Tabbatarwa';

  @override
  String get retryVerification => 'Sake Gwada Tabbatarwa';

  @override
  String verifiedAt(String date) {
    return 'An Tabbatar: $date';
  }

  @override
  String get documentsSubmitted => 'An gabatar da takardu don dubawa';

  @override
  String get documentsSubmittedDesc =>
      'Dubawa yawanci yana ɗaukar kwanaki 1-2 na kasuwanci. Za ku karɓi sanarwar turawa da sakamakon.';

  @override
  String get securityAes => 'Ana kare bayananka da AES-256 ɓoyewa';

  @override
  String get verificationTime =>
      'Tabbatarwa yana ɗaukar kwanaki 1-2 na kasuwanci';

  @override
  String get pushNotification => 'Za ku karɓi sanarwar turawa da sakamakon';

  @override
  String get kycWebOnly =>
      'Tabbatar da KYC yana samuwa ne kawai a cikin manhajar wayar hannu.';

  @override
  String verificationError(String code) {
    return 'Kuskuren tabbatarwa: $code';
  }

  @override
  String get organizations => 'Ƙungiyoyi';

  @override
  String get noOrganizations => 'Babu ƙungiyoyi';

  @override
  String get noOrganizationsDesc => 'Ƙirƙiri ƙungiya ko karɓi gayyata';

  @override
  String get createOrganization => 'Ƙirƙiri Ƙungiya';

  @override
  String get newOrganization => 'Sabuwar Ƙungiya';

  @override
  String get orgName => 'Suna *';

  @override
  String get orgDescription => 'Bayanin';

  @override
  String get orgEmail => 'Imel na Tuntuɓa';

  @override
  String get orgWebsite => 'Yanar Gizo';

  @override
  String get orgLegalAddress => 'Adireshin Shari\'a';

  @override
  String get create => 'Ƙirƙiri';

  @override
  String get organization => 'Ƙungiya';

  @override
  String get contacts => 'Tuntuɓi';

  @override
  String members(int count) {
    return 'Mambobi ($count)';
  }

  @override
  String get inviteMember => 'Gayyata Memba';

  @override
  String get invite => 'Gayyata';

  @override
  String get sendInvite => 'Aika Gayyata';

  @override
  String inviteSent(String email) {
    return 'An aika gayyata zuwa $email';
  }

  @override
  String get role => 'Matsayi';

  @override
  String get roleOwner => 'Mai Shi';

  @override
  String get roleAdmin => 'Mai Gudanarwa';

  @override
  String get roleOperator => 'Mai Aiki';

  @override
  String get roleViewer => 'Mai Kallo';

  @override
  String get editOrganization => 'Gyara';

  @override
  String get editOrganizationTitle => 'Gyara Ƙungiya';

  @override
  String get removeMember => 'Cire Memba';

  @override
  String removeMemberConfirm(String name) {
    return 'A cire $name daga ƙungiya?';
  }

  @override
  String get memberRemoved => 'An cire memba';

  @override
  String get roleChanged => 'An canza matsayi';

  @override
  String get kybVerified => 'An Tabbatar';

  @override
  String get kybPending => 'Ana Jira';

  @override
  String get kybRejected => 'An Ki';

  @override
  String get kybNone => 'Ba a Tabbatar ba';

  @override
  String get kybVerification => 'Fara Tabbatar da KYB';

  @override
  String get kybStartBusiness => 'Fara Tabbatar da Kasuwanci';

  @override
  String get kybStatusLabel => 'Matsayin KYB';

  @override
  String get noKyb => 'Babu KYB';

  @override
  String get kybBusinessVerificationTitle => 'Tabbatar da Kasuwanci (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'An tabbatar da ƙungiya cikin nasara.';

  @override
  String get kybPendingOrgDesc =>
      'Ana duba takardu. Wannan yawanci yana ɗaukar kwanaki 1-3 na kasuwanci.';

  @override
  String get kybRejectedOrgDesc =>
      'Tabbatarwa ta gaza. Da fatan za a sake gwadawa.';

  @override
  String get kybNoneOrgDesc =>
      'Tabbatar da ƙungiyarku don samun damar fasalolin kasuwanci.';

  @override
  String get invitePlus => '+ Gayyata';

  @override
  String get kybVerificationTitle => 'Tabbatar da KYB';

  @override
  String get kybWebOnlyBusiness =>
      'Binciken KYB yana samuwa ne kawai a cikin manhajar wayar hannu.';

  @override
  String get unknownDevice => 'Na\'ura ba a sani ba';

  @override
  String get ipUnknown => 'IP ba a sani ba';

  @override
  String get currentSessionLabel => 'Na yanzu';

  @override
  String get endSessionAction => 'Rufe';

  @override
  String get deviceLoggedOut => 'Za a fitar da na\'urar.';

  @override
  String get acceptInvitationTitle => 'Gayyata zuwa Ƙungiya';

  @override
  String get acceptInvitation => 'Karɓi Gayyata';

  @override
  String get acceptInvitationDesc =>
      'An gayyace ka ka shiga wata ƙungiya a cikin tsarin Taler.';

  @override
  String get accept => 'Karɓi';

  @override
  String get reject => 'Ki';

  @override
  String get sessions => 'Zaman Aiki';

  @override
  String get currentSession => 'Zaman yanzu';

  @override
  String get deleteSession => 'Rufe Zama';

  @override
  String get deleteSessionConfirm => 'Rufe wannan zaman?';

  @override
  String get sessionDeleted => 'An rufe zaman';

  @override
  String get noSessions => 'Babu zaman aiki';

  @override
  String minutesAgo(int count) {
    return '$count min da suka wuce';
  }

  @override
  String hoursAgo(int count) {
    return '$count hr da suka wuce';
  }

  @override
  String daysAgo(int count) {
    return '$count kwanaki da suka wuce';
  }

  @override
  String get justNow => 'Yanzu-yanzu';

  @override
  String get settings => 'Saituna';

  @override
  String get security => 'Tsaro';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get biometricsDesc => 'Shiga cikin sauri da Face ID ko yatsa';

  @override
  String get biometricsConfirm =>
      'Tabbatar da biometrics don kunna shiga cikin sauri';

  @override
  String get biometricsError => 'Gaza kunna biometrics. Duba saitunan na\'ura.';

  @override
  String get changePassword => 'Sauya Kalmar Wucewa';

  @override
  String get twoFactorAuth => 'Tabbatarwa Biyu';

  @override
  String get currentPassword => 'Kalmar Wucewa ta Yanzu';

  @override
  String get newPassword => 'Sabuwar Kalmar Wucewa';

  @override
  String get confirmNewPassword => 'Tabbatar da Sabuwar Kalmar Wucewa';

  @override
  String get passwordChanged => 'An sauya kalmar wucewa';

  @override
  String get wrongCurrentPassword => 'Kalmar wucewa ta yanzu ba daidai ba';

  @override
  String get passwordTooWeak =>
      'Kalmar wucewa rauni: aƙalla haruffa 8, harafi da lamba suna bukata';

  @override
  String get passwordChangeFailed => 'Gaza sauya kalmar wucewa';

  @override
  String get notifications => 'Sanarwa';

  @override
  String get permissions => 'Izini';

  @override
  String get permissionNotifications => 'Sanarwar Tura';

  @override
  String get permissionNotificationsDesc => 'Kira, saƙonni, halaye';

  @override
  String get permissionMicrophone => 'Makirufo';

  @override
  String get permissionMicrophoneDesc => 'Kiran waya da mataimaki na murya';

  @override
  String get permissionCamera => 'Kamara';

  @override
  String get permissionCameraDesc => 'Kiran bidiyo da tantancewa';

  @override
  String get permissionLocation => 'Wuri';

  @override
  String get permissionLocationDesc => 'Ana amfani da shi don tantancewa';

  @override
  String get permissionOpenSettings => 'Don soke izini, bude saitunan tsarin';

  @override
  String get pushKycStatus => 'Matsayin KYC';

  @override
  String get pushKycStatusDesc => 'Sakamakon tantancewa';

  @override
  String get pushLogins => 'Shiga na\'ura';

  @override
  String get pushLoginsDesc => 'Lokacin shiga daga sabuwar na\'ura';

  @override
  String get account => 'Asusu';

  @override
  String get language => 'Harshe';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Harshe na Fuska';

  @override
  String get exportData => 'Fitar da Bayanai (GDPR)';

  @override
  String get deleteAccount => 'Goge Asusu';

  @override
  String get deleteAccountConfirm => 'Goge asusu?';

  @override
  String get deleteAccountDesc =>
      'Dukkan bayananka za a goge su (GDPR). Wannan aiki ba za a iya dawo da shi ba.';

  @override
  String get logout => 'Fita';

  @override
  String get logoutConfirm => 'Fita?';

  @override
  String get logoutDesc => 'Za a fitar da kai daga Taler ID a wannan na\'ura.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Lambar PIN';

  @override
  String get pinCodeDesc => 'Shiga da sauri tare da lamba mai lamba 4';

  @override
  String get setupPin => 'Saita PIN';

  @override
  String get enterPin => 'Shigar da PIN';

  @override
  String get confirmPin => 'Tabbatar da PIN';

  @override
  String get pinMismatch => 'PIN ba su dace ba';

  @override
  String get passwordMismatch => 'Kalmomin sirri ba su dace ba';

  @override
  String get pinSet => 'An saita PIN cikin nasara';

  @override
  String get enterPinToLogin => 'Shigar da PIN don shiga';

  @override
  String get pinIncorrect => 'PIN ba daidai ba';

  @override
  String get removePin => 'Cire PIN';

  @override
  String get pinRemoved => 'An cire PIN';

  @override
  String get cancel => 'Soke';

  @override
  String get delete => 'Goge';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Sake gwadawa';

  @override
  String get loading => 'Ana loda...';

  @override
  String get error => 'Kuskure';

  @override
  String get success => 'Nasara';

  @override
  String get noData => 'Babu bayanai';

  @override
  String get failedToLoad => 'An kasa loda bayanai';

  @override
  String get failedToLoadProfile => 'An kasa loda bayanin martaba';

  @override
  String get failedToSave => 'An kasa adana canje-canje';

  @override
  String get failedToLoadOrgs => 'An kasa loda kungiyoyi';

  @override
  String get failedToLoadOrg => 'An kasa loda bayanan kungiya';

  @override
  String get failedToCreateOrg => 'An kasa ƙirƙirar kungiya';

  @override
  String get failedToInvite => 'An kasa aika gayyata';

  @override
  String get failedToAcceptInvite => 'An kasa karɓar gayyata';

  @override
  String get failedToLoadSessions => 'An kasa loda zamanai';

  @override
  String get failedToDeleteSession => 'An kasa ƙare zaman';

  @override
  String get failedToLoadKyc => 'An kasa loda matsayin tantancewa';

  @override
  String get failedToStartKyc => 'An kasa fara tantancewa';

  @override
  String get verifiedPersonalInfo => 'Bayanan da aka tantance';

  @override
  String get middleName => 'Sunan Tsakiya';

  @override
  String get placeOfBirth => 'Wurin Haihuwa';

  @override
  String get nationality => 'Ƙasa';

  @override
  String get gender => 'Jinsi';

  @override
  String get genderMale => 'Namiji';

  @override
  String get genderFemale => 'Mace';

  @override
  String get docNumber => 'Lamba';

  @override
  String get docIssuedDate => 'An bayar';

  @override
  String get docValidUntil => 'Ya ƙare a';

  @override
  String get docIssuedBy => 'An bayar da shi ta';

  @override
  String get address => 'Adireshi';

  @override
  String get refreshData => 'Sabunta Bayanai';

  @override
  String get failedToLoadSumsubData => 'An kasa loda bayanan tantancewa';

  @override
  String get sumsubDataLoading => 'Ana lodin bayanan tantancewa...';

  @override
  String get reviewResultGreen => 'Tantancewa ta yi nasara';

  @override
  String get reviewResultRed => 'Tantancewa ta kasa';

  @override
  String get tabAssistant => 'Mataimaki';

  @override
  String get assistantChatHint => 'Message the assistant';

  @override
  String get assistantActionUnavailable => 'Item is no longer available';

  @override
  String get assistantAttachFile => 'Attach file';

  @override
  String get assistantTyping => 'Assistant is thinking…';

  @override
  String get assistantEmptyHint => 'Ask anything — by voice or text';

  @override
  String get assistantToolLoopError =>
      'The assistant couldn\'t complete the request';

  @override
  String get assistantError => 'Something went wrong. Try again';

  @override
  String get assistantConnecting => 'Ana haɗawa…';

  @override
  String get assistantSpeaking => 'Ana magana…';

  @override
  String get assistantListening => 'Ana sauraro…';

  @override
  String get assistantTapToStart => 'Matsa don farawa';

  @override
  String get assistantTapToTalk => 'Matsa don magana da AI';

  @override
  String get assistantRealtimeDesc =>
      'Mataimaki yana amsawa da murya a cikin lokaci na ainihi';

  @override
  String get assistantConnectingToAssistant => 'Ana haɗawa da mataimaki...';

  @override
  String get assistantAiSpeaking => 'AI na magana...';

  @override
  String get assistantAiListening => 'AI na sauraro';

  @override
  String get assistantSpeakerOn => 'Kunna lasifika';

  @override
  String get assistantSpeaker => 'Lasifika';

  @override
  String get assistantEnd => 'Ƙare';

  @override
  String get assistantUnmute => 'Bude murya';

  @override
  String get assistantMicrophone => 'Makirufo';

  @override
  String get assistantConnectionError => 'Kuskuren haɗi';

  @override
  String get tabMessenger => 'Saƙonni';

  @override
  String get tabCalls => 'Kiran waya';

  @override
  String get tabCalendar => 'Kalanda';

  @override
  String get appearance => 'Bayyanar';

  @override
  String get appearanceSelect => 'Zaɓi Jigo';

  @override
  String get themeLight => 'Haske';

  @override
  String get themeDark => 'Duƙu';

  @override
  String get themeSystem => 'Tsarin';

  @override
  String get onboardingTitle1 => 'Shaidar Haɗin Kai';

  @override
  String get onboardingDesc1 =>
      'Taler ID shine fasfo ɗin ku na dijital a cikin tsarin Taler. Asusun guda ɗaya don duk ayyuka.';

  @override
  String get onboardingTitle2 => 'Tsaron Bayanai';

  @override
  String get onboardingDesc2 =>
      'Tabbatar da KYC, ɓoyayyen AES-256, da tabbatarwa ta hanyoyi biyu suna kare shaidar ku.';

  @override
  String get onboardingTitle3 => 'Kasance da Labari';

  @override
  String get onboardingDesc3 =>
      'Sami sanarwa game da matsayin tabbatarwa, shiga daga sabbin na\'urori, da kiran shigowa.';

  @override
  String get onboardingNext => 'Gaba';

  @override
  String get onboardingEnableNotifications => 'Kunna Sanarwa';

  @override
  String get onboardingTitle4 => 'Kiran Murya';

  @override
  String get onboardingDesc4 =>
      'Ba da damar amfani da makirufo don kiran murya da mataimakin AI. Kuna iya canza wannan daga baya a cikin saituna.';

  @override
  String get onboardingEnableMicrophone => 'Kunna Makirufo';

  @override
  String get onboardingStart => 'Fara';

  @override
  String get onboardingSkip => 'Tsallake';

  @override
  String get meshLocalNetworkPromptTitle =>
      'Ba da damar shiga cibiyar sadarwa ta gida';

  @override
  String get meshLocalNetworkPromptBody =>
      'Don nemo abokan hulɗa akan Wi-Fi (kiran rukuni na layi), iOS yana buƙatar izinin Cibiyar Sadarwa ta Gida. Buɗe Saituna → Sirri & Tsaro → Cibiyar Sadarwa ta Gida → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Buɗe Saituna';

  @override
  String get meshLocalNetworkPromptDismiss => 'Na gane';

  @override
  String get forgotPassword => 'Manta kalmar sirri?';

  @override
  String get forgotPasswordTitle => 'Sake saita Kalmar Sirri';

  @override
  String get forgotPasswordSubtitle =>
      'Shigar da imel ɗin ku don karɓar lambar sake saiti';

  @override
  String resetCodeSent(String email) {
    return 'An aika lamba zuwa $email';
  }

  @override
  String get enterResetCode => 'Shigar da lambar';

  @override
  String get resetPasswordButton => 'Sake saita Kalmar Sirri';

  @override
  String get passwordResetSuccess => 'An sake saita kalmar sirri cikin nasara';

  @override
  String get sendCode => 'Aika Lambar';

  @override
  String get resendCode => 'Sake Aika Lambar';

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'We\'ll send a 6-digit code to $email.';
  }

  @override
  String verifyEmailCodeSent(String email) {
    return 'Code sent to $email. Enter it below.';
  }

  @override
  String get verifyEmailSendCode => 'Send Code';

  @override
  String get verifyEmailConfirm => 'Verify';

  @override
  String get verifyEmailResend => 'Resend code';

  @override
  String get verifyEmailSuccess => 'Email verified ✓';

  @override
  String get verifyEmailAlreadyVerified => 'Email is already verified';

  @override
  String get verifyEmailBannerTitle => 'Verify your email';

  @override
  String get verifyEmailBannerSubtitle =>
      'Tap to receive a 6-digit code and confirm your address.';

  @override
  String get newGroup => 'Sabon Rukuni';

  @override
  String get newChat => 'Sabon Tattaunawa';

  @override
  String get groupName => 'Sunan Rukuni';

  @override
  String get createGroup => 'Ƙirƙiri Rukuni';

  @override
  String get groupInfo => 'Bayanin Rukuni';

  @override
  String groupMembers(int count) {
    return 'Mambobi ($count)';
  }

  @override
  String get addMembers => 'Ƙara Mambobi';

  @override
  String get leaveGroup => 'Barin Rukuni';

  @override
  String get leaveGroupConfirm => 'Bar wannan rukuni?';

  @override
  String get deleteGroup => 'Goge Rukuni';

  @override
  String get deleteGroupConfirm =>
      'Goge wannan rukuni? Ba za a iya dawo da shi ba.';

  @override
  String get groupRoleOwner => 'Mai Rukuni';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Mamba';

  @override
  String get selectParticipants => 'Zaɓi mahalarta';

  @override
  String selectedCount(int count) {
    return '$count an zaɓa';
  }

  @override
  String get changeRole => 'Canja Matsayi';

  @override
  String get groupCreated => 'An ƙirƙiri rukuni';

  @override
  String memberJoined(String name) {
    return '$name ya shiga';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name ya bar';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name an cire';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name yanzu $role';
  }

  @override
  String participantsCount(int count) {
    return '$count mahalarta';
  }

  @override
  String get enterGroupName => 'Shigar da sunan rukuni';

  @override
  String get muteNotifications => 'Dakatar da sanarwa';

  @override
  String get unmuteNotifications => 'Sake kunna sanarwa';

  @override
  String get muteFor1Hour => 'Na awa 1';

  @override
  String get muteFor8Hours => 'Na awanni 8';

  @override
  String get muteFor2Days => 'Na kwanaki 2';

  @override
  String get muteForever => 'Har abada';

  @override
  String get muted => 'An dakatar';

  @override
  String get tabTranslator => 'Fassara';

  @override
  String get translatorTitle => 'Mai Fassara';

  @override
  String get translatorSelectLanguage => 'Zaɓi harshe';

  @override
  String get translatorDownloading => 'Ana sauke samfuran harshe...';

  @override
  String get translatorDownloadingHint =>
      'Ana buƙatar intanet ne kawai don sauke na farko';

  @override
  String get translatorTypeHint => 'Rubuta rubutu ko danna makirufo';

  @override
  String get translatorListening => 'Ana saurare...';

  @override
  String get translatorTapToSpeak => 'Danna don magana';

  @override
  String get translatorTapToStop => 'Danna don tsayawa';

  @override
  String get translatorAutoSpeak => 'Magana ta atomatik';

  @override
  String get translatorCopied => 'An kwafi';

  @override
  String get translatorLangRu => 'Rasha';

  @override
  String get translatorLangEn => 'Turanci';

  @override
  String get translatorLangDe => 'Jamus';

  @override
  String get translatorLangFr => 'Faransanci';

  @override
  String get translatorLangEs => 'Sipaniya';

  @override
  String get translatorLangIt => 'Italiyanci';

  @override
  String get translatorLangPt => 'Fotugis';

  @override
  String get translatorLangTr => 'Turkiyya';

  @override
  String get translatorLangZh => 'Sinanci';

  @override
  String get translatorLangJa => 'Jafananci';

  @override
  String get translatorLangKo => 'Koreya';

  @override
  String get translatorLangAr => 'Larabci';

  @override
  String get translatorLangPl => 'Polish';

  @override
  String get translatorLangSk => 'Slovak';

  @override
  String get translatorLangCs => 'Czech';

  @override
  String get translatorLangNl => 'Holanci';

  @override
  String get translatorLangSv => 'Swedish';

  @override
  String get translatorLangDa => 'Danish';

  @override
  String get translatorLangNo => 'Norwegian';

  @override
  String get translatorLangFi => 'Finnish';

  @override
  String get translatorLangUk => 'Ukrainian';

  @override
  String get translatorLangEl => 'Girka';

  @override
  String get translatorLangRo => 'Romaniya';

  @override
  String get translatorLangHu => 'Hungariyanci';

  @override
  String get translatorLangBg => 'Bulgaria';

  @override
  String get translatorLangHr => 'Kuroshiya';

  @override
  String get translatorLangSr => 'Serbiya';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Thai';

  @override
  String get translatorLangVi => 'Biyetinam';

  @override
  String get translatorLangId => 'Indonesiya';

  @override
  String get translatorLangMs => 'Malayu';

  @override
  String get translatorLangHe => 'Ibrananci';

  @override
  String get translatorLangFa => 'Farisa';

  @override
  String get callInProgress => 'Ana ci gaba da kira';

  @override
  String get joinCall => 'Shiga';

  @override
  String get createCallLink => 'Link ɗin kira';

  @override
  String get callLinkCopied => 'An kwafi link';

  @override
  String get callLinkTitle => 'Link ɗin ɗaki';

  @override
  String get connectionUnstable => 'Haɗin bai da ƙarfi — duba intanet ɗinka';

  @override
  String get today => 'Yau';

  @override
  String get yesterday => 'Jiya';

  @override
  String get errorTimeout => 'Haɗin ya ƙare. Duba haɗin intanet ɗinka.';

  @override
  String get errorNoConnection => 'Babu haɗin intanet.';

  @override
  String get errorGeneral => 'An samu kuskure. Da fatan a sake gwadawa.';

  @override
  String errorWithMessage(String message) {
    return 'Kuskure: $message';
  }

  @override
  String get notifChannelMessages => 'Saƙonni';

  @override
  String get notifChannelMessagesDesc => 'Sanarwar sabon saƙo';

  @override
  String get notifChannelMissedCalls => 'Kiran da aka rasa';

  @override
  String get notifChannelMissedCallsDesc => 'Sanarwar kiran da aka rasa';

  @override
  String get notifMissedCall => 'Kiran da aka rasa';

  @override
  String get notifAccept => 'Karɓa';

  @override
  String get notifDecline => 'Ƙi';

  @override
  String get notifIncomingCall => 'Kiran shigowa';

  @override
  String get notifIncomingCallChannel => 'Kiran shigowa';

  @override
  String get notifMissedCallChannel => 'Kiran da aka rasa';

  @override
  String get notifUnknown => 'Ba a sani ba';

  @override
  String get effectNone => 'Babu bango';

  @override
  String get effectBlur => 'Duhu';

  @override
  String get effectOffice => 'Ofis';

  @override
  String get effectNature => 'Yanayi';

  @override
  String get effectGradient => 'Gradient';

  @override
  String get effectLibrary => 'Dakin karatu';

  @override
  String get effectCity => 'Birni';

  @override
  String get effectMinimalism => 'Minimalism';

  @override
  String get voiceParticipant => 'Mai halarta';

  @override
  String get voiceInvitesToRoom => 'yana gayyatarka zuwa ɗakin';

  @override
  String get voiceRoom => 'Ɗaki';

  @override
  String get voicePasswordProtected => 'An kiyaye da kalmar sirri';

  @override
  String get voicePasswordHint => 'Kalmar sirri';

  @override
  String get voiceEnter => 'Shiga';

  @override
  String get voiceJoinRoom => 'Shiga ɗakin';

  @override
  String get voiceYourName => 'Sunan ka';

  @override
  String voiceInvitationSent(String name) {
    return 'An aika gayyata zuwa $name';
  }

  @override
  String get voiceNoActiveRoom => 'Babu ɗaki mai aiki';

  @override
  String get voiceCameraPermission =>
      'Bada izinin amfani da kyamara a Saituna → Sirri → Kyamara → TalerID';

  @override
  String get voiceOpenSettings => 'Buɗe';

  @override
  String voiceCameraError(String error) {
    return 'An kasa kunna kyamara: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Duk sun yarda. An fara rikodi.';

  @override
  String get voiceNewParticipantAgreed => 'Sabon mahalarta ya yarda da rikodi.';

  @override
  String get voiceDeclinedRecording => 'Ka ƙi rikodi. Barin kiran.';

  @override
  String get voiceRecordingEnded => 'An gama rikodi';

  @override
  String get voiceRecordingInProgress => 'Rikodi yana gudana';

  @override
  String get voiceTranscriptionRequest => 'Neman rubutun magana';

  @override
  String get voiceRecordingRequest => 'Neman rikodi';

  @override
  String get voiceAgree => 'Yarda';

  @override
  String get voiceDeclineAndLeave => 'Ki yarda kuma bar';

  @override
  String get voiceAudioOutput => 'Fitar sauti';

  @override
  String get voiceAudioPhone => 'Waya';

  @override
  String get voiceAudioSpeaker => 'Makarar magana';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Lasifikan kunne';

  @override
  String get voiceLinkCopied => 'An kwafi mahaɗin';

  @override
  String get voiceTranslateTo => 'Fassara zuwa';

  @override
  String get voiceSearchLanguage => 'Neman harshe...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Daki $name';
  }

  @override
  String get voiceVoiceCall => 'Kiran murya';

  @override
  String get voiceOnHold => 'A jira';

  @override
  String get voiceActiveCall => 'Aiki';

  @override
  String get voiceEndAllCalls => 'Gama duk kiran';

  @override
  String get voiceEndThisCall => 'Gama wannan kiran';

  @override
  String get voiceCopyLink => 'Kwafi mahaɗin';

  @override
  String get voiceAddParticipant => 'Ƙara mahalarta';

  @override
  String get voiceReconnecting => 'Sake haɗawa...';

  @override
  String get voiceConnectionError => 'Kuskuren haɗi';

  @override
  String get voiceClose => 'Rufe';

  @override
  String get voiceCalling => 'Ana kira...';

  @override
  String get voiceCallActive => 'Kira yana aiki';

  @override
  String get voiceWaiting => 'Jiran';

  @override
  String get voiceWaitingUpper => 'JIRAN';

  @override
  String get voiceRec => 'RIKO';

  @override
  String get voiceStop => 'Tsaya';

  @override
  String get voiceRecord => 'Rikodi';

  @override
  String get voiceTranslation => 'Fassara';

  @override
  String get voiceAudio => 'Sauti';

  @override
  String get voiceFlipCamera => 'Juya';

  @override
  String get voiceBackground => 'Bango';

  @override
  String get voiceAssistantSpeakingStatus => 'Mataimaki yana magana...';

  @override
  String get voiceAssistantListeningStatus => 'Mataimaki yana sauraro...';

  @override
  String get voiceUnmute => 'Bude murya';

  @override
  String get voiceMic => 'Makirufo';

  @override
  String get voiceAssistantLabel => 'Mataimaki';

  @override
  String get voiceCameraOn => 'Kamera a kunne';

  @override
  String get voiceCameraLabel => 'Kamera';

  @override
  String get voiceEndCall => 'Ƙarshen kira';

  @override
  String get voiceWaitingParticipants => 'Ana jiran mahalarta...';

  @override
  String get voiceYou => 'Kai';

  @override
  String get voiceAiAssistant => 'AI Mataimaki';

  @override
  String get voiceVideoUnavailable => 'Bidiyo ba ya samuwa';

  @override
  String get voiceSearchNickname => 'Nemo ta laƙabi...';

  @override
  String get voiceTranscriptionWord => 'rubutawa';

  @override
  String get voiceRecordingWord => 'rikodi';

  @override
  String get voiceConnecting => 'Ana haɗawa...';

  @override
  String get voiceVideoBackground => 'Bango na bidiyo';

  @override
  String get voiceCallSettings => 'Saitunan kira';

  @override
  String get voiceEnableAI => 'Kunna AI mataimaki';

  @override
  String get voiceAIParticipating => 'AI zai shiga cikin tattaunawa';

  @override
  String get voiceNormalCall => 'Kira na al\'ada ba tare da AI ba';

  @override
  String get voiceCallConfirm => 'Yi kira?';

  @override
  String get chatAlreadyInCall => 'Tuni a cikin kira';

  @override
  String chatCallError(String error) {
    return 'Kuskuren kira: $error';
  }

  @override
  String get chatPhotoVideo => 'Hoto / Bidiyo';

  @override
  String get chatCamera => 'Kamera';

  @override
  String get chatFile => 'Fayil';

  @override
  String get chatContact => 'Tuntuɓi';

  @override
  String get chatSelectContact => 'Zaɓi tuntuɓi';

  @override
  String get chatNoContacts => 'Babu tuntuɓi';

  @override
  String get chatUser => 'Mai amfani';

  @override
  String get chatFileAttachment => '📎 Fayil';

  @override
  String chatFileUploadError(String error) {
    return 'Kuskuren ɗora fayil: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Saƙon murya';

  @override
  String get chatGroup => 'Rukuni';

  @override
  String get chatDialog => 'Tattaunawa';

  @override
  String get chatCall => 'Kira';

  @override
  String get chatStartConversation => 'Fara tattaunawa';

  @override
  String get chatYou => 'Kai';

  @override
  String get chatIsTyping => 'yana rubutu...';

  @override
  String chatUserIsTyping(String name) {
    return '$name yana rubutu...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names suna rubutu...';
  }

  @override
  String get chatPreparingFile => 'Ana shirya fayil…';

  @override
  String chatUploading(int progress) {
    return 'Ana ɗora… $progress%';
  }

  @override
  String get chatEdited => 'An gyara';

  @override
  String get chatViaMesh => 'ta hanyar mesh';

  @override
  String get chatReply => 'Amsa';

  @override
  String get chatEdit => 'Gyara';

  @override
  String get chatCopy => 'Kwafi';

  @override
  String get chatCopied => 'An kwafi';

  @override
  String get chatSaveMedia => 'Ajiye';

  @override
  String get chatForward => 'Mika';

  @override
  String get chatSaving => 'Ana ajiye...';

  @override
  String get chatSavedToGallery => 'An ajiye a gallery';

  @override
  String get chatNoSavePermission => 'Babu izinin ajiya. Duba saituna.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Kuskuren ajiye fayil';

  @override
  String get chatDeleteMessage => 'Goge saƙo';

  @override
  String get chatDeleteForMe => 'Goge a gare ni';

  @override
  String get chatDeleteForEveryone => 'Goge ga kowa';

  @override
  String get chatMessageForwarded => 'An mika saƙo';

  @override
  String get chatContactTapToOpen => 'Tuntuɓi · danna don buɗewa';

  @override
  String get chatForwardTo => 'Mika zuwa...';

  @override
  String get chatSearchHint => 'Bincika...';

  @override
  String get chatRecording => 'Ana rikodi...';

  @override
  String get chatMessageHint => 'Saƙo...';

  @override
  String get chatHideKeyboard => 'Boye madannai';

  @override
  String get chatEditing => 'Ana gyara';

  @override
  String get chatFileDownloadError => 'Kuskuren sauke fayil';

  @override
  String get chatVoiceMessageShort => 'Saƙon murya';

  @override
  String get chatVideoSavedToGallery => 'An ajiye bidiyo a gallery';

  @override
  String get chatSavingError => 'Kuskuren ajiya';

  @override
  String get convSetNickname => 'Saita sunan lakabi';

  @override
  String get convNicknameRequired =>
      'Ana buƙatar sunan lakabi don amfani da manzo. Sauran masu amfani za su iya samun ku da shi.';

  @override
  String get convNicknameRules => 'Haruffa 3–30: haruffa, lambobi, _';

  @override
  String get convNicknameTaken => 'An riga an ɗauki sunan lakabi';

  @override
  String get convSaveError => 'Kuskuren ajiya';

  @override
  String get convContactsLabel => 'Tuntuɓi';

  @override
  String get convDefaultUser => 'Mai amfani';

  @override
  String get convNoDialogs => 'Babu tattaunawa';

  @override
  String get convFindUserToChat => 'Nemo mai amfani don fara hira';

  @override
  String get convDefaultContact => 'Tuntuɓi';

  @override
  String get dashboardUser => 'Mai amfani';

  @override
  String get dashboardIncomingCall => 'Kiran shigowa';

  @override
  String get dashboardDecline => 'Ki yarda';

  @override
  String get dashboardAccept => 'Karɓa';

  @override
  String get dashboardActiveCall => 'Kiran aiki — danna don dawowa';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Sabuntawa akwai $version';
  }

  @override
  String get dashboardUpdate => 'Sabuntawa';

  @override
  String get dashboardWhatsNew => 'Menene sabo';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Menene sabo a $version';
  }

  @override
  String get dashboardInstalling => 'Ana girkawa...';

  @override
  String get updateInstallConflictTitle => 'Couldn\'t update in place';

  @override
  String updateInstallConflictBody(String filename) {
    return 'The installed version is signed with a different certificate, so Android refuses to update it. Uninstall the app via Settings → Apps → Taler ID, then open the Downloads folder in your file manager and tap $filename to install fresh. This step is only needed once.';
  }

  @override
  String get updateInstallFailedTitle => 'Install failed';

  @override
  String updateInstallFailedBody(String reason, String filename) {
    return '$reason\n\nThe APK was saved to your Downloads folder as $filename — you can try installing it manually from a file manager.';
  }

  @override
  String get updateInstallOk => 'OK';

  @override
  String get contactRequestsTitle => 'Tuntuɓi';

  @override
  String get messengerContactRequestsSection => 'Buƙatun tuntuɓa';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buƙatu sabbi',
      one: 'buƙata 1 sabuwa',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Bincika';

  @override
  String get contactRequestsIncoming => 'Shigowa';

  @override
  String get contactRequestsSent => 'An aika';

  @override
  String get contactRequestsSearchHint => 'Sunan lakabi ko imel';

  @override
  String get contactRequestSent => 'An aika buƙata';

  @override
  String get contactRequestsNoUsers => 'Babu masu amfani da aka samu';

  @override
  String get contactRequestsSearchHelp =>
      'Shigar da sunan lakabi ko imel daidai\nkuma danna bincika';

  @override
  String get contactRequestsSendTooltip => 'Aika buƙata';

  @override
  String get contactRequestTitle => 'Buƙatar tuntuɓa';

  @override
  String contactRequestConfirm(String name) {
    return 'Aika buƙatar tuntuɓa zuwa $name?';
  }

  @override
  String get contactRequestSend => 'Aika';

  @override
  String get contactRequestsNoIncoming => 'Babu buƙatun shigowa';

  @override
  String get contactRequestsNoSent => 'Babu buƙatun da aka aika';

  @override
  String get contactRequestStatusPending => 'Ana jiran amsa';

  @override
  String get contactRequestStatusAccepted => 'An karɓa';

  @override
  String get contactRequestStatusRejected => 'An ƙi';

  @override
  String get userSearchTitle => 'Nemo mai amfani';

  @override
  String get userSearchHint => 'Sunan lakabi, waya ko imel';

  @override
  String get userSearchHelper =>
      'Shigar da @nickname, imel ko suna don bincika';

  @override
  String get userSearchNoUsers => 'Babu masu amfani da aka samu';

  @override
  String get userProfileShareContact => 'Raba tuntuɓa';

  @override
  String get userProfileShareContactDesc => 'Aika hanyar tuntuɓa';

  @override
  String get userProfileCopyLink => 'Kwafi hanyar';

  @override
  String get userProfileCopied => 'An kwafi';

  @override
  String get userProfileTitle => 'Bayanan martaba';

  @override
  String get userProfileLoadError => 'Kuskuren ɗaukar bayanin martaba';

  @override
  String get userProfileMessage => 'Saƙo';

  @override
  String get userProfileCall => 'Kira';

  @override
  String get userProfileRequestSent => 'An aika buƙata';

  @override
  String get userProfileAccept => 'Karɓa';

  @override
  String get userProfileDecline => 'Ki yarda';

  @override
  String get userProfileAddToContacts => 'Ƙara zuwa lambobi';

  @override
  String get userProfileMediaTab => 'Kafofin watsa labarai';

  @override
  String get userProfileFilesTab => 'Fayiloli';

  @override
  String get userProfileLinksTab => 'Hanyoyin haɗi';

  @override
  String get userProfileRecordingsTab => 'Rakodi';

  @override
  String get userProfileSummariesTab => 'Taƙaitawa';

  @override
  String get userProfileNoMedia => 'Babu fayilolin kafofin watsa labarai';

  @override
  String get userProfileNoFiles => 'Babu fayiloli';

  @override
  String get userProfileNoLinks => 'Babu hanyoyin haɗi';

  @override
  String get userProfileNoRecordings => 'Babu rakodi';

  @override
  String get userProfileNoSummaries => 'Babu taƙaitawa';

  @override
  String get userProfileMeetingSummary => 'Taƙaitaccen taro';

  @override
  String get userProfileFailedOpenChat => 'An kasa buɗe tattaunawa';

  @override
  String get sharedMediaTitle => 'Kafofin watsa labarai da fayiloli';

  @override
  String get sharedMediaTab => 'Kafofin watsa labarai';

  @override
  String get sharedFilesTab => 'Fayiloli';

  @override
  String get sharedLinksTab => 'Hanyoyin haɗi';

  @override
  String get sharedNoMedia => 'Babu fayilolin kafofin watsa labarai';

  @override
  String get sharedNoFiles => 'Babu fayiloli';

  @override
  String get sharedNoLinks => 'Babu hanyoyin haɗi';

  @override
  String get shareToChat => 'Mika zuwa tattaunawa';

  @override
  String get shareSelectChat => 'Zaɓi tattaunawa';

  @override
  String get shareNoChats => 'Babu tattaunawa';

  @override
  String shareFilesCount(int count) {
    return '$count fayiloli';
  }

  @override
  String get contactsTitle => 'Lambobi';

  @override
  String get contactsAddTooltip => 'Ƙara lamba';

  @override
  String get contactsSearchHint => 'Nemo lambobi...';

  @override
  String get contactsNotFound => 'Babu abin da aka samu';

  @override
  String get contactsEmpty => 'Babu lambobi';

  @override
  String get contactsAdd => 'Ƙara lamba';

  @override
  String get contactsPendingConfirmation => 'Ana jiran tabbaci';

  @override
  String get contactsMessage => 'Saƙo';

  @override
  String get contactsCall => 'Kira';

  @override
  String get contactsResend => 'Sake aika buƙata';

  @override
  String get contactsResendTimeout => 'Sake gwadawa a cikin sa\'o\'i 24';

  @override
  String get contactsResent => 'An sake aikawa';

  @override
  String get contactsWantsToConnect => 'Na so haɗuwa da kai';

  @override
  String get contactsSearchPeople => 'Nemo mutane';

  @override
  String get notesTitle => 'Bayanan kula';

  @override
  String get notesAssistantSpeaking => 'Mataimaki yana magana...';

  @override
  String get notesListening => 'Sauraro...';

  @override
  String get notesEmpty => 'Babu bayanan kula';

  @override
  String get notesEmptyHint =>
      'Danna makirufo don rubutu\nt ko + don shigarwa da hannu';

  @override
  String get notesDeleteConfirm => 'Share bayanin kula?';

  @override
  String get notesNew => 'Sabon bayanin kula';

  @override
  String get notesEdit => 'Gyara';

  @override
  String get notesTitleHint => 'Suna';

  @override
  String get notesContentHint => 'Rubuta tunaninka...';

  @override
  String get calendarTitle => 'Kalanda';

  @override
  String get calendarStop => 'Tsaya';

  @override
  String get calendarVoiceInput => 'Shigar murya';

  @override
  String get calendarNewEvent => 'Sabon taron';

  @override
  String get calendarAssistantSpeaking => 'Mataimaki yana magana...';

  @override
  String get calendarListening => 'Sauraro...';

  @override
  String calendarInvitations(int count) {
    return 'Gayyata ($count)';
  }

  @override
  String get calendarNoEvents => 'Babu taruka';

  @override
  String get calendarDayMon => 'Lit';

  @override
  String get calendarDayTue => 'Tal';

  @override
  String get calendarDayWed => 'Lar';

  @override
  String get calendarDayThu => 'Alh';

  @override
  String get calendarDayFri => 'Jum';

  @override
  String get calendarDaySat => 'Asa';

  @override
  String get calendarDaySun => 'Lah';

  @override
  String get calendarEnterRoom => 'Shiga ɗakin';

  @override
  String get calendarMeeting => 'Taro';

  @override
  String calendarLocationPrefix(String location) {
    return 'Wuri: $location';
  }

  @override
  String get calendarEditEvent => 'Gyara';

  @override
  String get calendarTitleHint => 'Suna';

  @override
  String get calendarDescriptionHint => 'Bayani';

  @override
  String get calendarTypeEvent => 'Taro';

  @override
  String get calendarTypeMeeting => 'Taro';

  @override
  String get calendarTypeReminder => 'Tunatarwa';

  @override
  String get calendarKindEvent => 'Event';

  @override
  String get calendarKindTask => 'Task';

  @override
  String get calendarTaskMarkDone => 'Mark done';

  @override
  String get calendarTaskDelete => 'Delete';

  @override
  String get calendarTaskDoneMsg => 'Task completed';

  @override
  String get calendarTaskDeletedMsg => 'Task deleted';

  @override
  String get calendarTypeLabel => 'Nau\'i';

  @override
  String get calendarMeetingLink => 'Hadin taro';

  @override
  String get calendarLocationHint => 'Wuri';

  @override
  String get calendarDateLabel => 'Kwanan wata';

  @override
  String get calendarTimeLabel => 'Lokaci';

  @override
  String get calendarReminderLabel => 'Tunatarwa';

  @override
  String get calendarReminderNone => 'Babu';

  @override
  String get calendarReminder15min => '15 min kafin';

  @override
  String get calendarReminder30min => '30 min kafin';

  @override
  String get calendarReminder1hour => '1 awa kafin';

  @override
  String get calendarRepeatLabel => 'Maimaici';

  @override
  String get calendarRepeatNone => 'Babu maimaitawa';

  @override
  String get calendarRepeatDaily => 'Kowace rana';

  @override
  String get calendarRepeatWeekly => 'Kowane mako';

  @override
  String get calendarRepeatMonthly => 'Kowane wata';

  @override
  String get calendarRepeatYearly => 'Kowace shekara';

  @override
  String get calendarParticipants => 'Masu halarta';

  @override
  String get calendarAddParticipant => 'Ƙara';

  @override
  String get calendarSearchContacts => 'Nemo lambobi...';

  @override
  String get calendarNoContacts => 'Babu lambobi';

  @override
  String get calendarStatusAccepted => 'An amince';

  @override
  String get calendarStatusDeclined => 'An ƙi';

  @override
  String get calendarStatusMaybe => 'Watakila';

  @override
  String get calendarStatusPending => 'Ana jiran amsa';

  @override
  String get calendarEndTime => 'Lokacin ƙarewa';

  @override
  String get calendarYourAnswer => 'Amsarka:';

  @override
  String get calendarOrganizer => 'Mai shirya';

  @override
  String calendarDeleteError(String error) {
    return 'An kasa sharewa: $error';
  }

  @override
  String get calendarRsvpAccept => 'Amince';

  @override
  String get calendarRsvpMaybe => 'Watakila';

  @override
  String get calendarRsvpDecline => 'Ƙi';

  @override
  String get callHistoryTitle => 'Kiran waya';

  @override
  String get callHistoryTab => 'Tarihin kira';

  @override
  String get callHistoryTempMeeting => 'Taron wucin gadi';

  @override
  String get callHistoryCopy => 'Kwafi';

  @override
  String get callHistoryLinkCopied => 'An kwafi hanyar';

  @override
  String get callHistoryShare => 'Raba';

  @override
  String get callHistoryEnter => 'Shiga';

  @override
  String get callHistoryAlreadyInCall => 'Tuni a cikin kira';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Ba a iya tantance ɗayan ɓangaren ba';

  @override
  String get callHistoryContacts => 'Lambobi';

  @override
  String get callHistoryFailedLoadRoom => 'An kasa ɗauko ɗakin ku';

  @override
  String get callHistoryYourRoom => 'Dakin ku';

  @override
  String get callHistoryCreateMeeting => 'Ƙirƙiri taro';

  @override
  String get callHistoryMeetingSummaries => 'Takaitaccen taro';

  @override
  String get callHistoryMeetingRecordings => 'Rakodin taro';

  @override
  String get callHistoryNoCalls => 'Babu kira';

  @override
  String get callHistoryMissed => 'An rasa';

  @override
  String get callHistoryRecording => 'Rakodi';

  @override
  String get callHistorySummary => 'Takaitawa';

  @override
  String get callHistoryCallAgain => 'Kira sake';

  @override
  String callHistoryTodayTime(String time) {
    return 'Yau, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Jiya, $time';
  }

  @override
  String get callHistoryUnknown => 'Ba a sani ba';

  @override
  String get callHistoryDetails => 'Cikakken bayani na kira';

  @override
  String get callHistoryOutgoing => 'Kiran fita';

  @override
  String get callHistoryIncoming => 'Kiran shigowa';

  @override
  String callHistoryDuration(String duration) {
    return 'Tsawon lokaci: $duration';
  }

  @override
  String get callHistoryWithAI => 'Tare da mataimakin AI';

  @override
  String get callHistoryParticipants => 'Masu halarta';

  @override
  String get callDetailYouSuffix => '(Kai)';

  @override
  String get callHistoryMeetingSummary => 'Takaitaccen taro';

  @override
  String get callHistoryMoreDetails => 'Karin bayani';

  @override
  String get callHistorySummaryProcessing => 'Ana sarrafa takaitawa...';

  @override
  String get callHistoryMeetingRecording => 'Rakodin taro';

  @override
  String get callHistoryProcessing => 'Ana sarrafawa...';

  @override
  String get callHistoryCreateTranscript => 'Ƙirƙiri rubutun magana';

  @override
  String get callHistoryNoSummaries => 'Babu takaitawa';

  @override
  String get callHistoryRecordDuringCall => 'Danna \"Rakodi\" yayin kira';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Taro $time';
  }

  @override
  String get callHistoryTranscribing => 'Ana rubuta magana da takaitawa...';

  @override
  String get callHistoryTranscriptCreated => 'An ƙirƙiri rubutun magana';

  @override
  String get callHistoryNoRecordings => 'Babu rakodi';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Rakodi $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Rakodin ba ya samuwa';

  @override
  String get callHistoryTranscriptReady => 'Rubutun magana a shirye';

  @override
  String get callHistoryTranscript => 'Rubutun magana';

  @override
  String get callHistoryKeyPoints => 'Muhimman maki';

  @override
  String get callHistoryTasks => 'Ayyuka';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'An sanya wa: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Shawara';

  @override
  String get callHistoryShowTranscript => 'Nuna cikakken rubutun magana';

  @override
  String get profileScanQr => 'Duba QR';

  @override
  String get profileMyQrCode => 'QR kaina';

  @override
  String profileAddMeShare(String userId) {
    return 'Ƙara ni a Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Nuna wannan lambar don ƙara ku';

  @override
  String get profileEditDesc => 'Suna, sunan mahaifi, sunan uba, ranar haihuwa';

  @override
  String get profileAboutMe => 'Game da ni';

  @override
  String get profileAboutMeDesc => 'Dabi\'u, kwarewa, sha\'awa da ƙari';

  @override
  String get profileNotes => 'Bayanan kula';

  @override
  String get profileNotesDesc => 'Tunani, ra\'ayoyi da bayanan kula';

  @override
  String get profileAvatarUpdated => 'An sabunta hoto';

  @override
  String get profileNickname => 'Sunan lakabi';

  @override
  String get profileNotSet => 'Ba a saita ba';

  @override
  String get profileChangeNickname => 'Canja sunan lakabi';

  @override
  String get profileNicknameUpdated => 'An sabunta sunan lakabi';

  @override
  String get profileShareLabel => 'Raba';

  @override
  String get profileScanQrCode => 'Duba lambar QR';

  @override
  String get profilePointCamera => 'Nuna kyamara a lambar QR';

  @override
  String get profilePhotoCamera => 'Dauki hoto';

  @override
  String get profilePhotoGallery => 'Zaɓi daga hotunan';

  @override
  String get editProfilePatronymic => 'Sunan uba (na zaɓi)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'Game da ni';

  @override
  String get aboutMeClickToFill => 'Danna don cika';

  @override
  String get aboutMeCoreValues => 'Dabi\'u';

  @override
  String get aboutMeWorldview => 'Ra\'ayin duniya';

  @override
  String get aboutMeSkills => 'Kwarewa';

  @override
  String get aboutMeInterests => 'Sha\'awa';

  @override
  String get aboutMeDesires => 'Buruka';

  @override
  String get aboutMeBackground => 'Bayanin martaba';

  @override
  String get aboutMeLikes => 'Abubuwan da nake so';

  @override
  String get aboutMeDislikes => 'Abubuwan da bana so';

  @override
  String get aboutMeDeleteSection => 'Share sashe?';

  @override
  String get aboutMeDeleteConfirm =>
      'Dukkan bayanan da ke cikin wannan sashe za su bace.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Kuskuren haɗi: $error';
  }

  @override
  String get aboutMeVisibility => 'Bayyanawa';

  @override
  String get aboutMeTags => 'Alamomi';

  @override
  String get aboutMeAddTag => 'Ƙara alama...';

  @override
  String get aboutMeDescription => 'Bayani';

  @override
  String get aboutMeDescribeLong => 'Faɗa mana ƙarin bayani...';

  @override
  String get aboutMeVisibilityEveryone => 'Kowa';

  @override
  String get aboutMeVisibilityContacts => 'Abokan hulɗa';

  @override
  String get aboutMeVisibilityOnlyMe => 'Ni kaɗai';

  @override
  String get settingsProfileSubtitle => 'Bayanin martaba';

  @override
  String get settingsWallpaper => 'Hoton bango';

  @override
  String get settingsWallpaperDesc => 'Hoton bango don dukkan app';

  @override
  String get settingsWallpaperNone => 'Babu';

  @override
  String get settingsAccount => 'Asusu';

  @override
  String get settingsKycVerification => 'Tabbatar da Shaida (KYC)';

  @override
  String get settingsOrganizations => 'Ƙungiyoyi';

  @override
  String get incomingCallLabel => 'Kiran shigowa';

  @override
  String get incomingCallDecline => 'Ƙi';

  @override
  String get incomingCallAccept => 'Karɓa';

  @override
  String callGlareTitle(String name) {
    return '$name is also calling you';
  }

  @override
  String get callGlareBody =>
      'You both dialled each other at the same moment. Pick up theirs or stay on yours?';

  @override
  String get callGlareSwitch => 'Pick up theirs';

  @override
  String get callGlareKeepOwn => 'Stay on mine';

  @override
  String get meshIncomingCallLabel => '📡 Kiran mesh shigowa';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Na\'urar mesh $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Gama kiran da ake yi yanzu';

  @override
  String get callPopupTransportTitle => 'Kira ta';

  @override
  String get callPopupTransportMesh => '📡 Mesh (peer-to-peer)';

  @override
  String get callPopupTransportLk => '📞 Uwar garke';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Ba za a iya samun lamba ta mesh ba';

  @override
  String get meshOnboardingTitle => '📡 Kiran mesh yana buƙatar app a buɗe';

  @override
  String get meshOnboardingBody =>
      'Idan an kulle wayar, kiran mesh na iya yankewa bayan ~30 seconds (ƙuntatawar iOS).';

  @override
  String get meshOnboardingAck => 'Na gane';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Lamba ba ta cikin jerin ku';

  @override
  String get meshCallStatusInviting => 'Ana kira…';

  @override
  String get meshCallStatusConnecting => 'Ana haɗawa…';

  @override
  String get meshCallEndedUserHangup => 'An gama kiran';

  @override
  String get meshCallEndedRemoteHangup => 'An gama daga ɗayan ɓangaren';

  @override
  String get meshCallEndedRejected => 'An ƙi';

  @override
  String get meshCallEndedNoAnswer => 'Babu amsa';

  @override
  String get meshCallEndedConnectionLost => 'An rasa haɗi';

  @override
  String get meshCallEndedError => 'Matsalar haɗi';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Kiran mesh mai dogaro';

  @override
  String get batteryExemptionBody =>
      'Bada izinin app ɗin ya gudana ba tare da ƙuntatawar batir ba don Android ba ya kashe mesh a bango.';

  @override
  String get batteryExemptionAccept => 'Buɗe saituna';

  @override
  String get batteryExemptionDismiss => 'Ba yanzu ba';

  @override
  String get groupCamera => 'Kamara';

  @override
  String get groupGallery => 'Hotuna';

  @override
  String get groupAvatarUpdated => 'An sabunta hoton rukuni';

  @override
  String get groupNameTitle => 'Sunan rukuni';

  @override
  String get groupEnterName => 'Shigar da suna';

  @override
  String get groupDescriptionTitle => 'Bayanin rukuni';

  @override
  String get groupEnterDescription => 'Shigar da bayanin rukuni';

  @override
  String get groupChangeRoleTitle => 'Canza matsayi';

  @override
  String get groupRemoveMemberTitle => 'Cire memba';

  @override
  String get groupDescription => 'Bayanin';

  @override
  String get groupAddDescription => 'Ƙara bayanin rukuni';

  @override
  String get groupNoDescription => 'Babu bayani';

  @override
  String get groupMediaAndFiles => 'Kafofi da fayiloli';

  @override
  String get groupMuteNotifications => 'Kashe sanarwa';

  @override
  String get groupMuted => 'An kashe';

  @override
  String get groupNoResults => 'Babu sakamako';

  @override
  String get authInvalidCode => 'Lambar ba daidai ba ce. Gwada sake.';

  @override
  String get loginSubtitle => 'Yi amfani da imel da kalmar sirri';

  @override
  String get emailRequired => 'Shigar da imel';

  @override
  String get emailInvalid => 'Imel ba daidai ba';

  @override
  String get passwordRequired => 'Shigar da kalmar sirri';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Asusu ɗaya don dukkan tsarin Taler';

  @override
  String get usernameOptional => 'Sunan mai amfani (na zaɓi)';

  @override
  String get usernameMinLength => 'Aƙalla haruffa 3';

  @override
  String get usernameMaxLength => 'Mafi yawa haruffa 30';

  @override
  String get usernameInvalid => 'Haruffa, lambobi da _ kawai';

  @override
  String get biometricLoginReason => 'Shiga Taler ID';

  @override
  String get docTypePassport => 'Fasfo';

  @override
  String get docTypeIdCard => 'Katun Shaida';

  @override
  String get docTypeDriverLicense => 'Lasisin Tuƙi';

  @override
  String get docTypeResidencePermit => 'Izinin Zama';

  @override
  String addressApartment(String number) {
    return 'apt. $number';
  }

  @override
  String get failedToUpdateProfile => 'An kasa sabunta bayanin martaba';

  @override
  String get failedToStartKyb => 'An kasa fara tantancewar KYB';

  @override
  String get orgUpdated => 'An sabunta ƙungiya';

  @override
  String get failedToUpdateOrg => 'An kasa sabunta ƙungiya';

  @override
  String get failedToChangeRole => 'An kasa canza matsayi';

  @override
  String get failedToRemoveMember => 'An kasa cire memba';

  @override
  String get capabilityMessagesTitle => 'Saƙonni';

  @override
  String get capabilityMessagesDesc =>
      'Duba saƙonni ko rubuta wa wani. Misali: \"Rubuta wa Viktor: zan zo cikin awa ɗaya\"';

  @override
  String get capabilityCallsTitle => 'Kiran waya';

  @override
  String get capabilityCallsDesc =>
      'Kira kowane lamba ta murya. Misali: \"Kira Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Tarihin Tattaunawa';

  @override
  String get capabilityChatDesc =>
      'Zan bincika tarihin tattaunawa. Misali: \"Me muka tattauna da Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Bayanin Kai';

  @override
  String get capabilityProfileDesc =>
      'Zan nuna ko sabunta bayanin ka. Misali: \"Nuna bayanin kai na\"';

  @override
  String get capabilityCoachingTitle => 'Koyarwa';

  @override
  String get capabilityCoachingDesc =>
      'Yanayi: Koyarwar ICF, masanin halayyar dan Adam, shawarar HR. Ce: \"Mu yi koyarwa\"';

  @override
  String get capabilityCalendarTitle => 'Kalanda';

  @override
  String get capabilityCalendarDesc =>
      'Tsara taro ko saita tunatarwa. Misali: \"Tsara taro da Viktor gobe da karfe 15:00\"';

  @override
  String get capabilityNotesTitle => 'Bayanan kula';

  @override
  String get capabilityNotesDesc =>
      'Ajiye tunani ko karanta bayanan kula na baya-bayan nan. Misali: \"Rubuta wata ra\'ayi...\" ko \"Karanta bayanan kula na baya-bayan nan\"';

  @override
  String get assistantCallConfirm => 'Yi kira?';

  @override
  String get callNoAnswer => 'Babu amsa';

  @override
  String get contactDelete => 'Cire lamba';

  @override
  String get contactDeleteTitle => 'Cire lamba';

  @override
  String get contactDeleteConfirm => 'Ka tabbata? Za a cire wannan lamba.';

  @override
  String get contactBlock => 'Toshe';

  @override
  String get contactBlockTitle => 'Toshe mai amfani';

  @override
  String get contactBlockConfirm =>
      'Wannan mai amfani ba zai iya aika saƙo ko kira ka ba.';

  @override
  String get contactUnblock => 'Bude toshewa';

  @override
  String get contactBlocked => 'An toshe';

  @override
  String get contactYouAreBlocked => 'Wannan mai amfani ya toshe ka';

  @override
  String get chatBlockedByYou => 'Ka toshe wannan mai amfani';

  @override
  String get chatYouAreBlocked => 'An toshe ka daga wannan mai amfani';

  @override
  String get chatNotContacts =>
      'Kara wannan mai amfani zuwa lambobi don aika saƙo';

  @override
  String get contactRevokeRequest => 'Janye buƙata';

  @override
  String get messengerPoll => 'Zaben ra\'ayi';

  @override
  String get messengerCreatePoll => 'Ƙirƙiri Zaben ra\'ayi';

  @override
  String get messengerPollQuestion => 'Tambaya';

  @override
  String messengerPollOption(int number) {
    return 'Zaɓi $number';
  }

  @override
  String get messengerPollAddOption => 'Ƙara zaɓi';

  @override
  String get messengerPollAnonymous => 'Zaben ra\'ayi ba tare da suna ba';

  @override
  String get messengerPollMultiple => 'Zaɓuɓɓuka da yawa';

  @override
  String get messengerPollCreateError => 'An kasa ƙirƙirar zaben ra\'ayi';

  @override
  String get messengerPollUnavailable => 'Zaben ra\'ayi ba ya samuwa';

  @override
  String get messengerPollMultipleNote => 'Za ka iya zaɓar da yawa';

  @override
  String messengerPollVotes(int count) {
    return '$count kuri\'u';
  }

  @override
  String get messengerVideoMessage => 'Saƙon bidiyo';

  @override
  String get messengerVideoRecordError => 'Kuskuren rikodin bidiyo';

  @override
  String get messengerVideoPlaybackError => 'Ba a iya kunna bidiyo ba';

  @override
  String get messengerGalleryAccessError => 'Babu damar shiga gallery';

  @override
  String get messengerSearchInChat => 'Nema a cikin hira...';

  @override
  String get messengerSaveToFavorites => 'Ajiye a cikin abubuwan so';

  @override
  String get messengerSavedToFavorites => 'An ajiye a cikin abubuwan so';

  @override
  String get messengerSearchInMessages => 'Nema a cikin saƙonni...';

  @override
  String messengerFoundInMessages(int count) {
    return 'An samo a cikin saƙonni ($count)';
  }

  @override
  String get messengerGroupDefault => 'Rukuni';

  @override
  String get messengerUserDefault => 'Mai amfani';

  @override
  String get messengerPin => 'Manne';

  @override
  String get messengerUnpin => 'Cire manne';

  @override
  String get messengerArchive => 'Ajiye a tarihi';

  @override
  String get messengerUnarchive => 'Cire daga tarihi';

  @override
  String get messengerDeleteChat => 'Share hira';

  @override
  String get messengerDeleteChatTitle => 'Share hira?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Share hira tare da $name? Ba za a iya dawo da shi ba.';
  }

  @override
  String get messengerCreateChannel => 'Ƙirƙiri Tashar';

  @override
  String get messengerChannelName => 'Suna';

  @override
  String get messengerChannelDescription => 'Bayanin (na zaɓi)';

  @override
  String get messengerChannelCreateError => 'An kasa ƙirƙirar tashar';

  @override
  String get messengerFilterAll => 'Duka';

  @override
  String get messengerFilterUnread => 'Ba a karanta ba';

  @override
  String get messengerFilterPersonal => 'Na kaina';

  @override
  String get messengerFilterGroups => 'Rukuni';

  @override
  String get messengerFilterChannels => 'Tashoshi';

  @override
  String get messengerArchivedSection => 'An ajiye a tarihi';

  @override
  String get messengerSavedSection => 'Abubuwan so';

  @override
  String get messengerSavedSubtitle => 'Ajiye a cikin ƙwaƙwalwa';

  @override
  String messengerArchiveTitle(int count) {
    return 'Tarihi ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Tarihi babu komai';

  @override
  String messengerYouPrefix(String message) {
    return 'Kai: $message';
  }

  @override
  String get messengerMissedCall => 'Kira da aka rasa';

  @override
  String get messengerSavedTitle => 'Abubuwan so';

  @override
  String get messengerNoSavedMessages => 'Babu saƙonnin da aka ajiye';

  @override
  String get messengerSavedHint =>
      'Danna dogon saƙo → \"Ajiye a cikin abubuwan so\"';

  @override
  String get messengerDefaultFile => 'Fayil';

  @override
  String get messengerTopicDefault => 'Janar';

  @override
  String get messengerTopicNew => 'Sabon Jigo';

  @override
  String get messengerTopicNameHint => 'Sunan jigo';

  @override
  String get messengerTopicIcon => 'Alama';

  @override
  String messengerTopicCount(int count) {
    return '$count jigogi';
  }

  @override
  String get messengerNoTopics => 'Babu jigogi';

  @override
  String get messengerNoMessages => 'Babu saƙonni';

  @override
  String get you => 'Kai';

  @override
  String get messengerThread => 'Zaren';

  @override
  String get messengerThreadReply => 'amsa';

  @override
  String get messengerThreadReplies => 'amsoshi';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Babu amsoshi';

  @override
  String get messengerReplyHint => 'Amsa zaren...';

  @override
  String get messengerContactName => 'Sunan tuntuɓa';

  @override
  String messengerOriginalName(String name) {
    return 'Asalin suna: $name';
  }

  @override
  String get messengerDisplayName => 'Sunan nuni';

  @override
  String messengerShareContact(String name) {
    return 'Tuntuɓa a Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Share saƙonni ta atomatik';

  @override
  String get messengerAutoDeleteOff => 'Kashe';

  @override
  String get messengerAutoDelete7d => 'kwanaki 7';

  @override
  String get messengerAutoDelete30d => 'kwanaki 30';

  @override
  String get messengerAutoDelete90d => 'kwanaki 90';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count kwanaki';
  }

  @override
  String get messengerSettingsHeader => 'Saituna';

  @override
  String get messengerAdminOnly => 'Sanya admin kawai';

  @override
  String get messengerAdminOnlyDesc => 'Membobi za su iya karantawa kawai';

  @override
  String get messengerTopics => 'Batutuwa';

  @override
  String get messengerTopicsDesc => 'Raba hira zuwa batutuwa';

  @override
  String get aiTwinSection => 'AI Muryar Twin';

  @override
  String get aiTwinEnabled => 'Kunna AI Twin';

  @override
  String get aiTwinEnabledDesc =>
      'Idan ba ka amsa ba, AI twin ɗinka zai ɗauki kiran da muryarka';

  @override
  String get aiTwinTimeout => 'Lokacin amsa';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds sec';
  }

  @override
  String get aiTwinPrompt => 'Umarnin AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Yadda AI twin ya kamata ya gabatar da kansa da abin da za a tattauna';

  @override
  String aiTwinPromptHint(String name) {
    return 'Sannu, wannan muryar AI twin na $name. $name ba zai iya ɗaukar kiran yanzu ba. Faɗa min wanda ke kira da abin da ya shafi — zan isar da saƙon.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Siffanta muryar clone na nan ba da jimawa ba. A yanzu AI yana magana da muryar $name.';
  }

  @override
  String get aiTwinDefaultName => 'mai shi';

  @override
  String get aiTwinPromptReset => 'Sake saiti';

  @override
  String get callHistoryAiTwinAnswered => 'AI TWIN YA AMSA';

  @override
  String get callHistoryAiTwinSummary => 'TAKAITACCEN KIRA';

  @override
  String get callHistoryAiTwinTranscript => 'RUBUTU';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'Daga $name';
  }

  @override
  String get aiTwinOfferTitle => 'Ba a amsa ba';

  @override
  String aiTwinOfferBody(String name) {
    return '$name bai ɗauka ba. Ka bar saƙo tare da muryar AI ɗinsu?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Mai amfani';

  @override
  String get aiTwinOfferAccept => 'I, ajiye saƙo';

  @override
  String get aiTwinOfferKeepWaiting => 'Ci gaba da jira';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Madadin AI naka';

  @override
  String get aiTwinHeroSubtitle =>
      'Yana amsa kira da muryarka idan ba za ka iya ba.';

  @override
  String get aiTwinProfileTitle => 'Madadin AI';

  @override
  String get aiTwinProfileDesc => 'Yana amsa kira da muryarka';

  @override
  String get aiTwinBadgeOn => 'AKAN';

  @override
  String get aiAnalystTitle => 'Mai Bincike AI';

  @override
  String get aiAnalystSubtitle => 'Fayiloli, ayyuka, bincike — Claude';

  @override
  String get channelsDiscover => 'Nemo tashar';

  @override
  String get channelsSearchHint => 'Bincika tashoshi';

  @override
  String get channelsSubscribers => 'masu biyan kuɗi';

  @override
  String get channelsSubscribe => 'Yi rijista';

  @override
  String get channelsUnsubscribe => 'Ficewa';

  @override
  String get channelsSubscribedLabel => 'Ka yi rijista';

  @override
  String get channelsSettings => 'Saitunan tashar';

  @override
  String get channelsDelete => 'Goge tashar';

  @override
  String get channelsDeleteConfirm => 'Goge tashar dindindin?';

  @override
  String get channelsEmpty => 'Babu tashoshi tukuna';

  @override
  String get channelsOpen => 'Buɗe';

  @override
  String get channelsNameLabel => 'Suna';

  @override
  String get channelsDescriptionLabel => 'Bayanin';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Mai shi ba zai iya ficewa ba. Goge tashar maimakon.';

  @override
  String get channelsNotFoundRedirect => 'Tashar ba ta wanzu';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bincike',
      one: '$count bincike',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fayiloli',
      one: '$count fayil',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count umarni',
      one: '$count umarni',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hotuna',
      one: '$count hoto',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matakai',
      one: '$count mataki',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Saƙonnin da aka ajiye';

  @override
  String get savedSubtitle => 'Gajimare naka na sirri';

  @override
  String get savedOpenError => 'Ba a iya buɗe Saƙonnin da aka ajiye ba';

  @override
  String get billingWalletTitle => 'Aljihu';

  @override
  String get billingBuyPackage => 'Saya fakiti';

  @override
  String get billingCurrentBalance => 'Ma\'auni na yanzu';

  @override
  String get billingPackagesTitle => 'Fakitoci';

  @override
  String get billingPackagesUnavailable => 'Ba a samun fakitoci';

  @override
  String get billingRecentOperations => 'Ayyuka na baya-bayan nan';

  @override
  String get billingAllOperations => 'Dukkan ayyuka';

  @override
  String get billingNoOperations => 'Babu ayyuka';

  @override
  String get billingOperationsTitle => 'Ayyuka';

  @override
  String get billingOperationsEmptyTitle => 'Babu ayyuka tukuna';

  @override
  String get billingOperationsEmptySubtitle =>
      'Karin kudi da cajin fasalolin AI za su bayyana a nan';

  @override
  String get billingPricebookTitle => 'Farashin fasaloli';

  @override
  String get billingPricebookUnavailable => 'Ba a samun jerin farashi';

  @override
  String get billingAiFeaturesTitle => 'Fasalolin AI';

  @override
  String get billingInsufficientFundsTitle => 'Kudin bai isa ba';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Kara kudin ka don amfani da wannan fasalin.';

  @override
  String billingRequiredLine(String required) {
    return 'Bukata: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Akwai: $available μTAL';
  }

  @override
  String get billingTopUp => 'Kara kudi';

  @override
  String get billingCancel => 'Soke';

  @override
  String get billingRetry => 'Sake gwadawa';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Kudin yana raguwa: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Waleti & Ma\'auni';

  @override
  String get billingSectionHeader => 'Biyan kudi & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Mataimakin murya';

  @override
  String get billingFeatureWebSearch => 'Binciken yanar gizo na mataimaki';

  @override
  String get billingFeatureAiTwin => 'Muryar tagwaye';

  @override
  String get billingFeatureAiTwinLong => 'Muryar tagwaye (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot mai kira';

  @override
  String get billingFeatureOutboundCallLong => 'Bot mai kiran fita';

  @override
  String get billingFeatureWhisperTranscribe => 'Fassarar kira';

  @override
  String get billingFeatureMeetingSummary => 'Takaitaccen kiran AI';

  @override
  String get billingConfigureAiTwin => 'Saita AI twin';

  @override
  String get billingWebSearchSubtitle => '(ana amfani da shi ta mataimaki)';

  @override
  String billingPackagePurchased(String balance) {
    return 'An sayi fakiti: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'An ba da shawara';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Kudin ya kare — an dakatar da zaman';

  @override
  String get billingSessionTerminatedGeneric => 'An dakatar da zaman mataimaki';

  @override
  String billingBuyForPrice(String price) {
    return 'Sayi don €$price';
  }

  @override
  String get billingTxTypeTopup => 'Kara kudi';

  @override
  String get billingTxTypeRefund => 'Mayar da kudi';

  @override
  String get billingTxTypeSpend => 'Caji';

  @override
  String get billingUnitMinute => 'minti';

  @override
  String get billingUnitRequest => 'buƙata';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K tokens';

  @override
  String get billingUnitCall => 'kira';

  @override
  String get groupCallSelectParticipants => 'Zaɓi mahalarta';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Bincika';

  @override
  String get groupCallMaxReached => 'Mafi yawa 7 mahalarta';

  @override
  String get groupCallLobbyTitle => 'Rukuni • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Mai masauki: $name';
  }

  @override
  String get groupCallMicHint => 'Mic zai kunna lokacin haɗawa';

  @override
  String get groupCallCancel => 'Soke';

  @override
  String get groupCallNoAnswer => 'Babu wanda ya amsa';

  @override
  String get groupCallEndedByHost => 'Kira ya ƙare daga mai masauki';

  @override
  String get groupCallAllLeft => 'Kowa ya bar kiran';

  @override
  String get groupCallEnded => 'Kira ya ƙare';

  @override
  String groupCallActiveTitle(int count) {
    return 'Rukuni • $count';
  }

  @override
  String get groupCallConnectionLost => 'An rasa haɗin';

  @override
  String get groupCallMuteRequested => 'Mai masauki ya nemi kowa ya yi shiru';

  @override
  String get groupCallUnmute => 'Bude murya';

  @override
  String get groupCallMute => 'Rufe murya';

  @override
  String get groupCallMuteAll => 'Rufe kowa';

  @override
  String get groupCallLeave => 'Barin';

  @override
  String get groupCallStatusCalling => 'ana kira…';

  @override
  String get groupCallStatusDeclined => 'an ƙi';

  @override
  String get groupCallStatusTimeout => 'babu amsa';

  @override
  String get groupCallStatusLeft => 'ya bar';

  @override
  String groupCallKickConfirm(String name) {
    return 'Cire $name daga kira';
  }

  @override
  String get groupCallCancelAction => 'Soke';

  @override
  String get groupCallActiveBanner => 'Kira mai aiki';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Rukuni: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Rukuni: $host';
  }

  @override
  String get groupCallCreateError => 'Ba a iya ƙirƙirar kira ba';

  @override
  String get groupCallJoinError => 'Ba a iya shiga kira ba';

  @override
  String get groupCallLivekitError => 'Kuskuren LiveKit';

  @override
  String get groupCallDone => 'An gama';

  @override
  String get groupCallNoResults => 'Babu sakamako';

  @override
  String get groupCallNoContacts => 'Babu lambobi';

  @override
  String get meshGcContactOffline => 'Ba a kan wannan Wi-Fi';

  @override
  String get meshGcOnlineViaMesh => 'A kan layi ta hanyar mesh';

  @override
  String get meshGcMaxInvitees =>
      'Kiran rukuni yana goyan bayan har zuwa mutane 4 da aka gayyata (mutane 5 gaba ɗaya).';

  @override
  String get meshGcStart => 'Fara kiran rukuni';

  @override
  String get meshGcCancel => 'Soke';

  @override
  String get meshGcStatusCalling => 'Ana kira…';

  @override
  String get meshGcStatusJoined => 'An shiga';

  @override
  String get meshGcStatusDeclined => 'An ƙi';

  @override
  String get meshGcStatusNoAnswer => 'Babu amsa';

  @override
  String get meshGcStatusConnectionFailed => 'Haɗin bai yi nasara ba';

  @override
  String get meshGcStatusLeft => 'An bar';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Gama kiran da kake yi yanzu.';

  @override
  String get presenceOnline => 'akan layi';

  @override
  String get presenceLastSeenJustNow => 'an gani yanzu-yanzu';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'an gani $minutes min da suka wuce';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'an gani yau da $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'an gani jiya da $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'an gani $date';
  }

  @override
  String get presenceLastSeenRecently => 'an gani kwanan nan';

  @override
  String get privacySectionTitle => 'Sirri';

  @override
  String get privacyLastSeenLabel =>
      'Wa zai ga lokacin da aka gan ka na ƙarshe';

  @override
  String get privacyEveryone => 'Kowa';

  @override
  String get privacyContacts => 'Abokan hulɗa kawai';

  @override
  String get privacyNobody => 'Babu kowa';

  @override
  String get voiceTurnOffTranslation => 'Turn off translator';

  @override
  String get informerBotTitle => 'Informer';

  @override
  String get informerBotSubtitle => 'Wallet and balance monitoring';

  @override
  String seenByCount(int count) {
    return 'Seen by $count';
  }

  @override
  String get messageInfo => 'Message info';

  @override
  String get readBy => 'Read by';

  @override
  String get notReadYet => 'Not read yet';

  @override
  String get reactionsLabel => 'Reactions';

  @override
  String get noReactions => 'No reactions';

  @override
  String get mailTitle => 'Mail';

  @override
  String get mailSectionHeader => 'Mail';

  @override
  String get mailInboxEmpty => 'No emails yet';

  @override
  String get mailNoAccountTitle => 'Choose your @talerid.io address';

  @override
  String get mailNoAccountBody =>
      'Create your personal email address to send and receive mail.';

  @override
  String get mailChooseAddress => 'Choose address';

  @override
  String get mailAddressHint => 'username';

  @override
  String get mailAddressTaken => 'This address is already taken';

  @override
  String get mailAddressInvalid =>
      'Only latin letters, digits, dot, dash, underscore (3–64 chars)';

  @override
  String get mailAddressReserved => 'This name is reserved';

  @override
  String get mailAddressAvailable => 'Address is available';

  @override
  String get mailCreateAddress => 'Create address';

  @override
  String get mailSetupLater => 'Later';

  @override
  String get mailCompose => 'New email';

  @override
  String get mailTo => 'To';

  @override
  String get mailSubject => 'Subject';

  @override
  String get mailBody => 'Message';

  @override
  String get mailSend => 'Send';

  @override
  String get mailSent => 'Email sent';

  @override
  String get mailReply => 'Reply';

  @override
  String get mailDelete => 'Delete';

  @override
  String get mailMarkUnread => 'Mark as unread';

  @override
  String get mailAttachments => 'Attachments';

  @override
  String get mailAttachFile => 'Attach file';

  @override
  String get mailAppPasswords => 'App passwords';

  @override
  String get mailAppPasswordsHint =>
      'Use app passwords to connect Apple Mail, Gmail or other IMAP clients.';

  @override
  String get mailAppPasswordLabel => 'Name (e.g. iPhone Apple Mail)';

  @override
  String get mailAppPasswordCreate => 'Create password';

  @override
  String get mailAppPasswordShownOnce =>
      'Save this password now — it is shown only once.';

  @override
  String get mailAppPasswordCopied => 'Password copied';

  @override
  String get mailAppPasswordRevoke => 'Revoke';

  @override
  String get mailClientSettingsTitle => 'Client settings';

  @override
  String get mailSendLimitReached => 'Daily send limit reached';

  @override
  String get mailSendFailed => 'Failed to send email';

  @override
  String get mailAttachmentsTooLarge => 'Attachments must be under 10 MB total';

  @override
  String get mailQuotaTitle => 'Mailbox';

  @override
  String get mailFolders => 'Folders';

  @override
  String get mailFolderInbox => 'Inbox';

  @override
  String get mailFolderSent => 'Sent';

  @override
  String get mailFolderDrafts => 'Drafts';

  @override
  String get mailFolderJunk => 'Spam';

  @override
  String get mailFolderTrash => 'Trash';

  @override
  String get mailNewFolder => 'New folder';

  @override
  String get mailDeleteFolder => 'Delete folder?';

  @override
  String get mailMoveTo => 'Move to';

  @override
  String get mailMoved => 'Moved';

  @override
  String get mailSaveDraft => 'Save draft?';

  @override
  String get mailDraftSaved => 'Draft saved';

  @override
  String get deviceApprovalTitle => 'Confirm sign-in';

  @override
  String get deviceApprovalWaiting =>
      'We sent a request to your trusted devices. Open the notification and confirm.';

  @override
  String get deviceApprovalNoApprovers =>
      'No device was available to ask. Get a code by email instead.';

  @override
  String deviceApprovalExpiresIn(String time) {
    return '$time left';
  }

  @override
  String get deviceApprovalRejected =>
      'The sign-in was rejected from another device.';

  @override
  String get deviceApprovalExpired => 'The confirmation window has expired.';

  @override
  String get deviceApprovalBackToLogin => 'Back to sign-in';

  @override
  String get deviceApprovalSendEmail => 'Email me a code';

  @override
  String get deviceApprovalEmailSent => 'Code sent to your email';

  @override
  String get deviceApprovalEnterCode => 'Enter the code from the email';

  @override
  String get deviceApprovalSheetTitle => 'Account sign-in';

  @override
  String get deviceApprovalSheetBody =>
      'Someone is signing in to your account from this device. Is this you?';

  @override
  String get deviceApprovalAllow => 'Yes, allow';

  @override
  String get deviceApprovalDeny => 'This wasn\'t me';

  @override
  String get deviceApprovalApproved => 'Sign-in allowed';

  @override
  String get deviceApprovalDenied => 'Sign-in rejected';

  @override
  String get trustedDevicesTitle => 'Devices';

  @override
  String get trustedDevicesToggle => 'Confirm sign-ins from new devices';

  @override
  String get trustedDevicesToggleHint =>
      'Signing in on an unfamiliar device will need confirmation here, or a code by email';

  @override
  String get trustedDevicesEmpty => 'No trusted devices yet';

  @override
  String get trustedDevicesThisDevice => 'This device';

  @override
  String trustedDevicesLastSeen(String when) {
    return 'Last sign-in: $when';
  }

  @override
  String get trustedDevicesRevoke => 'Revoke';

  @override
  String get trustedDevicesRevokeConfirm =>
      'Revoke trust for this device? It will be signed out.';

  @override
  String get pinnedMessage => 'Pinned message';

  @override
  String get pinnedMessagesTitle => 'Pinned';

  @override
  String get pinAction => 'Pin';

  @override
  String get unpinAction => 'Unpin';

  @override
  String get unpinAllAction => 'Unpin all';

  @override
  String get noPinnedMessages => 'No pinned messages';

  @override
  String pinnedCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String messagePinnedBy(String actor) {
    return '$actor pinned a message';
  }

  @override
  String get unpinAllConfirm => 'Unpin all messages in this chat?';
}
