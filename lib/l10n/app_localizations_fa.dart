// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'جستجو';

  @override
  String get appSubtitle => 'هویت یکپارچه اکوسیستم';

  @override
  String get login => 'ورود';

  @override
  String get loginButton => 'ورود';

  @override
  String get register => 'ایجاد حساب';

  @override
  String get registerButton => 'ایجاد حساب';

  @override
  String get email => 'ایمیل';

  @override
  String get password => 'رمز عبور';

  @override
  String get confirmPassword => 'تأیید رمز عبور';

  @override
  String get firstName => 'نام';

  @override
  String get lastName => 'نام خانوادگی';

  @override
  String get noAccount => 'حساب کاربری ندارید؟';

  @override
  String get createOne => 'ایجاد کنید';

  @override
  String get haveAccount => 'حساب کاربری دارید؟';

  @override
  String get signIn => 'ورود';

  @override
  String get passwordMinLength => 'حداقل ۸ کاراکتر';

  @override
  String get invalidEmail => 'ایمیل معتبر وارد کنید';

  @override
  String get fieldRequired => 'فیلد الزامی';

  @override
  String get twoFATitle => 'احراز هویت دو مرحله‌ای';

  @override
  String get twoFASubtitle => 'کد ۶ رقمی از برنامه احراز هویت خود را وارد کنید';

  @override
  String get twoFACode => 'کد 2FA';

  @override
  String get verify => 'تأیید';

  @override
  String get tabProfile => 'پروفایل';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'سازمان';

  @override
  String get tabSettings => 'تنظیمات';

  @override
  String get profile => 'پروفایل';

  @override
  String get editProfile => 'ویرایش پروفایل';

  @override
  String get phone => 'تلفن';

  @override
  String get country => 'کشور';

  @override
  String get dateOfBirth => 'تاریخ تولد';

  @override
  String get documents => 'مدارک';

  @override
  String get addDocument => 'افزودن مدرک';

  @override
  String get noDocuments => 'مدرکی بارگذاری نشده است';

  @override
  String get save => 'ذخیره';

  @override
  String get profileUpdated => 'پروفایل به‌روزرسانی شد';

  @override
  String get personalData => 'اطلاعات شخصی';

  @override
  String get passport => 'پاسپورت';

  @override
  String get drivingLicense => 'گواهینامه رانندگی';

  @override
  String get diploma => 'دیپلم';

  @override
  String get nationalId => 'کارت ملی';

  @override
  String get certificate => 'گواهینامه';

  @override
  String get notSpecified => 'مشخص نشده';

  @override
  String get notSpecifiedFemale => 'مشخص نشده';

  @override
  String get documentType => 'نوع سند';

  @override
  String get passportId => 'پاسپورت / کارت شناسایی';

  @override
  String get diplomaCertificate => 'دیپلم / گواهینامه';

  @override
  String get loadError => 'خطا در بارگذاری';

  @override
  String get verification => 'تأیید';

  @override
  String get countryAustria => 'اتریش';

  @override
  String get countryGermany => 'آلمان';

  @override
  String get countryRussia => 'روسیه';

  @override
  String get countryUkraine => 'اوکراین';

  @override
  String get countryKazakhstan => 'قزاقستان';

  @override
  String get countryBelarus => 'بلاروس';

  @override
  String get countryOther => 'سایر';

  @override
  String get kycTitle => 'تأیید KYC';

  @override
  String get kycVerified => 'تأیید شده';

  @override
  String get kycPending => 'در انتظار';

  @override
  String get kycRejected => 'رد شده';

  @override
  String get kycUnverified => 'تأیید نشده';

  @override
  String get kycVerifiedDesc =>
      'هویت شما تأیید شده است. شما به تمامی ویژگی‌های اکوسیستم Taler دسترسی کامل دارید.';

  @override
  String get kycPendingDesc =>
      'مدارک شما در حال بررسی است. این فرآیند معمولاً ۱-۲ روز کاری طول می‌کشد.';

  @override
  String get kycRejectedDesc =>
      'تأیید ناموفق بود. لطفاً دلیل را بررسی کرده و مدارک خود را دوباره ارسال کنید.';

  @override
  String get kycUnverifiedDesc =>
      'برای دسترسی کامل به ویژگی‌های مالی اکوسیستم Taler، تأیید را کامل کنید.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'شروع تأیید';

  @override
  String get retryVerification => 'تلاش مجدد برای تأیید';

  @override
  String verifiedAt(String date) {
    return 'تأیید شده: $date';
  }

  @override
  String get documentsSubmitted => 'مدارک برای بررسی ارسال شد';

  @override
  String get documentsSubmittedDesc =>
      'بررسی معمولاً ۱-۲ روز کاری طول می‌کشد. شما یک اعلان فشاری با نتیجه دریافت خواهید کرد.';

  @override
  String get securityAes => 'داده‌های شما با رمزگذاری AES-256 محافظت می‌شود';

  @override
  String get verificationTime => 'تأیید ۱-۲ روز کاری طول می‌کشد';

  @override
  String get pushNotification =>
      'شما یک اعلان فشاری با نتیجه دریافت خواهید کرد';

  @override
  String get kycWebOnly => 'تأیید KYC فقط در اپلیکیشن موبایل در دسترس است.';

  @override
  String verificationError(String code) {
    return 'خطای تأیید: $code';
  }

  @override
  String get organizations => 'سازمان‌ها';

  @override
  String get noOrganizations => 'هیچ سازمانی وجود ندارد';

  @override
  String get noOrganizationsDesc =>
      'یک سازمان ایجاد کنید یا دعوت‌نامه‌ای را بپذیرید';

  @override
  String get createOrganization => 'ایجاد سازمان';

  @override
  String get newOrganization => 'سازمان جدید';

  @override
  String get orgName => 'نام *';

  @override
  String get orgDescription => 'توضیحات';

  @override
  String get orgEmail => 'ایمیل تماس';

  @override
  String get orgWebsite => 'وب‌سایت';

  @override
  String get orgLegalAddress => 'آدرس قانونی';

  @override
  String get create => 'ایجاد';

  @override
  String get organization => 'سازمان';

  @override
  String get contacts => 'مخاطبین';

  @override
  String members(int count) {
    return 'اعضا ($count)';
  }

  @override
  String get inviteMember => 'دعوت عضو';

  @override
  String get invite => 'دعوت';

  @override
  String get sendInvite => 'ارسال دعوت‌نامه';

  @override
  String inviteSent(String email) {
    return 'دعوت‌نامه به $email ارسال شد';
  }

  @override
  String get role => 'نقش';

  @override
  String get roleOwner => 'مالک';

  @override
  String get roleAdmin => 'مدیر';

  @override
  String get roleOperator => 'اپراتور';

  @override
  String get roleViewer => 'مشاهده‌گر';

  @override
  String get editOrganization => 'ویرایش';

  @override
  String get editOrganizationTitle => 'ویرایش سازمان';

  @override
  String get removeMember => 'حذف عضو';

  @override
  String removeMemberConfirm(String name) {
    return 'آیا $name از سازمان حذف شود؟';
  }

  @override
  String get memberRemoved => 'عضو حذف شد';

  @override
  String get roleChanged => 'نقش تغییر کرد';

  @override
  String get kybVerified => 'تأیید شده';

  @override
  String get kybPending => 'در انتظار';

  @override
  String get kybRejected => 'رد شده';

  @override
  String get kybNone => 'تأیید نشده';

  @override
  String get kybVerification => 'شروع تأیید KYB';

  @override
  String get kybStartBusiness => 'شروع تأیید کسب‌وکار';

  @override
  String get kybStatusLabel => 'وضعیت KYB';

  @override
  String get noKyb => 'بدون KYB';

  @override
  String get kybBusinessVerificationTitle => 'تأیید کسب‌وکار (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'سازمان با موفقیت تأیید شد.';

  @override
  String get kybPendingOrgDesc =>
      'مدارک در حال بررسی هستند. این معمولاً ۱-۳ روز کاری طول می‌کشد.';

  @override
  String get kybRejectedOrgDesc => 'تأیید ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get kybNoneOrgDesc =>
      'سازمان خود را تأیید کنید تا به ویژگی‌های کسب‌وکار دسترسی پیدا کنید.';

  @override
  String get invitePlus => '+ دعوت';

  @override
  String get kybVerificationTitle => 'تأیید KYB';

  @override
  String get kybWebOnlyBusiness =>
      'تأیید KYB فقط در اپلیکیشن موبایل موجود است.';

  @override
  String get unknownDevice => 'دستگاه ناشناس';

  @override
  String get ipUnknown => 'IP ناشناس';

  @override
  String get currentSessionLabel => 'فعلی';

  @override
  String get endSessionAction => 'پایان';

  @override
  String get deviceLoggedOut => 'دستگاه خارج خواهد شد.';

  @override
  String get acceptInvitationTitle => 'دعوت‌نامه سازمان';

  @override
  String get acceptInvitation => 'قبول دعوت‌نامه';

  @override
  String get acceptInvitationDesc =>
      'شما به پیوستن به یک سازمان در اکوسیستم Taler دعوت شده‌اید.';

  @override
  String get accept => 'قبول';

  @override
  String get reject => 'رد';

  @override
  String get sessions => 'جلسات فعال';

  @override
  String get currentSession => 'جلسه فعلی';

  @override
  String get deleteSession => 'پایان جلسه';

  @override
  String get deleteSessionConfirm => 'این جلسه پایان یابد؟';

  @override
  String get sessionDeleted => 'جلسه پایان یافت';

  @override
  String get noSessions => 'هیچ جلسه فعالی وجود ندارد';

  @override
  String minutesAgo(int count) {
    return '$count دقیقه پیش';
  }

  @override
  String hoursAgo(int count) {
    return '$count ساعت پیش';
  }

  @override
  String daysAgo(int count) {
    return '$count روز پیش';
  }

  @override
  String get justNow => 'همین حالا';

  @override
  String get settings => 'تنظیمات';

  @override
  String get security => 'امنیت';

  @override
  String get biometrics => 'بیومتریک';

  @override
  String get biometricsDesc => 'ورود سریع با Face ID یا اثر انگشت';

  @override
  String get biometricsConfirm =>
      'برای فعال‌سازی ورود سریع، بیومتریک را تأیید کنید';

  @override
  String get biometricsError =>
      'فعال‌سازی بیومتریک ناموفق بود. تنظیمات دستگاه را بررسی کنید.';

  @override
  String get changePassword => 'تغییر رمز عبور';

  @override
  String get twoFactorAuth => 'احراز هویت دو مرحله‌ای';

  @override
  String get currentPassword => 'رمز عبور فعلی';

  @override
  String get newPassword => 'رمز عبور جدید';

  @override
  String get confirmNewPassword => 'تأیید رمز عبور جدید';

  @override
  String get passwordChanged => 'رمز عبور تغییر کرد';

  @override
  String get wrongCurrentPassword => 'رمز عبور فعلی اشتباه است';

  @override
  String get passwordTooWeak =>
      'رمز عبور ضعیف است: حداقل ۸ کاراکتر، حرف و عدد لازم است';

  @override
  String get passwordChangeFailed => 'تغییر رمز عبور ناموفق بود';

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get permissions => 'مجوزها';

  @override
  String get permissionNotifications => 'اعلان‌های فشاری';

  @override
  String get permissionNotificationsDesc => 'تماس‌ها، پیام‌ها، وضعیت‌ها';

  @override
  String get permissionMicrophone => 'میکروفون';

  @override
  String get permissionMicrophoneDesc => 'تماس‌ها و دستیار صوتی';

  @override
  String get permissionCamera => 'دوربین';

  @override
  String get permissionCameraDesc => 'تماس‌های ویدیویی و تأیید هویت';

  @override
  String get permissionLocation => 'موقعیت';

  @override
  String get permissionLocationDesc => 'استفاده برای تأیید هویت';

  @override
  String get permissionOpenSettings =>
      'برای لغو مجوز، تنظیمات سیستم را باز کنید';

  @override
  String get pushKycStatus => 'وضعیت KYC';

  @override
  String get pushKycStatusDesc => 'نتیجه تأیید هویت';

  @override
  String get pushLogins => 'ورود به سیستم';

  @override
  String get pushLoginsDesc => 'هنگام ورود از دستگاه جدید';

  @override
  String get account => 'حساب';

  @override
  String get language => 'زبان';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'زبان رابط کاربری';

  @override
  String get exportData => 'صادرات داده (GDPR)';

  @override
  String get deleteAccount => 'حذف حساب';

  @override
  String get deleteAccountConfirm => 'حساب حذف شود؟';

  @override
  String get deleteAccountDesc =>
      'تمام داده‌های شما حذف خواهد شد (GDPR). این عمل غیرقابل بازگشت است.';

  @override
  String get logout => 'خروج';

  @override
  String get logoutConfirm => 'خروج انجام شود؟';

  @override
  String get logoutDesc => 'شما از Taler ID در این دستگاه خارج خواهید شد.';

  @override
  String version(String version) {
    return 'Taler ID نسخه $version';
  }

  @override
  String get pinCode => 'کد PIN';

  @override
  String get pinCodeDesc => 'ورود سریع با کد ۴ رقمی';

  @override
  String get setupPin => 'تنظیم کد PIN';

  @override
  String get enterPin => 'وارد کردن کد PIN';

  @override
  String get confirmPin => 'تأیید کد PIN';

  @override
  String get pinMismatch => 'کدهای PIN مطابقت ندارند';

  @override
  String get passwordMismatch => 'رمزهای عبور مطابقت ندارند';

  @override
  String get pinSet => 'کد PIN با موفقیت تنظیم شد';

  @override
  String get enterPinToLogin => 'برای ورود کد PIN را وارد کنید';

  @override
  String get pinIncorrect => 'کد PIN نادرست است';

  @override
  String get removePin => 'حذف کد PIN';

  @override
  String get pinRemoved => 'کد PIN حذف شد';

  @override
  String get cancel => 'لغو';

  @override
  String get delete => 'حذف';

  @override
  String get ok => 'باشه';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get loading => 'در حال بارگذاری...';

  @override
  String get error => 'خطا';

  @override
  String get success => 'موفقیت';

  @override
  String get noData => 'بدون داده';

  @override
  String get failedToLoad => 'بارگذاری داده‌ها ناموفق بود';

  @override
  String get failedToLoadProfile => 'بارگذاری پروفایل ناموفق بود';

  @override
  String get failedToSave => 'ذخیره تغییرات ناموفق بود';

  @override
  String get failedToLoadOrgs => 'بارگذاری سازمان‌ها ناموفق بود';

  @override
  String get failedToLoadOrg => 'بارگذاری داده‌های سازمان ناموفق بود';

  @override
  String get failedToCreateOrg => 'ایجاد سازمان ناموفق بود';

  @override
  String get failedToInvite => 'ارسال دعوت‌نامه ناموفق بود';

  @override
  String get failedToAcceptInvite => 'پذیرش دعوت‌نامه ناموفق بود';

  @override
  String get failedToLoadSessions => 'بارگذاری جلسات ناموفق بود';

  @override
  String get failedToDeleteSession => 'پایان جلسه ناموفق بود';

  @override
  String get failedToLoadKyc => 'بارگذاری وضعیت تأیید ناموفق بود';

  @override
  String get failedToStartKyc => 'شروع تأیید ناموفق بود';

  @override
  String get verifiedPersonalInfo => 'داده‌های تأیید شده';

  @override
  String get middleName => 'نام میانی';

  @override
  String get placeOfBirth => 'محل تولد';

  @override
  String get nationality => 'ملیت';

  @override
  String get gender => 'جنسیت';

  @override
  String get genderMale => 'مرد';

  @override
  String get genderFemale => 'زن';

  @override
  String get docNumber => 'شماره';

  @override
  String get docIssuedDate => 'تاریخ صدور';

  @override
  String get docValidUntil => 'معتبر تا';

  @override
  String get docIssuedBy => 'صادر کننده';

  @override
  String get address => 'آدرس';

  @override
  String get refreshData => 'تازه‌سازی داده‌ها';

  @override
  String get failedToLoadSumsubData => 'بارگذاری داده‌های تأیید ناموفق بود';

  @override
  String get sumsubDataLoading => 'در حال بارگذاری داده‌های تأیید...';

  @override
  String get reviewResultGreen => 'تأیید موفقیت‌آمیز بود';

  @override
  String get reviewResultRed => 'تأیید ناموفق بود';

  @override
  String get tabAssistant => 'دستیار';

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
  String get assistantConnecting => 'در حال اتصال...';

  @override
  String get assistantSpeaking => 'در حال صحبت...';

  @override
  String get assistantListening => 'در حال گوش دادن...';

  @override
  String get assistantTapToStart => 'برای شروع ضربه بزنید';

  @override
  String get assistantTapToTalk => 'برای صحبت با AI ضربه بزنید';

  @override
  String get assistantRealtimeDesc =>
      'دستیار به صورت همزمان با صدا پاسخ می‌دهد';

  @override
  String get assistantConnectingToAssistant => 'در حال اتصال به دستیار...';

  @override
  String get assistantAiSpeaking => 'در حال صحبت کردن AI...';

  @override
  String get assistantAiListening => 'در حال گوش دادن AI';

  @override
  String get assistantSpeakerOn => 'بلندگو روشن';

  @override
  String get assistantSpeaker => 'بلندگو';

  @override
  String get assistantEnd => 'پایان';

  @override
  String get assistantUnmute => 'غیر بی‌صدا';

  @override
  String get assistantMicrophone => 'میکروفون';

  @override
  String get assistantConnectionError => 'خطای اتصال';

  @override
  String get tabMessenger => 'پیام‌ها';

  @override
  String get tabCalls => 'تماس‌ها';

  @override
  String get tabCalendar => 'تقویم';

  @override
  String get appearance => 'ظاهر';

  @override
  String get appearanceSelect => 'انتخاب تم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get onboardingTitle1 => 'هویت یکپارچه';

  @override
  String get onboardingDesc1 =>
      'Taler ID گذرنامه دیجیتال شما در اکوسیستم Taler است. یک حساب برای همه خدمات.';

  @override
  String get onboardingTitle2 => 'امنیت داده';

  @override
  String get onboardingDesc2 =>
      'تأیید KYC، رمزگذاری AES-256 و احراز هویت دو مرحله‌ای از هویت شما محافظت می‌کنند.';

  @override
  String get onboardingTitle3 => 'مطلع بمانید';

  @override
  String get onboardingDesc3 =>
      'از وضعیت تأیید، ورود از دستگاه‌های جدید و تماس‌های ورودی مطلع شوید.';

  @override
  String get onboardingNext => 'بعدی';

  @override
  String get onboardingEnableNotifications => 'فعال‌سازی اعلان‌ها';

  @override
  String get onboardingTitle4 => 'تماس‌های صوتی';

  @override
  String get onboardingDesc4 =>
      'دسترسی به میکروفون را برای تماس‌های صوتی و دستیار AI اعطا کنید. می‌توانید این تنظیمات را بعداً تغییر دهید.';

  @override
  String get onboardingEnableMicrophone => 'فعال‌سازی میکروفون';

  @override
  String get onboardingStart => 'شروع کنید';

  @override
  String get onboardingSkip => 'رد کردن';

  @override
  String get meshLocalNetworkPromptTitle => 'اجازه دسترسی به شبکه محلی';

  @override
  String get meshLocalNetworkPromptBody =>
      'برای یافتن همتایان در Wi-Fi (تماس‌های گروهی آفلاین)، iOS نیاز به مجوز شبکه محلی دارد. تنظیمات را باز کنید → حریم خصوصی و امنیت → شبکه محلی → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'باز کردن تنظیمات';

  @override
  String get meshLocalNetworkPromptDismiss => 'متوجه شدم';

  @override
  String get forgotPassword => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get forgotPasswordTitle => 'بازنشانی رمز عبور';

  @override
  String get forgotPasswordSubtitle =>
      'ایمیل خود را وارد کنید تا کد بازنشانی دریافت کنید';

  @override
  String resetCodeSent(String email) {
    return 'کد به $email ارسال شد';
  }

  @override
  String get enterResetCode => 'کد را وارد کنید';

  @override
  String get resetPasswordButton => 'بازنشانی رمز عبور';

  @override
  String get passwordResetSuccess => 'رمز عبور با موفقیت بازنشانی شد';

  @override
  String get sendCode => 'ارسال کد';

  @override
  String get resendCode => 'ارسال مجدد کد';

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
  String get newGroup => 'گروه جدید';

  @override
  String get newChat => 'چت جدید';

  @override
  String get groupName => 'نام گروه';

  @override
  String get createGroup => 'ایجاد گروه';

  @override
  String get groupInfo => 'اطلاعات گروه';

  @override
  String groupMembers(int count) {
    return 'اعضا ($count)';
  }

  @override
  String get addMembers => 'افزودن اعضا';

  @override
  String get leaveGroup => 'ترک گروه';

  @override
  String get leaveGroupConfirm => 'این گروه را ترک کنید؟';

  @override
  String get deleteGroup => 'حذف گروه';

  @override
  String get deleteGroupConfirm =>
      'این گروه حذف شود؟ این عمل قابل بازگشت نیست.';

  @override
  String get groupRoleOwner => 'مالک';

  @override
  String get groupRoleAdmin => 'مدیر';

  @override
  String get groupRoleMember => 'عضو';

  @override
  String get selectParticipants => 'انتخاب شرکت‌کنندگان';

  @override
  String selectedCount(int count) {
    return '$count انتخاب شده';
  }

  @override
  String get changeRole => 'تغییر نقش';

  @override
  String get groupCreated => 'گروه ایجاد شد';

  @override
  String memberJoined(String name) {
    return '$name پیوست';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name گروه را ترک کرد';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name حذف شد';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name اکنون $role است';
  }

  @override
  String participantsCount(int count) {
    return '$count شرکت‌کننده';
  }

  @override
  String get enterGroupName => 'نام گروه را وارد کنید';

  @override
  String get muteNotifications => 'بی‌صدا کردن اعلان‌ها';

  @override
  String get unmuteNotifications => 'لغو بی‌صدا کردن اعلان‌ها';

  @override
  String get muteFor1Hour => 'برای ۱ ساعت';

  @override
  String get muteFor8Hours => 'برای ۸ ساعت';

  @override
  String get muteFor2Days => 'برای ۲ روز';

  @override
  String get muteForever => 'برای همیشه';

  @override
  String get muted => 'بی‌صدا شد';

  @override
  String get tabTranslator => 'ترجمه';

  @override
  String get translatorTitle => 'مترجم';

  @override
  String get translatorSelectLanguage => 'انتخاب زبان';

  @override
  String get translatorDownloading => 'در حال دانلود مدل‌های زبان...';

  @override
  String get translatorDownloadingHint =>
      'اینترنت فقط برای اولین دانلود نیاز است';

  @override
  String get translatorTypeHint => 'متن را تایپ کنید یا میکروفون را لمس کنید';

  @override
  String get translatorListening => 'در حال گوش دادن...';

  @override
  String get translatorTapToSpeak => 'برای صحبت کردن ضربه بزنید';

  @override
  String get translatorTapToStop => 'برای توقف ضربه بزنید';

  @override
  String get translatorAutoSpeak => 'پخش خودکار';

  @override
  String get translatorCopied => 'کپی شد';

  @override
  String get translatorLangRu => 'روسی';

  @override
  String get translatorLangEn => 'انگلیسی';

  @override
  String get translatorLangDe => 'آلمانی';

  @override
  String get translatorLangFr => 'فرانسوی';

  @override
  String get translatorLangEs => 'اسپانیایی';

  @override
  String get translatorLangIt => 'ایتالیایی';

  @override
  String get translatorLangPt => 'پرتغالی';

  @override
  String get translatorLangTr => 'ترکی';

  @override
  String get translatorLangZh => 'چینی';

  @override
  String get translatorLangJa => 'ژاپنی';

  @override
  String get translatorLangKo => 'کره‌ای';

  @override
  String get translatorLangAr => 'عربی';

  @override
  String get translatorLangPl => 'لهستانی';

  @override
  String get translatorLangSk => 'اسلواکی';

  @override
  String get translatorLangCs => 'چکی';

  @override
  String get translatorLangNl => 'هلندی';

  @override
  String get translatorLangSv => 'سوئدی';

  @override
  String get translatorLangDa => 'دانمارکی';

  @override
  String get translatorLangNo => 'نروژی';

  @override
  String get translatorLangFi => 'فنلاندی';

  @override
  String get translatorLangUk => 'اوکراینی';

  @override
  String get translatorLangEl => 'یونانی';

  @override
  String get translatorLangRo => 'رومانیایی';

  @override
  String get translatorLangHu => 'مجاری';

  @override
  String get translatorLangBg => 'بلغاری';

  @override
  String get translatorLangHr => 'کرواتی';

  @override
  String get translatorLangSr => 'صربی';

  @override
  String get translatorLangHi => 'هندی';

  @override
  String get translatorLangTh => 'تایلندی';

  @override
  String get translatorLangVi => 'ویتنامی';

  @override
  String get translatorLangId => 'اندونزیایی';

  @override
  String get translatorLangMs => 'مالایی';

  @override
  String get translatorLangHe => 'عبری';

  @override
  String get translatorLangFa => 'فارسی';

  @override
  String get callInProgress => 'تماس در حال انجام';

  @override
  String get joinCall => 'پیوستن';

  @override
  String get createCallLink => 'لینک تماس';

  @override
  String get callLinkCopied => 'لینک کپی شد';

  @override
  String get callLinkTitle => 'لینک اتاق';

  @override
  String get connectionUnstable => 'اتصال ناپایدار — اینترنت خود را بررسی کنید';

  @override
  String get today => 'امروز';

  @override
  String get yesterday => 'دیروز';

  @override
  String get errorTimeout => 'اتصال قطع شد. اتصال اینترنت خود را بررسی کنید.';

  @override
  String get errorNoConnection => 'بدون اتصال به اینترنت.';

  @override
  String get errorGeneral => 'خطایی رخ داده است. لطفاً دوباره تلاش کنید.';

  @override
  String errorWithMessage(String message) {
    return 'خطا: $message';
  }

  @override
  String get notifChannelMessages => 'پیام‌ها';

  @override
  String get notifChannelMessagesDesc => 'اعلان‌های پیام جدید';

  @override
  String get notifChannelMissedCalls => 'تماس‌های از دست رفته';

  @override
  String get notifChannelMissedCallsDesc => 'اعلان‌های تماس از دست رفته';

  @override
  String get notifMissedCall => 'تماس از دست رفته';

  @override
  String get notifAccept => 'پذیرفتن';

  @override
  String get notifDecline => 'رد کردن';

  @override
  String get notifIncomingCall => 'تماس ورودی';

  @override
  String get notifIncomingCallChannel => 'تماس ورودی';

  @override
  String get notifMissedCallChannel => 'تماس از دست رفته';

  @override
  String get notifUnknown => 'ناشناخته';

  @override
  String get effectNone => 'بدون پس‌زمینه';

  @override
  String get effectBlur => 'تاری';

  @override
  String get effectOffice => 'دفتر';

  @override
  String get effectNature => 'طبیعت';

  @override
  String get effectGradient => 'گرادیان';

  @override
  String get effectLibrary => 'کتابخانه';

  @override
  String get effectCity => 'شهر';

  @override
  String get effectMinimalism => 'مینیمالیسم';

  @override
  String get voiceParticipant => 'شرکت‌کننده';

  @override
  String get voiceInvitesToRoom => 'شما را به اتاق دعوت می‌کند';

  @override
  String get voiceRoom => 'اتاق';

  @override
  String get voicePasswordProtected => 'محافظت شده با رمز عبور';

  @override
  String get voicePasswordHint => 'رمز عبور';

  @override
  String get voiceEnter => 'ورود';

  @override
  String get voiceJoinRoom => 'پیوستن به اتاق';

  @override
  String get voiceYourName => 'نام شما';

  @override
  String voiceInvitationSent(String name) {
    return 'دعوت‌نامه به $name ارسال شد';
  }

  @override
  String get voiceNoActiveRoom => 'اتاق فعال وجود ندارد';

  @override
  String get voiceCameraPermission =>
      'دسترسی به دوربین را در تنظیمات → حریم خصوصی → دوربین → TalerID فعال کنید';

  @override
  String get voiceOpenSettings => 'باز کردن';

  @override
  String voiceCameraError(String error) {
    return 'فعال‌سازی دوربین ناموفق بود: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'همه موافقت کردند. ضبط شروع شد.';

  @override
  String get voiceNewParticipantAgreed => 'شرکت‌کننده جدید با ضبط موافقت کرد.';

  @override
  String get voiceDeclinedRecording => 'شما ضبط را رد کردید. در حال ترک تماس.';

  @override
  String get voiceRecordingEnded => 'ضبط پایان یافت';

  @override
  String get voiceRecordingInProgress => 'ضبط در حال انجام';

  @override
  String get voiceTranscriptionRequest => 'درخواست رونویسی';

  @override
  String get voiceRecordingRequest => 'درخواست ضبط';

  @override
  String get voiceAgree => 'موافقت';

  @override
  String get voiceDeclineAndLeave => 'رد و ترک';

  @override
  String get voiceAudioOutput => 'خروجی صدا';

  @override
  String get voiceAudioPhone => 'تلفن';

  @override
  String get voiceAudioSpeaker => 'بلندگو';

  @override
  String get voiceAudioBluetooth => 'بلوتوث';

  @override
  String get voiceAudioHeadphones => 'هدفون';

  @override
  String get voiceLinkCopied => 'لینک کپی شد';

  @override
  String get voiceTranslateTo => 'ترجمه به';

  @override
  String get voiceSearchLanguage => 'جستجوی زبان...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'اتاق $name';
  }

  @override
  String get voiceVoiceCall => 'تماس صوتی';

  @override
  String get voiceOnHold => 'در انتظار';

  @override
  String get voiceActiveCall => 'فعال';

  @override
  String get voiceEndAllCalls => 'پایان همه تماس‌ها';

  @override
  String get voiceEndThisCall => 'پایان این تماس';

  @override
  String get voiceCopyLink => 'کپی لینک';

  @override
  String get voiceAddParticipant => 'افزودن شرکت‌کننده';

  @override
  String get voiceReconnecting => 'در حال اتصال مجدد...';

  @override
  String get voiceConnectionError => 'خطای اتصال';

  @override
  String get voiceClose => 'بستن';

  @override
  String get voiceCalling => 'در حال تماس...';

  @override
  String get voiceCallActive => 'تماس فعال';

  @override
  String get voiceWaiting => 'در انتظار';

  @override
  String get voiceWaitingUpper => 'در انتظار';

  @override
  String get voiceRec => 'ضبط';

  @override
  String get voiceStop => 'توقف';

  @override
  String get voiceRecord => 'ضبط';

  @override
  String get voiceTranslation => 'ترجمه';

  @override
  String get voiceAudio => 'صوت';

  @override
  String get voiceFlipCamera => 'چرخش';

  @override
  String get voiceBackground => 'پس‌زمینه';

  @override
  String get voiceAssistantSpeakingStatus => 'دستیار در حال صحبت...';

  @override
  String get voiceAssistantListeningStatus => 'دستیار در حال گوش دادن...';

  @override
  String get voiceUnmute => 'لغو بی‌صدا';

  @override
  String get voiceMic => 'میکروفون';

  @override
  String get voiceAssistantLabel => 'دستیار';

  @override
  String get voiceCameraOn => 'دوربین روشن';

  @override
  String get voiceCameraLabel => 'دوربین';

  @override
  String get voiceEndCall => 'پایان تماس';

  @override
  String get voiceWaitingParticipants => 'در انتظار شرکت‌کنندگان...';

  @override
  String get voiceYou => 'شما';

  @override
  String get voiceAiAssistant => 'دستیار AI';

  @override
  String get voiceVideoUnavailable => 'ویدیو در دسترس نیست';

  @override
  String get voiceSearchNickname => 'جستجو بر اساس نام مستعار...';

  @override
  String get voiceTranscriptionWord => 'رونویسی';

  @override
  String get voiceRecordingWord => 'ضبط';

  @override
  String get voiceConnecting => 'در حال اتصال...';

  @override
  String get voiceVideoBackground => 'پس‌زمینه ویدیو';

  @override
  String get voiceCallSettings => 'تنظیمات تماس';

  @override
  String get voiceEnableAI => 'فعال‌سازی دستیار AI';

  @override
  String get voiceAIParticipating => 'AI در مکالمه شرکت خواهد کرد';

  @override
  String get voiceNormalCall => 'تماس عادی بدون AI';

  @override
  String get voiceCallConfirm => 'تماس بگیرید؟';

  @override
  String get chatAlreadyInCall => 'در حال حاضر در تماس';

  @override
  String chatCallError(String error) {
    return 'خطای تماس: $error';
  }

  @override
  String get chatPhotoVideo => 'عکس / ویدیو';

  @override
  String get chatCamera => 'دوربین';

  @override
  String get chatFile => 'فایل';

  @override
  String get chatContact => 'مخاطب';

  @override
  String get chatSelectContact => 'انتخاب یک مخاطب';

  @override
  String get chatNoContacts => 'بدون مخاطب';

  @override
  String get chatUser => 'کاربر';

  @override
  String get chatFileAttachment => '📎 فایل';

  @override
  String chatFileUploadError(String error) {
    return 'خطای بارگذاری فایل: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 پیام صوتی';

  @override
  String get chatGroup => 'گروه';

  @override
  String get chatDialog => 'گفتگو';

  @override
  String get chatCall => 'تماس';

  @override
  String get chatStartConversation => 'شروع مکالمه';

  @override
  String get chatYou => 'شما';

  @override
  String get chatIsTyping => 'در حال تایپ...';

  @override
  String chatUserIsTyping(String name) {
    return '$name در حال تایپ...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names در حال تایپ...';
  }

  @override
  String get chatPreparingFile => 'در حال آماده‌سازی فایل…';

  @override
  String chatUploading(int progress) {
    return 'در حال بارگذاری… $progress%';
  }

  @override
  String get chatEdited => 'ویرایش شده';

  @override
  String get chatViaMesh => 'از طریق مش';

  @override
  String get chatReply => 'پاسخ';

  @override
  String get chatEdit => 'ویرایش';

  @override
  String get chatCopy => 'کپی';

  @override
  String get chatCopied => 'کپی شد';

  @override
  String get chatSaveMedia => 'ذخیره';

  @override
  String get chatForward => 'فوروارد';

  @override
  String get chatSaving => 'در حال ذخیره...';

  @override
  String get chatSavedToGallery => 'در گالری ذخیره شد';

  @override
  String get chatNoSavePermission =>
      'اجازه ذخیره وجود ندارد. تنظیمات را بررسی کنید.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'خطا در ذخیره فایل';

  @override
  String get chatDeleteMessage => 'حذف پیام';

  @override
  String get chatDeleteForMe => 'حذف برای من';

  @override
  String get chatDeleteForEveryone => 'حذف برای همه';

  @override
  String get chatMessageForwarded => 'پیام فوروارد شد';

  @override
  String get chatContactTapToOpen => 'تماس · برای باز کردن ضربه بزنید';

  @override
  String get chatForwardTo => 'فوروارد به...';

  @override
  String get chatSearchHint => 'جستجو...';

  @override
  String get chatRecording => 'در حال ضبط...';

  @override
  String get chatMessageHint => 'پیام...';

  @override
  String get chatHideKeyboard => 'پنهان کردن کیبورد';

  @override
  String get chatEditing => 'در حال ویرایش';

  @override
  String get chatFileDownloadError => 'خطا در دانلود فایل';

  @override
  String get chatVoiceMessageShort => 'پیام صوتی';

  @override
  String get chatVideoSavedToGallery => 'ویدیو در گالری ذخیره شد';

  @override
  String get chatSavingError => 'خطا در ذخیره‌سازی';

  @override
  String get convSetNickname => 'تنظیم نام مستعار';

  @override
  String get convNicknameRequired =>
      'برای استفاده از پیام‌رسان، نام مستعار لازم است. دیگر کاربران می‌توانند شما را با آن پیدا کنند.';

  @override
  String get convNicknameRules => '۳–۳۰ کاراکتر: حروف، ارقام، _';

  @override
  String get convNicknameTaken => 'نام مستعار قبلاً گرفته شده است';

  @override
  String get convSaveError => 'خطا در ذخیره‌سازی';

  @override
  String get convContactsLabel => 'مخاطبین';

  @override
  String get convDefaultUser => 'کاربر';

  @override
  String get convNoDialogs => 'هیچ مکالمه‌ای وجود ندارد';

  @override
  String get convFindUserToChat => 'یافتن کاربر برای شروع چت';

  @override
  String get convDefaultContact => 'مخاطب';

  @override
  String get dashboardUser => 'کاربر';

  @override
  String get dashboardIncomingCall => 'تماس ورودی';

  @override
  String get dashboardDecline => 'رد کردن';

  @override
  String get dashboardAccept => 'پذیرفتن';

  @override
  String get dashboardActiveCall => 'تماس فعال — برای بازگشت ضربه بزنید';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'به‌روزرسانی موجود است $version';
  }

  @override
  String get dashboardUpdate => 'به‌روزرسانی';

  @override
  String get dashboardWhatsNew => 'چه خبر';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'چه خبر در $version';
  }

  @override
  String get dashboardInstalling => 'در حال نصب...';

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
  String get contactRequestsTitle => 'مخاطبین';

  @override
  String get messengerContactRequestsSection => 'درخواست‌های مخاطب';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count درخواست جدید',
      one: '1 درخواست جدید',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'جستجو';

  @override
  String get contactRequestsIncoming => 'ورودی';

  @override
  String get contactRequestsSent => 'ارسال شده';

  @override
  String get contactRequestsSearchHint => 'نام مستعار یا ایمیل';

  @override
  String get contactRequestSent => 'درخواست ارسال شد';

  @override
  String get contactRequestsNoUsers => 'کاربری یافت نشد';

  @override
  String get contactRequestsSearchHelp =>
      'نام مستعار یا ایمیل دقیق را وارد کنید\nو جستجو را فشار دهید';

  @override
  String get contactRequestsSendTooltip => 'ارسال درخواست';

  @override
  String get contactRequestTitle => 'درخواست مخاطب';

  @override
  String contactRequestConfirm(String name) {
    return 'ارسال درخواست مخاطب به $name؟';
  }

  @override
  String get contactRequestSend => 'ارسال';

  @override
  String get contactRequestsNoIncoming => 'درخواستی در ورودی نیست';

  @override
  String get contactRequestsNoSent => 'درخواستی ارسال نشده';

  @override
  String get contactRequestStatusPending => 'در انتظار پاسخ';

  @override
  String get contactRequestStatusAccepted => 'پذیرفته شد';

  @override
  String get contactRequestStatusRejected => 'رد شد';

  @override
  String get userSearchTitle => 'یافتن کاربر';

  @override
  String get userSearchHint => 'نام مستعار، تلفن یا ایمیل';

  @override
  String get userSearchHelper =>
      'برای جستجو @نام مستعار، ایمیل یا نام را وارد کنید';

  @override
  String get userSearchNoUsers => 'کاربری یافت نشد';

  @override
  String get userProfileShareContact => 'اشتراک‌گذاری مخاطب';

  @override
  String get userProfileShareContactDesc => 'ارسال لینک مخاطب';

  @override
  String get userProfileCopyLink => 'کپی لینک';

  @override
  String get userProfileCopied => 'کپی شد';

  @override
  String get userProfileTitle => 'پروفایل';

  @override
  String get userProfileLoadError => 'خطا در بارگذاری پروفایل';

  @override
  String get userProfileMessage => 'پیام';

  @override
  String get userProfileCall => 'تماس';

  @override
  String get userProfileRequestSent => 'درخواست ارسال شد';

  @override
  String get userProfileAccept => 'پذیرفتن';

  @override
  String get userProfileDecline => 'رد کردن';

  @override
  String get userProfileAddToContacts => 'افزودن به مخاطبین';

  @override
  String get userProfileMediaTab => 'رسانه';

  @override
  String get userProfileFilesTab => 'فایل‌ها';

  @override
  String get userProfileLinksTab => 'لینک‌ها';

  @override
  String get userProfileRecordingsTab => 'ضبط‌ها';

  @override
  String get userProfileSummariesTab => 'خلاصه‌ها';

  @override
  String get userProfileNoMedia => 'فایل رسانه‌ای موجود نیست';

  @override
  String get userProfileNoFiles => 'فایلی موجود نیست';

  @override
  String get userProfileNoLinks => 'لینکی موجود نیست';

  @override
  String get userProfileNoRecordings => 'ضبطی موجود نیست';

  @override
  String get userProfileNoSummaries => 'خلاصه‌ای موجود نیست';

  @override
  String get userProfileMeetingSummary => 'خلاصه جلسه';

  @override
  String get userProfileFailedOpenChat => 'باز کردن چت ناموفق بود';

  @override
  String get sharedMediaTitle => 'رسانه و فایل‌ها';

  @override
  String get sharedMediaTab => 'رسانه';

  @override
  String get sharedFilesTab => 'فایل‌ها';

  @override
  String get sharedLinksTab => 'لینک‌ها';

  @override
  String get sharedNoMedia => 'فایل رسانه‌ای موجود نیست';

  @override
  String get sharedNoFiles => 'فایلی موجود نیست';

  @override
  String get sharedNoLinks => 'لینکی موجود نیست';

  @override
  String get shareToChat => 'ارسال به چت';

  @override
  String get shareSelectChat => 'انتخاب چت';

  @override
  String get shareNoChats => 'چتی موجود نیست';

  @override
  String shareFilesCount(int count) {
    return '$count فایل';
  }

  @override
  String get contactsTitle => 'مخاطبین';

  @override
  String get contactsAddTooltip => 'افزودن مخاطب';

  @override
  String get contactsSearchHint => 'جستجوی مخاطبین...';

  @override
  String get contactsNotFound => 'چیزی یافت نشد';

  @override
  String get contactsEmpty => 'مخاطبی موجود نیست';

  @override
  String get contactsAdd => 'افزودن مخاطب';

  @override
  String get contactsPendingConfirmation => 'در انتظار تأیید';

  @override
  String get contactsMessage => 'پیام';

  @override
  String get contactsCall => 'تماس';

  @override
  String get contactsResend => 'ارسال مجدد درخواست';

  @override
  String get contactsResendTimeout => '24 ساعت دیگر دوباره تلاش کنید';

  @override
  String get contactsResent => 'درخواست دوباره ارسال شد';

  @override
  String get contactsWantsToConnect => 'می‌خواهد با شما ارتباط برقرار کند';

  @override
  String get contactsSearchPeople => 'یافتن افراد';

  @override
  String get notesTitle => 'یادداشت‌ها';

  @override
  String get notesAssistantSpeaking => 'دستیار در حال صحبت...';

  @override
  String get notesListening => 'در حال گوش دادن...';

  @override
  String get notesEmpty => 'بدون یادداشت';

  @override
  String get notesEmptyHint =>
      'برای دیکته میکروفون را فشار دهید\nیا + برای ورود دستی';

  @override
  String get notesDeleteConfirm => 'یادداشت حذف شود؟';

  @override
  String get notesNew => 'یادداشت جدید';

  @override
  String get notesEdit => 'ویرایش';

  @override
  String get notesTitleHint => 'عنوان';

  @override
  String get notesContentHint => 'افکار خود را بنویسید...';

  @override
  String get calendarTitle => 'تقویم';

  @override
  String get calendarStop => 'توقف';

  @override
  String get calendarVoiceInput => 'ورودی صوتی';

  @override
  String get calendarNewEvent => 'رویداد جدید';

  @override
  String get calendarAssistantSpeaking => 'دستیار در حال صحبت...';

  @override
  String get calendarListening => 'در حال گوش دادن...';

  @override
  String calendarInvitations(int count) {
    return 'دعوت‌نامه‌ها ($count)';
  }

  @override
  String get calendarNoEvents => 'بدون رویداد';

  @override
  String get calendarDayMon => 'دوشنبه';

  @override
  String get calendarDayTue => 'سه‌شنبه';

  @override
  String get calendarDayWed => 'چهارشنبه';

  @override
  String get calendarDayThu => 'پنج‌شنبه';

  @override
  String get calendarDayFri => 'جمعه';

  @override
  String get calendarDaySat => 'شنبه';

  @override
  String get calendarDaySun => 'یک‌شنبه';

  @override
  String get calendarEnterRoom => 'ورود به اتاق';

  @override
  String get calendarMeeting => 'جلسه';

  @override
  String calendarLocationPrefix(String location) {
    return 'مکان: $location';
  }

  @override
  String get calendarEditEvent => 'ویرایش';

  @override
  String get calendarTitleHint => 'عنوان';

  @override
  String get calendarDescriptionHint => 'توضیحات';

  @override
  String get calendarTypeEvent => 'رویداد';

  @override
  String get calendarTypeMeeting => 'جلسه';

  @override
  String get calendarTypeReminder => 'یادآوری';

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
  String get calendarTypeLabel => 'نوع';

  @override
  String get calendarMeetingLink => 'لینک جلسه';

  @override
  String get calendarLocationHint => 'مکان';

  @override
  String get calendarDateLabel => 'تاریخ';

  @override
  String get calendarTimeLabel => 'زمان';

  @override
  String get calendarReminderLabel => 'یادآوری';

  @override
  String get calendarReminderNone => 'هیچ‌کدام';

  @override
  String get calendarReminder15min => '۱۵ دقیقه قبل';

  @override
  String get calendarReminder30min => '۳۰ دقیقه قبل';

  @override
  String get calendarReminder1hour => '۱ ساعت قبل';

  @override
  String get calendarRepeatLabel => 'تکرار';

  @override
  String get calendarRepeatNone => 'بدون تکرار';

  @override
  String get calendarRepeatDaily => 'هر روز';

  @override
  String get calendarRepeatWeekly => 'هر هفته';

  @override
  String get calendarRepeatMonthly => 'هر ماه';

  @override
  String get calendarRepeatYearly => 'هر سال';

  @override
  String get calendarParticipants => 'شرکت‌کنندگان';

  @override
  String get calendarAddParticipant => 'افزودن';

  @override
  String get calendarSearchContacts => 'جستجوی مخاطبین...';

  @override
  String get calendarNoContacts => 'بدون مخاطب';

  @override
  String get calendarStatusAccepted => 'پذیرفته شد';

  @override
  String get calendarStatusDeclined => 'رد شد';

  @override
  String get calendarStatusMaybe => 'شاید';

  @override
  String get calendarStatusPending => 'در انتظار';

  @override
  String get calendarEndTime => 'زمان پایان';

  @override
  String get calendarYourAnswer => 'پاسخ شما:';

  @override
  String get calendarOrganizer => 'برگزارکننده';

  @override
  String calendarDeleteError(String error) {
    return 'حذف ناموفق: $error';
  }

  @override
  String get calendarRsvpAccept => 'پذیرفتن';

  @override
  String get calendarRsvpMaybe => 'شاید';

  @override
  String get calendarRsvpDecline => 'رد کردن';

  @override
  String get callHistoryTitle => 'تماس‌ها';

  @override
  String get callHistoryTab => 'تاریخچه تماس';

  @override
  String get callHistoryTempMeeting => 'جلسه موقت';

  @override
  String get callHistoryCopy => 'کپی';

  @override
  String get callHistoryLinkCopied => 'لینک کپی شد';

  @override
  String get callHistoryShare => 'اشتراک‌گذاری';

  @override
  String get callHistoryEnter => 'ورود';

  @override
  String get callHistoryAlreadyInCall => 'در حال حاضر در یک تماس';

  @override
  String get callHistoryCouldNotDeterminePeer => 'طرف مقابل مشخص نشد';

  @override
  String get callHistoryContacts => 'مخاطبین';

  @override
  String get callHistoryFailedLoadRoom => 'بارگذاری اتاق شما ناموفق بود';

  @override
  String get callHistoryYourRoom => 'اتاق شما';

  @override
  String get callHistoryCreateMeeting => 'ایجاد جلسه';

  @override
  String get callHistoryMeetingSummaries => 'خلاصه جلسات';

  @override
  String get callHistoryMeetingRecordings => 'ضبط جلسات';

  @override
  String get callHistoryNoCalls => 'بدون تماس';

  @override
  String get callHistoryMissed => 'از دست رفته';

  @override
  String get callHistoryRecording => 'در حال ضبط';

  @override
  String get callHistorySummary => 'خلاصه';

  @override
  String get callHistoryCallAgain => 'تماس مجدد';

  @override
  String callHistoryTodayTime(String time) {
    return 'امروز، $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'دیروز، $time';
  }

  @override
  String get callHistoryUnknown => 'ناشناخته';

  @override
  String get callHistoryDetails => 'جزئیات تماس';

  @override
  String get callHistoryOutgoing => 'تماس خروجی';

  @override
  String get callHistoryIncoming => 'تماس ورودی';

  @override
  String callHistoryDuration(String duration) {
    return 'مدت زمان: $duration';
  }

  @override
  String get callHistoryWithAI => 'با دستیار AI';

  @override
  String get callHistoryParticipants => 'شرکت‌کنندگان';

  @override
  String get callDetailYouSuffix => '(شما)';

  @override
  String get callHistoryMeetingSummary => 'خلاصه جلسه';

  @override
  String get callHistoryMoreDetails => 'جزئیات بیشتر';

  @override
  String get callHistorySummaryProcessing => 'در حال پردازش خلاصه...';

  @override
  String get callHistoryMeetingRecording => 'ضبط جلسه';

  @override
  String get callHistoryProcessing => 'در حال پردازش...';

  @override
  String get callHistoryCreateTranscript => 'ایجاد متن';

  @override
  String get callHistoryNoSummaries => 'بدون خلاصه';

  @override
  String get callHistoryRecordDuringCall => 'در طول تماس \"ضبط\" را فشار دهید';

  @override
  String callHistoryMeetingTime(String time) {
    return 'جلسه $time';
  }

  @override
  String get callHistoryTranscribing => 'در حال تبدیل به متن و خلاصه‌سازی...';

  @override
  String get callHistoryTranscriptCreated => 'متن ایجاد شد';

  @override
  String get callHistoryNoRecordings => 'بدون ضبط';

  @override
  String callHistoryRecordingDate(String date) {
    return 'ضبط $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'ضبط در دسترس نیست';

  @override
  String get callHistoryTranscriptReady => 'متن آماده است';

  @override
  String get callHistoryTranscript => 'متن';

  @override
  String get callHistoryKeyPoints => 'نکات کلیدی';

  @override
  String get callHistoryTasks => 'وظایف';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'اختصاص داده شده به: $assignee';
  }

  @override
  String get callHistoryDecisions => 'تصمیمات';

  @override
  String get callHistoryShowTranscript => 'نمایش متن کامل';

  @override
  String get profileScanQr => 'اسکن QR';

  @override
  String get profileMyQrCode => 'کد QR من';

  @override
  String profileAddMeShare(String userId) {
    return 'من را در Taler ID اضافه کنید!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'این کد را نشان دهید تا شما را اضافه کنند';

  @override
  String get profileEditDesc => 'نام، نام خانوادگی، نام پدر، تاریخ تولد';

  @override
  String get profileAboutMe => 'درباره من';

  @override
  String get profileAboutMeDesc => 'ارزش‌ها، مهارت‌ها، علایق و بیشتر';

  @override
  String get profileNotes => 'یادداشت‌ها';

  @override
  String get profileNotesDesc => 'افکار، ایده‌ها و یادداشت‌ها';

  @override
  String get profileAvatarUpdated => 'آواتار به‌روزرسانی شد';

  @override
  String get profileNickname => 'نام مستعار';

  @override
  String get profileNotSet => 'تنظیم نشده';

  @override
  String get profileChangeNickname => 'تغییر نام مستعار';

  @override
  String get profileNicknameUpdated => 'نام مستعار به‌روزرسانی شد';

  @override
  String get profileShareLabel => 'اشتراک‌گذاری';

  @override
  String get profileScanQrCode => 'اسکن کد QR';

  @override
  String get profilePointCamera => 'دوربین را به کد QR بگیرید';

  @override
  String get profilePhotoCamera => 'گرفتن عکس';

  @override
  String get profilePhotoGallery => 'انتخاب از گالری';

  @override
  String get editProfilePatronymic => 'نام پدر (اختیاری)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'درباره من';

  @override
  String get aboutMeClickToFill => 'برای پر کردن کلیک کنید';

  @override
  String get aboutMeCoreValues => 'ارزش‌ها';

  @override
  String get aboutMeWorldview => 'جهان‌بینی';

  @override
  String get aboutMeSkills => 'مهارت‌ها';

  @override
  String get aboutMeInterests => 'علایق';

  @override
  String get aboutMeDesires => 'خواسته‌ها';

  @override
  String get aboutMeBackground => 'پروفایل';

  @override
  String get aboutMeLikes => 'دوست‌داشتنی‌ها';

  @override
  String get aboutMeDislikes => 'ناپسندها';

  @override
  String get aboutMeDeleteSection => 'حذف بخش؟';

  @override
  String get aboutMeDeleteConfirm => 'تمام داده‌های این بخش حذف خواهند شد.';

  @override
  String aboutMeConnectionError(String error) {
    return 'خطای اتصال: $error';
  }

  @override
  String get aboutMeVisibility => 'قابلیت مشاهده';

  @override
  String get aboutMeTags => 'برچسب‌ها';

  @override
  String get aboutMeAddTag => 'افزودن برچسب...';

  @override
  String get aboutMeDescription => 'توضیحات';

  @override
  String get aboutMeDescribeLong => 'بیشتر بگویید...';

  @override
  String get aboutMeVisibilityEveryone => 'همه';

  @override
  String get aboutMeVisibilityContacts => 'مخاطبین';

  @override
  String get aboutMeVisibilityOnlyMe => 'فقط من';

  @override
  String get settingsProfileSubtitle => 'پروفایل';

  @override
  String get settingsWallpaper => 'تصویر زمینه';

  @override
  String get settingsWallpaperDesc => 'تصویر پس‌زمینه برای کل برنامه';

  @override
  String get settingsWallpaperNone => 'هیچ‌کدام';

  @override
  String get settingsAccount => 'حساب';

  @override
  String get settingsKycVerification => 'تأیید هویت (KYC)';

  @override
  String get settingsOrganizations => 'سازمان‌ها';

  @override
  String get incomingCallLabel => 'تماس ورودی';

  @override
  String get incomingCallDecline => 'رد کردن';

  @override
  String get incomingCallAccept => 'پذیرفتن';

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
  String get meshIncomingCallLabel => '📡 تماس مش ورودی';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'دستگاه مش $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'ابتدا تماس فعلی را پایان دهید';

  @override
  String get callPopupTransportTitle => 'تماس از طریق';

  @override
  String get callPopupTransportMesh => '📡 مش (نقطه به نقطه)';

  @override
  String get callPopupTransportLk => '📞 سرور';

  @override
  String get callPopupTransportMeshUnavailable =>
      'مخاطب از طریق مش در دسترس نیست';

  @override
  String get meshOnboardingTitle =>
      '📡 تماس‌های مش نیاز به باز بودن برنامه دارند';

  @override
  String get meshOnboardingBody =>
      'وقتی گوشی قفل است، تماس‌های مش ممکن است بعد از ~30 ثانیه قطع شوند (محدودیت iOS).';

  @override
  String get meshOnboardingAck => 'متوجه شدم';

  @override
  String get meshHistoryBadge => '📡 مش';

  @override
  String get meshHistoryNoChatAvailable => 'مخاطب در لیست شما نیست';

  @override
  String get meshCallStatusInviting => 'در حال تماس...';

  @override
  String get meshCallStatusConnecting => 'در حال اتصال...';

  @override
  String get meshCallEndedUserHangup => 'تماس پایان یافت';

  @override
  String get meshCallEndedRemoteHangup => 'توسط همتا پایان یافت';

  @override
  String get meshCallEndedRejected => 'رد شد';

  @override
  String get meshCallEndedNoAnswer => 'بدون پاسخ';

  @override
  String get meshCallEndedConnectionLost => 'اتصال قطع شد';

  @override
  String get meshCallEndedError => 'خطای اتصال';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 مش · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 مش';

  @override
  String get batteryExemptionTitle => '📡 تماس‌های مش قابل اعتماد';

  @override
  String get batteryExemptionBody =>
      'اجازه دهید برنامه بدون محدودیت‌های باتری اجرا شود تا اندروید مش را در پس‌زمینه متوقف نکند.';

  @override
  String get batteryExemptionAccept => 'باز کردن تنظیمات';

  @override
  String get batteryExemptionDismiss => 'فعلاً نه';

  @override
  String get groupCamera => 'دوربین';

  @override
  String get groupGallery => 'گالری';

  @override
  String get groupAvatarUpdated => 'آواتار گروه به‌روزرسانی شد';

  @override
  String get groupNameTitle => 'نام گروه';

  @override
  String get groupEnterName => 'نام را وارد کنید';

  @override
  String get groupDescriptionTitle => 'توضیحات گروه';

  @override
  String get groupEnterDescription => 'توضیحات گروه را وارد کنید';

  @override
  String get groupChangeRoleTitle => 'تغییر نقش';

  @override
  String get groupRemoveMemberTitle => 'حذف عضو';

  @override
  String get groupDescription => 'توضیحات';

  @override
  String get groupAddDescription => 'افزودن توضیحات گروه';

  @override
  String get groupNoDescription => 'بدون توضیحات';

  @override
  String get groupMediaAndFiles => 'رسانه و فایل‌ها';

  @override
  String get groupMuteNotifications => 'بی‌صدا کردن اعلان‌ها';

  @override
  String get groupMuted => 'بی‌صدا';

  @override
  String get groupNoResults => 'بدون نتیجه';

  @override
  String get authInvalidCode => 'کد نامعتبر. دوباره تلاش کنید.';

  @override
  String get loginSubtitle => 'استفاده از ایمیل و رمز عبور';

  @override
  String get emailRequired => 'ایمیل را وارد کنید';

  @override
  String get emailInvalid => 'ایمیل نامعتبر';

  @override
  String get passwordRequired => 'رمز عبور را وارد کنید';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'یک حساب برای کل اکوسیستم Taler';

  @override
  String get usernameOptional => 'نام کاربری (اختیاری)';

  @override
  String get usernameMinLength => 'حداقل ۳ کاراکتر';

  @override
  String get usernameMaxLength => 'حداکثر ۳۰ کاراکتر';

  @override
  String get usernameInvalid => 'فقط حروف، اعداد و _';

  @override
  String get biometricLoginReason => 'ورود به Taler ID';

  @override
  String get docTypePassport => 'پاسپورت';

  @override
  String get docTypeIdCard => 'کارت شناسایی';

  @override
  String get docTypeDriverLicense => 'گواهینامه رانندگی';

  @override
  String get docTypeResidencePermit => 'اجازه اقامت';

  @override
  String addressApartment(String number) {
    return 'واحد $number';
  }

  @override
  String get failedToUpdateProfile => 'به‌روزرسانی پروفایل ناموفق بود';

  @override
  String get failedToStartKyb => 'شروع تأیید KYB ناموفق بود';

  @override
  String get orgUpdated => 'سازمان به‌روزرسانی شد';

  @override
  String get failedToUpdateOrg => 'به‌روزرسانی سازمان ناموفق بود';

  @override
  String get failedToChangeRole => 'تغییر نقش ناموفق بود';

  @override
  String get failedToRemoveMember => 'حذف عضو ناموفق بود';

  @override
  String get capabilityMessagesTitle => 'پیام‌ها';

  @override
  String get capabilityMessagesDesc =>
      'پیام‌ها را بررسی کنید یا به کسی پیام دهید. برای مثال: \"به ویکتور بنویس: یک ساعت دیگر آنجا خواهم بود\"';

  @override
  String get capabilityCallsTitle => 'تماس‌ها';

  @override
  String get capabilityCallsDesc =>
      'با هر تماسی به صورت صوتی تماس بگیرید. برای مثال: \"با ویکتور ویکتروف تماس بگیر\"';

  @override
  String get capabilityChatTitle => 'تاریخچه چت';

  @override
  String get capabilityChatDesc =>
      'تاریخچه چت را تحلیل می‌کنم. برای مثال: \"چه چیزی با ویکتور بحث کردیم؟\"';

  @override
  String get capabilityProfileTitle => 'پروفایل';

  @override
  String get capabilityProfileDesc =>
      'پروفایل شما را نشان می‌دهم یا به‌روزرسانی می‌کنم. برای مثال: \"پروفایل من را نشان بده\"';

  @override
  String get capabilityCoachingTitle => 'کوچینگ';

  @override
  String get capabilityCoachingDesc =>
      'حالت‌ها: کوچینگ ICF، روانشناس، مشاوره منابع انسانی. بگویید: \"بیایید کوچینگ کنیم\"';

  @override
  String get capabilityCalendarTitle => 'تقویم';

  @override
  String get capabilityCalendarDesc =>
      'برنامه‌ریزی جلسه یا تنظیم یادآور. برای مثال: \"برنامه‌ریزی جلسه با ویکتور برای فردا ساعت ۱۵:۰۰\"';

  @override
  String get capabilityNotesTitle => 'یادداشت‌ها';

  @override
  String get capabilityNotesDesc =>
      'ذخیره یک فکر یا خواندن یادداشت‌های اخیر. برای مثال: \"یک ایده بنویس...\" یا \"یادداشت‌های اخیر را بخوان\"';

  @override
  String get assistantCallConfirm => 'تماس بگیرم؟';

  @override
  String get callNoAnswer => 'پاسخی نیست';

  @override
  String get contactDelete => 'حذف مخاطب';

  @override
  String get contactDeleteTitle => 'حذف مخاطب';

  @override
  String get contactDeleteConfirm => 'آیا مطمئن هستید؟ این مخاطب حذف خواهد شد.';

  @override
  String get contactBlock => 'مسدود کردن';

  @override
  String get contactBlockTitle => 'مسدود کردن کاربر';

  @override
  String get contactBlockConfirm =>
      'این کاربر نمی‌تواند به شما پیام دهد یا تماس بگیرد.';

  @override
  String get contactUnblock => 'رفع مسدودی';

  @override
  String get contactBlocked => 'مسدود شده';

  @override
  String get contactYouAreBlocked => 'این کاربر شما را مسدود کرده است';

  @override
  String get chatBlockedByYou => 'شما این کاربر را مسدود کرده‌اید';

  @override
  String get chatYouAreBlocked => 'شما توسط این کاربر مسدود شده‌اید';

  @override
  String get chatNotContacts =>
      'برای پیام دادن، این کاربر را به مخاطبین اضافه کنید';

  @override
  String get contactRevokeRequest => 'لغو درخواست';

  @override
  String get messengerPoll => 'نظرسنجی';

  @override
  String get messengerCreatePoll => 'ایجاد نظرسنجی';

  @override
  String get messengerPollQuestion => 'سوال';

  @override
  String messengerPollOption(int number) {
    return 'گزینه $number';
  }

  @override
  String get messengerPollAddOption => 'افزودن گزینه';

  @override
  String get messengerPollAnonymous => 'رای‌گیری ناشناس';

  @override
  String get messengerPollMultiple => 'چند گزینه‌ای';

  @override
  String get messengerPollCreateError => 'ایجاد نظرسنجی ناموفق بود';

  @override
  String get messengerPollUnavailable => 'نظرسنجی در دسترس نیست';

  @override
  String get messengerPollMultipleNote => 'می‌توانید چندین گزینه انتخاب کنید';

  @override
  String messengerPollVotes(int count) {
    return '$count رای';
  }

  @override
  String get messengerVideoMessage => 'پیام ویدئویی';

  @override
  String get messengerVideoRecordError => 'خطا در ضبط ویدئو';

  @override
  String get messengerVideoPlaybackError => 'پخش ویدئو ممکن نیست';

  @override
  String get messengerGalleryAccessError => 'دسترسی به گالری وجود ندارد';

  @override
  String get messengerSearchInChat => 'جستجو در چت...';

  @override
  String get messengerSaveToFavorites => 'ذخیره در علاقه‌مندی‌ها';

  @override
  String get messengerSavedToFavorites => 'در علاقه‌مندی‌ها ذخیره شد';

  @override
  String get messengerSearchInMessages => 'جستجو در پیام‌ها...';

  @override
  String messengerFoundInMessages(int count) {
    return 'یافت شده در پیام‌ها ($count)';
  }

  @override
  String get messengerGroupDefault => 'گروه';

  @override
  String get messengerUserDefault => 'کاربر';

  @override
  String get messengerPin => 'سنجاق کردن';

  @override
  String get messengerUnpin => 'برداشتن سنجاق';

  @override
  String get messengerArchive => 'بایگانی';

  @override
  String get messengerUnarchive => 'خارج کردن از بایگانی';

  @override
  String get messengerDeleteChat => 'حذف چت';

  @override
  String get messengerDeleteChatTitle => 'حذف چت؟';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'چت با $name حذف شود؟ این عمل قابل بازگشت نیست.';
  }

  @override
  String get messengerCreateChannel => 'ایجاد کانال';

  @override
  String get messengerChannelName => 'نام';

  @override
  String get messengerChannelDescription => 'توضیحات (اختیاری)';

  @override
  String get messengerChannelCreateError => 'ایجاد کانال ناموفق بود';

  @override
  String get messengerFilterAll => 'همه';

  @override
  String get messengerFilterUnread => 'خوانده نشده';

  @override
  String get messengerFilterPersonal => 'شخصی';

  @override
  String get messengerFilterGroups => 'گروه‌ها';

  @override
  String get messengerFilterChannels => 'کانال‌ها';

  @override
  String get messengerArchivedSection => 'بایگانی شده';

  @override
  String get messengerSavedSection => 'علاقه‌مندی‌ها';

  @override
  String get messengerSavedSubtitle => 'ذخیره در حافظه';

  @override
  String messengerArchiveTitle(int count) {
    return 'بایگانی ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'بایگانی خالی است';

  @override
  String messengerYouPrefix(String message) {
    return 'شما: $message';
  }

  @override
  String get messengerMissedCall => 'تماس از دست رفته';

  @override
  String get messengerSavedTitle => 'علاقه‌مندی‌ها';

  @override
  String get messengerNoSavedMessages => 'پیام ذخیره شده‌ای وجود ندارد';

  @override
  String get messengerSavedHint =>
      'برای ذخیره پیام، طولانی فشار دهید → \"ذخیره در علاقه‌مندی‌ها\"';

  @override
  String get messengerDefaultFile => 'فایل';

  @override
  String get messengerTopicDefault => 'عمومی';

  @override
  String get messengerTopicNew => 'موضوع جدید';

  @override
  String get messengerTopicNameHint => 'نام موضوع';

  @override
  String get messengerTopicIcon => 'آیکون';

  @override
  String messengerTopicCount(int count) {
    return '$count موضوع';
  }

  @override
  String get messengerNoTopics => 'موضوعی وجود ندارد';

  @override
  String get messengerNoMessages => 'پیامی وجود ندارد';

  @override
  String get you => 'شما';

  @override
  String get messengerThread => 'رشته';

  @override
  String get messengerThreadReply => 'پاسخ';

  @override
  String get messengerThreadReplies => 'پاسخ‌ها';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'بدون پاسخ';

  @override
  String get messengerReplyHint => 'پاسخ به رشته...';

  @override
  String get messengerContactName => 'نام مخاطب';

  @override
  String messengerOriginalName(String name) {
    return 'نام اصلی: $name';
  }

  @override
  String get messengerDisplayName => 'نام نمایشی';

  @override
  String messengerShareContact(String name) {
    return 'مخاطب در Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'حذف خودکار پیام‌ها';

  @override
  String get messengerAutoDeleteOff => 'خاموش';

  @override
  String get messengerAutoDelete7d => '۷ روز';

  @override
  String get messengerAutoDelete30d => '۳۰ روز';

  @override
  String get messengerAutoDelete90d => '۹۰ روز';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count روز';
  }

  @override
  String get messengerSettingsHeader => 'تنظیمات';

  @override
  String get messengerAdminOnly => 'ارسال فقط توسط مدیر';

  @override
  String get messengerAdminOnlyDesc => 'اعضا فقط می‌توانند بخوانند';

  @override
  String get messengerTopics => 'موضوعات';

  @override
  String get messengerTopicsDesc => 'چت را به موضوعات تقسیم کنید';

  @override
  String get aiTwinSection => 'همزاد صوتی AI';

  @override
  String get aiTwinEnabled => 'فعال‌سازی همزاد AI';

  @override
  String get aiTwinEnabledDesc =>
      'اگر پاسخ ندهید، همزاد AI شما تماس را با صدای شما پاسخ می‌دهد';

  @override
  String get aiTwinTimeout => 'زمان انتظار پاسخ';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds ثانیه';
  }

  @override
  String get aiTwinPrompt => 'دستورالعمل‌های AI';

  @override
  String get aiTwinPromptSubtitle =>
      'چگونه همزاد AI باید خود را معرفی کند و درباره چه چیزی صحبت کند';

  @override
  String aiTwinPromptHint(String name) {
    return 'سلام، این همزاد صوتی AI $name است. $name در حال حاضر نمی‌تواند پاسخ دهد. بگویید چه کسی تماس گرفته و موضوع چیست — من آن را منتقل می‌کنم.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'شبیه‌سازی صدای سفارشی به زودی می‌آید. فعلاً AI با صدای $name صحبت می‌کند.';
  }

  @override
  String get aiTwinDefaultName => 'مالک';

  @override
  String get aiTwinPromptReset => 'بازنشانی';

  @override
  String get callHistoryAiTwinAnswered => 'پاسخ داده شده توسط همزاد AI';

  @override
  String get callHistoryAiTwinSummary => 'خلاصه تماس';

  @override
  String get callHistoryAiTwinTranscript => 'رونوشت';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'از $name';
  }

  @override
  String get aiTwinOfferTitle => 'پاسخ ندادن';

  @override
  String aiTwinOfferBody(String name) {
    return '$name پاسخ نمی‌دهد. پیام را با همزاد صوتی AI او بگذارید؟';
  }

  @override
  String get aiTwinOfferBodyUser => 'کاربر';

  @override
  String get aiTwinOfferAccept => 'بله، پیام بگذارید';

  @override
  String get aiTwinOfferKeepWaiting => 'منتظر بمانید';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'نماینده AI شما';

  @override
  String get aiTwinHeroSubtitle =>
      'وقتی نمی‌توانید، تماس‌ها را با صدای شما پاسخ می‌دهد.';

  @override
  String get aiTwinProfileTitle => 'نماینده AI';

  @override
  String get aiTwinProfileDesc => 'تماس‌ها را با صدای شما پاسخ می‌دهد';

  @override
  String get aiTwinBadgeOn => 'روشن';

  @override
  String get aiAnalystTitle => 'تحلیلگر AI';

  @override
  String get aiAnalystSubtitle => 'فایل‌ها، وظایف، تحلیل — Claude';

  @override
  String get channelsDiscover => 'یافتن کانال';

  @override
  String get channelsSearchHint => 'جستجوی کانال‌ها';

  @override
  String get channelsSubscribers => 'مشترکین';

  @override
  String get channelsSubscribe => 'اشتراک';

  @override
  String get channelsUnsubscribe => 'لغو اشتراک';

  @override
  String get channelsSubscribedLabel => 'شما مشترک هستید';

  @override
  String get channelsSettings => 'تنظیمات کانال';

  @override
  String get channelsDelete => 'حذف کانال';

  @override
  String get channelsDeleteConfirm => 'کانال را به طور دائمی حذف کنید؟';

  @override
  String get channelsEmpty => 'هنوز کانالی وجود ندارد';

  @override
  String get channelsOpen => 'باز کردن';

  @override
  String get channelsNameLabel => 'نام';

  @override
  String get channelsDescriptionLabel => 'توضیحات';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'مالک نمی‌تواند لغو اشتراک کند. در عوض کانال را حذف کنید.';

  @override
  String get channelsNotFoundRedirect => 'کانال دیگر وجود ندارد';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جستجو',
      one: '$count جستجو',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل',
      one: '$count فایل',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فرمان',
      one: '$count فرمان',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تصویر',
      one: '$count تصویر',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرحله',
      one: '$count مرحله',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$secondsثانیه';
  }

  @override
  String get savedTitle => 'پیام‌های ذخیره‌شده';

  @override
  String get savedSubtitle => 'ابر خصوصی شما';

  @override
  String get savedOpenError => 'نمی‌توان پیام‌های ذخیره‌شده را باز کرد';

  @override
  String get billingWalletTitle => 'کیف پول';

  @override
  String get billingBuyPackage => 'خرید بسته';

  @override
  String get billingCurrentBalance => 'موجودی فعلی';

  @override
  String get billingPackagesTitle => 'بسته‌ها';

  @override
  String get billingPackagesUnavailable => 'بسته‌ها در دسترس نیستند';

  @override
  String get billingRecentOperations => 'عملیات اخیر';

  @override
  String get billingAllOperations => 'همه عملیات';

  @override
  String get billingNoOperations => 'بدون عملیات';

  @override
  String get billingOperationsTitle => 'عملیات';

  @override
  String get billingOperationsEmptyTitle => 'هنوز عملیاتی وجود ندارد';

  @override
  String get billingOperationsEmptySubtitle =>
      'افزایش اعتبار و هزینه‌ها برای ویژگی‌های AI اینجا نمایش داده می‌شوند';

  @override
  String get billingPricebookTitle => 'قیمت ویژگی‌ها';

  @override
  String get billingPricebookUnavailable => 'لیست قیمت در دسترس نیست';

  @override
  String get billingAiFeaturesTitle => 'ویژگی‌های AI';

  @override
  String get billingInsufficientFundsTitle => 'اعتبار ناکافی';

  @override
  String get billingInsufficientFundsSubtitle =>
      'برای استفاده از این ویژگی، اعتبار خود را افزایش دهید.';

  @override
  String billingRequiredLine(String required) {
    return 'نیاز: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'دارایی: $available μTAL';
  }

  @override
  String get billingTopUp => 'افزایش اعتبار';

  @override
  String get billingCancel => 'لغو';

  @override
  String get billingRetry => 'تلاش مجدد';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'اعتبار کم است: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'کیف پول و اعتبار';

  @override
  String get billingSectionHeader => 'صورتحساب و AI';

  @override
  String get billingFeatureVoiceAssistant => 'دستیار صوتی';

  @override
  String get billingFeatureWebSearch => 'جستجوی وب دستیار';

  @override
  String get billingFeatureAiTwin => 'همزاد صوتی';

  @override
  String get billingFeatureAiTwinLong => 'همزاد صوتی (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'ربات تماس خروجی';

  @override
  String get billingFeatureOutboundCallLong => 'ربات تماس خروجی';

  @override
  String get billingFeatureWhisperTranscribe => 'رونویسی تماس';

  @override
  String get billingFeatureMeetingSummary => 'خلاصه تماس AI';

  @override
  String get billingConfigureAiTwin => 'پیکربندی همزاد AI';

  @override
  String get billingWebSearchSubtitle => '(استفاده شده توسط دستیار)';

  @override
  String billingPackagePurchased(String balance) {
    return 'بسته خریداری شد: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'پیشنهاد شده';

  @override
  String get billingSessionTerminatedNoFunds =>
      'اعتبار تمام شد — جلسه پایان یافت';

  @override
  String get billingSessionTerminatedGeneric => 'جلسه دستیار پایان یافت';

  @override
  String billingBuyForPrice(String price) {
    return 'خرید به قیمت €$price';
  }

  @override
  String get billingTxTypeTopup => 'افزایش اعتبار';

  @override
  String get billingTxTypeRefund => 'بازپرداخت';

  @override
  String get billingTxTypeSpend => 'هزینه';

  @override
  String get billingUnitMinute => 'دقیقه';

  @override
  String get billingUnitRequest => 'درخواست';

  @override
  String get billingUnitToken => 'توکن';

  @override
  String get billingUnitTokens1k => '۱K توکن';

  @override
  String get billingUnitCall => 'تماس';

  @override
  String get groupCallSelectParticipants => 'انتخاب شرکت‌کنندگان';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'جستجو';

  @override
  String get groupCallMaxReached => 'حداکثر ۷ شرکت‌کننده';

  @override
  String get groupCallLobbyTitle => 'گروه • لابی';

  @override
  String groupCallHostLabel(String name) {
    return 'میزبان: $name';
  }

  @override
  String get groupCallMicHint => 'میکروفون هنگام اتصال فعال می‌شود';

  @override
  String get groupCallCancel => 'لغو';

  @override
  String get groupCallNoAnswer => 'کسی پاسخ نداد';

  @override
  String get groupCallEndedByHost => 'تماس توسط میزبان پایان یافت';

  @override
  String get groupCallAllLeft => 'همه تماس را ترک کردند';

  @override
  String get groupCallEnded => 'تماس پایان یافت';

  @override
  String groupCallActiveTitle(int count) {
    return 'گروه • $count';
  }

  @override
  String get groupCallConnectionLost => 'ارتباط قطع شد';

  @override
  String get groupCallMuteRequested =>
      'میزبان از همه خواست که میکروفون را خاموش کنند';

  @override
  String get groupCallUnmute => 'روشن کردن میکروفون';

  @override
  String get groupCallMute => 'خاموش کردن میکروفون';

  @override
  String get groupCallMuteAll => 'خاموش کردن میکروفون همه';

  @override
  String get groupCallLeave => 'ترک کردن';

  @override
  String get groupCallStatusCalling => 'در حال تماس...';

  @override
  String get groupCallStatusDeclined => 'رد شد';

  @override
  String get groupCallStatusTimeout => 'پاسخی نیست';

  @override
  String get groupCallStatusLeft => 'ترک کرد';

  @override
  String groupCallKickConfirm(String name) {
    return 'حذف $name از تماس';
  }

  @override
  String get groupCallCancelAction => 'لغو';

  @override
  String get groupCallActiveBanner => 'تماس فعال';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'گروه: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'گروه: $host';
  }

  @override
  String get groupCallCreateError => 'امکان ایجاد تماس نیست';

  @override
  String get groupCallJoinError => 'امکان پیوستن به تماس نیست';

  @override
  String get groupCallLivekitError => 'خطای LiveKit';

  @override
  String get groupCallDone => 'انجام شد';

  @override
  String get groupCallNoResults => 'نتیجه‌ای یافت نشد';

  @override
  String get groupCallNoContacts => 'تماسی وجود ندارد';

  @override
  String get meshGcContactOffline => 'در این وای‌فای نیست';

  @override
  String get meshGcOnlineViaMesh => 'آنلاین از طریق مش';

  @override
  String get meshGcMaxInvitees =>
      'تماس‌های گروهی تا ۴ دعوت‌شونده (۵ نفر در مجموع) را پشتیبانی می‌کنند.';

  @override
  String get meshGcStart => 'شروع تماس گروهی';

  @override
  String get meshGcCancel => 'لغو';

  @override
  String get meshGcStatusCalling => 'در حال تماس…';

  @override
  String get meshGcStatusJoined => 'پیوست';

  @override
  String get meshGcStatusDeclined => 'رد شد';

  @override
  String get meshGcStatusNoAnswer => 'بدون پاسخ';

  @override
  String get meshGcStatusConnectionFailed => 'اتصال ناموفق';

  @override
  String get meshGcStatusLeft => 'ترک کرد';

  @override
  String get meshGcTopTitle => 'مش';

  @override
  String get meshGcBusyOneOnOne => 'ابتدا تماس فعلی خود را تمام کنید.';

  @override
  String get presenceOnline => 'آنلاین';

  @override
  String get presenceLastSeenJustNow => 'آخرین بازدید همین حالا';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'آخرین بازدید $minutes دقیقه پیش';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'آخرین بازدید امروز در $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'آخرین بازدید دیروز در $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'آخرین بازدید $date';
  }

  @override
  String get presenceLastSeenRecently => 'آخرین بازدید اخیراً';

  @override
  String get privacySectionTitle => 'حریم خصوصی';

  @override
  String get privacyLastSeenLabel => 'چه کسی زمان آخرین بازدید شما را می‌بیند';

  @override
  String get privacyEveryone => 'همه';

  @override
  String get privacyContacts => 'فقط مخاطبین';

  @override
  String get privacyNobody => 'هیچ‌کس';

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

  @override
  String get pinnedMessageNotLoaded =>
      'Message not loaded — scroll up to find it';

  @override
  String get chatReplyOriginalNotLoaded =>
      'Original not loaded — scroll up to find it';

  @override
  String get chatOriginalDeleted => 'Message deleted';

  @override
  String chatForwardedFrom(String name) {
    return 'Forwarded from $name';
  }

  @override
  String get chatUnreadDivider => 'Unread messages';

  @override
  String chatSelectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String chatSelectionLimit(int limit) {
    return 'You can select at most $limit messages';
  }
}
