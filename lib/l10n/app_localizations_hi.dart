// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'खोजें';

  @override
  String get appSubtitle => 'एकीकृत पारिस्थितिकी तंत्र पहचान';

  @override
  String get login => 'साइन इन करें';

  @override
  String get loginButton => 'साइन इन करें';

  @override
  String get register => 'खाता बनाएं';

  @override
  String get registerButton => 'खाता बनाएं';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get firstName => 'पहला नाम';

  @override
  String get lastName => 'अंतिम नाम';

  @override
  String get noAccount => 'खाता नहीं है?';

  @override
  String get createOne => 'एक बनाएं';

  @override
  String get haveAccount => 'पहले से खाता है?';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get passwordMinLength => 'न्यूनतम 8 अक्षर';

  @override
  String get invalidEmail => 'मान्य ईमेल दर्ज करें';

  @override
  String get fieldRequired => 'आवश्यक फ़ील्ड';

  @override
  String get twoFATitle => 'दो-कारक प्रमाणीकरण';

  @override
  String get twoFASubtitle => 'अपने प्रमाणीकरण ऐप से 6-अंकीय कोड दर्ज करें';

  @override
  String get twoFACode => '2FA कोड';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get tabProfile => 'प्रोफ़ाइल';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'संगठन';

  @override
  String get tabSettings => 'सेटिंग्स';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get phone => 'फ़ोन';

  @override
  String get country => 'देश';

  @override
  String get dateOfBirth => 'जन्म तिथि';

  @override
  String get documents => 'दस्तावेज़';

  @override
  String get addDocument => 'दस्तावेज़ जोड़ें';

  @override
  String get noDocuments => 'कोई दस्तावेज़ अपलोड नहीं किया गया';

  @override
  String get save => 'सहेजें';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट की गई';

  @override
  String get personalData => 'व्यक्तिगत डेटा';

  @override
  String get passport => 'पासपोर्ट';

  @override
  String get drivingLicense => 'ड्राइविंग लाइसेंस';

  @override
  String get diploma => 'डिप्लोमा';

  @override
  String get nationalId => 'राष्ट्रीय पहचान पत्र';

  @override
  String get certificate => 'प्रमाण पत्र';

  @override
  String get notSpecified => 'निर्दिष्ट नहीं';

  @override
  String get notSpecifiedFemale => 'निर्दिष्ट नहीं';

  @override
  String get documentType => 'दस्तावेज़ प्रकार';

  @override
  String get passportId => 'पासपोर्ट / आईडी';

  @override
  String get diplomaCertificate => 'डिप्लोमा / प्रमाण पत्र';

  @override
  String get loadError => 'लोडिंग त्रुटि';

  @override
  String get verification => 'सत्यापन';

  @override
  String get countryAustria => 'ऑस्ट्रिया';

  @override
  String get countryGermany => 'जर्मनी';

  @override
  String get countryRussia => 'रूस';

  @override
  String get countryUkraine => 'यूक्रेन';

  @override
  String get countryKazakhstan => 'कज़ाख़स्तान';

  @override
  String get countryBelarus => 'बेलारूस';

  @override
  String get countryOther => 'अन्य';

  @override
  String get kycTitle => 'KYC सत्यापन';

  @override
  String get kycVerified => 'सत्यापित';

  @override
  String get kycPending => 'लंबित';

  @override
  String get kycRejected => 'अस्वीकृत';

  @override
  String get kycUnverified => 'असत्यापित';

  @override
  String get kycVerifiedDesc =>
      'आपकी पहचान सत्यापित हो गई है। आपको Taler पारिस्थितिकी तंत्र की सभी विशेषताओं का पूर्ण उपयोग मिलेगा।';

  @override
  String get kycPendingDesc =>
      'आपके दस्तावेज़ों की समीक्षा की जा रही है। इसमें आमतौर पर 1-2 कार्य दिवस लगते हैं।';

  @override
  String get kycRejectedDesc =>
      'सत्यापन विफल रहा। कृपया कारण की समीक्षा करें और अपने दस्तावेज़ पुनः सबमिट करें।';

  @override
  String get kycUnverifiedDesc =>
      'Taler पारिस्थितिकी तंत्र की वित्तीय विशेषताओं का पूर्ण उपयोग अनलॉक करने के लिए सत्यापन पूरा करें।';

  @override
  String get startVerification => 'सत्यापन प्रारंभ करें';

  @override
  String get retryVerification => 'सत्यापन पुनः प्रयास करें';

  @override
  String verifiedAt(String date) {
    return 'सत्यापित: $date';
  }

  @override
  String get documentsSubmitted => 'समीक्षा के लिए दस्तावेज़ सबमिट किए गए';

  @override
  String get documentsSubmittedDesc =>
      'समीक्षा में आमतौर पर 1-2 कार्य दिवस लगते हैं। आपको परिणाम के साथ एक पुश सूचना प्राप्त होगी।';

  @override
  String get securityAes => 'आपका डेटा AES-256 एन्क्रिप्शन के साथ सुरक्षित है';

  @override
  String get verificationTime => 'सत्यापन में 1-2 कार्य दिवस लगते हैं';

  @override
  String get pushNotification => 'आपको परिणाम के साथ एक पुश सूचना प्राप्त होगी';

  @override
  String get kycWebOnly => 'KYC सत्यापन केवल मोबाइल ऐप में उपलब्ध है।';

  @override
  String verificationError(String code) {
    return 'सत्यापन त्रुटि: $code';
  }

  @override
  String get organizations => 'संगठन';

  @override
  String get noOrganizations => 'कोई संगठन नहीं';

  @override
  String get noOrganizationsDesc =>
      'एक संगठन बनाएं या एक निमंत्रण स्वीकार करें';

  @override
  String get createOrganization => 'संगठन बनाएं';

  @override
  String get newOrganization => 'नई संगठन';

  @override
  String get orgName => 'नाम *';

  @override
  String get orgDescription => 'विवरण';

  @override
  String get orgEmail => 'संपर्क ईमेल';

  @override
  String get orgWebsite => 'वेबसाइट';

  @override
  String get orgLegalAddress => 'कानूनी पता';

  @override
  String get create => 'बनाएं';

  @override
  String get organization => 'संगठन';

  @override
  String get contacts => 'संपर्क';

  @override
  String members(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String get inviteMember => 'सदस्य को आमंत्रित करें';

  @override
  String get invite => 'आमंत्रित करें';

  @override
  String get sendInvite => 'आमंत्रण भेजें';

  @override
  String inviteSent(String email) {
    return 'आमंत्रण $email पर भेजा गया';
  }

  @override
  String get role => 'भूमिका';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get roleAdmin => 'प्रशासक';

  @override
  String get roleOperator => 'ऑपरेटर';

  @override
  String get roleViewer => 'दर्शक';

  @override
  String get editOrganization => 'संपादित करें';

  @override
  String get editOrganizationTitle => 'संगठन संपादित करें';

  @override
  String get removeMember => 'सदस्य हटाएं';

  @override
  String removeMemberConfirm(String name) {
    return 'क्या आप $name को संगठन से हटाना चाहते हैं?';
  }

  @override
  String get memberRemoved => 'सदस्य हटाया गया';

  @override
  String get roleChanged => 'भूमिका बदली गई';

  @override
  String get kybVerified => 'सत्यापित';

  @override
  String get kybPending => 'लंबित';

  @override
  String get kybRejected => 'अस्वीकृत';

  @override
  String get kybNone => 'असत्यापित';

  @override
  String get kybVerification => 'KYC सत्यापन शुरू करें';

  @override
  String get kybStartBusiness => 'व्यवसाय सत्यापन शुरू करें';

  @override
  String get kybStatusLabel => 'KYB स्थिति';

  @override
  String get noKyb => 'कोई KYB नहीं';

  @override
  String get kybBusinessVerificationTitle => 'व्यवसाय सत्यापन (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'संगठन सफलतापूर्वक सत्यापित हुआ।';

  @override
  String get kybPendingOrgDesc =>
      'दस्तावेज़ों की समीक्षा की जा रही है। इसमें आमतौर पर 1-3 कार्य दिवस लगते हैं।';

  @override
  String get kybRejectedOrgDesc => 'सत्यापन विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get kybNoneOrgDesc =>
      'व्यवसाय सुविधाओं का उपयोग करने के लिए अपने संगठन को सत्यापित करें।';

  @override
  String get invitePlus => '+ आमंत्रित करें';

  @override
  String get kybVerificationTitle => 'KYB सत्यापन';

  @override
  String get kybWebOnlyBusiness => 'KYB सत्यापन केवल मोबाइल ऐप में उपलब्ध है।';

  @override
  String get unknownDevice => 'अज्ञात डिवाइस';

  @override
  String get ipUnknown => 'IP अज्ञात';

  @override
  String get currentSessionLabel => 'वर्तमान';

  @override
  String get endSessionAction => 'समाप्त करें';

  @override
  String get deviceLoggedOut => 'डिवाइस साइन आउट हो जाएगा।';

  @override
  String get acceptInvitationTitle => 'संगठन निमंत्रण';

  @override
  String get acceptInvitation => 'निमंत्रण स्वीकार करें';

  @override
  String get acceptInvitationDesc =>
      'आपको Taler पारिस्थितिकी तंत्र में एक संगठन में शामिल होने के लिए आमंत्रित किया गया है।';

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get reject => 'अस्वीकार करें';

  @override
  String get sessions => 'सक्रिय सत्र';

  @override
  String get currentSession => 'वर्तमान सत्र';

  @override
  String get deleteSession => 'सत्र समाप्त करें';

  @override
  String get deleteSessionConfirm => 'इस सत्र को समाप्त करें?';

  @override
  String get sessionDeleted => 'सत्र समाप्त हुआ';

  @override
  String get noSessions => 'कोई सक्रिय सत्र नहीं';

  @override
  String minutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String hoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String daysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get justNow => 'अभी-अभी';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get security => 'सुरक्षा';

  @override
  String get biometrics => 'बायोमेट्रिक्स';

  @override
  String get biometricsDesc => 'फेस आईडी या फिंगरप्रिंट से त्वरित लॉगिन';

  @override
  String get biometricsConfirm =>
      'त्वरित लॉगिन सक्षम करने के लिए बायोमेट्रिक्स की पुष्टि करें';

  @override
  String get biometricsError =>
      'बायोमेट्रिक्स सक्षम करने में विफल। डिवाइस सेटिंग्स जांचें।';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get twoFactorAuth => 'दो-कारक प्रमाणीकरण';

  @override
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmNewPassword => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get passwordChanged => 'पासवर्ड बदला गया';

  @override
  String get wrongCurrentPassword => 'गलत वर्तमान पासवर्ड';

  @override
  String get passwordTooWeak =>
      'पासवर्ड बहुत कमजोर: कम से कम 8 अक्षर, अक्षर और अंक आवश्यक';

  @override
  String get passwordChangeFailed => 'पासवर्ड बदलने में विफल';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get permissions => 'अनुमतियां';

  @override
  String get permissionNotifications => 'पुश सूचनाएं';

  @override
  String get permissionNotificationsDesc => 'कॉल, संदेश, स्थिति';

  @override
  String get permissionMicrophone => 'माइक्रोफोन';

  @override
  String get permissionMicrophoneDesc => 'कॉल और वॉइस असिस्टेंट';

  @override
  String get permissionCamera => 'कैमरा';

  @override
  String get permissionCameraDesc => 'वीडियो कॉल और सत्यापन';

  @override
  String get permissionLocation => 'स्थान';

  @override
  String get permissionLocationDesc => 'सत्यापन के लिए उपयोग किया जाता है';

  @override
  String get permissionOpenSettings =>
      'अनुमति रद्द करने के लिए, सिस्टम सेटिंग्स खोलें';

  @override
  String get pushKycStatus => 'KYC स्थिति पुश';

  @override
  String get pushKycStatusDesc => 'सत्यापन परिणाम';

  @override
  String get pushLogins => 'लॉगिन पुश';

  @override
  String get pushLoginsDesc => 'जब किसी नए डिवाइस से साइन इन करते हैं';

  @override
  String get account => 'खाता';

  @override
  String get language => 'भाषा';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'इंटरफ़ेस भाषा';

  @override
  String get exportData => 'डेटा निर्यात करें (GDPR)';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get deleteAccountConfirm => 'खाता हटाएं?';

  @override
  String get deleteAccountDesc =>
      'आपका सारा डेटा हटा दिया जाएगा (GDPR)। यह क्रिया अपरिवर्तनीय है।';

  @override
  String get logout => 'साइन आउट';

  @override
  String get logoutConfirm => 'साइन आउट करें?';

  @override
  String get logoutDesc => 'आप इस डिवाइस पर Taler ID से साइन आउट हो जाएंगे।';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'पिन कोड';

  @override
  String get pinCodeDesc => '4-अंकीय कोड से त्वरित लॉगिन';

  @override
  String get setupPin => 'पिन सेट करें';

  @override
  String get enterPin => 'पिन दर्ज करें';

  @override
  String get confirmPin => 'पिन की पुष्टि करें';

  @override
  String get pinMismatch => 'पिन मेल नहीं खाते';

  @override
  String get passwordMismatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get pinSet => 'पिन सफलतापूर्वक सेट किया गया';

  @override
  String get enterPinToLogin => 'साइन इन करने के लिए पिन दर्ज करें';

  @override
  String get pinIncorrect => 'गलत पिन';

  @override
  String get removePin => 'पिन हटाएं';

  @override
  String get pinRemoved => 'पिन हटा दिया गया';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get ok => 'ठीक है';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get noData => 'कोई डेटा नहीं';

  @override
  String get failedToLoad => 'डेटा लोड करने में विफल';

  @override
  String get failedToLoadProfile => 'प्रोफ़ाइल लोड करने में विफल';

  @override
  String get failedToSave => 'परिवर्तनों को सहेजने में विफल';

  @override
  String get failedToLoadOrgs => 'संगठनों को लोड करने में विफल';

  @override
  String get failedToLoadOrg => 'संगठन डेटा लोड करने में विफल';

  @override
  String get failedToCreateOrg => 'संगठन बनाने में विफल';

  @override
  String get failedToInvite => 'निमंत्रण भेजने में विफल';

  @override
  String get failedToAcceptInvite => 'निमंत्रण स्वीकार करने में विफल';

  @override
  String get failedToLoadSessions => 'सत्र लोड करने में विफल';

  @override
  String get failedToDeleteSession => 'सत्र समाप्त करने में विफल';

  @override
  String get failedToLoadKyc => 'सत्यापन स्थिति लोड करने में विफल';

  @override
  String get failedToStartKyc => 'सत्यापन शुरू करने में विफल';

  @override
  String get verifiedPersonalInfo => 'सत्यापित डेटा';

  @override
  String get middleName => 'मध्य नाम';

  @override
  String get placeOfBirth => 'जन्म स्थान';

  @override
  String get nationality => 'राष्ट्रीयता';

  @override
  String get gender => 'लिंग';

  @override
  String get genderMale => 'पुरुष';

  @override
  String get genderFemale => 'महिला';

  @override
  String get docNumber => 'संख्या';

  @override
  String get docIssuedDate => 'जारी';

  @override
  String get docValidUntil => 'तक मान्य';

  @override
  String get docIssuedBy => 'द्वारा जारी';

  @override
  String get address => 'पता';

  @override
  String get refreshData => 'डेटा ताज़ा करें';

  @override
  String get failedToLoadSumsubData => 'सत्यापन डेटा लोड करने में विफल';

  @override
  String get sumsubDataLoading => 'सत्यापन डेटा लोड हो रहा है...';

  @override
  String get reviewResultGreen => 'सत्यापन पास हुआ';

  @override
  String get reviewResultRed => 'सत्यापन विफल';

  @override
  String get tabAssistant => 'सहायक';

  @override
  String get assistantConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get assistantSpeaking => 'बोल रहा है…';

  @override
  String get assistantListening => 'सुन रहा है…';

  @override
  String get assistantTapToStart => 'शुरू करने के लिए टैप करें';

  @override
  String get assistantTapToTalk => 'AI से बात करने के लिए टैप करें';

  @override
  String get assistantRealtimeDesc =>
      'सहायक वास्तविक समय में आवाज के साथ प्रतिक्रिया देता है';

  @override
  String get assistantConnectingToAssistant => 'सहायक से कनेक्ट हो रहा है...';

  @override
  String get assistantAiSpeaking => 'AI बोल रहा है...';

  @override
  String get assistantAiListening => 'AI सुन रहा है';

  @override
  String get assistantSpeakerOn => 'स्पीकर चालू';

  @override
  String get assistantSpeaker => 'स्पीकर';

  @override
  String get assistantEnd => 'समाप्त';

  @override
  String get assistantUnmute => 'अनम्यूट';

  @override
  String get assistantMicrophone => 'माइक्रोफोन';

  @override
  String get assistantConnectionError => 'कनेक्शन त्रुटि';

  @override
  String get tabMessenger => 'संदेश';

  @override
  String get tabCalls => 'कॉल';

  @override
  String get tabCalendar => 'कैलेंडर';

  @override
  String get appearance => 'दिखावट';

  @override
  String get appearanceSelect => 'थीम चुनें';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get onboardingTitle1 => 'एकीकृत पहचान';

  @override
  String get onboardingDesc1 =>
      'Taler ID आपके Taler इकोसिस्टम में डिजिटल पासपोर्ट है। सभी सेवाओं के लिए एक खाता।';

  @override
  String get onboardingTitle2 => 'डेटा सुरक्षा';

  @override
  String get onboardingDesc2 =>
      'KYC सत्यापन, AES-256 एन्क्रिप्शन, और दो-कारक प्रमाणीकरण आपकी पहचान की सुरक्षा करते हैं।';

  @override
  String get onboardingTitle3 => 'सूचित रहें';

  @override
  String get onboardingDesc3 =>
      'सत्यापन स्थिति, नए उपकरणों से लॉगिन और आने वाली कॉल के बारे में सूचित रहें।';

  @override
  String get onboardingNext => 'अगला';

  @override
  String get onboardingEnableNotifications => 'सूचनाएं सक्षम करें';

  @override
  String get onboardingTitle4 => 'वॉइस कॉल';

  @override
  String get onboardingDesc4 =>
      'वॉइस कॉल और AI सहायक के लिए माइक्रोफोन एक्सेस दें। आप इसे बाद में सेटिंग्स में बदल सकते हैं।';

  @override
  String get onboardingEnableMicrophone => 'माइक्रोफोन सक्षम करें';

  @override
  String get onboardingStart => 'शुरू करें';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get meshLocalNetworkPromptTitle =>
      'स्थानीय नेटवर्क एक्सेस की अनुमति दें';

  @override
  String get meshLocalNetworkPromptBody =>
      'वाई-फाई पर साथियों को खोजने के लिए (ऑफ़लाइन समूह कॉल), iOS को स्थानीय नेटवर्क अनुमति की आवश्यकता होती है। सेटिंग्स खोलें → गोपनीयता और सुरक्षा → स्थानीय नेटवर्क → Taler ID।';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get meshLocalNetworkPromptDismiss => 'समझ गया';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get forgotPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get forgotPasswordSubtitle =>
      'रीसेट कोड प्राप्त करने के लिए अपना ईमेल दर्ज करें';

  @override
  String resetCodeSent(String email) {
    return 'कोड $email पर भेजा गया';
  }

  @override
  String get enterResetCode => 'कोड दर्ज करें';

  @override
  String get resetPasswordButton => 'पासवर्ड रीसेट करें';

  @override
  String get passwordResetSuccess => 'पासवर्ड सफलतापूर्वक रीसेट किया गया';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get resendCode => 'कोड पुनः भेजें';

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
  String get newGroup => 'नया समूह';

  @override
  String get newChat => 'नई चैट';

  @override
  String get groupName => 'समूह का नाम';

  @override
  String get createGroup => 'समूह बनाएं';

  @override
  String get groupInfo => 'समूह जानकारी';

  @override
  String groupMembers(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String get addMembers => 'सदस्य जोड़ें';

  @override
  String get leaveGroup => 'समूह छोड़ें';

  @override
  String get leaveGroupConfirm => 'क्या आप इस समूह को छोड़ना चाहते हैं?';

  @override
  String get deleteGroup => 'समूह हटाएं';

  @override
  String get deleteGroupConfirm =>
      'क्या आप इस समूह को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get groupRoleOwner => 'मालिक';

  @override
  String get groupRoleAdmin => 'प्रशासक';

  @override
  String get groupRoleMember => 'सदस्य';

  @override
  String get selectParticipants => 'प्रतिभागियों का चयन करें';

  @override
  String selectedCount(int count) {
    return '$count चयनित';
  }

  @override
  String get changeRole => 'भूमिका बदलें';

  @override
  String get groupCreated => 'समूह बनाया गया';

  @override
  String memberJoined(String name) {
    return '$name शामिल हुआ';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name ने समूह छोड़ा';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name को हटा दिया गया';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name अब $role है';
  }

  @override
  String participantsCount(int count) {
    return '$count प्रतिभागी';
  }

  @override
  String get enterGroupName => 'समूह का नाम दर्ज करें';

  @override
  String get muteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get unmuteNotifications => 'सूचनाएं अनम्यूट करें';

  @override
  String get muteFor1Hour => '1 घंटे के लिए';

  @override
  String get muteFor8Hours => '8 घंटे के लिए';

  @override
  String get muteFor2Days => '2 दिनों के लिए';

  @override
  String get muteForever => 'हमेशा के लिए';

  @override
  String get muted => 'म्यूट किया गया';

  @override
  String get tabTranslator => 'अनुवाद करें';

  @override
  String get translatorTitle => 'अनुवादक';

  @override
  String get translatorSelectLanguage => 'भाषा चुनें';

  @override
  String get translatorDownloading => 'भाषा मॉडल डाउनलोड हो रहे हैं...';

  @override
  String get translatorDownloadingHint =>
      'पहली बार डाउनलोड के लिए इंटरनेट की आवश्यकता है';

  @override
  String get translatorTypeHint => 'पाठ टाइप करें या माइक्रोफोन टैप करें';

  @override
  String get translatorListening => 'सुन रहे हैं...';

  @override
  String get translatorTapToSpeak => 'बोलने के लिए टैप करें';

  @override
  String get translatorTapToStop => 'रोकने के लिए टैप करें';

  @override
  String get translatorAutoSpeak => 'स्वतः बोलें';

  @override
  String get translatorCopied => 'कॉपी किया गया';

  @override
  String get translatorLangRu => 'रूसी';

  @override
  String get translatorLangEn => 'अंग्रेज़ी';

  @override
  String get translatorLangDe => 'जर्मन';

  @override
  String get translatorLangFr => 'फ्रेंच';

  @override
  String get translatorLangEs => 'स्पेनिश';

  @override
  String get translatorLangIt => 'इतालवी';

  @override
  String get translatorLangPt => 'पुर्तगाली';

  @override
  String get translatorLangTr => 'तुर्की';

  @override
  String get translatorLangZh => 'चीनी';

  @override
  String get translatorLangJa => 'जापानी';

  @override
  String get translatorLangKo => 'कोरियाई';

  @override
  String get translatorLangAr => 'अरबी';

  @override
  String get translatorLangPl => 'पोलिश';

  @override
  String get translatorLangSk => 'स्लोवाक';

  @override
  String get translatorLangCs => 'चेक';

  @override
  String get translatorLangNl => 'डच';

  @override
  String get translatorLangSv => 'स्वीडिश';

  @override
  String get translatorLangDa => 'डेनिश';

  @override
  String get translatorLangNo => 'नॉर्वेजियन';

  @override
  String get translatorLangFi => 'फिनिश';

  @override
  String get translatorLangUk => 'यूक्रेनी';

  @override
  String get translatorLangEl => 'यूनानी';

  @override
  String get translatorLangRo => 'रोमानियाई';

  @override
  String get translatorLangHu => 'हंगेरियन';

  @override
  String get translatorLangBg => 'बुल्गारियाई';

  @override
  String get translatorLangHr => 'क्रोएशियाई';

  @override
  String get translatorLangSr => 'सर्बियाई';

  @override
  String get translatorLangHi => 'हिंदी';

  @override
  String get translatorLangTh => 'थाई';

  @override
  String get translatorLangVi => 'वियतनामी';

  @override
  String get translatorLangId => 'इंडोनेशियाई';

  @override
  String get translatorLangMs => 'मलय';

  @override
  String get translatorLangHe => 'हिब्रू';

  @override
  String get translatorLangFa => 'फारसी';

  @override
  String get callInProgress => 'कॉल जारी है';

  @override
  String get joinCall => 'शामिल हों';

  @override
  String get createCallLink => 'कॉल लिंक';

  @override
  String get callLinkCopied => 'लिंक कॉपी हो गया';

  @override
  String get callLinkTitle => 'रूम लिंक';

  @override
  String get connectionUnstable => 'कनेक्शन अस्थिर है — अपनी इंटरनेट जांचें';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get errorTimeout =>
      'कनेक्शन का समय समाप्त हो गया। अपनी इंटरनेट कनेक्शन जांचें।';

  @override
  String get errorNoConnection => 'कोई इंटरनेट कनेक्शन नहीं।';

  @override
  String get errorGeneral => 'एक त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String errorWithMessage(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String get notifChannelMessages => 'संदेश';

  @override
  String get notifChannelMessagesDesc => 'नए संदेश सूचनाएं';

  @override
  String get notifChannelMissedCalls => 'छूटे हुए कॉल';

  @override
  String get notifChannelMissedCallsDesc => 'छूटे हुए कॉल सूचनाएं';

  @override
  String get notifMissedCall => 'छूटा हुआ कॉल';

  @override
  String get notifAccept => 'स्वीकार करें';

  @override
  String get notifDecline => 'अस्वीकार करें';

  @override
  String get notifIncomingCall => 'आने वाली कॉल';

  @override
  String get notifIncomingCallChannel => 'आने वाली कॉल';

  @override
  String get notifMissedCallChannel => 'छूटा हुआ कॉल';

  @override
  String get notifUnknown => 'अज्ञात';

  @override
  String get effectNone => 'कोई पृष्ठभूमि नहीं';

  @override
  String get effectBlur => 'धुंधला';

  @override
  String get effectOffice => 'ऑफिस';

  @override
  String get effectNature => 'प्रकृति';

  @override
  String get effectGradient => 'ग्रेडिएंट';

  @override
  String get effectLibrary => 'लाइब्रेरी';

  @override
  String get effectCity => 'शहर';

  @override
  String get effectMinimalism => 'मिनिमलिज़्म';

  @override
  String get voiceParticipant => 'प्रतिभागी';

  @override
  String get voiceInvitesToRoom => 'आपको रूम में आमंत्रित करता है';

  @override
  String get voiceRoom => 'रूम';

  @override
  String get voicePasswordProtected => 'पासवर्ड संरक्षित';

  @override
  String get voicePasswordHint => 'पासवर्ड';

  @override
  String get voiceEnter => 'प्रवेश करें';

  @override
  String get voiceJoinRoom => 'रूम में शामिल हों';

  @override
  String get voiceYourName => 'आपका नाम';

  @override
  String voiceInvitationSent(String name) {
    return '$name को निमंत्रण भेजा गया';
  }

  @override
  String get voiceNoActiveRoom => 'कोई सक्रिय रूम नहीं';

  @override
  String get voiceCameraPermission =>
      'सेटिंग्स → प्राइवेसी → कैमरा → TalerID में कैमरा एक्सेस की अनुमति दें';

  @override
  String get voiceOpenSettings => 'खोलें';

  @override
  String voiceCameraError(String error) {
    return 'कैमरा सक्षम करने में विफल: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'सभी सहमत। रिकॉर्डिंग शुरू हुई।';

  @override
  String get voiceNewParticipantAgreed =>
      'नए प्रतिभागी ने रिकॉर्डिंग के लिए सहमति दी।';

  @override
  String get voiceDeclinedRecording =>
      'आपने रिकॉर्डिंग अस्वीकार की। कॉल छोड़ रहे हैं।';

  @override
  String get voiceRecordingEnded => 'रिकॉर्डिंग समाप्त';

  @override
  String get voiceRecordingInProgress => 'रिकॉर्डिंग जारी है';

  @override
  String get voiceTranscriptionRequest => 'प्रतिलिपि अनुरोध';

  @override
  String get voiceRecordingRequest => 'रिकॉर्डिंग अनुरोध';

  @override
  String get voiceAgree => 'सहमत';

  @override
  String get voiceDeclineAndLeave => 'अस्वीकार करें और छोड़ें';

  @override
  String get voiceAudioOutput => 'ऑडियो आउटपुट';

  @override
  String get voiceAudioPhone => 'फ़ोन';

  @override
  String get voiceAudioSpeaker => 'स्पीकर';

  @override
  String get voiceAudioBluetooth => 'ब्लूटूथ';

  @override
  String get voiceAudioHeadphones => 'हेडफ़ोन';

  @override
  String get voiceLinkCopied => 'लिंक कॉपी किया गया';

  @override
  String get voiceTranslateTo => 'अनुवाद करें';

  @override
  String get voiceSearchLanguage => 'भाषा खोजें...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'कक्ष $name';
  }

  @override
  String get voiceVoiceCall => 'वॉइस कॉल';

  @override
  String get voiceOnHold => 'रुका हुआ';

  @override
  String get voiceActiveCall => 'सक्रिय';

  @override
  String get voiceEndAllCalls => 'सभी कॉल समाप्त करें';

  @override
  String get voiceEndThisCall => 'इस कॉल को समाप्त करें';

  @override
  String get voiceCopyLink => 'लिंक कॉपी करें';

  @override
  String get voiceAddParticipant => 'प्रतिभागी जोड़ें';

  @override
  String get voiceReconnecting => 'पुनः कनेक्ट कर रहे हैं...';

  @override
  String get voiceConnectionError => 'कनेक्शन त्रुटि';

  @override
  String get voiceClose => 'बंद करें';

  @override
  String get voiceCalling => 'कॉल कर रहे हैं...';

  @override
  String get voiceCallActive => 'कॉल सक्रिय';

  @override
  String get voiceWaiting => 'प्रतीक्षा कर रहे हैं';

  @override
  String get voiceWaitingUpper => 'प्रतीक्षा';

  @override
  String get voiceRec => 'रिकॉर्ड';

  @override
  String get voiceStop => 'रोकें';

  @override
  String get voiceRecord => 'रिकॉर्डिंग';

  @override
  String get voiceTranslation => 'अनुवाद';

  @override
  String get voiceAudio => 'ऑडियो';

  @override
  String get voiceFlipCamera => 'कैमरा पलटें';

  @override
  String get voiceBackground => 'पृष्ठभूमि';

  @override
  String get voiceAssistantSpeakingStatus => 'सहायक बोल रहा है...';

  @override
  String get voiceAssistantListeningStatus => 'सहायक सुन रहा है...';

  @override
  String get voiceUnmute => 'अनम्यूट';

  @override
  String get voiceMic => 'माइक्रोफोन';

  @override
  String get voiceAssistantLabel => 'सहायक';

  @override
  String get voiceCameraOn => 'कैमरा चालू';

  @override
  String get voiceCameraLabel => 'कैमरा';

  @override
  String get voiceEndCall => 'कॉल समाप्त करें';

  @override
  String get voiceWaitingParticipants =>
      'प्रतिभागियों की प्रतीक्षा कर रहे हैं...';

  @override
  String get voiceYou => 'आप';

  @override
  String get voiceAiAssistant => 'AI सहायक';

  @override
  String get voiceVideoUnavailable => 'वीडियो उपलब्ध नहीं है';

  @override
  String get voiceSearchNickname => 'उपनाम से खोजें...';

  @override
  String get voiceTranscriptionWord => 'प्रतिलिपि';

  @override
  String get voiceRecordingWord => 'रिकॉर्डिंग';

  @override
  String get voiceConnecting => 'कनेक्ट कर रहा है...';

  @override
  String get voiceVideoBackground => 'वीडियो पृष्ठभूमि';

  @override
  String get voiceCallSettings => 'कॉल सेटिंग्स';

  @override
  String get voiceEnableAI => 'AI सहायक सक्षम करें';

  @override
  String get voiceAIParticipating => 'AI बातचीत में भाग लेगा';

  @override
  String get voiceNormalCall => 'AI के बिना सामान्य कॉल';

  @override
  String get voiceCallConfirm => 'कॉल करें?';

  @override
  String get chatAlreadyInCall => 'पहले से ही एक कॉल में हैं';

  @override
  String chatCallError(String error) {
    return 'कॉल त्रुटि: $error';
  }

  @override
  String get chatPhotoVideo => 'फोटो / वीडियो';

  @override
  String get chatCamera => 'कैमरा';

  @override
  String get chatFile => 'फ़ाइल';

  @override
  String get chatContact => 'संपर्क';

  @override
  String get chatSelectContact => 'एक संपर्क चुनें';

  @override
  String get chatNoContacts => 'कोई संपर्क नहीं';

  @override
  String get chatUser => 'उपयोगकर्ता';

  @override
  String get chatFileAttachment => '📎 फ़ाइल';

  @override
  String chatFileUploadError(String error) {
    return 'फ़ाइल अपलोड त्रुटि: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 वॉइस संदेश';

  @override
  String get chatGroup => 'समूह';

  @override
  String get chatDialog => 'संवाद';

  @override
  String get chatCall => 'कॉल';

  @override
  String get chatStartConversation => 'वार्तालाप शुरू करें';

  @override
  String get chatYou => 'आप';

  @override
  String get chatIsTyping => 'टाइप कर रहा है...';

  @override
  String chatUserIsTyping(String name) {
    return '$name टाइप कर रहा है...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names टाइप कर रहे हैं...';
  }

  @override
  String get chatPreparingFile => 'फ़ाइल तैयार कर रहा है…';

  @override
  String chatUploading(int progress) {
    return 'अपलोड कर रहा है… $progress%';
  }

  @override
  String get chatEdited => 'संपादित';

  @override
  String get chatViaMesh => 'मेश के माध्यम से';

  @override
  String get chatReply => 'उत्तर दें';

  @override
  String get chatEdit => 'संपादित करें';

  @override
  String get chatCopy => 'कॉपी करें';

  @override
  String get chatCopied => 'कॉपी किया गया';

  @override
  String get chatSaveMedia => 'सहेजें';

  @override
  String get chatForward => 'फॉरवर्ड करें';

  @override
  String get chatSaving => 'सहेज रहा है...';

  @override
  String get chatSavedToGallery => 'गैलरी में सहेजा गया';

  @override
  String get chatNoSavePermission =>
      'सहेजने की अनुमति नहीं है। सेटिंग्स जांचें।';

  @override
  String get chatFileSaveError => 'फ़ाइल सहेजने में त्रुटि';

  @override
  String get chatDeleteMessage => 'संदेश हटाएं';

  @override
  String get chatDeleteForMe => 'मेरे लिए हटाएं';

  @override
  String get chatDeleteForEveryone => 'सभी के लिए हटाएं';

  @override
  String get chatMessageForwarded => 'संदेश अग्रेषित किया गया';

  @override
  String get chatContactTapToOpen => 'संपर्क · खोलने के लिए टैप करें';

  @override
  String get chatForwardTo => 'इसको फॉरवर्ड करें...';

  @override
  String get chatSearchHint => 'खोजें...';

  @override
  String get chatRecording => 'रिकॉर्डिंग...';

  @override
  String get chatMessageHint => 'संदेश...';

  @override
  String get chatHideKeyboard => 'कीबोर्ड छुपाएं';

  @override
  String get chatEditing => 'संपादन कर रहा है';

  @override
  String get chatFileDownloadError => 'फ़ाइल डाउनलोड त्रुटि';

  @override
  String get chatVoiceMessageShort => 'वॉइस संदेश';

  @override
  String get chatVideoSavedToGallery => 'वीडियो गैलरी में सहेजा गया';

  @override
  String get chatSavingError => 'सहेजने में त्रुटि';

  @override
  String get convSetNickname => 'उपनाम सेट करें';

  @override
  String get convNicknameRequired =>
      'मैसेंजर का उपयोग करने के लिए उपनाम आवश्यक है। अन्य उपयोगकर्ता आपको इसके द्वारा ढूंढ सकते हैं।';

  @override
  String get convNicknameRules => '3–30 अक्षर: अक्षर, अंक, _';

  @override
  String get convNicknameTaken => 'उपनाम पहले से लिया गया है';

  @override
  String get convSaveError => 'सहेजने में त्रुटि';

  @override
  String get convContactsLabel => 'संपर्क';

  @override
  String get convDefaultUser => 'उपयोगकर्ता';

  @override
  String get convNoDialogs => 'कोई वार्तालाप नहीं';

  @override
  String get convFindUserToChat => 'चैट शुरू करने के लिए उपयोगकर्ता खोजें';

  @override
  String get convDefaultContact => 'संपर्क';

  @override
  String get dashboardUser => 'उपयोगकर्ता';

  @override
  String get dashboardIncomingCall => 'आने वाली कॉल';

  @override
  String get dashboardDecline => 'अस्वीकार करें';

  @override
  String get dashboardAccept => 'स्वीकार करें';

  @override
  String get dashboardActiveCall => 'सक्रिय कॉल — वापस जाने के लिए टैप करें';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'अपडेट उपलब्ध $version';
  }

  @override
  String get dashboardUpdate => 'अपडेट';

  @override
  String get dashboardWhatsNew => 'क्या नया है';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version में क्या नया है';
  }

  @override
  String get dashboardInstalling => 'इंस्टॉल हो रहा है...';

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
  String get contactRequestsTitle => 'संपर्क';

  @override
  String get messengerContactRequestsSection => 'संपर्क अनुरोध';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नए अनुरोध',
      one: '1 नया अनुरोध',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'खोजें';

  @override
  String get contactRequestsIncoming => 'आने वाले';

  @override
  String get contactRequestsSent => 'भेजे गए';

  @override
  String get contactRequestsSearchHint => 'उपनाम या ईमेल';

  @override
  String get contactRequestSent => 'अनुरोध भेजा गया';

  @override
  String get contactRequestsNoUsers => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get contactRequestsSearchHelp =>
      'सटीक उपनाम या ईमेल दर्ज करें\nऔर खोज दबाएं';

  @override
  String get contactRequestsSendTooltip => 'अनुरोध भेजें';

  @override
  String get contactRequestTitle => 'संपर्क अनुरोध';

  @override
  String contactRequestConfirm(String name) {
    return '$name को संपर्क अनुरोध भेजें?';
  }

  @override
  String get contactRequestSend => 'भेजें';

  @override
  String get contactRequestsNoIncoming => 'कोई आने वाले अनुरोध नहीं';

  @override
  String get contactRequestsNoSent => 'कोई भेजे गए अनुरोध नहीं';

  @override
  String get contactRequestStatusPending => 'प्रतिक्रिया की प्रतीक्षा में';

  @override
  String get contactRequestStatusAccepted => 'स्वीकृत';

  @override
  String get contactRequestStatusRejected => 'अस्वीकृत';

  @override
  String get userSearchTitle => 'उपयोगकर्ता खोजें';

  @override
  String get userSearchHint => 'उपनाम, फोन या ईमेल';

  @override
  String get userSearchHelper => '@उपनाम, ईमेल या नाम दर्ज करें और खोजें';

  @override
  String get userSearchNoUsers => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get userProfileShareContact => 'संपर्क साझा करें';

  @override
  String get userProfileShareContactDesc => 'संपर्क लिंक भेजें';

  @override
  String get userProfileCopyLink => 'लिंक कॉपी करें';

  @override
  String get userProfileCopied => 'कॉपी किया गया';

  @override
  String get userProfileTitle => 'प्रोफ़ाइल';

  @override
  String get userProfileLoadError => 'प्रोफ़ाइल लोड त्रुटि';

  @override
  String get userProfileMessage => 'संदेश';

  @override
  String get userProfileCall => 'कॉल';

  @override
  String get userProfileRequestSent => 'अनुरोध भेजा गया';

  @override
  String get userProfileAccept => 'स्वीकार करें';

  @override
  String get userProfileDecline => 'अस्वीकार करें';

  @override
  String get userProfileAddToContacts => 'संपर्कों में जोड़ें';

  @override
  String get userProfileMediaTab => 'मीडिया';

  @override
  String get userProfileFilesTab => 'फ़ाइलें';

  @override
  String get userProfileLinksTab => 'लिंक';

  @override
  String get userProfileRecordingsTab => 'रिकॉर्डिंग';

  @override
  String get userProfileSummariesTab => 'सारांश';

  @override
  String get userProfileNoMedia => 'कोई मीडिया फ़ाइल नहीं';

  @override
  String get userProfileNoFiles => 'कोई फ़ाइल नहीं';

  @override
  String get userProfileNoLinks => 'कोई लिंक नहीं';

  @override
  String get userProfileNoRecordings => 'कोई रिकॉर्डिंग नहीं';

  @override
  String get userProfileNoSummaries => 'कोई सारांश नहीं';

  @override
  String get userProfileMeetingSummary => 'बैठक का सारांश';

  @override
  String get userProfileFailedOpenChat => 'चैट खोलने में विफल';

  @override
  String get sharedMediaTitle => 'मीडिया और फ़ाइलें';

  @override
  String get sharedMediaTab => 'मीडिया';

  @override
  String get sharedFilesTab => 'फ़ाइलें';

  @override
  String get sharedLinksTab => 'लिंक';

  @override
  String get sharedNoMedia => 'कोई मीडिया फ़ाइल नहीं';

  @override
  String get sharedNoFiles => 'कोई फ़ाइल नहीं';

  @override
  String get sharedNoLinks => 'कोई लिंक नहीं';

  @override
  String get shareToChat => 'चैट में अग्रेषित करें';

  @override
  String get shareSelectChat => 'चैट चुनें';

  @override
  String get shareNoChats => 'कोई चैट नहीं';

  @override
  String shareFilesCount(int count) {
    return '$count फ़ाइलें';
  }

  @override
  String get contactsTitle => 'संपर्क';

  @override
  String get contactsAddTooltip => 'संपर्क जोड़ें';

  @override
  String get contactsSearchHint => 'संपर्क खोजें...';

  @override
  String get contactsNotFound => 'कुछ नहीं मिला';

  @override
  String get contactsEmpty => 'कोई संपर्क नहीं';

  @override
  String get contactsAdd => 'संपर्क जोड़ें';

  @override
  String get contactsPendingConfirmation => 'पुष्टि की प्रतीक्षा में';

  @override
  String get contactsMessage => 'संदेश';

  @override
  String get contactsCall => 'कॉल';

  @override
  String get contactsResend => 'अनुरोध पुनः भेजें';

  @override
  String get contactsResendTimeout => '24 घंटे में पुनः प्रयास करें';

  @override
  String get contactsResent => 'अनुरोध पुनः भेजा गया';

  @override
  String get contactsWantsToConnect => 'आपसे जुड़ना चाहता है';

  @override
  String get contactsSearchPeople => 'लोगों को खोजें';

  @override
  String get notesTitle => 'नोट्स';

  @override
  String get notesAssistantSpeaking => 'सहायक बोल रहा है...';

  @override
  String get notesListening => 'सुन रहा है...';

  @override
  String get notesEmpty => 'कोई नोट्स नहीं';

  @override
  String get notesEmptyHint =>
      'डिक्टेशन के लिए माइक दबाएं\nया मैन्युअल प्रविष्टि के लिए + दबाएं';

  @override
  String get notesDeleteConfirm => 'नोट हटाएं?';

  @override
  String get notesNew => 'नया नोट';

  @override
  String get notesEdit => 'संपादित करें';

  @override
  String get notesTitleHint => 'शीर्षक';

  @override
  String get notesContentHint => 'अपने विचार लिखें...';

  @override
  String get calendarTitle => 'कैलेंडर';

  @override
  String get calendarStop => 'रोकें';

  @override
  String get calendarVoiceInput => 'वॉयस इनपुट';

  @override
  String get calendarNewEvent => 'नया इवेंट';

  @override
  String get calendarAssistantSpeaking => 'सहायक बोल रहा है...';

  @override
  String get calendarListening => 'सुन रहा है...';

  @override
  String calendarInvitations(int count) {
    return 'निमंत्रण ($count)';
  }

  @override
  String get calendarNoEvents => 'कोई इवेंट नहीं';

  @override
  String get calendarDayMon => 'सोम';

  @override
  String get calendarDayTue => 'मंगल';

  @override
  String get calendarDayWed => 'बुध';

  @override
  String get calendarDayThu => 'गुरु';

  @override
  String get calendarDayFri => 'शुक्र';

  @override
  String get calendarDaySat => 'शनि';

  @override
  String get calendarDaySun => 'रवि';

  @override
  String get calendarEnterRoom => 'कक्ष में प्रवेश करें';

  @override
  String get calendarMeeting => 'बैठक';

  @override
  String calendarLocationPrefix(String location) {
    return 'स्थान: $location';
  }

  @override
  String get calendarEditEvent => 'संपादित करें';

  @override
  String get calendarTitleHint => 'शीर्षक';

  @override
  String get calendarDescriptionHint => 'विवरण';

  @override
  String get calendarTypeEvent => 'इवेंट';

  @override
  String get calendarTypeMeeting => 'बैठक';

  @override
  String get calendarTypeReminder => 'अनुस्मारक';

  @override
  String get calendarTypeLabel => 'प्रकार';

  @override
  String get calendarMeetingLink => 'बैठक लिंक';

  @override
  String get calendarLocationHint => 'स्थान';

  @override
  String get calendarDateLabel => 'तारीख';

  @override
  String get calendarTimeLabel => 'समय';

  @override
  String get calendarReminderLabel => 'अनुस्मारक';

  @override
  String get calendarReminderNone => 'कोई नहीं';

  @override
  String get calendarReminder15min => '15 मिनट पहले';

  @override
  String get calendarReminder30min => '30 मिनट पहले';

  @override
  String get calendarReminder1hour => '1 घंटा पहले';

  @override
  String get calendarRepeatLabel => 'दोहराएँ';

  @override
  String get calendarRepeatNone => 'कोई पुनरावृत्ति नहीं';

  @override
  String get calendarRepeatDaily => 'हर दिन';

  @override
  String get calendarRepeatWeekly => 'हर सप्ताह';

  @override
  String get calendarRepeatMonthly => 'हर माह';

  @override
  String get calendarRepeatYearly => 'हर साल';

  @override
  String get calendarParticipants => 'प्रतिभागी';

  @override
  String get calendarAddParticipant => 'जोड़ें';

  @override
  String get calendarSearchContacts => 'संपर्क खोजें...';

  @override
  String get calendarNoContacts => 'कोई संपर्क नहीं';

  @override
  String get calendarStatusAccepted => 'स्वीकृत';

  @override
  String get calendarStatusDeclined => 'अस्वीकृत';

  @override
  String get calendarStatusMaybe => 'शायद';

  @override
  String get calendarStatusPending => 'लंबित';

  @override
  String get calendarEndTime => 'समाप्ति समय';

  @override
  String get calendarYourAnswer => 'आपका उत्तर:';

  @override
  String get calendarOrganizer => 'आयोजक';

  @override
  String calendarDeleteError(String error) {
    return 'हटाने में विफल: $error';
  }

  @override
  String get calendarRsvpAccept => 'स्वीकार करें';

  @override
  String get calendarRsvpMaybe => 'शायद';

  @override
  String get calendarRsvpDecline => 'अस्वीकार करें';

  @override
  String get callHistoryTitle => 'कॉल्स';

  @override
  String get callHistoryTab => 'कॉल इतिहास';

  @override
  String get callHistoryTempMeeting => 'अस्थायी बैठक';

  @override
  String get callHistoryCopy => 'कॉपी करें';

  @override
  String get callHistoryLinkCopied => 'लिंक कॉपी किया गया';

  @override
  String get callHistoryShare => 'साझा करें';

  @override
  String get callHistoryEnter => 'प्रवेश करें';

  @override
  String get callHistoryAlreadyInCall => 'पहले से ही कॉल में हैं';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'दूसरे पक्ष का पता नहीं लगा सके';

  @override
  String get callHistoryContacts => 'संपर्क';

  @override
  String get callHistoryFailedLoadRoom => 'आपका कमरा लोड करने में विफल';

  @override
  String get callHistoryYourRoom => 'आपका कमरा';

  @override
  String get callHistoryCreateMeeting => 'मीटिंग बनाएं';

  @override
  String get callHistoryMeetingSummaries => 'मीटिंग सारांश';

  @override
  String get callHistoryMeetingRecordings => 'मीटिंग रिकॉर्डिंग्स';

  @override
  String get callHistoryNoCalls => 'कोई कॉल नहीं';

  @override
  String get callHistoryMissed => 'मिस्ड';

  @override
  String get callHistoryRecording => 'रिकॉर्डिंग';

  @override
  String get callHistorySummary => 'सारांश';

  @override
  String get callHistoryCallAgain => 'फिर से कॉल करें';

  @override
  String callHistoryTodayTime(String time) {
    return 'आज, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'कल, $time';
  }

  @override
  String get callHistoryUnknown => 'अज्ञात';

  @override
  String get callHistoryDetails => 'कॉल विवरण';

  @override
  String get callHistoryOutgoing => 'आउटगोइंग कॉल';

  @override
  String get callHistoryIncoming => 'इनकमिंग कॉल';

  @override
  String callHistoryDuration(String duration) {
    return 'अवधि: $duration';
  }

  @override
  String get callHistoryWithAI => 'AI सहायक के साथ';

  @override
  String get callHistoryParticipants => 'प्रतिभागी';

  @override
  String get callDetailYouSuffix => '(आप)';

  @override
  String get callHistoryMeetingSummary => 'मीटिंग सारांश';

  @override
  String get callHistoryMoreDetails => 'अधिक विवरण';

  @override
  String get callHistorySummaryProcessing => 'सारांश प्रसंस्करण...';

  @override
  String get callHistoryMeetingRecording => 'मीटिंग रिकॉर्डिंग';

  @override
  String get callHistoryProcessing => 'प्रसंस्करण...';

  @override
  String get callHistoryCreateTranscript => 'प्रतिलिपि बनाएं';

  @override
  String get callHistoryNoSummaries => 'कोई सारांश नहीं';

  @override
  String get callHistoryRecordDuringCall => 'कॉल के दौरान \"रिकॉर्ड\" दबाएं';

  @override
  String callHistoryMeetingTime(String time) {
    return 'मीटिंग $time';
  }

  @override
  String get callHistoryTranscribing => 'प्रतिलिपि और सारांश बना रहे हैं...';

  @override
  String get callHistoryTranscriptCreated => 'प्रतिलिपि बनाई गई';

  @override
  String get callHistoryNoRecordings => 'कोई रिकॉर्डिंग नहीं';

  @override
  String callHistoryRecordingDate(String date) {
    return 'रिकॉर्डिंग $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'रिकॉर्डिंग उपलब्ध नहीं';

  @override
  String get callHistoryTranscriptReady => 'प्रतिलिपि तैयार';

  @override
  String get callHistoryTranscript => 'प्रतिलिपि';

  @override
  String get callHistoryKeyPoints => 'मुख्य बिंदु';

  @override
  String get callHistoryTasks => 'कार्य';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'सौंपा गया: $assignee';
  }

  @override
  String get callHistoryDecisions => 'निर्णय';

  @override
  String get callHistoryShowTranscript => 'पूर्ण प्रतिलिपि दिखाएं';

  @override
  String get profileScanQr => 'QR स्कैन करें';

  @override
  String get profileMyQrCode => 'मेरा QR कोड';

  @override
  String profileAddMeShare(String userId) {
    return 'मुझे Taler ID में जोड़ें!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'आपको जोड़ने के लिए यह कोड दिखाएं';

  @override
  String get profileEditDesc => 'नाम, उपनाम, पिता का नाम, जन्म तिथि';

  @override
  String get profileAboutMe => 'मेरे बारे में';

  @override
  String get profileAboutMeDesc => 'मूल्य, कौशल, रुचियां और अधिक';

  @override
  String get profileNotes => 'नोट्स';

  @override
  String get profileNotesDesc => 'विचार, आइडिया और नोट्स';

  @override
  String get profileAvatarUpdated => 'अवतार अपडेट किया गया';

  @override
  String get profileNickname => 'उपनाम';

  @override
  String get profileNotSet => 'सेट नहीं है';

  @override
  String get profileChangeNickname => 'उपनाम बदलें';

  @override
  String get profileNicknameUpdated => 'उपनाम अपडेट किया गया';

  @override
  String get profileShareLabel => 'साझा करें';

  @override
  String get profileScanQrCode => 'QR कोड स्कैन करें';

  @override
  String get profilePointCamera => 'कैमरा QR कोड पर इंगित करें';

  @override
  String get profilePhotoCamera => 'फोटो लें';

  @override
  String get profilePhotoGallery => 'गैलरी से चुनें';

  @override
  String get editProfilePatronymic => 'पिता का नाम (वैकल्पिक)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'मेरे बारे में';

  @override
  String get aboutMeClickToFill => 'भरने के लिए क्लिक करें';

  @override
  String get aboutMeCoreValues => 'मूल्य';

  @override
  String get aboutMeWorldview => 'विश्व दृष्टिकोण';

  @override
  String get aboutMeSkills => 'कौशल';

  @override
  String get aboutMeInterests => 'रुचियां';

  @override
  String get aboutMeDesires => 'इच्छाएं';

  @override
  String get aboutMeBackground => 'प्रोफ़ाइल';

  @override
  String get aboutMeLikes => 'पसंद';

  @override
  String get aboutMeDislikes => 'नापसंद';

  @override
  String get aboutMeDeleteSection => 'सेक्शन हटाएं?';

  @override
  String get aboutMeDeleteConfirm => 'इस सेक्शन के सभी डेटा हटा दिए जाएंगे।';

  @override
  String aboutMeConnectionError(String error) {
    return 'कनेक्शन त्रुटि: $error';
  }

  @override
  String get aboutMeVisibility => 'दृश्यता';

  @override
  String get aboutMeTags => 'टैग';

  @override
  String get aboutMeAddTag => 'टैग जोड़ें...';

  @override
  String get aboutMeDescription => 'विवरण';

  @override
  String get aboutMeDescribeLong => 'हमें और बताएं...';

  @override
  String get aboutMeVisibilityEveryone => 'सभी';

  @override
  String get aboutMeVisibilityContacts => 'संपर्क';

  @override
  String get aboutMeVisibilityOnlyMe => 'केवल मैं';

  @override
  String get settingsProfileSubtitle => 'प्रोफ़ाइल';

  @override
  String get settingsWallpaper => 'वॉलपेपर';

  @override
  String get settingsWallpaperDesc => 'पूरे ऐप के लिए पृष्ठभूमि छवि';

  @override
  String get settingsWallpaperNone => 'कोई नहीं';

  @override
  String get settingsAccount => 'खाता';

  @override
  String get settingsKycVerification => 'पहचान सत्यापन (KYC)';

  @override
  String get settingsOrganizations => 'संगठन';

  @override
  String get incomingCallLabel => 'आने वाली कॉल';

  @override
  String get incomingCallDecline => 'अस्वीकार करें';

  @override
  String get incomingCallAccept => 'स्वीकार करें';

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
  String get meshIncomingCallLabel => '📡 आने वाली मेष कॉल';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'मेष डिवाइस $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'पहले वर्तमान कॉल समाप्त करें';

  @override
  String get callPopupTransportTitle => 'कॉल द्वारा';

  @override
  String get callPopupTransportMesh => '📡 मेष (पीयर-टू-पीयर)';

  @override
  String get callPopupTransportLk => '📞 सर्वर';

  @override
  String get callPopupTransportMeshUnavailable =>
      'संपर्क मेष के माध्यम से उपलब्ध नहीं है';

  @override
  String get meshOnboardingTitle => '📡 मेष कॉल के लिए ऐप खुला होना चाहिए';

  @override
  String get meshOnboardingBody =>
      'जब फोन लॉक होता है, तो मेष कॉल ~30 सेकंड के बाद ड्रॉप हो सकती हैं (iOS सीमा)।';

  @override
  String get meshOnboardingAck => 'समझ गया';

  @override
  String get meshHistoryBadge => '📡 मेष';

  @override
  String get meshHistoryNoChatAvailable => 'संपर्क आपकी सूची में नहीं है';

  @override
  String get meshCallStatusInviting => 'कॉल कर रहे हैं…';

  @override
  String get meshCallStatusConnecting => 'कनेक्ट कर रहे हैं…';

  @override
  String get meshCallEndedUserHangup => 'कॉल समाप्त';

  @override
  String get meshCallEndedRemoteHangup => 'पीयर द्वारा समाप्त';

  @override
  String get meshCallEndedRejected => 'अस्वीकृत';

  @override
  String get meshCallEndedNoAnswer => 'कोई उत्तर नहीं';

  @override
  String get meshCallEndedConnectionLost => 'कनेक्शन खो गया';

  @override
  String get meshCallEndedError => 'कनेक्शन त्रुटि';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 मेष · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 मेष';

  @override
  String get batteryExemptionTitle => '📡 विश्वसनीय मेष कॉल';

  @override
  String get batteryExemptionBody =>
      'ऐप को बैटरी प्रतिबंधों के बिना चलने की अनुमति दें ताकि Android बैकग्राउंड में मेष को बंद न करे।';

  @override
  String get batteryExemptionAccept => 'सेटिंग्स खोलें';

  @override
  String get batteryExemptionDismiss => 'अभी नहीं';

  @override
  String get groupCamera => 'कैमरा';

  @override
  String get groupGallery => 'गैलरी';

  @override
  String get groupAvatarUpdated => 'समूह अवतार अपडेट किया गया';

  @override
  String get groupNameTitle => 'समूह का नाम';

  @override
  String get groupEnterName => 'नाम दर्ज करें';

  @override
  String get groupDescriptionTitle => 'समूह विवरण';

  @override
  String get groupEnterDescription => 'समूह विवरण दर्ज करें';

  @override
  String get groupChangeRoleTitle => 'भूमिका बदलें';

  @override
  String get groupRemoveMemberTitle => 'सदस्य हटाएं';

  @override
  String get groupDescription => 'विवरण';

  @override
  String get groupAddDescription => 'समूह विवरण जोड़ें';

  @override
  String get groupNoDescription => 'कोई विवरण नहीं';

  @override
  String get groupMediaAndFiles => 'मीडिया और फाइलें';

  @override
  String get groupMuteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get groupMuted => 'म्यूट किया गया';

  @override
  String get groupNoResults => 'कोई परिणाम नहीं';

  @override
  String get authInvalidCode => 'अमान्य कोड। फिर से प्रयास करें।';

  @override
  String get loginSubtitle => 'ईमेल और पासवर्ड का उपयोग करें';

  @override
  String get emailRequired => 'ईमेल दर्ज करें';

  @override
  String get emailInvalid => 'अमान्य ईमेल';

  @override
  String get passwordRequired => 'पासवर्ड दर्ज करें';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'पूरे Taler इकोसिस्टम के लिए एक खाता';

  @override
  String get usernameOptional => 'उपयोगकर्ता नाम (वैकल्पिक)';

  @override
  String get usernameMinLength => 'न्यूनतम 3 अक्षर';

  @override
  String get usernameMaxLength => 'अधिकतम 30 अक्षर';

  @override
  String get usernameInvalid => 'केवल अक्षर, अंक और _';

  @override
  String get biometricLoginReason => 'Taler ID में साइन इन करें';

  @override
  String get docTypePassport => 'पासपोर्ट';

  @override
  String get docTypeIdCard => 'आईडी कार्ड';

  @override
  String get docTypeDriverLicense => 'ड्राइवर का लाइसेंस';

  @override
  String get docTypeResidencePermit => 'निवास परमिट';

  @override
  String addressApartment(String number) {
    return 'अपार्टमेंट $number';
  }

  @override
  String get failedToUpdateProfile => 'प्रोफ़ाइल अपडेट करने में विफल';

  @override
  String get failedToStartKyb => 'KYB सत्यापन शुरू करने में विफल';

  @override
  String get orgUpdated => 'संगठन अपडेट किया गया';

  @override
  String get failedToUpdateOrg => 'संगठन अपडेट करने में विफल';

  @override
  String get failedToChangeRole => 'भूमिका बदलने में विफल';

  @override
  String get failedToRemoveMember => 'सदस्य को हटाने में विफल';

  @override
  String get capabilityMessagesTitle => 'संदेश';

  @override
  String get capabilityMessagesDesc =>
      'संदेश जांचें या किसी को लिखें। उदाहरण: \"विक्टर को लिखें: एक घंटे में वहाँ पहुँचूँगा\"';

  @override
  String get capabilityCallsTitle => 'कॉल';

  @override
  String get capabilityCallsDesc =>
      'किसी भी संपर्क को आवाज से कॉल करें। उदाहरण: \"विक्टर विक्टोरोव को कॉल करें\"';

  @override
  String get capabilityChatTitle => 'चैट इतिहास';

  @override
  String get capabilityChatDesc =>
      'मैं चैट इतिहास का विश्लेषण करूंगा। उदाहरण: \"हमने विक्टर के साथ क्या चर्चा की?\"';

  @override
  String get capabilityProfileTitle => 'प्रोफ़ाइल';

  @override
  String get capabilityProfileDesc =>
      'मैं आपकी प्रोफ़ाइल दिखाऊंगा या अपडेट करूंगा। उदाहरण: \"मेरी प्रोफ़ाइल दिखाओ\"';

  @override
  String get capabilityCoachingTitle => 'कोचिंग';

  @override
  String get capabilityCoachingDesc =>
      'मोड्स: ICF कोचिंग, मनोवैज्ञानिक, HR परामर्श। कहें: \"चलो कोचिंग करते हैं\"';

  @override
  String get capabilityCalendarTitle => 'कैलेंडर';

  @override
  String get capabilityCalendarDesc =>
      'एक बैठक निर्धारित करें या एक रिमाइंडर सेट करें। उदाहरण: \"विक्टर के साथ कल 15:00 बजे बैठक निर्धारित करें\"';

  @override
  String get capabilityNotesTitle => 'नोट्स';

  @override
  String get capabilityNotesDesc =>
      'एक विचार सहेजें या हाल के नोट्स पढ़ें। उदाहरण: \"एक विचार लिखें...\" या \"हाल के नोट्स पढ़ें\"';

  @override
  String get assistantCallConfirm => 'कॉल करें?';

  @override
  String get callNoAnswer => 'कोई उत्तर नहीं';

  @override
  String get contactDelete => 'संपर्क हटाएं';

  @override
  String get contactDeleteTitle => 'संपर्क हटाएं';

  @override
  String get contactDeleteConfirm =>
      'क्या आप सुनिश्चित हैं? यह संपर्क हटा दिया जाएगा।';

  @override
  String get contactBlock => 'ब्लॉक';

  @override
  String get contactBlockTitle => 'उपयोगकर्ता को ब्लॉक करें';

  @override
  String get contactBlockConfirm =>
      'यह उपयोगकर्ता आपको संदेश या कॉल नहीं कर सकेगा।';

  @override
  String get contactUnblock => 'अनब्लॉक';

  @override
  String get contactBlocked => 'ब्लॉक किया गया';

  @override
  String get contactYouAreBlocked => 'इस उपयोगकर्ता ने आपको ब्लॉक कर दिया है';

  @override
  String get chatBlockedByYou => 'आपने इस उपयोगकर्ता को ब्लॉक कर दिया है';

  @override
  String get chatYouAreBlocked =>
      'आपको इस उपयोगकर्ता द्वारा ब्लॉक कर दिया गया है';

  @override
  String get chatNotContacts =>
      'उन्हें संदेश भेजने के लिए इस उपयोगकर्ता को संपर्क में जोड़ें';

  @override
  String get contactRevokeRequest => 'अनुरोध रद्द करें';

  @override
  String get messengerPoll => 'मतदान';

  @override
  String get messengerCreatePoll => 'मतदान बनाएं';

  @override
  String get messengerPollQuestion => 'प्रश्न';

  @override
  String messengerPollOption(int number) {
    return 'विकल्प $number';
  }

  @override
  String get messengerPollAddOption => 'विकल्प जोड़ें';

  @override
  String get messengerPollAnonymous => 'गोपनीय मतदान';

  @override
  String get messengerPollMultiple => 'एकाधिक विकल्प';

  @override
  String get messengerPollCreateError => 'मतदान बनाने में विफल';

  @override
  String get messengerPollUnavailable => 'मतदान उपलब्ध नहीं';

  @override
  String get messengerPollMultipleNote => 'आप कई चुन सकते हैं';

  @override
  String messengerPollVotes(int count) {
    return '$count वोट';
  }

  @override
  String get messengerVideoMessage => 'वीडियो संदेश';

  @override
  String get messengerVideoRecordError => 'वीडियो रिकॉर्डिंग त्रुटि';

  @override
  String get messengerVideoPlaybackError => 'वीडियो चलाने में असमर्थ';

  @override
  String get messengerGalleryAccessError => 'गैलरी तक पहुंच नहीं';

  @override
  String get messengerSearchInChat => 'चैट में खोजें...';

  @override
  String get messengerSaveToFavorites => 'पसंदीदा में सहेजें';

  @override
  String get messengerSavedToFavorites => 'पसंदीदा में सहेजा गया';

  @override
  String get messengerSearchInMessages => 'संदेशों में खोजें...';

  @override
  String messengerFoundInMessages(int count) {
    return 'संदेशों में मिला ($count)';
  }

  @override
  String get messengerGroupDefault => 'समूह';

  @override
  String get messengerUserDefault => 'उपयोगकर्ता';

  @override
  String get messengerPin => 'पिन';

  @override
  String get messengerUnpin => 'अनपिन';

  @override
  String get messengerArchive => 'संग्रह';

  @override
  String get messengerUnarchive => 'अनसंग्रह';

  @override
  String get messengerDeleteChat => 'चैट हटाएं';

  @override
  String get messengerDeleteChatTitle => 'चैट हटाएं?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '$name के साथ चैट हटाएं? इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get messengerCreateChannel => 'चैनल बनाएं';

  @override
  String get messengerChannelName => 'नाम';

  @override
  String get messengerChannelDescription => 'विवरण (वैकल्पिक)';

  @override
  String get messengerChannelCreateError => 'चैनल बनाने में विफल';

  @override
  String get messengerFilterAll => 'सभी';

  @override
  String get messengerFilterUnread => 'अपठित';

  @override
  String get messengerFilterPersonal => 'व्यक्तिगत';

  @override
  String get messengerFilterGroups => 'समूह';

  @override
  String get messengerFilterChannels => 'चैनल';

  @override
  String get messengerArchivedSection => 'संग्रहीत';

  @override
  String get messengerSavedSection => 'पसंदीदा';

  @override
  String get messengerSavedSubtitle => 'स्मृति में सहेजें';

  @override
  String messengerArchiveTitle(int count) {
    return 'संग्रह ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'संग्रह खाली है';

  @override
  String messengerYouPrefix(String message) {
    return 'आप: $message';
  }

  @override
  String get messengerMissedCall => 'मिस्ड कॉल';

  @override
  String get messengerSavedTitle => 'पसंदीदा';

  @override
  String get messengerNoSavedMessages => 'कोई सहेजे गए संदेश नहीं';

  @override
  String get messengerSavedHint =>
      'किसी संदेश को लंबे समय तक दबाएं → \"पसंदीदा में सहेजें\"';

  @override
  String get messengerDefaultFile => 'फ़ाइल';

  @override
  String get messengerTopicDefault => 'सामान्य';

  @override
  String get messengerTopicNew => 'नया विषय';

  @override
  String get messengerTopicNameHint => 'विषय का नाम';

  @override
  String get messengerTopicIcon => 'चिह्न';

  @override
  String messengerTopicCount(int count) {
    return '$count विषय';
  }

  @override
  String get messengerNoTopics => 'कोई विषय नहीं';

  @override
  String get messengerNoMessages => 'कोई संदेश नहीं';

  @override
  String get you => 'आप';

  @override
  String get messengerThread => 'थ्रेड';

  @override
  String get messengerThreadReply => 'जवाब';

  @override
  String get messengerThreadReplies => 'जवाब';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'कोई जवाब नहीं';

  @override
  String get messengerReplyHint => 'थ्रेड का जवाब दें...';

  @override
  String get messengerContactName => 'संपर्क नाम';

  @override
  String messengerOriginalName(String name) {
    return 'मूल नाम: $name';
  }

  @override
  String get messengerDisplayName => 'प्रदर्शित नाम';

  @override
  String messengerShareContact(String name) {
    return 'Taler ID में संपर्क: $name';
  }

  @override
  String get messengerAutoDelete => 'संदेश स्वचालित रूप से हटाएं';

  @override
  String get messengerAutoDeleteOff => 'बंद';

  @override
  String get messengerAutoDelete7d => '7 दिन';

  @override
  String get messengerAutoDelete30d => '30 दिन';

  @override
  String get messengerAutoDelete90d => '90 दिन';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count दिन';
  }

  @override
  String get messengerSettingsHeader => 'सेटिंग्स';

  @override
  String get messengerAdminOnly => 'केवल एडमिन पोस्ट कर सकते हैं';

  @override
  String get messengerAdminOnlyDesc => 'सदस्य केवल पढ़ सकते हैं';

  @override
  String get messengerTopics => 'विषय';

  @override
  String get messengerTopicsDesc => 'चैट को विषयों में विभाजित करें';

  @override
  String get aiTwinSection => 'AI वॉइस ट्विन';

  @override
  String get aiTwinEnabled => 'AI ट्विन सक्षम करें';

  @override
  String get aiTwinEnabledDesc =>
      'यदि आप उत्तर नहीं देते हैं, तो आपका AI ट्विन आपकी आवाज़ में कॉल लेता है';

  @override
  String get aiTwinTimeout => 'प्रतिक्रिया समय सीमा';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds सेकंड';
  }

  @override
  String get aiTwinPrompt => 'AI निर्देश';

  @override
  String get aiTwinPromptSubtitle =>
      'AI ट्विन को खुद को कैसे पेश करना चाहिए और किस बारे में बात करनी चाहिए';

  @override
  String aiTwinPromptHint(String name) {
    return 'नमस्ते, यह $name का AI वॉइस ट्विन है। $name अभी कॉल नहीं उठा सकते। मुझे बताएं कौन कॉल कर रहा है और किस बारे में है — मैं इसे पास कर दूंगा।';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'कस्टम वॉइस क्लोनिंग जल्द आ रही है। फिलहाल AI $name की आवाज़ में बोलता है।';
  }

  @override
  String get aiTwinDefaultName => 'मालिक';

  @override
  String get aiTwinPromptReset => 'रीसेट';

  @override
  String get callHistoryAiTwinAnswered => 'AI ट्विन ने उत्तर दिया';

  @override
  String get callHistoryAiTwinSummary => 'कॉल सारांश';

  @override
  String get callHistoryAiTwinTranscript => 'प्रतिलिपि';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '$name से';
  }

  @override
  String get aiTwinOfferTitle => 'उत्तर नहीं दे रहे';

  @override
  String aiTwinOfferBody(String name) {
    return '$name फोन नहीं उठा रहे हैं। उनकी AI आवाज़ ट्विन के साथ संदेश छोड़ें?';
  }

  @override
  String get aiTwinOfferBodyUser => 'उपयोगकर्ता';

  @override
  String get aiTwinOfferAccept => 'हाँ, संदेश छोड़ें';

  @override
  String get aiTwinOfferKeepWaiting => 'प्रतीक्षा करते रहें';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'आपका AI प्रतिनिधि';

  @override
  String get aiTwinHeroSubtitle =>
      'जब आप नहीं उठा सकते, आपकी आवाज़ में कॉल का जवाब देता है।';

  @override
  String get aiTwinProfileTitle => 'AI प्रतिनिधि';

  @override
  String get aiTwinProfileDesc => 'आपकी आवाज़ में कॉल का जवाब देता है';

  @override
  String get aiTwinBadgeOn => 'चालू';

  @override
  String get aiAnalystTitle => 'AI विश्लेषक';

  @override
  String get aiAnalystSubtitle => 'फाइलें, कार्य, विश्लेषण — Claude';

  @override
  String get channelsDiscover => 'चैनल खोजें';

  @override
  String get channelsSearchHint => 'चैनल खोजें';

  @override
  String get channelsSubscribers => 'सदस्य';

  @override
  String get channelsSubscribe => 'सदस्यता लें';

  @override
  String get channelsUnsubscribe => 'सदस्यता समाप्त करें';

  @override
  String get channelsSubscribedLabel => 'आप सदस्य हैं';

  @override
  String get channelsSettings => 'चैनल सेटिंग्स';

  @override
  String get channelsDelete => 'चैनल हटाएं';

  @override
  String get channelsDeleteConfirm => 'चैनल को स्थायी रूप से हटाएं?';

  @override
  String get channelsEmpty => 'अभी तक कोई चैनल नहीं';

  @override
  String get channelsOpen => 'खोलें';

  @override
  String get channelsNameLabel => 'नाम';

  @override
  String get channelsDescriptionLabel => 'विवरण';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'मालिक सदस्यता समाप्त नहीं कर सकता। इसके बजाय चैनल हटाएं।';

  @override
  String get channelsNotFoundRedirect => 'चैनल अब मौजूद नहीं है';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खोजें',
      one: '$count खोज',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फाइलें',
      one: '$count फाइल',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कमांड्स',
      one: '$count कमांड',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count छवियाँ',
      one: '$count छवि',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चरण',
      one: '$count चरण',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$secondsसे';
  }

  @override
  String get savedTitle => 'सहेजे गए संदेश';

  @override
  String get savedSubtitle => 'आपका निजी क्लाउड';

  @override
  String get savedOpenError => 'सहेजे गए संदेश खोल नहीं सके';

  @override
  String get billingWalletTitle => 'वॉलेट';

  @override
  String get billingBuyPackage => 'पैकेज खरीदें';

  @override
  String get billingCurrentBalance => 'वर्तमान शेष राशि';

  @override
  String get billingPackagesTitle => 'पैकेज';

  @override
  String get billingPackagesUnavailable => 'पैकेज उपलब्ध नहीं हैं';

  @override
  String get billingRecentOperations => 'हाल की गतिविधियाँ';

  @override
  String get billingAllOperations => 'सभी गतिविधियाँ';

  @override
  String get billingNoOperations => 'कोई गतिविधियाँ नहीं';

  @override
  String get billingOperationsTitle => 'गतिविधियाँ';

  @override
  String get billingOperationsEmptyTitle => 'अभी तक कोई गतिविधियाँ नहीं';

  @override
  String get billingOperationsEmptySubtitle =>
      'AI फीचर्स के लिए टॉप-अप और शुल्क यहाँ दिखाई देंगे';

  @override
  String get billingPricebookTitle => 'फीचर की कीमतें';

  @override
  String get billingPricebookUnavailable => 'मूल्य सूची उपलब्ध नहीं है';

  @override
  String get billingAiFeaturesTitle => 'AI फीचर्स';

  @override
  String get billingInsufficientFundsTitle => 'अपर्याप्त धनराशि';

  @override
  String get billingInsufficientFundsSubtitle =>
      'इस फीचर का उपयोग करने के लिए अपना बैलेंस टॉप अप करें।';

  @override
  String billingRequiredLine(String required) {
    return 'आवश्यक: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'उपलब्ध: $available μTAL';
  }

  @override
  String get billingTopUp => 'टॉप अप';

  @override
  String get billingCancel => 'रद्द करें';

  @override
  String get billingRetry => 'पुनः प्रयास करें';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'बैलेंस कम हो रहा है: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'वॉलेट और बैलेंस';

  @override
  String get billingSectionHeader => 'बिलिंग और AI';

  @override
  String get billingFeatureVoiceAssistant => 'वॉइस असिस्टेंट';

  @override
  String get billingFeatureWebSearch => 'असिस्टेंट वेब खोज';

  @override
  String get billingFeatureAiTwin => 'वॉइस ट्विन';

  @override
  String get billingFeatureAiTwinLong => 'वॉइस ट्विन (AI ट्विन)';

  @override
  String get billingFeatureOutboundCall => 'आउटबाउंड बॉट';

  @override
  String get billingFeatureOutboundCallLong => 'आउटबाउंड कॉलिंग बॉट';

  @override
  String get billingFeatureWhisperTranscribe => 'कॉल ट्रांसक्रिप्शन';

  @override
  String get billingFeatureMeetingSummary => 'AI कॉल सारांश';

  @override
  String get billingConfigureAiTwin => 'AI ट्विन कॉन्फ़िगर करें';

  @override
  String get billingWebSearchSubtitle => '(असिस्टेंट द्वारा उपयोग किया गया)';

  @override
  String billingPackagePurchased(String balance) {
    return 'पैकेज खरीदा गया: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'अनुशंसित';

  @override
  String get billingSessionTerminatedNoFunds =>
      'बैलेंस समाप्त हो गया — सत्र समाप्त हुआ';

  @override
  String get billingSessionTerminatedGeneric => 'असिस्टेंट सत्र समाप्त हुआ';

  @override
  String billingBuyForPrice(String price) {
    return '€$price में खरीदें';
  }

  @override
  String get billingTxTypeTopup => 'टॉप-अप';

  @override
  String get billingTxTypeRefund => 'वापसी';

  @override
  String get billingTxTypeSpend => 'शुल्क';

  @override
  String get billingUnitMinute => 'मिनट';

  @override
  String get billingUnitRequest => 'अनुरोध';

  @override
  String get billingUnitToken => 'टोकन';

  @override
  String get billingUnitTokens1k => '1K टोकन';

  @override
  String get billingUnitCall => 'कॉल';

  @override
  String get groupCallSelectParticipants => 'प्रतिभागियों का चयन करें';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'खोजें';

  @override
  String get groupCallMaxReached => 'अधिकतम 7 प्रतिभागी';

  @override
  String get groupCallLobbyTitle => 'समूह • लॉबी';

  @override
  String groupCallHostLabel(String name) {
    return 'मेज़बान: $name';
  }

  @override
  String get groupCallMicHint => 'माइक कनेक्ट होने पर सक्रिय होगा';

  @override
  String get groupCallCancel => 'रद्द करें';

  @override
  String get groupCallNoAnswer => 'कोई जवाब नहीं मिला';

  @override
  String get groupCallEndedByHost => 'कॉल मेज़बान द्वारा समाप्त की गई';

  @override
  String get groupCallAllLeft => 'सभी कॉल छोड़ चुके हैं';

  @override
  String get groupCallEnded => 'कॉल समाप्त हुई';

  @override
  String groupCallActiveTitle(int count) {
    return 'समूह • $count';
  }

  @override
  String get groupCallConnectionLost => 'कनेक्शन खो गया';

  @override
  String get groupCallMuteRequested =>
      'मेज़बान ने सभी को म्यूट करने के लिए कहा';

  @override
  String get groupCallUnmute => 'अनम्यूट';

  @override
  String get groupCallMute => 'म्यूट';

  @override
  String get groupCallMuteAll => 'सभी को म्यूट करें';

  @override
  String get groupCallLeave => 'छोड़ें';

  @override
  String get groupCallStatusCalling => 'कॉल कर रहे हैं…';

  @override
  String get groupCallStatusDeclined => 'अस्वीकृत';

  @override
  String get groupCallStatusTimeout => 'कोई जवाब नहीं';

  @override
  String get groupCallStatusLeft => 'छोड़ दिया';

  @override
  String groupCallKickConfirm(String name) {
    return '$name को कॉल से हटाएं';
  }

  @override
  String get groupCallCancelAction => 'रद्द करें';

  @override
  String get groupCallActiveBanner => 'सक्रिय कॉल';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'समूह: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'समूह: $host';
  }

  @override
  String get groupCallCreateError => 'कॉल नहीं बना सके';

  @override
  String get groupCallJoinError => 'कॉल में शामिल नहीं हो सके';

  @override
  String get groupCallLivekitError => 'LiveKit त्रुटि';

  @override
  String get groupCallDone => 'हो गया';

  @override
  String get groupCallNoResults => 'कोई परिणाम नहीं';

  @override
  String get groupCallNoContacts => 'कोई संपर्क नहीं';

  @override
  String get meshGcContactOffline => 'इस वाई-फाई पर नहीं';

  @override
  String get meshGcOnlineViaMesh => 'मेश के माध्यम से ऑनलाइन';

  @override
  String get meshGcMaxInvitees =>
      'समूह कॉल में अधिकतम 4 आमंत्रित (कुल 5 लोग) का समर्थन होता है।';

  @override
  String get meshGcStart => 'समूह कॉल शुरू करें';

  @override
  String get meshGcCancel => 'रद्द करें';

  @override
  String get meshGcStatusCalling => 'कॉल कर रहे हैं…';

  @override
  String get meshGcStatusJoined => 'शामिल हो गए';

  @override
  String get meshGcStatusDeclined => 'अस्वीकृत';

  @override
  String get meshGcStatusNoAnswer => 'कोई उत्तर नहीं';

  @override
  String get meshGcStatusConnectionFailed => 'कनेक्शन विफल';

  @override
  String get meshGcStatusLeft => 'छोड़ दिया';

  @override
  String get meshGcTopTitle => 'मेश';

  @override
  String get meshGcBusyOneOnOne => 'पहले अपनी वर्तमान कॉल समाप्त करें।';

  @override
  String get presenceOnline => 'ऑनलाइन';

  @override
  String get presenceLastSeenJustNow => 'अभी-अभी देखा गया';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return '$minutes मिनट पहले देखा गया';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'आज $time पर देखा गया';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'कल $time पर देखा गया';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return '$date को देखा गया';
  }

  @override
  String get presenceLastSeenRecently => 'हाल ही में देखा गया';

  @override
  String get privacySectionTitle => 'गोपनीयता';

  @override
  String get privacyLastSeenLabel => 'आपका अंतिम देखा गया समय कौन देखता है';

  @override
  String get privacyEveryone => 'सभी';

  @override
  String get privacyContacts => 'केवल संपर्क';

  @override
  String get privacyNobody => 'कोई नहीं';

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
}
