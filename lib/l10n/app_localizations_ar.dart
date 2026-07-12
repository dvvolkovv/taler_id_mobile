// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'بحث';

  @override
  String get appSubtitle => 'هوية النظام البيئي الموحد';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get registerButton => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'الاسم الأخير';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get createOne => 'أنشئ واحدًا';

  @override
  String get haveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get passwordMinLength => 'الحد الأدنى 8 أحرف';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get fieldRequired => 'حقل مطلوب';

  @override
  String get twoFATitle => 'المصادقة الثنائية';

  @override
  String get twoFASubtitle =>
      'أدخل الرمز المكون من 6 أرقام من تطبيق المصادقة الخاص بك';

  @override
  String get twoFACode => 'رمز 2FA';

  @override
  String get verify => 'تحقق';

  @override
  String get tabProfile => 'الملف الشخصي';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'المنظمة';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get phone => 'الهاتف';

  @override
  String get country => 'البلد';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get documents => 'المستندات';

  @override
  String get addDocument => 'إضافة مستند';

  @override
  String get noDocuments => 'لم يتم تحميل مستندات';

  @override
  String get save => 'حفظ';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get personalData => 'البيانات الشخصية';

  @override
  String get passport => 'جواز السفر';

  @override
  String get drivingLicense => 'رخصة القيادة';

  @override
  String get diploma => 'دبلوم';

  @override
  String get nationalId => 'الهوية الوطنية';

  @override
  String get certificate => 'شهادة';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get notSpecifiedFemale => 'غير محدد';

  @override
  String get documentType => 'نوع المستند';

  @override
  String get passportId => 'جواز السفر / الهوية';

  @override
  String get diplomaCertificate => 'دبلوم / شهادة';

  @override
  String get loadError => 'خطأ في التحميل';

  @override
  String get verification => 'التحقق';

  @override
  String get countryAustria => 'النمسا';

  @override
  String get countryGermany => 'ألمانيا';

  @override
  String get countryRussia => 'روسيا';

  @override
  String get countryUkraine => 'أوكرانيا';

  @override
  String get countryKazakhstan => 'كازاخستان';

  @override
  String get countryBelarus => 'بيلاروسيا';

  @override
  String get countryOther => 'أخرى';

  @override
  String get kycTitle => 'التحقق من KYC';

  @override
  String get kycVerified => 'تم التحقق';

  @override
  String get kycPending => 'قيد الانتظار';

  @override
  String get kycRejected => 'مرفوض';

  @override
  String get kycUnverified => 'غير محقق';

  @override
  String get kycVerifiedDesc =>
      'تم التحقق من هويتك. لديك وصول كامل إلى جميع ميزات نظام Taler.';

  @override
  String get kycPendingDesc =>
      'يتم مراجعة مستنداتك. عادةً ما يستغرق ذلك 1-2 يوم عمل.';

  @override
  String get kycRejectedDesc =>
      'فشل التحقق. يرجى مراجعة السبب وإعادة تقديم مستنداتك.';

  @override
  String get kycUnverifiedDesc =>
      'أكمل التحقق لفتح الوصول الكامل إلى الميزات المالية لنظام Taler.';

  @override
  String get startVerification => 'ابدأ التحقق';

  @override
  String get retryVerification => 'أعد محاولة التحقق';

  @override
  String verifiedAt(String date) {
    return 'تم التحقق: $date';
  }

  @override
  String get documentsSubmitted => 'تم تقديم المستندات للمراجعة';

  @override
  String get documentsSubmittedDesc =>
      'عادةً ما تستغرق المراجعة 1-2 يوم عمل. ستتلقى إشعارًا بالنتيجة.';

  @override
  String get securityAes => 'بياناتك محمية بتشفير AES-256';

  @override
  String get verificationTime => 'يستغرق التحقق 1-2 يوم عمل';

  @override
  String get pushNotification => 'ستتلقى إشعارًا بالنتيجة';

  @override
  String get kycWebOnly => 'التحقق من KYC متاح فقط في التطبيق المحمول.';

  @override
  String verificationError(String code) {
    return 'خطأ في التحقق: $code';
  }

  @override
  String get organizations => 'المنظمات';

  @override
  String get noOrganizations => 'لا توجد منظمات';

  @override
  String get noOrganizationsDesc => 'أنشئ منظمة أو اقبل دعوة';

  @override
  String get createOrganization => 'إنشاء منظمة';

  @override
  String get newOrganization => 'منظمة جديدة';

  @override
  String get orgName => 'الاسم *';

  @override
  String get orgDescription => 'الوصف';

  @override
  String get orgEmail => 'البريد الإلكتروني للتواصل';

  @override
  String get orgWebsite => 'الموقع الإلكتروني';

  @override
  String get orgLegalAddress => 'العنوان القانوني';

  @override
  String get create => 'إنشاء';

  @override
  String get organization => 'المنظمة';

  @override
  String get contacts => 'جهات الاتصال';

  @override
  String members(int count) {
    return 'الأعضاء ($count)';
  }

  @override
  String get inviteMember => 'دعوة عضو';

  @override
  String get invite => 'دعوة';

  @override
  String get sendInvite => 'إرسال الدعوة';

  @override
  String inviteSent(String email) {
    return 'تم إرسال الدعوة إلى $email';
  }

  @override
  String get role => 'الدور';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleAdmin => 'المسؤول';

  @override
  String get roleOperator => 'المشغل';

  @override
  String get roleViewer => 'المشاهد';

  @override
  String get editOrganization => 'تعديل';

  @override
  String get editOrganizationTitle => 'تعديل المنظمة';

  @override
  String get removeMember => 'إزالة عضو';

  @override
  String removeMemberConfirm(String name) {
    return 'إزالة $name من المنظمة؟';
  }

  @override
  String get memberRemoved => 'تمت إزالة العضو';

  @override
  String get roleChanged => 'تم تغيير الدور';

  @override
  String get kybVerified => 'تم التحقق';

  @override
  String get kybPending => 'قيد الانتظار';

  @override
  String get kybRejected => 'مرفوض';

  @override
  String get kybNone => 'غير محقق';

  @override
  String get kybVerification => 'بدء التحقق KYB';

  @override
  String get kybStartBusiness => 'بدء التحقق من العمل';

  @override
  String get kybStatusLabel => 'حالة KYB';

  @override
  String get noKyb => 'لا يوجد KYB';

  @override
  String get kybBusinessVerificationTitle => 'التحقق من العمل (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'تم التحقق من المنظمة بنجاح.';

  @override
  String get kybPendingOrgDesc =>
      'يتم مراجعة المستندات. يستغرق ذلك عادة 1-3 أيام عمل.';

  @override
  String get kybRejectedOrgDesc => 'فشل التحقق. يرجى المحاولة مرة أخرى.';

  @override
  String get kybNoneOrgDesc => 'تحقق من منظمتك للوصول إلى ميزات العمل.';

  @override
  String get invitePlus => '+ دعوة';

  @override
  String get kybVerificationTitle => 'التحقق KYB';

  @override
  String get kybWebOnlyBusiness =>
      'التحقق KYB متاح فقط في تطبيق الهاتف المحمول.';

  @override
  String get unknownDevice => 'جهاز غير معروف';

  @override
  String get ipUnknown => 'IP غير معروف';

  @override
  String get currentSessionLabel => 'الحالي';

  @override
  String get endSessionAction => 'إنهاء';

  @override
  String get deviceLoggedOut => 'سيتم تسجيل خروج الجهاز.';

  @override
  String get acceptInvitationTitle => 'دعوة المنظمة';

  @override
  String get acceptInvitation => 'قبول الدعوة';

  @override
  String get acceptInvitationDesc =>
      'لقد تمت دعوتك للانضمام إلى منظمة في نظام Taler البيئي.';

  @override
  String get accept => 'قبول';

  @override
  String get reject => 'رفض';

  @override
  String get sessions => 'الجلسات النشطة';

  @override
  String get currentSession => 'الجلسة الحالية';

  @override
  String get deleteSession => 'إنهاء الجلسة';

  @override
  String get deleteSessionConfirm => 'إنهاء هذه الجلسة؟';

  @override
  String get sessionDeleted => 'تم إنهاء الجلسة';

  @override
  String get noSessions => 'لا توجد جلسات نشطة';

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get settings => 'الإعدادات';

  @override
  String get security => 'الأمان';

  @override
  String get biometrics => 'القياسات الحيوية';

  @override
  String get biometricsDesc =>
      'تسجيل دخول سريع باستخدام Face ID أو بصمة الإصبع';

  @override
  String get biometricsConfirm =>
      'أكد القياسات الحيوية لتمكين تسجيل الدخول السريع';

  @override
  String get biometricsError =>
      'فشل في تمكين القياسات الحيوية. تحقق من إعدادات الجهاز.';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get twoFactorAuth => 'المصادقة الثنائية';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور';

  @override
  String get wrongCurrentPassword => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get passwordTooWeak =>
      'كلمة المرور ضعيفة جدًا: يجب أن تحتوي على 8 أحرف على الأقل، وحرف ورقم';

  @override
  String get passwordChangeFailed => 'فشل في تغيير كلمة المرور';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get permissions => 'الأذونات';

  @override
  String get permissionNotifications => 'إشعارات الدفع';

  @override
  String get permissionNotificationsDesc => 'المكالمات، الرسائل، الحالات';

  @override
  String get permissionMicrophone => 'الميكروفون';

  @override
  String get permissionMicrophoneDesc => 'المكالمات والمساعد الصوتي';

  @override
  String get permissionCamera => 'الكاميرا';

  @override
  String get permissionCameraDesc => 'مكالمات الفيديو والتحقق';

  @override
  String get permissionLocation => 'الموقع';

  @override
  String get permissionLocationDesc => 'يستخدم للتحقق';

  @override
  String get permissionOpenSettings => 'لإلغاء إذن، افتح إعدادات النظام';

  @override
  String get pushKycStatus => 'إشعار حالة KYC';

  @override
  String get pushKycStatusDesc => 'نتيجة التحقق';

  @override
  String get pushLogins => 'إشعار تسجيل الدخول';

  @override
  String get pushLoginsDesc => 'عند تسجيل الدخول من جهاز جديد';

  @override
  String get account => 'الحساب';

  @override
  String get language => 'اللغة';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'لغة الواجهة';

  @override
  String get exportData => 'تصدير البيانات (GDPR)';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirm => 'حذف الحساب؟';

  @override
  String get deleteAccountDesc =>
      'سيتم حذف جميع بياناتك (GDPR). هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'تسجيل الخروج؟';

  @override
  String get logoutDesc => 'سيتم تسجيل خروجك من Taler ID على هذا الجهاز.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'رمز PIN';

  @override
  String get pinCodeDesc => 'تسجيل دخول سريع برمز من 4 أرقام';

  @override
  String get setupPin => 'إعداد رمز PIN';

  @override
  String get enterPin => 'أدخل رمز PIN';

  @override
  String get confirmPin => 'تأكيد رمز PIN';

  @override
  String get pinMismatch => 'الرموز غير متطابقة';

  @override
  String get passwordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get pinSet => 'تم تعيين رمز PIN بنجاح';

  @override
  String get enterPinToLogin => 'أدخل رمز PIN لتسجيل الدخول';

  @override
  String get pinIncorrect => 'رمز PIN غير صحيح';

  @override
  String get removePin => 'إزالة رمز PIN';

  @override
  String get pinRemoved => 'تمت إزالة رمز PIN';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get ok => 'حسنًا';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get failedToLoad => 'فشل في تحميل البيانات';

  @override
  String get failedToLoadProfile => 'فشل في تحميل الملف الشخصي';

  @override
  String get failedToSave => 'فشل في حفظ التغييرات';

  @override
  String get failedToLoadOrgs => 'فشل في تحميل المنظمات';

  @override
  String get failedToLoadOrg => 'فشل في تحميل بيانات المنظمة';

  @override
  String get failedToCreateOrg => 'فشل في إنشاء المنظمة';

  @override
  String get failedToInvite => 'فشل في إرسال الدعوة';

  @override
  String get failedToAcceptInvite => 'فشل في قبول الدعوة';

  @override
  String get failedToLoadSessions => 'فشل في تحميل الجلسات';

  @override
  String get failedToDeleteSession => 'فشل في إنهاء الجلسة';

  @override
  String get failedToLoadKyc => 'فشل في تحميل حالة التحقق';

  @override
  String get failedToStartKyc => 'فشل في بدء التحقق';

  @override
  String get verifiedPersonalInfo => 'البيانات الموثقة';

  @override
  String get middleName => 'الاسم الأوسط';

  @override
  String get placeOfBirth => 'مكان الميلاد';

  @override
  String get nationality => 'الجنسية';

  @override
  String get gender => 'الجنس';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get docNumber => 'الرقم';

  @override
  String get docIssuedDate => 'تاريخ الإصدار';

  @override
  String get docValidUntil => 'صالح حتى';

  @override
  String get docIssuedBy => 'صادر عن';

  @override
  String get address => 'العنوان';

  @override
  String get refreshData => 'تحديث البيانات';

  @override
  String get failedToLoadSumsubData => 'فشل في تحميل بيانات التحقق';

  @override
  String get sumsubDataLoading => 'جارٍ تحميل بيانات التحقق...';

  @override
  String get reviewResultGreen => 'تم اجتياز التحقق';

  @override
  String get reviewResultRed => 'فشل في التحقق';

  @override
  String get tabAssistant => 'المساعد';

  @override
  String get assistantConnecting => 'جارٍ الاتصال…';

  @override
  String get assistantSpeaking => 'يتحدث…';

  @override
  String get assistantListening => 'يستمع…';

  @override
  String get assistantTapToStart => 'اضغط للبدء';

  @override
  String get assistantTapToTalk => 'اضغط للتحدث إلى AI';

  @override
  String get assistantRealtimeDesc => 'المساعد يرد بالصوت في الوقت الحقيقي';

  @override
  String get assistantConnectingToAssistant => 'جارٍ الاتصال بالمساعد...';

  @override
  String get assistantAiSpeaking => 'الذكاء الاصطناعي يتحدث...';

  @override
  String get assistantAiListening => 'الذكاء الاصطناعي يستمع';

  @override
  String get assistantSpeakerOn => 'تشغيل السماعة';

  @override
  String get assistantSpeaker => 'السماعة';

  @override
  String get assistantEnd => 'إنهاء';

  @override
  String get assistantUnmute => 'إلغاء كتم الصوت';

  @override
  String get assistantMicrophone => 'الميكروفون';

  @override
  String get assistantConnectionError => 'خطأ في الاتصال';

  @override
  String get tabMessenger => 'الرسائل';

  @override
  String get tabCalls => 'المكالمات';

  @override
  String get tabCalendar => 'التقويم';

  @override
  String get appearance => 'المظهر';

  @override
  String get appearanceSelect => 'اختر السمة';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get onboardingTitle1 => 'هوية موحدة';

  @override
  String get onboardingDesc1 =>
      'Taler ID هو جواز سفرك الرقمي في نظام Taler. حساب واحد لجميع الخدمات.';

  @override
  String get onboardingTitle2 => 'أمان البيانات';

  @override
  String get onboardingDesc2 =>
      'التحقق من KYC، تشفير AES-256، والمصادقة الثنائية تحمي هويتك.';

  @override
  String get onboardingTitle3 => 'ابقَ على اطلاع';

  @override
  String get onboardingDesc3 =>
      'احصل على إشعارات حول حالة التحقق، تسجيل الدخول من أجهزة جديدة، والمكالمات الواردة.';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingEnableNotifications => 'تفعيل الإشعارات';

  @override
  String get onboardingTitle4 => 'المكالمات الصوتية';

  @override
  String get onboardingDesc4 =>
      'امنح إذن الوصول إلى الميكروفون للمكالمات الصوتية ومساعد الذكاء الاصطناعي. يمكنك تغيير هذا لاحقًا في الإعدادات.';

  @override
  String get onboardingEnableMicrophone => 'تفعيل الميكروفون';

  @override
  String get onboardingStart => 'ابدأ';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get meshLocalNetworkPromptTitle => 'السماح بالوصول إلى الشبكة المحلية';

  @override
  String get meshLocalNetworkPromptBody =>
      'للعثور على الأقران عبر Wi-Fi (مكالمات المجموعة دون اتصال)، يتطلب iOS إذن الشبكة المحلية. افتح الإعدادات → الخصوصية والأمان → الشبكة المحلية → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'افتح الإعدادات';

  @override
  String get meshLocalNetworkPromptDismiss => 'فهمت';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني لتلقي رمز إعادة التعيين';

  @override
  String resetCodeSent(String email) {
    return 'تم إرسال الرمز إلى $email';
  }

  @override
  String get enterResetCode => 'أدخل الرمز';

  @override
  String get resetPasswordButton => 'إعادة تعيين كلمة المرور';

  @override
  String get passwordResetSuccess => 'تمت إعادة تعيين كلمة المرور بنجاح';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

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
  String get newGroup => 'مجموعة جديدة';

  @override
  String get newChat => 'دردشة جديدة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get createGroup => 'إنشاء مجموعة';

  @override
  String get groupInfo => 'معلومات المجموعة';

  @override
  String groupMembers(int count) {
    return 'الأعضاء ($count)';
  }

  @override
  String get addMembers => 'إضافة أعضاء';

  @override
  String get leaveGroup => 'مغادرة المجموعة';

  @override
  String get leaveGroupConfirm => 'مغادرة هذه المجموعة؟';

  @override
  String get deleteGroup => 'حذف المجموعة';

  @override
  String get deleteGroupConfirm => 'حذف هذه المجموعة؟ لا يمكن التراجع عن ذلك.';

  @override
  String get groupRoleOwner => 'المالك';

  @override
  String get groupRoleAdmin => 'المسؤول';

  @override
  String get groupRoleMember => 'عضو';

  @override
  String get selectParticipants => 'اختر المشاركين';

  @override
  String selectedCount(int count) {
    return '$count مختار';
  }

  @override
  String get changeRole => 'تغيير الدور';

  @override
  String get groupCreated => 'تم إنشاء المجموعة';

  @override
  String memberJoined(String name) {
    return 'انضم $name';
  }

  @override
  String memberLeftGroup(String name) {
    return 'غادر $name';
  }

  @override
  String memberWasRemoved(String name) {
    return 'تمت إزالة $name';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name أصبح الآن $role';
  }

  @override
  String participantsCount(int count) {
    return '$count مشارك';
  }

  @override
  String get enterGroupName => 'أدخل اسم المجموعة';

  @override
  String get muteNotifications => 'كتم الإشعارات';

  @override
  String get unmuteNotifications => 'إلغاء كتم الإشعارات';

  @override
  String get muteFor1Hour => 'لمدة ساعة';

  @override
  String get muteFor8Hours => 'لمدة 8 ساعات';

  @override
  String get muteFor2Days => 'لمدة يومين';

  @override
  String get muteForever => 'إلى الأبد';

  @override
  String get muted => 'مكتوم';

  @override
  String get tabTranslator => 'ترجمة';

  @override
  String get translatorTitle => 'المترجم';

  @override
  String get translatorSelectLanguage => 'اختر اللغة';

  @override
  String get translatorDownloading => 'جارٍ تنزيل نماذج اللغة...';

  @override
  String get translatorDownloadingHint => 'الإنترنت مطلوب فقط للتنزيل الأول';

  @override
  String get translatorTypeHint => 'اكتب النص أو اضغط على الميكروفون';

  @override
  String get translatorListening => 'الاستماع...';

  @override
  String get translatorTapToSpeak => 'اضغط للتحدث';

  @override
  String get translatorTapToStop => 'اضغط للإيقاف';

  @override
  String get translatorAutoSpeak => 'التحدث التلقائي';

  @override
  String get translatorCopied => 'تم النسخ';

  @override
  String get translatorLangRu => 'الروسية';

  @override
  String get translatorLangEn => 'الإنجليزية';

  @override
  String get translatorLangDe => 'الألمانية';

  @override
  String get translatorLangFr => 'الفرنسية';

  @override
  String get translatorLangEs => 'الإسبانية';

  @override
  String get translatorLangIt => 'الإيطالية';

  @override
  String get translatorLangPt => 'البرتغالية';

  @override
  String get translatorLangTr => 'التركية';

  @override
  String get translatorLangZh => 'الصينية';

  @override
  String get translatorLangJa => 'اليابانية';

  @override
  String get translatorLangKo => 'الكورية';

  @override
  String get translatorLangAr => 'العربية';

  @override
  String get translatorLangPl => 'البولندية';

  @override
  String get translatorLangSk => 'السلوفاكية';

  @override
  String get translatorLangCs => 'التشيكية';

  @override
  String get translatorLangNl => 'الهولندية';

  @override
  String get translatorLangSv => 'السويدية';

  @override
  String get translatorLangDa => 'الدانماركية';

  @override
  String get translatorLangNo => 'النرويجية';

  @override
  String get translatorLangFi => 'الفنلندية';

  @override
  String get translatorLangUk => 'الأوكرانية';

  @override
  String get translatorLangEl => 'اليونانية';

  @override
  String get translatorLangRo => 'الرومانية';

  @override
  String get translatorLangHu => 'الهنغارية';

  @override
  String get translatorLangBg => 'البلغارية';

  @override
  String get translatorLangHr => 'الكرواتية';

  @override
  String get translatorLangSr => 'الصربية';

  @override
  String get translatorLangHi => 'الهندية';

  @override
  String get translatorLangTh => 'التايلاندية';

  @override
  String get translatorLangVi => 'الفيتنامية';

  @override
  String get translatorLangId => 'الإندونيسية';

  @override
  String get translatorLangMs => 'الماليزية';

  @override
  String get translatorLangHe => 'العبرية';

  @override
  String get translatorLangFa => 'الفارسية';

  @override
  String get callInProgress => 'المكالمة جارية';

  @override
  String get joinCall => 'انضم';

  @override
  String get createCallLink => 'رابط المكالمة';

  @override
  String get callLinkCopied => 'تم نسخ الرابط';

  @override
  String get callLinkTitle => 'رابط الغرفة';

  @override
  String get connectionUnstable => 'الاتصال غير مستقر — تحقق من الإنترنت';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get errorTimeout => 'انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.';

  @override
  String get errorNoConnection => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get errorGeneral => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get notifChannelMessages => 'الرسائل';

  @override
  String get notifChannelMessagesDesc => 'إشعارات الرسائل الجديدة';

  @override
  String get notifChannelMissedCalls => 'المكالمات الفائتة';

  @override
  String get notifChannelMissedCallsDesc => 'إشعارات المكالمات الفائتة';

  @override
  String get notifMissedCall => 'مكالمة فائتة';

  @override
  String get notifAccept => 'قبول';

  @override
  String get notifDecline => 'رفض';

  @override
  String get notifIncomingCall => 'مكالمة واردة';

  @override
  String get notifIncomingCallChannel => 'مكالمة واردة';

  @override
  String get notifMissedCallChannel => 'مكالمة فائتة';

  @override
  String get notifUnknown => 'غير معروف';

  @override
  String get effectNone => 'بدون خلفية';

  @override
  String get effectBlur => 'ضبابية';

  @override
  String get effectOffice => 'مكتب';

  @override
  String get effectNature => 'طبيعة';

  @override
  String get effectGradient => 'تدرج';

  @override
  String get effectLibrary => 'مكتبة';

  @override
  String get effectCity => 'مدينة';

  @override
  String get effectMinimalism => 'تبسيط';

  @override
  String get voiceParticipant => 'مشارك';

  @override
  String get voiceInvitesToRoom => 'يدعوك إلى الغرفة';

  @override
  String get voiceRoom => 'غرفة';

  @override
  String get voicePasswordProtected => 'محمي بكلمة مرور';

  @override
  String get voicePasswordHint => 'كلمة المرور';

  @override
  String get voiceEnter => 'دخول';

  @override
  String get voiceJoinRoom => 'انضم إلى الغرفة';

  @override
  String get voiceYourName => 'اسمك';

  @override
  String voiceInvitationSent(String name) {
    return 'تم إرسال الدعوة إلى $name';
  }

  @override
  String get voiceNoActiveRoom => 'لا توجد غرفة نشطة';

  @override
  String get voiceCameraPermission =>
      'اسمح بالوصول إلى الكاميرا في الإعدادات → الخصوصية → الكاميرا → TalerID';

  @override
  String get voiceOpenSettings => 'افتح';

  @override
  String voiceCameraError(String error) {
    return 'فشل في تفعيل الكاميرا: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'تم الاتفاق. بدأ التسجيل.';

  @override
  String get voiceNewParticipantAgreed => 'مشارك جديد وافق على التسجيل.';

  @override
  String get voiceDeclinedRecording => 'رفضت التسجيل. مغادرة المكالمة.';

  @override
  String get voiceRecordingEnded => 'انتهى التسجيل';

  @override
  String get voiceRecordingInProgress => 'التسجيل جارٍ';

  @override
  String get voiceTranscriptionRequest => 'طلب النسخ';

  @override
  String get voiceRecordingRequest => 'طلب التسجيل';

  @override
  String get voiceAgree => 'موافقة';

  @override
  String get voiceDeclineAndLeave => 'رفض ومغادرة';

  @override
  String get voiceAudioOutput => 'مخرج الصوت';

  @override
  String get voiceAudioPhone => 'الهاتف';

  @override
  String get voiceAudioSpeaker => 'مكبر الصوت';

  @override
  String get voiceAudioBluetooth => 'بلوتوث';

  @override
  String get voiceAudioHeadphones => 'سماعات';

  @override
  String get voiceLinkCopied => 'تم نسخ الرابط';

  @override
  String get voiceTranslateTo => 'ترجمة إلى';

  @override
  String get voiceSearchLanguage => 'بحث عن لغة...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'غرفة $name';
  }

  @override
  String get voiceVoiceCall => 'مكالمة صوتية';

  @override
  String get voiceOnHold => 'قيد الانتظار';

  @override
  String get voiceActiveCall => 'نشط';

  @override
  String get voiceEndAllCalls => 'إنهاء جميع المكالمات';

  @override
  String get voiceEndThisCall => 'إنهاء هذه المكالمة';

  @override
  String get voiceCopyLink => 'نسخ الرابط';

  @override
  String get voiceAddParticipant => 'إضافة مشارك';

  @override
  String get voiceReconnecting => 'إعادة الاتصال...';

  @override
  String get voiceConnectionError => 'خطأ في الاتصال';

  @override
  String get voiceClose => 'إغلاق';

  @override
  String get voiceCalling => 'جارٍ الاتصال...';

  @override
  String get voiceCallActive => 'المكالمة نشطة';

  @override
  String get voiceWaiting => 'انتظار';

  @override
  String get voiceWaitingUpper => 'انتظار';

  @override
  String get voiceRec => 'تسجيل';

  @override
  String get voiceStop => 'إيقاف';

  @override
  String get voiceRecord => 'تسجيل';

  @override
  String get voiceTranslation => 'ترجمة';

  @override
  String get voiceAudio => 'صوت';

  @override
  String get voiceFlipCamera => 'تبديل';

  @override
  String get voiceBackground => 'الخلفية';

  @override
  String get voiceAssistantSpeakingStatus => 'المساعد يتحدث...';

  @override
  String get voiceAssistantListeningStatus => 'المساعد يستمع...';

  @override
  String get voiceUnmute => 'إلغاء كتم الصوت';

  @override
  String get voiceMic => 'الميكروفون';

  @override
  String get voiceAssistantLabel => 'المساعد';

  @override
  String get voiceCameraOn => 'تشغيل الكاميرا';

  @override
  String get voiceCameraLabel => 'الكاميرا';

  @override
  String get voiceEndCall => 'إنهاء المكالمة';

  @override
  String get voiceWaitingParticipants => 'في انتظار المشاركين...';

  @override
  String get voiceYou => 'أنت';

  @override
  String get voiceAiAssistant => 'المساعد AI';

  @override
  String get voiceVideoUnavailable => 'الفيديو غير متاح';

  @override
  String get voiceSearchNickname => 'البحث باللقب...';

  @override
  String get voiceTranscriptionWord => 'النسخ';

  @override
  String get voiceRecordingWord => 'التسجيل';

  @override
  String get voiceConnecting => 'جارٍ الاتصال...';

  @override
  String get voiceVideoBackground => 'خلفية الفيديو';

  @override
  String get voiceCallSettings => 'إعدادات المكالمة';

  @override
  String get voiceEnableAI => 'تمكين المساعد AI';

  @override
  String get voiceAIParticipating => 'سيشارك AI في المحادثة';

  @override
  String get voiceNormalCall => 'مكالمة عادية بدون AI';

  @override
  String get voiceCallConfirm => 'إجراء مكالمة؟';

  @override
  String get chatAlreadyInCall => 'أنت بالفعل في مكالمة';

  @override
  String chatCallError(String error) {
    return 'خطأ في المكالمة: $error';
  }

  @override
  String get chatPhotoVideo => 'صورة / فيديو';

  @override
  String get chatCamera => 'الكاميرا';

  @override
  String get chatFile => 'ملف';

  @override
  String get chatContact => 'جهة اتصال';

  @override
  String get chatSelectContact => 'اختر جهة اتصال';

  @override
  String get chatNoContacts => 'لا توجد جهات اتصال';

  @override
  String get chatUser => 'المستخدم';

  @override
  String get chatFileAttachment => '📎 ملف';

  @override
  String chatFileUploadError(String error) {
    return 'خطأ في تحميل الملف: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 رسالة صوتية';

  @override
  String get chatGroup => 'مجموعة';

  @override
  String get chatDialog => 'حوار';

  @override
  String get chatCall => 'مكالمة';

  @override
  String get chatStartConversation => 'ابدأ محادثة';

  @override
  String get chatYou => 'أنت';

  @override
  String get chatIsTyping => 'يكتب...';

  @override
  String chatUserIsTyping(String name) {
    return '$name يكتب...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names يكتبون...';
  }

  @override
  String get chatPreparingFile => 'جارٍ تحضير الملف…';

  @override
  String chatUploading(int progress) {
    return 'جارٍ الرفع… $progress%';
  }

  @override
  String get chatEdited => 'معدّل';

  @override
  String get chatViaMesh => 'عبر الشبكة';

  @override
  String get chatReply => 'رد';

  @override
  String get chatEdit => 'تعديل';

  @override
  String get chatCopy => 'نسخ';

  @override
  String get chatCopied => 'تم النسخ';

  @override
  String get chatSaveMedia => 'حفظ';

  @override
  String get chatForward => 'إعادة توجيه';

  @override
  String get chatSaving => 'جارٍ الحفظ...';

  @override
  String get chatSavedToGallery => 'تم الحفظ في المعرض';

  @override
  String get chatNoSavePermission => 'لا يوجد إذن للحفظ. تحقق من الإعدادات.';

  @override
  String get chatFileSaveError => 'خطأ في حفظ الملف';

  @override
  String get chatDeleteMessage => 'حذف الرسالة';

  @override
  String get chatDeleteForMe => 'حذف لي';

  @override
  String get chatDeleteForEveryone => 'حذف للجميع';

  @override
  String get chatMessageForwarded => 'تم إعادة توجيه الرسالة';

  @override
  String get chatContactTapToOpen => 'جهة اتصال · اضغط للفتح';

  @override
  String get chatForwardTo => 'إعادة توجيه إلى...';

  @override
  String get chatSearchHint => 'بحث...';

  @override
  String get chatRecording => 'جارٍ التسجيل...';

  @override
  String get chatMessageHint => 'رسالة...';

  @override
  String get chatHideKeyboard => 'إخفاء لوحة المفاتيح';

  @override
  String get chatEditing => 'جارٍ التعديل';

  @override
  String get chatFileDownloadError => 'خطأ في تنزيل الملف';

  @override
  String get chatVoiceMessageShort => 'رسالة صوتية';

  @override
  String get chatVideoSavedToGallery => 'تم حفظ الفيديو في المعرض';

  @override
  String get chatSavingError => 'خطأ في الحفظ';

  @override
  String get convSetNickname => 'تعيين لقب';

  @override
  String get convNicknameRequired =>
      'يتطلب استخدام المراسلة تعيين لقب. يمكن للمستخدمين الآخرين العثور عليك من خلاله.';

  @override
  String get convNicknameRules => '3–30 حرفًا: حروف، أرقام، _';

  @override
  String get convNicknameTaken => 'اللقب مستخدم بالفعل';

  @override
  String get convSaveError => 'خطأ في الحفظ';

  @override
  String get convContactsLabel => 'جهات الاتصال';

  @override
  String get convDefaultUser => 'مستخدم';

  @override
  String get convNoDialogs => 'لا توجد محادثات';

  @override
  String get convFindUserToChat => 'ابحث عن مستخدم لبدء الدردشة';

  @override
  String get convDefaultContact => 'جهة اتصال';

  @override
  String get dashboardUser => 'مستخدم';

  @override
  String get dashboardIncomingCall => 'مكالمة واردة';

  @override
  String get dashboardDecline => 'رفض';

  @override
  String get dashboardAccept => 'قبول';

  @override
  String get dashboardActiveCall => 'مكالمة نشطة — اضغط للعودة';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'تحديث متاح $version';
  }

  @override
  String get dashboardUpdate => 'تحديث';

  @override
  String get dashboardWhatsNew => 'ما الجديد';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'ما الجديد في $version';
  }

  @override
  String get dashboardInstalling => 'جارٍ التثبيت...';

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
  String get contactRequestsTitle => 'جهات الاتصال';

  @override
  String get messengerContactRequestsSection => 'طلبات الاتصال';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلبات جديدة',
      one: 'طلب جديد واحد',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'بحث';

  @override
  String get contactRequestsIncoming => 'وارد';

  @override
  String get contactRequestsSent => 'مرسل';

  @override
  String get contactRequestsSearchHint => 'الاسم المستعار أو البريد الإلكتروني';

  @override
  String get contactRequestSent => 'تم إرسال الطلب';

  @override
  String get contactRequestsNoUsers => 'لم يتم العثور على مستخدمين';

  @override
  String get contactRequestsSearchHelp =>
      'أدخل الاسم المستعار أو البريد الإلكتروني بدقة\nواضغط على بحث';

  @override
  String get contactRequestsSendTooltip => 'إرسال طلب';

  @override
  String get contactRequestTitle => 'طلب اتصال';

  @override
  String contactRequestConfirm(String name) {
    return 'إرسال طلب اتصال إلى $name؟';
  }

  @override
  String get contactRequestSend => 'إرسال';

  @override
  String get contactRequestsNoIncoming => 'لا توجد طلبات واردة';

  @override
  String get contactRequestsNoSent => 'لا توجد طلبات مرسلة';

  @override
  String get contactRequestStatusPending => 'بانتظار الرد';

  @override
  String get contactRequestStatusAccepted => 'مقبول';

  @override
  String get contactRequestStatusRejected => 'مرفوض';

  @override
  String get userSearchTitle => 'البحث عن مستخدم';

  @override
  String get userSearchHint => 'الاسم المستعار، الهاتف أو البريد الإلكتروني';

  @override
  String get userSearchHelper =>
      'أدخل @الاسم المستعار، البريد الإلكتروني أو الاسم للبحث';

  @override
  String get userSearchNoUsers => 'لم يتم العثور على مستخدمين';

  @override
  String get userProfileShareContact => 'مشاركة جهة الاتصال';

  @override
  String get userProfileShareContactDesc => 'إرسال رابط جهة الاتصال';

  @override
  String get userProfileCopyLink => 'نسخ الرابط';

  @override
  String get userProfileCopied => 'تم النسخ';

  @override
  String get userProfileTitle => 'الملف الشخصي';

  @override
  String get userProfileLoadError => 'خطأ في تحميل الملف الشخصي';

  @override
  String get userProfileMessage => 'رسالة';

  @override
  String get userProfileCall => 'اتصال';

  @override
  String get userProfileRequestSent => 'تم إرسال الطلب';

  @override
  String get userProfileAccept => 'قبول';

  @override
  String get userProfileDecline => 'رفض';

  @override
  String get userProfileAddToContacts => 'إضافة إلى جهات الاتصال';

  @override
  String get userProfileMediaTab => 'وسائط';

  @override
  String get userProfileFilesTab => 'ملفات';

  @override
  String get userProfileLinksTab => 'روابط';

  @override
  String get userProfileRecordingsTab => 'تسجيلات';

  @override
  String get userProfileSummariesTab => 'ملخصات';

  @override
  String get userProfileNoMedia => 'لا توجد ملفات وسائط';

  @override
  String get userProfileNoFiles => 'لا توجد ملفات';

  @override
  String get userProfileNoLinks => 'لا توجد روابط';

  @override
  String get userProfileNoRecordings => 'لا توجد تسجيلات';

  @override
  String get userProfileNoSummaries => 'لا توجد ملخصات';

  @override
  String get userProfileMeetingSummary => 'ملخص الاجتماع';

  @override
  String get userProfileFailedOpenChat => 'فشل في فتح الدردشة';

  @override
  String get sharedMediaTitle => 'الوسائط والملفات';

  @override
  String get sharedMediaTab => 'وسائط';

  @override
  String get sharedFilesTab => 'ملفات';

  @override
  String get sharedLinksTab => 'روابط';

  @override
  String get sharedNoMedia => 'لا توجد ملفات وسائط';

  @override
  String get sharedNoFiles => 'لا توجد ملفات';

  @override
  String get sharedNoLinks => 'لا توجد روابط';

  @override
  String get shareToChat => 'إعادة توجيه إلى الدردشة';

  @override
  String get shareSelectChat => 'اختر دردشة';

  @override
  String get shareNoChats => 'لا توجد دردشات';

  @override
  String shareFilesCount(int count) {
    return '$count ملفات';
  }

  @override
  String get contactsTitle => 'جهات الاتصال';

  @override
  String get contactsAddTooltip => 'إضافة جهة اتصال';

  @override
  String get contactsSearchHint => 'ابحث في جهات الاتصال...';

  @override
  String get contactsNotFound => 'لم يتم العثور على شيء';

  @override
  String get contactsEmpty => 'لا توجد جهات اتصال';

  @override
  String get contactsAdd => 'إضافة جهة اتصال';

  @override
  String get contactsPendingConfirmation => 'في انتظار التأكيد';

  @override
  String get contactsMessage => 'رسالة';

  @override
  String get contactsCall => 'اتصال';

  @override
  String get contactsResend => 'إعادة إرسال الطلب';

  @override
  String get contactsResendTimeout => 'أعد المحاولة خلال 24 ساعة';

  @override
  String get contactsResent => 'تم إعادة إرسال الطلب';

  @override
  String get contactsWantsToConnect => 'يريد الاتصال بك';

  @override
  String get contactsSearchPeople => 'ابحث عن أشخاص';

  @override
  String get notesTitle => 'ملاحظات';

  @override
  String get notesAssistantSpeaking => 'المساعد يتحدث...';

  @override
  String get notesListening => 'الاستماع...';

  @override
  String get notesEmpty => 'لا توجد ملاحظات';

  @override
  String get notesEmptyHint =>
      'اضغط على الميكروفون للإملاء\nأو + للإدخال اليدوي';

  @override
  String get notesDeleteConfirm => 'حذف الملاحظة؟';

  @override
  String get notesNew => 'ملاحظة جديدة';

  @override
  String get notesEdit => 'تعديل';

  @override
  String get notesTitleHint => 'العنوان';

  @override
  String get notesContentHint => 'اكتب أفكارك...';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get calendarStop => 'إيقاف';

  @override
  String get calendarVoiceInput => 'إدخال صوتي';

  @override
  String get calendarNewEvent => 'حدث جديد';

  @override
  String get calendarAssistantSpeaking => 'المساعد يتحدث...';

  @override
  String get calendarListening => 'الاستماع...';

  @override
  String calendarInvitations(int count) {
    return 'الدعوات ($count)';
  }

  @override
  String get calendarNoEvents => 'لا توجد أحداث';

  @override
  String get calendarDayMon => 'الإثنين';

  @override
  String get calendarDayTue => 'الثلاثاء';

  @override
  String get calendarDayWed => 'الأربعاء';

  @override
  String get calendarDayThu => 'الخميس';

  @override
  String get calendarDayFri => 'الجمعة';

  @override
  String get calendarDaySat => 'السبت';

  @override
  String get calendarDaySun => 'الأحد';

  @override
  String get calendarEnterRoom => 'دخول الغرفة';

  @override
  String get calendarMeeting => 'اجتماع';

  @override
  String calendarLocationPrefix(String location) {
    return 'الموقع: $location';
  }

  @override
  String get calendarEditEvent => 'تعديل';

  @override
  String get calendarTitleHint => 'العنوان';

  @override
  String get calendarDescriptionHint => 'الوصف';

  @override
  String get calendarTypeEvent => 'حدث';

  @override
  String get calendarTypeMeeting => 'اجتماع';

  @override
  String get calendarTypeReminder => 'تذكير';

  @override
  String get calendarTypeLabel => 'النوع';

  @override
  String get calendarMeetingLink => 'رابط الاجتماع';

  @override
  String get calendarLocationHint => 'الموقع';

  @override
  String get calendarDateLabel => 'التاريخ';

  @override
  String get calendarTimeLabel => 'الوقت';

  @override
  String get calendarReminderLabel => 'التذكير';

  @override
  String get calendarReminderNone => 'لا يوجد';

  @override
  String get calendarReminder15min => 'قبل 15 دقيقة';

  @override
  String get calendarReminder30min => 'قبل 30 دقيقة';

  @override
  String get calendarReminder1hour => 'قبل ساعة';

  @override
  String get calendarRepeatLabel => 'التكرار';

  @override
  String get calendarRepeatNone => 'بدون تكرار';

  @override
  String get calendarRepeatDaily => 'كل يوم';

  @override
  String get calendarRepeatWeekly => 'كل أسبوع';

  @override
  String get calendarRepeatMonthly => 'كل شهر';

  @override
  String get calendarRepeatYearly => 'كل سنة';

  @override
  String get calendarParticipants => 'المشاركون';

  @override
  String get calendarAddParticipant => 'إضافة';

  @override
  String get calendarSearchContacts => 'البحث في جهات الاتصال...';

  @override
  String get calendarNoContacts => 'لا توجد جهات اتصال';

  @override
  String get calendarStatusAccepted => 'مقبول';

  @override
  String get calendarStatusDeclined => 'مرفوض';

  @override
  String get calendarStatusMaybe => 'ربما';

  @override
  String get calendarStatusPending => 'قيد الانتظار';

  @override
  String get calendarEndTime => 'وقت الانتهاء';

  @override
  String get calendarYourAnswer => 'إجابتك:';

  @override
  String get calendarOrganizer => 'المنظم';

  @override
  String calendarDeleteError(String error) {
    return 'فشل في الحذف: $error';
  }

  @override
  String get calendarRsvpAccept => 'قبول';

  @override
  String get calendarRsvpMaybe => 'ربما';

  @override
  String get calendarRsvpDecline => 'رفض';

  @override
  String get callHistoryTitle => 'المكالمات';

  @override
  String get callHistoryTab => 'سجل المكالمات';

  @override
  String get callHistoryTempMeeting => 'اجتماع مؤقت';

  @override
  String get callHistoryCopy => 'نسخ';

  @override
  String get callHistoryLinkCopied => 'تم نسخ الرابط';

  @override
  String get callHistoryShare => 'مشاركة';

  @override
  String get callHistoryEnter => 'دخول';

  @override
  String get callHistoryAlreadyInCall => 'أنت بالفعل في مكالمة';

  @override
  String get callHistoryCouldNotDeterminePeer => 'تعذر تحديد الطرف الآخر';

  @override
  String get callHistoryContacts => 'جهات الاتصال';

  @override
  String get callHistoryFailedLoadRoom => 'فشل في تحميل الغرفة';

  @override
  String get callHistoryYourRoom => 'غرفتك';

  @override
  String get callHistoryCreateMeeting => 'إنشاء اجتماع';

  @override
  String get callHistoryMeetingSummaries => 'ملخصات الاجتماعات';

  @override
  String get callHistoryMeetingRecordings => 'تسجيلات الاجتماعات';

  @override
  String get callHistoryNoCalls => 'لا توجد مكالمات';

  @override
  String get callHistoryMissed => 'فائتة';

  @override
  String get callHistoryRecording => 'تسجيل';

  @override
  String get callHistorySummary => 'ملخص';

  @override
  String get callHistoryCallAgain => 'اتصل مرة أخرى';

  @override
  String callHistoryTodayTime(String time) {
    return 'اليوم، $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'أمس، $time';
  }

  @override
  String get callHistoryUnknown => 'غير معروف';

  @override
  String get callHistoryDetails => 'تفاصيل المكالمة';

  @override
  String get callHistoryOutgoing => 'مكالمة صادرة';

  @override
  String get callHistoryIncoming => 'مكالمة واردة';

  @override
  String callHistoryDuration(String duration) {
    return 'المدة: $duration';
  }

  @override
  String get callHistoryWithAI => 'مع المساعد AI';

  @override
  String get callHistoryParticipants => 'المشاركون';

  @override
  String get callDetailYouSuffix => '(أنت)';

  @override
  String get callHistoryMeetingSummary => 'ملخص الاجتماع';

  @override
  String get callHistoryMoreDetails => 'مزيد من التفاصيل';

  @override
  String get callHistorySummaryProcessing => 'جاري معالجة الملخص...';

  @override
  String get callHistoryMeetingRecording => 'تسجيل الاجتماع';

  @override
  String get callHistoryProcessing => 'جاري المعالجة...';

  @override
  String get callHistoryCreateTranscript => 'إنشاء نص';

  @override
  String get callHistoryNoSummaries => 'لا توجد ملخصات';

  @override
  String get callHistoryRecordDuringCall => 'اضغط على \"تسجيل\" أثناء المكالمة';

  @override
  String callHistoryMeetingTime(String time) {
    return 'اجتماع $time';
  }

  @override
  String get callHistoryTranscribing => 'جاري النسخ والتلخيص...';

  @override
  String get callHistoryTranscriptCreated => 'تم إنشاء النص';

  @override
  String get callHistoryNoRecordings => 'لا توجد تسجيلات';

  @override
  String callHistoryRecordingDate(String date) {
    return 'تسجيل $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'التسجيل غير متاح';

  @override
  String get callHistoryTranscriptReady => 'النص جاهز';

  @override
  String get callHistoryTranscript => 'النص';

  @override
  String get callHistoryKeyPoints => 'النقاط الرئيسية';

  @override
  String get callHistoryTasks => 'المهام';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'مُكلف لـ: $assignee';
  }

  @override
  String get callHistoryDecisions => 'القرارات';

  @override
  String get callHistoryShowTranscript => 'عرض النص الكامل';

  @override
  String get profileScanQr => 'مسح QR';

  @override
  String get profileMyQrCode => 'رمز QR الخاص بي';

  @override
  String profileAddMeShare(String userId) {
    return 'أضفني في Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'اعرض هذا الرمز لإضافتك';

  @override
  String get profileEditDesc => 'الاسم، اللقب، اسم الأب، تاريخ الميلاد';

  @override
  String get profileAboutMe => 'عني';

  @override
  String get profileAboutMeDesc => 'القيم، المهارات، الاهتمامات والمزيد';

  @override
  String get profileNotes => 'ملاحظات';

  @override
  String get profileNotesDesc => 'أفكار، أفكار وملاحظات';

  @override
  String get profileAvatarUpdated => 'تم تحديث الصورة الرمزية';

  @override
  String get profileNickname => 'اللقب';

  @override
  String get profileNotSet => 'غير محدد';

  @override
  String get profileChangeNickname => 'تغيير اللقب';

  @override
  String get profileNicknameUpdated => 'تم تحديث اللقب';

  @override
  String get profileShareLabel => 'مشاركة';

  @override
  String get profileScanQrCode => 'مسح رمز QR';

  @override
  String get profilePointCamera => 'وجه الكاميرا نحو رمز QR';

  @override
  String get profilePhotoCamera => 'التقاط صورة';

  @override
  String get profilePhotoGallery => 'اختر من المعرض';

  @override
  String get editProfilePatronymic => 'اسم الأب (اختياري)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'عني';

  @override
  String get aboutMeClickToFill => 'اضغط للملء';

  @override
  String get aboutMeCoreValues => 'القيم';

  @override
  String get aboutMeWorldview => 'النظرة للعالم';

  @override
  String get aboutMeSkills => 'المهارات';

  @override
  String get aboutMeInterests => 'الاهتمامات';

  @override
  String get aboutMeDesires => 'الرغبات';

  @override
  String get aboutMeBackground => 'الملف الشخصي';

  @override
  String get aboutMeLikes => 'الإعجابات';

  @override
  String get aboutMeDislikes => 'عدم الإعجابات';

  @override
  String get aboutMeDeleteSection => 'حذف القسم؟';

  @override
  String get aboutMeDeleteConfirm => 'سيتم حذف جميع البيانات في هذا القسم.';

  @override
  String aboutMeConnectionError(String error) {
    return 'خطأ في الاتصال: $error';
  }

  @override
  String get aboutMeVisibility => 'الرؤية';

  @override
  String get aboutMeTags => 'العلامات';

  @override
  String get aboutMeAddTag => 'أضف علامة...';

  @override
  String get aboutMeDescription => 'الوصف';

  @override
  String get aboutMeDescribeLong => 'أخبرنا المزيد...';

  @override
  String get aboutMeVisibilityEveryone => 'الجميع';

  @override
  String get aboutMeVisibilityContacts => 'جهات الاتصال';

  @override
  String get aboutMeVisibilityOnlyMe => 'أنا فقط';

  @override
  String get settingsProfileSubtitle => 'الملف الشخصي';

  @override
  String get settingsWallpaper => 'خلفية';

  @override
  String get settingsWallpaperDesc => 'صورة الخلفية للتطبيق بالكامل';

  @override
  String get settingsWallpaperNone => 'لا شيء';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsKycVerification => 'التحقق من الهوية (KYC)';

  @override
  String get settingsOrganizations => 'المنظمات';

  @override
  String get incomingCallLabel => 'مكالمة واردة';

  @override
  String get incomingCallDecline => 'رفض';

  @override
  String get incomingCallAccept => 'قبول';

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
  String get meshIncomingCallLabel => '📡 مكالمة شبكة واردة';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'جهاز شبكة $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'أنهِ المكالمة الحالية أولاً';

  @override
  String get callPopupTransportTitle => 'اتصال عبر';

  @override
  String get callPopupTransportMesh => '📡 شبكة (نظير إلى نظير)';

  @override
  String get callPopupTransportLk => '📞 خادم';

  @override
  String get callPopupTransportMeshUnavailable =>
      'لا يمكن الوصول إلى جهة الاتصال عبر الشبكة';

  @override
  String get meshOnboardingTitle =>
      '📡 المكالمات الشبكية تحتاج إلى فتح التطبيق';

  @override
  String get meshOnboardingBody =>
      'عند قفل الهاتف، قد تنقطع المكالمات الشبكية بعد ~30 ثانية (قيود iOS).';

  @override
  String get meshOnboardingAck => 'فهمت';

  @override
  String get meshHistoryBadge => '📡 شبكة';

  @override
  String get meshHistoryNoChatAvailable => 'جهة الاتصال ليست في قائمتك';

  @override
  String get meshCallStatusInviting => 'جارٍ الاتصال…';

  @override
  String get meshCallStatusConnecting => 'جارٍ الاتصال…';

  @override
  String get meshCallEndedUserHangup => 'انتهت المكالمة';

  @override
  String get meshCallEndedRemoteHangup => 'انتهت من قبل الطرف الآخر';

  @override
  String get meshCallEndedRejected => 'مرفوضة';

  @override
  String get meshCallEndedNoAnswer => 'لا يوجد رد';

  @override
  String get meshCallEndedConnectionLost => 'تم فقد الاتصال';

  @override
  String get meshCallEndedError => 'خطأ في الاتصال';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 شبكة · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 شبكة';

  @override
  String get batteryExemptionTitle => '📡 مكالمات شبكة موثوقة';

  @override
  String get batteryExemptionBody =>
      'اسمح للتطبيق بالعمل بدون قيود البطارية حتى لا يقوم Android بإيقاف الشبكة في الخلفية.';

  @override
  String get batteryExemptionAccept => 'افتح الإعدادات';

  @override
  String get batteryExemptionDismiss => 'ليس الآن';

  @override
  String get groupCamera => 'الكاميرا';

  @override
  String get groupGallery => 'المعرض';

  @override
  String get groupAvatarUpdated => 'تم تحديث صورة المجموعة';

  @override
  String get groupNameTitle => 'اسم المجموعة';

  @override
  String get groupEnterName => 'أدخل الاسم';

  @override
  String get groupDescriptionTitle => 'وصف المجموعة';

  @override
  String get groupEnterDescription => 'أدخل وصف المجموعة';

  @override
  String get groupChangeRoleTitle => 'تغيير الدور';

  @override
  String get groupRemoveMemberTitle => 'إزالة عضو';

  @override
  String get groupDescription => 'الوصف';

  @override
  String get groupAddDescription => 'أضف وصف المجموعة';

  @override
  String get groupNoDescription => 'لا يوجد وصف';

  @override
  String get groupMediaAndFiles => 'الوسائط والملفات';

  @override
  String get groupMuteNotifications => 'كتم الإشعارات';

  @override
  String get groupMuted => 'مكتوم';

  @override
  String get groupNoResults => 'لا توجد نتائج';

  @override
  String get authInvalidCode => 'رمز غير صالح. حاول مرة أخرى.';

  @override
  String get loginSubtitle => 'استخدم البريد الإلكتروني وكلمة المرور';

  @override
  String get emailRequired => 'أدخل البريد الإلكتروني';

  @override
  String get emailInvalid => 'بريد إلكتروني غير صالح';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'حساب واحد لكل نظام Taler';

  @override
  String get usernameOptional => 'اسم المستخدم (اختياري)';

  @override
  String get usernameMinLength => 'الحد الأدنى 3 أحرف';

  @override
  String get usernameMaxLength => 'الحد الأقصى 30 حرفًا';

  @override
  String get usernameInvalid => 'فقط حروف، أرقام و _';

  @override
  String get biometricLoginReason => 'تسجيل الدخول إلى Taler ID';

  @override
  String get docTypePassport => 'جواز السفر';

  @override
  String get docTypeIdCard => 'بطاقة الهوية';

  @override
  String get docTypeDriverLicense => 'رخصة القيادة';

  @override
  String get docTypeResidencePermit => 'تصريح الإقامة';

  @override
  String addressApartment(String number) {
    return 'شقة $number';
  }

  @override
  String get failedToUpdateProfile => 'فشل في تحديث الملف الشخصي';

  @override
  String get failedToStartKyb => 'فشل في بدء التحقق KYB';

  @override
  String get orgUpdated => 'تم تحديث المنظمة';

  @override
  String get failedToUpdateOrg => 'فشل في تحديث المنظمة';

  @override
  String get failedToChangeRole => 'فشل في تغيير الدور';

  @override
  String get failedToRemoveMember => 'فشل في إزالة العضو';

  @override
  String get capabilityMessagesTitle => 'الرسائل';

  @override
  String get capabilityMessagesDesc =>
      'تحقق من الرسائل أو اكتب لشخص ما. على سبيل المثال: \"اكتب إلى فيكتور: سأكون هناك خلال ساعة\"';

  @override
  String get capabilityCallsTitle => 'المكالمات';

  @override
  String get capabilityCallsDesc =>
      'اتصل بأي جهة اتصال صوتيًا. على سبيل المثال: \"اتصل بفيكتور فيكتوروف\"';

  @override
  String get capabilityChatTitle => 'سجل الدردشة';

  @override
  String get capabilityChatDesc =>
      'سأقوم بتحليل سجل الدردشة. على سبيل المثال: \"ماذا ناقشنا مع فيكتور؟\"';

  @override
  String get capabilityProfileTitle => 'الملف الشخصي';

  @override
  String get capabilityProfileDesc =>
      'سأعرض أو أحدث ملفك الشخصي. على سبيل المثال: \"اعرض ملفي الشخصي\"';

  @override
  String get capabilityCoachingTitle => 'التدريب';

  @override
  String get capabilityCoachingDesc =>
      'الأوضاع: تدريب ICF، علم النفس، استشارة الموارد البشرية. قل: \"لنقم بالتدريب\"';

  @override
  String get capabilityCalendarTitle => 'التقويم';

  @override
  String get capabilityCalendarDesc =>
      'جدولة اجتماع أو تعيين تذكير. على سبيل المثال: \"جدول اجتماع مع فيكتور غداً الساعة 15:00\"';

  @override
  String get capabilityNotesTitle => 'الملاحظات';

  @override
  String get capabilityNotesDesc =>
      'احفظ فكرة أو اقرأ الملاحظات الأخيرة. على سبيل المثال: \"اكتب فكرة...\" أو \"اقرأ الملاحظات الأخيرة\"';

  @override
  String get assistantCallConfirm => 'إجراء مكالمة؟';

  @override
  String get callNoAnswer => 'لا يوجد رد';

  @override
  String get contactDelete => 'إزالة جهة الاتصال';

  @override
  String get contactDeleteTitle => 'إزالة جهة الاتصال';

  @override
  String get contactDeleteConfirm => 'هل أنت متأكد؟ سيتم إزالة هذه الجهة.';

  @override
  String get contactBlock => 'حظر';

  @override
  String get contactBlockTitle => 'حظر المستخدم';

  @override
  String get contactBlockConfirm =>
      'لن يتمكن هذا المستخدم من مراسلتك أو الاتصال بك.';

  @override
  String get contactUnblock => 'إلغاء الحظر';

  @override
  String get contactBlocked => 'محظور';

  @override
  String get contactYouAreBlocked => 'هذا المستخدم قام بحظرك';

  @override
  String get chatBlockedByYou => 'لقد قمت بحظر هذا المستخدم';

  @override
  String get chatYouAreBlocked => 'لقد تم حظرك من قبل هذا المستخدم';

  @override
  String get chatNotContacts =>
      'أضف هذا المستخدم إلى جهات الاتصال لتتمكن من مراسلته';

  @override
  String get contactRevokeRequest => 'إلغاء الطلب';

  @override
  String get messengerPoll => 'استطلاع';

  @override
  String get messengerCreatePoll => 'إنشاء استطلاع';

  @override
  String get messengerPollQuestion => 'السؤال';

  @override
  String messengerPollOption(int number) {
    return 'الخيار $number';
  }

  @override
  String get messengerPollAddOption => 'إضافة خيار';

  @override
  String get messengerPollAnonymous => 'تصويت مجهول';

  @override
  String get messengerPollMultiple => 'اختيار متعدد';

  @override
  String get messengerPollCreateError => 'فشل في إنشاء الاستطلاع';

  @override
  String get messengerPollUnavailable => 'الاستطلاع غير متاح';

  @override
  String get messengerPollMultipleNote => 'يمكنك اختيار عدة خيارات';

  @override
  String messengerPollVotes(int count) {
    return '$count أصوات';
  }

  @override
  String get messengerVideoMessage => 'رسالة فيديو';

  @override
  String get messengerVideoRecordError => 'خطأ في تسجيل الفيديو';

  @override
  String get messengerVideoPlaybackError => 'تعذر تشغيل الفيديو';

  @override
  String get messengerGalleryAccessError => 'لا يوجد وصول إلى المعرض';

  @override
  String get messengerSearchInChat => 'البحث في الدردشة...';

  @override
  String get messengerSaveToFavorites => 'حفظ في المفضلة';

  @override
  String get messengerSavedToFavorites => 'تم الحفظ في المفضلة';

  @override
  String get messengerSearchInMessages => 'البحث في الرسائل...';

  @override
  String messengerFoundInMessages(int count) {
    return 'تم العثور في الرسائل ($count)';
  }

  @override
  String get messengerGroupDefault => 'مجموعة';

  @override
  String get messengerUserDefault => 'مستخدم';

  @override
  String get messengerPin => 'تثبيت';

  @override
  String get messengerUnpin => 'إلغاء التثبيت';

  @override
  String get messengerArchive => 'أرشفة';

  @override
  String get messengerUnarchive => 'إلغاء الأرشفة';

  @override
  String get messengerDeleteChat => 'حذف الدردشة';

  @override
  String get messengerDeleteChatTitle => 'حذف الدردشة؟';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'حذف الدردشة مع $name؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get messengerCreateChannel => 'إنشاء قناة';

  @override
  String get messengerChannelName => 'الاسم';

  @override
  String get messengerChannelDescription => 'الوصف (اختياري)';

  @override
  String get messengerChannelCreateError => 'فشل في إنشاء القناة';

  @override
  String get messengerFilterAll => 'الكل';

  @override
  String get messengerFilterUnread => 'غير مقروء';

  @override
  String get messengerFilterPersonal => 'شخصي';

  @override
  String get messengerFilterGroups => 'المجموعات';

  @override
  String get messengerFilterChannels => 'القنوات';

  @override
  String get messengerArchivedSection => 'المؤرشفة';

  @override
  String get messengerSavedSection => 'المفضلة';

  @override
  String get messengerSavedSubtitle => 'حفظ في الذاكرة';

  @override
  String messengerArchiveTitle(int count) {
    return 'الأرشيف ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'الأرشيف فارغ';

  @override
  String messengerYouPrefix(String message) {
    return 'أنت: $message';
  }

  @override
  String get messengerMissedCall => 'مكالمة فائتة';

  @override
  String get messengerSavedTitle => 'المفضلة';

  @override
  String get messengerNoSavedMessages => 'لا توجد رسائل محفوظة';

  @override
  String get messengerSavedHint => 'اضغط مطولاً على رسالة → \"حفظ في المفضلة\"';

  @override
  String get messengerDefaultFile => 'ملف';

  @override
  String get messengerTopicDefault => 'عام';

  @override
  String get messengerTopicNew => 'موضوع جديد';

  @override
  String get messengerTopicNameHint => 'اسم الموضوع';

  @override
  String get messengerTopicIcon => 'أيقونة';

  @override
  String messengerTopicCount(int count) {
    return '$count مواضيع';
  }

  @override
  String get messengerNoTopics => 'لا توجد مواضيع';

  @override
  String get messengerNoMessages => 'لا توجد رسائل';

  @override
  String get you => 'أنت';

  @override
  String get messengerThread => 'سلسلة';

  @override
  String get messengerThreadReply => 'رد';

  @override
  String get messengerThreadReplies => 'ردود';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'لا توجد ردود';

  @override
  String get messengerReplyHint => 'الرد على السلسلة...';

  @override
  String get messengerContactName => 'اسم جهة الاتصال';

  @override
  String messengerOriginalName(String name) {
    return 'الاسم الأصلي: $name';
  }

  @override
  String get messengerDisplayName => 'اسم العرض';

  @override
  String messengerShareContact(String name) {
    return 'جهة الاتصال في Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'حذف الرسائل تلقائيًا';

  @override
  String get messengerAutoDeleteOff => 'إيقاف';

  @override
  String get messengerAutoDelete7d => '7 أيام';

  @override
  String get messengerAutoDelete30d => '30 يومًا';

  @override
  String get messengerAutoDelete90d => '90 يومًا';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count أيام';
  }

  @override
  String get messengerSettingsHeader => 'الإعدادات';

  @override
  String get messengerAdminOnly => 'النشر للإدارة فقط';

  @override
  String get messengerAdminOnlyDesc => 'يمكن للأعضاء القراءة فقط';

  @override
  String get messengerTopics => 'المواضيع';

  @override
  String get messengerTopicsDesc => 'تقسيم الدردشة إلى مواضيع';

  @override
  String get aiTwinSection => 'التوأم الصوتي AI';

  @override
  String get aiTwinEnabled => 'تفعيل التوأم AI';

  @override
  String get aiTwinEnabledDesc => 'إذا لم ترد، يتولى التوأم AI المكالمة بصوتك';

  @override
  String get aiTwinTimeout => 'مهلة الاستجابة';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String get aiTwinPrompt => 'تعليمات AI';

  @override
  String get aiTwinPromptSubtitle =>
      'كيف يجب أن يقدم التوأم AI نفسه وما الذي يجب التحدث عنه';

  @override
  String aiTwinPromptHint(String name) {
    return 'مرحبًا، هذا هو التوأم الصوتي AI لـ $name. لم يتمكن $name من الرد الآن. أخبرني من المتصل وما الموضوع — سأقوم بنقل الرسالة.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'استنساخ الصوت المخصص قادم قريبًا. حاليًا يتحدث AI بصوت $name.';
  }

  @override
  String get aiTwinDefaultName => 'المالك';

  @override
  String get aiTwinPromptReset => 'إعادة تعيين';

  @override
  String get callHistoryAiTwinAnswered => 'أجاب التوأم AI';

  @override
  String get callHistoryAiTwinSummary => 'ملخص المكالمة';

  @override
  String get callHistoryAiTwinTranscript => 'النص';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'من $name';
  }

  @override
  String get aiTwinOfferTitle => 'عدم الرد';

  @override
  String aiTwinOfferBody(String name) {
    return '$name لا يرد. هل تود ترك رسالة بصوت التوأم الذكي؟';
  }

  @override
  String get aiTwinOfferBodyUser => 'المستخدم';

  @override
  String get aiTwinOfferAccept => 'نعم، اترك رسالة';

  @override
  String get aiTwinOfferKeepWaiting => 'استمر في الانتظار';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'بديلك الذكي';

  @override
  String get aiTwinHeroSubtitle => 'يجيب على المكالمات بصوتك عندما لا تستطيع.';

  @override
  String get aiTwinProfileTitle => 'البديل الذكي';

  @override
  String get aiTwinProfileDesc => 'يجيب على المكالمات بصوتك';

  @override
  String get aiTwinBadgeOn => 'مُفعل';

  @override
  String get aiAnalystTitle => 'المحلل الذكي';

  @override
  String get aiAnalystSubtitle => 'ملفات، مهام، تحليل — Claude';

  @override
  String get channelsDiscover => 'ابحث عن قناة';

  @override
  String get channelsSearchHint => 'ابحث في القنوات';

  @override
  String get channelsSubscribers => 'مشتركين';

  @override
  String get channelsSubscribe => 'اشترك';

  @override
  String get channelsUnsubscribe => 'إلغاء الاشتراك';

  @override
  String get channelsSubscribedLabel => 'أنت مشترك';

  @override
  String get channelsSettings => 'إعدادات القناة';

  @override
  String get channelsDelete => 'حذف القناة';

  @override
  String get channelsDeleteConfirm => 'حذف القناة نهائيًا؟';

  @override
  String get channelsEmpty => 'لا توجد قنوات بعد';

  @override
  String get channelsOpen => 'افتح';

  @override
  String get channelsNameLabel => 'الاسم';

  @override
  String get channelsDescriptionLabel => 'الوصف';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'لا يمكن للمالك إلغاء الاشتراك. احذف القناة بدلاً من ذلك.';

  @override
  String get channelsNotFoundRedirect => 'القناة لم تعد موجودة';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بحوث',
      one: '$count بحث',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملفات',
      one: '$count ملف',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أوامر',
      one: '$count أمر',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صور',
      one: '$count صورة',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خطوات',
      one: '$count خطوة',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$secondsث';
  }

  @override
  String get savedTitle => 'الرسائل المحفوظة';

  @override
  String get savedSubtitle => 'سحابتك الخاصة';

  @override
  String get savedOpenError => 'تعذر فتح الرسائل المحفوظة';

  @override
  String get billingWalletTitle => 'المحفظة';

  @override
  String get billingBuyPackage => 'شراء حزمة';

  @override
  String get billingCurrentBalance => 'الرصيد الحالي';

  @override
  String get billingPackagesTitle => 'الحزم';

  @override
  String get billingPackagesUnavailable => 'الحزم غير متوفرة';

  @override
  String get billingRecentOperations => 'العمليات الأخيرة';

  @override
  String get billingAllOperations => 'جميع العمليات';

  @override
  String get billingNoOperations => 'لا توجد عمليات';

  @override
  String get billingOperationsTitle => 'العمليات';

  @override
  String get billingOperationsEmptyTitle => 'لا توجد عمليات بعد';

  @override
  String get billingOperationsEmptySubtitle =>
      'ستظهر عمليات الشحن والرسوم لميزات AI هنا';

  @override
  String get billingPricebookTitle => 'أسعار الميزات';

  @override
  String get billingPricebookUnavailable => 'قائمة الأسعار غير متوفرة';

  @override
  String get billingAiFeaturesTitle => 'ميزات AI';

  @override
  String get billingInsufficientFundsTitle => 'الأموال غير كافية';

  @override
  String get billingInsufficientFundsSubtitle =>
      'اشحن رصيدك لاستخدام هذه الميزة.';

  @override
  String billingRequiredLine(String required) {
    return 'المطلوب: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'المتوفر: $available μTAL';
  }

  @override
  String get billingTopUp => 'اشحن';

  @override
  String get billingCancel => 'إلغاء';

  @override
  String get billingRetry => 'أعد المحاولة';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'الرصيد منخفض: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'المحفظة والرصيد';

  @override
  String get billingSectionHeader => 'الفوترة وAI';

  @override
  String get billingFeatureVoiceAssistant => 'المساعد الصوتي';

  @override
  String get billingFeatureWebSearch => 'بحث الويب للمساعد';

  @override
  String get billingFeatureAiTwin => 'التوأم الصوتي';

  @override
  String get billingFeatureAiTwinLong => 'التوأم الصوتي (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'بوت المكالمات الصادرة';

  @override
  String get billingFeatureOutboundCallLong => 'بوت المكالمات الصادرة';

  @override
  String get billingFeatureWhisperTranscribe => 'نسخ المكالمات';

  @override
  String get billingFeatureMeetingSummary => 'ملخصات المكالمات AI';

  @override
  String get billingConfigureAiTwin => 'تهيئة التوأم AI';

  @override
  String get billingWebSearchSubtitle => '(يستخدمه المساعد)';

  @override
  String billingPackagePurchased(String balance) {
    return 'تم شراء الحزمة: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'موصى به';

  @override
  String get billingSessionTerminatedNoFunds => 'نفد الرصيد - انتهت الجلسة';

  @override
  String get billingSessionTerminatedGeneric => 'انتهت جلسة المساعد';

  @override
  String billingBuyForPrice(String price) {
    return 'اشترِ مقابل €$price';
  }

  @override
  String get billingTxTypeTopup => 'شحن';

  @override
  String get billingTxTypeRefund => 'استرداد';

  @override
  String get billingTxTypeSpend => 'رسوم';

  @override
  String get billingUnitMinute => 'دقيقة';

  @override
  String get billingUnitRequest => 'طلب';

  @override
  String get billingUnitToken => 'رمز';

  @override
  String get billingUnitTokens1k => '1K رموز';

  @override
  String get billingUnitCall => 'مكالمة';

  @override
  String get groupCallSelectParticipants => 'اختر المشاركين';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'بحث';

  @override
  String get groupCallMaxReached => 'الحد الأقصى 7 مشاركين';

  @override
  String get groupCallLobbyTitle => 'مجموعة • اللوبي';

  @override
  String groupCallHostLabel(String name) {
    return 'المضيف: $name';
  }

  @override
  String get groupCallMicHint => 'سيتم تفعيل الميكروفون عند الاتصال';

  @override
  String get groupCallCancel => 'إلغاء';

  @override
  String get groupCallNoAnswer => 'لم يجب أحد';

  @override
  String get groupCallEndedByHost => 'انتهت المكالمة بواسطة المضيف';

  @override
  String get groupCallAllLeft => 'غادر الجميع المكالمة';

  @override
  String get groupCallEnded => 'انتهت المكالمة';

  @override
  String groupCallActiveTitle(int count) {
    return 'مجموعة • $count';
  }

  @override
  String get groupCallConnectionLost => 'تم فقدان الاتصال';

  @override
  String get groupCallMuteRequested => 'طلب المضيف من الجميع كتم الصوت';

  @override
  String get groupCallUnmute => 'إلغاء كتم الصوت';

  @override
  String get groupCallMute => 'كتم الصوت';

  @override
  String get groupCallMuteAll => 'كتم الجميع';

  @override
  String get groupCallLeave => 'مغادرة';

  @override
  String get groupCallStatusCalling => 'يتصل…';

  @override
  String get groupCallStatusDeclined => 'مرفوض';

  @override
  String get groupCallStatusTimeout => 'لا إجابة';

  @override
  String get groupCallStatusLeft => 'غادر';

  @override
  String groupCallKickConfirm(String name) {
    return 'إزالة $name من المكالمة';
  }

  @override
  String get groupCallCancelAction => 'إلغاء';

  @override
  String get groupCallActiveBanner => 'مكالمة نشطة';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'مجموعة: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'مجموعة: $host';
  }

  @override
  String get groupCallCreateError => 'تعذر إنشاء المكالمة';

  @override
  String get groupCallJoinError => 'تعذر الانضمام إلى المكالمة';

  @override
  String get groupCallLivekitError => 'خطأ في LiveKit';

  @override
  String get groupCallDone => 'تم';

  @override
  String get groupCallNoResults => 'لا توجد نتائج';

  @override
  String get groupCallNoContacts => 'لا توجد جهات اتصال';

  @override
  String get meshGcContactOffline => 'غير متصل على هذا الواي فاي';

  @override
  String get meshGcOnlineViaMesh => 'متصل عبر الشبكة';

  @override
  String get meshGcMaxInvitees =>
      'المكالمات الجماعية تدعم حتى 4 مدعوين (5 أشخاص إجمالاً).';

  @override
  String get meshGcStart => 'ابدأ مكالمة جماعية';

  @override
  String get meshGcCancel => 'إلغاء';

  @override
  String get meshGcStatusCalling => 'جارٍ الاتصال…';

  @override
  String get meshGcStatusJoined => 'انضم';

  @override
  String get meshGcStatusDeclined => 'مرفوض';

  @override
  String get meshGcStatusNoAnswer => 'لا يوجد رد';

  @override
  String get meshGcStatusConnectionFailed => 'فشل الاتصال';

  @override
  String get meshGcStatusLeft => 'غادر';

  @override
  String get meshGcTopTitle => 'شبكة';

  @override
  String get meshGcBusyOneOnOne => 'أنهِ مكالمتك الحالية أولاً.';

  @override
  String get presenceOnline => 'متصل';

  @override
  String get presenceLastSeenJustNow => 'آخر ظهور الآن';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'آخر ظهور منذ $minutes دقيقة';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'آخر ظهور اليوم في $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'آخر ظهور أمس في $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'آخر ظهور في $date';
  }

  @override
  String get presenceLastSeenRecently => 'آخر ظهور مؤخراً';

  @override
  String get privacySectionTitle => 'الخصوصية';

  @override
  String get privacyLastSeenLabel => 'من يرى وقت آخر ظهور لك';

  @override
  String get privacyEveryone => 'الجميع';

  @override
  String get privacyContacts => 'جهات الاتصال فقط';

  @override
  String get privacyNobody => 'لا أحد';

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
