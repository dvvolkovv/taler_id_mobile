// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Ara';

  @override
  String get appSubtitle => 'Birleşik ekosistem kimliği';

  @override
  String get login => 'Giriş Yap';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get register => 'Hesap Oluştur';

  @override
  String get registerButton => 'Hesap Oluştur';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get noAccount => 'Hesabınız yok mu?';

  @override
  String get createOne => 'Bir tane oluştur';

  @override
  String get haveAccount => 'Zaten bir hesabınız var mı?';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get passwordMinLength => 'Minimum 8 karakter';

  @override
  String get invalidEmail => 'Geçerli bir e-posta girin';

  @override
  String get fieldRequired => 'Zorunlu alan';

  @override
  String get twoFATitle => 'İki Faktörlü Kimlik Doğrulama';

  @override
  String get twoFASubtitle => 'Doğrulayıcı uygulamanızdan 6 haneli kodu girin';

  @override
  String get twoFACode => '2FA Kodu';

  @override
  String get verify => 'Doğrula';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organizasyon';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get phone => 'Telefon';

  @override
  String get country => 'Ülke';

  @override
  String get dateOfBirth => 'Doğum Tarihi';

  @override
  String get documents => 'Belgeler';

  @override
  String get addDocument => 'Belge Ekle';

  @override
  String get noDocuments => 'Yüklenmiş belge yok';

  @override
  String get save => 'Kaydet';

  @override
  String get profileUpdated => 'Profil güncellendi';

  @override
  String get personalData => 'Kişisel Bilgiler';

  @override
  String get passport => 'Pasaport';

  @override
  String get drivingLicense => 'Sürücü Belgesi';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'Ulusal Kimlik';

  @override
  String get certificate => 'Sertifika';

  @override
  String get notSpecified => 'Belirtilmedi';

  @override
  String get notSpecifiedFemale => 'Belirtilmedi';

  @override
  String get documentType => 'Belge Türü';

  @override
  String get passportId => 'Pasaport / Kimlik';

  @override
  String get diplomaCertificate => 'Diploma / Sertifika';

  @override
  String get loadError => 'Yükleme hatası';

  @override
  String get verification => 'Doğrulama';

  @override
  String get countryAustria => 'Avusturya';

  @override
  String get countryGermany => 'Almanya';

  @override
  String get countryRussia => 'Rusya';

  @override
  String get countryUkraine => 'Ukrayna';

  @override
  String get countryKazakhstan => 'Kazakistan';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryOther => 'Diğer';

  @override
  String get kycTitle => 'KYC Doğrulama';

  @override
  String get kycVerified => 'Doğrulandı';

  @override
  String get kycPending => 'Beklemede';

  @override
  String get kycRejected => 'Reddedildi';

  @override
  String get kycUnverified => 'Doğrulanmadı';

  @override
  String get kycVerifiedDesc =>
      'Kimliğiniz doğrulandı. Taler ekosisteminin tüm özelliklerine tam erişiminiz var.';

  @override
  String get kycPendingDesc =>
      'Belgeleriniz inceleniyor. Bu genellikle 1-2 iş günü sürer.';

  @override
  String get kycRejectedDesc =>
      'Doğrulama başarısız oldu. Lütfen nedeni gözden geçirin ve belgelerinizi yeniden gönderin.';

  @override
  String get kycUnverifiedDesc =>
      'Taler ekosisteminin finansal özelliklerine tam erişim sağlamak için doğrulamayı tamamlayın.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Doğrulamayı Başlat';

  @override
  String get retryVerification => 'Doğrulamayı Tekrar Dene';

  @override
  String verifiedAt(String date) {
    return 'Doğrulandı: $date';
  }

  @override
  String get documentsSubmitted => 'İnceleme için belgeler gönderildi';

  @override
  String get documentsSubmittedDesc =>
      'İnceleme genellikle 1-2 iş günü sürer. Sonuçla ilgili bir push bildirimi alacaksınız.';

  @override
  String get securityAes => 'Verileriniz AES-256 şifreleme ile korunmaktadır';

  @override
  String get verificationTime => 'Doğrulama 1-2 iş günü sürer';

  @override
  String get pushNotification =>
      'Sonuçla ilgili bir push bildirimi alacaksınız';

  @override
  String get kycWebOnly =>
      'KYC doğrulaması yalnızca mobil uygulamada mevcuttur.';

  @override
  String verificationError(String code) {
    return 'Doğrulama hatası: $code';
  }

  @override
  String get organizations => 'Organizasyonlar';

  @override
  String get noOrganizations => 'Organizasyon yok';

  @override
  String get noOrganizationsDesc =>
      'Bir organizasyon oluşturun veya bir daveti kabul edin';

  @override
  String get createOrganization => 'Organizasyon Oluştur';

  @override
  String get newOrganization => 'Yeni Organizasyon';

  @override
  String get orgName => 'Ad *';

  @override
  String get orgDescription => 'Açıklama';

  @override
  String get orgEmail => 'İletişim E-postası';

  @override
  String get orgWebsite => 'Web Sitesi';

  @override
  String get orgLegalAddress => 'Yasal Adres';

  @override
  String get create => 'Oluştur';

  @override
  String get organization => 'Organizasyon';

  @override
  String get contacts => 'Kişiler';

  @override
  String members(int count) {
    return 'Üyeler ($count)';
  }

  @override
  String get inviteMember => 'Üye Davet Et';

  @override
  String get invite => 'Davet Et';

  @override
  String get sendInvite => 'Davet Gönder';

  @override
  String inviteSent(String email) {
    return '$email adresine davet gönderildi';
  }

  @override
  String get role => 'Rol';

  @override
  String get roleOwner => 'Sahip';

  @override
  String get roleAdmin => 'Yönetici';

  @override
  String get roleOperator => 'Operatör';

  @override
  String get roleViewer => 'Görüntüleyici';

  @override
  String get editOrganization => 'Düzenle';

  @override
  String get editOrganizationTitle => 'Organizasyonu Düzenle';

  @override
  String get removeMember => 'Üyeyi Kaldır';

  @override
  String removeMemberConfirm(String name) {
    return '$name organizasyondan kaldırılsın mı?';
  }

  @override
  String get memberRemoved => 'Üye kaldırıldı';

  @override
  String get roleChanged => 'Rol değiştirildi';

  @override
  String get kybVerified => 'Doğrulandı';

  @override
  String get kybPending => 'Beklemede';

  @override
  String get kybRejected => 'Reddedildi';

  @override
  String get kybNone => 'Doğrulanmadı';

  @override
  String get kybVerification => 'KYB Doğrulamasını Başlat';

  @override
  String get kybStartBusiness => 'İşletme Doğrulamasını Başlat';

  @override
  String get kybStatusLabel => 'KYB Durumu';

  @override
  String get noKyb => 'KYB Yok';

  @override
  String get kybBusinessVerificationTitle => 'İşletme Doğrulaması (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organizasyon başarıyla doğrulandı.';

  @override
  String get kybPendingOrgDesc =>
      'Belgeler inceleniyor. Bu genellikle 1-3 iş günü sürer.';

  @override
  String get kybRejectedOrgDesc =>
      'Doğrulama başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get kybNoneOrgDesc =>
      'İşletme özelliklerine erişmek için organizasyonunuzu doğrulayın.';

  @override
  String get invitePlus => '+ Davet Et';

  @override
  String get kybVerificationTitle => 'KYB Doğrulaması';

  @override
  String get kybWebOnlyBusiness =>
      'KYB doğrulaması yalnızca mobil uygulamada kullanılabilir.';

  @override
  String get unknownDevice => 'Bilinmeyen cihaz';

  @override
  String get ipUnknown => 'IP bilinmiyor';

  @override
  String get currentSessionLabel => 'Mevcut';

  @override
  String get endSessionAction => 'Sonlandır';

  @override
  String get deviceLoggedOut => 'Cihaz oturumu kapatılacak.';

  @override
  String get acceptInvitationTitle => 'Organizasyon Daveti';

  @override
  String get acceptInvitation => 'Daveti Kabul Et';

  @override
  String get acceptInvitationDesc =>
      'Taler ekosisteminde bir organizasyona katılmak için davet edildiniz.';

  @override
  String get accept => 'Kabul Et';

  @override
  String get reject => 'Reddet';

  @override
  String get sessions => 'Aktif Oturumlar';

  @override
  String get currentSession => 'Mevcut oturum';

  @override
  String get deleteSession => 'Oturumu Sonlandır';

  @override
  String get deleteSessionConfirm => 'Bu oturumu sonlandır?';

  @override
  String get sessionDeleted => 'Oturum sonlandırıldı';

  @override
  String get noSessions => 'Aktif oturum yok';

  @override
  String minutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String hoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String get justNow => 'Az önce';

  @override
  String get settings => 'Ayarlar';

  @override
  String get security => 'Güvenlik';

  @override
  String get biometrics => 'Biyometrik';

  @override
  String get biometricsDesc => 'Face ID veya parmak izi ile hızlı giriş';

  @override
  String get biometricsConfirm =>
      'Hızlı girişi etkinleştirmek için biyometrik doğrulayın';

  @override
  String get biometricsError =>
      'Biyometrik etkinleştirilemedi. Cihaz ayarlarını kontrol edin.';

  @override
  String get changePassword => 'Şifreyi Değiştir';

  @override
  String get twoFactorAuth => 'İki Faktörlü Kimlik Doğrulama';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get confirmNewPassword => 'Yeni Şifreyi Onayla';

  @override
  String get passwordChanged => 'Şifre değiştirildi';

  @override
  String get wrongCurrentPassword => 'Yanlış mevcut şifre';

  @override
  String get passwordTooWeak =>
      'Şifre çok zayıf: en az 8 karakter, harf ve rakam gerekli';

  @override
  String get passwordChangeFailed => 'Şifre değiştirilemedi';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get permissions => 'İzinler';

  @override
  String get permissionNotifications => 'Push Bildirimleri';

  @override
  String get permissionNotificationsDesc => 'Aramalar, mesajlar, durumlar';

  @override
  String get permissionMicrophone => 'Mikrofon';

  @override
  String get permissionMicrophoneDesc => 'Aramalar ve sesli asistan';

  @override
  String get permissionCamera => 'Kamera';

  @override
  String get permissionCameraDesc => 'Görüntülü aramalar ve doğrulama';

  @override
  String get permissionLocation => 'Konum';

  @override
  String get permissionLocationDesc => 'Doğrulama için kullanılır';

  @override
  String get permissionOpenSettings =>
      'Bir izni iptal etmek için sistem ayarlarını açın';

  @override
  String get pushKycStatus => 'KYC Durum Bildirimi';

  @override
  String get pushKycStatusDesc => 'Doğrulama sonucu';

  @override
  String get pushLogins => 'Giriş Bildirimi';

  @override
  String get pushLoginsDesc => 'Yeni bir cihazdan giriş yapıldığında';

  @override
  String get account => 'Hesap';

  @override
  String get language => 'Dil';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Arayüz Dili';

  @override
  String get exportData => 'Verileri Dışa Aktar (GDPR)';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountConfirm => 'Hesabı sil?';

  @override
  String get deleteAccountDesc =>
      'Tüm verileriniz silinecek (GDPR). Bu işlem geri alınamaz.';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get logoutConfirm => 'Çıkış yapılsın mı?';

  @override
  String get logoutDesc => 'Bu cihazda Taler ID\'den çıkış yapacaksınız.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN Kodu';

  @override
  String get pinCodeDesc => '4 haneli kodla hızlı giriş';

  @override
  String get setupPin => 'PIN Ayarla';

  @override
  String get enterPin => 'PIN Girin';

  @override
  String get confirmPin => 'PIN\'i Onayla';

  @override
  String get pinMismatch => 'PIN\'ler eşleşmiyor';

  @override
  String get passwordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get pinSet => 'PIN başarıyla ayarlandı';

  @override
  String get enterPinToLogin => 'Giriş yapmak için PIN girin';

  @override
  String get pinIncorrect => 'Hatalı PIN';

  @override
  String get removePin => 'PIN\'i Kaldır';

  @override
  String get pinRemoved => 'PIN kaldırıldı';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get ok => 'Tamam';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Hata';

  @override
  String get success => 'Başarılı';

  @override
  String get noData => 'Veri yok';

  @override
  String get failedToLoad => 'Veri yüklenemedi';

  @override
  String get failedToLoadProfile => 'Profil yüklenemedi';

  @override
  String get failedToSave => 'Değişiklikler kaydedilemedi';

  @override
  String get failedToLoadOrgs => 'Organizasyonlar yüklenemedi';

  @override
  String get failedToLoadOrg => 'Organizasyon verileri yüklenemedi';

  @override
  String get failedToCreateOrg => 'Organizasyon oluşturulamadı';

  @override
  String get failedToInvite => 'Davet gönderilemedi';

  @override
  String get failedToAcceptInvite => 'Davet kabul edilemedi';

  @override
  String get failedToLoadSessions => 'Oturumlar yüklenemedi';

  @override
  String get failedToDeleteSession => 'Oturum sonlandırılamadı';

  @override
  String get failedToLoadKyc => 'Doğrulama durumu yüklenemedi';

  @override
  String get failedToStartKyc => 'Doğrulama başlatılamadı';

  @override
  String get verifiedPersonalInfo => 'Doğrulanmış Veri';

  @override
  String get middleName => 'İkinci İsim';

  @override
  String get placeOfBirth => 'Doğum Yeri';

  @override
  String get nationality => 'Uyruk';

  @override
  String get gender => 'Cinsiyet';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get docNumber => 'Numara';

  @override
  String get docIssuedDate => 'Veriliş Tarihi';

  @override
  String get docValidUntil => 'Geçerlilik Tarihi';

  @override
  String get docIssuedBy => 'Veren Kurum';

  @override
  String get address => 'Adres';

  @override
  String get refreshData => 'Verileri Yenile';

  @override
  String get failedToLoadSumsubData => 'Doğrulama verileri yüklenemedi';

  @override
  String get sumsubDataLoading => 'Doğrulama verileri yükleniyor...';

  @override
  String get reviewResultGreen => 'Doğrulama başarılı';

  @override
  String get reviewResultRed => 'Doğrulama başarısız';

  @override
  String get tabAssistant => 'Asistan';

  @override
  String get assistantConnecting => 'Bağlanıyor…';

  @override
  String get assistantSpeaking => 'Konuşuyor…';

  @override
  String get assistantListening => 'Dinliyor…';

  @override
  String get assistantTapToStart => 'Başlamak için dokunun';

  @override
  String get assistantTapToTalk => 'AI ile konuşmak için dokunun';

  @override
  String get assistantRealtimeDesc =>
      'Asistan gerçek zamanlı olarak sesle yanıt verir';

  @override
  String get assistantConnectingToAssistant => 'Asistana bağlanılıyor...';

  @override
  String get assistantAiSpeaking => 'AI konuşuyor...';

  @override
  String get assistantAiListening => 'AI dinliyor';

  @override
  String get assistantSpeakerOn => 'Hoparlör açık';

  @override
  String get assistantSpeaker => 'Hoparlör';

  @override
  String get assistantEnd => 'Bitir';

  @override
  String get assistantUnmute => 'Sesi aç';

  @override
  String get assistantMicrophone => 'Mikrofon';

  @override
  String get assistantConnectionError => 'Bağlantı hatası';

  @override
  String get tabMessenger => 'Mesajlar';

  @override
  String get tabCalls => 'Aramalar';

  @override
  String get tabCalendar => 'Takvim';

  @override
  String get appearance => 'Görünüm';

  @override
  String get appearanceSelect => 'Tema Seçin';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get onboardingTitle1 => 'Birleşik Kimlik';

  @override
  String get onboardingDesc1 =>
      'Taler ID, Taler ekosisteminde dijital pasaportunuzdur. Tüm hizmetler için tek hesap.';

  @override
  String get onboardingTitle2 => 'Veri Güvenliği';

  @override
  String get onboardingDesc2 =>
      'KYC doğrulaması, AES-256 şifreleme ve iki faktörlü kimlik doğrulama kimliğinizi korur.';

  @override
  String get onboardingTitle3 => 'Bilgili Kalın';

  @override
  String get onboardingDesc3 =>
      'Doğrulama durumu, yeni cihazlardan girişler ve gelen aramalar hakkında bildirim alın.';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingEnableNotifications => 'Bildirimleri Etkinleştir';

  @override
  String get onboardingTitle4 => 'Sesli Aramalar';

  @override
  String get onboardingDesc4 =>
      'Sesli aramalar ve AI asistanı için mikrofon erişimi verin. Bunu daha sonra ayarlardan değiştirebilirsiniz.';

  @override
  String get onboardingEnableMicrophone => 'Mikrofonu Etkinleştir';

  @override
  String get onboardingStart => 'Başlayın';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get meshLocalNetworkPromptTitle => 'Yerel ağ erişimine izin ver';

  @override
  String get meshLocalNetworkPromptBody =>
      'Wi-Fi\'da eşleri bulmak için (çevrimdışı grup aramaları), iOS Yerel Ağ iznini gerektirir. Ayarlar → Gizlilik ve Güvenlik → Yerel Ağ → Taler ID\'yi açın.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Ayarları Aç';

  @override
  String get meshLocalNetworkPromptDismiss => 'Anladım';

  @override
  String get forgotPassword => 'Şifrenizi mi unuttunuz?';

  @override
  String get forgotPasswordTitle => 'Şifreyi Sıfırla';

  @override
  String get forgotPasswordSubtitle =>
      'Sıfırlama kodu almak için e-posta adresinizi girin';

  @override
  String resetCodeSent(String email) {
    return 'Kod $email adresine gönderildi';
  }

  @override
  String get enterResetCode => 'Kodu girin';

  @override
  String get resetPasswordButton => 'Şifreyi Sıfırla';

  @override
  String get passwordResetSuccess => 'Şifre başarıyla sıfırlandı';

  @override
  String get sendCode => 'Kodu Gönder';

  @override
  String get resendCode => 'Kodu Yeniden Gönder';

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
  String get newGroup => 'Yeni Grup';

  @override
  String get newChat => 'Yeni Sohbet';

  @override
  String get groupName => 'Grup Adı';

  @override
  String get createGroup => 'Grup Oluştur';

  @override
  String get groupInfo => 'Grup Bilgisi';

  @override
  String groupMembers(int count) {
    return 'Üyeler ($count)';
  }

  @override
  String get addMembers => 'Üye Ekle';

  @override
  String get leaveGroup => 'Gruptan Ayrıl';

  @override
  String get leaveGroupConfirm => 'Bu gruptan ayrılmak istiyor musunuz?';

  @override
  String get deleteGroup => 'Grubu Sil';

  @override
  String get deleteGroupConfirm =>
      'Bu grubu silmek istiyor musunuz? Bu işlem geri alınamaz.';

  @override
  String get groupRoleOwner => 'Sahip';

  @override
  String get groupRoleAdmin => 'Yönetici';

  @override
  String get groupRoleMember => 'Üye';

  @override
  String get selectParticipants => 'Katılımcıları Seç';

  @override
  String selectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get changeRole => 'Rolü Değiştir';

  @override
  String get groupCreated => 'Grup oluşturuldu';

  @override
  String memberJoined(String name) {
    return '$name katıldı';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name ayrıldı';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name çıkarıldı';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name artık $role';
  }

  @override
  String participantsCount(int count) {
    return '$count katılımcı';
  }

  @override
  String get enterGroupName => 'Grup adını girin';

  @override
  String get muteNotifications => 'Bildirimleri Sessize Al';

  @override
  String get unmuteNotifications => 'Bildirimleri Aç';

  @override
  String get muteFor1Hour => '1 saatliğine';

  @override
  String get muteFor8Hours => '8 saatliğine';

  @override
  String get muteFor2Days => '2 günlüğüne';

  @override
  String get muteForever => 'Süresiz';

  @override
  String get muted => 'Sessize Alındı';

  @override
  String get tabTranslator => 'Çevir';

  @override
  String get translatorTitle => 'Çevirici';

  @override
  String get translatorSelectLanguage => 'Dili Seç';

  @override
  String get translatorDownloading => 'Dil modelleri indiriliyor...';

  @override
  String get translatorDownloadingHint =>
      'İnternet sadece ilk indirme için gereklidir';

  @override
  String get translatorTypeHint => 'Metin yazın veya mikrofona dokunun';

  @override
  String get translatorListening => 'Dinleniyor...';

  @override
  String get translatorTapToSpeak => 'Konuşmak için dokunun';

  @override
  String get translatorTapToStop => 'Durdurmak için dokunun';

  @override
  String get translatorAutoSpeak => 'Otomatik konuşma';

  @override
  String get translatorCopied => 'Kopyalandı';

  @override
  String get translatorLangRu => 'Rusça';

  @override
  String get translatorLangEn => 'İngilizce';

  @override
  String get translatorLangDe => 'Almanca';

  @override
  String get translatorLangFr => 'Fransızca';

  @override
  String get translatorLangEs => 'İspanyolca';

  @override
  String get translatorLangIt => 'İtalyanca';

  @override
  String get translatorLangPt => 'Portekizce';

  @override
  String get translatorLangTr => 'Türkçe';

  @override
  String get translatorLangZh => 'Çince';

  @override
  String get translatorLangJa => 'Japonca';

  @override
  String get translatorLangKo => 'Korece';

  @override
  String get translatorLangAr => 'Arapça';

  @override
  String get translatorLangPl => 'Lehçe';

  @override
  String get translatorLangSk => 'Slovakça';

  @override
  String get translatorLangCs => 'Çekçe';

  @override
  String get translatorLangNl => 'Felemenkçe';

  @override
  String get translatorLangSv => 'İsveççe';

  @override
  String get translatorLangDa => 'Danca';

  @override
  String get translatorLangNo => 'Norveççe';

  @override
  String get translatorLangFi => 'Fince';

  @override
  String get translatorLangUk => 'Ukraynaca';

  @override
  String get translatorLangEl => 'Yunanca';

  @override
  String get translatorLangRo => 'Romence';

  @override
  String get translatorLangHu => 'Macarca';

  @override
  String get translatorLangBg => 'Bulgarca';

  @override
  String get translatorLangHr => 'Hırvatça';

  @override
  String get translatorLangSr => 'Sırpça';

  @override
  String get translatorLangHi => 'Hintçe';

  @override
  String get translatorLangTh => 'Tayca';

  @override
  String get translatorLangVi => 'Vietnamca';

  @override
  String get translatorLangId => 'Endonezce';

  @override
  String get translatorLangMs => 'Malayca';

  @override
  String get translatorLangHe => 'İbranice';

  @override
  String get translatorLangFa => 'Farsça';

  @override
  String get callInProgress => 'Görüşme devam ediyor';

  @override
  String get joinCall => 'Katıl';

  @override
  String get createCallLink => 'Çağrı bağlantısı';

  @override
  String get callLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get callLinkTitle => 'Oda bağlantısı';

  @override
  String get connectionUnstable =>
      'Bağlantı kararsız — internetinizi kontrol edin';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String get errorTimeout =>
      'Bağlantı zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';

  @override
  String get errorNoConnection => 'İnternet bağlantısı yok.';

  @override
  String get errorGeneral => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String errorWithMessage(String message) {
    return 'Hata: $message';
  }

  @override
  String get notifChannelMessages => 'Mesajlar';

  @override
  String get notifChannelMessagesDesc => 'Yeni mesaj bildirimleri';

  @override
  String get notifChannelMissedCalls => 'Cevapsız çağrılar';

  @override
  String get notifChannelMissedCallsDesc => 'Cevapsız çağrı bildirimleri';

  @override
  String get notifMissedCall => 'Cevapsız çağrı';

  @override
  String get notifAccept => 'Kabul et';

  @override
  String get notifDecline => 'Reddet';

  @override
  String get notifIncomingCall => 'Gelen çağrı';

  @override
  String get notifIncomingCallChannel => 'Gelen çağrı';

  @override
  String get notifMissedCallChannel => 'Cevapsız çağrı';

  @override
  String get notifUnknown => 'Bilinmeyen';

  @override
  String get effectNone => 'Arka plan yok';

  @override
  String get effectBlur => 'Bulanık';

  @override
  String get effectOffice => 'Ofis';

  @override
  String get effectNature => 'Doğa';

  @override
  String get effectGradient => 'Gradyan';

  @override
  String get effectLibrary => 'Kütüphane';

  @override
  String get effectCity => 'Şehir';

  @override
  String get effectMinimalism => 'Minimalizm';

  @override
  String get voiceParticipant => 'Katılımcı';

  @override
  String get voiceInvitesToRoom => 'sizi odaya davet ediyor';

  @override
  String get voiceRoom => 'Oda';

  @override
  String get voicePasswordProtected => 'Şifre korumalı';

  @override
  String get voicePasswordHint => 'Şifre';

  @override
  String get voiceEnter => 'Giriş yap';

  @override
  String get voiceJoinRoom => 'Odaya katıl';

  @override
  String get voiceYourName => 'Adınız';

  @override
  String voiceInvitationSent(String name) {
    return '$name kişisine davet gönderildi';
  }

  @override
  String get voiceNoActiveRoom => 'Aktif oda yok';

  @override
  String get voiceCameraPermission =>
      'Ayarlar → Gizlilik → Kamera → TalerID\'de kamera erişimine izin verin';

  @override
  String get voiceOpenSettings => 'Aç';

  @override
  String voiceCameraError(String error) {
    return 'Kamera etkinleştirilemedi: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Herkes kabul etti. Kayıt başladı.';

  @override
  String get voiceNewParticipantAgreed => 'Yeni katılımcı kaydı kabul etti.';

  @override
  String get voiceDeclinedRecording =>
      'Kaydı reddettiniz. Görüşmeden ayrılıyorsunuz.';

  @override
  String get voiceRecordingEnded => 'Kayıt sona erdi';

  @override
  String get voiceRecordingInProgress => 'Kayıt devam ediyor';

  @override
  String get voiceTranscriptionRequest => 'Transkripsiyon isteği';

  @override
  String get voiceRecordingRequest => 'Kayıt isteği';

  @override
  String get voiceAgree => 'Kabul et';

  @override
  String get voiceDeclineAndLeave => 'Reddet ve ayrıl';

  @override
  String get voiceAudioOutput => 'Ses çıkışı';

  @override
  String get voiceAudioPhone => 'Telefon';

  @override
  String get voiceAudioSpeaker => 'Hoparlör';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Kulaklık';

  @override
  String get voiceLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get voiceTranslateTo => 'Çevir';

  @override
  String get voiceSearchLanguage => 'Dil ara...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Oda $name';
  }

  @override
  String get voiceVoiceCall => 'Sesli arama';

  @override
  String get voiceOnHold => 'Beklemede';

  @override
  String get voiceActiveCall => 'Aktif';

  @override
  String get voiceEndAllCalls => 'Tüm aramaları bitir';

  @override
  String get voiceEndThisCall => 'Bu aramayı bitir';

  @override
  String get voiceCopyLink => 'Bağlantıyı kopyala';

  @override
  String get voiceAddParticipant => 'Katılımcı ekle';

  @override
  String get voiceReconnecting => 'Yeniden bağlanıyor...';

  @override
  String get voiceConnectionError => 'Bağlantı hatası';

  @override
  String get voiceClose => 'Kapat';

  @override
  String get voiceCalling => 'Aranıyor...';

  @override
  String get voiceCallActive => 'Arama aktif';

  @override
  String get voiceWaiting => 'Bekleniyor';

  @override
  String get voiceWaitingUpper => 'BEKLENİYOR';

  @override
  String get voiceRec => 'KAYIT';

  @override
  String get voiceStop => 'Durdur';

  @override
  String get voiceRecord => 'Kayıt';

  @override
  String get voiceTranslation => 'Çeviri';

  @override
  String get voiceAudio => 'Ses';

  @override
  String get voiceFlipCamera => 'Çevir';

  @override
  String get voiceBackground => 'Arka plan';

  @override
  String get voiceAssistantSpeakingStatus => 'Asistan konuşuyor...';

  @override
  String get voiceAssistantListeningStatus => 'Asistan dinliyor...';

  @override
  String get voiceUnmute => 'Sesi aç';

  @override
  String get voiceMic => 'Mikrofon';

  @override
  String get voiceAssistantLabel => 'Asistan';

  @override
  String get voiceCameraOn => 'Kamera açık';

  @override
  String get voiceCameraLabel => 'Kamera';

  @override
  String get voiceEndCall => 'Çağrıyı bitir';

  @override
  String get voiceWaitingParticipants => 'Katılımcılar bekleniyor...';

  @override
  String get voiceYou => 'Sen';

  @override
  String get voiceAiAssistant => 'AI Asistan';

  @override
  String get voiceVideoUnavailable => 'Video kullanılamıyor';

  @override
  String get voiceSearchNickname => 'Takma ad ile ara...';

  @override
  String get voiceTranscriptionWord => 'transkripsiyon';

  @override
  String get voiceRecordingWord => 'kayıt';

  @override
  String get voiceConnecting => 'Bağlanıyor...';

  @override
  String get voiceVideoBackground => 'Video arka planı';

  @override
  String get voiceCallSettings => 'Çağrı ayarları';

  @override
  String get voiceEnableAI => 'AI asistanı etkinleştir';

  @override
  String get voiceAIParticipating => 'AI konuşmaya katılacak';

  @override
  String get voiceNormalCall => 'AI olmadan normal çağrı';

  @override
  String get voiceCallConfirm => 'Çağrı yapılsın mı?';

  @override
  String get chatAlreadyInCall => 'Zaten bir çağrıda';

  @override
  String chatCallError(String error) {
    return 'Çağrı hatası: $error';
  }

  @override
  String get chatPhotoVideo => 'Fotoğraf / Video';

  @override
  String get chatCamera => 'Kamera';

  @override
  String get chatFile => 'Dosya';

  @override
  String get chatContact => 'Kişi';

  @override
  String get chatSelectContact => 'Bir kişi seç';

  @override
  String get chatNoContacts => 'Kişi yok';

  @override
  String get chatUser => 'Kullanıcı';

  @override
  String get chatFileAttachment => '📎 Dosya';

  @override
  String chatFileUploadError(String error) {
    return 'Dosya yükleme hatası: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Sesli mesaj';

  @override
  String get chatGroup => 'Grup';

  @override
  String get chatDialog => 'Diyalog';

  @override
  String get chatCall => 'Çağrı';

  @override
  String get chatStartConversation => 'Sohbet başlat';

  @override
  String get chatYou => 'Sen';

  @override
  String get chatIsTyping => 'yazıyor...';

  @override
  String chatUserIsTyping(String name) {
    return '$name yazıyor...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names yazıyor...';
  }

  @override
  String get chatPreparingFile => 'Dosya hazırlanıyor…';

  @override
  String chatUploading(int progress) {
    return 'Yükleniyor… $progress%';
  }

  @override
  String get chatEdited => 'Düzenlendi';

  @override
  String get chatViaMesh => 'ağ üzerinden';

  @override
  String get chatReply => 'Yanıtla';

  @override
  String get chatEdit => 'Düzenle';

  @override
  String get chatCopy => 'Kopyala';

  @override
  String get chatCopied => 'Kopyalandı';

  @override
  String get chatSaveMedia => 'Kaydet';

  @override
  String get chatForward => 'İlet';

  @override
  String get chatSaving => 'Kaydediliyor...';

  @override
  String get chatSavedToGallery => 'Galeriye kaydedildi';

  @override
  String get chatNoSavePermission =>
      'Kaydetme izni yok. Ayarları kontrol edin.';

  @override
  String get chatFileSaveError => 'Dosya kaydetme hatası';

  @override
  String get chatDeleteMessage => 'Mesajı sil';

  @override
  String get chatDeleteForMe => 'Benim için sil';

  @override
  String get chatDeleteForEveryone => 'Herkes için sil';

  @override
  String get chatMessageForwarded => 'Mesaj iletildi';

  @override
  String get chatContactTapToOpen => 'Kişi · açmak için dokunun';

  @override
  String get chatForwardTo => 'Şuraya ilet...';

  @override
  String get chatSearchHint => 'Ara...';

  @override
  String get chatRecording => 'Kaydediliyor...';

  @override
  String get chatMessageHint => 'Mesaj...';

  @override
  String get chatHideKeyboard => 'Klavye gizle';

  @override
  String get chatEditing => 'Düzenleniyor';

  @override
  String get chatFileDownloadError => 'Dosya indirme hatası';

  @override
  String get chatVoiceMessageShort => 'Sesli mesaj';

  @override
  String get chatVideoSavedToGallery => 'Video galeriye kaydedildi';

  @override
  String get chatSavingError => 'Kaydetme hatası';

  @override
  String get convSetNickname => 'Bir takma ad belirleyin';

  @override
  String get convNicknameRequired =>
      'Mesajlaşmayı kullanmak için bir takma ad gereklidir. Diğer kullanıcılar sizi bu adla bulabilir.';

  @override
  String get convNicknameRules => '3–30 karakter: harfler, rakamlar, _';

  @override
  String get convNicknameTaken => 'Takma ad zaten alınmış';

  @override
  String get convSaveError => 'Kaydetme hatası';

  @override
  String get convContactsLabel => 'Kişiler';

  @override
  String get convDefaultUser => 'Kullanıcı';

  @override
  String get convNoDialogs => 'Sohbet yok';

  @override
  String get convFindUserToChat => 'Sohbet başlatmak için bir kullanıcı bulun';

  @override
  String get convDefaultContact => 'Kişi';

  @override
  String get dashboardUser => 'Kullanıcı';

  @override
  String get dashboardIncomingCall => 'Gelen arama';

  @override
  String get dashboardDecline => 'Reddet';

  @override
  String get dashboardAccept => 'Kabul et';

  @override
  String get dashboardActiveCall => 'Aktif arama — geri dönmek için dokunun';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Güncelleme mevcut $version';
  }

  @override
  String get dashboardUpdate => 'Güncelle';

  @override
  String get dashboardWhatsNew => 'Yenilikler';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version sürümündeki yenilikler';
  }

  @override
  String get dashboardInstalling => 'Yükleniyor...';

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
  String get contactRequestsTitle => 'Kişiler';

  @override
  String get messengerContactRequestsSection => 'Kişi istekleri';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni istek',
      one: '1 yeni istek',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Ara';

  @override
  String get contactRequestsIncoming => 'Gelen';

  @override
  String get contactRequestsSent => 'Gönderilen';

  @override
  String get contactRequestsSearchHint => 'Takma ad veya e-posta';

  @override
  String get contactRequestSent => 'İstek gönderildi';

  @override
  String get contactRequestsNoUsers => 'Kullanıcı bulunamadı';

  @override
  String get contactRequestsSearchHelp =>
      'Tam takma ad veya e-posta girin\nve ara\'ya basın';

  @override
  String get contactRequestsSendTooltip => 'İstek gönder';

  @override
  String get contactRequestTitle => 'Kişi isteği';

  @override
  String contactRequestConfirm(String name) {
    return '$name kişisine istek gönderilsin mi?';
  }

  @override
  String get contactRequestSend => 'Gönder';

  @override
  String get contactRequestsNoIncoming => 'Gelen istek yok';

  @override
  String get contactRequestsNoSent => 'Gönderilen istek yok';

  @override
  String get contactRequestStatusPending => 'Yanıt bekleniyor';

  @override
  String get contactRequestStatusAccepted => 'Kabul edildi';

  @override
  String get contactRequestStatusRejected => 'Reddedildi';

  @override
  String get userSearchTitle => 'Kullanıcı bul';

  @override
  String get userSearchHint => 'Takma ad, telefon veya e-posta';

  @override
  String get userSearchHelper =>
      'Aramak için @takmaad, e-posta veya isim girin';

  @override
  String get userSearchNoUsers => 'Kullanıcı bulunamadı';

  @override
  String get userProfileShareContact => 'Kişiyi paylaş';

  @override
  String get userProfileShareContactDesc => 'Kişi bağlantısını gönder';

  @override
  String get userProfileCopyLink => 'Bağlantıyı kopyala';

  @override
  String get userProfileCopied => 'Kopyalandı';

  @override
  String get userProfileTitle => 'Profil';

  @override
  String get userProfileLoadError => 'Profil yükleme hatası';

  @override
  String get userProfileMessage => 'Mesaj';

  @override
  String get userProfileCall => 'Ara';

  @override
  String get userProfileRequestSent => 'İstek gönderildi';

  @override
  String get userProfileAccept => 'Kabul et';

  @override
  String get userProfileDecline => 'Reddet';

  @override
  String get userProfileAddToContacts => 'Kişilere ekle';

  @override
  String get userProfileMediaTab => 'Medya';

  @override
  String get userProfileFilesTab => 'Dosyalar';

  @override
  String get userProfileLinksTab => 'Bağlantılar';

  @override
  String get userProfileRecordingsTab => 'Kayıtlar';

  @override
  String get userProfileSummariesTab => 'Özetler';

  @override
  String get userProfileNoMedia => 'Medya dosyası yok';

  @override
  String get userProfileNoFiles => 'Dosya yok';

  @override
  String get userProfileNoLinks => 'Bağlantı yok';

  @override
  String get userProfileNoRecordings => 'Kayıt yok';

  @override
  String get userProfileNoSummaries => 'Özet yok';

  @override
  String get userProfileMeetingSummary => 'Toplantı özeti';

  @override
  String get userProfileFailedOpenChat => 'Sohbet açılamadı';

  @override
  String get sharedMediaTitle => 'Medya ve dosyalar';

  @override
  String get sharedMediaTab => 'Medya';

  @override
  String get sharedFilesTab => 'Dosyalar';

  @override
  String get sharedLinksTab => 'Bağlantılar';

  @override
  String get sharedNoMedia => 'Medya dosyası yok';

  @override
  String get sharedNoFiles => 'Dosya yok';

  @override
  String get sharedNoLinks => 'Bağlantı yok';

  @override
  String get shareToChat => 'Sohbete ilet';

  @override
  String get shareSelectChat => 'Sohbet seç';

  @override
  String get shareNoChats => 'Sohbet yok';

  @override
  String shareFilesCount(int count) {
    return '$count dosya';
  }

  @override
  String get contactsTitle => 'Kişiler';

  @override
  String get contactsAddTooltip => 'Kişi ekle';

  @override
  String get contactsSearchHint => 'Kişilerde ara...';

  @override
  String get contactsNotFound => 'Hiçbir şey bulunamadı';

  @override
  String get contactsEmpty => 'Kişi yok';

  @override
  String get contactsAdd => 'Kişi ekle';

  @override
  String get contactsPendingConfirmation => 'Onay bekleniyor';

  @override
  String get contactsMessage => 'Mesaj';

  @override
  String get contactsCall => 'Ara';

  @override
  String get contactsResend => 'İsteği yeniden gönder';

  @override
  String get contactsResendTimeout => '24 saat sonra tekrar dene';

  @override
  String get contactsResent => 'İstek yeniden gönderildi';

  @override
  String get contactsWantsToConnect => 'Sizinle bağlantı kurmak istiyor';

  @override
  String get contactsSearchPeople => 'Kişi bul';

  @override
  String get notesTitle => 'Notlar';

  @override
  String get notesAssistantSpeaking => 'Asistan konuşuyor...';

  @override
  String get notesListening => 'Dinliyor...';

  @override
  String get notesEmpty => 'Not yok';

  @override
  String get notesEmptyHint =>
      'Dikte için mikrofona basın\nveya manuel giriş için +';

  @override
  String get notesDeleteConfirm => 'Notu sil?';

  @override
  String get notesNew => 'Yeni not';

  @override
  String get notesEdit => 'Düzenle';

  @override
  String get notesTitleHint => 'Başlık';

  @override
  String get notesContentHint => 'Düşüncelerinizi yazın...';

  @override
  String get calendarTitle => 'Takvim';

  @override
  String get calendarStop => 'Durdur';

  @override
  String get calendarVoiceInput => 'Sesli giriş';

  @override
  String get calendarNewEvent => 'Yeni etkinlik';

  @override
  String get calendarAssistantSpeaking => 'Asistan konuşuyor...';

  @override
  String get calendarListening => 'Dinliyor...';

  @override
  String calendarInvitations(int count) {
    return 'Davetler ($count)';
  }

  @override
  String get calendarNoEvents => 'Etkinlik yok';

  @override
  String get calendarDayMon => 'Pzt';

  @override
  String get calendarDayTue => 'Sal';

  @override
  String get calendarDayWed => 'Çar';

  @override
  String get calendarDayThu => 'Per';

  @override
  String get calendarDayFri => 'Cum';

  @override
  String get calendarDaySat => 'Cmt';

  @override
  String get calendarDaySun => 'Paz';

  @override
  String get calendarEnterRoom => 'Odaya gir';

  @override
  String get calendarMeeting => 'Toplantı';

  @override
  String calendarLocationPrefix(String location) {
    return 'Konum: $location';
  }

  @override
  String get calendarEditEvent => 'Düzenle';

  @override
  String get calendarTitleHint => 'Başlık';

  @override
  String get calendarDescriptionHint => 'Açıklama';

  @override
  String get calendarTypeEvent => 'Etkinlik';

  @override
  String get calendarTypeMeeting => 'Toplantı';

  @override
  String get calendarTypeReminder => 'Hatırlatıcı';

  @override
  String get calendarTypeLabel => 'Tür';

  @override
  String get calendarMeetingLink => 'Toplantı bağlantısı';

  @override
  String get calendarLocationHint => 'Konum';

  @override
  String get calendarDateLabel => 'Tarih';

  @override
  String get calendarTimeLabel => 'Saat';

  @override
  String get calendarReminderLabel => 'Hatırlatıcı';

  @override
  String get calendarReminderNone => 'Yok';

  @override
  String get calendarReminder15min => '15 dk önce';

  @override
  String get calendarReminder30min => '30 dk önce';

  @override
  String get calendarReminder1hour => '1 saat önce';

  @override
  String get calendarRepeatLabel => 'Tekrar';

  @override
  String get calendarRepeatNone => 'Tekrar yok';

  @override
  String get calendarRepeatDaily => 'Her gün';

  @override
  String get calendarRepeatWeekly => 'Her hafta';

  @override
  String get calendarRepeatMonthly => 'Her ay';

  @override
  String get calendarRepeatYearly => 'Her yıl';

  @override
  String get calendarParticipants => 'Katılımcılar';

  @override
  String get calendarAddParticipant => 'Ekle';

  @override
  String get calendarSearchContacts => 'Kişilerde ara...';

  @override
  String get calendarNoContacts => 'Kişi yok';

  @override
  String get calendarStatusAccepted => 'Kabul edildi';

  @override
  String get calendarStatusDeclined => 'Reddedildi';

  @override
  String get calendarStatusMaybe => 'Belki';

  @override
  String get calendarStatusPending => 'Beklemede';

  @override
  String get calendarEndTime => 'Bitiş saati';

  @override
  String get calendarYourAnswer => 'Cevabınız:';

  @override
  String get calendarOrganizer => 'Organizatör';

  @override
  String calendarDeleteError(String error) {
    return 'Silme başarısız: $error';
  }

  @override
  String get calendarRsvpAccept => 'Kabul et';

  @override
  String get calendarRsvpMaybe => 'Belki';

  @override
  String get calendarRsvpDecline => 'Reddet';

  @override
  String get callHistoryTitle => 'Aramalar';

  @override
  String get callHistoryTab => 'Arama geçmişi';

  @override
  String get callHistoryTempMeeting => 'Geçici toplantı';

  @override
  String get callHistoryCopy => 'Kopyala';

  @override
  String get callHistoryLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get callHistoryShare => 'Paylaş';

  @override
  String get callHistoryEnter => 'Giriş yap';

  @override
  String get callHistoryAlreadyInCall => 'Zaten bir aramada';

  @override
  String get callHistoryCouldNotDeterminePeer => 'Diğer taraf belirlenemedi';

  @override
  String get callHistoryContacts => 'Kişiler';

  @override
  String get callHistoryFailedLoadRoom => 'Odanız yüklenemedi';

  @override
  String get callHistoryYourRoom => 'Odanız';

  @override
  String get callHistoryCreateMeeting => 'Toplantı oluştur';

  @override
  String get callHistoryMeetingSummaries => 'Toplantı özetleri';

  @override
  String get callHistoryMeetingRecordings => 'Toplantı kayıtları';

  @override
  String get callHistoryNoCalls => 'Arama yok';

  @override
  String get callHistoryMissed => 'Cevapsız';

  @override
  String get callHistoryRecording => 'Kayıt';

  @override
  String get callHistorySummary => 'Özet';

  @override
  String get callHistoryCallAgain => 'Tekrar ara';

  @override
  String callHistoryTodayTime(String time) {
    return 'Bugün, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Dün, $time';
  }

  @override
  String get callHistoryUnknown => 'Bilinmeyen';

  @override
  String get callHistoryDetails => 'Arama detayları';

  @override
  String get callHistoryOutgoing => 'Giden arama';

  @override
  String get callHistoryIncoming => 'Gelen arama';

  @override
  String callHistoryDuration(String duration) {
    return 'Süre: $duration';
  }

  @override
  String get callHistoryWithAI => 'AI asistan ile';

  @override
  String get callHistoryParticipants => 'Katılımcılar';

  @override
  String get callDetailYouSuffix => '(Siz)';

  @override
  String get callHistoryMeetingSummary => 'Toplantı özeti';

  @override
  String get callHistoryMoreDetails => 'Daha fazla detay';

  @override
  String get callHistorySummaryProcessing => 'Özet işleniyor...';

  @override
  String get callHistoryMeetingRecording => 'Toplantı kaydı';

  @override
  String get callHistoryProcessing => 'İşleniyor...';

  @override
  String get callHistoryCreateTranscript => 'Transkript oluştur';

  @override
  String get callHistoryNoSummaries => 'Özet yok';

  @override
  String get callHistoryRecordDuringCall => 'Arama sırasında \"Kayıt\"a basın';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Toplantı $time';
  }

  @override
  String get callHistoryTranscribing => 'Transkript ve özet oluşturuluyor...';

  @override
  String get callHistoryTranscriptCreated => 'Transkript oluşturuldu';

  @override
  String get callHistoryNoRecordings => 'Kayıt yok';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Kayıt $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Kayıt mevcut değil';

  @override
  String get callHistoryTranscriptReady => 'Transkript hazır';

  @override
  String get callHistoryTranscript => 'Transkript';

  @override
  String get callHistoryKeyPoints => 'Ana noktalar';

  @override
  String get callHistoryTasks => 'Görevler';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Atanan: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Kararlar';

  @override
  String get callHistoryShowTranscript => 'Tam transkripti göster';

  @override
  String get profileScanQr => 'QR Tara';

  @override
  String get profileMyQrCode => 'Benim QR kodum';

  @override
  String profileAddMeShare(String userId) {
    return 'Beni Taler ID\'de ekle!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Seni eklemek için bu kodu göster';

  @override
  String get profileEditDesc => 'Ad, soyad, baba adı, doğum tarihi';

  @override
  String get profileAboutMe => 'Hakkımda';

  @override
  String get profileAboutMeDesc =>
      'Değerler, beceriler, ilgi alanları ve daha fazlası';

  @override
  String get profileNotes => 'Notlar';

  @override
  String get profileNotesDesc => 'Düşünceler, fikirler ve notlar';

  @override
  String get profileAvatarUpdated => 'Avatar güncellendi';

  @override
  String get profileNickname => 'Takma ad';

  @override
  String get profileNotSet => 'Ayarlanmadı';

  @override
  String get profileChangeNickname => 'Takma adı değiştir';

  @override
  String get profileNicknameUpdated => 'Takma ad güncellendi';

  @override
  String get profileShareLabel => 'Paylaş';

  @override
  String get profileScanQrCode => 'QR kodu tara';

  @override
  String get profilePointCamera => 'Kamerayı QR koda yönelt';

  @override
  String get profilePhotoCamera => 'Fotoğraf çek';

  @override
  String get profilePhotoGallery => 'Galeriden seç';

  @override
  String get editProfilePatronymic => 'Baba adı (isteğe bağlı)';

  @override
  String get editProfileDateFormat => 'GG.AA.YYYY';

  @override
  String get aboutMeTitle => 'Hakkımda';

  @override
  String get aboutMeClickToFill => 'Doldurmak için tıklayın';

  @override
  String get aboutMeCoreValues => 'Değerler';

  @override
  String get aboutMeWorldview => 'Dünya görüşü';

  @override
  String get aboutMeSkills => 'Beceriler';

  @override
  String get aboutMeInterests => 'İlgi alanları';

  @override
  String get aboutMeDesires => 'İstekler';

  @override
  String get aboutMeBackground => 'Profil';

  @override
  String get aboutMeLikes => 'Beğeniler';

  @override
  String get aboutMeDislikes => 'Beğenmediklerim';

  @override
  String get aboutMeDeleteSection => 'Bölümü sil?';

  @override
  String get aboutMeDeleteConfirm => 'Bu bölümdeki tüm veriler silinecek.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Bağlantı hatası: $error';
  }

  @override
  String get aboutMeVisibility => 'Görünürlük';

  @override
  String get aboutMeTags => 'Etiketler';

  @override
  String get aboutMeAddTag => 'Etiket ekle...';

  @override
  String get aboutMeDescription => 'Açıklama';

  @override
  String get aboutMeDescribeLong => 'Daha fazla bilgi ver...';

  @override
  String get aboutMeVisibilityEveryone => 'Herkes';

  @override
  String get aboutMeVisibilityContacts => 'Kişiler';

  @override
  String get aboutMeVisibilityOnlyMe => 'Sadece ben';

  @override
  String get settingsProfileSubtitle => 'Profil';

  @override
  String get settingsWallpaper => 'Duvar Kağıdı';

  @override
  String get settingsWallpaperDesc => 'Tüm uygulama için arka plan resmi';

  @override
  String get settingsWallpaperNone => 'Yok';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsKycVerification => 'Kimlik Doğrulama (KYC)';

  @override
  String get settingsOrganizations => 'Organizasyonlar';

  @override
  String get incomingCallLabel => 'Gelen arama';

  @override
  String get incomingCallDecline => 'Reddet';

  @override
  String get incomingCallAccept => 'Kabul et';

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
  String get meshIncomingCallLabel => '📡 Gelen mesh araması';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Mesh cihazı $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Önce mevcut aramayı bitir';

  @override
  String get callPopupTransportTitle => 'Arama ile';

  @override
  String get callPopupTransportMesh => '📡 Mesh (eşler arası)';

  @override
  String get callPopupTransportLk => '📞 Sunucu';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Kişi mesh üzerinden ulaşılamaz';

  @override
  String get meshOnboardingTitle =>
      '📡 Mesh aramaları için uygulama açık olmalı';

  @override
  String get meshOnboardingBody =>
      'Telefon kilitliyken, mesh aramaları ~30 saniye sonra düşebilir (iOS kısıtlaması).';

  @override
  String get meshOnboardingAck => 'Anladım';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Kişi listenizde değil';

  @override
  String get meshCallStatusInviting => 'Aranıyor…';

  @override
  String get meshCallStatusConnecting => 'Bağlanıyor…';

  @override
  String get meshCallEndedUserHangup => 'Arama sona erdi';

  @override
  String get meshCallEndedRemoteHangup => 'Karşı taraf sonlandırdı';

  @override
  String get meshCallEndedRejected => 'Reddedildi';

  @override
  String get meshCallEndedNoAnswer => 'Yanıt yok';

  @override
  String get meshCallEndedConnectionLost => 'Bağlantı kaybedildi';

  @override
  String get meshCallEndedError => 'Bağlantı hatası';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Güvenilir mesh aramaları';

  @override
  String get batteryExemptionBody =>
      'Android\'in arka planda mesh\'i kapatmaması için uygulamanın pil kısıtlamaları olmadan çalışmasına izin verin.';

  @override
  String get batteryExemptionAccept => 'Ayarları aç';

  @override
  String get batteryExemptionDismiss => 'Şimdi değil';

  @override
  String get groupCamera => 'Kamera';

  @override
  String get groupGallery => 'Galeri';

  @override
  String get groupAvatarUpdated => 'Grup avatarı güncellendi';

  @override
  String get groupNameTitle => 'Grup adı';

  @override
  String get groupEnterName => 'Ad girin';

  @override
  String get groupDescriptionTitle => 'Grup açıklaması';

  @override
  String get groupEnterDescription => 'Grup açıklaması girin';

  @override
  String get groupChangeRoleTitle => 'Rolü değiştir';

  @override
  String get groupRemoveMemberTitle => 'Üyeyi kaldır';

  @override
  String get groupDescription => 'Açıklama';

  @override
  String get groupAddDescription => 'Grup açıklaması ekle';

  @override
  String get groupNoDescription => 'Açıklama yok';

  @override
  String get groupMediaAndFiles => 'Medya ve dosyalar';

  @override
  String get groupMuteNotifications => 'Bildirimleri sessize al';

  @override
  String get groupMuted => 'Sessize alındı';

  @override
  String get groupNoResults => 'Sonuç yok';

  @override
  String get authInvalidCode => 'Geçersiz kod. Tekrar deneyin.';

  @override
  String get loginSubtitle => 'E-posta ve şifre kullanın';

  @override
  String get emailRequired => 'E-posta girin';

  @override
  String get emailInvalid => 'Geçersiz e-posta';

  @override
  String get passwordRequired => 'Şifre girin';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Taler ekosisteminin tamamı için tek hesap';

  @override
  String get usernameOptional => 'Kullanıcı adı (isteğe bağlı)';

  @override
  String get usernameMinLength => 'En az 3 karakter';

  @override
  String get usernameMaxLength => 'En fazla 30 karakter';

  @override
  String get usernameInvalid => 'Sadece harfler, rakamlar ve _';

  @override
  String get biometricLoginReason => 'Taler ID\'ye giriş yapın';

  @override
  String get docTypePassport => 'Pasaport';

  @override
  String get docTypeIdCard => 'Kimlik Kartı';

  @override
  String get docTypeDriverLicense => 'Sürücü Belgesi';

  @override
  String get docTypeResidencePermit => 'Oturma İzni';

  @override
  String addressApartment(String number) {
    return 'daire $number';
  }

  @override
  String get failedToUpdateProfile => 'Profil güncellenemedi';

  @override
  String get failedToStartKyb => 'KYB doğrulaması başlatılamadı';

  @override
  String get orgUpdated => 'Organizasyon güncellendi';

  @override
  String get failedToUpdateOrg => 'Organizasyon güncellenemedi';

  @override
  String get failedToChangeRole => 'Rol değiştirilemedi';

  @override
  String get failedToRemoveMember => 'Üye kaldırılamadı';

  @override
  String get capabilityMessagesTitle => 'Mesajlar';

  @override
  String get capabilityMessagesDesc =>
      'Mesajları kontrol edin veya birine yazın. Örneğin: \"Viktor\'a yaz: bir saat içinde orada olacağım\"';

  @override
  String get capabilityCallsTitle => 'Aramalar';

  @override
  String get capabilityCallsDesc =>
      'Herhangi bir kişiyi sesli arayın. Örneğin: \"Viktor Viktorov\'u ara\"';

  @override
  String get capabilityChatTitle => 'Sohbet Geçmişi';

  @override
  String get capabilityChatDesc =>
      'Sohbet geçmişini analiz edeceğim. Örneğin: \"Viktor ile ne konuştuk?\"';

  @override
  String get capabilityProfileTitle => 'Profil';

  @override
  String get capabilityProfileDesc =>
      'Profilinizi göstereceğim veya güncelleyeceğim. Örneğin: \"Profilimi göster\"';

  @override
  String get capabilityCoachingTitle => 'Koçluk';

  @override
  String get capabilityCoachingDesc =>
      'Modlar: ICF koçluk, psikolog, İK danışmanlığı. Şunu söyleyin: \"Koçluk yapalım\"';

  @override
  String get capabilityCalendarTitle => 'Takvim';

  @override
  String get capabilityCalendarDesc =>
      'Bir toplantı planlayın veya hatırlatıcı ayarlayın. Örneğin: \"Yarın saat 15:00\'te Viktor ile toplantı planla\"';

  @override
  String get capabilityNotesTitle => 'Notlar';

  @override
  String get capabilityNotesDesc =>
      'Bir düşünceyi kaydedin veya son notları okuyun. Örneğin: \"Bir fikir yaz...\" veya \"Son notları oku\"';

  @override
  String get assistantCallConfirm => 'Arama yapılsın mı?';

  @override
  String get callNoAnswer => 'Cevap yok';

  @override
  String get contactDelete => 'Kişiyi kaldır';

  @override
  String get contactDeleteTitle => 'Kişiyi kaldır';

  @override
  String get contactDeleteConfirm => 'Emin misiniz? Bu kişi kaldırılacak.';

  @override
  String get contactBlock => 'Engelle';

  @override
  String get contactBlockTitle => 'Kullanıcıyı engelle';

  @override
  String get contactBlockConfirm =>
      'Bu kullanıcı size mesaj gönderemeyecek veya sizi arayamayacak.';

  @override
  String get contactUnblock => 'Engeli kaldır';

  @override
  String get contactBlocked => 'Engellendi';

  @override
  String get contactYouAreBlocked => 'Bu kullanıcı sizi engelledi';

  @override
  String get chatBlockedByYou => 'Bu kullanıcıyı engellediniz';

  @override
  String get chatYouAreBlocked => 'Bu kullanıcı tarafından engellendiniz';

  @override
  String get chatNotContacts =>
      'Mesaj göndermek için bu kullanıcıyı kişilere ekleyin';

  @override
  String get contactRevokeRequest => 'İsteği geri çek';

  @override
  String get messengerPoll => 'Anket';

  @override
  String get messengerCreatePoll => 'Anket Oluştur';

  @override
  String get messengerPollQuestion => 'Soru';

  @override
  String messengerPollOption(int number) {
    return 'Seçenek $number';
  }

  @override
  String get messengerPollAddOption => 'Seçenek ekle';

  @override
  String get messengerPollAnonymous => 'Anonim oylama';

  @override
  String get messengerPollMultiple => 'Çoklu seçim';

  @override
  String get messengerPollCreateError => 'Anket oluşturulamadı';

  @override
  String get messengerPollUnavailable => 'Anket kullanılamıyor';

  @override
  String get messengerPollMultipleNote => 'Birden fazla seçebilirsiniz';

  @override
  String messengerPollVotes(int count) {
    return '$count oy';
  }

  @override
  String get messengerVideoMessage => 'Video mesajı';

  @override
  String get messengerVideoRecordError => 'Video kaydetme hatası';

  @override
  String get messengerVideoPlaybackError => 'Video oynatılamadı';

  @override
  String get messengerGalleryAccessError => 'Galerilere erişim yok';

  @override
  String get messengerSearchInChat => 'Sohbette ara...';

  @override
  String get messengerSaveToFavorites => 'Favorilere kaydet';

  @override
  String get messengerSavedToFavorites => 'Favorilere kaydedildi';

  @override
  String get messengerSearchInMessages => 'Mesajlarda ara...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Mesajlarda bulundu ($count)';
  }

  @override
  String get messengerGroupDefault => 'Grup';

  @override
  String get messengerUserDefault => 'Kullanıcı';

  @override
  String get messengerPin => 'Sabitle';

  @override
  String get messengerUnpin => 'Sabitliği kaldır';

  @override
  String get messengerArchive => 'Arşivle';

  @override
  String get messengerUnarchive => 'Arşivden çıkar';

  @override
  String get messengerDeleteChat => 'Sohbeti sil';

  @override
  String get messengerDeleteChatTitle => 'Sohbeti sil?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '$name ile sohbeti sil? Bu işlem geri alınamaz.';
  }

  @override
  String get messengerCreateChannel => 'Kanal Oluştur';

  @override
  String get messengerChannelName => 'Ad';

  @override
  String get messengerChannelDescription => 'Açıklama (isteğe bağlı)';

  @override
  String get messengerChannelCreateError => 'Kanal oluşturulamadı';

  @override
  String get messengerFilterAll => 'Tümü';

  @override
  String get messengerFilterUnread => 'Okunmamış';

  @override
  String get messengerFilterPersonal => 'Kişisel';

  @override
  String get messengerFilterGroups => 'Gruplar';

  @override
  String get messengerFilterChannels => 'Kanallar';

  @override
  String get messengerArchivedSection => 'Arşivlenmiş';

  @override
  String get messengerSavedSection => 'Favoriler';

  @override
  String get messengerSavedSubtitle => 'Hafızaya kaydet';

  @override
  String messengerArchiveTitle(int count) {
    return 'Arşiv ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Arşiv boş';

  @override
  String messengerYouPrefix(String message) {
    return 'Sen: $message';
  }

  @override
  String get messengerMissedCall => 'Cevapsız çağrı';

  @override
  String get messengerSavedTitle => 'Favoriler';

  @override
  String get messengerNoSavedMessages => 'Kaydedilmiş mesaj yok';

  @override
  String get messengerSavedHint =>
      'Bir mesaja uzun bas → \"Favorilere kaydet\"';

  @override
  String get messengerDefaultFile => 'Dosya';

  @override
  String get messengerTopicDefault => 'Genel';

  @override
  String get messengerTopicNew => 'Yeni Konu';

  @override
  String get messengerTopicNameHint => 'Konu adı';

  @override
  String get messengerTopicIcon => 'Simge';

  @override
  String messengerTopicCount(int count) {
    return '$count konu';
  }

  @override
  String get messengerNoTopics => 'Konu yok';

  @override
  String get messengerNoMessages => 'Mesaj yok';

  @override
  String get you => 'Sen';

  @override
  String get messengerThread => 'Konu';

  @override
  String get messengerThreadReply => 'yanıtla';

  @override
  String get messengerThreadReplies => 'yanıtlar';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Yanıt yok';

  @override
  String get messengerReplyHint => 'Konuya yanıtla...';

  @override
  String get messengerContactName => 'Kişi adı';

  @override
  String messengerOriginalName(String name) {
    return 'Orijinal ad: $name';
  }

  @override
  String get messengerDisplayName => 'Görünen ad';

  @override
  String messengerShareContact(String name) {
    return 'Taler ID\'de kişi: $name';
  }

  @override
  String get messengerAutoDelete => 'Mesajları otomatik sil';

  @override
  String get messengerAutoDeleteOff => 'Kapalı';

  @override
  String get messengerAutoDelete7d => '7 gün';

  @override
  String get messengerAutoDelete30d => '30 gün';

  @override
  String get messengerAutoDelete90d => '90 gün';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count gün';
  }

  @override
  String get messengerSettingsHeader => 'Ayarlar';

  @override
  String get messengerAdminOnly => 'Yalnızca yönetici gönderimi';

  @override
  String get messengerAdminOnlyDesc => 'Üyeler sadece okuyabilir';

  @override
  String get messengerTopics => 'Konular';

  @override
  String get messengerTopicsDesc => 'Sohbeti konulara ayır';

  @override
  String get aiTwinSection => 'AI Ses İkizi';

  @override
  String get aiTwinEnabled => 'AI İkizini Etkinleştir';

  @override
  String get aiTwinEnabledDesc =>
      'Cevap vermezseniz, AI ikiziniz sizin sesinizle aramayı alır';

  @override
  String get aiTwinTimeout => 'Yanıt süresi';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds sn';
  }

  @override
  String get aiTwinPrompt => 'AI talimatları';

  @override
  String get aiTwinPromptSubtitle =>
      'AI ikizi kendini nasıl tanıtmalı ve ne hakkında konuşmalı';

  @override
  String aiTwinPromptHint(String name) {
    return 'Merhaba, ben $name\'in AI ses ikiziyim. $name şu anda cevap veremiyor. Kimin aradığını ve ne hakkında olduğunu söyleyin — ileteceğim.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Özel ses klonlama yakında geliyor. Şimdilik AI, $name\'in sesiyle konuşuyor.';
  }

  @override
  String get aiTwinDefaultName => 'sahip';

  @override
  String get aiTwinPromptReset => 'Sıfırla';

  @override
  String get callHistoryAiTwinAnswered => 'AI İKİZİ CEVAPLADI';

  @override
  String get callHistoryAiTwinSummary => 'ARAMA ÖZETİ';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSKRİPT';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '$name\'den';
  }

  @override
  String get aiTwinOfferTitle => 'Cevap vermiyor';

  @override
  String aiTwinOfferBody(String name) {
    return '$name cevap vermiyor. AI ses ikiziyle mesaj bırakmak ister misiniz?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Kullanıcı';

  @override
  String get aiTwinOfferAccept => 'Evet, mesaj bırak';

  @override
  String get aiTwinOfferKeepWaiting => 'Beklemeye devam et';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'AI yedeğiniz';

  @override
  String get aiTwinHeroSubtitle =>
      'Cevap veremediğinizde aramaları sesinizle yanıtlar.';

  @override
  String get aiTwinProfileTitle => 'AI Yedeği';

  @override
  String get aiTwinProfileDesc => 'Aramaları sesinizle yanıtlar';

  @override
  String get aiTwinBadgeOn => 'AÇIK';

  @override
  String get aiAnalystTitle => 'AI Analisti';

  @override
  String get aiAnalystSubtitle => 'Dosyalar, görevler, analiz — Claude';

  @override
  String get channelsDiscover => 'Kanal bul';

  @override
  String get channelsSearchHint => 'Kanalları ara';

  @override
  String get channelsSubscribers => 'aboneler';

  @override
  String get channelsSubscribe => 'Abone ol';

  @override
  String get channelsUnsubscribe => 'Abonelikten çık';

  @override
  String get channelsSubscribedLabel => 'Abonesiniz';

  @override
  String get channelsSettings => 'Kanal ayarları';

  @override
  String get channelsDelete => 'Kanalı sil';

  @override
  String get channelsDeleteConfirm => 'Kanalı kalıcı olarak sil?';

  @override
  String get channelsEmpty => 'Henüz kanal yok';

  @override
  String get channelsOpen => 'Aç';

  @override
  String get channelsNameLabel => 'Ad';

  @override
  String get channelsDescriptionLabel => 'Açıklama';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Sahibi abonelikten çıkamaz. Bunun yerine kanalı silin.';

  @override
  String get channelsNotFoundRedirect => 'Kanal artık mevcut değil';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arama',
      one: '$count arama',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '$count dosya',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komut',
      one: '$count komut',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resim',
      one: '$count resim',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adım',
      one: '$count adım',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Kaydedilen Mesajlar';

  @override
  String get savedSubtitle => 'Özel bulutunuz';

  @override
  String get savedOpenError => 'Kaydedilen Mesajlar açılamadı';

  @override
  String get billingWalletTitle => 'Cüzdan';

  @override
  String get billingBuyPackage => 'Paket satın al';

  @override
  String get billingCurrentBalance => 'Mevcut bakiye';

  @override
  String get billingPackagesTitle => 'Paketler';

  @override
  String get billingPackagesUnavailable => 'Paketler mevcut değil';

  @override
  String get billingRecentOperations => 'Son işlemler';

  @override
  String get billingAllOperations => 'Tüm işlemler';

  @override
  String get billingNoOperations => 'İşlem yok';

  @override
  String get billingOperationsTitle => 'İşlemler';

  @override
  String get billingOperationsEmptyTitle => 'Henüz işlem yok';

  @override
  String get billingOperationsEmptySubtitle =>
      'AI özellikleri için yapılan yüklemeler ve ücretlendirmeler burada görünecek';

  @override
  String get billingPricebookTitle => 'Özellik fiyatları';

  @override
  String get billingPricebookUnavailable => 'Fiyat listesi mevcut değil';

  @override
  String get billingAiFeaturesTitle => 'AI özellikleri';

  @override
  String get billingInsufficientFundsTitle => 'Yetersiz bakiye';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Bu özelliği kullanmak için bakiyenizi doldurun.';

  @override
  String billingRequiredLine(String required) {
    return 'Gerekli: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Mevcut: $available μTAL';
  }

  @override
  String get billingTopUp => 'Bakiye yükle';

  @override
  String get billingCancel => 'İptal';

  @override
  String get billingRetry => 'Tekrar dene';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Bakiye düşük: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Cüzdan & Bakiye';

  @override
  String get billingSectionHeader => 'Faturalama & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Sesli asistan';

  @override
  String get billingFeatureWebSearch => 'Asistan web araması';

  @override
  String get billingFeatureAiTwin => 'Ses ikizi';

  @override
  String get billingFeatureAiTwinLong => 'Ses ikizi (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Giden bot';

  @override
  String get billingFeatureOutboundCallLong => 'Giden arama botu';

  @override
  String get billingFeatureWhisperTranscribe => 'Çağrı transkripsiyonu';

  @override
  String get billingFeatureMeetingSummary => 'AI çağrı özetleri';

  @override
  String get billingConfigureAiTwin => 'AI ikizini yapılandır';

  @override
  String get billingWebSearchSubtitle => '(asistan tarafından kullanılır)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Paket satın alındı: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Önerilen';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Bakiye tükendi — oturum sona erdi';

  @override
  String get billingSessionTerminatedGeneric => 'Asistan oturumu sona erdi';

  @override
  String billingBuyForPrice(String price) {
    return '€$price karşılığında satın al';
  }

  @override
  String get billingTxTypeTopup => 'Bakiye yükleme';

  @override
  String get billingTxTypeRefund => 'İade';

  @override
  String get billingTxTypeSpend => 'Ücretlendirme';

  @override
  String get billingUnitMinute => 'dakika';

  @override
  String get billingUnitRequest => 'istek';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K token';

  @override
  String get billingUnitCall => 'arama';

  @override
  String get groupCallSelectParticipants => 'Katılımcıları seç';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Ara';

  @override
  String get groupCallMaxReached => 'Maksimum 7 katılımcı';

  @override
  String get groupCallLobbyTitle => 'Grup • Lobi';

  @override
  String groupCallHostLabel(String name) {
    return 'Ev sahibi: $name';
  }

  @override
  String get groupCallMicHint => 'Bağlanınca mikrofon açılacak';

  @override
  String get groupCallCancel => 'İptal';

  @override
  String get groupCallNoAnswer => 'Kimse cevap vermedi';

  @override
  String get groupCallEndedByHost => 'Arama ev sahibi tarafından sonlandırıldı';

  @override
  String get groupCallAllLeft => 'Herkes aramadan ayrıldı';

  @override
  String get groupCallEnded => 'Arama sona erdi';

  @override
  String groupCallActiveTitle(int count) {
    return 'Grup • $count';
  }

  @override
  String get groupCallConnectionLost => 'Bağlantı kesildi';

  @override
  String get groupCallMuteRequested =>
      'Ev sahibi herkesin sessize almasını istedi';

  @override
  String get groupCallUnmute => 'Sesi aç';

  @override
  String get groupCallMute => 'Sessize al';

  @override
  String get groupCallMuteAll => 'Herkesi sessize al';

  @override
  String get groupCallLeave => 'Ayrıl';

  @override
  String get groupCallStatusCalling => 'aranıyor…';

  @override
  String get groupCallStatusDeclined => 'reddedildi';

  @override
  String get groupCallStatusTimeout => 'cevap yok';

  @override
  String get groupCallStatusLeft => 'ayrıldı';

  @override
  String groupCallKickConfirm(String name) {
    return '$name aramadan çıkarılsın mı?';
  }

  @override
  String get groupCallCancelAction => 'İptal';

  @override
  String get groupCallActiveBanner => 'Aktif arama';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Grup: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Grup: $host';
  }

  @override
  String get groupCallCreateError => 'Arama oluşturulamadı';

  @override
  String get groupCallJoinError => 'Aramaya katılamadı';

  @override
  String get groupCallLivekitError => 'LiveKit hatası';

  @override
  String get groupCallDone => 'Tamam';

  @override
  String get groupCallNoResults => 'Sonuç yok';

  @override
  String get groupCallNoContacts => 'Kişi yok';

  @override
  String get meshGcContactOffline => 'Bu Wi-Fi\'da değil';

  @override
  String get meshGcOnlineViaMesh => 'Mesh üzerinden çevrimiçi';

  @override
  String get meshGcMaxInvitees =>
      'Grup aramaları en fazla 4 davetliyi destekler (toplam 5 kişi).';

  @override
  String get meshGcStart => 'Grup çağrısını başlat';

  @override
  String get meshGcCancel => 'İptal';

  @override
  String get meshGcStatusCalling => 'Aranıyor…';

  @override
  String get meshGcStatusJoined => 'Katıldı';

  @override
  String get meshGcStatusDeclined => 'Reddedildi';

  @override
  String get meshGcStatusNoAnswer => 'Yanıt yok';

  @override
  String get meshGcStatusConnectionFailed => 'Bağlantı başarısız';

  @override
  String get meshGcStatusLeft => 'Ayrıldı';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Önce mevcut çağrınızı bitirin.';

  @override
  String get presenceOnline => 'çevrimiçi';

  @override
  String get presenceLastSeenJustNow => 'az önce görüldü';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return '$minutes dk önce görüldü';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'bugün $time görüldü';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'dün $time görüldü';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return '$date görüldü';
  }

  @override
  String get presenceLastSeenRecently => 'son zamanlarda görüldü';

  @override
  String get privacySectionTitle => 'Gizlilik';

  @override
  String get privacyLastSeenLabel => 'Son görülme zamanınızı kim görebilir';

  @override
  String get privacyEveryone => 'Herkes';

  @override
  String get privacyContacts => 'Sadece kişiler';

  @override
  String get privacyNobody => 'Kimse';

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
