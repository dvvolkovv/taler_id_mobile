// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'தேடல்';

  @override
  String get appSubtitle => 'ஒற்றுமையான சூழல் அடையாளம்';

  @override
  String get login => 'உள்நுழையவும்';

  @override
  String get loginButton => 'உள்நுழையவும்';

  @override
  String get register => 'கணக்கை உருவாக்கவும்';

  @override
  String get registerButton => 'கணக்கை உருவாக்கவும்';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get confirmPassword => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get firstName => 'முதல் பெயர்';

  @override
  String get lastName => 'கடைசி பெயர்';

  @override
  String get noAccount => 'கணக்கு இல்லையா?';

  @override
  String get createOne => 'ஒன்றை உருவாக்கவும்';

  @override
  String get haveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get signIn => 'உள்நுழையவும்';

  @override
  String get passwordMinLength => 'குறைந்தது 8 எழுத்துக்கள்';

  @override
  String get invalidEmail => 'சரியான மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get fieldRequired => 'தேவையான புலம்';

  @override
  String get twoFATitle => 'இரண்டு காரணி அங்கீகாரம்';

  @override
  String get twoFASubtitle =>
      'உங்கள் அங்கீகார பயன்பாட்டில் இருந்து 6-எண் குறியீட்டை உள்ளிடவும்';

  @override
  String get twoFACode => '2FA குறியீடு';

  @override
  String get verify => 'சரிபார்க்கவும்';

  @override
  String get tabProfile => 'சுயவிவரம்';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'அமைப்பு';

  @override
  String get tabSettings => 'அமைப்புகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get editProfile => 'சுயவிவரத்தை திருத்தவும்';

  @override
  String get phone => 'தொலைபேசி';

  @override
  String get country => 'நாடு';

  @override
  String get dateOfBirth => 'பிறந்த தேதி';

  @override
  String get documents => 'ஆவணங்கள்';

  @override
  String get addDocument => 'ஆவணத்தை சேர்க்கவும்';

  @override
  String get noDocuments => 'ஆவணங்கள் பதிவேற்றப்படவில்லை';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get profileUpdated => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String get personalData => 'தனிப்பட்ட தகவல்கள்';

  @override
  String get passport => 'கடவுச்சீட்டு';

  @override
  String get drivingLicense => 'ஓட்டுநர் உரிமம்';

  @override
  String get diploma => 'டிப்ளோமா';

  @override
  String get nationalId => 'தேசிய அடையாள அட்டை';

  @override
  String get certificate => 'சான்றிதழ்';

  @override
  String get notSpecified => 'குறிப்பிடப்படவில்லை';

  @override
  String get notSpecifiedFemale => 'குறிப்பிடப்படவில்லை';

  @override
  String get documentType => 'ஆவண வகை';

  @override
  String get passportId => 'கடவுச்சீட்டு / அடையாள அட்டை';

  @override
  String get diplomaCertificate => 'டிப்ளோமா / சான்றிதழ்';

  @override
  String get loadError => 'ஏற்றுதல் பிழை';

  @override
  String get verification => 'சரிபார்ப்பு';

  @override
  String get countryAustria => 'ஆஸ்திரியா';

  @override
  String get countryGermany => 'ஜெர்மனி';

  @override
  String get countryRussia => 'ரஷ்யா';

  @override
  String get countryUkraine => 'உக்ரைன்';

  @override
  String get countryKazakhstan => 'கஸகஸ்தான்';

  @override
  String get countryBelarus => 'பெலாரஸ்';

  @override
  String get countryOther => 'மற்றவை';

  @override
  String get kycTitle => 'KYC சரிபார்ப்பு';

  @override
  String get kycVerified => 'சரிபார்க்கப்பட்டது';

  @override
  String get kycPending => 'நிலுவையில்';

  @override
  String get kycRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get kycUnverified => 'சரிபார்க்கப்படவில்லை';

  @override
  String get kycVerifiedDesc =>
      'உங்கள் அடையாளம் சரிபார்க்கப்பட்டுள்ளது. அனைத்து Taler சூழல் அம்சங்களுக்கும் முழு அணுகல் உங்களுக்கு உள்ளது.';

  @override
  String get kycPendingDesc =>
      'உங்கள் ஆவணங்கள் பரிசீலனையில் உள்ளன. இது பொதுவாக 1-2 வேலை நாட்கள் ஆகும்.';

  @override
  String get kycRejectedDesc =>
      'சரிபார்ப்பு தோல்வியடைந்தது. காரணத்தை பரிசீலித்து உங்கள் ஆவணங்களை மீண்டும் சமர்ப்பிக்கவும்.';

  @override
  String get kycUnverifiedDesc =>
      'Taler சூழல் நிதி அம்சங்களுக்கு முழு அணுகலை திறக்க சரிபார்ப்பை முடிக்கவும்.';

  @override
  String get startVerification => 'சரிபார்ப்பை தொடங்கவும்';

  @override
  String get retryVerification => 'சரிபார்ப்பை மீண்டும் முயற்சிக்கவும்';

  @override
  String verifiedAt(String date) {
    return 'சரிபார்க்கப்பட்டது: $date';
  }

  @override
  String get documentsSubmitted => 'பரிசீலனைக்காக ஆவணங்கள் சமர்ப்பிக்கப்பட்டன';

  @override
  String get documentsSubmittedDesc =>
      'பரிசீலனை பொதுவாக 1-2 வேலை நாட்கள் ஆகும். முடிவுடன் நீங்கள் ஒரு புஷ் அறிவிப்பைப் பெறுவீர்கள்.';

  @override
  String get securityAes =>
      'உங்கள் தரவு AES-256 குறியாக்கத்துடன் பாதுகாக்கப்பட்டுள்ளது';

  @override
  String get verificationTime => 'சரிபார்ப்பு 1-2 வேலை நாட்கள் ஆகும்';

  @override
  String get pushNotification =>
      'முடிவுடன் நீங்கள் ஒரு புஷ் அறிவிப்பைப் பெறுவீர்கள்';

  @override
  String get kycWebOnly =>
      'KYC சரிபார்ப்பு மொபைல் பயன்பாட்டில் மட்டுமே கிடைக்கிறது.';

  @override
  String verificationError(String code) {
    return 'சரிபார்ப்பு பிழை: $code';
  }

  @override
  String get organizations => 'நிறுவனங்கள்';

  @override
  String get noOrganizations => 'நிறுவனங்கள் இல்லை';

  @override
  String get noOrganizationsDesc =>
      'ஒரு நிறுவனம் உருவாக்கவும் அல்லது அழைப்பை ஏற்கவும்';

  @override
  String get createOrganization => 'நிறுவனம் உருவாக்கவும்';

  @override
  String get newOrganization => 'புதிய நிறுவனம்';

  @override
  String get orgName => 'பெயர் *';

  @override
  String get orgDescription => 'விளக்கம்';

  @override
  String get orgEmail => 'தொடர்பு மின்னஞ்சல்';

  @override
  String get orgWebsite => 'வலைத்தளம்';

  @override
  String get orgLegalAddress => 'சட்ட முகவரி';

  @override
  String get create => 'உருவாக்கு';

  @override
  String get organization => 'நிறுவனம்';

  @override
  String get contacts => 'தொடர்புகள்';

  @override
  String members(int count) {
    return 'உறுப்பினர்கள் ($count)';
  }

  @override
  String get inviteMember => 'உறுப்பினரை அழைக்கவும்';

  @override
  String get invite => 'அழை';

  @override
  String get sendInvite => 'அழைப்பை அனுப்பு';

  @override
  String inviteSent(String email) {
    return '$email க்கு அழைப்பு அனுப்பப்பட்டது';
  }

  @override
  String get role => 'பங்கு';

  @override
  String get roleOwner => 'உரிமையாளர்';

  @override
  String get roleAdmin => 'நிர்வாகி';

  @override
  String get roleOperator => 'இயக்குனர்';

  @override
  String get roleViewer => 'பார்வையாளர்';

  @override
  String get editOrganization => 'தொகு';

  @override
  String get editOrganizationTitle => 'நிறுவனத்தைத் திருத்து';

  @override
  String get removeMember => 'உறுப்பினரை நீக்கு';

  @override
  String removeMemberConfirm(String name) {
    return '$name ஐ நிறுவனத்திலிருந்து நீக்கவா?';
  }

  @override
  String get memberRemoved => 'உறுப்பினர் நீக்கப்பட்டார்';

  @override
  String get roleChanged => 'பங்கு மாற்றப்பட்டது';

  @override
  String get kybVerified => 'சரிபார்க்கப்பட்டது';

  @override
  String get kybPending => 'நிலுவையில் உள்ளது';

  @override
  String get kybRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get kybNone => 'சரிபார்க்கப்படவில்லை';

  @override
  String get kybVerification => 'KYB சரிபார்ப்பை தொடங்கு';

  @override
  String get kybStartBusiness => 'வணிக சரிபார்ப்பை தொடங்கு';

  @override
  String get kybStatusLabel => 'KYB நிலை';

  @override
  String get noKyb => 'KYB இல்லை';

  @override
  String get kybBusinessVerificationTitle => 'வணிக சரிபார்ப்பு (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'நிறுவனம் வெற்றிகரமாக சரிபார்க்கப்பட்டது.';

  @override
  String get kybPendingOrgDesc =>
      'ஆவணங்கள் பரிசீலிக்கப்படுகின்றன. இது பொதுவாக 1-3 வணிக நாட்கள் ஆகும்.';

  @override
  String get kybRejectedOrgDesc =>
      'சரிபார்ப்பு தோல்வியடைந்தது. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get kybNoneOrgDesc =>
      'வணிக அம்சங்களை அணுக உங்கள் நிறுவனத்தை சரிபார்க்கவும்.';

  @override
  String get invitePlus => '+ அழை';

  @override
  String get kybVerificationTitle => 'KYB சரிபார்ப்பு';

  @override
  String get kybWebOnlyBusiness =>
      'KYB சரிபார்ப்பு மொபைல் பயன்பாட்டில் மட்டுமே கிடைக்கிறது.';

  @override
  String get unknownDevice => 'அறியப்படாத சாதனம்';

  @override
  String get ipUnknown => 'IP தெரியவில்லை';

  @override
  String get currentSessionLabel => 'தற்போது';

  @override
  String get endSessionAction => 'முடி';

  @override
  String get deviceLoggedOut => 'சாதனம் வெளியேறும்.';

  @override
  String get acceptInvitationTitle => 'அமைப்பு அழைப்பு';

  @override
  String get acceptInvitation => 'அழைப்பை ஏற்கவும்';

  @override
  String get acceptInvitationDesc =>
      'Taler சூழலில் ஒரு அமைப்பில் சேர அழைக்கப்பட்டுள்ளீர்கள்.';

  @override
  String get accept => 'ஏற்கவும்';

  @override
  String get reject => 'நிராகரிக்கவும்';

  @override
  String get sessions => 'செயலில் உள்ள அமர்வுகள்';

  @override
  String get currentSession => 'தற்போதைய அமர்வு';

  @override
  String get deleteSession => 'அமர்வை முடிக்கவும்';

  @override
  String get deleteSessionConfirm => 'இந்த அமர்வை முடிக்கவா?';

  @override
  String get sessionDeleted => 'அமர்வு முடிந்தது';

  @override
  String get noSessions => 'செயலில் உள்ள அமர்வுகள் இல்லை';

  @override
  String minutesAgo(int count) {
    return '$count நிமிடங்களுக்கு முன்';
  }

  @override
  String hoursAgo(int count) {
    return '$count மணி நேரத்திற்கு முன்';
  }

  @override
  String daysAgo(int count) {
    return '$count நாட்களுக்கு முன்';
  }

  @override
  String get justNow => 'இப்பொழுது';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get security => 'பாதுகாப்பு';

  @override
  String get biometrics => 'உயிரியல் அடையாளங்கள்';

  @override
  String get biometricsDesc =>
      'முக அடையாளம் அல்லது விரல் ரேகை மூலம் விரைவான உள்நுழைவு';

  @override
  String get biometricsConfirm =>
      'விரைவான உள்நுழைவை இயக்க உயிரியல் அடையாளங்களை உறுதிப்படுத்தவும்';

  @override
  String get biometricsError =>
      'உயிரியல் அடையாளங்களை இயக்க முடியவில்லை. சாதன அமைப்புகளை சரிபார்க்கவும்.';

  @override
  String get changePassword => 'கடவுச்சொல்லை மாற்றவும்';

  @override
  String get twoFactorAuth => 'இரண்டு காரணி அங்கீகாரம்';

  @override
  String get currentPassword => 'தற்போதைய கடவுச்சொல்';

  @override
  String get newPassword => 'புதிய கடவுச்சொல்';

  @override
  String get confirmNewPassword => 'புதிய கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get passwordChanged => 'கடவுச்சொல் மாற்றப்பட்டது';

  @override
  String get wrongCurrentPassword => 'தவறான தற்போதைய கடவுச்சொல்';

  @override
  String get passwordTooWeak =>
      'கடவுச்சொல் பலவீனமாக உள்ளது: குறைந்தது 8 எழுத்துக்கள், எழுத்து மற்றும் எண் தேவை';

  @override
  String get passwordChangeFailed => 'கடவுச்சொல்லை மாற்ற முடியவில்லை';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get permissions => 'அனுமதிகள்';

  @override
  String get permissionNotifications => 'புஷ் அறிவிப்புகள்';

  @override
  String get permissionNotificationsDesc => 'அழைப்புகள், செய்திகள், நிலைகள்';

  @override
  String get permissionMicrophone => 'மைக்ரோஃபோன்';

  @override
  String get permissionMicrophoneDesc => 'கால்கள் மற்றும் குரல் உதவியாளர்';

  @override
  String get permissionCamera => 'கேமரா';

  @override
  String get permissionCameraDesc => 'வீடியோ கால்கள் மற்றும் சரிபார்ப்பு';

  @override
  String get permissionLocation => 'இடம்';

  @override
  String get permissionLocationDesc => 'சரிபார்ப்புக்கு பயன்படுத்தப்படுகிறது';

  @override
  String get permissionOpenSettings =>
      'ஒரு அனுமதியை ரத்து செய்ய, அமைப்புகளை திறக்கவும்';

  @override
  String get pushKycStatus => 'KYC நிலை புஷ்';

  @override
  String get pushKycStatusDesc => 'சரிபார்ப்பு முடிவு';

  @override
  String get pushLogins => 'உள்நுழைவு புஷ்';

  @override
  String get pushLoginsDesc => 'புதிய சாதனத்தில் உள்நுழையும் போது';

  @override
  String get account => 'கணக்கு';

  @override
  String get language => 'மொழி';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'இணைமுக மொழி';

  @override
  String get exportData => 'தரவை ஏற்றுமதி செய்க (GDPR)';

  @override
  String get deleteAccount => 'கணக்கை நீக்கு';

  @override
  String get deleteAccountConfirm => 'கணக்கை நீக்கவா?';

  @override
  String get deleteAccountDesc =>
      'உங்கள் அனைத்து தரவுகளும் நீக்கப்படும் (GDPR). இந்த செயல்பாடு மாற்ற முடியாது.';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get logoutConfirm => 'வெளியேறவா?';

  @override
  String get logoutDesc =>
      'இந்த சாதனத்தில் இருந்து Taler ID இல் இருந்து நீங்கள் வெளியேறுவீர்கள்.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'பின் குறியீடு';

  @override
  String get pinCodeDesc => '4 இலக்க குறியீட்டுடன் விரைவான உள்நுழைவு';

  @override
  String get setupPin => 'பின் அமைக்கவும்';

  @override
  String get enterPin => 'பினை உள்ளிடவும்';

  @override
  String get confirmPin => 'பினை உறுதிப்படுத்தவும்';

  @override
  String get pinMismatch => 'பின்கள் பொருந்தவில்லை';

  @override
  String get passwordMismatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get pinSet => 'பின் வெற்றிகரமாக அமைக்கப்பட்டது';

  @override
  String get enterPinToLogin => 'உள்நுழைய பினை உள்ளிடவும்';

  @override
  String get pinIncorrect => 'தவறான பின்';

  @override
  String get removePin => 'பினை நீக்கு';

  @override
  String get pinRemoved => 'பின் நீக்கப்பட்டது';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get delete => 'நீக்கு';

  @override
  String get ok => 'சரி';

  @override
  String get retry => 'மீண்டும் முயற்சி செய்';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get error => 'பிழை';

  @override
  String get success => 'வெற்றி';

  @override
  String get noData => 'தகவல் இல்லை';

  @override
  String get failedToLoad => 'தரவை ஏற்ற முடியவில்லை';

  @override
  String get failedToLoadProfile => 'சுயவிவரத்தை ஏற்ற முடியவில்லை';

  @override
  String get failedToSave => 'மாற்றங்களை சேமிக்க முடியவில்லை';

  @override
  String get failedToLoadOrgs => 'நிறுவனங்களை ஏற்ற முடியவில்லை';

  @override
  String get failedToLoadOrg => 'நிறுவனத்தின் தரவை ஏற்ற முடியவில்லை';

  @override
  String get failedToCreateOrg => 'நிறுவனத்தை உருவாக்க முடியவில்லை';

  @override
  String get failedToInvite => 'அழைப்பை அனுப்ப முடியவில்லை';

  @override
  String get failedToAcceptInvite => 'அழைப்பை ஏற்க முடியவில்லை';

  @override
  String get failedToLoadSessions => 'அமர்வுகளை ஏற்ற முடியவில்லை';

  @override
  String get failedToDeleteSession => 'அமர்வை முடிக்க முடியவில்லை';

  @override
  String get failedToLoadKyc => 'சரிபார்ப்பு நிலையை ஏற்ற முடியவில்லை';

  @override
  String get failedToStartKyc => 'சரிபார்ப்பை தொடங்க முடியவில்லை';

  @override
  String get verifiedPersonalInfo => 'சரிபார்க்கப்பட்ட தரவு';

  @override
  String get middleName => 'நடுத்தர பெயர்';

  @override
  String get placeOfBirth => 'பிறந்த இடம்';

  @override
  String get nationality => 'தேசியம்';

  @override
  String get gender => 'பாலினம்';

  @override
  String get genderMale => 'ஆண்';

  @override
  String get genderFemale => 'பெண்';

  @override
  String get docNumber => 'எண்';

  @override
  String get docIssuedDate => 'வெளியிடப்பட்டது';

  @override
  String get docValidUntil => 'செல்லுபடியாகும் வரை';

  @override
  String get docIssuedBy => 'வெளியிட்டவர்';

  @override
  String get address => 'முகவரி';

  @override
  String get refreshData => 'தரவை புதுப்பிக்கவும்';

  @override
  String get failedToLoadSumsubData => 'சரிபார்ப்பு தரவை ஏற்ற முடியவில்லை';

  @override
  String get sumsubDataLoading => 'சரிபார்ப்பு தரவை ஏற்றுகிறது...';

  @override
  String get reviewResultGreen => 'சரிபார்ப்பு வெற்றி';

  @override
  String get reviewResultRed => 'சரிபார்ப்பு தோல்வி';

  @override
  String get tabAssistant => 'உதவியாளர்';

  @override
  String get assistantConnecting => 'இணைக்கிறது…';

  @override
  String get assistantSpeaking => 'பேசுகிறது…';

  @override
  String get assistantListening => 'கேட்கிறது…';

  @override
  String get assistantTapToStart => 'தொடங்க தட்டவும்';

  @override
  String get assistantTapToTalk => 'AI உடன் பேச தட்டவும்';

  @override
  String get assistantRealtimeDesc => 'உதவியாளர் உடனடி குரல் பதிலளிக்கிறது';

  @override
  String get assistantConnectingToAssistant => 'உதவியாளருடன் இணைக்கிறது...';

  @override
  String get assistantAiSpeaking => 'AI பேசுகிறது...';

  @override
  String get assistantAiListening => 'AI கேட்கிறது';

  @override
  String get assistantSpeakerOn => 'ஸ்பீக்கர் ஆன்';

  @override
  String get assistantSpeaker => 'ஸ்பீக்கர்';

  @override
  String get assistantEnd => 'முடிவு';

  @override
  String get assistantUnmute => 'மூடியதை திற';

  @override
  String get assistantMicrophone => 'மைக்ரோஃபோன்';

  @override
  String get assistantConnectionError => 'இணைப்பு பிழை';

  @override
  String get tabMessenger => 'செய்திகள்';

  @override
  String get tabCalls => 'அழைப்புகள்';

  @override
  String get tabCalendar => 'நாட்காட்டி';

  @override
  String get appearance => 'தோற்றம்';

  @override
  String get appearanceSelect => 'தீமையை தேர்வு செய்க';

  @override
  String get themeLight => 'ஒளி';

  @override
  String get themeDark => 'இருள்';

  @override
  String get themeSystem => 'அமைப்பு';

  @override
  String get onboardingTitle1 => 'ஒற்றுமையான அடையாளம்';

  @override
  String get onboardingDesc1 =>
      'Taler ID உங்கள் டிஜிட்டல் பாஸ்போர்ட். அனைத்து சேவைகளுக்கும் ஒரு கணக்கு.';

  @override
  String get onboardingTitle2 => 'தரவு பாதுகாப்பு';

  @override
  String get onboardingDesc2 =>
      'KYC சரிபார்ப்பு, AES-256 குறியாக்கம், மற்றும் இரட்டை காரணி அங்கீகாரம் உங்கள் அடையாளத்தை பாதுகாக்கும்.';

  @override
  String get onboardingTitle3 => 'தகவல் பெறுங்கள்';

  @override
  String get onboardingDesc3 =>
      'சரிபார்ப்பு நிலை, புதிய சாதனங்களில் உள்நுழைவு, மற்றும் வரும் அழைப்புகள் பற்றிய அறிவிப்புகளைப் பெறுங்கள்.';

  @override
  String get onboardingNext => 'அடுத்தது';

  @override
  String get onboardingEnableNotifications => 'அறிவிப்புகளை இயக்கு';

  @override
  String get onboardingTitle4 => 'குரல் அழைப்புகள்';

  @override
  String get onboardingDesc4 =>
      'குரல் அழைப்புகள் மற்றும் AI உதவியாளருக்கு மைக்ரோஃபோன் அணுகலை வழங்கவும். பின்னர் அமைப்புகளில் இதை மாற்றலாம்.';

  @override
  String get onboardingEnableMicrophone => 'மைக்ரோஃபோனை இயக்கு';

  @override
  String get onboardingStart => 'தொடங்குங்கள்';

  @override
  String get onboardingSkip => 'தவிர்க்கவும்';

  @override
  String get meshLocalNetworkPromptTitle =>
      'உள்ளூர் நெட்வொர்க் அணுகலை அனுமதிக்கவும்';

  @override
  String get meshLocalNetworkPromptBody =>
      'Wi-Fi இல் (ஆஃப்லைன் குழு அழைப்புகள்) சகாக்களை கண்டறிய, iOS உள்ளூர் நெட்வொர்க் அனுமதியை தேவைப்படுகிறது. அமைப்புகள் திறக்கவும் → தனியுரிமை & பாதுகாப்பு → உள்ளூர் நெட்வொர்க் → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'அமைப்புகளை திறக்கவும்';

  @override
  String get meshLocalNetworkPromptDismiss => 'புரிந்தது';

  @override
  String get forgotPassword => 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?';

  @override
  String get forgotPasswordTitle => 'கடவுச்சொல்லை மீட்டமைக்கவும்';

  @override
  String get forgotPasswordSubtitle =>
      'மீட்டமைப்பு குறியீட்டை பெற உங்கள் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String resetCodeSent(String email) {
    return '$email க்கு குறியீடு அனுப்பப்பட்டது';
  }

  @override
  String get enterResetCode => 'குறியீட்டை உள்ளிடவும்';

  @override
  String get resetPasswordButton => 'கடவுச்சொல்லை மீட்டமைக்கவும்';

  @override
  String get passwordResetSuccess =>
      'கடவுச்சொல் வெற்றிகரமாக மீட்டமைக்கப்பட்டது';

  @override
  String get sendCode => 'குறியீட்டை அனுப்பு';

  @override
  String get resendCode => 'மீண்டும் குறியீட்டை அனுப்பு';

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
  String get newGroup => 'புதிய குழு';

  @override
  String get newChat => 'புதிய உரையாடல்';

  @override
  String get groupName => 'குழு பெயர்';

  @override
  String get createGroup => 'குழுவை உருவாக்கு';

  @override
  String get groupInfo => 'குழு தகவல்';

  @override
  String groupMembers(int count) {
    return 'உறுப்பினர்கள் ($count)';
  }

  @override
  String get addMembers => 'உறுப்பினர்களை சேர்';

  @override
  String get leaveGroup => 'குழுவை விட்டு வெளியேறு';

  @override
  String get leaveGroupConfirm => 'இந்த குழுவை விட்டு வெளியேறவா?';

  @override
  String get deleteGroup => 'குழுவை நீக்கு';

  @override
  String get deleteGroupConfirm => 'இந்த குழுவை நீக்கவா? இது மீட்க முடியாது.';

  @override
  String get groupRoleOwner => 'உரிமையாளர்';

  @override
  String get groupRoleAdmin => 'நிர்வாகி';

  @override
  String get groupRoleMember => 'உறுப்பினர்';

  @override
  String get selectParticipants => 'பங்கேற்பாளர்களை தேர்வு செய்';

  @override
  String selectedCount(int count) {
    return '$count தேர்வு செய்யப்பட்டது';
  }

  @override
  String get changeRole => 'பாத்திரத்தை மாற்று';

  @override
  String get groupCreated => 'குழு உருவாக்கப்பட்டது';

  @override
  String memberJoined(String name) {
    return '$name சேர்ந்தார்';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name விட்டு வெளியேறினார்';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name நீக்கப்பட்டார்';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name இப்போது $role';
  }

  @override
  String participantsCount(int count) {
    return '$count பங்கேற்பாளர்கள்';
  }

  @override
  String get enterGroupName => 'குழு பெயரை உள்ளிடவும்';

  @override
  String get muteNotifications => 'அறிவிப்புகளை மவுட் செய்';

  @override
  String get unmuteNotifications => 'அறிவிப்புகளை மவுட் நீக்கு';

  @override
  String get muteFor1Hour => '1 மணி நேரத்திற்கு';

  @override
  String get muteFor8Hours => '8 மணி நேரத்திற்கு';

  @override
  String get muteFor2Days => '2 நாட்களுக்கு';

  @override
  String get muteForever => 'எப்போதும்';

  @override
  String get muted => 'மவுட் செய்யப்பட்டது';

  @override
  String get tabTranslator => 'மொழிபெயர்ப்பு';

  @override
  String get translatorTitle => 'மொழிபெயர்ப்பாளர்';

  @override
  String get translatorSelectLanguage => 'மொழியை தேர்வு செய்';

  @override
  String get translatorDownloading => 'மொழி மாதிரிகளை பதிவிறக்குகிறது...';

  @override
  String get translatorDownloadingHint =>
      'முதல் பதிவிறக்கத்திற்கு மட்டுமே இணையம் தேவை';

  @override
  String get translatorTypeHint =>
      'உரை தட்டச்சு செய்யவும் அல்லது மைக்ரோஃபோனை தட்டவும்';

  @override
  String get translatorListening => 'கேட்கிறது...';

  @override
  String get translatorTapToSpeak => 'பேச தட்டவும்';

  @override
  String get translatorTapToStop => 'நிறுத்த தட்டவும்';

  @override
  String get translatorAutoSpeak => 'தானியங்கி பேச்சு';

  @override
  String get translatorCopied => 'நகலெடுக்கப்பட்டது';

  @override
  String get translatorLangRu => 'ரஷியன்';

  @override
  String get translatorLangEn => 'ஆங்கிலம்';

  @override
  String get translatorLangDe => 'ஜெர்மன்';

  @override
  String get translatorLangFr => 'பிரெஞ்சு';

  @override
  String get translatorLangEs => 'ஸ்பானிஷ்';

  @override
  String get translatorLangIt => 'இத்தாலியன்';

  @override
  String get translatorLangPt => 'போர்ச்சுகீஸ்';

  @override
  String get translatorLangTr => 'துருக்கிஷ்';

  @override
  String get translatorLangZh => 'சீனம்';

  @override
  String get translatorLangJa => 'ஜப்பானியன்';

  @override
  String get translatorLangKo => 'கொரியன்';

  @override
  String get translatorLangAr => 'அரபிக்';

  @override
  String get translatorLangPl => 'போலிஷ்';

  @override
  String get translatorLangSk => 'ஸ்லோவாக்';

  @override
  String get translatorLangCs => 'செக்';

  @override
  String get translatorLangNl => 'டச்சு';

  @override
  String get translatorLangSv => 'ஸ்வீடிஷ்';

  @override
  String get translatorLangDa => 'டேனிஷ்';

  @override
  String get translatorLangNo => 'நார்வேஜியன்';

  @override
  String get translatorLangFi => 'பின்னிஷ்';

  @override
  String get translatorLangUk => 'உக்ரைனியன்';

  @override
  String get translatorLangEl => 'கிரேக்கம்';

  @override
  String get translatorLangRo => 'ருமேனியன்';

  @override
  String get translatorLangHu => 'ஹங்கேரியன்';

  @override
  String get translatorLangBg => 'பல்கேரியன்';

  @override
  String get translatorLangHr => 'குரோஷியன்';

  @override
  String get translatorLangSr => 'செர்பியன்';

  @override
  String get translatorLangHi => 'இந்தி';

  @override
  String get translatorLangTh => 'தாய்';

  @override
  String get translatorLangVi => 'வியட்நாமிஸ்';

  @override
  String get translatorLangId => 'இந்தோனேஷியன்';

  @override
  String get translatorLangMs => 'மலாய்';

  @override
  String get translatorLangHe => 'ஹீப்ரூ';

  @override
  String get translatorLangFa => 'பாரசீகன்';

  @override
  String get callInProgress => 'அழைப்பு நடக்கிறது';

  @override
  String get joinCall => 'சேர';

  @override
  String get createCallLink => 'கால் இணைப்பு';

  @override
  String get callLinkCopied => 'இணைப்பு நகலெடுக்கப்பட்டது';

  @override
  String get callLinkTitle => 'அறை இணைப்பு';

  @override
  String get connectionUnstable =>
      'இணைப்பு நிலையற்றது — உங்கள் இணையத்தை சரிபார்க்கவும்';

  @override
  String get today => 'இன்று';

  @override
  String get yesterday => 'நேற்று';

  @override
  String get errorTimeout =>
      'இணைப்பு நேரம் முடிந்தது. உங்கள் இணைய இணைப்பை சரிபார்க்கவும்.';

  @override
  String get errorNoConnection => 'இணைய இணைப்பு இல்லை.';

  @override
  String get errorGeneral =>
      'ஒரு பிழை ஏற்பட்டுள்ளது. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String errorWithMessage(String message) {
    return 'பிழை: $message';
  }

  @override
  String get notifChannelMessages => 'செய்திகள்';

  @override
  String get notifChannelMessagesDesc => 'புதிய செய்தி அறிவிப்புகள்';

  @override
  String get notifChannelMissedCalls => 'தவறவிட்ட அழைப்புகள்';

  @override
  String get notifChannelMissedCallsDesc => 'தவறவிட்ட அழைப்பு அறிவிப்புகள்';

  @override
  String get notifMissedCall => 'தவறவிட்ட அழைப்பு';

  @override
  String get notifAccept => 'ஏற்கவும்';

  @override
  String get notifDecline => 'நிராகரிக்கவும்';

  @override
  String get notifIncomingCall => 'உள்வரும் அழைப்பு';

  @override
  String get notifIncomingCallChannel => 'உள்வரும் அழைப்பு';

  @override
  String get notifMissedCallChannel => 'தவறவிட்ட அழைப்பு';

  @override
  String get notifUnknown => 'அறியப்படாதது';

  @override
  String get effectNone => 'பின்னணி இல்லை';

  @override
  String get effectBlur => 'மங்கல்';

  @override
  String get effectOffice => 'அலுவலகம்';

  @override
  String get effectNature => 'இயற்கை';

  @override
  String get effectGradient => 'சாய்வு';

  @override
  String get effectLibrary => 'நூலகம்';

  @override
  String get effectCity => 'நகரம்';

  @override
  String get effectMinimalism => 'குறைவியல்பாடு';

  @override
  String get voiceParticipant => 'பங்கேற்பாளர்';

  @override
  String get voiceInvitesToRoom => 'அறைக்கு அழைக்கிறார்';

  @override
  String get voiceRoom => 'அறை';

  @override
  String get voicePasswordProtected => 'கடவுச்சொல்லால் பாதுகாக்கப்பட்டது';

  @override
  String get voicePasswordHint => 'கடவுச்சொல்';

  @override
  String get voiceEnter => 'உள்ளிடவும்';

  @override
  String get voiceJoinRoom => 'அறையில் சேரவும்';

  @override
  String get voiceYourName => 'உங்கள் பெயர்';

  @override
  String voiceInvitationSent(String name) {
    return '$name க்கு அழைப்பு அனுப்பப்பட்டது';
  }

  @override
  String get voiceNoActiveRoom => 'செயலில் உள்ள அறை இல்லை';

  @override
  String get voiceCameraPermission =>
      'அமைப்புகள் → தனியுரிமை → கேமரா → TalerID இல் கேமரா அணுகலை அனுமதிக்கவும்';

  @override
  String get voiceOpenSettings => 'திற';

  @override
  String voiceCameraError(String error) {
    return 'கேமராவை இயக்க முடியவில்லை: $error';
  }

  @override
  String get voiceAllAgreedRecording =>
      'அனைவரும் ஒப்புக்கொண்டனர். பதிவு தொடங்கியது.';

  @override
  String get voiceNewParticipantAgreed =>
      'புதிய பங்கேற்பாளர் பதிவுக்கு ஒப்புக்கொண்டார்.';

  @override
  String get voiceDeclinedRecording =>
      'நீங்கள் பதிவை நிராகரித்தீர்கள். அழைப்பை விட்டு வெளியேறுகிறேன்.';

  @override
  String get voiceRecordingEnded => 'பதிவு முடிந்தது';

  @override
  String get voiceRecordingInProgress => 'பதிவு நடைபெறுகிறது';

  @override
  String get voiceTranscriptionRequest => 'உரை மாற்று கோரிக்கை';

  @override
  String get voiceRecordingRequest => 'பதிவு கோரிக்கை';

  @override
  String get voiceAgree => 'ஒப்புக்கொள்';

  @override
  String get voiceDeclineAndLeave => 'நிராகரித்து விட்டு வெளியேறு';

  @override
  String get voiceAudioOutput => 'ஆடியோ வெளியீடு';

  @override
  String get voiceAudioPhone => 'தொலைபேசி';

  @override
  String get voiceAudioSpeaker => 'ஸ்பீக்கர்';

  @override
  String get voiceAudioBluetooth => 'ப்ளூடூத்';

  @override
  String get voiceAudioHeadphones => 'தலைக்கூடிகள்';

  @override
  String get voiceLinkCopied => 'இணைப்பு நகலெடுக்கப்பட்டது';

  @override
  String get voiceTranslateTo => 'மொழிபெயர்க்க';

  @override
  String get voiceSearchLanguage => 'மொழி தேடு...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'அறை $name';
  }

  @override
  String get voiceVoiceCall => 'குரல் அழைப்பு';

  @override
  String get voiceOnHold => 'நிறுத்தப்பட்டது';

  @override
  String get voiceActiveCall => 'செயலில் உள்ளது';

  @override
  String get voiceEndAllCalls => 'அனைத்து அழைப்புகளையும் முடி';

  @override
  String get voiceEndThisCall => 'இந்த அழைப்பை முடி';

  @override
  String get voiceCopyLink => 'இணைப்பை நகலெடு';

  @override
  String get voiceAddParticipant => 'பங்கேற்பாளரை சேர்';

  @override
  String get voiceReconnecting => 'மீண்டும் இணைக்கப்படுகிறது...';

  @override
  String get voiceConnectionError => 'இணைப்பு பிழை';

  @override
  String get voiceClose => 'மூடு';

  @override
  String get voiceCalling => 'அழைக்கிறது...';

  @override
  String get voiceCallActive => 'அழைப்பு செயலில் உள்ளது';

  @override
  String get voiceWaiting => 'காத்திருக்கிறது';

  @override
  String get voiceWaitingUpper => 'காத்திருக்கிறது';

  @override
  String get voiceRec => 'பதிவு';

  @override
  String get voiceStop => 'நிறுத்து';

  @override
  String get voiceRecord => 'பதிவு';

  @override
  String get voiceTranslation => 'மொழிபெயர்ப்பு';

  @override
  String get voiceAudio => 'ஆடியோ';

  @override
  String get voiceFlipCamera => 'கேமராவை திருப்பு';

  @override
  String get voiceBackground => 'பின்னணி';

  @override
  String get voiceAssistantSpeakingStatus => 'உதவியாளர் பேசுகிறார்...';

  @override
  String get voiceAssistantListeningStatus => 'உதவியாளர் கேட்கிறார்...';

  @override
  String get voiceUnmute => 'மூடியதை திற';

  @override
  String get voiceMic => 'மைக்ரோஃபோன்';

  @override
  String get voiceAssistantLabel => 'உதவியாளர்';

  @override
  String get voiceCameraOn => 'கேமரா இயக்கம்';

  @override
  String get voiceCameraLabel => 'கேமரா';

  @override
  String get voiceEndCall => 'அழைப்பை முடி';

  @override
  String get voiceWaitingParticipants =>
      'பங்கேற்பாளர்களுக்காக காத்திருக்கிறது...';

  @override
  String get voiceYou => 'நீங்கள்';

  @override
  String get voiceAiAssistant => 'AI உதவியாளர்';

  @override
  String get voiceVideoUnavailable => 'வீடியோ கிடைக்கவில்லை';

  @override
  String get voiceSearchNickname => 'புனைப்பெயரால் தேடுங்கள்...';

  @override
  String get voiceTranscriptionWord => 'எழுத்துப்பதிவு';

  @override
  String get voiceRecordingWord => 'பதிவு';

  @override
  String get voiceConnecting => 'இணைக்கிறது...';

  @override
  String get voiceVideoBackground => 'வீடியோ பின்னணி';

  @override
  String get voiceCallSettings => 'அழைப்பு அமைப்புகள்';

  @override
  String get voiceEnableAI => 'AI உதவியாளரை இயக்கவும்';

  @override
  String get voiceAIParticipating => 'AI உரையாடலில் பங்கேற்கும்';

  @override
  String get voiceNormalCall => 'AI இல்லாமல் சாதாரண அழைப்பு';

  @override
  String get voiceCallConfirm => 'அழைப்பை செய்யவா?';

  @override
  String get chatAlreadyInCall => 'ஏற்கனவே ஒரு அழைப்பில் உள்ளீர்கள்';

  @override
  String chatCallError(String error) {
    return 'அழைப்பு பிழை: $error';
  }

  @override
  String get chatPhotoVideo => 'புகைப்படம் / வீடியோ';

  @override
  String get chatCamera => 'கேமரா';

  @override
  String get chatFile => 'கோப்பு';

  @override
  String get chatContact => 'தொடர்பு';

  @override
  String get chatSelectContact => 'ஒரு தொடர்பை தேர்ந்தெடுக்கவும்';

  @override
  String get chatNoContacts => 'தொடர்புகள் இல்லை';

  @override
  String get chatUser => 'பயனர்';

  @override
  String get chatFileAttachment => '📎 கோப்பு';

  @override
  String chatFileUploadError(String error) {
    return 'கோப்பு பதிவேற்ற பிழை: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 குரல் செய்தி';

  @override
  String get chatGroup => 'குழு';

  @override
  String get chatDialog => 'உரையாடல்';

  @override
  String get chatCall => 'அழைப்பு';

  @override
  String get chatStartConversation => 'உரையாடலை தொடங்கவும்';

  @override
  String get chatYou => 'நீங்கள்';

  @override
  String get chatIsTyping => 'எழுதுகிறது...';

  @override
  String chatUserIsTyping(String name) {
    return '$name எழுதுகிறது...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names எழுதுகிறார்கள்...';
  }

  @override
  String get chatPreparingFile => 'கோப்பை தயாரிக்கிறது…';

  @override
  String chatUploading(int progress) {
    return 'பதிவேற்றுகிறது… $progress%';
  }

  @override
  String get chatEdited => 'திருத்தப்பட்டது';

  @override
  String get chatViaMesh => 'mesh மூலம்';

  @override
  String get chatReply => 'பதில்';

  @override
  String get chatEdit => 'திருத்து';

  @override
  String get chatCopy => 'நகல்';

  @override
  String get chatCopied => 'நகலெடுக்கப்பட்டது';

  @override
  String get chatSaveMedia => 'சேமிக்கவும்';

  @override
  String get chatForward => 'முன்னேற்றவும்';

  @override
  String get chatSaving => 'சேமிக்கிறது...';

  @override
  String get chatSavedToGallery => 'கேலரியில் சேமிக்கப்பட்டது';

  @override
  String get chatNoSavePermission =>
      'சேமிக்க அனுமதி இல்லை. அமைப்புகளை சரிபார்க்கவும்.';

  @override
  String get chatFileSaveError => 'கோப்பு சேமிப்பு பிழை';

  @override
  String get chatDeleteMessage => 'செய்தியை நீக்கு';

  @override
  String get chatDeleteForMe => 'எனக்காக நீக்கு';

  @override
  String get chatDeleteForEveryone => 'அனைவருக்கும் நீக்கு';

  @override
  String get chatMessageForwarded => 'செய்தி முன்னேற்றப்பட்டது';

  @override
  String get chatContactTapToOpen => 'தொடர்பு · திறக்க தட்டவும்';

  @override
  String get chatForwardTo => 'முன்னேற்றவும்...';

  @override
  String get chatSearchHint => 'தேடல்...';

  @override
  String get chatRecording => 'பதிவு செய்கிறது...';

  @override
  String get chatMessageHint => 'செய்தி...';

  @override
  String get chatHideKeyboard => 'விசைப்பலகையை மறைக்கவும்';

  @override
  String get chatEditing => 'திருத்துகிறது';

  @override
  String get chatFileDownloadError => 'கோப்பு பதிவிறக்கம் பிழை';

  @override
  String get chatVoiceMessageShort => 'குரல் செய்தி';

  @override
  String get chatVideoSavedToGallery => 'கேலரியில் வீடியோ சேமிக்கப்பட்டது';

  @override
  String get chatSavingError => 'சேமிப்பு பிழை';

  @override
  String get convSetNickname => 'ஒரு புனைப்பெயரை அமைக்கவும்';

  @override
  String get convNicknameRequired =>
      'மெசஞ்சரைப் பயன்படுத்த புனைப்பெயர் தேவை. மற்ற பயனர்கள் உங்களை அதனால் கண்டுபிடிக்க முடியும்.';

  @override
  String get convNicknameRules => '3–30 எழுத்துக்கள்: எழுத்துக்கள், எண்கள், _';

  @override
  String get convNicknameTaken => 'புனைப்பெயர் ஏற்கனவே பயன்படுத்தப்பட்டுள்ளது';

  @override
  String get convSaveError => 'சேமிப்பு பிழை';

  @override
  String get convContactsLabel => 'தொடர்புகள்';

  @override
  String get convDefaultUser => 'பயனர்';

  @override
  String get convNoDialogs => 'உரையாடல்கள் இல்லை';

  @override
  String get convFindUserToChat => 'உரையாடலைத் தொடங்க பயனரைத் தேடுங்கள்';

  @override
  String get convDefaultContact => 'தொடர்பு';

  @override
  String get dashboardUser => 'பயனர்';

  @override
  String get dashboardIncomingCall => 'உள்வரும் அழைப்பு';

  @override
  String get dashboardDecline => 'நிராகரிக்கவும்';

  @override
  String get dashboardAccept => 'ஏற்கவும்';

  @override
  String get dashboardActiveCall => 'செயலில் உள்ள அழைப்பு — திரும்பத் தொட்டு';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'புதுப்பிப்பு கிடைக்கிறது $version';
  }

  @override
  String get dashboardUpdate => 'புதுப்பிக்கவும்';

  @override
  String get dashboardWhatsNew => 'என்ன புதியது';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version இல் என்ன புதியது';
  }

  @override
  String get dashboardInstalling => 'நிறுவப்படுகிறது...';

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
  String get contactRequestsTitle => 'தொடர்புகள்';

  @override
  String get messengerContactRequestsSection => 'தொடர்பு கோரிக்கைகள்';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count புதிய கோரிக்கைகள்',
      one: '1 புதிய கோரிக்கை',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'தேடல்';

  @override
  String get contactRequestsIncoming => 'உள்வரும்';

  @override
  String get contactRequestsSent => 'அனுப்பப்பட்டது';

  @override
  String get contactRequestsSearchHint => 'புனைப்பெயர் அல்லது மின்னஞ்சல்';

  @override
  String get contactRequestSent => 'கோரிக்கை அனுப்பப்பட்டது';

  @override
  String get contactRequestsNoUsers => 'பயனர்கள் கிடைக்கவில்லை';

  @override
  String get contactRequestsSearchHelp =>
      'துல்லியமான புனைப்பெயர் அல்லது மின்னஞ்சலை உள்ளிடவும்\nமற்றும் தேடலை அழுத்தவும்';

  @override
  String get contactRequestsSendTooltip => 'கோரிக்கையை அனுப்பவும்';

  @override
  String get contactRequestTitle => 'தொடர்பு கோரிக்கை';

  @override
  String contactRequestConfirm(String name) {
    return '$name க்கு தொடர்பு கோரிக்கையை அனுப்பவா?';
  }

  @override
  String get contactRequestSend => 'அனுப்பவும்';

  @override
  String get contactRequestsNoIncoming => 'உள்வரும் கோரிக்கைகள் இல்லை';

  @override
  String get contactRequestsNoSent => 'அனுப்பிய கோரிக்கைகள் இல்லை';

  @override
  String get contactRequestStatusPending => 'பதில் காத்திருக்கிறது';

  @override
  String get contactRequestStatusAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get contactRequestStatusRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get userSearchTitle => 'பயனரைத் தேடுங்கள்';

  @override
  String get userSearchHint => 'புனைப்பெயர், தொலைபேசி அல்லது மின்னஞ்சல்';

  @override
  String get userSearchHelper =>
      '@புனைப்பெயர், மின்னஞ்சல் அல்லது பெயரை தேடவும்';

  @override
  String get userSearchNoUsers => 'பயனர்கள் கிடைக்கவில்லை';

  @override
  String get userProfileShareContact => 'தொடர்பை பகிரவும்';

  @override
  String get userProfileShareContactDesc => 'தொடர்பு இணைப்பை அனுப்பவும்';

  @override
  String get userProfileCopyLink => 'இணைப்பை நகலெடுக்கவும்';

  @override
  String get userProfileCopied => 'நகலெடுக்கப்பட்டது';

  @override
  String get userProfileTitle => 'சுயவிவரம்';

  @override
  String get userProfileLoadError => 'சுயவிவர ஏற்றுதல் பிழை';

  @override
  String get userProfileMessage => 'செய்தி';

  @override
  String get userProfileCall => 'அழைப்பு';

  @override
  String get userProfileRequestSent => 'கோரிக்கை அனுப்பப்பட்டது';

  @override
  String get userProfileAccept => 'ஏற்கவும்';

  @override
  String get userProfileDecline => 'நிராகரிக்கவும்';

  @override
  String get userProfileAddToContacts => 'தொடர்புகளுக்கு சேர்க்கவும்';

  @override
  String get userProfileMediaTab => 'ஊடகம்';

  @override
  String get userProfileFilesTab => 'கோப்புகள்';

  @override
  String get userProfileLinksTab => 'இணைப்புகள்';

  @override
  String get userProfileRecordingsTab => 'பதிவுகள்';

  @override
  String get userProfileSummariesTab => 'சுருக்கங்கள்';

  @override
  String get userProfileNoMedia => 'ஊடக கோப்புகள் இல்லை';

  @override
  String get userProfileNoFiles => 'கோப்புகள் இல்லை';

  @override
  String get userProfileNoLinks => 'இணைப்புகள் இல்லை';

  @override
  String get userProfileNoRecordings => 'பதிவுகள் இல்லை';

  @override
  String get userProfileNoSummaries => 'சுருக்கங்கள் இல்லை';

  @override
  String get userProfileMeetingSummary => 'சந்திப்பு சுருக்கம்';

  @override
  String get userProfileFailedOpenChat => 'அரட்டை திறக்க முடியவில்லை';

  @override
  String get sharedMediaTitle => 'ஊடகம் மற்றும் கோப்புகள்';

  @override
  String get sharedMediaTab => 'ஊடகம்';

  @override
  String get sharedFilesTab => 'கோப்புகள்';

  @override
  String get sharedLinksTab => 'இணைப்புகள்';

  @override
  String get sharedNoMedia => 'ஊடக கோப்புகள் இல்லை';

  @override
  String get sharedNoFiles => 'கோப்புகள் இல்லை';

  @override
  String get sharedNoLinks => 'இணைப்புகள் இல்லை';

  @override
  String get shareToChat => 'அரட்டைக்கு அனுப்பவும்';

  @override
  String get shareSelectChat => 'அரட்டை தேர்ந்தெடுக்கவும்';

  @override
  String get shareNoChats => 'அரட்டைகள் இல்லை';

  @override
  String shareFilesCount(int count) {
    return '$count கோப்புகள்';
  }

  @override
  String get contactsTitle => 'தொடர்புகள்';

  @override
  String get contactsAddTooltip => 'தொடர்பைச் சேர்க்கவும்';

  @override
  String get contactsSearchHint => 'தொடர்புகளைத் தேடவும்...';

  @override
  String get contactsNotFound => 'எதுவும் கிடைக்கவில்லை';

  @override
  String get contactsEmpty => 'தொடர்புகள் இல்லை';

  @override
  String get contactsAdd => 'தொடர்பைச் சேர்க்கவும்';

  @override
  String get contactsPendingConfirmation => 'உறுதிப்படுத்தல் நிலுவையில் உள்ளது';

  @override
  String get contactsMessage => 'செய்தி';

  @override
  String get contactsCall => 'அழைப்பு';

  @override
  String get contactsResend => 'கோரிக்கையை மீண்டும் அனுப்பவும்';

  @override
  String get contactsResendTimeout =>
      '24 மணி நேரத்தில் மீண்டும் முயற்சிக்கவும்';

  @override
  String get contactsResent => 'விண்ணப்பம் மீண்டும் அனுப்பப்பட்டது';

  @override
  String get contactsWantsToConnect => 'உங்களுடன் இணைக்க விரும்புகிறது';

  @override
  String get contactsSearchPeople => 'மக்களைத் தேடுங்கள்';

  @override
  String get notesTitle => 'குறிப்புகள்';

  @override
  String get notesAssistantSpeaking => 'உதவியாளர் பேசுகிறது...';

  @override
  String get notesListening => 'கேட்கிறது...';

  @override
  String get notesEmpty => 'குறிப்புகள் இல்லை';

  @override
  String get notesEmptyHint =>
      'உரை மாற்ற மைக்ரோஃபோனை அழுத்தவும்\nஅல்லது கையேடு உள்ளீட்டிற்கு + அழுத்தவும்';

  @override
  String get notesDeleteConfirm => 'குறிப்பை நீக்கவா?';

  @override
  String get notesNew => 'புதிய குறிப்பு';

  @override
  String get notesEdit => 'தொகு';

  @override
  String get notesTitleHint => 'தலைப்பு';

  @override
  String get notesContentHint => 'உங்கள் எண்ணங்களை எழுதுங்கள்...';

  @override
  String get calendarTitle => 'நாட்காட்டி';

  @override
  String get calendarStop => 'நிறுத்து';

  @override
  String get calendarVoiceInput => 'குரல் உள்ளீடு';

  @override
  String get calendarNewEvent => 'புதிய நிகழ்வு';

  @override
  String get calendarAssistantSpeaking => 'உதவியாளர் பேசுகிறது...';

  @override
  String get calendarListening => 'கேட்கிறது...';

  @override
  String calendarInvitations(int count) {
    return 'அழைப்புகள் ($count)';
  }

  @override
  String get calendarNoEvents => 'நிகழ்வுகள் இல்லை';

  @override
  String get calendarDayMon => 'திங்கள்';

  @override
  String get calendarDayTue => 'செவ்வாய்';

  @override
  String get calendarDayWed => 'புதன்';

  @override
  String get calendarDayThu => 'வியாழன்';

  @override
  String get calendarDayFri => 'வெள்ளி';

  @override
  String get calendarDaySat => 'சனி';

  @override
  String get calendarDaySun => 'ஞாயிறு';

  @override
  String get calendarEnterRoom => 'அறைக்குள் செல்லவும்';

  @override
  String get calendarMeeting => 'சந்திப்பு';

  @override
  String calendarLocationPrefix(String location) {
    return 'இடம்: $location';
  }

  @override
  String get calendarEditEvent => 'தொகு';

  @override
  String get calendarTitleHint => 'தலைப்பு';

  @override
  String get calendarDescriptionHint => 'விவரணம்';

  @override
  String get calendarTypeEvent => 'நிகழ்வு';

  @override
  String get calendarTypeMeeting => 'சந்திப்பு';

  @override
  String get calendarTypeReminder => 'நினைவூட்டல்';

  @override
  String get calendarTypeLabel => 'வகை';

  @override
  String get calendarMeetingLink => 'சந்திப்பு இணைப்பு';

  @override
  String get calendarLocationHint => 'இடம்';

  @override
  String get calendarDateLabel => 'தேதி';

  @override
  String get calendarTimeLabel => 'நேரம்';

  @override
  String get calendarReminderLabel => 'நினைவூட்டல்';

  @override
  String get calendarReminderNone => 'இல்லை';

  @override
  String get calendarReminder15min => '15 நிமிடங்களுக்கு முன்';

  @override
  String get calendarReminder30min => '30 நிமிடங்களுக்கு முன்';

  @override
  String get calendarReminder1hour => '1 மணி நேரத்திற்கு முன்';

  @override
  String get calendarRepeatLabel => 'மீண்டும்';

  @override
  String get calendarRepeatNone => 'மீண்டும் இல்லை';

  @override
  String get calendarRepeatDaily => 'ஒவ்வொரு நாளும்';

  @override
  String get calendarRepeatWeekly => 'ஒவ்வொரு வாரமும்';

  @override
  String get calendarRepeatMonthly => 'ஒவ்வொரு மாதமும்';

  @override
  String get calendarRepeatYearly => 'ஒவ்வொரு ஆண்டும்';

  @override
  String get calendarParticipants => 'பங்கேற்பாளர்கள்';

  @override
  String get calendarAddParticipant => 'சேர்க்கவும்';

  @override
  String get calendarSearchContacts => 'தொடர்புகளை தேடுங்கள்...';

  @override
  String get calendarNoContacts => 'தொடர்புகள் இல்லை';

  @override
  String get calendarStatusAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get calendarStatusDeclined => 'நிராகரிக்கப்பட்டது';

  @override
  String get calendarStatusMaybe => 'ஏற்கலாம்';

  @override
  String get calendarStatusPending => 'நிலுவையில்';

  @override
  String get calendarEndTime => 'முடிவு நேரம்';

  @override
  String get calendarYourAnswer => 'உங்கள் பதில்:';

  @override
  String get calendarOrganizer => 'நிர்வாகி';

  @override
  String calendarDeleteError(String error) {
    return 'அழிக்க முடியவில்லை: $error';
  }

  @override
  String get calendarRsvpAccept => 'ஏற்கவும்';

  @override
  String get calendarRsvpMaybe => 'ஏற்கலாம்';

  @override
  String get calendarRsvpDecline => 'நிராகரிக்கவும்';

  @override
  String get callHistoryTitle => 'அழைப்புகள்';

  @override
  String get callHistoryTab => 'அழைப்பு வரலாறு';

  @override
  String get callHistoryTempMeeting => 'தற்காலிக கூட்டம்';

  @override
  String get callHistoryCopy => 'நகலெடுக்கவும்';

  @override
  String get callHistoryLinkCopied => 'இணைப்பு நகலெடுக்கப்பட்டது';

  @override
  String get callHistoryShare => 'பகிரவும்';

  @override
  String get callHistoryEnter => 'உள்ளிடவும்';

  @override
  String get callHistoryAlreadyInCall => 'ஏற்கனவே அழைப்பில் உள்ளீர்கள்';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'மற்ற பக்கம் கண்டறிய முடியவில்லை';

  @override
  String get callHistoryContacts => 'தொடர்புகள்';

  @override
  String get callHistoryFailedLoadRoom => 'உங்கள் அறையை ஏற்ற முடியவில்லை';

  @override
  String get callHistoryYourRoom => 'உங்கள் அறை';

  @override
  String get callHistoryCreateMeeting => 'சந்திப்பு உருவாக்கவும்';

  @override
  String get callHistoryMeetingSummaries => 'சந்திப்பு சுருக்கங்கள்';

  @override
  String get callHistoryMeetingRecordings => 'சந்திப்பு பதிவுகள்';

  @override
  String get callHistoryNoCalls => 'அழைப்புகள் இல்லை';

  @override
  String get callHistoryMissed => 'தவறவிட்டது';

  @override
  String get callHistoryRecording => 'பதிவு';

  @override
  String get callHistorySummary => 'சுருக்கம்';

  @override
  String get callHistoryCallAgain => 'மீண்டும் அழைக்கவும்';

  @override
  String callHistoryTodayTime(String time) {
    return 'இன்று, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'நேற்று, $time';
  }

  @override
  String get callHistoryUnknown => 'அறியப்படாதது';

  @override
  String get callHistoryDetails => 'அழைப்பு விவரங்கள்';

  @override
  String get callHistoryOutgoing => 'வெளியேறும் அழைப்பு';

  @override
  String get callHistoryIncoming => 'உள்வரும் அழைப்பு';

  @override
  String callHistoryDuration(String duration) {
    return 'கால அளவு: $duration';
  }

  @override
  String get callHistoryWithAI => 'AI உதவியுடன்';

  @override
  String get callHistoryParticipants => 'பங்கேற்பாளர்கள்';

  @override
  String get callDetailYouSuffix => '(நீங்கள்)';

  @override
  String get callHistoryMeetingSummary => 'சந்திப்பு சுருக்கம்';

  @override
  String get callHistoryMoreDetails => 'மேலும் விவரங்கள்';

  @override
  String get callHistorySummaryProcessing => 'சுருக்கம் செயலாக்கம்...';

  @override
  String get callHistoryMeetingRecording => 'சந்திப்பு பதிவு';

  @override
  String get callHistoryProcessing => 'செயலாக்கம்...';

  @override
  String get callHistoryCreateTranscript => 'மொழிபெயர்ப்பு உருவாக்கவும்';

  @override
  String get callHistoryNoSummaries => 'சுருக்கங்கள் இல்லை';

  @override
  String get callHistoryRecordDuringCall =>
      'அழைப்பின் போது \"பதிவு\" அழுத்தவும்';

  @override
  String callHistoryMeetingTime(String time) {
    return 'சந்திப்பு $time';
  }

  @override
  String get callHistoryTranscribing => 'மொழிபெயர்த்து சுருக்கம் செய்கிறது...';

  @override
  String get callHistoryTranscriptCreated => 'மொழிபெயர்ப்பு உருவாக்கப்பட்டது';

  @override
  String get callHistoryNoRecordings => 'பதிவுகள் இல்லை';

  @override
  String callHistoryRecordingDate(String date) {
    return 'பதிவு $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'பதிவு கிடைக்கவில்லை';

  @override
  String get callHistoryTranscriptReady => 'மொழிபெயர்ப்பு தயாராக உள்ளது';

  @override
  String get callHistoryTranscript => 'மொழிபெயர்ப்பு';

  @override
  String get callHistoryKeyPoints => 'முக்கிய புள்ளிகள்';

  @override
  String get callHistoryTasks => 'பணிகள்';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'ஒதுக்கப்பட்டது: $assignee';
  }

  @override
  String get callHistoryDecisions => 'முடிவுகள்';

  @override
  String get callHistoryShowTranscript => 'முழு மொழிபெயர்ப்பை காண்பிக்கவும்';

  @override
  String get profileScanQr => 'QR ஸ்கேன் செய்யவும்';

  @override
  String get profileMyQrCode => 'என் QR குறியீடு';

  @override
  String profileAddMeShare(String userId) {
    return 'என்னை Taler ID இல் சேர்க்கவும்!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'உங்களைச் சேர்க்க இந்தக் குறியீட்டை காட்டவும்';

  @override
  String get profileEditDesc =>
      'பெயர், குடும்பப்பெயர், தந்தையின் பெயர், பிறந்த தேதி';

  @override
  String get profileAboutMe => 'என்னைப் பற்றி';

  @override
  String get profileAboutMeDesc =>
      'மதிப்புகள், திறன்கள், ஆர்வங்கள் மற்றும் மேலும்';

  @override
  String get profileNotes => 'குறிப்புகள்';

  @override
  String get profileNotesDesc => 'சிந்தனைகள், யோசனைகள் மற்றும் குறிப்புகள்';

  @override
  String get profileAvatarUpdated => 'அவதார் புதுப்பிக்கப்பட்டது';

  @override
  String get profileNickname => 'புனைப்பெயர்';

  @override
  String get profileNotSet => 'அமைக்கப்படவில்லை';

  @override
  String get profileChangeNickname => 'புனைப்பெயரை மாற்றவும்';

  @override
  String get profileNicknameUpdated => 'புனைப்பெயர் புதுப்பிக்கப்பட்டது';

  @override
  String get profileShareLabel => 'பகிரவும்';

  @override
  String get profileScanQrCode => 'QR குறியீட்டை ஸ்கேன் செய்யவும்';

  @override
  String get profilePointCamera => 'QR குறியீட்டில் கேமராவை நோக்கவும்';

  @override
  String get profilePhotoCamera => 'புகைப்படம் எடுக்கவும்';

  @override
  String get profilePhotoGallery => 'கேலரியில் இருந்து தேர்வு செய்யவும்';

  @override
  String get editProfilePatronymic => 'தந்தையின் பெயர் (விருப்பத்தேர்வு)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'என்னைப் பற்றி';

  @override
  String get aboutMeClickToFill => 'நிரப்ப கிளிக் செய்யவும்';

  @override
  String get aboutMeCoreValues => 'மூல மதிப்புகள்';

  @override
  String get aboutMeWorldview => 'உலகக் காட்சி';

  @override
  String get aboutMeSkills => 'திறன்கள்';

  @override
  String get aboutMeInterests => 'ஆர்வங்கள்';

  @override
  String get aboutMeDesires => 'ஆசைகள்';

  @override
  String get aboutMeBackground => 'சுயவிவரம்';

  @override
  String get aboutMeLikes => 'விருப்பங்கள்';

  @override
  String get aboutMeDislikes => 'விருப்பமின்மை';

  @override
  String get aboutMeDeleteSection => 'பகுதியை நீக்கவா?';

  @override
  String get aboutMeDeleteConfirm =>
      'இந்தப் பகுதியில் உள்ள அனைத்து தரவும் நீக்கப்படும்.';

  @override
  String aboutMeConnectionError(String error) {
    return 'இணைப்பு பிழை: $error';
  }

  @override
  String get aboutMeVisibility => 'தெரிவுத்தன்மை';

  @override
  String get aboutMeTags => 'குறிச்சொற்கள்';

  @override
  String get aboutMeAddTag => 'குறிச்சொல்லை சேர்க்கவும்...';

  @override
  String get aboutMeDescription => 'விளக்கம்';

  @override
  String get aboutMeDescribeLong => 'மேலும் சொல்லவும்...';

  @override
  String get aboutMeVisibilityEveryone => 'அனைவரும்';

  @override
  String get aboutMeVisibilityContacts => 'தொடர்புகள்';

  @override
  String get aboutMeVisibilityOnlyMe => 'நான் மட்டும்';

  @override
  String get settingsProfileSubtitle => 'சுயவிவரம்';

  @override
  String get settingsWallpaper => 'சுவரொட்டி';

  @override
  String get settingsWallpaperDesc => 'முழு பயன்பாட்டிற்கும் பின்னணி படம்';

  @override
  String get settingsWallpaperNone => 'எதுவும் இல்லை';

  @override
  String get settingsAccount => 'கணக்கு';

  @override
  String get settingsKycVerification => 'அடையாள சரிபார்ப்பு (KYC)';

  @override
  String get settingsOrganizations => 'அமைப்புகள்';

  @override
  String get incomingCallLabel => 'உள்வரும் அழைப்பு';

  @override
  String get incomingCallDecline => 'நிராகரிக்க';

  @override
  String get incomingCallAccept => 'ஏற்க';

  @override
  String get meshIncomingCallLabel => '📡 உள்வரும் மெஷ் அழைப்பு';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'மெஷ் சாதனம் $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'முதலில் நடப்பு அழைப்பை முடிக்கவும்';

  @override
  String get callPopupTransportTitle => 'அழைப்பு மூலம்';

  @override
  String get callPopupTransportMesh => '📡 மெஷ் (பியர்-டூ-பியர்)';

  @override
  String get callPopupTransportLk => '📞 சர்வர்';

  @override
  String get callPopupTransportMeshUnavailable =>
      'தொடர்பு மெஷ் மூலம் அணுக முடியவில்லை';

  @override
  String get meshOnboardingTitle =>
      '📡 மெஷ் அழைப்புகள் பயன்பாடு திறந்திருக்க வேண்டும்';

  @override
  String get meshOnboardingBody =>
      'தொலைபேசி பூட்டப்பட்டிருந்தால், மெஷ் அழைப்புகள் ~30 விநாடிகளுக்குப் பிறகு கைவிடப்படலாம் (iOS வரம்பு).';

  @override
  String get meshOnboardingAck => 'புரிந்தது';

  @override
  String get meshHistoryBadge => '📡 மெஷ்';

  @override
  String get meshHistoryNoChatAvailable => 'தொடர்பு உங்கள் பட்டியலில் இல்லை';

  @override
  String get meshCallStatusInviting => 'அழைக்கிறது…';

  @override
  String get meshCallStatusConnecting => 'இணைக்கிறது…';

  @override
  String get meshCallEndedUserHangup => 'அழைப்பு முடிந்தது';

  @override
  String get meshCallEndedRemoteHangup => 'பியர் மூலம் முடிக்கப்பட்டது';

  @override
  String get meshCallEndedRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get meshCallEndedNoAnswer => 'பதில் இல்லை';

  @override
  String get meshCallEndedConnectionLost => 'இணைப்பு இழந்தது';

  @override
  String get meshCallEndedError => 'இணைப்பு பிழை';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 மெஷ் · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 மெஷ்';

  @override
  String get batteryExemptionTitle => '📡 நம்பகமான மெஷ் அழைப்புகள்';

  @override
  String get batteryExemptionBody =>
      'பயன்பாட்டை பேட்டரி கட்டுப்பாடுகள் இல்லாமல் இயக்க அனுமதிக்கவும், எனவே Android பின்னணியில் மெஷை முடிக்காது.';

  @override
  String get batteryExemptionAccept => 'அமைப்புகளை திறக்கவும்';

  @override
  String get batteryExemptionDismiss => 'இப்போது வேண்டாம்';

  @override
  String get groupCamera => 'கேமரா';

  @override
  String get groupGallery => 'கேலரி';

  @override
  String get groupAvatarUpdated => 'குழு அவதார் புதுப்பிக்கப்பட்டது';

  @override
  String get groupNameTitle => 'குழு பெயர்';

  @override
  String get groupEnterName => 'பெயரை உள்ளிடவும்';

  @override
  String get groupDescriptionTitle => 'குழு விளக்கம்';

  @override
  String get groupEnterDescription => 'குழு விளக்கத்தை உள்ளிடவும்';

  @override
  String get groupChangeRoleTitle => 'பாத்திரத்தை மாற்றவும்';

  @override
  String get groupRemoveMemberTitle => 'உறுப்பினரை நீக்கவும்';

  @override
  String get groupDescription => 'விளக்கம்';

  @override
  String get groupAddDescription => 'குழு விளக்கத்தைச் சேர்க்கவும்';

  @override
  String get groupNoDescription => 'விளக்கம் இல்லை';

  @override
  String get groupMediaAndFiles => 'ஊடகங்கள் மற்றும் கோப்புகள்';

  @override
  String get groupMuteNotifications => 'அறிவிப்புகளை மவுட் செய்யவும்';

  @override
  String get groupMuted => 'மவுட் செய்யப்பட்டது';

  @override
  String get groupNoResults => 'முடிவுகள் இல்லை';

  @override
  String get authInvalidCode => 'தவறான குறியீடு. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginSubtitle =>
      'மின்னஞ்சல் மற்றும் கடவுச்சொல்லைப் பயன்படுத்தவும்';

  @override
  String get emailRequired => 'மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get emailInvalid => 'தவறான மின்னஞ்சல்';

  @override
  String get passwordRequired => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'முழு Taler சூழலுக்கான ஒரு கணக்கு';

  @override
  String get usernameOptional => 'பயனர்பெயர் (விருப்பத்தேர்வு)';

  @override
  String get usernameMinLength => 'குறைந்தபட்சம் 3 எழுத்துக்கள்';

  @override
  String get usernameMaxLength => 'அதிகபட்சம் 30 எழுத்துக்கள்';

  @override
  String get usernameInvalid => 'எழுத்துக்கள், இலக்கங்கள் மற்றும் _ மட்டுமே';

  @override
  String get biometricLoginReason => 'Taler ID இல் உள்நுழைக';

  @override
  String get docTypePassport => 'கடவுச்சீட்டு';

  @override
  String get docTypeIdCard => 'அடையாள அட்டை';

  @override
  String get docTypeDriverLicense => 'ஓட்டுநர் உரிமம்';

  @override
  String get docTypeResidencePermit => 'வசிப்பிட அனுமதி';

  @override
  String addressApartment(String number) {
    return 'அபார்ட்மெண்ட் $number';
  }

  @override
  String get failedToUpdateProfile => 'சுயவிவரத்தை புதுப்பிக்க முடியவில்லை';

  @override
  String get failedToStartKyb => 'KYB சரிபார்ப்பை தொடங்க முடியவில்லை';

  @override
  String get orgUpdated => 'அமைப்பு புதுப்பிக்கப்பட்டது';

  @override
  String get failedToUpdateOrg => 'அமைப்பை புதுப்பிக்க முடியவில்லை';

  @override
  String get failedToChangeRole => 'பாத்திரத்தை மாற்ற முடியவில்லை';

  @override
  String get failedToRemoveMember => 'உறுப்பினரை நீக்க முடியவில்லை';

  @override
  String get capabilityMessagesTitle => 'செய்திகள்';

  @override
  String get capabilityMessagesDesc =>
      'செய்திகளைச் சரிபார்க்கவும் அல்லது யாருக்காவது எழுதவும். உதாரணமாக: \"விக்டருக்கு எழுதவும்: ஒரு மணி நேரத்தில் அங்கு இருப்பேன்\"';

  @override
  String get capabilityCallsTitle => 'அழைப்புகள்';

  @override
  String get capabilityCallsDesc =>
      'எந்த தொடர்புக்கும் குரல் மூலம் அழைக்கவும். உதாரணமாக: \"விக்டர் விக்டரோவை அழைக்கவும்\"';

  @override
  String get capabilityChatTitle => 'அரட்டை வரலாறு';

  @override
  String get capabilityChatDesc =>
      'நான் அரட்டை வரலாற்றை பகுப்பாய்வு செய்வேன். உதாரணமாக: \"நாம் விக்டருடன் என்ன விவாதித்தோம்?\"';

  @override
  String get capabilityProfileTitle => 'சுயவிவரம்';

  @override
  String get capabilityProfileDesc =>
      'நான் உங்கள் சுயவிவரத்தை காட்டுவேன் அல்லது புதுப்பிப்பேன். உதாரணமாக: \"என் சுயவிவரத்தை காட்டு\"';

  @override
  String get capabilityCoachingTitle => 'பயிற்சி';

  @override
  String get capabilityCoachingDesc =>
      'முறைகள்: ICF பயிற்சி, உளவியல் நிபுணர், மனிதவள ஆலோசனை. சொல்லுங்கள்: \"பயிற்சி செய்யலாம்\"';

  @override
  String get capabilityCalendarTitle => 'நாட்காட்டி';

  @override
  String get capabilityCalendarDesc =>
      'ஒரு கூட்டத்தை திட்டமிடுங்கள் அல்லது நினைவூட்டலை அமைக்கவும். உதாரணமாக: \"நாளை 15:00 மணிக்கு விக்டருடன் ஒரு கூட்டத்தை திட்டமிடுங்கள்\"';

  @override
  String get capabilityNotesTitle => 'குறிப்புகள்';

  @override
  String get capabilityNotesDesc =>
      'ஒரு எண்ணத்தை சேமிக்கவும் அல்லது சமீபத்திய குறிப்புகளை படிக்கவும். உதாரணமாக: \"ஒரு யோசனையை எழுதுங்கள்...\" அல்லது \"சமீபத்திய குறிப்புகளை படிக்கவும்\"';

  @override
  String get assistantCallConfirm => 'ஒரு அழைப்பை செய்யவா?';

  @override
  String get callNoAnswer => 'பதில் இல்லை';

  @override
  String get contactDelete => 'தொடர்பை நீக்கு';

  @override
  String get contactDeleteTitle => 'தொடர்பை நீக்கு';

  @override
  String get contactDeleteConfirm =>
      'நீங்கள் உறுதியாக இருக்கிறீர்களா? இந்த தொடர்பு நீக்கப்படும்.';

  @override
  String get contactBlock => 'தடுப்பு';

  @override
  String get contactBlockTitle => 'பயனரை தடை செய்';

  @override
  String get contactBlockConfirm =>
      'இந்த பயனர் உங்களுக்கு செய்தி அனுப்பவோ அல்லது அழைக்கவோ முடியாது.';

  @override
  String get contactUnblock => 'தடையை நீக்கு';

  @override
  String get contactBlocked => 'தடுக்கப்பட்டது';

  @override
  String get contactYouAreBlocked => 'இந்த பயனர் உங்களை தடுத்துள்ளார்';

  @override
  String get chatBlockedByYou => 'நீங்கள் இந்த பயனரை தடுத்துள்ளீர்கள்';

  @override
  String get chatYouAreBlocked => 'இந்த பயனர் உங்களை தடுத்துள்ளார்';

  @override
  String get chatNotContacts =>
      'அவர்களுக்கு செய்தி அனுப்ப இந்த பயனரை தொடர்புகளில் சேர்க்கவும்';

  @override
  String get contactRevokeRequest => 'கோரிக்கையை ரத்து செய்';

  @override
  String get messengerPoll => 'வாக்கெடுப்பு';

  @override
  String get messengerCreatePoll => 'வாக்கெடுப்பை உருவாக்கு';

  @override
  String get messengerPollQuestion => 'கேள்வி';

  @override
  String messengerPollOption(int number) {
    return 'விருப்பம் $number';
  }

  @override
  String get messengerPollAddOption => 'விருப்பத்தை சேர்க்கவும்';

  @override
  String get messengerPollAnonymous => 'அடையாளம் தெரியாத வாக்களிப்பு';

  @override
  String get messengerPollMultiple => 'பல தேர்வு';

  @override
  String get messengerPollCreateError => 'வாக்கெடுப்பை உருவாக்க முடியவில்லை';

  @override
  String get messengerPollUnavailable => 'வாக்கெடுப்பு கிடைக்கவில்லை';

  @override
  String get messengerPollMultipleNote => 'நீங்கள் பலவற்றை தேர்வு செய்யலாம்';

  @override
  String messengerPollVotes(int count) {
    return '$count வாக்குகள்';
  }

  @override
  String get messengerVideoMessage => 'வீடியோ செய்தி';

  @override
  String get messengerVideoRecordError => 'வீடியோ பதிவு பிழை';

  @override
  String get messengerVideoPlaybackError => 'வீடியோவை இயக்க முடியவில்லை';

  @override
  String get messengerGalleryAccessError => 'கேலரிக்கு அணுகல் இல்லை';

  @override
  String get messengerSearchInChat => 'அரட்டையில் தேடுங்கள்...';

  @override
  String get messengerSaveToFavorites => 'பிடித்தவற்றில் சேமிக்கவும்';

  @override
  String get messengerSavedToFavorites => 'பிடித்தவற்றில் சேமிக்கப்பட்டது';

  @override
  String get messengerSearchInMessages => 'செய்திகளில் தேடுங்கள்...';

  @override
  String messengerFoundInMessages(int count) {
    return 'செய்திகளில் கண்டறியப்பட்டது ($count)';
  }

  @override
  String get messengerGroupDefault => 'குழு';

  @override
  String get messengerUserDefault => 'பயனர்';

  @override
  String get messengerPin => 'பின்';

  @override
  String get messengerUnpin => 'அன்பின்';

  @override
  String get messengerArchive => 'காப்பகம்';

  @override
  String get messengerUnarchive => 'காப்பகத்தை நீக்கு';

  @override
  String get messengerDeleteChat => 'அரட்டையை நீக்கு';

  @override
  String get messengerDeleteChatTitle => 'அரட்டையை நீக்கவா?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '$name உடன் அரட்டையை நீக்கவா? இது திரும்ப பெற முடியாது.';
  }

  @override
  String get messengerCreateChannel => 'சேனல் உருவாக்கவும்';

  @override
  String get messengerChannelName => 'பெயர்';

  @override
  String get messengerChannelDescription => 'விளக்கம் (விருப்பத்தேர்வு)';

  @override
  String get messengerChannelCreateError => 'சேனல் உருவாக்க முடியவில்லை';

  @override
  String get messengerFilterAll => 'அனைத்தும்';

  @override
  String get messengerFilterUnread => 'படிக்காதவை';

  @override
  String get messengerFilterPersonal => 'தனிப்பட்டவை';

  @override
  String get messengerFilterGroups => 'குழுக்கள்';

  @override
  String get messengerFilterChannels => 'சேனல்கள்';

  @override
  String get messengerArchivedSection => 'காப்பகப்படுத்தப்பட்டது';

  @override
  String get messengerSavedSection => 'பிடித்தவை';

  @override
  String get messengerSavedSubtitle => 'நினைவில் சேமிக்கவும்';

  @override
  String messengerArchiveTitle(int count) {
    return 'காப்பகம் ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'காப்பகம் காலியாக உள்ளது';

  @override
  String messengerYouPrefix(String message) {
    return 'நீங்கள்: $message';
  }

  @override
  String get messengerMissedCall => 'தவறவிட்ட அழைப்பு';

  @override
  String get messengerSavedTitle => 'பிடித்தவை';

  @override
  String get messengerNoSavedMessages => 'சேமிக்கப்பட்ட செய்திகள் இல்லை';

  @override
  String get messengerSavedHint =>
      'ஒரு செய்தியை நீண்ட நேரம் அழுத்தவும் → \"பிடித்தவற்றில் சேமிக்கவும்\"';

  @override
  String get messengerDefaultFile => 'கோப்பு';

  @override
  String get messengerTopicDefault => 'பொது';

  @override
  String get messengerTopicNew => 'புதிய தலைப்பு';

  @override
  String get messengerTopicNameHint => 'தலைப்பு பெயர்';

  @override
  String get messengerTopicIcon => 'சின்னம்';

  @override
  String messengerTopicCount(int count) {
    return '$count தலைப்புகள்';
  }

  @override
  String get messengerNoTopics => 'தலைப்புகள் இல்லை';

  @override
  String get messengerNoMessages => 'செய்திகள் இல்லை';

  @override
  String get you => 'நீங்கள்';

  @override
  String get messengerThread => 'தொடர்';

  @override
  String get messengerThreadReply => 'பதில்';

  @override
  String get messengerThreadReplies => 'பதில்கள்';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'பதில்கள் இல்லை';

  @override
  String get messengerReplyHint => 'தொடருக்கு பதிலளிக்க...';

  @override
  String get messengerContactName => 'தொடர்பு பெயர்';

  @override
  String messengerOriginalName(String name) {
    return 'மூல பெயர்: $name';
  }

  @override
  String get messengerDisplayName => 'காட்சி பெயர்';

  @override
  String messengerShareContact(String name) {
    return 'Taler ID இல் தொடர்பு: $name';
  }

  @override
  String get messengerAutoDelete => 'செய்திகளை தானாக நீக்கு';

  @override
  String get messengerAutoDeleteOff => 'ஆஃப்';

  @override
  String get messengerAutoDelete7d => '7 நாட்கள்';

  @override
  String get messengerAutoDelete30d => '30 நாட்கள்';

  @override
  String get messengerAutoDelete90d => '90 நாட்கள்';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count நாட்கள்';
  }

  @override
  String get messengerSettingsHeader => 'அமைப்புகள்';

  @override
  String get messengerAdminOnly => 'நிர்வாகி மட்டும் இடுகை';

  @override
  String get messengerAdminOnlyDesc => 'உறுப்பினர்கள் படிக்க மட்டுமே முடியும்';

  @override
  String get messengerTopics => 'தலைப்புகள்';

  @override
  String get messengerTopicsDesc => 'அரட்டை தலைப்புகளாகப் பிரிக்கவும்';

  @override
  String get aiTwinSection => 'AI குரல் இரட்டை';

  @override
  String get aiTwinEnabled => 'AI இரட்டை இயக்கு';

  @override
  String get aiTwinEnabledDesc =>
      'நீங்கள் பதிலளிக்காவிட்டால், உங்கள் AI இரட்டை உங்கள் குரலில் அழைப்பை ஏற்கும்';

  @override
  String get aiTwinTimeout => 'பதில் நேரம் முடிவு';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds விநாடிகள்';
  }

  @override
  String get aiTwinPrompt => 'AI வழிமுறைகள்';

  @override
  String get aiTwinPromptSubtitle =>
      'AI இரட்டை எப்படி அறிமுகப்படுத்த வேண்டும் மற்றும் என்ன பேச வேண்டும்';

  @override
  String aiTwinPromptHint(String name) {
    return 'வணக்கம், இது $name அவர்களின் AI குரல் இரட்டை. $name இப்போது அழைப்பு ஏற்க முடியவில்லை. யார் அழைக்கிறார்கள் மற்றும் என்ன பற்றி என்பதை சொல்லுங்கள் — நான் அதை தெரிவிக்கிறேன்.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'தனிப்பயன் குரல் நகலெடுக்கும் விரைவில் வருகிறது. தற்போது AI $name அவர்களின் குரலில் பேசுகிறது.';
  }

  @override
  String get aiTwinDefaultName => 'உரிமையாளர்';

  @override
  String get aiTwinPromptReset => 'மீட்டமை';

  @override
  String get callHistoryAiTwinAnswered => 'AI இரட்டை பதிலளித்தது';

  @override
  String get callHistoryAiTwinSummary => 'அழைப்பு சுருக்கம்';

  @override
  String get callHistoryAiTwinTranscript => 'மொழிபெயர்ப்பு';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '$name அவர்களிடமிருந்து';
  }

  @override
  String get aiTwinOfferTitle => 'பதில் அளிக்கவில்லை';

  @override
  String aiTwinOfferBody(String name) {
    return '$name எடுத்துக்கொள்ளவில்லை. அவர்களின் AI குரல் நகலுடன் ஒரு செய்தி விடுக்கவா?';
  }

  @override
  String get aiTwinOfferBodyUser => 'பயனர்';

  @override
  String get aiTwinOfferAccept => 'ஆம், செய்தி விடுக்கவும்';

  @override
  String get aiTwinOfferKeepWaiting => 'காத்திருக்கவும்';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'உங்கள் AI பிரதிநிதி';

  @override
  String get aiTwinHeroSubtitle =>
      'நீங்கள் முடியாதபோது உங்கள் குரலில் அழைப்புகளை பதிலளிக்கிறது.';

  @override
  String get aiTwinProfileTitle => 'AI பிரதிநிதி';

  @override
  String get aiTwinProfileDesc => 'உங்கள் குரலில் அழைப்புகளை பதிலளிக்கிறது';

  @override
  String get aiTwinBadgeOn => 'ON';

  @override
  String get aiAnalystTitle => 'AI பகுப்பாய்வாளர்';

  @override
  String get aiAnalystSubtitle => 'கோப்புகள், பணிகள், பகுப்பாய்வு — Claude';

  @override
  String get channelsDiscover => 'சேனலை கண்டறியவும்';

  @override
  String get channelsSearchHint => 'சேனல்களை தேடவும்';

  @override
  String get channelsSubscribers => 'சந்தாதாரர்கள்';

  @override
  String get channelsSubscribe => 'சந்தா';

  @override
  String get channelsUnsubscribe => 'சந்தாவை ரத்து செய்யவும்';

  @override
  String get channelsSubscribedLabel => 'நீங்கள் சந்தா செய்துள்ளீர்கள்';

  @override
  String get channelsSettings => 'சேனல் அமைப்புகள்';

  @override
  String get channelsDelete => 'சேனலை நீக்கவும்';

  @override
  String get channelsDeleteConfirm => 'சேனலை நிரந்தரமாக நீக்கவா?';

  @override
  String get channelsEmpty => 'இன்னும் சேனல்கள் இல்லை';

  @override
  String get channelsOpen => 'திறக்கவும்';

  @override
  String get channelsNameLabel => 'பெயர்';

  @override
  String get channelsDescriptionLabel => 'விளக்கம்';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'உரிமையாளர் சந்தாவை ரத்து செய்ய முடியாது. சேனலை நீக்கவும்.';

  @override
  String get channelsNotFoundRedirect => 'சேனல் இனி இல்லை';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count தேடல்கள்',
      one: '$count தேடல்',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count கோப்புகள்',
      one: '$count கோப்பு',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count கட்டளைகள்',
      one: '$count கட்டளை',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count படங்கள்',
      one: '$count படம்',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count படிகள்',
      one: '$count படி',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$secondsசெ';
  }

  @override
  String get savedTitle => 'சேமிக்கப்பட்ட செய்திகள்';

  @override
  String get savedSubtitle => 'உங்கள் தனிப்பட்ட மேகம்';

  @override
  String get savedOpenError => 'சேமிக்கப்பட்ட செய்திகளைத் திறக்க முடியவில்லை';

  @override
  String get billingWalletTitle => 'பணப்பை';

  @override
  String get billingBuyPackage => 'பொதியை வாங்கவும்';

  @override
  String get billingCurrentBalance => 'தற்போதைய இருப்பு';

  @override
  String get billingPackagesTitle => 'பொதிகள்';

  @override
  String get billingPackagesUnavailable => 'பேக்கேஜ்கள் கிடைக்கவில்லை';

  @override
  String get billingRecentOperations => 'சமீபத்திய செயல்பாடுகள்';

  @override
  String get billingAllOperations => 'அனைத்து செயல்பாடுகள்';

  @override
  String get billingNoOperations => 'செயல்பாடுகள் இல்லை';

  @override
  String get billingOperationsTitle => 'செயல்பாடுகள்';

  @override
  String get billingOperationsEmptyTitle => 'இன்னும் செயல்பாடுகள் இல்லை';

  @override
  String get billingOperationsEmptySubtitle =>
      'AI அம்சங்களுக்கான டாப்-அப்கள் மற்றும் கட்டணங்கள் இங்கே தோன்றும்';

  @override
  String get billingPricebookTitle => 'அம்ச விலைகள்';

  @override
  String get billingPricebookUnavailable => 'விலைப்பட்டியல் கிடைக்கவில்லை';

  @override
  String get billingAiFeaturesTitle => 'AI அம்சங்கள்';

  @override
  String get billingInsufficientFundsTitle => 'போதுமான நிதி இல்லை';

  @override
  String get billingInsufficientFundsSubtitle =>
      'இந்த அம்சத்தை பயன்படுத்த உங்கள் இருப்பை டாப் அப் செய்யவும்.';

  @override
  String billingRequiredLine(String required) {
    return 'தேவை: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'உள்ளது: $available μTAL';
  }

  @override
  String get billingTopUp => 'டாப் அப்';

  @override
  String get billingCancel => 'ரத்து செய்';

  @override
  String get billingRetry => 'மீண்டும் முயற்சி செய்';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'இருப்பு குறைந்து வருகிறது: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'பணப்பை & இருப்பு';

  @override
  String get billingSectionHeader => 'பில்லிங் & AI';

  @override
  String get billingFeatureVoiceAssistant => 'குரல் உதவியாளர்';

  @override
  String get billingFeatureWebSearch => 'உதவியாளர் வலை தேடல்';

  @override
  String get billingFeatureAiTwin => 'குரல் இரட்டை';

  @override
  String get billingFeatureAiTwinLong => 'குரல் இரட்டை (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'வெளியீட்டு பாட்டி';

  @override
  String get billingFeatureOutboundCallLong => 'வெளியீட்டு அழைப்புப் பாட்டி';

  @override
  String get billingFeatureWhisperTranscribe => 'அழைப்பு உரை';

  @override
  String get billingFeatureMeetingSummary => 'AI அழைப்பு சுருக்கங்கள்';

  @override
  String get billingConfigureAiTwin => 'AI இரட்டையை அமைக்கவும்';

  @override
  String get billingWebSearchSubtitle => '(உதவியாளர் பயன்படுத்துகிறது)';

  @override
  String billingPackagePurchased(String balance) {
    return 'பேக்கேஜ் வாங்கப்பட்டது: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'பரிந்துரைக்கப்பட்டது';

  @override
  String get billingSessionTerminatedNoFunds =>
      'இருப்பு முடிந்தது — அமர்வு முடிந்தது';

  @override
  String get billingSessionTerminatedGeneric => 'உதவியாளர் அமர்வு முடிந்தது';

  @override
  String billingBuyForPrice(String price) {
    return '€$price க்கு வாங்கவும்';
  }

  @override
  String get billingTxTypeTopup => 'டாப்-அப்';

  @override
  String get billingTxTypeRefund => 'திருப்பி';

  @override
  String get billingTxTypeSpend => 'கட்டணம்';

  @override
  String get billingUnitMinute => 'நிமிடம்';

  @override
  String get billingUnitRequest => 'கோரிக்கை';

  @override
  String get billingUnitToken => 'டோக்கன்';

  @override
  String get billingUnitTokens1k => '1K டோக்கன்கள்';

  @override
  String get billingUnitCall => 'அழைப்பு';

  @override
  String get groupCallSelectParticipants => 'பங்கேற்பாளர்களை தேர்ந்தெடுக்கவும்';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'தேடல்';

  @override
  String get groupCallMaxReached => 'அதிகபட்சம் 7 பங்கேற்பாளர்கள்';

  @override
  String get groupCallLobbyTitle => 'குழு • லாபி';

  @override
  String groupCallHostLabel(String name) {
    return 'தொகுப்பாளர்: $name';
  }

  @override
  String get groupCallMicHint => 'இணைக்கும்போது மைக் செயல்படும்';

  @override
  String get groupCallCancel => 'ரத்து';

  @override
  String get groupCallNoAnswer => 'யாரும் பதிலளிக்கவில்லை';

  @override
  String get groupCallEndedByHost => 'தொகுப்பாளர் அழைப்பை முடித்தார்';

  @override
  String get groupCallAllLeft => 'அனைவரும் அழைப்பை விட்டு வெளியேறினர்';

  @override
  String get groupCallEnded => 'அழைப்பு முடிந்தது';

  @override
  String groupCallActiveTitle(int count) {
    return 'குழு • $count';
  }

  @override
  String get groupCallConnectionLost => 'இணைப்பு இழந்தது';

  @override
  String get groupCallMuteRequested =>
      'தொகுப்பாளர் அனைவரையும் மியூட் செய்ய கேட்டார்';

  @override
  String get groupCallUnmute => 'மியூட் நீக்கு';

  @override
  String get groupCallMute => 'மியூட்';

  @override
  String get groupCallMuteAll => 'அனைவரையும் மியூட் செய்யவும்';

  @override
  String get groupCallLeave => 'விட்டு வெளியேறு';

  @override
  String get groupCallStatusCalling => 'அழைக்கிறது…';

  @override
  String get groupCallStatusDeclined => 'நிராகரிக்கப்பட்டது';

  @override
  String get groupCallStatusTimeout => 'பதில் இல்லை';

  @override
  String get groupCallStatusLeft => 'விட்டு சென்றார்';

  @override
  String groupCallKickConfirm(String name) {
    return '$name ஐ அழைப்பில் இருந்து நீக்கவும்';
  }

  @override
  String get groupCallCancelAction => 'ரத்து';

  @override
  String get groupCallActiveBanner => 'செயலில் உள்ள அழைப்பு';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'குழு: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'குழு: $host';
  }

  @override
  String get groupCallCreateError => 'அழைப்பை உருவாக்க முடியவில்லை';

  @override
  String get groupCallJoinError => 'அழைப்பில் சேர முடியவில்லை';

  @override
  String get groupCallLivekitError => 'LiveKit பிழை';

  @override
  String get groupCallDone => 'முடிந்தது';

  @override
  String get groupCallNoResults => 'முடிவுகள் இல்லை';

  @override
  String get groupCallNoContacts => 'தொடர்புகள் இல்லை';

  @override
  String get meshGcContactOffline => 'இந்த Wi-Fi இல் இல்லை';

  @override
  String get meshGcOnlineViaMesh => 'மேஷ் மூலம் ஆன்லைன்';

  @override
  String get meshGcMaxInvitees =>
      'குழு அழைப்புகள் அதிகபட்சம் 4 அழைப்பாளர்களை (மொத்தம் 5 பேர்) ஆதரிக்கின்றன.';

  @override
  String get meshGcStart => 'குழு அழைப்பை தொடங்கு';

  @override
  String get meshGcCancel => 'ரத்து செய்';

  @override
  String get meshGcStatusCalling => 'அழைக்கிறது…';

  @override
  String get meshGcStatusJoined => 'சேர்ந்துவிட்டார்';

  @override
  String get meshGcStatusDeclined => 'நிராகரிக்கப்பட்டது';

  @override
  String get meshGcStatusNoAnswer => 'பதில் இல்லை';

  @override
  String get meshGcStatusConnectionFailed => 'இணைப்பு தோல்வியடைந்தது';

  @override
  String get meshGcStatusLeft => 'விட்டு சென்றார்';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne =>
      'முதலில் உங்கள் தற்போதைய அழைப்பை முடிக்கவும்.';

  @override
  String get presenceOnline => 'ஆன்லைன்';

  @override
  String get presenceLastSeenJustNow => 'இப்போதுதான் கடைசியாக காணப்பட்டது';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return '$minutes நிமிடங்களுக்கு முன் கடைசியாக காணப்பட்டது';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'இன்று $time மணிக்கு கடைசியாக காணப்பட்டது';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'நேற்று $time மணிக்கு கடைசியாக காணப்பட்டது';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return '$date அன்று கடைசியாக காணப்பட்டது';
  }

  @override
  String get presenceLastSeenRecently => 'சமீபத்தில் கடைசியாக காணப்பட்டது';

  @override
  String get privacySectionTitle => 'தனியுரிமை';

  @override
  String get privacyLastSeenLabel =>
      'உங்கள் கடைசி காணப்பட்ட நேரத்தை யார் பார்க்கிறார்கள்';

  @override
  String get privacyEveryone => 'எல்லோரும்';

  @override
  String get privacyContacts => 'தொடர்புகள் மட்டும்';

  @override
  String get privacyNobody => 'யாரும் இல்லை';

  @override
  String get voiceTurnOffTranslation => 'Turn off translator';

  @override
  String get informerBotTitle => 'Informer';

  @override
  String get informerBotSubtitle => 'Wallet and balance monitoring';
}
