// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Cari';

  @override
  String get appSubtitle => 'Identitas ekosistem terpadu';

  @override
  String get login => 'Masuk';

  @override
  String get loginButton => 'Masuk';

  @override
  String get register => 'Buat Akun';

  @override
  String get registerButton => 'Buat Akun';

  @override
  String get email => 'Email';

  @override
  String get password => 'Kata Sandi';

  @override
  String get confirmPassword => 'Konfirmasi Kata Sandi';

  @override
  String get firstName => 'Nama Depan';

  @override
  String get lastName => 'Nama Belakang';

  @override
  String get noAccount => 'Belum punya akun?';

  @override
  String get createOne => 'Buat satu';

  @override
  String get haveAccount => 'Sudah punya akun?';

  @override
  String get signIn => 'Masuk';

  @override
  String get passwordMinLength => 'Minimal 8 karakter';

  @override
  String get invalidEmail => 'Masukkan email yang valid';

  @override
  String get fieldRequired => 'Kolom wajib diisi';

  @override
  String get twoFATitle => 'Otentikasi Dua Faktor';

  @override
  String get twoFASubtitle =>
      'Masukkan kode 6 digit dari aplikasi autentikator Anda';

  @override
  String get twoFACode => 'Kode 2FA';

  @override
  String get verify => 'Verifikasi';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organisasi';

  @override
  String get tabSettings => 'Pengaturan';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get phone => 'Telepon';

  @override
  String get country => 'Negara';

  @override
  String get dateOfBirth => 'Tanggal Lahir';

  @override
  String get documents => 'Dokumen';

  @override
  String get addDocument => 'Tambah Dokumen';

  @override
  String get noDocuments => 'Tidak ada dokumen yang diunggah';

  @override
  String get save => 'Simpan';

  @override
  String get profileUpdated => 'Profil diperbarui';

  @override
  String get personalData => 'Data Pribadi';

  @override
  String get passport => 'Paspor';

  @override
  String get drivingLicense => 'SIM';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'KTP';

  @override
  String get certificate => 'Sertifikat';

  @override
  String get notSpecified => 'Tidak ditentukan';

  @override
  String get notSpecifiedFemale => 'Tidak ditentukan';

  @override
  String get documentType => 'Jenis Dokumen';

  @override
  String get passportId => 'Paspor / KTP';

  @override
  String get diplomaCertificate => 'Diploma / Sertifikat';

  @override
  String get loadError => 'Kesalahan memuat';

  @override
  String get verification => 'Verifikasi';

  @override
  String get countryAustria => 'Austria';

  @override
  String get countryGermany => 'Jerman';

  @override
  String get countryRussia => 'Rusia';

  @override
  String get countryUkraine => 'Ukraina';

  @override
  String get countryKazakhstan => 'Kazakhstan';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryOther => 'Lainnya';

  @override
  String get kycTitle => 'Verifikasi KYC';

  @override
  String get kycVerified => 'Terverifikasi';

  @override
  String get kycPending => 'Menunggu';

  @override
  String get kycRejected => 'Ditolak';

  @override
  String get kycUnverified => 'Belum Terverifikasi';

  @override
  String get kycVerifiedDesc =>
      'Identitas Anda telah diverifikasi. Anda memiliki akses penuh ke semua fitur ekosistem Taler.';

  @override
  String get kycPendingDesc =>
      'Dokumen Anda sedang ditinjau. Ini biasanya memakan waktu 1-2 hari kerja.';

  @override
  String get kycRejectedDesc =>
      'Verifikasi gagal. Silakan tinjau alasannya dan kirim ulang dokumen Anda.';

  @override
  String get kycUnverifiedDesc =>
      'Selesaikan verifikasi untuk membuka akses penuh ke fitur keuangan ekosistem Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Mulai Verifikasi';

  @override
  String get retryVerification => 'Coba Lagi Verifikasi';

  @override
  String verifiedAt(String date) {
    return 'Terverifikasi: $date';
  }

  @override
  String get documentsSubmitted => 'Dokumen dikirim untuk ditinjau';

  @override
  String get documentsSubmittedDesc =>
      'Peninjauan biasanya memakan waktu 1-2 hari kerja. Anda akan menerima notifikasi push dengan hasilnya.';

  @override
  String get securityAes => 'Data Anda dilindungi dengan enkripsi AES-256';

  @override
  String get verificationTime => 'Verifikasi memakan waktu 1-2 hari kerja';

  @override
  String get pushNotification =>
      'Anda akan menerima notifikasi push dengan hasilnya';

  @override
  String get kycWebOnly => 'Verifikasi KYC hanya tersedia di aplikasi seluler.';

  @override
  String verificationError(String code) {
    return 'Kesalahan verifikasi: $code';
  }

  @override
  String get organizations => 'Organisasi';

  @override
  String get noOrganizations => 'Tidak ada organisasi';

  @override
  String get noOrganizationsDesc => 'Buat organisasi atau terima undangan';

  @override
  String get createOrganization => 'Buat Organisasi';

  @override
  String get newOrganization => 'Organisasi Baru';

  @override
  String get orgName => 'Nama *';

  @override
  String get orgDescription => 'Deskripsi';

  @override
  String get orgEmail => 'Email Kontak';

  @override
  String get orgWebsite => 'Situs Web';

  @override
  String get orgLegalAddress => 'Alamat Legal';

  @override
  String get create => 'Buat';

  @override
  String get organization => 'Organisasi';

  @override
  String get contacts => 'Kontak';

  @override
  String members(int count) {
    return 'Anggota ($count)';
  }

  @override
  String get inviteMember => 'Undang Anggota';

  @override
  String get invite => 'Undang';

  @override
  String get sendInvite => 'Kirim Undangan';

  @override
  String inviteSent(String email) {
    return 'Undangan dikirim ke $email';
  }

  @override
  String get role => 'Peran';

  @override
  String get roleOwner => 'Pemilik';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleViewer => 'Penonton';

  @override
  String get editOrganization => 'Edit';

  @override
  String get editOrganizationTitle => 'Edit Organisasi';

  @override
  String get removeMember => 'Hapus Anggota';

  @override
  String removeMemberConfirm(String name) {
    return 'Hapus $name dari organisasi?';
  }

  @override
  String get memberRemoved => 'Anggota dihapus';

  @override
  String get roleChanged => 'Peran diubah';

  @override
  String get kybVerified => 'Terverifikasi';

  @override
  String get kybPending => 'Menunggu';

  @override
  String get kybRejected => 'Ditolak';

  @override
  String get kybNone => 'Belum Terverifikasi';

  @override
  String get kybVerification => 'Mulai Verifikasi KYB';

  @override
  String get kybStartBusiness => 'Mulai Verifikasi Bisnis';

  @override
  String get kybStatusLabel => 'Status KYB';

  @override
  String get noKyb => 'Tidak ada KYB';

  @override
  String get kybBusinessVerificationTitle => 'Verifikasi Bisnis (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organisasi berhasil diverifikasi.';

  @override
  String get kybPendingOrgDesc =>
      'Dokumen sedang ditinjau. Ini biasanya memakan waktu 1-3 hari kerja.';

  @override
  String get kybRejectedOrgDesc => 'Verifikasi gagal. Silakan coba lagi.';

  @override
  String get kybNoneOrgDesc =>
      'Verifikasi organisasi Anda untuk mengakses fitur bisnis.';

  @override
  String get invitePlus => '+ Undang';

  @override
  String get kybVerificationTitle => 'Verifikasi KYB';

  @override
  String get kybWebOnlyBusiness =>
      'Verifikasi KYB hanya tersedia di aplikasi seluler.';

  @override
  String get unknownDevice => 'Perangkat tidak dikenal';

  @override
  String get ipUnknown => 'IP tidak dikenal';

  @override
  String get currentSessionLabel => 'Saat ini';

  @override
  String get endSessionAction => 'Akhiri';

  @override
  String get deviceLoggedOut => 'Perangkat akan keluar.';

  @override
  String get acceptInvitationTitle => 'Undangan Organisasi';

  @override
  String get acceptInvitation => 'Terima Undangan';

  @override
  String get acceptInvitationDesc =>
      'Anda diundang untuk bergabung dengan organisasi di ekosistem Taler.';

  @override
  String get accept => 'Terima';

  @override
  String get reject => 'Tolak';

  @override
  String get sessions => 'Sesi Aktif';

  @override
  String get currentSession => 'Sesi saat ini';

  @override
  String get deleteSession => 'Akhiri Sesi';

  @override
  String get deleteSessionConfirm => 'Akhiri sesi ini?';

  @override
  String get sessionDeleted => 'Sesi berakhir';

  @override
  String get noSessions => 'Tidak ada sesi aktif';

  @override
  String minutesAgo(int count) {
    return '$count menit yang lalu';
  }

  @override
  String hoursAgo(int count) {
    return '$count jam yang lalu';
  }

  @override
  String daysAgo(int count) {
    return '$count hari yang lalu';
  }

  @override
  String get justNow => 'Baru saja';

  @override
  String get settings => 'Pengaturan';

  @override
  String get security => 'Keamanan';

  @override
  String get biometrics => 'Biometrik';

  @override
  String get biometricsDesc => 'Login cepat dengan Face ID atau sidik jari';

  @override
  String get biometricsConfirm =>
      'Konfirmasi biometrik untuk mengaktifkan login cepat';

  @override
  String get biometricsError =>
      'Gagal mengaktifkan biometrik. Periksa pengaturan perangkat.';

  @override
  String get changePassword => 'Ubah Kata Sandi';

  @override
  String get twoFactorAuth => 'Otentikasi Dua Faktor';

  @override
  String get currentPassword => 'Kata Sandi Saat Ini';

  @override
  String get newPassword => 'Kata Sandi Baru';

  @override
  String get confirmNewPassword => 'Konfirmasi Kata Sandi Baru';

  @override
  String get passwordChanged => 'Kata sandi diubah';

  @override
  String get wrongCurrentPassword => 'Kata sandi saat ini salah';

  @override
  String get passwordTooWeak =>
      'Kata sandi terlalu lemah: minimal 8 karakter, huruf dan angka diperlukan';

  @override
  String get passwordChangeFailed => 'Gagal mengubah kata sandi';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get permissions => 'Izin';

  @override
  String get permissionNotifications => 'Notifikasi Push';

  @override
  String get permissionNotificationsDesc => 'Panggilan, pesan, status';

  @override
  String get permissionMicrophone => 'Mikrofon';

  @override
  String get permissionMicrophoneDesc => 'Panggilan dan asisten suara';

  @override
  String get permissionCamera => 'Kamera';

  @override
  String get permissionCameraDesc => 'Panggilan video dan verifikasi';

  @override
  String get permissionLocation => 'Lokasi';

  @override
  String get permissionLocationDesc => 'Digunakan untuk verifikasi';

  @override
  String get permissionOpenSettings =>
      'Untuk mencabut izin, buka pengaturan sistem';

  @override
  String get pushKycStatus => 'Push Status KYC';

  @override
  String get pushKycStatusDesc => 'Hasil verifikasi';

  @override
  String get pushLogins => 'Push Login';

  @override
  String get pushLoginsDesc => 'Saat masuk dari perangkat baru';

  @override
  String get account => 'Akun';

  @override
  String get language => 'Bahasa';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Bahasa Antarmuka';

  @override
  String get exportData => 'Ekspor Data (GDPR)';

  @override
  String get deleteAccount => 'Hapus Akun';

  @override
  String get deleteAccountConfirm => 'Hapus akun?';

  @override
  String get deleteAccountDesc =>
      'Semua data Anda akan dihapus (GDPR). Tindakan ini tidak dapat dibatalkan.';

  @override
  String get logout => 'Keluar';

  @override
  String get logoutConfirm => 'Keluar?';

  @override
  String get logoutDesc => 'Anda akan keluar dari Taler ID di perangkat ini.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Kode PIN';

  @override
  String get pinCodeDesc => 'Login cepat dengan kode 4 digit';

  @override
  String get setupPin => 'Atur PIN';

  @override
  String get enterPin => 'Masukkan PIN';

  @override
  String get confirmPin => 'Konfirmasi PIN';

  @override
  String get pinMismatch => 'PIN tidak cocok';

  @override
  String get passwordMismatch => 'Kata sandi tidak cocok';

  @override
  String get pinSet => 'PIN berhasil diatur';

  @override
  String get enterPinToLogin => 'Masukkan PIN untuk masuk';

  @override
  String get pinIncorrect => 'PIN salah';

  @override
  String get removePin => 'Hapus PIN';

  @override
  String get pinRemoved => 'PIN dihapus';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get loading => 'Memuat...';

  @override
  String get error => 'Kesalahan';

  @override
  String get success => 'Berhasil';

  @override
  String get noData => 'Tidak ada data';

  @override
  String get failedToLoad => 'Gagal memuat data';

  @override
  String get failedToLoadProfile => 'Gagal memuat profil';

  @override
  String get failedToSave => 'Gagal menyimpan perubahan';

  @override
  String get failedToLoadOrgs => 'Gagal memuat organisasi';

  @override
  String get failedToLoadOrg => 'Gagal memuat data organisasi';

  @override
  String get failedToCreateOrg => 'Gagal membuat organisasi';

  @override
  String get failedToInvite => 'Gagal mengirim undangan';

  @override
  String get failedToAcceptInvite => 'Gagal menerima undangan';

  @override
  String get failedToLoadSessions => 'Gagal memuat sesi';

  @override
  String get failedToDeleteSession => 'Gagal mengakhiri sesi';

  @override
  String get failedToLoadKyc => 'Gagal memuat status verifikasi';

  @override
  String get failedToStartKyc => 'Gagal memulai verifikasi';

  @override
  String get verifiedPersonalInfo => 'Data Terverifikasi';

  @override
  String get middleName => 'Nama Tengah';

  @override
  String get placeOfBirth => 'Tempat Lahir';

  @override
  String get nationality => 'Kewarganegaraan';

  @override
  String get gender => 'Jenis Kelamin';

  @override
  String get genderMale => 'Laki-laki';

  @override
  String get genderFemale => 'Perempuan';

  @override
  String get docNumber => 'Nomor';

  @override
  String get docIssuedDate => 'Dikeluarkan';

  @override
  String get docValidUntil => 'Berlaku Hingga';

  @override
  String get docIssuedBy => 'Dikeluarkan Oleh';

  @override
  String get address => 'Alamat';

  @override
  String get refreshData => 'Segarkan Data';

  @override
  String get failedToLoadSumsubData => 'Gagal memuat data verifikasi';

  @override
  String get sumsubDataLoading => 'Memuat data verifikasi...';

  @override
  String get reviewResultGreen => 'Verifikasi berhasil';

  @override
  String get reviewResultRed => 'Verifikasi gagal';

  @override
  String get tabAssistant => 'Asisten';

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
  String get assistantConnecting => 'Menghubungkan…';

  @override
  String get assistantSpeaking => 'Berbicara…';

  @override
  String get assistantListening => 'Mendengarkan…';

  @override
  String get assistantTapToStart => 'Ketuk untuk memulai';

  @override
  String get assistantTapToTalk => 'Ketuk untuk berbicara dengan AI';

  @override
  String get assistantRealtimeDesc =>
      'Asisten merespons dengan suara secara real time';

  @override
  String get assistantConnectingToAssistant => 'Menghubungkan ke asisten...';

  @override
  String get assistantAiSpeaking => 'AI berbicara...';

  @override
  String get assistantAiListening => 'AI mendengarkan';

  @override
  String get assistantSpeakerOn => 'Speaker aktif';

  @override
  String get assistantSpeaker => 'Speaker';

  @override
  String get assistantEnd => 'Akhiri';

  @override
  String get assistantUnmute => 'Buka suara';

  @override
  String get assistantMicrophone => 'Mikrofon';

  @override
  String get assistantConnectionError => 'Kesalahan koneksi';

  @override
  String get tabMessenger => 'Pesan';

  @override
  String get tabCalls => 'Panggilan';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get appearance => 'Tampilan';

  @override
  String get appearanceSelect => 'Pilih Tema';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get onboardingTitle1 => 'Identitas Terpadu';

  @override
  String get onboardingDesc1 =>
      'Taler ID adalah paspor digital Anda di ekosistem Taler. Satu akun untuk semua layanan.';

  @override
  String get onboardingTitle2 => 'Keamanan Data';

  @override
  String get onboardingDesc2 =>
      'Verifikasi KYC, enkripsi AES-256, dan autentikasi dua faktor melindungi identitas Anda.';

  @override
  String get onboardingTitle3 => 'Tetap Terinformasi';

  @override
  String get onboardingDesc3 =>
      'Dapatkan pemberitahuan tentang status verifikasi, login dari perangkat baru, dan panggilan masuk.';

  @override
  String get onboardingNext => 'Berikutnya';

  @override
  String get onboardingEnableNotifications => 'Aktifkan Notifikasi';

  @override
  String get onboardingTitle4 => 'Panggilan Suara';

  @override
  String get onboardingDesc4 =>
      'Beri akses mikrofon untuk panggilan suara dan asisten AI. Anda dapat mengubah ini nanti di pengaturan.';

  @override
  String get onboardingEnableMicrophone => 'Aktifkan Mikrofon';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get onboardingSkip => 'Lewati';

  @override
  String get meshLocalNetworkPromptTitle => 'Izinkan akses jaringan lokal';

  @override
  String get meshLocalNetworkPromptBody =>
      'Untuk menemukan rekan di Wi-Fi (panggilan grup offline), iOS memerlukan izin Jaringan Lokal. Buka Pengaturan → Privasi & Keamanan → Jaringan Lokal → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Buka Pengaturan';

  @override
  String get meshLocalNetworkPromptDismiss => 'Mengerti';

  @override
  String get forgotPassword => 'Lupa kata sandi?';

  @override
  String get forgotPasswordTitle => 'Atur Ulang Kata Sandi';

  @override
  String get forgotPasswordSubtitle =>
      'Masukkan email Anda untuk menerima kode reset';

  @override
  String resetCodeSent(String email) {
    return 'Kode dikirim ke $email';
  }

  @override
  String get enterResetCode => 'Masukkan kode';

  @override
  String get resetPasswordButton => 'Atur Ulang Kata Sandi';

  @override
  String get passwordResetSuccess => 'Kata sandi berhasil diatur ulang';

  @override
  String get sendCode => 'Kirim Kode';

  @override
  String get resendCode => 'Kirim Ulang Kode';

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
  String get newGroup => 'Grup Baru';

  @override
  String get newChat => 'Chat Baru';

  @override
  String get groupName => 'Nama Grup';

  @override
  String get createGroup => 'Buat Grup';

  @override
  String get groupInfo => 'Info Grup';

  @override
  String groupMembers(int count) {
    return 'Anggota ($count)';
  }

  @override
  String get addMembers => 'Tambah Anggota';

  @override
  String get leaveGroup => 'Keluar Grup';

  @override
  String get leaveGroupConfirm => 'Keluar dari grup ini?';

  @override
  String get deleteGroup => 'Hapus Grup';

  @override
  String get deleteGroupConfirm =>
      'Hapus grup ini? Ini tidak dapat dibatalkan.';

  @override
  String get groupRoleOwner => 'Pemilik';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Anggota';

  @override
  String get selectParticipants => 'Pilih peserta';

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get changeRole => 'Ubah Peran';

  @override
  String get groupCreated => 'Grup dibuat';

  @override
  String memberJoined(String name) {
    return '$name bergabung';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name keluar';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name dihapus';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name sekarang $role';
  }

  @override
  String participantsCount(int count) {
    return '$count peserta';
  }

  @override
  String get enterGroupName => 'Masukkan nama grup';

  @override
  String get muteNotifications => 'Bisukan notifikasi';

  @override
  String get unmuteNotifications => 'Bunyikan notifikasi';

  @override
  String get muteFor1Hour => 'Selama 1 jam';

  @override
  String get muteFor8Hours => 'Selama 8 jam';

  @override
  String get muteFor2Days => 'Selama 2 hari';

  @override
  String get muteForever => 'Selamanya';

  @override
  String get muted => 'Dibisukan';

  @override
  String get tabTranslator => 'Terjemahkan';

  @override
  String get translatorTitle => 'Penerjemah';

  @override
  String get translatorSelectLanguage => 'Pilih bahasa';

  @override
  String get translatorDownloading => 'Mengunduh model bahasa...';

  @override
  String get translatorDownloadingHint =>
      'Internet hanya diperlukan untuk unduhan pertama';

  @override
  String get translatorTypeHint => 'Ketik teks atau ketuk mikrofon';

  @override
  String get translatorListening => 'Mendengarkan...';

  @override
  String get translatorTapToSpeak => 'Ketuk untuk berbicara';

  @override
  String get translatorTapToStop => 'Ketuk untuk berhenti';

  @override
  String get translatorAutoSpeak => 'Otomatis berbicara';

  @override
  String get translatorCopied => 'Disalin';

  @override
  String get translatorLangRu => 'Rusia';

  @override
  String get translatorLangEn => 'Inggris';

  @override
  String get translatorLangDe => 'Jerman';

  @override
  String get translatorLangFr => 'Perancis';

  @override
  String get translatorLangEs => 'Spanyol';

  @override
  String get translatorLangIt => 'Italia';

  @override
  String get translatorLangPt => 'Portugis';

  @override
  String get translatorLangTr => 'Turki';

  @override
  String get translatorLangZh => 'Cina';

  @override
  String get translatorLangJa => 'Jepang';

  @override
  String get translatorLangKo => 'Korea';

  @override
  String get translatorLangAr => 'Arab';

  @override
  String get translatorLangPl => 'Polandia';

  @override
  String get translatorLangSk => 'Slovakia';

  @override
  String get translatorLangCs => 'Ceko';

  @override
  String get translatorLangNl => 'Belanda';

  @override
  String get translatorLangSv => 'Swedia';

  @override
  String get translatorLangDa => 'Denmark';

  @override
  String get translatorLangNo => 'Norwegia';

  @override
  String get translatorLangFi => 'Finlandia';

  @override
  String get translatorLangUk => 'Ukraina';

  @override
  String get translatorLangEl => 'Yunani';

  @override
  String get translatorLangRo => 'Rumania';

  @override
  String get translatorLangHu => 'Hungaria';

  @override
  String get translatorLangBg => 'Bulgaria';

  @override
  String get translatorLangHr => 'Kroasia';

  @override
  String get translatorLangSr => 'Serbia';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Thailand';

  @override
  String get translatorLangVi => 'Vietnam';

  @override
  String get translatorLangId => 'Indonesia';

  @override
  String get translatorLangMs => 'Melayu';

  @override
  String get translatorLangHe => 'Ibrani';

  @override
  String get translatorLangFa => 'Persia';

  @override
  String get callInProgress => 'Panggilan sedang berlangsung';

  @override
  String get joinCall => 'Bergabung';

  @override
  String get createCallLink => 'Tautan panggilan';

  @override
  String get callLinkCopied => 'Tautan disalin';

  @override
  String get callLinkTitle => 'Tautan ruang';

  @override
  String get connectionUnstable =>
      'Koneksi tidak stabil — periksa internet Anda';

  @override
  String get today => 'Hari ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get errorTimeout =>
      'Koneksi habis waktu. Periksa koneksi internet Anda.';

  @override
  String get errorNoConnection => 'Tidak ada koneksi internet.';

  @override
  String get errorGeneral => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String errorWithMessage(String message) {
    return 'Kesalahan: $message';
  }

  @override
  String get notifChannelMessages => 'Pesan';

  @override
  String get notifChannelMessagesDesc => 'Notifikasi pesan baru';

  @override
  String get notifChannelMissedCalls => 'Panggilan tak terjawab';

  @override
  String get notifChannelMissedCallsDesc => 'Notifikasi panggilan tak terjawab';

  @override
  String get notifMissedCall => 'Panggilan tak terjawab';

  @override
  String get notifAccept => 'Terima';

  @override
  String get notifDecline => 'Tolak';

  @override
  String get notifIncomingCall => 'Panggilan masuk';

  @override
  String get notifIncomingCallChannel => 'Panggilan masuk';

  @override
  String get notifMissedCallChannel => 'Panggilan tak terjawab';

  @override
  String get notifUnknown => 'Tidak dikenal';

  @override
  String get effectNone => 'Tanpa latar belakang';

  @override
  String get effectBlur => 'Kabur';

  @override
  String get effectOffice => 'Kantor';

  @override
  String get effectNature => 'Alam';

  @override
  String get effectGradient => 'Gradasi';

  @override
  String get effectLibrary => 'Perpustakaan';

  @override
  String get effectCity => 'Kota';

  @override
  String get effectMinimalism => 'Minimalisme';

  @override
  String get voiceParticipant => 'Peserta';

  @override
  String get voiceInvitesToRoom => 'mengundang Anda ke ruang';

  @override
  String get voiceRoom => 'Ruang';

  @override
  String get voicePasswordProtected => 'Dilindungi kata sandi';

  @override
  String get voicePasswordHint => 'Kata sandi';

  @override
  String get voiceEnter => 'Masuk';

  @override
  String get voiceJoinRoom => 'Bergabung ke ruang';

  @override
  String get voiceYourName => 'Nama Anda';

  @override
  String voiceInvitationSent(String name) {
    return 'Undangan dikirim ke $name';
  }

  @override
  String get voiceNoActiveRoom => 'Tidak ada ruang aktif';

  @override
  String get voiceCameraPermission =>
      'Izinkan akses kamera di Pengaturan → Privasi → Kamera → TalerID';

  @override
  String get voiceOpenSettings => 'Buka';

  @override
  String voiceCameraError(String error) {
    return 'Gagal mengaktifkan kamera: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Semua setuju. Perekaman dimulai.';

  @override
  String get voiceNewParticipantAgreed => 'Peserta baru setuju untuk merekam.';

  @override
  String get voiceDeclinedRecording =>
      'Anda menolak perekaman. Keluar dari panggilan.';

  @override
  String get voiceRecordingEnded => 'Perekaman selesai';

  @override
  String get voiceRecordingInProgress => 'Perekaman sedang berlangsung';

  @override
  String get voiceTranscriptionRequest => 'Permintaan transkripsi';

  @override
  String get voiceRecordingRequest => 'Permintaan perekaman';

  @override
  String get voiceAgree => 'Setuju';

  @override
  String get voiceDeclineAndLeave => 'Tolak dan keluar';

  @override
  String get voiceAudioOutput => 'Output audio';

  @override
  String get voiceAudioPhone => 'Telepon';

  @override
  String get voiceAudioSpeaker => 'Speaker';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Headphone';

  @override
  String get voiceLinkCopied => 'Tautan disalin';

  @override
  String get voiceTranslateTo => 'Terjemahkan ke';

  @override
  String get voiceSearchLanguage => 'Cari bahasa...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Ruang $name';
  }

  @override
  String get voiceVoiceCall => 'Panggilan suara';

  @override
  String get voiceOnHold => 'Ditahan';

  @override
  String get voiceActiveCall => 'Aktif';

  @override
  String get voiceEndAllCalls => 'Akhiri semua panggilan';

  @override
  String get voiceEndThisCall => 'Akhiri panggilan ini';

  @override
  String get voiceCopyLink => 'Salin tautan';

  @override
  String get voiceAddParticipant => 'Tambah peserta';

  @override
  String get voiceReconnecting => 'Menyambungkan kembali...';

  @override
  String get voiceConnectionError => 'Kesalahan koneksi';

  @override
  String get voiceClose => 'Tutup';

  @override
  String get voiceCalling => 'Memanggil...';

  @override
  String get voiceCallActive => 'Panggilan aktif';

  @override
  String get voiceWaiting => 'Menunggu';

  @override
  String get voiceWaitingUpper => 'MENUNGGU';

  @override
  String get voiceRec => 'REC';

  @override
  String get voiceStop => 'Berhenti';

  @override
  String get voiceRecord => 'Merekam';

  @override
  String get voiceTranslation => 'Terjemahan';

  @override
  String get voiceAudio => 'Audio';

  @override
  String get voiceFlipCamera => 'Balik';

  @override
  String get voiceBackground => 'Latar belakang';

  @override
  String get voiceAssistantSpeakingStatus => 'Asisten sedang berbicara...';

  @override
  String get voiceAssistantListeningStatus => 'Asisten mendengarkan...';

  @override
  String get voiceUnmute => 'Buka suara';

  @override
  String get voiceMic => 'Mikrofon';

  @override
  String get voiceAssistantLabel => 'Asisten';

  @override
  String get voiceCameraOn => 'Kamera aktif';

  @override
  String get voiceCameraLabel => 'Kamera';

  @override
  String get voiceEndCall => 'Akhiri panggilan';

  @override
  String get voiceWaitingParticipants => 'Menunggu peserta...';

  @override
  String get voiceYou => 'Anda';

  @override
  String get voiceAiAssistant => 'Asisten AI';

  @override
  String get voiceVideoUnavailable => 'Video tidak tersedia';

  @override
  String get voiceSearchNickname => 'Cari berdasarkan nama panggilan...';

  @override
  String get voiceTranscriptionWord => 'transkripsi';

  @override
  String get voiceRecordingWord => 'rekaman';

  @override
  String get voiceConnecting => 'Menghubungkan...';

  @override
  String get voiceVideoBackground => 'Latar belakang video';

  @override
  String get voiceCallSettings => 'Pengaturan panggilan';

  @override
  String get voiceEnableAI => 'Aktifkan asisten AI';

  @override
  String get voiceAIParticipating => 'AI akan berpartisipasi dalam percakapan';

  @override
  String get voiceNormalCall => 'Panggilan normal tanpa AI';

  @override
  String get voiceCallConfirm => 'Lakukan panggilan?';

  @override
  String get chatAlreadyInCall => 'Sudah dalam panggilan';

  @override
  String chatCallError(String error) {
    return 'Kesalahan panggilan: $error';
  }

  @override
  String get chatPhotoVideo => 'Foto / Video';

  @override
  String get chatCamera => 'Kamera';

  @override
  String get chatFile => 'Berkas';

  @override
  String get chatContact => 'Kontak';

  @override
  String get chatSelectContact => 'Pilih kontak';

  @override
  String get chatNoContacts => 'Tidak ada kontak';

  @override
  String get chatUser => 'Pengguna';

  @override
  String get chatFileAttachment => '📎 Berkas';

  @override
  String chatFileUploadError(String error) {
    return 'Kesalahan unggah berkas: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Pesan suara';

  @override
  String get chatGroup => 'Grup';

  @override
  String get chatDialog => 'Dialog';

  @override
  String get chatCall => 'Panggilan';

  @override
  String get chatStartConversation => 'Mulai percakapan';

  @override
  String get chatYou => 'Anda';

  @override
  String get chatIsTyping => 'sedang mengetik...';

  @override
  String chatUserIsTyping(String name) {
    return '$name sedang mengetik...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names sedang mengetik...';
  }

  @override
  String get chatPreparingFile => 'Menyiapkan file…';

  @override
  String chatUploading(int progress) {
    return 'Mengunggah… $progress%';
  }

  @override
  String get chatEdited => 'Diedit';

  @override
  String get chatViaMesh => 'melalui mesh';

  @override
  String get chatReply => 'Balas';

  @override
  String get chatEdit => 'Edit';

  @override
  String get chatCopy => 'Salin';

  @override
  String get chatCopied => 'Disalin';

  @override
  String get chatSaveMedia => 'Simpan';

  @override
  String get chatForward => 'Teruskan';

  @override
  String get chatSaving => 'Menyimpan...';

  @override
  String get chatSavedToGallery => 'Disimpan ke galeri';

  @override
  String get chatNoSavePermission =>
      'Tidak ada izin untuk menyimpan. Periksa pengaturan.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Kesalahan menyimpan file';

  @override
  String get chatDeleteMessage => 'Hapus pesan';

  @override
  String get chatDeleteForMe => 'Hapus untuk saya';

  @override
  String get chatDeleteForEveryone => 'Hapus untuk semua orang';

  @override
  String get chatMessageForwarded => 'Pesan diteruskan';

  @override
  String get chatContactTapToOpen => 'Kontak · ketuk untuk membuka';

  @override
  String get chatForwardTo => 'Teruskan ke...';

  @override
  String get chatSearchHint => 'Cari...';

  @override
  String get chatRecording => 'Merekam...';

  @override
  String get chatMessageHint => 'Pesan...';

  @override
  String get chatHideKeyboard => 'Sembunyikan keyboard';

  @override
  String get chatEditing => 'Mengedit';

  @override
  String get chatFileDownloadError => 'Kesalahan mengunduh file';

  @override
  String get chatVoiceMessageShort => 'Pesan suara';

  @override
  String get chatVideoSavedToGallery => 'Video disimpan ke galeri';

  @override
  String get chatSavingError => 'Kesalahan menyimpan';

  @override
  String get convSetNickname => 'Tetapkan nama panggilan';

  @override
  String get convNicknameRequired =>
      'Nama panggilan diperlukan untuk menggunakan messenger. Pengguna lain dapat menemukan Anda dengan itu.';

  @override
  String get convNicknameRules => '3–30 karakter: huruf, angka, _';

  @override
  String get convNicknameTaken => 'Nama panggilan sudah digunakan';

  @override
  String get convSaveError => 'Kesalahan menyimpan';

  @override
  String get convContactsLabel => 'Kontak';

  @override
  String get convDefaultUser => 'Pengguna';

  @override
  String get convNoDialogs => 'Tidak ada percakapan';

  @override
  String get convFindUserToChat => 'Cari pengguna untuk mulai mengobrol';

  @override
  String get convDefaultContact => 'Kontak';

  @override
  String get dashboardUser => 'Pengguna';

  @override
  String get dashboardIncomingCall => 'Panggilan masuk';

  @override
  String get dashboardDecline => 'Tolak';

  @override
  String get dashboardAccept => 'Terima';

  @override
  String get dashboardActiveCall => 'Panggilan aktif — ketuk untuk kembali';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Pembaruan tersedia $version';
  }

  @override
  String get dashboardUpdate => 'Perbarui';

  @override
  String get dashboardWhatsNew => 'Apa yang baru';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Apa yang baru di $version';
  }

  @override
  String get dashboardInstalling => 'Menginstal...';

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
  String get contactRequestsTitle => 'Kontak';

  @override
  String get messengerContactRequestsSection => 'Permintaan kontak';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permintaan baru',
      one: '1 permintaan baru',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Cari';

  @override
  String get contactRequestsIncoming => 'Masuk';

  @override
  String get contactRequestsSent => 'Terkirim';

  @override
  String get contactRequestsSearchHint => 'Nama panggilan atau email';

  @override
  String get contactRequestSent => 'Permintaan terkirim';

  @override
  String get contactRequestsNoUsers => 'Tidak ada pengguna ditemukan';

  @override
  String get contactRequestsSearchHelp =>
      'Masukkan nama panggilan atau email\ntepat dan tekan cari';

  @override
  String get contactRequestsSendTooltip => 'Kirim permintaan';

  @override
  String get contactRequestTitle => 'Permintaan kontak';

  @override
  String contactRequestConfirm(String name) {
    return 'Kirim permintaan kontak ke $name?';
  }

  @override
  String get contactRequestSend => 'Kirim';

  @override
  String get contactRequestsNoIncoming => 'Tidak ada permintaan masuk';

  @override
  String get contactRequestsNoSent => 'Tidak ada permintaan terkirim';

  @override
  String get contactRequestStatusPending => 'Menunggu tanggapan';

  @override
  String get contactRequestStatusAccepted => 'Diterima';

  @override
  String get contactRequestStatusRejected => 'Ditolak';

  @override
  String get userSearchTitle => 'Cari pengguna';

  @override
  String get userSearchHint => 'Nama panggilan, telepon atau email';

  @override
  String get userSearchHelper =>
      'Masukkan @nama panggilan, email atau nama untuk mencari';

  @override
  String get userSearchNoUsers => 'Tidak ada pengguna ditemukan';

  @override
  String get userProfileShareContact => 'Bagikan kontak';

  @override
  String get userProfileShareContactDesc => 'Kirim tautan kontak';

  @override
  String get userProfileCopyLink => 'Salin tautan';

  @override
  String get userProfileCopied => 'Tersalin';

  @override
  String get userProfileTitle => 'Profil';

  @override
  String get userProfileLoadError => 'Kesalahan memuat profil';

  @override
  String get userProfileMessage => 'Pesan';

  @override
  String get userProfileCall => 'Panggil';

  @override
  String get userProfileRequestSent => 'Permintaan terkirim';

  @override
  String get userProfileAccept => 'Terima';

  @override
  String get userProfileDecline => 'Tolak';

  @override
  String get userProfileAddToContacts => 'Tambahkan ke kontak';

  @override
  String get userProfileMediaTab => 'Media';

  @override
  String get userProfileFilesTab => 'Berkas';

  @override
  String get userProfileLinksTab => 'Tautan';

  @override
  String get userProfileRecordingsTab => 'Rekaman';

  @override
  String get userProfileSummariesTab => 'Ringkasan';

  @override
  String get userProfileNoMedia => 'Tidak ada berkas media';

  @override
  String get userProfileNoFiles => 'Tidak ada berkas';

  @override
  String get userProfileNoLinks => 'Tidak ada tautan';

  @override
  String get userProfileNoRecordings => 'Tidak ada rekaman';

  @override
  String get userProfileNoSummaries => 'Tidak ada ringkasan';

  @override
  String get userProfileMeetingSummary => 'Ringkasan pertemuan';

  @override
  String get userProfileFailedOpenChat => 'Gagal membuka obrolan';

  @override
  String get sharedMediaTitle => 'Media dan berkas';

  @override
  String get sharedMediaTab => 'Media';

  @override
  String get sharedFilesTab => 'Berkas';

  @override
  String get sharedLinksTab => 'Tautan';

  @override
  String get sharedNoMedia => 'Tidak ada berkas media';

  @override
  String get sharedNoFiles => 'Tidak ada berkas';

  @override
  String get sharedNoLinks => 'Tidak ada tautan';

  @override
  String get shareToChat => 'Teruskan ke obrolan';

  @override
  String get shareSelectChat => 'Pilih obrolan';

  @override
  String get shareNoChats => 'Tidak ada obrolan';

  @override
  String shareFilesCount(int count) {
    return '$count berkas';
  }

  @override
  String get contactsTitle => 'Kontak';

  @override
  String get contactsAddTooltip => 'Tambahkan kontak';

  @override
  String get contactsSearchHint => 'Cari kontak...';

  @override
  String get contactsNotFound => 'Tidak ditemukan';

  @override
  String get contactsEmpty => 'Tidak ada kontak';

  @override
  String get contactsAdd => 'Tambahkan kontak';

  @override
  String get contactsPendingConfirmation => 'Menunggu konfirmasi';

  @override
  String get contactsMessage => 'Pesan';

  @override
  String get contactsCall => 'Panggil';

  @override
  String get contactsResend => 'Kirim ulang permintaan';

  @override
  String get contactsResendTimeout => 'Coba lagi dalam 24 jam';

  @override
  String get contactsResent => 'Permintaan dikirim ulang';

  @override
  String get contactsWantsToConnect => 'Ingin terhubung dengan Anda';

  @override
  String get contactsSearchPeople => 'Cari orang';

  @override
  String get notesTitle => 'Catatan';

  @override
  String get notesAssistantSpeaking => 'Asisten berbicara...';

  @override
  String get notesListening => 'Mendengarkan...';

  @override
  String get notesEmpty => 'Tidak ada catatan';

  @override
  String get notesEmptyHint =>
      'Tekan mic untuk dikte\natau + untuk entri manual';

  @override
  String get notesDeleteConfirm => 'Hapus catatan?';

  @override
  String get notesNew => 'Catatan baru';

  @override
  String get notesEdit => 'Edit';

  @override
  String get notesTitleHint => 'Judul';

  @override
  String get notesContentHint => 'Tulis pemikiran Anda...';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get calendarStop => 'Berhenti';

  @override
  String get calendarVoiceInput => 'Input suara';

  @override
  String get calendarNewEvent => 'Acara baru';

  @override
  String get calendarAssistantSpeaking => 'Asisten berbicara...';

  @override
  String get calendarListening => 'Mendengarkan...';

  @override
  String calendarInvitations(int count) {
    return 'Undangan ($count)';
  }

  @override
  String get calendarNoEvents => 'Tidak ada acara';

  @override
  String get calendarDayMon => 'Sen';

  @override
  String get calendarDayTue => 'Sel';

  @override
  String get calendarDayWed => 'Rab';

  @override
  String get calendarDayThu => 'Kam';

  @override
  String get calendarDayFri => 'Jum';

  @override
  String get calendarDaySat => 'Sab';

  @override
  String get calendarDaySun => 'Min';

  @override
  String get calendarEnterRoom => 'Masuk ruangan';

  @override
  String get calendarMeeting => 'Rapat';

  @override
  String calendarLocationPrefix(String location) {
    return 'Lokasi: $location';
  }

  @override
  String get calendarEditEvent => 'Edit';

  @override
  String get calendarTitleHint => 'Judul';

  @override
  String get calendarDescriptionHint => 'Deskripsi';

  @override
  String get calendarTypeEvent => 'Acara';

  @override
  String get calendarTypeMeeting => 'Rapat';

  @override
  String get calendarTypeReminder => 'Pengingat';

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
  String get calendarTypeLabel => 'Jenis';

  @override
  String get calendarMeetingLink => 'Tautan rapat';

  @override
  String get calendarLocationHint => 'Lokasi';

  @override
  String get calendarDateLabel => 'Tanggal';

  @override
  String get calendarTimeLabel => 'Waktu';

  @override
  String get calendarReminderLabel => 'Pengingat';

  @override
  String get calendarReminderNone => 'Tidak ada';

  @override
  String get calendarReminder15min => '15 menit sebelum';

  @override
  String get calendarReminder30min => '30 menit sebelum';

  @override
  String get calendarReminder1hour => '1 jam sebelum';

  @override
  String get calendarRepeatLabel => 'Ulangi';

  @override
  String get calendarRepeatNone => 'Tidak berulang';

  @override
  String get calendarRepeatDaily => 'Setiap hari';

  @override
  String get calendarRepeatWeekly => 'Setiap minggu';

  @override
  String get calendarRepeatMonthly => 'Setiap bulan';

  @override
  String get calendarRepeatYearly => 'Setiap tahun';

  @override
  String get calendarParticipants => 'Peserta';

  @override
  String get calendarAddParticipant => 'Tambah';

  @override
  String get calendarSearchContacts => 'Cari kontak...';

  @override
  String get calendarNoContacts => 'Tidak ada kontak';

  @override
  String get calendarStatusAccepted => 'Diterima';

  @override
  String get calendarStatusDeclined => 'Ditolak';

  @override
  String get calendarStatusMaybe => 'Mungkin';

  @override
  String get calendarStatusPending => 'Menunggu';

  @override
  String get calendarEndTime => 'Waktu selesai';

  @override
  String get calendarYourAnswer => 'Jawaban Anda:';

  @override
  String get calendarOrganizer => 'Penyelenggara';

  @override
  String calendarDeleteError(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String get calendarRsvpAccept => 'Terima';

  @override
  String get calendarRsvpMaybe => 'Mungkin';

  @override
  String get calendarRsvpDecline => 'Tolak';

  @override
  String get callHistoryTitle => 'Panggilan';

  @override
  String get callHistoryTab => 'Riwayat panggilan';

  @override
  String get callHistoryTempMeeting => 'Pertemuan sementara';

  @override
  String get callHistoryCopy => 'Salin';

  @override
  String get callHistoryLinkCopied => 'Tautan disalin';

  @override
  String get callHistoryShare => 'Bagikan';

  @override
  String get callHistoryEnter => 'Masuk';

  @override
  String get callHistoryAlreadyInCall => 'Sudah dalam panggilan';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Tidak dapat menentukan pihak lain';

  @override
  String get callHistoryContacts => 'Kontak';

  @override
  String get callHistoryFailedLoadRoom => 'Gagal memuat ruangan Anda';

  @override
  String get callHistoryYourRoom => 'Ruang Anda';

  @override
  String get callHistoryCreateMeeting => 'Buat pertemuan';

  @override
  String get callHistoryMeetingSummaries => 'Ringkasan pertemuan';

  @override
  String get callHistoryMeetingRecordings => 'Rekaman pertemuan';

  @override
  String get callHistoryNoCalls => 'Tidak ada panggilan';

  @override
  String get callHistoryMissed => 'Terlewat';

  @override
  String get callHistoryRecording => 'Merekam';

  @override
  String get callHistorySummary => 'Ringkasan';

  @override
  String get callHistoryCallAgain => 'Panggil lagi';

  @override
  String callHistoryTodayTime(String time) {
    return 'Hari ini, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Kemarin, $time';
  }

  @override
  String get callHistoryUnknown => 'Tidak diketahui';

  @override
  String get callHistoryDetails => 'Detail panggilan';

  @override
  String get callHistoryOutgoing => 'Panggilan keluar';

  @override
  String get callHistoryIncoming => 'Panggilan masuk';

  @override
  String callHistoryDuration(String duration) {
    return 'Durasi: $duration';
  }

  @override
  String get callHistoryWithAI => 'Dengan asisten AI';

  @override
  String get callHistoryParticipants => 'Peserta';

  @override
  String get callDetailYouSuffix => '(Anda)';

  @override
  String get callHistoryMeetingSummary => 'Ringkasan pertemuan';

  @override
  String get callHistoryMoreDetails => 'Detail lebih lanjut';

  @override
  String get callHistorySummaryProcessing => 'Memproses ringkasan...';

  @override
  String get callHistoryMeetingRecording => 'Rekaman pertemuan';

  @override
  String get callHistoryProcessing => 'Memproses...';

  @override
  String get callHistoryCreateTranscript => 'Buat transkrip';

  @override
  String get callHistoryNoSummaries => 'Tidak ada ringkasan';

  @override
  String get callHistoryRecordDuringCall => 'Tekan \"Rekam\" selama panggilan';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Pertemuan $time';
  }

  @override
  String get callHistoryTranscribing => 'Mentranskrip dan merangkum...';

  @override
  String get callHistoryTranscriptCreated => 'Transkrip dibuat';

  @override
  String get callHistoryNoRecordings => 'Tidak ada rekaman';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Rekaman $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Rekaman tidak tersedia';

  @override
  String get callHistoryTranscriptReady => 'Transkrip siap';

  @override
  String get callHistoryTranscript => 'Transkrip';

  @override
  String get callHistoryKeyPoints => 'Poin penting';

  @override
  String get callHistoryTasks => 'Tugas';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Ditugaskan kepada: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Keputusan';

  @override
  String get callHistoryShowTranscript => 'Tampilkan transkrip lengkap';

  @override
  String get profileScanQr => 'Pindai QR';

  @override
  String get profileMyQrCode => 'Kode QR saya';

  @override
  String profileAddMeShare(String userId) {
    return 'Tambahkan saya di Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Tunjukkan kode ini untuk menambahkan Anda';

  @override
  String get profileEditDesc =>
      'Nama, nama belakang, patronimik, tanggal lahir';

  @override
  String get profileAboutMe => 'Tentang saya';

  @override
  String get profileAboutMeDesc => 'Nilai, keterampilan, minat, dan lainnya';

  @override
  String get profileNotes => 'Catatan';

  @override
  String get profileNotesDesc => 'Pikiran, ide, dan catatan';

  @override
  String get profileAvatarUpdated => 'Avatar diperbarui';

  @override
  String get profileNickname => 'Nama panggilan';

  @override
  String get profileNotSet => 'Belum diatur';

  @override
  String get profileChangeNickname => 'Ubah nama panggilan';

  @override
  String get profileNicknameUpdated => 'Nama panggilan diperbarui';

  @override
  String get profileShareLabel => 'Bagikan';

  @override
  String get profileScanQrCode => 'Pindai kode QR';

  @override
  String get profilePointCamera => 'Arahkan kamera ke kode QR';

  @override
  String get profilePhotoCamera => 'Ambil foto';

  @override
  String get profilePhotoGallery => 'Pilih dari galeri';

  @override
  String get editProfilePatronymic => 'Patronimik (opsional)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'Tentang saya';

  @override
  String get aboutMeClickToFill => 'Klik untuk mengisi';

  @override
  String get aboutMeCoreValues => 'Nilai';

  @override
  String get aboutMeWorldview => 'Pandangan dunia';

  @override
  String get aboutMeSkills => 'Keterampilan';

  @override
  String get aboutMeInterests => 'Minat';

  @override
  String get aboutMeDesires => 'Keinginan';

  @override
  String get aboutMeBackground => 'Profil';

  @override
  String get aboutMeLikes => 'Suka';

  @override
  String get aboutMeDislikes => 'Tidak suka';

  @override
  String get aboutMeDeleteSection => 'Hapus bagian?';

  @override
  String get aboutMeDeleteConfirm => 'Semua data di bagian ini akan dihapus.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Kesalahan koneksi: $error';
  }

  @override
  String get aboutMeVisibility => 'Visibilitas';

  @override
  String get aboutMeTags => 'Tag';

  @override
  String get aboutMeAddTag => 'Tambahkan tag...';

  @override
  String get aboutMeDescription => 'Deskripsi';

  @override
  String get aboutMeDescribeLong => 'Ceritakan lebih banyak...';

  @override
  String get aboutMeVisibilityEveryone => 'Semua orang';

  @override
  String get aboutMeVisibilityContacts => 'Kontak';

  @override
  String get aboutMeVisibilityOnlyMe => 'Hanya saya';

  @override
  String get settingsProfileSubtitle => 'Profil';

  @override
  String get settingsWallpaper => 'Wallpaper';

  @override
  String get settingsWallpaperDesc => 'Gambar latar untuk seluruh aplikasi';

  @override
  String get settingsWallpaperNone => 'Tidak ada';

  @override
  String get settingsAccount => 'Akun';

  @override
  String get settingsKycVerification => 'Verifikasi Identitas (KYC)';

  @override
  String get settingsOrganizations => 'Organisasi';

  @override
  String get incomingCallLabel => 'Panggilan masuk';

  @override
  String get incomingCallDecline => 'Tolak';

  @override
  String get incomingCallAccept => 'Terima';

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
  String get meshIncomingCallLabel => '📡 Panggilan mesh masuk';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Perangkat mesh $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall =>
      'Selesaikan panggilan saat ini terlebih dahulu';

  @override
  String get callPopupTransportTitle => 'Panggil melalui';

  @override
  String get callPopupTransportMesh => '📡 Mesh (peer-to-peer)';

  @override
  String get callPopupTransportLk => '📞 Server';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Kontak tidak dapat dijangkau melalui mesh';

  @override
  String get meshOnboardingTitle =>
      '📡 Panggilan mesh memerlukan aplikasi terbuka';

  @override
  String get meshOnboardingBody =>
      'Ketika ponsel terkunci, panggilan mesh dapat terputus setelah ~30 detik (batasan iOS).';

  @override
  String get meshOnboardingAck => 'Mengerti';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Kontak tidak ada dalam daftar Anda';

  @override
  String get meshCallStatusInviting => 'Memanggil…';

  @override
  String get meshCallStatusConnecting => 'Menghubungkan…';

  @override
  String get meshCallEndedUserHangup => 'Panggilan berakhir';

  @override
  String get meshCallEndedRemoteHangup => 'Dihentikan oleh rekan';

  @override
  String get meshCallEndedRejected => 'Ditolak';

  @override
  String get meshCallEndedNoAnswer => 'Tidak ada jawaban';

  @override
  String get meshCallEndedConnectionLost => 'Koneksi terputus';

  @override
  String get meshCallEndedError => 'Kesalahan koneksi';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Panggilan mesh yang andal';

  @override
  String get batteryExemptionBody =>
      'Izinkan aplikasi berjalan tanpa batasan baterai agar Android tidak mematikan mesh di latar belakang.';

  @override
  String get batteryExemptionAccept => 'Buka pengaturan';

  @override
  String get batteryExemptionDismiss => 'Tidak sekarang';

  @override
  String get groupCamera => 'Kamera';

  @override
  String get groupGallery => 'Galeri';

  @override
  String get groupAvatarUpdated => 'Avatar grup diperbarui';

  @override
  String get groupNameTitle => 'Nama grup';

  @override
  String get groupEnterName => 'Masukkan nama';

  @override
  String get groupDescriptionTitle => 'Deskripsi grup';

  @override
  String get groupEnterDescription => 'Masukkan deskripsi grup';

  @override
  String get groupChangeRoleTitle => 'Ubah peran';

  @override
  String get groupRemoveMemberTitle => 'Hapus anggota';

  @override
  String get groupDescription => 'Deskripsi';

  @override
  String get groupAddDescription => 'Tambahkan deskripsi grup';

  @override
  String get groupNoDescription => 'Tidak ada deskripsi';

  @override
  String get groupMediaAndFiles => 'Media dan file';

  @override
  String get groupMuteNotifications => 'Bisukan notifikasi';

  @override
  String get groupMuted => 'Dibisukan';

  @override
  String get groupNoResults => 'Tidak ada hasil';

  @override
  String get authInvalidCode => 'Kode tidak valid. Coba lagi.';

  @override
  String get loginSubtitle => 'Gunakan email dan kata sandi';

  @override
  String get emailRequired => 'Masukkan email';

  @override
  String get emailInvalid => 'Email tidak valid';

  @override
  String get passwordRequired => 'Masukkan kata sandi';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Satu akun untuk seluruh ekosistem Taler';

  @override
  String get usernameOptional => 'Nama pengguna (opsional)';

  @override
  String get usernameMinLength => 'Minimal 3 karakter';

  @override
  String get usernameMaxLength => 'Maksimal 30 karakter';

  @override
  String get usernameInvalid => 'Hanya huruf, angka, dan _';

  @override
  String get biometricLoginReason => 'Masuk ke Taler ID';

  @override
  String get docTypePassport => 'Paspor';

  @override
  String get docTypeIdCard => 'KTP';

  @override
  String get docTypeDriverLicense => 'SIM';

  @override
  String get docTypeResidencePermit => 'Izin Tinggal';

  @override
  String addressApartment(String number) {
    return 'apt. $number';
  }

  @override
  String get failedToUpdateProfile => 'Gagal memperbarui profil';

  @override
  String get failedToStartKyb => 'Gagal memulai verifikasi KYB';

  @override
  String get orgUpdated => 'Organisasi diperbarui';

  @override
  String get failedToUpdateOrg => 'Gagal memperbarui organisasi';

  @override
  String get failedToChangeRole => 'Gagal mengubah peran';

  @override
  String get failedToRemoveMember => 'Gagal menghapus anggota';

  @override
  String get capabilityMessagesTitle => 'Pesan';

  @override
  String get capabilityMessagesDesc =>
      'Periksa pesan atau tulis kepada seseorang. Misalnya: \"Tulis kepada Viktor: akan tiba dalam satu jam\"';

  @override
  String get capabilityCallsTitle => 'Panggilan';

  @override
  String get capabilityCallsDesc =>
      'Panggil kontak mana pun dengan suara. Misalnya: \"Panggil Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Riwayat Chat';

  @override
  String get capabilityChatDesc =>
      'Saya akan menganalisis riwayat chat. Contohnya: \"Apa yang kita diskusikan dengan Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Profil';

  @override
  String get capabilityProfileDesc =>
      'Saya akan menampilkan atau memperbarui profil Anda. Contohnya: \"Tampilkan profil saya\"';

  @override
  String get capabilityCoachingTitle => 'Pelatihan';

  @override
  String get capabilityCoachingDesc =>
      'Mode: pelatihan ICF, psikolog, konsultasi HR. Katakan: \"Mari lakukan pelatihan\"';

  @override
  String get capabilityCalendarTitle => 'Kalender';

  @override
  String get capabilityCalendarDesc =>
      'Jadwalkan pertemuan atau atur pengingat. Contohnya: \"Jadwalkan pertemuan dengan Viktor untuk besok pukul 15:00\"';

  @override
  String get capabilityNotesTitle => 'Catatan';

  @override
  String get capabilityNotesDesc =>
      'Simpan pemikiran atau baca catatan terbaru. Contohnya: \"Tulis ide...\" atau \"Baca catatan terbaru\"';

  @override
  String get assistantCallConfirm => 'Lakukan panggilan?';

  @override
  String get callNoAnswer => 'Tidak ada jawaban';

  @override
  String get contactDelete => 'Hapus kontak';

  @override
  String get contactDeleteTitle => 'Hapus kontak';

  @override
  String get contactDeleteConfirm =>
      'Apakah Anda yakin? Kontak ini akan dihapus.';

  @override
  String get contactBlock => 'Blokir';

  @override
  String get contactBlockTitle => 'Blokir pengguna';

  @override
  String get contactBlockConfirm =>
      'Pengguna ini tidak akan dapat mengirim pesan atau menelepon Anda.';

  @override
  String get contactUnblock => 'Buka blokir';

  @override
  String get contactBlocked => 'Diblokir';

  @override
  String get contactYouAreBlocked => 'Pengguna ini telah memblokir Anda';

  @override
  String get chatBlockedByYou => 'Anda telah memblokir pengguna ini';

  @override
  String get chatYouAreBlocked => 'Anda telah diblokir oleh pengguna ini';

  @override
  String get chatNotContacts =>
      'Tambahkan pengguna ini ke kontak untuk mengirim pesan';

  @override
  String get contactRevokeRequest => 'Batalkan permintaan';

  @override
  String get messengerPoll => 'Jajak pendapat';

  @override
  String get messengerCreatePoll => 'Buat Jajak Pendapat';

  @override
  String get messengerPollQuestion => 'Pertanyaan';

  @override
  String messengerPollOption(int number) {
    return 'Opsi $number';
  }

  @override
  String get messengerPollAddOption => 'Tambah opsi';

  @override
  String get messengerPollAnonymous => 'Pemungutan suara anonim';

  @override
  String get messengerPollMultiple => 'Pilihan ganda';

  @override
  String get messengerPollCreateError => 'Gagal membuat jajak pendapat';

  @override
  String get messengerPollUnavailable => 'Jajak pendapat tidak tersedia';

  @override
  String get messengerPollMultipleNote => 'Anda dapat memilih lebih dari satu';

  @override
  String messengerPollVotes(int count) {
    return '$count suara';
  }

  @override
  String get messengerVideoMessage => 'Pesan video';

  @override
  String get messengerVideoRecordError => 'Kesalahan perekaman video';

  @override
  String get messengerVideoPlaybackError => 'Tidak dapat memutar video';

  @override
  String get messengerGalleryAccessError => 'Tidak ada akses ke galeri';

  @override
  String get messengerSearchInChat => 'Cari di obrolan...';

  @override
  String get messengerSaveToFavorites => 'Simpan ke favorit';

  @override
  String get messengerSavedToFavorites => 'Disimpan ke favorit';

  @override
  String get messengerSearchInMessages => 'Cari di pesan...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Ditemukan di pesan ($count)';
  }

  @override
  String get messengerGroupDefault => 'Grup';

  @override
  String get messengerUserDefault => 'Pengguna';

  @override
  String get messengerPin => 'Sematkan';

  @override
  String get messengerUnpin => 'Lepaskan sematan';

  @override
  String get messengerArchive => 'Arsipkan';

  @override
  String get messengerUnarchive => 'Batalkan arsip';

  @override
  String get messengerDeleteChat => 'Hapus obrolan';

  @override
  String get messengerDeleteChatTitle => 'Hapus obrolan?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Hapus obrolan dengan $name? Ini tidak dapat dibatalkan.';
  }

  @override
  String get messengerCreateChannel => 'Buat Saluran';

  @override
  String get messengerChannelName => 'Nama';

  @override
  String get messengerChannelDescription => 'Deskripsi (opsional)';

  @override
  String get messengerChannelCreateError => 'Gagal membuat saluran';

  @override
  String get messengerFilterAll => 'Semua';

  @override
  String get messengerFilterUnread => 'Belum dibaca';

  @override
  String get messengerFilterPersonal => 'Pribadi';

  @override
  String get messengerFilterGroups => 'Grup';

  @override
  String get messengerFilterChannels => 'Saluran';

  @override
  String get messengerArchivedSection => 'Diarsipkan';

  @override
  String get messengerSavedSection => 'Favorit';

  @override
  String get messengerSavedSubtitle => 'Simpan ke memori';

  @override
  String messengerArchiveTitle(int count) {
    return 'Arsip ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Arsip kosong';

  @override
  String messengerYouPrefix(String message) {
    return 'Anda: $message';
  }

  @override
  String get messengerMissedCall => 'Panggilan tak terjawab';

  @override
  String get messengerSavedTitle => 'Favorit';

  @override
  String get messengerNoSavedMessages => 'Tidak ada pesan yang disimpan';

  @override
  String get messengerSavedHint => 'Tekan lama pesan → \"Simpan ke favorit\"';

  @override
  String get messengerDefaultFile => 'Berkas';

  @override
  String get messengerTopicDefault => 'Umum';

  @override
  String get messengerTopicNew => 'Topik Baru';

  @override
  String get messengerTopicNameHint => 'Nama topik';

  @override
  String get messengerTopicIcon => 'Ikon';

  @override
  String messengerTopicCount(int count) {
    return '$count topik';
  }

  @override
  String get messengerNoTopics => 'Tidak ada topik';

  @override
  String get messengerNoMessages => 'Tidak ada pesan';

  @override
  String get you => 'Anda';

  @override
  String get messengerThread => 'Utasan';

  @override
  String get messengerThreadReply => 'balas';

  @override
  String get messengerThreadReplies => 'balasan';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Tidak ada balasan';

  @override
  String get messengerReplyHint => 'Balas utasan...';

  @override
  String get messengerContactName => 'Nama kontak';

  @override
  String messengerOriginalName(String name) {
    return 'Nama asli: $name';
  }

  @override
  String get messengerDisplayName => 'Nama tampilan';

  @override
  String messengerShareContact(String name) {
    return 'Kontak di Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Hapus pesan otomatis';

  @override
  String get messengerAutoDeleteOff => 'Mati';

  @override
  String get messengerAutoDelete7d => '7 hari';

  @override
  String get messengerAutoDelete30d => '30 hari';

  @override
  String get messengerAutoDelete90d => '90 hari';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count hari';
  }

  @override
  String get messengerSettingsHeader => 'Pengaturan';

  @override
  String get messengerAdminOnly => 'Hanya admin yang dapat memposting';

  @override
  String get messengerAdminOnlyDesc => 'Anggota hanya dapat membaca';

  @override
  String get messengerTopics => 'Topik';

  @override
  String get messengerTopicsDesc => 'Pisahkan obrolan ke dalam topik';

  @override
  String get aiTwinSection => 'AI Voice Twin';

  @override
  String get aiTwinEnabled => 'Aktifkan AI Twin';

  @override
  String get aiTwinEnabledDesc =>
      'Jika Anda tidak menjawab, AI twin Anda akan menerima panggilan dengan suara Anda';

  @override
  String get aiTwinTimeout => 'Batas waktu respons';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds detik';
  }

  @override
  String get aiTwinPrompt => 'Instruksi AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Bagaimana AI twin harus memperkenalkan diri dan apa yang harus dibicarakan';

  @override
  String aiTwinPromptHint(String name) {
    return 'Hai, ini adalah AI voice twin $name. $name tidak dapat menjawab saat ini. Beritahu saya siapa yang menelepon dan tentang apa — saya akan menyampaikannya.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Peniruan suara khusus segera hadir. Untuk saat ini AI berbicara dengan suara $name.';
  }

  @override
  String get aiTwinDefaultName => 'pemilik';

  @override
  String get aiTwinPromptReset => 'Atur ulang';

  @override
  String get callHistoryAiTwinAnswered => 'AI TWIN MENJAWAB';

  @override
  String get callHistoryAiTwinSummary => 'RINGKASAN PANGGILAN';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSKRIP';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'Dari $name';
  }

  @override
  String get aiTwinOfferTitle => 'Tidak menjawab';

  @override
  String aiTwinOfferBody(String name) {
    return '$name tidak menjawab. Tinggalkan pesan dengan kembaran suara AI mereka?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Pengguna';

  @override
  String get aiTwinOfferAccept => 'Ya, tinggalkan pesan';

  @override
  String get aiTwinOfferKeepWaiting => 'Tetap menunggu';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Pengganti AI Anda';

  @override
  String get aiTwinHeroSubtitle =>
      'Menjawab panggilan dengan suara Anda saat Anda tidak bisa.';

  @override
  String get aiTwinProfileTitle => 'Pengganti AI';

  @override
  String get aiTwinProfileDesc => 'Menjawab panggilan dengan suara Anda';

  @override
  String get aiTwinBadgeOn => 'AKTIF';

  @override
  String get aiAnalystTitle => 'Analis AI';

  @override
  String get aiAnalystSubtitle => 'Berkas, tugas, analisis — Claude';

  @override
  String get channelsDiscover => 'Temukan saluran';

  @override
  String get channelsSearchHint => 'Cari saluran';

  @override
  String get channelsSubscribers => 'pelanggan';

  @override
  String get channelsSubscribe => 'Berlangganan';

  @override
  String get channelsUnsubscribe => 'Berhenti berlangganan';

  @override
  String get channelsSubscribedLabel => 'Anda berlangganan';

  @override
  String get channelsSettings => 'Pengaturan saluran';

  @override
  String get channelsDelete => 'Hapus saluran';

  @override
  String get channelsDeleteConfirm => 'Hapus saluran secara permanen?';

  @override
  String get channelsEmpty => 'Belum ada saluran';

  @override
  String get channelsOpen => 'Buka';

  @override
  String get channelsNameLabel => 'Nama';

  @override
  String get channelsDescriptionLabel => 'Deskripsi';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Pemilik tidak dapat berhenti berlangganan. Hapus saluran sebagai gantinya.';

  @override
  String get channelsNotFoundRedirect => 'Saluran tidak lagi ada';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pencarian',
      one: '$count pencarian',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count berkas',
      one: '$count berkas',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perintah',
      one: '$count perintah',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gambar',
      one: '$count gambar',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langkah',
      one: '$count langkah',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}d';
  }

  @override
  String get savedTitle => 'Pesan Tersimpan';

  @override
  String get savedSubtitle => 'Awan pribadi Anda';

  @override
  String get savedOpenError => 'Tidak dapat membuka Pesan Tersimpan';

  @override
  String get billingWalletTitle => 'Dompet';

  @override
  String get billingBuyPackage => 'Beli paket';

  @override
  String get billingCurrentBalance => 'Saldo saat ini';

  @override
  String get billingPackagesTitle => 'Paket';

  @override
  String get billingPackagesUnavailable => 'Paket tidak tersedia';

  @override
  String get billingRecentOperations => 'Operasi terbaru';

  @override
  String get billingAllOperations => 'Semua operasi';

  @override
  String get billingNoOperations => 'Tidak ada operasi';

  @override
  String get billingOperationsTitle => 'Operasi';

  @override
  String get billingOperationsEmptyTitle => 'Belum ada operasi';

  @override
  String get billingOperationsEmptySubtitle =>
      'Isi ulang dan biaya fitur AI akan muncul di sini';

  @override
  String get billingPricebookTitle => 'Harga fitur';

  @override
  String get billingPricebookUnavailable => 'Daftar harga tidak tersedia';

  @override
  String get billingAiFeaturesTitle => 'Fitur AI';

  @override
  String get billingInsufficientFundsTitle => 'Dana tidak mencukupi';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Isi saldo Anda untuk menggunakan fitur ini.';

  @override
  String billingRequiredLine(String required) {
    return 'Dibutuhkan: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Tersedia: $available μTAL';
  }

  @override
  String get billingTopUp => 'Isi ulang';

  @override
  String get billingCancel => 'Batal';

  @override
  String get billingRetry => 'Coba lagi';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Saldo hampir habis: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Dompet & Saldo';

  @override
  String get billingSectionHeader => 'Penagihan & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Asisten suara';

  @override
  String get billingFeatureWebSearch => 'Pencarian web asisten';

  @override
  String get billingFeatureAiTwin => 'Kembaran suara';

  @override
  String get billingFeatureAiTwinLong => 'Kembaran suara (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot panggilan keluar';

  @override
  String get billingFeatureOutboundCallLong => 'Bot panggilan keluar';

  @override
  String get billingFeatureWhisperTranscribe => 'Transkripsi panggilan';

  @override
  String get billingFeatureMeetingSummary => 'Ringkasan panggilan AI';

  @override
  String get billingConfigureAiTwin => 'Konfigurasi kembaran AI';

  @override
  String get billingWebSearchSubtitle => '(digunakan oleh asisten)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Paket dibeli: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Direkomendasikan';

  @override
  String get billingSessionTerminatedNoFunds => 'Saldo habis — sesi berakhir';

  @override
  String get billingSessionTerminatedGeneric => 'Sesi asisten berakhir';

  @override
  String billingBuyForPrice(String price) {
    return 'Beli seharga €$price';
  }

  @override
  String get billingTxTypeTopup => 'Isi ulang';

  @override
  String get billingTxTypeRefund => 'Pengembalian dana';

  @override
  String get billingTxTypeSpend => 'Biaya';

  @override
  String get billingUnitMinute => 'menit';

  @override
  String get billingUnitRequest => 'permintaan';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K token';

  @override
  String get billingUnitCall => 'panggilan';

  @override
  String get groupCallSelectParticipants => 'Pilih peserta';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Cari';

  @override
  String get groupCallMaxReached => 'Maksimal 7 peserta';

  @override
  String get groupCallLobbyTitle => 'Grup • Lobi';

  @override
  String groupCallHostLabel(String name) {
    return 'Host: $name';
  }

  @override
  String get groupCallMicHint => 'Mic akan aktif saat terhubung';

  @override
  String get groupCallCancel => 'Batal';

  @override
  String get groupCallNoAnswer => 'Tidak ada yang menjawab';

  @override
  String get groupCallEndedByHost => 'Panggilan diakhiri oleh host';

  @override
  String get groupCallAllLeft => 'Semua meninggalkan panggilan';

  @override
  String get groupCallEnded => 'Panggilan diakhiri';

  @override
  String groupCallActiveTitle(int count) {
    return 'Grup • $count';
  }

  @override
  String get groupCallConnectionLost => 'Koneksi terputus';

  @override
  String get groupCallMuteRequested => 'Host meminta semua untuk membisukan';

  @override
  String get groupCallUnmute => 'Buka suara';

  @override
  String get groupCallMute => 'Bisukan';

  @override
  String get groupCallMuteAll => 'Bisukan semua';

  @override
  String get groupCallLeave => 'Tinggalkan';

  @override
  String get groupCallStatusCalling => 'memanggil…';

  @override
  String get groupCallStatusDeclined => 'ditolak';

  @override
  String get groupCallStatusTimeout => 'tidak ada jawaban';

  @override
  String get groupCallStatusLeft => 'meninggalkan';

  @override
  String groupCallKickConfirm(String name) {
    return 'Hapus $name dari panggilan';
  }

  @override
  String get groupCallCancelAction => 'Batal';

  @override
  String get groupCallActiveBanner => 'Panggilan aktif';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Grup: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Grup: $host';
  }

  @override
  String get groupCallCreateError => 'Tidak dapat membuat panggilan';

  @override
  String get groupCallJoinError => 'Tidak dapat bergabung dengan panggilan';

  @override
  String get groupCallLivekitError => 'Kesalahan LiveKit';

  @override
  String get groupCallDone => 'Selesai';

  @override
  String get groupCallNoResults => 'Tidak ada hasil';

  @override
  String get groupCallNoContacts => 'Tidak ada kontak';

  @override
  String get meshGcContactOffline => 'Tidak di Wi-Fi ini';

  @override
  String get meshGcOnlineViaMesh => 'Online melalui mesh';

  @override
  String get meshGcMaxInvitees =>
      'Panggilan grup mendukung hingga 4 undangan (total 5 orang).';

  @override
  String get meshGcStart => 'Mulai panggilan grup';

  @override
  String get meshGcCancel => 'Batalkan';

  @override
  String get meshGcStatusCalling => 'Memanggil…';

  @override
  String get meshGcStatusJoined => 'Bergabung';

  @override
  String get meshGcStatusDeclined => 'Ditolak';

  @override
  String get meshGcStatusNoAnswer => 'Tidak ada jawaban';

  @override
  String get meshGcStatusConnectionFailed => 'Koneksi gagal';

  @override
  String get meshGcStatusLeft => 'Keluar';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne =>
      'Selesaikan panggilan Anda saat ini terlebih dahulu.';

  @override
  String get presenceOnline => 'online';

  @override
  String get presenceLastSeenJustNow => 'terakhir terlihat baru saja';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'terakhir terlihat $minutes menit yang lalu';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'terakhir terlihat hari ini pukul $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'terakhir terlihat kemarin pukul $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'terakhir terlihat $date';
  }

  @override
  String get presenceLastSeenRecently => 'terakhir terlihat baru-baru ini';

  @override
  String get privacySectionTitle => 'Privasi';

  @override
  String get privacyLastSeenLabel =>
      'Siapa yang dapat melihat waktu terakhir Anda terlihat';

  @override
  String get privacyEveryone => 'Semua orang';

  @override
  String get privacyContacts => 'Hanya kontak';

  @override
  String get privacyNobody => 'Tidak ada';

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

  @override
  String get chatSelect => 'Select';

  @override
  String get convDraftLabel => 'Draft';

  @override
  String get chatMentionNotFound => 'User not found';
}
