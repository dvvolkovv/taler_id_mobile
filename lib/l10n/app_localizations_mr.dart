// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'शोधा';

  @override
  String get appSubtitle => 'एकत्रित परिसंस्था ओळख';

  @override
  String get login => 'साइन इन';

  @override
  String get loginButton => 'साइन इन';

  @override
  String get register => 'खाते तयार करा';

  @override
  String get registerButton => 'खाते तयार करा';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्डची पुष्टी करा';

  @override
  String get firstName => 'पहिले नाव';

  @override
  String get lastName => 'आडनाव';

  @override
  String get noAccount => 'खाते नाही?';

  @override
  String get createOne => 'एक तयार करा';

  @override
  String get haveAccount => 'खाते आधीच आहे?';

  @override
  String get signIn => 'साइन इन';

  @override
  String get passwordMinLength => 'किमान 8 अक्षरे';

  @override
  String get invalidEmail => 'वैध ईमेल प्रविष्ट करा';

  @override
  String get fieldRequired => 'आवश्यक क्षेत्र';

  @override
  String get twoFATitle => 'दुहेरी घटक प्रमाणीकरण';

  @override
  String get twoFASubtitle =>
      'आपल्या प्रमाणीकरण अनुप्रयोगातील 6-अंकी कोड प्रविष्ट करा';

  @override
  String get twoFACode => '2FA कोड';

  @override
  String get verify => 'पडताळा';

  @override
  String get tabProfile => 'प्रोफाइल';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'संघटना';

  @override
  String get tabSettings => 'सेटिंग्ज';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get phone => 'फोन';

  @override
  String get country => 'देश';

  @override
  String get dateOfBirth => 'जन्मतारीख';

  @override
  String get documents => 'दस्तऐवज';

  @override
  String get addDocument => 'दस्तऐवज जोडा';

  @override
  String get noDocuments => 'कोणतेही दस्तऐवज अपलोड केलेले नाहीत';

  @override
  String get save => 'जतन करा';

  @override
  String get profileUpdated => 'प्रोफाइल अद्यतनित केले';

  @override
  String get personalData => 'वैयक्तिक डेटा';

  @override
  String get passport => 'पासपोर्ट';

  @override
  String get drivingLicense => 'वाहन चालविण्याचा परवाना';

  @override
  String get diploma => 'डिप्लोमा';

  @override
  String get nationalId => 'राष्ट्रीय ओळखपत्र';

  @override
  String get certificate => 'प्रमाणपत्र';

  @override
  String get notSpecified => 'निर्दिष्ट नाही';

  @override
  String get notSpecifiedFemale => 'निर्दिष्ट नाही';

  @override
  String get documentType => 'दस्तऐवज प्रकार';

  @override
  String get passportId => 'पासपोर्ट / ओळखपत्र';

  @override
  String get diplomaCertificate => 'डिप्लोमा / प्रमाणपत्र';

  @override
  String get loadError => 'लोडिंग त्रुटी';

  @override
  String get verification => 'सत्यापन';

  @override
  String get countryAustria => 'ऑस्ट्रिया';

  @override
  String get countryGermany => 'जर्मनी';

  @override
  String get countryRussia => 'रशिया';

  @override
  String get countryUkraine => 'युक्रेन';

  @override
  String get countryKazakhstan => 'कझाकस्तान';

  @override
  String get countryBelarus => 'बेलारूस';

  @override
  String get countryOther => 'इतर';

  @override
  String get kycTitle => 'KYC सत्यापन';

  @override
  String get kycVerified => 'सत्यापित';

  @override
  String get kycPending => 'प्रलंबित';

  @override
  String get kycRejected => 'नाकारले';

  @override
  String get kycUnverified => 'असत्यापित';

  @override
  String get kycVerifiedDesc =>
      'आपली ओळख सत्यापित झाली आहे. आपल्याला Taler पर्यावरणातील सर्व वैशिष्ट्यांचा पूर्ण प्रवेश आहे.';

  @override
  String get kycPendingDesc =>
      'आपले दस्तऐवज पुनरावलोकनात आहेत. हे सामान्यतः 1-2 व्यावसायिक दिवस घेतात.';

  @override
  String get kycRejectedDesc =>
      'सत्यापन अयशस्वी. कृपया कारण पुनरावलोकन करा आणि आपले दस्तऐवज पुन्हा सबमिट करा.';

  @override
  String get kycUnverifiedDesc =>
      'Taler पर्यावरणातील आर्थिक वैशिष्ट्यांचा पूर्ण प्रवेश अनलॉक करण्यासाठी सत्यापन पूर्ण करा.';

  @override
  String get startVerification => 'सत्यापन प्रारंभ करा';

  @override
  String get retryVerification => 'सत्यापन पुन्हा प्रयत्न करा';

  @override
  String verifiedAt(String date) {
    return 'सत्यापित: $date';
  }

  @override
  String get documentsSubmitted => 'पुनरावलोकनासाठी दस्तऐवज सबमिट केले';

  @override
  String get documentsSubmittedDesc =>
      'पुनरावलोकन सामान्यतः 1-2 व्यावसायिक दिवस घेतात. आपल्याला निकालासह एक पुश सूचना प्राप्त होईल.';

  @override
  String get securityAes => 'आपले डेटा AES-256 एन्क्रिप्शनसह संरक्षित आहे';

  @override
  String get verificationTime => 'सत्यापनास 1-2 व्यावसायिक दिवस लागतात';

  @override
  String get pushNotification => 'आपल्याला निकालासह एक पुश सूचना प्राप्त होईल';

  @override
  String get kycWebOnly => 'KYC सत्यापन फक्त मोबाइल अॅपमध्ये उपलब्ध आहे.';

  @override
  String verificationError(String code) {
    return 'सत्यापन त्रुटी: $code';
  }

  @override
  String get organizations => 'संस्था';

  @override
  String get noOrganizations => 'कोणतीही संस्था नाहीत';

  @override
  String get noOrganizationsDesc => 'संस्था तयार करा किंवा आमंत्रण स्वीकारा';

  @override
  String get createOrganization => 'संस्था तयार करा';

  @override
  String get newOrganization => 'नवीन संस्था';

  @override
  String get orgName => 'नाव *';

  @override
  String get orgDescription => 'वर्णन';

  @override
  String get orgEmail => 'संपर्क ईमेल';

  @override
  String get orgWebsite => 'वेबसाइट';

  @override
  String get orgLegalAddress => 'कायदेशीर पत्ता';

  @override
  String get create => 'तयार करा';

  @override
  String get organization => 'संस्था';

  @override
  String get contacts => 'संपर्क';

  @override
  String members(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String get inviteMember => 'सदस्य आमंत्रित करा';

  @override
  String get invite => 'आमंत्रण';

  @override
  String get sendInvite => 'आमंत्रण पाठवा';

  @override
  String inviteSent(String email) {
    return '$email वर आमंत्रण पाठवले';
  }

  @override
  String get role => 'भूमिका';

  @override
  String get roleOwner => 'मालक';

  @override
  String get roleAdmin => 'प्रशासक';

  @override
  String get roleOperator => 'ऑपरेटर';

  @override
  String get roleViewer => 'प्रेक्षक';

  @override
  String get editOrganization => 'संपादन करा';

  @override
  String get editOrganizationTitle => 'संस्था संपादन करा';

  @override
  String get removeMember => 'सदस्य काढा';

  @override
  String removeMemberConfirm(String name) {
    return 'संस्थेतून $name काढा?';
  }

  @override
  String get memberRemoved => 'सदस्य काढला';

  @override
  String get roleChanged => 'भूमिका बदलली';

  @override
  String get kybVerified => 'प्रमाणित';

  @override
  String get kybPending => 'प्रलंबित';

  @override
  String get kybRejected => 'नाकारले';

  @override
  String get kybNone => 'अप्रमाणित';

  @override
  String get kybVerification => 'KYB प्रमाणीकरण सुरू करा';

  @override
  String get kybStartBusiness => 'व्यवसाय प्रमाणीकरण सुरू करा';

  @override
  String get kybStatusLabel => 'KYB स्थिती';

  @override
  String get noKyb => 'KYB नाही';

  @override
  String get kybBusinessVerificationTitle => 'व्यवसाय प्रमाणीकरण (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'संस्था यशस्वीरित्या प्रमाणित झाली.';

  @override
  String get kybPendingOrgDesc =>
      'कागदपत्रे पुनरावलोकनात आहेत. हे सामान्यतः 1-3 व्यावसायिक दिवस घेतात.';

  @override
  String get kybRejectedOrgDesc =>
      'प्रमाणीकरण अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get kybNoneOrgDesc =>
      'व्यवसाय वैशिष्ट्ये वापरण्यासाठी आपल्या संस्थेचे प्रमाणीकरण करा.';

  @override
  String get invitePlus => '+ आमंत्रण';

  @override
  String get kybVerificationTitle => 'KYB प्रमाणीकरण';

  @override
  String get kybWebOnlyBusiness =>
      'KYB पडताळणी फक्त मोबाइल अॅपमध्ये उपलब्ध आहे.';

  @override
  String get unknownDevice => 'अज्ञात डिव्हाइस';

  @override
  String get ipUnknown => 'IP अज्ञात';

  @override
  String get currentSessionLabel => 'सध्याचे';

  @override
  String get endSessionAction => 'समाप्त';

  @override
  String get deviceLoggedOut => 'डिव्हाइस साइन आउट केले जाईल.';

  @override
  String get acceptInvitationTitle => 'संघटना निमंत्रण';

  @override
  String get acceptInvitation => 'निमंत्रण स्वीकारा';

  @override
  String get acceptInvitationDesc =>
      'तुम्हाला Taler पर्यावरणात एका संघटनेत सामील होण्यासाठी आमंत्रित केले आहे.';

  @override
  String get accept => 'स्वीकारा';

  @override
  String get reject => 'नाकार';

  @override
  String get sessions => 'सक्रिय सत्रे';

  @override
  String get currentSession => 'सध्याचे सत्र';

  @override
  String get deleteSession => 'सत्र समाप्त करा';

  @override
  String get deleteSessionConfirm => 'हे सत्र समाप्त करायचे?';

  @override
  String get sessionDeleted => 'सत्र समाप्त झाले';

  @override
  String get noSessions => 'कोणतीही सक्रिय सत्रे नाहीत';

  @override
  String minutesAgo(int count) {
    return '$count मिनिटांपूर्वी';
  }

  @override
  String hoursAgo(int count) {
    return '$count तासांपूर्वी';
  }

  @override
  String daysAgo(int count) {
    return '$count दिवसांपूर्वी';
  }

  @override
  String get justNow => 'आत्ताच';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get security => 'सुरक्षा';

  @override
  String get biometrics => 'बायोमेट्रिक्स';

  @override
  String get biometricsDesc => 'फेस ID किंवा फिंगरप्रिंटसह जलद लॉगिन';

  @override
  String get biometricsConfirm =>
      'जलद लॉगिन सक्षम करण्यासाठी बायोमेट्रिक्सची पुष्टी करा';

  @override
  String get biometricsError =>
      'बायोमेट्रिक्स सक्षम करण्यात अयशस्वी. डिव्हाइस सेटिंग्ज तपासा.';

  @override
  String get changePassword => 'पासवर्ड बदला';

  @override
  String get twoFactorAuth => 'दुहेरी घटक प्रमाणीकरण';

  @override
  String get currentPassword => 'सध्याचा पासवर्ड';

  @override
  String get newPassword => 'नवीन पासवर्ड';

  @override
  String get confirmNewPassword => 'नवीन पासवर्डची पुष्टी करा';

  @override
  String get passwordChanged => 'पासवर्ड बदलला';

  @override
  String get wrongCurrentPassword => 'चुकीचा सध्याचा पासवर्ड';

  @override
  String get passwordTooWeak =>
      'पासवर्ड खूप कमकुवत: किमान 8 अक्षरे, अक्षर आणि अंक आवश्यक';

  @override
  String get passwordChangeFailed => 'पासवर्ड बदलण्यात अयशस्वी';

  @override
  String get notifications => 'सूचना';

  @override
  String get permissions => 'परवानग्या';

  @override
  String get permissionNotifications => 'पुश सूचना';

  @override
  String get permissionNotificationsDesc => 'कॉल्स, संदेश, स्थिती';

  @override
  String get permissionMicrophone => 'मायक्रोफोन';

  @override
  String get permissionMicrophoneDesc => 'कॉल्स आणि व्हॉइस असिस्टंट';

  @override
  String get permissionCamera => 'कॅमेरा';

  @override
  String get permissionCameraDesc => 'व्हिडिओ कॉल्स आणि पडताळणी';

  @override
  String get permissionLocation => 'स्थान';

  @override
  String get permissionLocationDesc => 'पडताळणीसाठी वापरले जाते';

  @override
  String get permissionOpenSettings =>
      'परवानगी रद्द करण्यासाठी, प्रणाली सेटिंग्ज उघडा';

  @override
  String get pushKycStatus => 'KYC स्थिती पुश';

  @override
  String get pushKycStatusDesc => 'पडताळणीचा निकाल';

  @override
  String get pushLogins => 'लॉगिन पुश';

  @override
  String get pushLoginsDesc => 'नवीन डिव्हाइसवर साइन इन करताना';

  @override
  String get account => 'खाते';

  @override
  String get language => 'भाषा';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'इंटरफेस भाषा';

  @override
  String get exportData => 'डेटा निर्यात करा (GDPR)';

  @override
  String get deleteAccount => 'खाते हटवा';

  @override
  String get deleteAccountConfirm => 'खाते हटवायचे?';

  @override
  String get deleteAccountDesc =>
      'तुमचा सर्व डेटा हटवला जाईल (GDPR). ही क्रिया अपरिवर्तनीय आहे.';

  @override
  String get logout => 'साइन आउट';

  @override
  String get logoutConfirm => 'साइन आउट करायचे?';

  @override
  String get logoutDesc =>
      'तुम्ही या डिव्हाइसवरून Taler ID वरून साइन आउट केले जाल.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN कोड';

  @override
  String get pinCodeDesc => '4-अंकी कोडसह जलद लॉगिन';

  @override
  String get setupPin => 'PIN सेट करा';

  @override
  String get enterPin => 'PIN प्रविष्ट करा';

  @override
  String get confirmPin => 'PIN पुष्टी करा';

  @override
  String get pinMismatch => 'PIN जुळत नाहीत';

  @override
  String get passwordMismatch => 'पासवर्ड जुळत नाहीत';

  @override
  String get pinSet => 'PIN यशस्वीरित्या सेट केला';

  @override
  String get enterPinToLogin => 'साइन इन करण्यासाठी PIN प्रविष्ट करा';

  @override
  String get pinIncorrect => 'चुकीचा PIN';

  @override
  String get removePin => 'PIN काढा';

  @override
  String get pinRemoved => 'PIN काढला';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get delete => 'हटवा';

  @override
  String get ok => 'ठीक आहे';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get loading => 'लोड करत आहे...';

  @override
  String get error => 'त्रुटी';

  @override
  String get success => 'यशस्वी';

  @override
  String get noData => 'माहिती नाही';

  @override
  String get failedToLoad => 'माहिती लोड करण्यात अयशस्वी';

  @override
  String get failedToLoadProfile => 'प्रोफाइल लोड करण्यात अयशस्वी';

  @override
  String get failedToSave => 'बदल जतन करण्यात अयशस्वी';

  @override
  String get failedToLoadOrgs => 'संस्था लोड करण्यात अयशस्वी';

  @override
  String get failedToLoadOrg => 'संस्थेची माहिती लोड करण्यात अयशस्वी';

  @override
  String get failedToCreateOrg => 'संस्था तयार करण्यात अयशस्वी';

  @override
  String get failedToInvite => 'आमंत्रण पाठवण्यात अयशस्वी';

  @override
  String get failedToAcceptInvite => 'आमंत्रण स्वीकारण्यात अयशस्वी';

  @override
  String get failedToLoadSessions => 'सत्र लोड करण्यात अयशस्वी';

  @override
  String get failedToDeleteSession => 'सत्र समाप्त करण्यात अयशस्वी';

  @override
  String get failedToLoadKyc => 'सत्यापन स्थिती लोड करण्यात अयशस्वी';

  @override
  String get failedToStartKyc => 'सत्यापन सुरू करण्यात अयशस्वी';

  @override
  String get verifiedPersonalInfo => 'सत्यापित माहिती';

  @override
  String get middleName => 'मधले नाव';

  @override
  String get placeOfBirth => 'जन्मस्थान';

  @override
  String get nationality => 'राष्ट्रीयत्व';

  @override
  String get gender => 'लिंग';

  @override
  String get genderMale => 'पुरुष';

  @override
  String get genderFemale => 'स्त्री';

  @override
  String get docNumber => 'क्रमांक';

  @override
  String get docIssuedDate => 'जारी तारीख';

  @override
  String get docValidUntil => 'वैध तारीख';

  @override
  String get docIssuedBy => 'जारीकर्ता';

  @override
  String get address => 'पत्ता';

  @override
  String get refreshData => 'माहिती रीफ्रेश करा';

  @override
  String get failedToLoadSumsubData => 'सत्यापन माहिती लोड करण्यात अयशस्वी';

  @override
  String get sumsubDataLoading => 'सत्यापन माहिती लोड होत आहे...';

  @override
  String get reviewResultGreen => 'सत्यापन यशस्वी';

  @override
  String get reviewResultRed => 'सत्यापन अयशस्वी';

  @override
  String get tabAssistant => 'सहाय्यक';

  @override
  String get assistantConnecting => 'जोडले जात आहे…';

  @override
  String get assistantSpeaking => 'बोलत आहे…';

  @override
  String get assistantListening => 'ऐकत आहे…';

  @override
  String get assistantTapToStart => 'सुरू करण्यासाठी टॅप करा';

  @override
  String get assistantTapToTalk => 'AI शी बोलण्यासाठी टॅप करा';

  @override
  String get assistantRealtimeDesc =>
      'सहाय्यक रिअल टाइममध्ये आवाजाने प्रतिसाद देतो';

  @override
  String get assistantConnectingToAssistant => 'सहाय्यकाशी जोडले जात आहे...';

  @override
  String get assistantAiSpeaking => 'AI बोलत आहे...';

  @override
  String get assistantAiListening => 'AI ऐकत आहे';

  @override
  String get assistantSpeakerOn => 'स्पीकर चालू';

  @override
  String get assistantSpeaker => 'स्पीकर';

  @override
  String get assistantEnd => 'समाप्त';

  @override
  String get assistantUnmute => 'अनम्यूट';

  @override
  String get assistantMicrophone => 'मायक्रोफोन';

  @override
  String get assistantConnectionError => 'कनेक्शन त्रुटी';

  @override
  String get tabMessenger => 'संदेश';

  @override
  String get tabCalls => 'कॉल्स';

  @override
  String get tabCalendar => 'कॅलेंडर';

  @override
  String get appearance => 'देखावा';

  @override
  String get appearanceSelect => 'थीम निवडा';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get onboardingTitle1 => 'एकत्रित ओळख';

  @override
  String get onboardingDesc1 =>
      'Taler ID हे Taler परिसंस्थेमधील तुमचे डिजिटल पासपोर्ट आहे. सर्व सेवांसाठी एक खाते.';

  @override
  String get onboardingTitle2 => 'डेटा सुरक्षा';

  @override
  String get onboardingDesc2 =>
      'KYC पडताळणी, AES-256 एन्क्रिप्शन, आणि दोन-घटक प्रमाणीकरण तुमची ओळख सुरक्षित ठेवतात.';

  @override
  String get onboardingTitle3 => 'माहिती मिळवा';

  @override
  String get onboardingDesc3 =>
      'पडताळणी स्थिती, नवीन उपकरणांवरील लॉगिन्स, आणि येणारे कॉल्स याबद्दल सूचना मिळवा.';

  @override
  String get onboardingNext => 'पुढे';

  @override
  String get onboardingEnableNotifications => 'सूचना सक्षम करा';

  @override
  String get onboardingTitle4 => 'व्हॉइस कॉल्स';

  @override
  String get onboardingDesc4 =>
      'व्हॉइस कॉल्स आणि AI सहाय्यकासाठी मायक्रोफोन प्रवेश द्या. तुम्ही हे नंतर सेटिंग्जमध्ये बदलू शकता.';

  @override
  String get onboardingEnableMicrophone => 'मायक्रोफोन सक्षम करा';

  @override
  String get onboardingStart => 'सुरू करा';

  @override
  String get onboardingSkip => 'वगळा';

  @override
  String get meshLocalNetworkPromptTitle => 'स्थानिक नेटवर्क प्रवेश द्या';

  @override
  String get meshLocalNetworkPromptBody =>
      'Wi-Fi वर सहकारी शोधण्यासाठी (ऑफलाइन गट कॉल्स), iOS ला स्थानिक नेटवर्क परवानगी आवश्यक आहे. सेटिंग्ज उघडा → गोपनीयता आणि सुरक्षा → स्थानिक नेटवर्क → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'सेटिंग्ज उघडा';

  @override
  String get meshLocalNetworkPromptDismiss => 'समजले';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get forgotPasswordTitle => 'पासवर्ड रीसेट करा';

  @override
  String get forgotPasswordSubtitle =>
      'रीसेट कोड प्राप्त करण्यासाठी तुमचा ईमेल प्रविष्ट करा';

  @override
  String resetCodeSent(String email) {
    return 'कोड $email वर पाठवला';
  }

  @override
  String get enterResetCode => 'कोड प्रविष्ट करा';

  @override
  String get resetPasswordButton => 'पासवर्ड रीसेट करा';

  @override
  String get passwordResetSuccess => 'पासवर्ड यशस्वीरित्या रीसेट केला';

  @override
  String get sendCode => 'कोड पाठवा';

  @override
  String get resendCode => 'कोड पुन्हा पाठवा';

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
  String get newGroup => 'नवीन गट';

  @override
  String get newChat => 'नवीन चॅट';

  @override
  String get groupName => 'गटाचे नाव';

  @override
  String get createGroup => 'गट तयार करा';

  @override
  String get groupInfo => 'गट माहिती';

  @override
  String groupMembers(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String get addMembers => 'सदस्य जोडा';

  @override
  String get leaveGroup => 'गट सोडा';

  @override
  String get leaveGroupConfirm => 'हा गट सोडायचा?';

  @override
  String get deleteGroup => 'गट हटवा';

  @override
  String get deleteGroupConfirm => 'हा गट हटवायचा? हे पूर्ववत करता येणार नाही.';

  @override
  String get groupRoleOwner => 'मालक';

  @override
  String get groupRoleAdmin => 'प्रशासक';

  @override
  String get groupRoleMember => 'सदस्य';

  @override
  String get selectParticipants => 'सहभागी निवडा';

  @override
  String selectedCount(int count) {
    return '$count निवडले';
  }

  @override
  String get changeRole => 'भूमिका बदला';

  @override
  String get groupCreated => 'गट तयार झाला';

  @override
  String memberJoined(String name) {
    return '$name सामील झाला';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name सोडला';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name काढला गेला';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name आता $role आहे';
  }

  @override
  String participantsCount(int count) {
    return '$count सहभागी';
  }

  @override
  String get enterGroupName => 'गटाचे नाव प्रविष्ट करा';

  @override
  String get muteNotifications => 'सूचना म्यूट करा';

  @override
  String get unmuteNotifications => 'सूचना अनम्यूट करा';

  @override
  String get muteFor1Hour => '1 तासासाठी';

  @override
  String get muteFor8Hours => '8 तासांसाठी';

  @override
  String get muteFor2Days => '2 दिवसांसाठी';

  @override
  String get muteForever => 'सर्वकाळासाठी';

  @override
  String get muted => 'म्यूट केले';

  @override
  String get tabTranslator => 'भाषांतर';

  @override
  String get translatorTitle => 'भाषांतरकार';

  @override
  String get translatorSelectLanguage => 'भाषा निवडा';

  @override
  String get translatorDownloading => 'भाषा मॉडेल्स डाउनलोड करत आहे...';

  @override
  String get translatorDownloadingHint =>
      'पहिल्या डाउनलोडसाठी इंटरनेट आवश्यक आहे';

  @override
  String get translatorTypeHint => 'मजकूर टाइप करा किंवा मायक्रोफोनवर टॅप करा';

  @override
  String get translatorListening => 'ऐकत आहे...';

  @override
  String get translatorTapToSpeak => 'बोलण्यासाठी टॅप करा';

  @override
  String get translatorTapToStop => 'थांबवण्यासाठी टॅप करा';

  @override
  String get translatorAutoSpeak => 'स्वयंचलित बोलणे';

  @override
  String get translatorCopied => 'कॉपी केले';

  @override
  String get translatorLangRu => 'रशियन';

  @override
  String get translatorLangEn => 'इंग्रजी';

  @override
  String get translatorLangDe => 'जर्मन';

  @override
  String get translatorLangFr => 'फ्रेंच';

  @override
  String get translatorLangEs => 'स्पॅनिश';

  @override
  String get translatorLangIt => 'इटालियन';

  @override
  String get translatorLangPt => 'पोर्तुगीज';

  @override
  String get translatorLangTr => 'तुर्की';

  @override
  String get translatorLangZh => 'चिनी';

  @override
  String get translatorLangJa => 'जपानी';

  @override
  String get translatorLangKo => 'कोरियन';

  @override
  String get translatorLangAr => 'अरबी';

  @override
  String get translatorLangPl => 'पोलिश';

  @override
  String get translatorLangSk => 'स्लोव्हाक';

  @override
  String get translatorLangCs => 'झेक';

  @override
  String get translatorLangNl => 'डच';

  @override
  String get translatorLangSv => 'स्वीडिश';

  @override
  String get translatorLangDa => 'डॅनिश';

  @override
  String get translatorLangNo => 'नॉर्वेजियन';

  @override
  String get translatorLangFi => 'फिन्निश';

  @override
  String get translatorLangUk => 'युक्रेनियन';

  @override
  String get translatorLangEl => 'ग्रीक';

  @override
  String get translatorLangRo => 'रोमानियन';

  @override
  String get translatorLangHu => 'हंगेरियन';

  @override
  String get translatorLangBg => 'बल्गेरियन';

  @override
  String get translatorLangHr => 'क्रोएशियन';

  @override
  String get translatorLangSr => 'सर्बियन';

  @override
  String get translatorLangHi => 'हिंदी';

  @override
  String get translatorLangTh => 'थाई';

  @override
  String get translatorLangVi => 'व्हिएतनामी';

  @override
  String get translatorLangId => 'इंडोनेशियन';

  @override
  String get translatorLangMs => 'मलय';

  @override
  String get translatorLangHe => 'हिब्रू';

  @override
  String get translatorLangFa => 'फारसी';

  @override
  String get callInProgress => 'कॉल चालू आहे';

  @override
  String get joinCall => 'सामील व्हा';

  @override
  String get createCallLink => 'कॉल लिंक';

  @override
  String get callLinkCopied => 'लिंक कॉपी केली';

  @override
  String get callLinkTitle => 'रूम लिंक';

  @override
  String get connectionUnstable => 'कनेक्शन अस्थिर आहे — तुमचे इंटरनेट तपासा';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'काल';

  @override
  String get errorTimeout =>
      'कनेक्शनची वेळ संपली. तुमचे इंटरनेट कनेक्शन तपासा.';

  @override
  String get errorNoConnection => 'कोणतेही इंटरनेट कनेक्शन नाही.';

  @override
  String get errorGeneral => 'एक त्रुटी आली आहे. कृपया पुन्हा प्रयत्न करा.';

  @override
  String errorWithMessage(String message) {
    return 'त्रुटी: $message';
  }

  @override
  String get notifChannelMessages => 'संदेश';

  @override
  String get notifChannelMessagesDesc => 'नवीन संदेश सूचना';

  @override
  String get notifChannelMissedCalls => 'मिस्ड कॉल्स';

  @override
  String get notifChannelMissedCallsDesc => 'मिस्ड कॉल सूचना';

  @override
  String get notifMissedCall => 'मिस्ड कॉल';

  @override
  String get notifAccept => 'स्वीकारा';

  @override
  String get notifDecline => 'नकारा';

  @override
  String get notifIncomingCall => 'येणारा कॉल';

  @override
  String get notifIncomingCallChannel => 'येणारा कॉल';

  @override
  String get notifMissedCallChannel => 'मिस्ड कॉल';

  @override
  String get notifUnknown => 'अज्ञात';

  @override
  String get effectNone => 'कोणताही पार्श्वभूमी नाही';

  @override
  String get effectBlur => 'ब्लर';

  @override
  String get effectOffice => 'ऑफिस';

  @override
  String get effectNature => 'निसर्ग';

  @override
  String get effectGradient => 'ग्रेडियंट';

  @override
  String get effectLibrary => 'लायब्ररी';

  @override
  String get effectCity => 'शहर';

  @override
  String get effectMinimalism => 'मिनिमलिझम';

  @override
  String get voiceParticipant => 'सहभागी';

  @override
  String get voiceInvitesToRoom => 'तुम्हाला रूममध्ये आमंत्रित करतो';

  @override
  String get voiceRoom => 'रूम';

  @override
  String get voicePasswordProtected => 'पासवर्ड संरक्षित';

  @override
  String get voicePasswordHint => 'पासवर्ड';

  @override
  String get voiceEnter => 'प्रवेश करा';

  @override
  String get voiceJoinRoom => 'रूममध्ये सामील व्हा';

  @override
  String get voiceYourName => 'तुमचे नाव';

  @override
  String voiceInvitationSent(String name) {
    return '$name ला आमंत्रण पाठवले';
  }

  @override
  String get voiceNoActiveRoom => 'कोणतीही सक्रिय रूम नाही';

  @override
  String get voiceCameraPermission =>
      'सेटिंग्ज → प्रायव्हसी → कॅमेरा → TalerID मध्ये कॅमेरा प्रवेश परवानगी द्या';

  @override
  String get voiceOpenSettings => 'उघडा';

  @override
  String voiceCameraError(String error) {
    return 'कॅमेरा सक्षम करण्यात अयशस्वी: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'सर्व सहमत. रेकॉर्डिंग सुरू.';

  @override
  String get voiceNewParticipantAgreed => 'नवीन सहभागी रेकॉर्डिंगसाठी सहमत.';

  @override
  String get voiceDeclinedRecording =>
      'तुम्ही रेकॉर्डिंग नाकारले. कॉल सोडत आहे.';

  @override
  String get voiceRecordingEnded => 'रेकॉर्डिंग संपले';

  @override
  String get voiceRecordingInProgress => 'रेकॉर्डिंग चालू आहे';

  @override
  String get voiceTranscriptionRequest => 'लिप्यंतरण विनंती';

  @override
  String get voiceRecordingRequest => 'रेकॉर्डिंग विनंती';

  @override
  String get voiceAgree => 'सहमत';

  @override
  String get voiceDeclineAndLeave => 'नकार द्या आणि सोडा';

  @override
  String get voiceAudioOutput => 'ऑडिओ आउटपुट';

  @override
  String get voiceAudioPhone => 'फोन';

  @override
  String get voiceAudioSpeaker => 'स्पीकर';

  @override
  String get voiceAudioBluetooth => 'ब्लूटूथ';

  @override
  String get voiceAudioHeadphones => 'हेडफोन्स';

  @override
  String get voiceLinkCopied => 'लिंक कॉपी केली';

  @override
  String get voiceTranslateTo => 'मध्ये भाषांतर करा';

  @override
  String get voiceSearchLanguage => 'भाषा शोधा...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'रूम $name';
  }

  @override
  String get voiceVoiceCall => 'व्हॉइस कॉल';

  @override
  String get voiceOnHold => 'होल्डवर';

  @override
  String get voiceActiveCall => 'सक्रिय';

  @override
  String get voiceEndAllCalls => 'सर्व कॉल समाप्त करा';

  @override
  String get voiceEndThisCall => 'हा कॉल समाप्त करा';

  @override
  String get voiceCopyLink => 'लिंक कॉपी करा';

  @override
  String get voiceAddParticipant => 'सहभागी जोडा';

  @override
  String get voiceReconnecting => 'पुन्हा कनेक्ट करत आहे...';

  @override
  String get voiceConnectionError => 'कनेक्शन त्रुटी';

  @override
  String get voiceClose => 'बंद करा';

  @override
  String get voiceCalling => 'कॉल करत आहे...';

  @override
  String get voiceCallActive => 'कॉल सक्रिय';

  @override
  String get voiceWaiting => 'प्रतीक्षा';

  @override
  String get voiceWaitingUpper => 'प्रतीक्षा';

  @override
  String get voiceRec => 'रेक';

  @override
  String get voiceStop => 'थांबवा';

  @override
  String get voiceRecord => 'रेकॉर्डिंग';

  @override
  String get voiceTranslation => 'भाषांतर';

  @override
  String get voiceAudio => 'ऑडिओ';

  @override
  String get voiceFlipCamera => 'फ्लिप';

  @override
  String get voiceBackground => 'पार्श्वभूमी';

  @override
  String get voiceAssistantSpeakingStatus => 'सहाय्यक बोलत आहे...';

  @override
  String get voiceAssistantListeningStatus => 'सहाय्यक ऐकत आहे...';

  @override
  String get voiceUnmute => 'म्यूट बंद करा';

  @override
  String get voiceMic => 'मायक्रोफोन';

  @override
  String get voiceAssistantLabel => 'सहाय्यक';

  @override
  String get voiceCameraOn => 'कॅमेरा चालू';

  @override
  String get voiceCameraLabel => 'कॅमेरा';

  @override
  String get voiceEndCall => 'कॉल समाप्त करा';

  @override
  String get voiceWaitingParticipants => 'सहभागींची प्रतीक्षा करत आहे...';

  @override
  String get voiceYou => 'तुम्ही';

  @override
  String get voiceAiAssistant => 'AI सहाय्यक';

  @override
  String get voiceVideoUnavailable => 'व्हिडिओ उपलब्ध नाही';

  @override
  String get voiceSearchNickname => 'टोपणनावाने शोधा...';

  @override
  String get voiceTranscriptionWord => 'लिप्यंतरण';

  @override
  String get voiceRecordingWord => 'रेकॉर्डिंग';

  @override
  String get voiceConnecting => 'जोडत आहे...';

  @override
  String get voiceVideoBackground => 'व्हिडिओ पार्श्वभूमी';

  @override
  String get voiceCallSettings => 'कॉल सेटिंग्ज';

  @override
  String get voiceEnableAI => 'AI सहाय्यक सक्षम करा';

  @override
  String get voiceAIParticipating => 'AI संभाषणात सहभागी होईल';

  @override
  String get voiceNormalCall => 'AI शिवाय सामान्य कॉल';

  @override
  String get voiceCallConfirm => 'कॉल करायचा आहे?';

  @override
  String get chatAlreadyInCall => 'आधीच कॉलमध्ये आहे';

  @override
  String chatCallError(String error) {
    return 'कॉल त्रुटी: $error';
  }

  @override
  String get chatPhotoVideo => 'फोटो / व्हिडिओ';

  @override
  String get chatCamera => 'कॅमेरा';

  @override
  String get chatFile => 'फाइल';

  @override
  String get chatContact => 'संपर्क';

  @override
  String get chatSelectContact => 'संपर्क निवडा';

  @override
  String get chatNoContacts => 'कोणतेही संपर्क नाहीत';

  @override
  String get chatUser => 'वापरकर्ता';

  @override
  String get chatFileAttachment => '📎 फाइल';

  @override
  String chatFileUploadError(String error) {
    return 'फाइल अपलोड त्रुटी: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 व्हॉइस मेसेज';

  @override
  String get chatGroup => 'गट';

  @override
  String get chatDialog => 'संवाद';

  @override
  String get chatCall => 'कॉल';

  @override
  String get chatStartConversation => 'संभाषण सुरू करा';

  @override
  String get chatYou => 'तुम्ही';

  @override
  String get chatIsTyping => 'टाइप करत आहे...';

  @override
  String chatUserIsTyping(String name) {
    return '$name टाइप करत आहे...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names टाइप करत आहेत...';
  }

  @override
  String get chatPreparingFile => 'फाइल तयार करत आहे…';

  @override
  String chatUploading(int progress) {
    return 'अपलोड करत आहे… $progress%';
  }

  @override
  String get chatEdited => 'संपादित';

  @override
  String get chatViaMesh => 'मेशद्वारे';

  @override
  String get chatReply => 'उत्तर द्या';

  @override
  String get chatEdit => 'संपादन करा';

  @override
  String get chatCopy => 'कॉपी करा';

  @override
  String get chatCopied => 'कॉपी केले';

  @override
  String get chatSaveMedia => 'जतन करा';

  @override
  String get chatForward => 'फॉरवर्ड करा';

  @override
  String get chatSaving => 'जतन करत आहे...';

  @override
  String get chatSavedToGallery => 'गॅलरीत जतन केले';

  @override
  String get chatNoSavePermission =>
      'जतन करण्याची परवानगी नाही. सेटिंग्ज तपासा.';

  @override
  String get chatFileSaveError => 'फाइल जतन त्रुटी';

  @override
  String get chatDeleteMessage => 'संदेश हटवा';

  @override
  String get chatDeleteForMe => 'माझ्यासाठी हटवा';

  @override
  String get chatDeleteForEveryone => 'सर्वांसाठी हटवा';

  @override
  String get chatMessageForwarded => 'संदेश फॉरवर्ड केला';

  @override
  String get chatContactTapToOpen => 'संपर्क · उघडण्यासाठी टॅप करा';

  @override
  String get chatForwardTo => 'याला फॉरवर्ड करा...';

  @override
  String get chatSearchHint => 'शोधा...';

  @override
  String get chatRecording => 'रेकॉर्डिंग...';

  @override
  String get chatMessageHint => 'संदेश...';

  @override
  String get chatHideKeyboard => 'कीबोर्ड लपवा';

  @override
  String get chatEditing => 'संपादन करत आहे';

  @override
  String get chatFileDownloadError => 'फाइल डाउनलोड त्रुटी';

  @override
  String get chatVoiceMessageShort => 'व्हॉइस संदेश';

  @override
  String get chatVideoSavedToGallery => 'व्हिडिओ गॅलरीत जतन केला';

  @override
  String get chatSavingError => 'जतन त्रुटी';

  @override
  String get convSetNickname => 'टोपणनाव सेट करा';

  @override
  String get convNicknameRequired =>
      'मेसेंजर वापरण्यासाठी टोपणनाव आवश्यक आहे. इतर वापरकर्ते तुम्हाला त्याद्वारे शोधू शकतात.';

  @override
  String get convNicknameRules => '3–30 अक्षरे: अक्षरे, अंक, _';

  @override
  String get convNicknameTaken => 'टोपणनाव आधीच घेतलेले आहे';

  @override
  String get convSaveError => 'जतन त्रुटी';

  @override
  String get convContactsLabel => 'संपर्क';

  @override
  String get convDefaultUser => 'वापरकर्ता';

  @override
  String get convNoDialogs => 'कोणत्याही संभाषण नाहीत';

  @override
  String get convFindUserToChat => 'गप्पा सुरू करण्यासाठी वापरकर्ता शोधा';

  @override
  String get convDefaultContact => 'संपर्क';

  @override
  String get dashboardUser => 'वापरकर्ता';

  @override
  String get dashboardIncomingCall => 'येणारी कॉल';

  @override
  String get dashboardDecline => 'नकार';

  @override
  String get dashboardAccept => 'स्वीकारा';

  @override
  String get dashboardActiveCall => 'सक्रिय कॉल — परत जाण्यासाठी टॅप करा';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'अपडेट उपलब्ध $version';
  }

  @override
  String get dashboardUpdate => 'अपडेट';

  @override
  String get dashboardWhatsNew => 'नवीन काय आहे';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version मध्ये नवीन काय आहे';
  }

  @override
  String get dashboardInstalling => 'इंस्टॉल करत आहे...';

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
  String get messengerContactRequestsSection => 'संपर्क विनंत्या';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नवीन विनंत्या',
      one: '1 नवीन विनंती',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'शोधा';

  @override
  String get contactRequestsIncoming => 'येणारे';

  @override
  String get contactRequestsSent => 'पाठविलेले';

  @override
  String get contactRequestsSearchHint => 'निकनेम किंवा ईमेल';

  @override
  String get contactRequestSent => 'विनंती पाठविली';

  @override
  String get contactRequestsNoUsers => 'कोणतेही वापरकर्ते सापडले नाहीत';

  @override
  String get contactRequestsSearchHelp =>
      'अचूक निकनेम किंवा ईमेल प्रविष्ट करा\nआणि शोधा दाबा';

  @override
  String get contactRequestsSendTooltip => 'विनंती पाठवा';

  @override
  String get contactRequestTitle => 'संपर्क विनंती';

  @override
  String contactRequestConfirm(String name) {
    return '$name ला संपर्क विनंती पाठवायची आहे का?';
  }

  @override
  String get contactRequestSend => 'पाठवा';

  @override
  String get contactRequestsNoIncoming => 'कोणत्याही येणाऱ्या विनंत्या नाहीत';

  @override
  String get contactRequestsNoSent => 'कोणत्याही पाठविलेल्या विनंत्या नाहीत';

  @override
  String get contactRequestStatusPending => 'प्रतिसादाची प्रतीक्षा';

  @override
  String get contactRequestStatusAccepted => 'स्वीकारले';

  @override
  String get contactRequestStatusRejected => 'नाकारले';

  @override
  String get userSearchTitle => 'वापरकर्ता शोधा';

  @override
  String get userSearchHint => 'निकनेम, फोन किंवा ईमेल';

  @override
  String get userSearchHelper =>
      '@nickname, ईमेल किंवा नाव प्रविष्ट करा शोधण्यासाठी';

  @override
  String get userSearchNoUsers => 'कोणतेही वापरकर्ते सापडले नाहीत';

  @override
  String get userProfileShareContact => 'संपर्क शेअर करा';

  @override
  String get userProfileShareContactDesc => 'संपर्क लिंक पाठवा';

  @override
  String get userProfileCopyLink => 'लिंक कॉपी करा';

  @override
  String get userProfileCopied => 'कॉपी केले';

  @override
  String get userProfileTitle => 'प्रोफाइल';

  @override
  String get userProfileLoadError => 'प्रोफाइल लोड त्रुटी';

  @override
  String get userProfileMessage => 'संदेश';

  @override
  String get userProfileCall => 'कॉल';

  @override
  String get userProfileRequestSent => 'विनंती पाठवली';

  @override
  String get userProfileAccept => 'स्वीकारा';

  @override
  String get userProfileDecline => 'नकारा';

  @override
  String get userProfileAddToContacts => 'संपर्कांमध्ये जोडा';

  @override
  String get userProfileMediaTab => 'मीडिया';

  @override
  String get userProfileFilesTab => 'फाइल्स';

  @override
  String get userProfileLinksTab => 'लिंक्स';

  @override
  String get userProfileRecordingsTab => 'रेकॉर्डिंग्ज';

  @override
  String get userProfileSummariesTab => 'सारांश';

  @override
  String get userProfileNoMedia => 'मीडिया फाइल्स नाहीत';

  @override
  String get userProfileNoFiles => 'फाइल्स नाहीत';

  @override
  String get userProfileNoLinks => 'लिंक्स नाहीत';

  @override
  String get userProfileNoRecordings => 'रेकॉर्डिंग्ज नाहीत';

  @override
  String get userProfileNoSummaries => 'सारांश नाहीत';

  @override
  String get userProfileMeetingSummary => 'बैठकीचा सारांश';

  @override
  String get userProfileFailedOpenChat => 'चॅट उघडण्यात अयशस्वी';

  @override
  String get sharedMediaTitle => 'मीडिया आणि फाइल्स';

  @override
  String get sharedMediaTab => 'मीडिया';

  @override
  String get sharedFilesTab => 'फाइल्स';

  @override
  String get sharedLinksTab => 'लिंक्स';

  @override
  String get sharedNoMedia => 'मीडिया फाइल्स नाहीत';

  @override
  String get sharedNoFiles => 'फाइल्स नाहीत';

  @override
  String get sharedNoLinks => 'लिंक्स नाहीत';

  @override
  String get shareToChat => 'चॅटला फॉरवर्ड करा';

  @override
  String get shareSelectChat => 'चॅट निवडा';

  @override
  String get shareNoChats => 'चॅट्स नाहीत';

  @override
  String shareFilesCount(int count) {
    return '$count फाइल्स';
  }

  @override
  String get contactsTitle => 'संपर्क';

  @override
  String get contactsAddTooltip => 'संपर्क जोडा';

  @override
  String get contactsSearchHint => 'संपर्क शोधा...';

  @override
  String get contactsNotFound => 'काहीही सापडले नाही';

  @override
  String get contactsEmpty => 'संपर्क नाहीत';

  @override
  String get contactsAdd => 'संपर्क जोडा';

  @override
  String get contactsPendingConfirmation => 'पुष्टीची प्रतीक्षा';

  @override
  String get contactsMessage => 'संदेश';

  @override
  String get contactsCall => 'कॉल';

  @override
  String get contactsResend => 'विनंती पुन्हा पाठवा';

  @override
  String get contactsResendTimeout => '24 तासांनी पुन्हा प्रयत्न करा';

  @override
  String get contactsResent => 'विनंती पुन्हा पाठवली';

  @override
  String get contactsWantsToConnect => 'तुमच्याशी जोडले जाऊ इच्छिते';

  @override
  String get contactsSearchPeople => 'लोक शोधा';

  @override
  String get notesTitle => 'नोट्स';

  @override
  String get notesAssistantSpeaking => 'सहाय्यक बोलत आहे...';

  @override
  String get notesListening => 'ऐकत आहे...';

  @override
  String get notesEmpty => 'कोणत्याही नोट्स नाहीत';

  @override
  String get notesEmptyHint =>
      'डिक्टेशनसाठी मायक्रोफोन दाबा\nकिंवा मॅन्युअल एंट्रीसाठी + दाबा';

  @override
  String get notesDeleteConfirm => 'नोट काढून टाका?';

  @override
  String get notesNew => 'नवीन नोट';

  @override
  String get notesEdit => 'संपादन करा';

  @override
  String get notesTitleHint => 'शीर्षक';

  @override
  String get notesContentHint => 'तुमचे विचार लिहा...';

  @override
  String get calendarTitle => 'कॅलेंडर';

  @override
  String get calendarStop => 'थांबा';

  @override
  String get calendarVoiceInput => 'व्हॉइस इनपुट';

  @override
  String get calendarNewEvent => 'नवीन कार्यक्रम';

  @override
  String get calendarAssistantSpeaking => 'सहाय्यक बोलत आहे...';

  @override
  String get calendarListening => 'ऐकत आहे...';

  @override
  String calendarInvitations(int count) {
    return 'आमंत्रणे ($count)';
  }

  @override
  String get calendarNoEvents => 'कोणतेही कार्यक्रम नाहीत';

  @override
  String get calendarDayMon => 'सोम';

  @override
  String get calendarDayTue => 'मंगळ';

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
  String get calendarEnterRoom => 'खोलीत प्रवेश करा';

  @override
  String get calendarMeeting => 'बैठक';

  @override
  String calendarLocationPrefix(String location) {
    return 'स्थान: $location';
  }

  @override
  String get calendarEditEvent => 'संपादन करा';

  @override
  String get calendarTitleHint => 'शीर्षक';

  @override
  String get calendarDescriptionHint => 'वर्णन';

  @override
  String get calendarTypeEvent => 'कार्यक्रम';

  @override
  String get calendarTypeMeeting => 'बैठक';

  @override
  String get calendarTypeReminder => 'स्मरणपत्र';

  @override
  String get calendarTypeLabel => 'प्रकार';

  @override
  String get calendarMeetingLink => 'बैठकीचा दुवा';

  @override
  String get calendarLocationHint => 'स्थान';

  @override
  String get calendarDateLabel => 'तारीख';

  @override
  String get calendarTimeLabel => 'वेळ';

  @override
  String get calendarReminderLabel => 'स्मरणपत्र';

  @override
  String get calendarReminderNone => 'काहीही नाही';

  @override
  String get calendarReminder15min => '१५ मिनिटे आधी';

  @override
  String get calendarReminder30min => '३० मिनिटे आधी';

  @override
  String get calendarReminder1hour => '१ तास आधी';

  @override
  String get calendarRepeatLabel => 'पुन्हा करा';

  @override
  String get calendarRepeatNone => 'पुन्हा नाही';

  @override
  String get calendarRepeatDaily => 'दररोज';

  @override
  String get calendarRepeatWeekly => 'दर आठवड्याला';

  @override
  String get calendarRepeatMonthly => 'दर महिन्याला';

  @override
  String get calendarRepeatYearly => 'दर वर्षी';

  @override
  String get calendarParticipants => 'सहभागी';

  @override
  String get calendarAddParticipant => 'जोडा';

  @override
  String get calendarSearchContacts => 'संपर्क शोधा...';

  @override
  String get calendarNoContacts => 'संपर्क नाहीत';

  @override
  String get calendarStatusAccepted => 'स्वीकारले';

  @override
  String get calendarStatusDeclined => 'नाकारले';

  @override
  String get calendarStatusMaybe => 'कदाचित';

  @override
  String get calendarStatusPending => 'प्रलंबित';

  @override
  String get calendarEndTime => 'समाप्ती वेळ';

  @override
  String get calendarYourAnswer => 'तुमचे उत्तर:';

  @override
  String get calendarOrganizer => 'आयोजक';

  @override
  String calendarDeleteError(String error) {
    return 'हटविण्यात अयशस्वी: $error';
  }

  @override
  String get calendarRsvpAccept => 'स्वीकारा';

  @override
  String get calendarRsvpMaybe => 'कदाचित';

  @override
  String get calendarRsvpDecline => 'नकारा';

  @override
  String get callHistoryTitle => 'कॉल्स';

  @override
  String get callHistoryTab => 'कॉल इतिहास';

  @override
  String get callHistoryTempMeeting => 'तात्पुरती बैठक';

  @override
  String get callHistoryCopy => 'कॉपी';

  @override
  String get callHistoryLinkCopied => 'लिंक कॉपी केली';

  @override
  String get callHistoryShare => 'शेअर';

  @override
  String get callHistoryEnter => 'प्रवेश करा';

  @override
  String get callHistoryAlreadyInCall => 'आधीच कॉलमध्ये आहे';

  @override
  String get callHistoryCouldNotDeterminePeer => 'दुसरी पार्टी ओळखता आली नाही';

  @override
  String get callHistoryContacts => 'संपर्क';

  @override
  String get callHistoryFailedLoadRoom => 'तुमची खोली लोड करण्यात अयशस्वी';

  @override
  String get callHistoryYourRoom => 'तुमची खोली';

  @override
  String get callHistoryCreateMeeting => 'बैठक तयार करा';

  @override
  String get callHistoryMeetingSummaries => 'बैठक सारांश';

  @override
  String get callHistoryMeetingRecordings => 'बैठक रेकॉर्डिंग';

  @override
  String get callHistoryNoCalls => 'कोणतेही कॉल नाहीत';

  @override
  String get callHistoryMissed => 'चुकलेले';

  @override
  String get callHistoryRecording => 'रेकॉर्डिंग';

  @override
  String get callHistorySummary => 'सारांश';

  @override
  String get callHistoryCallAgain => 'पुन्हा कॉल करा';

  @override
  String callHistoryTodayTime(String time) {
    return 'आज, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'काल, $time';
  }

  @override
  String get callHistoryUnknown => 'अज्ञात';

  @override
  String get callHistoryDetails => 'कॉल तपशील';

  @override
  String get callHistoryOutgoing => 'बाहेर जाणारा कॉल';

  @override
  String get callHistoryIncoming => 'आत येणारा कॉल';

  @override
  String callHistoryDuration(String duration) {
    return 'कालावधी: $duration';
  }

  @override
  String get callHistoryWithAI => 'AI सहाय्यकासह';

  @override
  String get callHistoryParticipants => 'सहभागी';

  @override
  String get callDetailYouSuffix => '(तुम्ही)';

  @override
  String get callHistoryMeetingSummary => 'बैठक सारांश';

  @override
  String get callHistoryMoreDetails => 'अधिक तपशील';

  @override
  String get callHistorySummaryProcessing => 'सारांश प्रक्रिया...';

  @override
  String get callHistoryMeetingRecording => 'बैठक रेकॉर्डिंग';

  @override
  String get callHistoryProcessing => 'प्रक्रिया...';

  @override
  String get callHistoryCreateTranscript => 'प्रतिलिपी तयार करा';

  @override
  String get callHistoryNoSummaries => 'कोणतेही सारांश नाहीत';

  @override
  String get callHistoryRecordDuringCall => 'कॉल दरम्यान \"रेकॉर्ड\" दाबा';

  @override
  String callHistoryMeetingTime(String time) {
    return 'बैठक $time';
  }

  @override
  String get callHistoryTranscribing =>
      'प्रतिलिपीकरण आणि सारांश तयार करीत आहे...';

  @override
  String get callHistoryTranscriptCreated => 'प्रतिलिपी तयार झाली';

  @override
  String get callHistoryNoRecordings => 'कोणतेही रेकॉर्डिंग नाहीत';

  @override
  String callHistoryRecordingDate(String date) {
    return 'रेकॉर्डिंग $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'रेकॉर्डिंग अनुपलब्ध';

  @override
  String get callHistoryTranscriptReady => 'प्रतिलिपी तयार';

  @override
  String get callHistoryTranscript => 'प्रतिलिपी';

  @override
  String get callHistoryKeyPoints => 'मुख्य मुद्दे';

  @override
  String get callHistoryTasks => 'कार्ये';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'नेमलेले: $assignee';
  }

  @override
  String get callHistoryDecisions => 'निर्णय';

  @override
  String get callHistoryShowTranscript => 'पूर्ण प्रतिलिपी दाखवा';

  @override
  String get profileScanQr => 'QR स्कॅन करा';

  @override
  String get profileMyQrCode => 'माझा QR कोड';

  @override
  String profileAddMeShare(String userId) {
    return 'मला Taler ID मध्ये जोडा!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'तुम्हाला जोडण्यासाठी हा कोड दाखवा';

  @override
  String get profileEditDesc => 'नाव, आडनाव, वडिलांचे नाव, जन्मतारीख';

  @override
  String get profileAboutMe => 'माझ्याबद्दल';

  @override
  String get profileAboutMeDesc => 'मूल्ये, कौशल्ये, आवडी आणि अधिक';

  @override
  String get profileNotes => 'टीप';

  @override
  String get profileNotesDesc => 'विचार, कल्पना आणि टीप';

  @override
  String get profileAvatarUpdated => 'अवतार अद्ययावत केला';

  @override
  String get profileNickname => 'टोपणनाव';

  @override
  String get profileNotSet => 'सेट केलेले नाही';

  @override
  String get profileChangeNickname => 'टोपणनाव बदला';

  @override
  String get profileNicknameUpdated => 'टोपणनाव अद्ययावत केले';

  @override
  String get profileShareLabel => 'शेअर करा';

  @override
  String get profileScanQrCode => 'QR कोड स्कॅन करा';

  @override
  String get profilePointCamera => 'QR कोडकडे कॅमेरा दाखवा';

  @override
  String get profilePhotoCamera => 'फोटो काढा';

  @override
  String get profilePhotoGallery => 'गॅलरीमधून निवडा';

  @override
  String get editProfilePatronymic => 'वडिलांचे नाव (पर्यायी)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'माझ्याबद्दल';

  @override
  String get aboutMeClickToFill => 'भरण्यासाठी क्लिक करा';

  @override
  String get aboutMeCoreValues => 'मूल्ये';

  @override
  String get aboutMeWorldview => 'जगदृष्टी';

  @override
  String get aboutMeSkills => 'कौशल्ये';

  @override
  String get aboutMeInterests => 'आवडी';

  @override
  String get aboutMeDesires => 'इच्छा';

  @override
  String get aboutMeBackground => 'प्रोफाइल';

  @override
  String get aboutMeLikes => 'आवडी';

  @override
  String get aboutMeDislikes => 'नावडी';

  @override
  String get aboutMeDeleteSection => 'विभाग हटवायचा?';

  @override
  String get aboutMeDeleteConfirm => 'या विभागातील सर्व डेटा हटविला जाईल.';

  @override
  String aboutMeConnectionError(String error) {
    return 'कनेक्शन त्रुटी: $error';
  }

  @override
  String get aboutMeVisibility => 'दृश्यता';

  @override
  String get aboutMeTags => 'टॅग';

  @override
  String get aboutMeAddTag => 'टॅग जोडा...';

  @override
  String get aboutMeDescription => 'वर्णन';

  @override
  String get aboutMeDescribeLong => 'आम्हाला अधिक सांगा...';

  @override
  String get aboutMeVisibilityEveryone => 'सर्वांना';

  @override
  String get aboutMeVisibilityContacts => 'संपर्क';

  @override
  String get aboutMeVisibilityOnlyMe => 'फक्त मी';

  @override
  String get settingsProfileSubtitle => 'प्रोफाइल';

  @override
  String get settingsWallpaper => 'वॉलपेपर';

  @override
  String get settingsWallpaperDesc => 'संपूर्ण अॅपसाठी पार्श्वभूमी प्रतिमा';

  @override
  String get settingsWallpaperNone => 'काहीही नाही';

  @override
  String get settingsAccount => 'खाते';

  @override
  String get settingsKycVerification => 'ओळख पडताळणी (KYC)';

  @override
  String get settingsOrganizations => 'संस्था';

  @override
  String get incomingCallLabel => 'आगामी कॉल';

  @override
  String get incomingCallDecline => 'नकार';

  @override
  String get incomingCallAccept => 'स्वीकारा';

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
  String get meshIncomingCallLabel => '📡 मेष कॉल येत आहे';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'मेष उपकरण $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'सध्याचा कॉल आधी संपवा';

  @override
  String get callPopupTransportTitle => 'कॉल द्वारे';

  @override
  String get callPopupTransportMesh => '📡 मेष (पीअर-टू-पीअर)';

  @override
  String get callPopupTransportLk => '📞 सर्व्हर';

  @override
  String get callPopupTransportMeshUnavailable =>
      'मेषद्वारे संपर्क साधता येत नाही';

  @override
  String get meshOnboardingTitle => '📡 मेष कॉलसाठी अॅप उघडे ठेवा';

  @override
  String get meshOnboardingBody =>
      'फोन लॉक असताना, मेष कॉल ~30 सेकंदांनंतर बंद होऊ शकतात (iOS मर्यादा).';

  @override
  String get meshOnboardingAck => 'समजले';

  @override
  String get meshHistoryBadge => '📡 मेष';

  @override
  String get meshHistoryNoChatAvailable => 'संपर्क तुमच्या यादीत नाही';

  @override
  String get meshCallStatusInviting => 'कॉल करत आहे…';

  @override
  String get meshCallStatusConnecting => 'जोडत आहे…';

  @override
  String get meshCallEndedUserHangup => 'कॉल संपला';

  @override
  String get meshCallEndedRemoteHangup => 'पीअरने संपवला';

  @override
  String get meshCallEndedRejected => 'नाकारले';

  @override
  String get meshCallEndedNoAnswer => 'उत्तर नाही';

  @override
  String get meshCallEndedConnectionLost => 'कनेक्शन हरवले';

  @override
  String get meshCallEndedError => 'कनेक्शन त्रुटी';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 मेष · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 मेष';

  @override
  String get batteryExemptionTitle => '📡 विश्वासार्ह मेष कॉल';

  @override
  String get batteryExemptionBody =>
      'अॅपला बॅटरी निर्बंधांशिवाय चालू ठेवण्यासाठी परवानगी द्या, जेणेकरून Android पार्श्वभूमीत मेष बंद करणार नाही.';

  @override
  String get batteryExemptionAccept => 'सेटिंग्ज उघडा';

  @override
  String get batteryExemptionDismiss => 'आता नाही';

  @override
  String get groupCamera => 'कॅमेरा';

  @override
  String get groupGallery => 'गॅलरी';

  @override
  String get groupAvatarUpdated => 'गटाचा अवतार अद्यतनित केला';

  @override
  String get groupNameTitle => 'गटाचे नाव';

  @override
  String get groupEnterName => 'नाव प्रविष्ट करा';

  @override
  String get groupDescriptionTitle => 'गटाचे वर्णन';

  @override
  String get groupEnterDescription => 'गटाचे वर्णन प्रविष्ट करा';

  @override
  String get groupChangeRoleTitle => 'भूमिका बदला';

  @override
  String get groupRemoveMemberTitle => 'सदस्य काढा';

  @override
  String get groupDescription => 'वर्णन';

  @override
  String get groupAddDescription => 'गटाचे वर्णन जोडा';

  @override
  String get groupNoDescription => 'वर्णन नाही';

  @override
  String get groupMediaAndFiles => 'मीडिया आणि फाइल्स';

  @override
  String get groupMuteNotifications => 'सूचना म्यूट करा';

  @override
  String get groupMuted => 'म्यूट केले';

  @override
  String get groupNoResults => 'निकाल नाहीत';

  @override
  String get authInvalidCode => 'अवैध कोड. पुन्हा प्रयत्न करा.';

  @override
  String get loginSubtitle => 'ईमेल आणि पासवर्ड वापरा';

  @override
  String get emailRequired => 'ईमेल प्रविष्ट करा';

  @override
  String get emailInvalid => 'अवैध ईमेल';

  @override
  String get passwordRequired => 'पासवर्ड प्रविष्ट करा';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'संपूर्ण Taler पर्यावरणासाठी एक खाते';

  @override
  String get usernameOptional => 'वापरकर्तानाव (ऐच्छिक)';

  @override
  String get usernameMinLength => 'किमान 3 अक्षरे';

  @override
  String get usernameMaxLength => 'कमाल 30 अक्षरे';

  @override
  String get usernameInvalid => 'फक्त अक्षरे, अंक आणि _';

  @override
  String get biometricLoginReason => 'Taler ID मध्ये साइन इन करा';

  @override
  String get docTypePassport => 'पासपोर्ट';

  @override
  String get docTypeIdCard => 'ओळखपत्र';

  @override
  String get docTypeDriverLicense => 'ड्रायव्हरचा परवाना';

  @override
  String get docTypeResidencePermit => 'निवास परवाना';

  @override
  String addressApartment(String number) {
    return 'अपार्टमेंट $number';
  }

  @override
  String get failedToUpdateProfile => 'प्रोफाइल अद्यतनित करण्यात अयशस्वी';

  @override
  String get failedToStartKyb => 'KYB पडताळणी सुरू करण्यात अयशस्वी';

  @override
  String get orgUpdated => 'संस्था अद्यतनित केली';

  @override
  String get failedToUpdateOrg => 'संस्था अद्यतनित करण्यात अयशस्वी';

  @override
  String get failedToChangeRole => 'भूमिका बदलण्यात अयशस्वी';

  @override
  String get failedToRemoveMember => 'सदस्य काढण्यात अयशस्वी';

  @override
  String get capabilityMessagesTitle => 'संदेश';

  @override
  String get capabilityMessagesDesc =>
      'संदेश तपासा किंवा कोणाला लिहा. उदाहरणार्थ: \"विक्टरला लिहा: एक तासात तिथे येईन\"';

  @override
  String get capabilityCallsTitle => 'कॉल्स';

  @override
  String get capabilityCallsDesc =>
      'कोणत्याही संपर्काला आवाजाने कॉल करा. उदाहरणार्थ: \"विक्टर विक्टरोवला कॉल करा\"';

  @override
  String get capabilityChatTitle => 'चॅट इतिहास';

  @override
  String get capabilityChatDesc =>
      'मी चॅट इतिहासाचे विश्लेषण करेन. उदाहरणार्थ: \"आपण विक्टरसोबत काय चर्चा केली?\"';

  @override
  String get capabilityProfileTitle => 'प्रोफाइल';

  @override
  String get capabilityProfileDesc =>
      'मी तुमचे प्रोफाइल दाखवेन किंवा अद्यतनित करेन. उदाहरणार्थ: \"माझे प्रोफाइल दाखवा\"';

  @override
  String get capabilityCoachingTitle => 'कोचिंग';

  @override
  String get capabilityCoachingDesc =>
      'मोड्स: ICF कोचिंग, मानसशास्त्रज्ञ, HR सल्ला. बोला: \"कोचिंग करूया\"';

  @override
  String get capabilityCalendarTitle => 'कॅलेंडर';

  @override
  String get capabilityCalendarDesc =>
      'बैठक ठरवा किंवा स्मरणपत्र सेट करा. उदाहरणार्थ: \"उद्या 15:00 वाजता विक्टरसोबत बैठक ठरवा\"';

  @override
  String get capabilityNotesTitle => 'नोट्स';

  @override
  String get capabilityNotesDesc =>
      'विचार जतन करा किंवा अलीकडील नोट्स वाचा. उदाहरणार्थ: \"एक कल्पना लिहा...\" किंवा \"अलीकडील नोट्स वाचा\"';

  @override
  String get assistantCallConfirm => 'कॉल करायचा?';

  @override
  String get callNoAnswer => 'उत्तर नाही';

  @override
  String get contactDelete => 'संपर्क काढा';

  @override
  String get contactDeleteTitle => 'संपर्क काढा';

  @override
  String get contactDeleteConfirm =>
      'तुम्हाला खात्री आहे? हा संपर्क काढला जाईल.';

  @override
  String get contactBlock => 'ब्लॉक करा';

  @override
  String get contactBlockTitle => 'वापरकर्ता ब्लॉक करा';

  @override
  String get contactBlockConfirm =>
      'हा वापरकर्ता तुम्हाला संदेश किंवा कॉल करू शकणार नाही.';

  @override
  String get contactUnblock => 'अनब्लॉक करा';

  @override
  String get contactBlocked => 'ब्लॉक केलेले';

  @override
  String get contactYouAreBlocked => 'या वापरकर्त्याने तुम्हाला ब्लॉक केले आहे';

  @override
  String get chatBlockedByYou => 'तुम्ही या वापरकर्त्याला ब्लॉक केले आहे';

  @override
  String get chatYouAreBlocked => 'तुम्हाला या वापरकर्त्याने ब्लॉक केले आहे';

  @override
  String get chatNotContacts =>
      'संदेश पाठवण्यासाठी या वापरकर्त्याला संपर्कांमध्ये जोडा';

  @override
  String get contactRevokeRequest => 'विनंती मागे घ्या';

  @override
  String get messengerPoll => 'मतदान';

  @override
  String get messengerCreatePoll => 'मतदान तयार करा';

  @override
  String get messengerPollQuestion => 'प्रश्न';

  @override
  String messengerPollOption(int number) {
    return 'पर्याय $number';
  }

  @override
  String get messengerPollAddOption => 'पर्याय जोडा';

  @override
  String get messengerPollAnonymous => 'अनामिक मतदान';

  @override
  String get messengerPollMultiple => 'अनेक पर्याय';

  @override
  String get messengerPollCreateError => 'मतदान तयार करण्यात अयशस्वी';

  @override
  String get messengerPollUnavailable => 'मतदान उपलब्ध नाही';

  @override
  String get messengerPollMultipleNote => 'तुम्ही अनेक निवड करू शकता';

  @override
  String messengerPollVotes(int count) {
    return '$count मते';
  }

  @override
  String get messengerVideoMessage => 'व्हिडिओ संदेश';

  @override
  String get messengerVideoRecordError => 'व्हिडिओ रेकॉर्डिंग त्रुटी';

  @override
  String get messengerVideoPlaybackError => 'व्हिडिओ प्ले करू शकलो नाही';

  @override
  String get messengerGalleryAccessError => 'गॅलरीसाठी प्रवेश नाही';

  @override
  String get messengerSearchInChat => 'चॅटमध्ये शोधा...';

  @override
  String get messengerSaveToFavorites => 'आवडीमध्ये जतन करा';

  @override
  String get messengerSavedToFavorites => 'आवडीमध्ये जतन केले';

  @override
  String get messengerSearchInMessages => 'संदेशांमध्ये शोधा...';

  @override
  String messengerFoundInMessages(int count) {
    return 'संदेशांमध्ये सापडले ($count)';
  }

  @override
  String get messengerGroupDefault => 'गट';

  @override
  String get messengerUserDefault => 'वापरकर्ता';

  @override
  String get messengerPin => 'पिन';

  @override
  String get messengerUnpin => 'अनपिन';

  @override
  String get messengerArchive => 'संग्रहित करा';

  @override
  String get messengerUnarchive => 'संग्रहातून काढा';

  @override
  String get messengerDeleteChat => 'चॅट हटवा';

  @override
  String get messengerDeleteChatTitle => 'चॅट हटवायचे?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '$name सोबतचा चॅट हटवायचा? हे पूर्ववत करता येणार नाही.';
  }

  @override
  String get messengerCreateChannel => 'चॅनेल तयार करा';

  @override
  String get messengerChannelName => 'नाव';

  @override
  String get messengerChannelDescription => 'वर्णन (ऐच्छिक)';

  @override
  String get messengerChannelCreateError => 'चॅनेल तयार करण्यात अयशस्वी';

  @override
  String get messengerFilterAll => 'सर्व';

  @override
  String get messengerFilterUnread => 'न वाचलेले';

  @override
  String get messengerFilterPersonal => 'वैयक्तिक';

  @override
  String get messengerFilterGroups => 'गट';

  @override
  String get messengerFilterChannels => 'चॅनेल';

  @override
  String get messengerArchivedSection => 'संग्रहित';

  @override
  String get messengerSavedSection => 'आवडी';

  @override
  String get messengerSavedSubtitle => 'स्मृतीत जतन करा';

  @override
  String messengerArchiveTitle(int count) {
    return 'संग्रहित ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'संग्रह रिकामा आहे';

  @override
  String messengerYouPrefix(String message) {
    return 'तुम्ही: $message';
  }

  @override
  String get messengerMissedCall => 'चुकलेला कॉल';

  @override
  String get messengerSavedTitle => 'आवडी';

  @override
  String get messengerNoSavedMessages => 'जतन केलेले संदेश नाहीत';

  @override
  String get messengerSavedHint => 'संदेशावर लांब दाबा → \"आवडीमध्ये जतन करा\"';

  @override
  String get messengerDefaultFile => 'फाइल';

  @override
  String get messengerTopicDefault => 'सामान्य';

  @override
  String get messengerTopicNew => 'नवीन विषय';

  @override
  String get messengerTopicNameHint => 'विषयाचे नाव';

  @override
  String get messengerTopicIcon => 'आयकॉन';

  @override
  String messengerTopicCount(int count) {
    return '$count विषय';
  }

  @override
  String get messengerNoTopics => 'विषय नाहीत';

  @override
  String get messengerNoMessages => 'कोणतेही संदेश नाहीत';

  @override
  String get you => 'तुम्ही';

  @override
  String get messengerThread => 'थ्रेड';

  @override
  String get messengerThreadReply => 'उत्तर';

  @override
  String get messengerThreadReplies => 'उत्तरे';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'कोणतीही उत्तरे नाहीत';

  @override
  String get messengerReplyHint => 'थ्रेडला उत्तर द्या...';

  @override
  String get messengerContactName => 'संपर्क नाव';

  @override
  String messengerOriginalName(String name) {
    return 'मूळ नाव: $name';
  }

  @override
  String get messengerDisplayName => 'प्रदर्शन नाव';

  @override
  String messengerShareContact(String name) {
    return 'Taler ID मध्ये संपर्क: $name';
  }

  @override
  String get messengerAutoDelete => 'संदेश आपोआप हटवा';

  @override
  String get messengerAutoDeleteOff => 'बंद';

  @override
  String get messengerAutoDelete7d => '7 दिवस';

  @override
  String get messengerAutoDelete30d => '30 दिवस';

  @override
  String get messengerAutoDelete90d => '90 दिवस';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count दिवस';
  }

  @override
  String get messengerSettingsHeader => 'सेटिंग्ज';

  @override
  String get messengerAdminOnly => 'फक्त प्रशासक पोस्ट करू शकतो';

  @override
  String get messengerAdminOnlyDesc => 'सदस्य फक्त वाचू शकतात';

  @override
  String get messengerTopics => 'विषय';

  @override
  String get messengerTopicsDesc => 'चॅटला विषयांमध्ये विभाजित करा';

  @override
  String get aiTwinSection => 'AI व्हॉइस ट्विन';

  @override
  String get aiTwinEnabled => 'AI ट्विन सक्षम करा';

  @override
  String get aiTwinEnabledDesc =>
      'जर तुम्ही उत्तर दिले नाही तर, तुमचा AI ट्विन तुमच्या आवाजात कॉल घेईल';

  @override
  String get aiTwinTimeout => 'प्रतिसाद वेळमर्यादा';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds सेकंद';
  }

  @override
  String get aiTwinPrompt => 'AI सूचना';

  @override
  String get aiTwinPromptSubtitle =>
      'AI ट्विनने स्वतःची ओळख कशी करून द्यावी आणि कोणत्या विषयावर बोलावे';

  @override
  String aiTwinPromptHint(String name) {
    return 'नमस्कार, हा $name चा AI व्हॉइस ट्विन आहे. $name सध्या कॉल घेऊ शकत नाही. मला सांगा कोण बोलत आहे आणि कोणत्या विषयावर — मी ते पुढे देईन.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'कस्टम व्हॉइस क्लोनिंग लवकरच येत आहे. सध्या AI $name च्या आवाजात बोलतो.';
  }

  @override
  String get aiTwinDefaultName => 'मालक';

  @override
  String get aiTwinPromptReset => 'रीसेट';

  @override
  String get callHistoryAiTwinAnswered => 'AI ट्विनने उत्तर दिले';

  @override
  String get callHistoryAiTwinSummary => 'कॉल सारांश';

  @override
  String get callHistoryAiTwinTranscript => 'प्रतिलिपी';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '$name कडून';
  }

  @override
  String get aiTwinOfferTitle => 'उत्तर देत नाही';

  @override
  String aiTwinOfferBody(String name) {
    return '$name फोन उचलत नाहीत. त्यांच्या AI आवाज जुळवणीसह संदेश सोडायचा?';
  }

  @override
  String get aiTwinOfferBodyUser => 'वापरकर्ता';

  @override
  String get aiTwinOfferAccept => 'होय, संदेश सोडा';

  @override
  String get aiTwinOfferKeepWaiting => 'प्रतीक्षा करत रहा';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'तुमचा AI प्रतिनिधी';

  @override
  String get aiTwinHeroSubtitle =>
      'जेव्हा तुम्ही नाही तेव्हा तुमच्या आवाजात कॉल्सला उत्तर देते.';

  @override
  String get aiTwinProfileTitle => 'AI प्रतिनिधी';

  @override
  String get aiTwinProfileDesc => 'तुमच्या आवाजात कॉल्सला उत्तर देते';

  @override
  String get aiTwinBadgeOn => 'चालू';

  @override
  String get aiAnalystTitle => 'AI विश्लेषक';

  @override
  String get aiAnalystSubtitle => 'फाइल्स, कार्ये, विश्लेषण — Claude';

  @override
  String get channelsDiscover => 'चॅनेल शोधा';

  @override
  String get channelsSearchHint => 'चॅनेल शोधा';

  @override
  String get channelsSubscribers => 'सदस्य';

  @override
  String get channelsSubscribe => 'सदस्यता घ्या';

  @override
  String get channelsUnsubscribe => 'सदस्यता रद्द करा';

  @override
  String get channelsSubscribedLabel => 'तुम्ही सदस्य आहात';

  @override
  String get channelsSettings => 'चॅनेल सेटिंग्ज';

  @override
  String get channelsDelete => 'चॅनेल हटवा';

  @override
  String get channelsDeleteConfirm => 'चॅनेल कायमचे हटवायचे?';

  @override
  String get channelsEmpty => 'अद्याप कोणतेही चॅनेल नाहीत';

  @override
  String get channelsOpen => 'उघडा';

  @override
  String get channelsNameLabel => 'नाव';

  @override
  String get channelsDescriptionLabel => 'वर्णन';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'मालक सदस्यता रद्द करू शकत नाहीत. त्याऐवजी चॅनेल हटवा.';

  @override
  String get channelsNotFoundRedirect => 'चॅनेल आता अस्तित्वात नाही';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शोध',
      one: '$count शोध',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फाइल्स',
      one: '$count फाइल',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आदेश',
      one: '$count आदेश',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्रतिमा',
      one: '$count प्रतिमा',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पावले',
      one: '$count पाऊल',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$secondsसे';
  }

  @override
  String get savedTitle => 'जतन केलेले संदेश';

  @override
  String get savedSubtitle => 'तुमचे खाजगी क्लाउड';

  @override
  String get savedOpenError => 'जतन केलेले संदेश उघडू शकले नाहीत';

  @override
  String get billingWalletTitle => 'वॉलेट';

  @override
  String get billingBuyPackage => 'पॅकेज खरेदी करा';

  @override
  String get billingCurrentBalance => 'सध्याची शिल्लक';

  @override
  String get billingPackagesTitle => 'पॅकेजेस';

  @override
  String get billingPackagesUnavailable => 'पॅकेजेस उपलब्ध नाहीत';

  @override
  String get billingRecentOperations => 'अलीकडील व्यवहार';

  @override
  String get billingAllOperations => 'सर्व व्यवहार';

  @override
  String get billingNoOperations => 'कोणतेही व्यवहार नाहीत';

  @override
  String get billingOperationsTitle => 'व्यवहार';

  @override
  String get billingOperationsEmptyTitle => 'अजून कोणतेही व्यवहार नाहीत';

  @override
  String get billingOperationsEmptySubtitle =>
      'AI वैशिष्ट्यांसाठी टॉप-अप आणि शुल्क येथे दिसतील';

  @override
  String get billingPricebookTitle => 'वैशिष्ट्यांचे दर';

  @override
  String get billingPricebookUnavailable => 'दर सूची उपलब्ध नाही';

  @override
  String get billingAiFeaturesTitle => 'AI वैशिष्ट्ये';

  @override
  String get billingInsufficientFundsTitle => 'अपुरे निधी';

  @override
  String get billingInsufficientFundsSubtitle =>
      'हे वैशिष्ट्य वापरण्यासाठी तुमचा शिल्लक रक्कम भरा.';

  @override
  String billingRequiredLine(String required) {
    return 'आवश्यक: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'उपलब्ध: $available μTAL';
  }

  @override
  String get billingTopUp => 'शिल्लक भरा';

  @override
  String get billingCancel => 'रद्द करा';

  @override
  String get billingRetry => 'पुन्हा प्रयत्न करा';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'शिल्लक कमी आहे: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'वॉलेट आणि शिल्लक';

  @override
  String get billingSectionHeader => 'बिलिंग आणि AI';

  @override
  String get billingFeatureVoiceAssistant => 'व्हॉइस असिस्टंट';

  @override
  String get billingFeatureWebSearch => 'असिस्टंट वेब शोध';

  @override
  String get billingFeatureAiTwin => 'व्हॉइस ट्विन';

  @override
  String get billingFeatureAiTwinLong => 'व्हॉइस ट्विन (AI ट्विन)';

  @override
  String get billingFeatureOutboundCall => 'आउटबाउंड बॉट';

  @override
  String get billingFeatureOutboundCallLong => 'आउटबाउंड कॉलिंग बॉट';

  @override
  String get billingFeatureWhisperTranscribe => 'कॉल ट्रान्सक्रिप्शन';

  @override
  String get billingFeatureMeetingSummary => 'AI कॉल सारांश';

  @override
  String get billingConfigureAiTwin => 'AI ट्विन कॉन्फिगर करा';

  @override
  String get billingWebSearchSubtitle => '(असिस्टंटद्वारे वापरले जाते)';

  @override
  String billingPackagePurchased(String balance) {
    return 'पॅकेज खरेदी केले: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'शिफारस केलेले';

  @override
  String get billingSessionTerminatedNoFunds => 'शिल्लक संपली — सत्र समाप्त';

  @override
  String get billingSessionTerminatedGeneric => 'असिस्टंट सत्र समाप्त';

  @override
  String billingBuyForPrice(String price) {
    return '€$price साठी खरेदी करा';
  }

  @override
  String get billingTxTypeTopup => 'टॉप-अप';

  @override
  String get billingTxTypeRefund => 'परतावा';

  @override
  String get billingTxTypeSpend => 'शुल्क';

  @override
  String get billingUnitMinute => 'मिनिट';

  @override
  String get billingUnitRequest => 'विनंती';

  @override
  String get billingUnitToken => 'टोकन';

  @override
  String get billingUnitTokens1k => '1K टोकन्स';

  @override
  String get billingUnitCall => 'कॉल';

  @override
  String get groupCallSelectParticipants => 'सहभागी निवडा';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'शोधा';

  @override
  String get groupCallMaxReached => 'कमाल 7 सहभागी';

  @override
  String get groupCallLobbyTitle => 'गट • लॉबी';

  @override
  String groupCallHostLabel(String name) {
    return 'होस्ट: $name';
  }

  @override
  String get groupCallMicHint => 'कनेक्ट झाल्यावर माइक सक्रिय होईल';

  @override
  String get groupCallCancel => 'रद्द करा';

  @override
  String get groupCallNoAnswer => 'कोणीही उत्तर दिले नाही';

  @override
  String get groupCallEndedByHost => 'होस्टने कॉल समाप्त केला';

  @override
  String get groupCallAllLeft => 'सर्वांनी कॉल सोडला';

  @override
  String get groupCallEnded => 'कॉल समाप्त';

  @override
  String groupCallActiveTitle(int count) {
    return 'गट • $count';
  }

  @override
  String get groupCallConnectionLost => 'कनेक्शन गमावले';

  @override
  String get groupCallMuteRequested =>
      'होस्टने सर्वांना म्यूट करण्यास सांगितले';

  @override
  String get groupCallUnmute => 'अनम्यूट';

  @override
  String get groupCallMute => 'म्यूट';

  @override
  String get groupCallMuteAll => 'सर्वांना म्यूट करा';

  @override
  String get groupCallLeave => 'सोडा';

  @override
  String get groupCallStatusCalling => 'कॉल करत आहे…';

  @override
  String get groupCallStatusDeclined => 'नाकारले';

  @override
  String get groupCallStatusTimeout => 'उत्तर नाही';

  @override
  String get groupCallStatusLeft => 'सोडले';

  @override
  String groupCallKickConfirm(String name) {
    return '$name ला कॉलमधून काढा';
  }

  @override
  String get groupCallCancelAction => 'रद्द करा';

  @override
  String get groupCallActiveBanner => 'सक्रिय कॉल';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'गट: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'गट: $host';
  }

  @override
  String get groupCallCreateError => 'कॉल तयार करू शकलो नाही';

  @override
  String get groupCallJoinError => 'कॉलमध्ये सामील होऊ शकलो नाही';

  @override
  String get groupCallLivekitError => 'LiveKit त्रुटी';

  @override
  String get groupCallDone => 'पूर्ण';

  @override
  String get groupCallNoResults => 'निकाल नाहीत';

  @override
  String get groupCallNoContacts => 'संपर्क नाहीत';

  @override
  String get meshGcContactOffline => 'या Wi-Fi वर नाही';

  @override
  String get meshGcOnlineViaMesh => 'मेशद्वारे ऑनलाइन';

  @override
  String get meshGcMaxInvitees =>
      'गट कॉल्समध्ये 4 आमंत्रित (एकूण 5 लोक) पर्यंत समर्थन आहे.';

  @override
  String get meshGcStart => 'गट कॉल सुरू करा';

  @override
  String get meshGcCancel => 'रद्द करा';

  @override
  String get meshGcStatusCalling => 'कॉल करत आहे…';

  @override
  String get meshGcStatusJoined => 'जोडले';

  @override
  String get meshGcStatusDeclined => 'नकार दिला';

  @override
  String get meshGcStatusNoAnswer => 'उत्तर नाही';

  @override
  String get meshGcStatusConnectionFailed => 'कनेक्शन अयशस्वी';

  @override
  String get meshGcStatusLeft => 'सोडले';

  @override
  String get meshGcTopTitle => 'मेश';

  @override
  String get meshGcBusyOneOnOne => 'तुमचा चालू कॉल आधी पूर्ण करा.';

  @override
  String get presenceOnline => 'ऑनलाइन';

  @override
  String get presenceLastSeenJustNow => 'आत्ताच शेवटचे पाहिले';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'शेवटचे पाहिले $minutes मिनिटांपूर्वी';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'आज $time वाजता शेवटचे पाहिले';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'काल $time वाजता शेवटचे पाहिले';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'शेवटचे पाहिले $date';
  }

  @override
  String get presenceLastSeenRecently => 'अलीकडेच शेवटचे पाहिले';

  @override
  String get privacySectionTitle => 'गोपनीयता';

  @override
  String get privacyLastSeenLabel => 'तुमचा शेवटचा पाहिलेला वेळ कोण पाहतो';

  @override
  String get privacyEveryone => 'सर्व';

  @override
  String get privacyContacts => 'फक्त संपर्क';

  @override
  String get privacyNobody => 'कोणीही नाही';

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
