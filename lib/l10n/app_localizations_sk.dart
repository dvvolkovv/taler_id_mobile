// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Hľadať';

  @override
  String get appSubtitle => 'Identita jednotného ekosystému';

  @override
  String get login => 'Prihlásiť sa';

  @override
  String get loginButton => 'Prihlásiť sa';

  @override
  String get register => 'Vytvoriť účet';

  @override
  String get registerButton => 'Vytvoriť účet';

  @override
  String get email => 'Email';

  @override
  String get password => 'Heslo';

  @override
  String get confirmPassword => 'Potvrdiť heslo';

  @override
  String get firstName => 'Meno';

  @override
  String get lastName => 'Priezvisko';

  @override
  String get noAccount => 'Nemáte účet?';

  @override
  String get createOne => 'Vytvorte si ho';

  @override
  String get haveAccount => 'Už máte účet?';

  @override
  String get signIn => 'Prihlásiť sa';

  @override
  String get passwordMinLength => 'Minimálne 8 znakov';

  @override
  String get invalidEmail => 'Zadajte platný email';

  @override
  String get fieldRequired => 'Povinné pole';

  @override
  String get twoFATitle => 'Dvojfaktorová autentifikácia';

  @override
  String get twoFASubtitle =>
      'Zadajte 6-miestny kód z vašej autentifikačnej aplikácie';

  @override
  String get twoFACode => '2FA kód';

  @override
  String get verify => 'Overiť';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organizácia';

  @override
  String get tabSettings => 'Nastavenia';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Upraviť profil';

  @override
  String get phone => 'Telefón';

  @override
  String get country => 'Krajina';

  @override
  String get dateOfBirth => 'Dátum narodenia';

  @override
  String get documents => 'Dokumenty';

  @override
  String get addDocument => 'Pridať dokument';

  @override
  String get noDocuments => 'Žiadne dokumenty nahrané';

  @override
  String get save => 'Uložiť';

  @override
  String get profileUpdated => 'Profil aktualizovaný';

  @override
  String get personalData => 'Osobné údaje';

  @override
  String get passport => 'Pas';

  @override
  String get drivingLicense => 'Vodičský preukaz';

  @override
  String get diploma => 'Diplom';

  @override
  String get nationalId => 'Národný preukaz';

  @override
  String get certificate => 'Certifikát';

  @override
  String get notSpecified => 'Nešpecifikované';

  @override
  String get notSpecifiedFemale => 'Nešpecifikované';

  @override
  String get documentType => 'Typ dokumentu';

  @override
  String get passportId => 'Pas / ID';

  @override
  String get diplomaCertificate => 'Diplom / Certifikát';

  @override
  String get loadError => 'Chyba načítania';

  @override
  String get verification => 'Overenie';

  @override
  String get countryAustria => 'Rakúsko';

  @override
  String get countryGermany => 'Nemecko';

  @override
  String get countryRussia => 'Rusko';

  @override
  String get countryUkraine => 'Ukrajina';

  @override
  String get countryKazakhstan => 'Kazachstan';

  @override
  String get countryBelarus => 'Bielorusko';

  @override
  String get countryOther => 'Iné';

  @override
  String get kycTitle => 'Overenie KYC';

  @override
  String get kycVerified => 'Overené';

  @override
  String get kycPending => 'Čaká sa';

  @override
  String get kycRejected => 'Zamietnuté';

  @override
  String get kycUnverified => 'Neoverené';

  @override
  String get kycVerifiedDesc =>
      'Vaša identita bola overená. Máte plný prístup ku všetkým funkciám ekosystému Taler.';

  @override
  String get kycPendingDesc =>
      'Vaše dokumenty sa posudzujú. Zvyčajne to trvá 1-2 pracovné dni.';

  @override
  String get kycRejectedDesc =>
      'Overenie zlyhalo. Skontrolujte dôvod a znovu odošlite svoje dokumenty.';

  @override
  String get kycUnverifiedDesc =>
      'Dokončite overenie, aby ste odomkli plný prístup k finančným funkciám ekosystému Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Začať overenie';

  @override
  String get retryVerification => 'Znova overiť';

  @override
  String verifiedAt(String date) {
    return 'Overené: $date';
  }

  @override
  String get documentsSubmitted => 'Dokumenty odoslané na kontrolu';

  @override
  String get documentsSubmittedDesc =>
      'Kontrola zvyčajne trvá 1-2 pracovné dni. Dostanete push notifikáciu s výsledkom.';

  @override
  String get securityAes => 'Vaše údaje sú chránené šifrovaním AES-256';

  @override
  String get verificationTime => 'Overenie trvá 1-2 pracovné dni';

  @override
  String get pushNotification => 'Dostanete push notifikáciu s výsledkom';

  @override
  String get kycWebOnly => 'Overenie KYC je dostupné iba v mobilnej aplikácii.';

  @override
  String verificationError(String code) {
    return 'Chyba overenia: $code';
  }

  @override
  String get organizations => 'Organizácie';

  @override
  String get noOrganizations => 'Žiadne organizácie';

  @override
  String get noOrganizationsDesc =>
      'Vytvorte organizáciu alebo prijmite pozvánku';

  @override
  String get createOrganization => 'Vytvoriť organizáciu';

  @override
  String get newOrganization => 'Nová organizácia';

  @override
  String get orgName => 'Názov *';

  @override
  String get orgDescription => 'Popis';

  @override
  String get orgEmail => 'Kontaktný email';

  @override
  String get orgWebsite => 'Webová stránka';

  @override
  String get orgLegalAddress => 'Právna adresa';

  @override
  String get create => 'Vytvoriť';

  @override
  String get organization => 'Organizácia';

  @override
  String get contacts => 'Kontakty';

  @override
  String members(int count) {
    return 'Členovia ($count)';
  }

  @override
  String get inviteMember => 'Pozvať člena';

  @override
  String get invite => 'Pozvať';

  @override
  String get sendInvite => 'Odoslať pozvánku';

  @override
  String inviteSent(String email) {
    return 'Pozvánka odoslaná na $email';
  }

  @override
  String get role => 'Rola';

  @override
  String get roleOwner => 'Vlastník';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operátor';

  @override
  String get roleViewer => 'Pozorovateľ';

  @override
  String get editOrganization => 'Upraviť';

  @override
  String get editOrganizationTitle => 'Upraviť organizáciu';

  @override
  String get removeMember => 'Odstrániť člena';

  @override
  String removeMemberConfirm(String name) {
    return 'Odstrániť $name z organizácie?';
  }

  @override
  String get memberRemoved => 'Člen odstránený';

  @override
  String get roleChanged => 'Rola zmenená';

  @override
  String get kybVerified => 'Overené';

  @override
  String get kybPending => 'Čakajúce';

  @override
  String get kybRejected => 'Zamietnuté';

  @override
  String get kybNone => 'Neoverené';

  @override
  String get kybVerification => 'Začať KYB overenie';

  @override
  String get kybStartBusiness => 'Začať overenie podnikania';

  @override
  String get kybStatusLabel => 'KYB stav';

  @override
  String get noKyb => 'Žiadne KYB';

  @override
  String get kybBusinessVerificationTitle => 'Overenie podnikania (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organizácia úspešne overená.';

  @override
  String get kybPendingOrgDesc =>
      'Dokumenty sú v procese kontroly. Zvyčajne to trvá 1-3 pracovné dni.';

  @override
  String get kybRejectedOrgDesc => 'Overenie zlyhalo. Skúste to prosím znova.';

  @override
  String get kybNoneOrgDesc =>
      'Overte svoju organizáciu pre prístup k obchodným funkciám.';

  @override
  String get invitePlus => '+ Pozvať';

  @override
  String get kybVerificationTitle => 'KYB overenie';

  @override
  String get kybWebOnlyBusiness =>
      'KYB overenie je dostupné iba v mobilnej aplikácii.';

  @override
  String get unknownDevice => 'Neznáme zariadenie';

  @override
  String get ipUnknown => 'IP neznáma';

  @override
  String get currentSessionLabel => 'Aktuálna';

  @override
  String get endSessionAction => 'Ukončiť';

  @override
  String get deviceLoggedOut => 'Zariadenie bude odhlásené.';

  @override
  String get acceptInvitationTitle => 'Pozvánka do organizácie';

  @override
  String get acceptInvitation => 'Prijať pozvánku';

  @override
  String get acceptInvitationDesc =>
      'Boli ste pozvaní, aby ste sa pripojili k organizácii v ekosystéme Taler.';

  @override
  String get accept => 'Prijať';

  @override
  String get reject => 'Odmietnuť';

  @override
  String get sessions => 'Aktívne relácie';

  @override
  String get currentSession => 'Aktuálna relácia';

  @override
  String get deleteSession => 'Ukončiť reláciu';

  @override
  String get deleteSessionConfirm => 'Ukončiť túto reláciu?';

  @override
  String get sessionDeleted => 'Relácia ukončená';

  @override
  String get noSessions => 'Žiadne aktívne relácie';

  @override
  String minutesAgo(int count) {
    return 'pred $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'pred $count hod';
  }

  @override
  String daysAgo(int count) {
    return 'pred $count dňami';
  }

  @override
  String get justNow => 'Práve teraz';

  @override
  String get settings => 'Nastavenia';

  @override
  String get security => 'Zabezpečenie';

  @override
  String get biometrics => 'Biometria';

  @override
  String get biometricsDesc =>
      'Rýchle prihlásenie pomocou Face ID alebo odtlačku prsta';

  @override
  String get biometricsConfirm =>
      'Potvrďte biometriu na povolenie rýchleho prihlásenia';

  @override
  String get biometricsError =>
      'Nepodarilo sa povoliť biometriu. Skontrolujte nastavenia zariadenia.';

  @override
  String get changePassword => 'Zmeniť heslo';

  @override
  String get twoFactorAuth => 'Dvojfaktorová autentifikácia';

  @override
  String get currentPassword => 'Aktuálne heslo';

  @override
  String get newPassword => 'Nové heslo';

  @override
  String get confirmNewPassword => 'Potvrdiť nové heslo';

  @override
  String get passwordChanged => 'Heslo zmenené';

  @override
  String get wrongCurrentPassword => 'Nesprávne aktuálne heslo';

  @override
  String get passwordTooWeak =>
      'Heslo je príliš slabé: vyžaduje sa aspoň 8 znakov, písmeno a číslica';

  @override
  String get passwordChangeFailed => 'Nepodarilo sa zmeniť heslo';

  @override
  String get notifications => 'Upozornenia';

  @override
  String get permissions => 'Povolenia';

  @override
  String get permissionNotifications => 'Push upozornenia';

  @override
  String get permissionNotificationsDesc => 'Hovory, správy, stavy';

  @override
  String get permissionMicrophone => 'Mikrofón';

  @override
  String get permissionMicrophoneDesc => 'Hovory a hlasový asistent';

  @override
  String get permissionCamera => 'Kamera';

  @override
  String get permissionCameraDesc => 'Videohovory a overenie';

  @override
  String get permissionLocation => 'Poloha';

  @override
  String get permissionLocationDesc => 'Používa sa na overenie';

  @override
  String get permissionOpenSettings =>
      'Ak chcete zrušiť povolenie, otvorte systémové nastavenia';

  @override
  String get pushKycStatus => 'Stav KYC Push';

  @override
  String get pushKycStatusDesc => 'Výsledok overenia';

  @override
  String get pushLogins => 'Prihlásenie Push';

  @override
  String get pushLoginsDesc => 'Pri prihlásení z nového zariadenia';

  @override
  String get account => 'Účet';

  @override
  String get language => 'Jazyk';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Jazyk rozhrania';

  @override
  String get exportData => 'Exportovať údaje (GDPR)';

  @override
  String get deleteAccount => 'Zmazať účet';

  @override
  String get deleteAccountConfirm => 'Zmazať účet?';

  @override
  String get deleteAccountDesc =>
      'Všetky vaše údaje budú zmazané (GDPR). Táto akcia je nevratná.';

  @override
  String get logout => 'Odhlásiť sa';

  @override
  String get logoutConfirm => 'Odhlásiť sa?';

  @override
  String get logoutDesc => 'Budete odhlásení z Taler ID na tomto zariadení.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN kód';

  @override
  String get pinCodeDesc => 'Rýchle prihlásenie pomocou 4-ciferného kódu';

  @override
  String get setupPin => 'Nastaviť PIN';

  @override
  String get enterPin => 'Zadajte PIN';

  @override
  String get confirmPin => 'Potvrďte PIN';

  @override
  String get pinMismatch => 'PIN kódy sa nezhodujú';

  @override
  String get passwordMismatch => 'Heslá sa nezhodujú';

  @override
  String get pinSet => 'PIN úspešne nastavený';

  @override
  String get enterPinToLogin => 'Zadajte PIN na prihlásenie';

  @override
  String get pinIncorrect => 'Nesprávny PIN';

  @override
  String get removePin => 'Odstrániť PIN';

  @override
  String get pinRemoved => 'PIN odstránený';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get delete => 'Zmazať';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Skúsiť znova';

  @override
  String get loading => 'Načítava sa...';

  @override
  String get error => 'Chyba';

  @override
  String get success => 'Úspech';

  @override
  String get noData => 'Žiadne údaje';

  @override
  String get failedToLoad => 'Nepodarilo sa načítať údaje';

  @override
  String get failedToLoadProfile => 'Nepodarilo sa načítať profil';

  @override
  String get failedToSave => 'Nepodarilo sa uložiť zmeny';

  @override
  String get failedToLoadOrgs => 'Nepodarilo sa načítať organizácie';

  @override
  String get failedToLoadOrg => 'Nepodarilo sa načítať údaje organizácie';

  @override
  String get failedToCreateOrg => 'Nepodarilo sa vytvoriť organizáciu';

  @override
  String get failedToInvite => 'Nepodarilo sa odoslať pozvánku';

  @override
  String get failedToAcceptInvite => 'Nepodarilo sa prijať pozvánku';

  @override
  String get failedToLoadSessions => 'Nepodarilo sa načítať relácie';

  @override
  String get failedToDeleteSession => 'Nepodarilo sa ukončiť reláciu';

  @override
  String get failedToLoadKyc => 'Nepodarilo sa načítať stav overenia';

  @override
  String get failedToStartKyc => 'Nepodarilo sa začať overenie';

  @override
  String get verifiedPersonalInfo => 'Overené údaje';

  @override
  String get middleName => 'Prostredné meno';

  @override
  String get placeOfBirth => 'Miesto narodenia';

  @override
  String get nationality => 'Národnosť';

  @override
  String get gender => 'Pohlavie';

  @override
  String get genderMale => 'Muž';

  @override
  String get genderFemale => 'Žena';

  @override
  String get docNumber => 'Číslo';

  @override
  String get docIssuedDate => 'Vydané';

  @override
  String get docValidUntil => 'Platné do';

  @override
  String get docIssuedBy => 'Vydané kým';

  @override
  String get address => 'Adresa';

  @override
  String get refreshData => 'Obnoviť údaje';

  @override
  String get failedToLoadSumsubData => 'Nepodarilo sa načítať údaje overenia';

  @override
  String get sumsubDataLoading => 'Načítavajú sa údaje overenia...';

  @override
  String get reviewResultGreen => 'Overenie úspešné';

  @override
  String get reviewResultRed => 'Overenie neúspešné';

  @override
  String get tabAssistant => 'Asistent';

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
  String get assistantConnecting => 'Pripája sa…';

  @override
  String get assistantSpeaking => 'Hovorí…';

  @override
  String get assistantListening => 'Počúva…';

  @override
  String get assistantTapToStart => 'Klepnutím začnite';

  @override
  String get assistantTapToTalk => 'Klepnutím hovorte s AI';

  @override
  String get assistantRealtimeDesc => 'Asistent odpovedá hlasom v reálnom čase';

  @override
  String get assistantConnectingToAssistant => 'Pripája sa k asistentovi...';

  @override
  String get assistantAiSpeaking => 'AI hovorí...';

  @override
  String get assistantAiListening => 'AI počúva';

  @override
  String get assistantSpeakerOn => 'Reproduktor zapnutý';

  @override
  String get assistantSpeaker => 'Reproduktor';

  @override
  String get assistantEnd => 'Koniec';

  @override
  String get assistantUnmute => 'Zrušiť stlmenie';

  @override
  String get assistantMicrophone => 'Mikrofón';

  @override
  String get assistantConnectionError => 'Chyba pripojenia';

  @override
  String get tabMessenger => 'Správy';

  @override
  String get tabCalls => 'Hovory';

  @override
  String get tabCalendar => 'Kalendár';

  @override
  String get appearance => 'Vzhľad';

  @override
  String get appearanceSelect => 'Vyberte tému';

  @override
  String get themeLight => 'Svetlá';

  @override
  String get themeDark => 'Tmavá';

  @override
  String get themeSystem => 'Systémová';

  @override
  String get onboardingTitle1 => 'Zjednotená identita';

  @override
  String get onboardingDesc1 =>
      'Taler ID je váš digitálny pas v ekosystéme Taler. Jeden účet pre všetky služby.';

  @override
  String get onboardingTitle2 => 'Bezpečnosť údajov';

  @override
  String get onboardingDesc2 =>
      'KYC overenie, AES-256 šifrovanie a dvojfaktorová autentifikácia chránia vašu identitu.';

  @override
  String get onboardingTitle3 => 'Buďte informovaní';

  @override
  String get onboardingDesc3 =>
      'Dostávajte upozornenia o stave overenia, prihláseniach z nových zariadení a prichádzajúcich hovoroch.';

  @override
  String get onboardingNext => 'Ďalej';

  @override
  String get onboardingEnableNotifications => 'Povoliť upozornenia';

  @override
  String get onboardingTitle4 => 'Hlasové hovory';

  @override
  String get onboardingDesc4 =>
      'Udeľte prístup k mikrofónu pre hlasové hovory a AI asistenta. Toto môžete neskôr zmeniť v nastaveniach.';

  @override
  String get onboardingEnableMicrophone => 'Povoliť mikrofón';

  @override
  String get onboardingStart => 'Začať';

  @override
  String get onboardingSkip => 'Preskočiť';

  @override
  String get meshLocalNetworkPromptTitle => 'Povoliť prístup k miestnej sieti';

  @override
  String get meshLocalNetworkPromptBody =>
      'Aby ste našli rovesníkov na Wi-Fi (offline skupinové hovory), iOS vyžaduje povolenie pre miestnu sieť. Otvorte Nastavenia → Súkromie a bezpečnosť → Miestna sieť → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Otvoriť nastavenia';

  @override
  String get meshLocalNetworkPromptDismiss => 'Rozumiem';

  @override
  String get forgotPassword => 'Zabudli ste heslo?';

  @override
  String get forgotPasswordTitle => 'Obnoviť heslo';

  @override
  String get forgotPasswordSubtitle =>
      'Zadajte svoj email pre prijatie obnovovacieho kódu';

  @override
  String resetCodeSent(String email) {
    return 'Kód odoslaný na $email';
  }

  @override
  String get enterResetCode => 'Zadajte kód';

  @override
  String get resetPasswordButton => 'Obnoviť heslo';

  @override
  String get passwordResetSuccess => 'Heslo bolo úspešne obnovené';

  @override
  String get sendCode => 'Odoslať kód';

  @override
  String get resendCode => 'Znova odoslať kód';

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
  String get newGroup => 'Nová skupina';

  @override
  String get newChat => 'Nový chat';

  @override
  String get groupName => 'Názov skupiny';

  @override
  String get createGroup => 'Vytvoriť skupinu';

  @override
  String get groupInfo => 'Informácie o skupine';

  @override
  String groupMembers(int count) {
    return 'Členovia ($count)';
  }

  @override
  String get addMembers => 'Pridať členov';

  @override
  String get leaveGroup => 'Opustiť skupinu';

  @override
  String get leaveGroupConfirm => 'Opustiť túto skupinu?';

  @override
  String get deleteGroup => 'Zmazať skupinu';

  @override
  String get deleteGroupConfirm =>
      'Zmazať túto skupinu? Toto sa nedá vrátiť späť.';

  @override
  String get groupRoleOwner => 'Vlastník';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Člen';

  @override
  String get selectParticipants => 'Vybrať účastníkov';

  @override
  String selectedCount(int count) {
    return '$count vybraných';
  }

  @override
  String get changeRole => 'Zmeniť rolu';

  @override
  String get groupCreated => 'Skupina vytvorená';

  @override
  String memberJoined(String name) {
    return '$name sa pridal';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name odišiel';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name bol odstránený';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name je teraz $role';
  }

  @override
  String participantsCount(int count) {
    return '$count účastníkov';
  }

  @override
  String get enterGroupName => 'Zadajte názov skupiny';

  @override
  String get muteNotifications => 'Stlmiť upozornenia';

  @override
  String get unmuteNotifications => 'Zrušiť stlmenie upozornení';

  @override
  String get muteFor1Hour => 'Na 1 hodinu';

  @override
  String get muteFor8Hours => 'Na 8 hodín';

  @override
  String get muteFor2Days => 'Na 2 dni';

  @override
  String get muteForever => 'Navždy';

  @override
  String get muted => 'Stlmené';

  @override
  String get tabTranslator => 'Preložiť';

  @override
  String get translatorTitle => 'Prekladač';

  @override
  String get translatorSelectLanguage => 'Vyberte jazyk';

  @override
  String get translatorDownloading => 'Sťahovanie jazykových modelov...';

  @override
  String get translatorDownloadingHint =>
      'Internet je potrebný iba pri prvom sťahovaní';

  @override
  String get translatorTypeHint => 'Napíšte text alebo klepnite na mikrofón';

  @override
  String get translatorListening => 'Počúvam...';

  @override
  String get translatorTapToSpeak => 'Klepnite na rozprávanie';

  @override
  String get translatorTapToStop => 'Klepnite na zastavenie';

  @override
  String get translatorAutoSpeak => 'Automatické rozprávanie';

  @override
  String get translatorCopied => 'Skopírované';

  @override
  String get translatorLangRu => 'Ruský';

  @override
  String get translatorLangEn => 'Anglický';

  @override
  String get translatorLangDe => 'Nemecký';

  @override
  String get translatorLangFr => 'Francúzsky';

  @override
  String get translatorLangEs => 'Španielsky';

  @override
  String get translatorLangIt => 'Taliansky';

  @override
  String get translatorLangPt => 'Portugalský';

  @override
  String get translatorLangTr => 'Turecký';

  @override
  String get translatorLangZh => 'Čínsky';

  @override
  String get translatorLangJa => 'Japonský';

  @override
  String get translatorLangKo => 'Kórejský';

  @override
  String get translatorLangAr => 'Arabský';

  @override
  String get translatorLangPl => 'Poľský';

  @override
  String get translatorLangSk => 'Slovenský';

  @override
  String get translatorLangCs => 'Český';

  @override
  String get translatorLangNl => 'Holandský';

  @override
  String get translatorLangSv => 'Švédsky';

  @override
  String get translatorLangDa => 'Dánsky';

  @override
  String get translatorLangNo => 'Nórsky';

  @override
  String get translatorLangFi => 'Fínsky';

  @override
  String get translatorLangUk => 'Ukrajinský';

  @override
  String get translatorLangEl => 'Grécky';

  @override
  String get translatorLangRo => 'Rumunský';

  @override
  String get translatorLangHu => 'Maďarský';

  @override
  String get translatorLangBg => 'Bulharský';

  @override
  String get translatorLangHr => 'Chorvátsky';

  @override
  String get translatorLangSr => 'Srbský';

  @override
  String get translatorLangHi => 'Hindský';

  @override
  String get translatorLangTh => 'Thajský';

  @override
  String get translatorLangVi => 'Vietnamský';

  @override
  String get translatorLangId => 'Indonézsky';

  @override
  String get translatorLangMs => 'Malajský';

  @override
  String get translatorLangHe => 'Hebrejský';

  @override
  String get translatorLangFa => 'Perzský';

  @override
  String get callInProgress => 'Hovor prebieha';

  @override
  String get joinCall => 'Pripojiť sa';

  @override
  String get createCallLink => 'Odkaz na hovor';

  @override
  String get callLinkCopied => 'Odkaz skopírovaný';

  @override
  String get callLinkTitle => 'Odkaz na miestnosť';

  @override
  String get connectionUnstable =>
      'Nestabilné pripojenie — skontrolujte internet';

  @override
  String get today => 'Dnes';

  @override
  String get yesterday => 'Včera';

  @override
  String get errorTimeout =>
      'Čas pripojenia vypršal. Skontrolujte svoje internetové pripojenie.';

  @override
  String get errorNoConnection => 'Žiadne internetové pripojenie.';

  @override
  String get errorGeneral => 'Vyskytla sa chyba. Skúste to znova.';

  @override
  String errorWithMessage(String message) {
    return 'Chyba: $message';
  }

  @override
  String get notifChannelMessages => 'Správy';

  @override
  String get notifChannelMessagesDesc => 'Upozornenia na nové správy';

  @override
  String get notifChannelMissedCalls => 'Zmeškané hovory';

  @override
  String get notifChannelMissedCallsDesc => 'Upozornenia na zmeškané hovory';

  @override
  String get notifMissedCall => 'Zmeškaný hovor';

  @override
  String get notifAccept => 'Prijať';

  @override
  String get notifDecline => 'Odmietnuť';

  @override
  String get notifIncomingCall => 'Prichádzajúci hovor';

  @override
  String get notifIncomingCallChannel => 'Prichádzajúci hovor';

  @override
  String get notifMissedCallChannel => 'Zmeškaný hovor';

  @override
  String get notifUnknown => 'Neznámy';

  @override
  String get effectNone => 'Bez pozadia';

  @override
  String get effectBlur => 'Rozmazanie';

  @override
  String get effectOffice => 'Kancelária';

  @override
  String get effectNature => 'Príroda';

  @override
  String get effectGradient => 'Prechod';

  @override
  String get effectLibrary => 'Knižnica';

  @override
  String get effectCity => 'Mesto';

  @override
  String get effectMinimalism => 'Minimalizmus';

  @override
  String get voiceParticipant => 'Účastník';

  @override
  String get voiceInvitesToRoom => 'vás pozýva do miestnosti';

  @override
  String get voiceRoom => 'Miestnosť';

  @override
  String get voicePasswordProtected => 'Chránené heslom';

  @override
  String get voicePasswordHint => 'Heslo';

  @override
  String get voiceEnter => 'Vstúpiť';

  @override
  String get voiceJoinRoom => 'Pripojiť sa k miestnosti';

  @override
  String get voiceYourName => 'Vaše meno';

  @override
  String voiceInvitationSent(String name) {
    return 'Pozvánka odoslaná $name';
  }

  @override
  String get voiceNoActiveRoom => 'Žiadna aktívna miestnosť';

  @override
  String get voiceCameraPermission =>
      'Povoliť prístup ku kamere v Nastavenia → Súkromie → Kamera → TalerID';

  @override
  String get voiceOpenSettings => 'Otvoriť';

  @override
  String voiceCameraError(String error) {
    return 'Nepodarilo sa zapnúť kameru: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Všetci súhlasili. Nahrávanie začalo.';

  @override
  String get voiceNewParticipantAgreed =>
      'Nový účastník súhlasil s nahrávaním.';

  @override
  String get voiceDeclinedRecording =>
      'Odmietli ste nahrávanie. Opúšťate hovor.';

  @override
  String get voiceRecordingEnded => 'Nahrávanie ukončené';

  @override
  String get voiceRecordingInProgress => 'Nahrávanie prebieha';

  @override
  String get voiceTranscriptionRequest => 'Žiadosť o prepis';

  @override
  String get voiceRecordingRequest => 'Žiadosť o nahrávanie';

  @override
  String get voiceAgree => 'Súhlasím';

  @override
  String get voiceDeclineAndLeave => 'Odmietnuť a odísť';

  @override
  String get voiceAudioOutput => 'Zvukový výstup';

  @override
  String get voiceAudioPhone => 'Telefón';

  @override
  String get voiceAudioSpeaker => 'Reproduktor';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Slúchadlá';

  @override
  String get voiceLinkCopied => 'Odkaz skopírovaný';

  @override
  String get voiceTranslateTo => 'Preložiť do';

  @override
  String get voiceSearchLanguage => 'Hľadať jazyk...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Miestnosť $name';
  }

  @override
  String get voiceVoiceCall => 'Hlasový hovor';

  @override
  String get voiceOnHold => 'Na podržaní';

  @override
  String get voiceActiveCall => 'Aktívny';

  @override
  String get voiceEndAllCalls => 'Ukončiť všetky hovory';

  @override
  String get voiceEndThisCall => 'Ukončiť tento hovor';

  @override
  String get voiceCopyLink => 'Kopírovať odkaz';

  @override
  String get voiceAddParticipant => 'Pridať účastníka';

  @override
  String get voiceReconnecting => 'Opätovné pripojenie...';

  @override
  String get voiceConnectionError => 'Chyba pripojenia';

  @override
  String get voiceClose => 'Zavrieť';

  @override
  String get voiceCalling => 'Volanie...';

  @override
  String get voiceCallActive => 'Hovor aktívny';

  @override
  String get voiceWaiting => 'Čakanie';

  @override
  String get voiceWaitingUpper => 'ČAKANIE';

  @override
  String get voiceRec => 'NAHR';

  @override
  String get voiceStop => 'Zastaviť';

  @override
  String get voiceRecord => 'Nahrávanie';

  @override
  String get voiceTranslation => 'Preklad';

  @override
  String get voiceAudio => 'Zvuk';

  @override
  String get voiceFlipCamera => 'Prevrátiť';

  @override
  String get voiceBackground => 'Pozadie';

  @override
  String get voiceAssistantSpeakingStatus => 'Asistent hovorí...';

  @override
  String get voiceAssistantListeningStatus => 'Asistent počúva...';

  @override
  String get voiceUnmute => 'Zapnúť zvuk';

  @override
  String get voiceMic => 'Mikrofón';

  @override
  String get voiceAssistantLabel => 'Asistent';

  @override
  String get voiceCameraOn => 'Kamera zapnutá';

  @override
  String get voiceCameraLabel => 'Kamera';

  @override
  String get voiceEndCall => 'Ukončiť hovor';

  @override
  String get voiceWaitingParticipants => 'Čakanie na účastníkov...';

  @override
  String get voiceYou => 'Vy';

  @override
  String get voiceAiAssistant => 'AI Asistent';

  @override
  String get voiceVideoUnavailable => 'Video nedostupné';

  @override
  String get voiceSearchNickname => 'Hľadať podľa prezývky...';

  @override
  String get voiceTranscriptionWord => 'prepis';

  @override
  String get voiceRecordingWord => 'nahrávanie';

  @override
  String get voiceConnecting => 'Pripájanie...';

  @override
  String get voiceVideoBackground => 'Video pozadie';

  @override
  String get voiceCallSettings => 'Nastavenia hovoru';

  @override
  String get voiceEnableAI => 'Povoliť AI asistenta';

  @override
  String get voiceAIParticipating => 'AI sa zúčastní na konverzácii';

  @override
  String get voiceNormalCall => 'Normálny hovor bez AI';

  @override
  String get voiceCallConfirm => 'Vykonať hovor?';

  @override
  String get chatAlreadyInCall => 'Už ste v hovore';

  @override
  String chatCallError(String error) {
    return 'Chyba hovoru: $error';
  }

  @override
  String get chatPhotoVideo => 'Foto / Video';

  @override
  String get chatCamera => 'Kamera';

  @override
  String get chatFile => 'Súbor';

  @override
  String get chatContact => 'Kontakt';

  @override
  String get chatSelectContact => 'Vyberte kontakt';

  @override
  String get chatNoContacts => 'Žiadne kontakty';

  @override
  String get chatUser => 'Používateľ';

  @override
  String get chatFileAttachment => '📎 Súbor';

  @override
  String chatFileUploadError(String error) {
    return 'Chyba nahrávania súboru: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Hlasová správa';

  @override
  String get chatGroup => 'Skupina';

  @override
  String get chatDialog => 'Dialóg';

  @override
  String get chatCall => 'Hovor';

  @override
  String get chatStartConversation => 'Začať konverzáciu';

  @override
  String get chatYou => 'Vy';

  @override
  String get chatIsTyping => 'píše...';

  @override
  String chatUserIsTyping(String name) {
    return '$name píše...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names píšu...';
  }

  @override
  String get chatPreparingFile => 'Pripravuje sa súbor…';

  @override
  String chatUploading(int progress) {
    return 'Nahráva sa… $progress%';
  }

  @override
  String get chatEdited => 'Upravené';

  @override
  String get chatViaMesh => 'cez mesh';

  @override
  String get chatReply => 'Odpovedať';

  @override
  String get chatEdit => 'Upraviť';

  @override
  String get chatCopy => 'Kopírovať';

  @override
  String get chatCopied => 'Skopírované';

  @override
  String get chatSaveMedia => 'Uložiť';

  @override
  String get chatForward => 'Preposlať';

  @override
  String get chatSaving => 'Ukladá sa...';

  @override
  String get chatSavedToGallery => 'Uložené do galérie';

  @override
  String get chatNoSavePermission =>
      'Nie je povolenie na uloženie. Skontrolujte nastavenia.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Chyba pri ukladaní súboru';

  @override
  String get chatDeleteMessage => 'Vymazať správu';

  @override
  String get chatDeleteForMe => 'Vymazať pre mňa';

  @override
  String get chatDeleteForEveryone => 'Vymazať pre všetkých';

  @override
  String get chatMessageForwarded => 'Správa preposlaná';

  @override
  String get chatContactTapToOpen => 'Kontakt · ťuknite na otvorenie';

  @override
  String get chatForwardTo => 'Preposlať komu...';

  @override
  String get chatSearchHint => 'Hľadať...';

  @override
  String get chatRecording => 'Nahráva sa...';

  @override
  String get chatMessageHint => 'Správa...';

  @override
  String get chatHideKeyboard => 'Skryť klávesnicu';

  @override
  String get chatEditing => 'Upravuje sa';

  @override
  String get chatFileDownloadError => 'Chyba pri sťahovaní súboru';

  @override
  String get chatVoiceMessageShort => 'Hlasová správa';

  @override
  String get chatVideoSavedToGallery => 'Video uložené do galérie';

  @override
  String get chatSavingError => 'Chyba pri ukladaní';

  @override
  String get convSetNickname => 'Nastaviť prezývku';

  @override
  String get convNicknameRequired =>
      'Na používanie messengeru je potrebná prezývka. Ostatní používatelia vás môžu nájsť podľa nej.';

  @override
  String get convNicknameRules => '3–30 znakov: písmená, číslice, _';

  @override
  String get convNicknameTaken => 'Prezývka je už obsadená';

  @override
  String get convSaveError => 'Chyba pri ukladaní';

  @override
  String get convContactsLabel => 'Kontakty';

  @override
  String get convDefaultUser => 'Používateľ';

  @override
  String get convNoDialogs => 'Žiadne konverzácie';

  @override
  String get convFindUserToChat => 'Nájdite používateľa na začatie chatu';

  @override
  String get convDefaultContact => 'Kontakt';

  @override
  String get dashboardUser => 'Používateľ';

  @override
  String get dashboardIncomingCall => 'Prichádzajúci hovor';

  @override
  String get dashboardDecline => 'Odmietnuť';

  @override
  String get dashboardAccept => 'Prijať';

  @override
  String get dashboardActiveCall => 'Aktívny hovor — klepnite pre návrat';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Dostupná aktualizácia $version';
  }

  @override
  String get dashboardUpdate => 'Aktualizovať';

  @override
  String get dashboardWhatsNew => 'Čo je nové';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Čo je nové v $version';
  }

  @override
  String get dashboardInstalling => 'Inštalujem...';

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
  String get contactRequestsTitle => 'Kontakty';

  @override
  String get messengerContactRequestsSection => 'Žiadosti o kontakt';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nové žiadosti',
      one: '1 nová žiadosť',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Hľadať';

  @override
  String get contactRequestsIncoming => 'Prichádzajúce';

  @override
  String get contactRequestsSent => 'Odoslané';

  @override
  String get contactRequestsSearchHint => 'Prezývka alebo email';

  @override
  String get contactRequestSent => 'Žiadosť odoslaná';

  @override
  String get contactRequestsNoUsers => 'Nenašli sa žiadni používatelia';

  @override
  String get contactRequestsSearchHelp =>
      'Zadajte presnú prezývku alebo email\na stlačte hľadať';

  @override
  String get contactRequestsSendTooltip => 'Odoslať žiadosť';

  @override
  String get contactRequestTitle => 'Žiadosť o kontakt';

  @override
  String contactRequestConfirm(String name) {
    return 'Odoslať žiadosť o kontakt používateľovi $name?';
  }

  @override
  String get contactRequestSend => 'Odoslať';

  @override
  String get contactRequestsNoIncoming => 'Žiadne prichádzajúce žiadosti';

  @override
  String get contactRequestsNoSent => 'Žiadne odoslané žiadosti';

  @override
  String get contactRequestStatusPending => 'Čaká na odpoveď';

  @override
  String get contactRequestStatusAccepted => 'Prijaté';

  @override
  String get contactRequestStatusRejected => 'Zamietnuté';

  @override
  String get userSearchTitle => 'Nájsť používateľa';

  @override
  String get userSearchHint => 'Prezývka, telefón alebo email';

  @override
  String get userSearchHelper =>
      'Zadajte @prezývku, email alebo meno na hľadanie';

  @override
  String get userSearchNoUsers => 'Nenašli sa žiadni používatelia';

  @override
  String get userProfileShareContact => 'Zdieľať kontakt';

  @override
  String get userProfileShareContactDesc => 'Odoslať odkaz na kontakt';

  @override
  String get userProfileCopyLink => 'Kopírovať odkaz';

  @override
  String get userProfileCopied => 'Skopírované';

  @override
  String get userProfileTitle => 'Profil';

  @override
  String get userProfileLoadError => 'Chyba načítania profilu';

  @override
  String get userProfileMessage => 'Správa';

  @override
  String get userProfileCall => 'Hovor';

  @override
  String get userProfileRequestSent => 'Žiadosť odoslaná';

  @override
  String get userProfileAccept => 'Prijať';

  @override
  String get userProfileDecline => 'Odmietnuť';

  @override
  String get userProfileAddToContacts => 'Pridať do kontaktov';

  @override
  String get userProfileMediaTab => 'Médiá';

  @override
  String get userProfileFilesTab => 'Súbory';

  @override
  String get userProfileLinksTab => 'Odkazy';

  @override
  String get userProfileRecordingsTab => 'Nahrávky';

  @override
  String get userProfileSummariesTab => 'Zhrnutia';

  @override
  String get userProfileNoMedia => 'Žiadne mediálne súbory';

  @override
  String get userProfileNoFiles => 'Žiadne súbory';

  @override
  String get userProfileNoLinks => 'Žiadne odkazy';

  @override
  String get userProfileNoRecordings => 'Žiadne nahrávky';

  @override
  String get userProfileNoSummaries => 'Žiadne zhrnutia';

  @override
  String get userProfileMeetingSummary => 'Zhrnutie stretnutia';

  @override
  String get userProfileFailedOpenChat => 'Nepodarilo sa otvoriť chat';

  @override
  String get sharedMediaTitle => 'Médiá a súbory';

  @override
  String get sharedMediaTab => 'Médiá';

  @override
  String get sharedFilesTab => 'Súbory';

  @override
  String get sharedLinksTab => 'Odkazy';

  @override
  String get sharedNoMedia => 'Žiadne mediálne súbory';

  @override
  String get sharedNoFiles => 'Žiadne súbory';

  @override
  String get sharedNoLinks => 'Žiadne odkazy';

  @override
  String get shareToChat => 'Preposlať do chatu';

  @override
  String get shareSelectChat => 'Vyberte chat';

  @override
  String get shareNoChats => 'Žiadne chaty';

  @override
  String shareFilesCount(int count) {
    return '$count súbory';
  }

  @override
  String get contactsTitle => 'Kontakty';

  @override
  String get contactsAddTooltip => 'Pridať kontakt';

  @override
  String get contactsSearchHint => 'Hľadať kontakty...';

  @override
  String get contactsNotFound => 'Nič sa nenašlo';

  @override
  String get contactsEmpty => 'Žiadne kontakty';

  @override
  String get contactsAdd => 'Pridať kontakt';

  @override
  String get contactsPendingConfirmation => 'Čaká sa na potvrdenie';

  @override
  String get contactsMessage => 'Správa';

  @override
  String get contactsCall => 'Hovor';

  @override
  String get contactsResend => 'Znova odoslať žiadosť';

  @override
  String get contactsResendTimeout => 'Skúsiť znova o 24h';

  @override
  String get contactsResent => 'Žiadosť odoslaná znova';

  @override
  String get contactsWantsToConnect => 'Chce sa s vami spojiť';

  @override
  String get contactsSearchPeople => 'Nájsť ľudí';

  @override
  String get notesTitle => 'Poznámky';

  @override
  String get notesAssistantSpeaking => 'Asistent hovorí...';

  @override
  String get notesListening => 'Počúvam...';

  @override
  String get notesEmpty => 'Žiadne poznámky';

  @override
  String get notesEmptyHint =>
      'Stlačte mikrofón pre diktovanie\nalebo + pre manuálny vstup';

  @override
  String get notesDeleteConfirm => 'Vymazať poznámku?';

  @override
  String get notesNew => 'Nová poznámka';

  @override
  String get notesEdit => 'Upraviť';

  @override
  String get notesTitleHint => 'Názov';

  @override
  String get notesContentHint => 'Napíšte svoje myšlienky...';

  @override
  String get calendarTitle => 'Kalendár';

  @override
  String get calendarStop => 'Zastaviť';

  @override
  String get calendarVoiceInput => 'Hlasový vstup';

  @override
  String get calendarNewEvent => 'Nová udalosť';

  @override
  String get calendarAssistantSpeaking => 'Asistent hovorí...';

  @override
  String get calendarListening => 'Počúvam...';

  @override
  String calendarInvitations(int count) {
    return 'Pozvánky ($count)';
  }

  @override
  String get calendarNoEvents => 'Žiadne udalosti';

  @override
  String get calendarDayMon => 'Po';

  @override
  String get calendarDayTue => 'Ut';

  @override
  String get calendarDayWed => 'St';

  @override
  String get calendarDayThu => 'Št';

  @override
  String get calendarDayFri => 'Pi';

  @override
  String get calendarDaySat => 'So';

  @override
  String get calendarDaySun => 'Ne';

  @override
  String get calendarEnterRoom => 'Vstúpiť do miestnosti';

  @override
  String get calendarMeeting => 'Stretnutie';

  @override
  String calendarLocationPrefix(String location) {
    return 'Miesto: $location';
  }

  @override
  String get calendarEditEvent => 'Upraviť';

  @override
  String get calendarTitleHint => 'Názov';

  @override
  String get calendarDescriptionHint => 'Popis';

  @override
  String get calendarTypeEvent => 'Udalosť';

  @override
  String get calendarTypeMeeting => 'Stretnutie';

  @override
  String get calendarTypeReminder => 'Pripomienka';

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
  String get calendarTypeLabel => 'Typ';

  @override
  String get calendarMeetingLink => 'Odkaz na stretnutie';

  @override
  String get calendarLocationHint => 'Miesto';

  @override
  String get calendarDateLabel => 'Dátum';

  @override
  String get calendarTimeLabel => 'Čas';

  @override
  String get calendarReminderLabel => 'Pripomienka';

  @override
  String get calendarReminderNone => 'Žiadna';

  @override
  String get calendarReminder15min => '15 min pred';

  @override
  String get calendarReminder30min => '30 min pred';

  @override
  String get calendarReminder1hour => '1 hod pred';

  @override
  String get calendarRepeatLabel => 'Opakovanie';

  @override
  String get calendarRepeatNone => 'Bez opakovania';

  @override
  String get calendarRepeatDaily => 'Každý deň';

  @override
  String get calendarRepeatWeekly => 'Každý týždeň';

  @override
  String get calendarRepeatMonthly => 'Každý mesiac';

  @override
  String get calendarRepeatYearly => 'Každý rok';

  @override
  String get calendarParticipants => 'Účastníci';

  @override
  String get calendarAddParticipant => 'Pridať';

  @override
  String get calendarSearchContacts => 'Hľadať kontakty...';

  @override
  String get calendarNoContacts => 'Žiadne kontakty';

  @override
  String get calendarStatusAccepted => 'Prijaté';

  @override
  String get calendarStatusDeclined => 'Odmietnuté';

  @override
  String get calendarStatusMaybe => 'Možno';

  @override
  String get calendarStatusPending => 'Čakajúce';

  @override
  String get calendarEndTime => 'Koniec';

  @override
  String get calendarYourAnswer => 'Vaša odpoveď:';

  @override
  String get calendarOrganizer => 'Organizátor';

  @override
  String calendarDeleteError(String error) {
    return 'Nepodarilo sa vymazať: $error';
  }

  @override
  String get calendarRsvpAccept => 'Prijať';

  @override
  String get calendarRsvpMaybe => 'Možno';

  @override
  String get calendarRsvpDecline => 'Odmietnuť';

  @override
  String get callHistoryTitle => 'Hovory';

  @override
  String get callHistoryTab => 'História hovorov';

  @override
  String get callHistoryTempMeeting => 'Dočasné stretnutie';

  @override
  String get callHistoryCopy => 'Kopírovať';

  @override
  String get callHistoryLinkCopied => 'Odkaz skopírovaný';

  @override
  String get callHistoryShare => 'Zdieľať';

  @override
  String get callHistoryEnter => 'Vstúpiť';

  @override
  String get callHistoryAlreadyInCall => 'Už ste v hovore';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Nepodarilo sa určiť druhú stranu';

  @override
  String get callHistoryContacts => 'Kontakty';

  @override
  String get callHistoryFailedLoadRoom =>
      'Nepodarilo sa načítať vašu miestnosť';

  @override
  String get callHistoryYourRoom => 'Vaša miestnosť';

  @override
  String get callHistoryCreateMeeting => 'Vytvoriť stretnutie';

  @override
  String get callHistoryMeetingSummaries => 'Zhrnutia stretnutí';

  @override
  String get callHistoryMeetingRecordings => 'Nahrávky stretnutí';

  @override
  String get callHistoryNoCalls => 'Žiadne hovory';

  @override
  String get callHistoryMissed => 'Zmeškané';

  @override
  String get callHistoryRecording => 'Nahrávanie';

  @override
  String get callHistorySummary => 'Zhrnutie';

  @override
  String get callHistoryCallAgain => 'Zavolať znova';

  @override
  String callHistoryTodayTime(String time) {
    return 'Dnes, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Včera, $time';
  }

  @override
  String get callHistoryUnknown => 'Neznáme';

  @override
  String get callHistoryDetails => 'Detaily hovoru';

  @override
  String get callHistoryOutgoing => 'Odchádzajúci hovor';

  @override
  String get callHistoryIncoming => 'Prichádzajúci hovor';

  @override
  String callHistoryDuration(String duration) {
    return 'Trvanie: $duration';
  }

  @override
  String get callHistoryWithAI => 'S AI asistentom';

  @override
  String get callHistoryParticipants => 'Účastníci';

  @override
  String get callDetailYouSuffix => '(Vy)';

  @override
  String get callHistoryMeetingSummary => 'Zhrnutie stretnutia';

  @override
  String get callHistoryMoreDetails => 'Viac detailov';

  @override
  String get callHistorySummaryProcessing => 'Spracovávanie zhrnutia...';

  @override
  String get callHistoryMeetingRecording => 'Nahrávka stretnutia';

  @override
  String get callHistoryProcessing => 'Spracovávanie...';

  @override
  String get callHistoryCreateTranscript => 'Vytvoriť prepis';

  @override
  String get callHistoryNoSummaries => 'Žiadne zhrnutia';

  @override
  String get callHistoryRecordDuringCall => 'Stlačte \"Nahrávať\" počas hovoru';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Stretnutie $time';
  }

  @override
  String get callHistoryTranscribing => 'Prepis a sumarizácia...';

  @override
  String get callHistoryTranscriptCreated => 'Prepis vytvorený';

  @override
  String get callHistoryNoRecordings => 'Žiadne nahrávky';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Nahrávka $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Nahrávka nie je dostupná';

  @override
  String get callHistoryTranscriptReady => 'Prepis pripravený';

  @override
  String get callHistoryTranscript => 'Prepis';

  @override
  String get callHistoryKeyPoints => 'Kľúčové body';

  @override
  String get callHistoryTasks => 'Úlohy';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Priradené: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Rozhodnutia';

  @override
  String get callHistoryShowTranscript => 'Zobraziť celý prepis';

  @override
  String get profileScanQr => 'Skenovať QR';

  @override
  String get profileMyQrCode => 'Môj QR kód';

  @override
  String profileAddMeShare(String userId) {
    return 'Pridaj ma v Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Ukáž tento kód na pridanie';

  @override
  String get profileEditDesc =>
      'Meno, priezvisko, patronymikum, dátum narodenia';

  @override
  String get profileAboutMe => 'O mne';

  @override
  String get profileAboutMeDesc => 'Hodnoty, zručnosti, záujmy a viac';

  @override
  String get profileNotes => 'Poznámky';

  @override
  String get profileNotesDesc => 'Myšlienky, nápady a poznámky';

  @override
  String get profileAvatarUpdated => 'Avatar aktualizovaný';

  @override
  String get profileNickname => 'Prezývka';

  @override
  String get profileNotSet => 'Nenastavené';

  @override
  String get profileChangeNickname => 'Zmeniť prezývku';

  @override
  String get profileNicknameUpdated => 'Prezývka aktualizovaná';

  @override
  String get profileShareLabel => 'Zdieľať';

  @override
  String get profileScanQrCode => 'Skenovať QR kód';

  @override
  String get profilePointCamera => 'Namieste kameru na QR kód';

  @override
  String get profilePhotoCamera => 'Odfotiť';

  @override
  String get profilePhotoGallery => 'Vybrať z galérie';

  @override
  String get editProfilePatronymic => 'Patronymikum (nepovinné)';

  @override
  String get editProfileDateFormat => 'DD.MM.RRRR';

  @override
  String get aboutMeTitle => 'O mne';

  @override
  String get aboutMeClickToFill => 'Kliknite na vyplnenie';

  @override
  String get aboutMeCoreValues => 'Hodnoty';

  @override
  String get aboutMeWorldview => 'Svetonázor';

  @override
  String get aboutMeSkills => 'Zručnosti';

  @override
  String get aboutMeInterests => 'Záujmy';

  @override
  String get aboutMeDesires => 'Túžby';

  @override
  String get aboutMeBackground => 'Profil';

  @override
  String get aboutMeLikes => 'Obľúbené';

  @override
  String get aboutMeDislikes => 'Neobľúbené';

  @override
  String get aboutMeDeleteSection => 'Vymazať sekciu?';

  @override
  String get aboutMeDeleteConfirm =>
      'Všetky údaje v tejto sekcii budú vymazané.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Chyba pripojenia: $error';
  }

  @override
  String get aboutMeVisibility => 'Viditeľnosť';

  @override
  String get aboutMeTags => 'Tagy';

  @override
  String get aboutMeAddTag => 'Pridať tag...';

  @override
  String get aboutMeDescription => 'Popis';

  @override
  String get aboutMeDescribeLong => 'Povedzte nám viac...';

  @override
  String get aboutMeVisibilityEveryone => 'Všetci';

  @override
  String get aboutMeVisibilityContacts => 'Kontakty';

  @override
  String get aboutMeVisibilityOnlyMe => 'Len ja';

  @override
  String get settingsProfileSubtitle => 'Profil';

  @override
  String get settingsWallpaper => 'Tapeta';

  @override
  String get settingsWallpaperDesc => 'Obrázok na pozadí pre celú aplikáciu';

  @override
  String get settingsWallpaperNone => 'Žiadna';

  @override
  String get settingsAccount => 'Účet';

  @override
  String get settingsKycVerification => 'Overenie identity (KYC)';

  @override
  String get settingsOrganizations => 'Organizácie';

  @override
  String get incomingCallLabel => 'Prichádzajúci hovor';

  @override
  String get incomingCallDecline => 'Odmietnuť';

  @override
  String get incomingCallAccept => 'Prijať';

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
  String get meshIncomingCallLabel => '📡 Prichádzajúci mesh hovor';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Mesh zariadenie $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Najprv ukončite aktuálny hovor';

  @override
  String get callPopupTransportTitle => 'Hovor cez';

  @override
  String get callPopupTransportMesh => '📡 Mesh (peer-to-peer)';

  @override
  String get callPopupTransportLk => '📞 Server';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Kontakt nie je dostupný cez mesh';

  @override
  String get meshOnboardingTitle =>
      '📡 Mesh hovory potrebujú otvorenú aplikáciu';

  @override
  String get meshOnboardingBody =>
      'Keď je telefón zamknutý, mesh hovory môžu po ~30 sekundách vypadnúť (obmedzenie iOS).';

  @override
  String get meshOnboardingAck => 'Rozumiem';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Kontakt nie je vo vašom zozname';

  @override
  String get meshCallStatusInviting => 'Volám…';

  @override
  String get meshCallStatusConnecting => 'Pripájam…';

  @override
  String get meshCallEndedUserHangup => 'Hovor ukončený';

  @override
  String get meshCallEndedRemoteHangup => 'Ukončené druhou stranou';

  @override
  String get meshCallEndedRejected => 'Odmietnuté';

  @override
  String get meshCallEndedNoAnswer => 'Bez odpovede';

  @override
  String get meshCallEndedConnectionLost => 'Spojenie stratené';

  @override
  String get meshCallEndedError => 'Chyba spojenia';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Spoľahlivé mesh hovory';

  @override
  String get batteryExemptionBody =>
      'Povoľte aplikácii bežať bez obmedzení batérie, aby Android nezabil mesh na pozadí.';

  @override
  String get batteryExemptionAccept => 'Otvoriť nastavenia';

  @override
  String get batteryExemptionDismiss => 'Teraz nie';

  @override
  String get groupCamera => 'Fotoaparát';

  @override
  String get groupGallery => 'Galéria';

  @override
  String get groupAvatarUpdated => 'Avatar skupiny bol aktualizovaný';

  @override
  String get groupNameTitle => 'Názov skupiny';

  @override
  String get groupEnterName => 'Zadajte názov';

  @override
  String get groupDescriptionTitle => 'Popis skupiny';

  @override
  String get groupEnterDescription => 'Zadajte popis skupiny';

  @override
  String get groupChangeRoleTitle => 'Zmeniť rolu';

  @override
  String get groupRemoveMemberTitle => 'Odstrániť člena';

  @override
  String get groupDescription => 'Popis';

  @override
  String get groupAddDescription => 'Pridať popis skupiny';

  @override
  String get groupNoDescription => 'Žiadny popis';

  @override
  String get groupMediaAndFiles => 'Médiá a súbory';

  @override
  String get groupMuteNotifications => 'Stlmiť upozornenia';

  @override
  String get groupMuted => 'Stlmené';

  @override
  String get groupNoResults => 'Žiadne výsledky';

  @override
  String get authInvalidCode => 'Neplatný kód. Skúste znova.';

  @override
  String get loginSubtitle => 'Použite email a heslo';

  @override
  String get emailRequired => 'Zadajte email';

  @override
  String get emailInvalid => 'Neplatný email';

  @override
  String get passwordRequired => 'Zadajte heslo';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Jeden účet pre celý ekosystém Taler';

  @override
  String get usernameOptional => 'Používateľské meno (voliteľné)';

  @override
  String get usernameMinLength => 'Minimálne 3 znaky';

  @override
  String get usernameMaxLength => 'Maximálne 30 znakov';

  @override
  String get usernameInvalid => 'Iba písmená, číslice a _';

  @override
  String get biometricLoginReason => 'Prihláste sa do Taler ID';

  @override
  String get docTypePassport => 'Pas';

  @override
  String get docTypeIdCard => 'Občiansky preukaz';

  @override
  String get docTypeDriverLicense => 'Vodičský preukaz';

  @override
  String get docTypeResidencePermit => 'Povolenie na pobyt';

  @override
  String addressApartment(String number) {
    return 'byt $number';
  }

  @override
  String get failedToUpdateProfile => 'Nepodarilo sa aktualizovať profil';

  @override
  String get failedToStartKyb => 'Nepodarilo sa spustiť overenie KYB';

  @override
  String get orgUpdated => 'Organizácia bola aktualizovaná';

  @override
  String get failedToUpdateOrg => 'Nepodarilo sa aktualizovať organizáciu';

  @override
  String get failedToChangeRole => 'Nepodarilo sa zmeniť rolu';

  @override
  String get failedToRemoveMember => 'Nepodarilo sa odstrániť člena';

  @override
  String get capabilityMessagesTitle => 'Správy';

  @override
  String get capabilityMessagesDesc =>
      'Skontrolujte správy alebo napíšte niekomu. Napríklad: \"Napíšte Viktorovi: budem tam o hodinu\"';

  @override
  String get capabilityCallsTitle => 'Hovory';

  @override
  String get capabilityCallsDesc =>
      'Zavolajte akémukoľvek kontaktu hlasom. Napríklad: \"Zavolajte Viktorovi Viktorovovi\"';

  @override
  String get capabilityChatTitle => 'História chatu';

  @override
  String get capabilityChatDesc =>
      'Analyzujem históriu chatu. Napríklad: \"O čom sme diskutovali s Viktorom?\"';

  @override
  String get capabilityProfileTitle => 'Profil';

  @override
  String get capabilityProfileDesc =>
      'Ukážem alebo aktualizujem váš profil. Napríklad: \"Ukáž môj profil\"';

  @override
  String get capabilityCoachingTitle => 'Koučing';

  @override
  String get capabilityCoachingDesc =>
      'Módy: ICF koučing, psychológ, HR konzultácia. Povedzte: \"Poďme na koučing\"';

  @override
  String get capabilityCalendarTitle => 'Kalendár';

  @override
  String get capabilityCalendarDesc =>
      'Naplánujte stretnutie alebo nastavte pripomienku. Napríklad: \"Naplánuj stretnutie s Viktorom na zajtra o 15:00\"';

  @override
  String get capabilityNotesTitle => 'Poznámky';

  @override
  String get capabilityNotesDesc =>
      'Uložte myšlienku alebo prečítajte si nedávne poznámky. Napríklad: \"Zapíš myšlienku...\" alebo \"Prečítaj nedávne poznámky\"';

  @override
  String get assistantCallConfirm => 'Zavolať?';

  @override
  String get callNoAnswer => 'Žiadna odpoveď';

  @override
  String get contactDelete => 'Odstrániť kontakt';

  @override
  String get contactDeleteTitle => 'Odstrániť kontakt';

  @override
  String get contactDeleteConfirm =>
      'Ste si istý? Tento kontakt bude odstránený.';

  @override
  String get contactBlock => 'Blokovať';

  @override
  String get contactBlockTitle => 'Blokovať používateľa';

  @override
  String get contactBlockConfirm =>
      'Tento používateľ vám nebude môcť posielať správy ani volať.';

  @override
  String get contactUnblock => 'Odblokovať';

  @override
  String get contactBlocked => 'Blokovaný';

  @override
  String get contactYouAreBlocked => 'Tento používateľ vás zablokoval';

  @override
  String get chatBlockedByYou => 'Zablokovali ste tohto používateľa';

  @override
  String get chatYouAreBlocked =>
      'Bol(a) ste zablokovaný(á) týmto používateľom';

  @override
  String get chatNotContacts =>
      'Pridajte tohto používateľa do kontaktov, aby ste mu mohli poslať správu';

  @override
  String get contactRevokeRequest => 'Odvolať žiadosť';

  @override
  String get messengerPoll => 'Anketa';

  @override
  String get messengerCreatePoll => 'Vytvoriť anketu';

  @override
  String get messengerPollQuestion => 'Otázka';

  @override
  String messengerPollOption(int number) {
    return 'Možnosť $number';
  }

  @override
  String get messengerPollAddOption => 'Pridať možnosť';

  @override
  String get messengerPollAnonymous => 'Anonymné hlasovanie';

  @override
  String get messengerPollMultiple => 'Viacnásobný výber';

  @override
  String get messengerPollCreateError => 'Nepodarilo sa vytvoriť anketu';

  @override
  String get messengerPollUnavailable => 'Anketa nedostupná';

  @override
  String get messengerPollMultipleNote => 'Môžete vybrať viacero možností';

  @override
  String messengerPollVotes(int count) {
    return '$count hlasov';
  }

  @override
  String get messengerVideoMessage => 'Video správa';

  @override
  String get messengerVideoRecordError => 'Chyba nahrávania videa';

  @override
  String get messengerVideoPlaybackError => 'Nepodarilo sa prehrať video';

  @override
  String get messengerGalleryAccessError => 'Žiadny prístup do galérie';

  @override
  String get messengerSearchInChat => 'Hľadať v chate...';

  @override
  String get messengerSaveToFavorites => 'Uložiť do obľúbených';

  @override
  String get messengerSavedToFavorites => 'Uložené do obľúbených';

  @override
  String get messengerSearchInMessages => 'Hľadať v správach...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Nájdené v správach ($count)';
  }

  @override
  String get messengerGroupDefault => 'Skupina';

  @override
  String get messengerUserDefault => 'Používateľ';

  @override
  String get messengerPin => 'Pripnúť';

  @override
  String get messengerUnpin => 'Odopnúť';

  @override
  String get messengerArchive => 'Archivovať';

  @override
  String get messengerUnarchive => 'Obnoviť z archívu';

  @override
  String get messengerDeleteChat => 'Vymazať chat';

  @override
  String get messengerDeleteChatTitle => 'Vymazať chat?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Vymazať chat s $name? Toto nie je možné vrátiť späť.';
  }

  @override
  String get messengerCreateChannel => 'Vytvoriť kanál';

  @override
  String get messengerChannelName => 'Názov';

  @override
  String get messengerChannelDescription => 'Popis (nepovinné)';

  @override
  String get messengerChannelCreateError => 'Nepodarilo sa vytvoriť kanál';

  @override
  String get messengerFilterAll => 'Všetko';

  @override
  String get messengerFilterUnread => 'Nečítané';

  @override
  String get messengerFilterPersonal => 'Osobné';

  @override
  String get messengerFilterGroups => 'Skupiny';

  @override
  String get messengerFilterChannels => 'Kanály';

  @override
  String get messengerArchivedSection => 'Archivované';

  @override
  String get messengerSavedSection => 'Obľúbené';

  @override
  String get messengerSavedSubtitle => 'Uložiť do pamäte';

  @override
  String messengerArchiveTitle(int count) {
    return 'Archív ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Archív je prázdny';

  @override
  String messengerYouPrefix(String message) {
    return 'Vy: $message';
  }

  @override
  String get messengerMissedCall => 'Zmeškaný hovor';

  @override
  String get messengerSavedTitle => 'Obľúbené';

  @override
  String get messengerNoSavedMessages => 'Žiadne uložené správy';

  @override
  String get messengerSavedHint =>
      'Dlhé stlačenie správy → \"Uložiť do obľúbených\"';

  @override
  String get messengerDefaultFile => 'Súbor';

  @override
  String get messengerTopicDefault => 'Všeobecné';

  @override
  String get messengerTopicNew => 'Nová téma';

  @override
  String get messengerTopicNameHint => 'Názov témy';

  @override
  String get messengerTopicIcon => 'Ikona';

  @override
  String messengerTopicCount(int count) {
    return '$count témy';
  }

  @override
  String get messengerNoTopics => 'Žiadne témy';

  @override
  String get messengerNoMessages => 'Žiadne správy';

  @override
  String get you => 'Vy';

  @override
  String get messengerThread => 'Vlákno';

  @override
  String get messengerThreadReply => 'odpoveď';

  @override
  String get messengerThreadReplies => 'odpovede';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Žiadne odpovede';

  @override
  String get messengerReplyHint => 'Odpovedať na vlákno...';

  @override
  String get messengerContactName => 'Meno kontaktu';

  @override
  String messengerOriginalName(String name) {
    return 'Pôvodné meno: $name';
  }

  @override
  String get messengerDisplayName => 'Zobrazené meno';

  @override
  String messengerShareContact(String name) {
    return 'Kontakt v Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Automatické mazanie správ';

  @override
  String get messengerAutoDeleteOff => 'Vypnuté';

  @override
  String get messengerAutoDelete7d => '7 dní';

  @override
  String get messengerAutoDelete30d => '30 dní';

  @override
  String get messengerAutoDelete90d => '90 dní';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count dní';
  }

  @override
  String get messengerSettingsHeader => 'Nastavenia';

  @override
  String get messengerAdminOnly => 'Iba pre adminov';

  @override
  String get messengerAdminOnlyDesc => 'Členovia môžu len čítať';

  @override
  String get messengerTopics => 'Témy';

  @override
  String get messengerTopicsDesc => 'Rozdeliť chat na témy';

  @override
  String get aiTwinSection => 'AI Hlasový Dvojník';

  @override
  String get aiTwinEnabled => 'Povoliť AI Dvojníka';

  @override
  String get aiTwinEnabledDesc =>
      'Ak neodpoviete, váš AI dvojník prijme hovor vaším hlasom';

  @override
  String get aiTwinTimeout => 'Časový limit odpovede';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds sek';
  }

  @override
  String get aiTwinPrompt => 'AI pokyny';

  @override
  String get aiTwinPromptSubtitle =>
      'Ako by sa mal AI dvojník predstaviť a o čom hovoriť';

  @override
  String aiTwinPromptHint(String name) {
    return 'Ahoj, tu je AI hlasový dvojník $name. $name momentálne nemôže prijať hovor. Povedzte mi, kto volá a o čo ide — odovzdám to.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Prispôsobené klonovanie hlasu čoskoro. Zatiaľ AI hovorí hlasom $name.';
  }

  @override
  String get aiTwinDefaultName => 'majiteľ';

  @override
  String get aiTwinPromptReset => 'Resetovať';

  @override
  String get callHistoryAiTwinAnswered => 'ODPOVEDAL AI DVOJNÍK';

  @override
  String get callHistoryAiTwinSummary => 'ZHRNUTIE HOVORU';

  @override
  String get callHistoryAiTwinTranscript => 'PREPIS';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'Od $name';
  }

  @override
  String get aiTwinOfferTitle => 'Neodpovedá';

  @override
  String aiTwinOfferBody(String name) {
    return '$name neodpovedá. Nechajte správu s ich AI hlasovým dvojníkom?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Používateľ';

  @override
  String get aiTwinOfferAccept => 'Áno, nechať správu';

  @override
  String get aiTwinOfferKeepWaiting => 'Pokračovať v čakaní';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Váš AI náhradník';

  @override
  String get aiTwinHeroSubtitle =>
      'Odpovedá na hovory vaším hlasom, keď nemôžete.';

  @override
  String get aiTwinProfileTitle => 'AI Náhradník';

  @override
  String get aiTwinProfileDesc => 'Odpovedá na hovory vaším hlasom';

  @override
  String get aiTwinBadgeOn => 'ZAP';

  @override
  String get aiAnalystTitle => 'AI Analytik';

  @override
  String get aiAnalystSubtitle => 'Súbory, úlohy, analýza — Claude';

  @override
  String get channelsDiscover => 'Nájsť kanál';

  @override
  String get channelsSearchHint => 'Hľadať kanály';

  @override
  String get channelsSubscribers => 'odberatelia';

  @override
  String get channelsSubscribe => 'Odoberať';

  @override
  String get channelsUnsubscribe => 'Zrušiť odber';

  @override
  String get channelsSubscribedLabel => 'Ste prihlásený na odber';

  @override
  String get channelsSettings => 'Nastavenia kanála';

  @override
  String get channelsDelete => 'Vymazať kanál';

  @override
  String get channelsDeleteConfirm => 'Vymazať kanál natrvalo?';

  @override
  String get channelsEmpty => 'Zatiaľ žiadne kanály';

  @override
  String get channelsOpen => 'Otvoriť';

  @override
  String get channelsNameLabel => 'Názov';

  @override
  String get channelsDescriptionLabel => 'Popis';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Vlastník nemôže zrušiť odber. Namiesto toho vymažte kanál.';

  @override
  String get channelsNotFoundRedirect => 'Kanál už neexistuje';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vyhľadávania',
      one: '$count vyhľadávanie',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count súbory',
      one: '$count súbor',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count príkazy',
      one: '$count príkaz',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obrázky',
      one: '$count obrázok',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kroky',
      one: '$count krok',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Uložené správy';

  @override
  String get savedSubtitle => 'Váš súkromný cloud';

  @override
  String get savedOpenError => 'Nepodarilo sa otvoriť Uložené správy';

  @override
  String get billingWalletTitle => 'Peňaženka';

  @override
  String get billingBuyPackage => 'Kúpiť balík';

  @override
  String get billingCurrentBalance => 'Aktuálny zostatok';

  @override
  String get billingPackagesTitle => 'Balíky';

  @override
  String get billingPackagesUnavailable => 'Balíky nie sú dostupné';

  @override
  String get billingRecentOperations => 'Nedávne operácie';

  @override
  String get billingAllOperations => 'Všetky operácie';

  @override
  String get billingNoOperations => 'Žiadne operácie';

  @override
  String get billingOperationsTitle => 'Operácie';

  @override
  String get billingOperationsEmptyTitle => 'Zatiaľ žiadne operácie';

  @override
  String get billingOperationsEmptySubtitle =>
      'Dobíjania a poplatky za AI funkcie sa zobrazia tu';

  @override
  String get billingPricebookTitle => 'Ceny funkcií';

  @override
  String get billingPricebookUnavailable => 'Cenník nie je dostupný';

  @override
  String get billingAiFeaturesTitle => 'AI funkcie';

  @override
  String get billingInsufficientFundsTitle => 'Nedostatok prostriedkov';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Dobite si zostatok, aby ste mohli použiť túto funkciu.';

  @override
  String billingRequiredLine(String required) {
    return 'Potreba: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'K dispozícii: $available μTAL';
  }

  @override
  String get billingTopUp => 'Dobitie';

  @override
  String get billingCancel => 'Zrušiť';

  @override
  String get billingRetry => 'Skúsiť znova';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Nízky zostatok: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Peňaženka & Zostatok';

  @override
  String get billingSectionHeader => 'Fakturácia & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Hlasový asistent';

  @override
  String get billingFeatureWebSearch => 'Asistent vyhľadávania na webe';

  @override
  String get billingFeatureAiTwin => 'Hlasový dvojník';

  @override
  String get billingFeatureAiTwinLong => 'Hlasový dvojník (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Odchádzajúci bot';

  @override
  String get billingFeatureOutboundCallLong => 'Odchádzajúci volací bot';

  @override
  String get billingFeatureWhisperTranscribe => 'Prepis hovoru';

  @override
  String get billingFeatureMeetingSummary => 'AI zhrnutia hovorov';

  @override
  String get billingConfigureAiTwin => 'Nastaviť AI dvojníka';

  @override
  String get billingWebSearchSubtitle => '(používa asistent)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Zakúpený balík: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Odporúčané';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Zostatok vyčerpaný — relácia ukončená';

  @override
  String get billingSessionTerminatedGeneric => 'Relácia asistenta ukončená';

  @override
  String billingBuyForPrice(String price) {
    return 'Kúpiť za $price €';
  }

  @override
  String get billingTxTypeTopup => 'Dobitie';

  @override
  String get billingTxTypeRefund => 'Vrátenie peňazí';

  @override
  String get billingTxTypeSpend => 'Poplatok';

  @override
  String get billingUnitMinute => 'minúta';

  @override
  String get billingUnitRequest => 'požiadavka';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K tokenov';

  @override
  String get billingUnitCall => 'hovor';

  @override
  String get groupCallSelectParticipants => 'Vyberte účastníkov';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Hľadať';

  @override
  String get groupCallMaxReached => 'Maximálne 7 účastníkov';

  @override
  String get groupCallLobbyTitle => 'Skupina • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Hostiteľ: $name';
  }

  @override
  String get groupCallMicHint => 'Mikrofón sa aktivuje po pripojení';

  @override
  String get groupCallCancel => 'Zrušiť';

  @override
  String get groupCallNoAnswer => 'Nikto neodpovedal';

  @override
  String get groupCallEndedByHost => 'Hovor ukončený hostiteľom';

  @override
  String get groupCallAllLeft => 'Všetci opustili hovor';

  @override
  String get groupCallEnded => 'Hovor ukončený';

  @override
  String groupCallActiveTitle(int count) {
    return 'Skupina • $count';
  }

  @override
  String get groupCallConnectionLost => 'Spojenie stratené';

  @override
  String get groupCallMuteRequested => 'Hostiteľ požiadal všetkých o stlmenie';

  @override
  String get groupCallUnmute => 'Zrušiť stlmenie';

  @override
  String get groupCallMute => 'Stlmiť';

  @override
  String get groupCallMuteAll => 'Stlmiť všetkých';

  @override
  String get groupCallLeave => 'Opustiť';

  @override
  String get groupCallStatusCalling => 'volanie…';

  @override
  String get groupCallStatusDeclined => 'odmietnuté';

  @override
  String get groupCallStatusTimeout => 'bez odpovede';

  @override
  String get groupCallStatusLeft => 'opustil';

  @override
  String groupCallKickConfirm(String name) {
    return 'Odstrániť $name z hovoru';
  }

  @override
  String get groupCallCancelAction => 'Zrušiť';

  @override
  String get groupCallActiveBanner => 'Aktívny hovor';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Skupina: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Skupina: $host';
  }

  @override
  String get groupCallCreateError => 'Nepodarilo sa vytvoriť hovor';

  @override
  String get groupCallJoinError => 'Nepodarilo sa pripojiť k hovoru';

  @override
  String get groupCallLivekitError => 'Chyba LiveKit';

  @override
  String get groupCallDone => 'Hotovo';

  @override
  String get groupCallNoResults => 'Žiadne výsledky';

  @override
  String get groupCallNoContacts => 'Žiadne kontakty';

  @override
  String get meshGcContactOffline => 'Nie je na tejto Wi-Fi';

  @override
  String get meshGcOnlineViaMesh => 'Online cez mesh';

  @override
  String get meshGcMaxInvitees =>
      'Skupinové hovory podporujú až 4 pozvaných (celkovo 5 osôb).';

  @override
  String get meshGcStart => 'Začať skupinový hovor';

  @override
  String get meshGcCancel => 'Zrušiť';

  @override
  String get meshGcStatusCalling => 'Volanie…';

  @override
  String get meshGcStatusJoined => 'Pripojený';

  @override
  String get meshGcStatusDeclined => 'Odmietnuté';

  @override
  String get meshGcStatusNoAnswer => 'Žiadna odpoveď';

  @override
  String get meshGcStatusConnectionFailed => 'Pripojenie zlyhalo';

  @override
  String get meshGcStatusLeft => 'Opustil';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Najprv dokončite aktuálny hovor.';

  @override
  String get presenceOnline => 'online';

  @override
  String get presenceLastSeenJustNow => 'naposledy videný práve teraz';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'naposledy videný pred $minutes min';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'naposledy videný dnes o $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'naposledy videný včera o $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'naposledy videný $date';
  }

  @override
  String get presenceLastSeenRecently => 'naposledy videný nedávno';

  @override
  String get privacySectionTitle => 'Súkromie';

  @override
  String get privacyLastSeenLabel => 'Kto vidí váš čas posledného videnia';

  @override
  String get privacyEveryone => 'Každý';

  @override
  String get privacyContacts => 'Iba kontakty';

  @override
  String get privacyNobody => 'Nikto';

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
}
