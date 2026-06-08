// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Suche';

  @override
  String get appSubtitle => 'Vereinheitlichte Ökosystem-Identität';

  @override
  String get login => 'Anmelden';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get register => 'Konto erstellen';

  @override
  String get registerButton => 'Konto erstellen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get firstName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get noAccount => 'Noch kein Konto?';

  @override
  String get createOne => 'Erstellen';

  @override
  String get haveAccount => 'Bereits ein Konto?';

  @override
  String get signIn => 'Anmelden';

  @override
  String get passwordMinLength => 'Mindestens 8 Zeichen';

  @override
  String get invalidEmail => 'Gültige E-Mail eingeben';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get twoFATitle => 'Zwei-Faktor-Authentifizierung';

  @override
  String get twoFASubtitle =>
      'Geben Sie den 6-stelligen Code aus Ihrer Authentifizierungs-App ein';

  @override
  String get twoFACode => '2FA-Code';

  @override
  String get verify => 'Verifizieren';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organisation';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get phone => 'Telefon';

  @override
  String get country => 'Land';

  @override
  String get dateOfBirth => 'Geburtsdatum';

  @override
  String get documents => 'Dokumente';

  @override
  String get addDocument => 'Dokument hinzufügen';

  @override
  String get noDocuments => 'Keine Dokumente hochgeladen';

  @override
  String get save => 'Speichern';

  @override
  String get profileUpdated => 'Profil aktualisiert';

  @override
  String get personalData => 'Persönliche Daten';

  @override
  String get passport => 'Reisepass';

  @override
  String get drivingLicense => 'Führerschein';

  @override
  String get diploma => 'Diplom';

  @override
  String get nationalId => 'Personalausweis';

  @override
  String get certificate => 'Zertifikat';

  @override
  String get notSpecified => 'Nicht angegeben';

  @override
  String get notSpecifiedFemale => 'Nicht angegeben';

  @override
  String get documentType => 'Dokumenttyp';

  @override
  String get passportId => 'Reisepass / Ausweis';

  @override
  String get diplomaCertificate => 'Diplom / Zertifikat';

  @override
  String get loadError => 'Ladefehler';

  @override
  String get verification => 'Verifizierung';

  @override
  String get countryAustria => 'Österreich';

  @override
  String get countryGermany => 'Deutschland';

  @override
  String get countryRussia => 'Russland';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryKazakhstan => 'Kasachstan';

  @override
  String get countryBelarus => 'Weißrussland';

  @override
  String get countryOther => 'Andere';

  @override
  String get kycTitle => 'KYC-Verifizierung';

  @override
  String get kycVerified => 'Verifiziert';

  @override
  String get kycPending => 'Ausstehend';

  @override
  String get kycRejected => 'Abgelehnt';

  @override
  String get kycUnverified => 'Unverifiziert';

  @override
  String get kycVerifiedDesc =>
      'Ihre Identität wurde verifiziert. Sie haben vollen Zugriff auf alle Funktionen des Taler-Ökosystems.';

  @override
  String get kycPendingDesc =>
      'Ihre Dokumente werden überprüft. Dies dauert normalerweise 1-2 Werktage.';

  @override
  String get kycRejectedDesc =>
      'Verifizierung fehlgeschlagen. Bitte überprüfen Sie den Grund und reichen Sie Ihre Dokumente erneut ein.';

  @override
  String get kycUnverifiedDesc =>
      'Schließen Sie die Verifizierung ab, um vollen Zugriff auf die Finanzfunktionen des Taler-Ökosystems zu erhalten.';

  @override
  String get startVerification => 'Verifizierung starten';

  @override
  String get retryVerification => 'Verifizierung erneut versuchen';

  @override
  String verifiedAt(String date) {
    return 'Verifiziert: $date';
  }

  @override
  String get documentsSubmitted => 'Dokumente zur Überprüfung eingereicht';

  @override
  String get documentsSubmittedDesc =>
      'Die Überprüfung dauert normalerweise 1-2 Werktage. Sie erhalten eine Push-Benachrichtigung mit dem Ergebnis.';

  @override
  String get securityAes =>
      'Ihre Daten sind mit AES-256-Verschlüsselung geschützt';

  @override
  String get verificationTime => 'Die Verifizierung dauert 1-2 Werktage';

  @override
  String get pushNotification =>
      'Sie erhalten eine Push-Benachrichtigung mit dem Ergebnis';

  @override
  String get kycWebOnly =>
      'KYC-Verifizierung ist nur in der mobilen App verfügbar.';

  @override
  String verificationError(String code) {
    return 'Verifizierungsfehler: $code';
  }

  @override
  String get organizations => 'Organisationen';

  @override
  String get noOrganizations => 'Keine Organisationen';

  @override
  String get noOrganizationsDesc =>
      'Erstellen Sie eine Organisation oder nehmen Sie eine Einladung an';

  @override
  String get createOrganization => 'Organisation erstellen';

  @override
  String get newOrganization => 'Neue Organisation';

  @override
  String get orgName => 'Name *';

  @override
  String get orgDescription => 'Beschreibung';

  @override
  String get orgEmail => 'Kontakt E-Mail';

  @override
  String get orgWebsite => 'Webseite';

  @override
  String get orgLegalAddress => 'Rechtliche Adresse';

  @override
  String get create => 'Erstellen';

  @override
  String get organization => 'Organisation';

  @override
  String get contacts => 'Kontakte';

  @override
  String members(int count) {
    return 'Mitglieder ($count)';
  }

  @override
  String get inviteMember => 'Mitglied einladen';

  @override
  String get invite => 'Einladen';

  @override
  String get sendInvite => 'Einladung senden';

  @override
  String inviteSent(String email) {
    return 'Einladung gesendet an $email';
  }

  @override
  String get role => 'Rolle';

  @override
  String get roleOwner => 'Eigentümer';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleViewer => 'Betrachter';

  @override
  String get editOrganization => 'Bearbeiten';

  @override
  String get editOrganizationTitle => 'Organisation bearbeiten';

  @override
  String get removeMember => 'Mitglied entfernen';

  @override
  String removeMemberConfirm(String name) {
    return '$name aus der Organisation entfernen?';
  }

  @override
  String get memberRemoved => 'Mitglied entfernt';

  @override
  String get roleChanged => 'Rolle geändert';

  @override
  String get kybVerified => 'Verifiziert';

  @override
  String get kybPending => 'Ausstehend';

  @override
  String get kybRejected => 'Abgelehnt';

  @override
  String get kybNone => 'Unverifiziert';

  @override
  String get kybVerification => 'KYB-Verifizierung starten';

  @override
  String get kybStartBusiness => 'Geschäftsverifizierung starten';

  @override
  String get kybStatusLabel => 'KYB-Status';

  @override
  String get noKyb => 'Kein KYB';

  @override
  String get kybBusinessVerificationTitle => 'Geschäftsverifizierung (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organisation erfolgreich verifiziert.';

  @override
  String get kybPendingOrgDesc =>
      'Dokumente werden überprüft. Dies dauert in der Regel 1-3 Werktage.';

  @override
  String get kybRejectedOrgDesc =>
      'Verifizierung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get kybNoneOrgDesc =>
      'Verifizieren Sie Ihre Organisation, um auf Geschäftsmerkmale zuzugreifen.';

  @override
  String get invitePlus => '+ Einladen';

  @override
  String get kybVerificationTitle => 'KYB-Verifizierung';

  @override
  String get kybWebOnlyBusiness =>
      'KYB-Verifizierung ist nur in der mobilen App verfügbar.';

  @override
  String get unknownDevice => 'Unbekanntes Gerät';

  @override
  String get ipUnknown => 'IP unbekannt';

  @override
  String get currentSessionLabel => 'Aktuell';

  @override
  String get endSessionAction => 'Beenden';

  @override
  String get deviceLoggedOut => 'Gerät wird abgemeldet.';

  @override
  String get acceptInvitationTitle => 'Organisationseinladung';

  @override
  String get acceptInvitation => 'Einladung annehmen';

  @override
  String get acceptInvitationDesc =>
      'Sie wurden eingeladen, einer Organisation im Taler-Ökosystem beizutreten.';

  @override
  String get accept => 'Annehmen';

  @override
  String get reject => 'Ablehnen';

  @override
  String get sessions => 'Aktive Sitzungen';

  @override
  String get currentSession => 'Aktuelle Sitzung';

  @override
  String get deleteSession => 'Sitzung beenden';

  @override
  String get deleteSessionConfirm => 'Diese Sitzung beenden?';

  @override
  String get sessionDeleted => 'Sitzung beendet';

  @override
  String get noSessions => 'Keine aktiven Sitzungen';

  @override
  String minutesAgo(int count) {
    return 'Vor $count Min.';
  }

  @override
  String hoursAgo(int count) {
    return 'Vor $count Std.';
  }

  @override
  String daysAgo(int count) {
    return 'Vor $count Tagen';
  }

  @override
  String get justNow => 'Gerade eben';

  @override
  String get settings => 'Einstellungen';

  @override
  String get security => 'Sicherheit';

  @override
  String get biometrics => 'Biometrie';

  @override
  String get biometricsDesc =>
      'Schnelles Anmelden mit Face ID oder Fingerabdruck';

  @override
  String get biometricsConfirm =>
      'Bestätigen Sie die Biometrie, um schnelles Anmelden zu aktivieren';

  @override
  String get biometricsError =>
      'Aktivierung der Biometrie fehlgeschlagen. Überprüfen Sie die Geräteeinstellungen.';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get twoFactorAuth => 'Zwei-Faktor-Authentifizierung';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get passwordChanged => 'Passwort geändert';

  @override
  String get wrongCurrentPassword => 'Falsches aktuelles Passwort';

  @override
  String get passwordTooWeak =>
      'Passwort zu schwach: mindestens 8 Zeichen, Buchstabe und Ziffer erforderlich';

  @override
  String get passwordChangeFailed => 'Passwortänderung fehlgeschlagen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get permissionNotifications => 'Push-Benachrichtigungen';

  @override
  String get permissionNotificationsDesc => 'Anrufe, Nachrichten, Status';

  @override
  String get permissionMicrophone => 'Mikrofon';

  @override
  String get permissionMicrophoneDesc => 'Anrufe und Sprachassistent';

  @override
  String get permissionCamera => 'Kamera';

  @override
  String get permissionCameraDesc => 'Videoanrufe und Verifizierung';

  @override
  String get permissionLocation => 'Standort';

  @override
  String get permissionLocationDesc => 'Wird zur Verifizierung verwendet';

  @override
  String get permissionOpenSettings =>
      'Um eine Berechtigung zu widerrufen, öffnen Sie die Systemeinstellungen';

  @override
  String get pushKycStatus => 'KYC-Status Push';

  @override
  String get pushKycStatusDesc => 'Verifizierungsergebnis';

  @override
  String get pushLogins => 'Login-Push';

  @override
  String get pushLoginsDesc => 'Beim Anmelden von einem neuen Gerät';

  @override
  String get account => 'Konto';

  @override
  String get language => 'Sprache';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Oberflächensprache';

  @override
  String get exportData => 'Daten exportieren (DSGVO)';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountConfirm => 'Konto löschen?';

  @override
  String get deleteAccountDesc =>
      'Alle Ihre Daten werden gelöscht (DSGVO). Diese Aktion ist unwiderruflich.';

  @override
  String get logout => 'Abmelden';

  @override
  String get logoutConfirm => 'Abmelden?';

  @override
  String get logoutDesc =>
      'Sie werden von Taler ID auf diesem Gerät abgemeldet.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN-Code';

  @override
  String get pinCodeDesc => 'Schnelles Anmelden mit 4-stelligem Code';

  @override
  String get setupPin => 'PIN einrichten';

  @override
  String get enterPin => 'PIN eingeben';

  @override
  String get confirmPin => 'PIN bestätigen';

  @override
  String get pinMismatch => 'PINs stimmen nicht überein';

  @override
  String get passwordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get pinSet => 'PIN erfolgreich gesetzt';

  @override
  String get enterPinToLogin => 'PIN eingeben, um sich anzumelden';

  @override
  String get pinIncorrect => 'Falsche PIN';

  @override
  String get removePin => 'PIN entfernen';

  @override
  String get pinRemoved => 'PIN entfernt';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get error => 'Fehler';

  @override
  String get success => 'Erfolg';

  @override
  String get noData => 'Keine Daten';

  @override
  String get failedToLoad => 'Daten konnten nicht geladen werden';

  @override
  String get failedToLoadProfile => 'Profil konnte nicht geladen werden';

  @override
  String get failedToSave => 'Änderungen konnten nicht gespeichert werden';

  @override
  String get failedToLoadOrgs => 'Organisationen konnten nicht geladen werden';

  @override
  String get failedToLoadOrg =>
      'Organisationsdaten konnten nicht geladen werden';

  @override
  String get failedToCreateOrg => 'Organisation konnte nicht erstellt werden';

  @override
  String get failedToInvite => 'Einladung konnte nicht gesendet werden';

  @override
  String get failedToAcceptInvite => 'Einladung konnte nicht angenommen werden';

  @override
  String get failedToLoadSessions => 'Sitzungen konnten nicht geladen werden';

  @override
  String get failedToDeleteSession => 'Sitzung konnte nicht beendet werden';

  @override
  String get failedToLoadKyc =>
      'Verifizierungsstatus konnte nicht geladen werden';

  @override
  String get failedToStartKyc => 'Verifizierung konnte nicht gestartet werden';

  @override
  String get verifiedPersonalInfo => 'Verifizierte Daten';

  @override
  String get middleName => 'Zweiter Vorname';

  @override
  String get placeOfBirth => 'Geburtsort';

  @override
  String get nationality => 'Nationalität';

  @override
  String get gender => 'Geschlecht';

  @override
  String get genderMale => 'Männlich';

  @override
  String get genderFemale => 'Weiblich';

  @override
  String get docNumber => 'Nummer';

  @override
  String get docIssuedDate => 'Ausgestellt';

  @override
  String get docValidUntil => 'Gültig bis';

  @override
  String get docIssuedBy => 'Ausgestellt von';

  @override
  String get address => 'Adresse';

  @override
  String get refreshData => 'Daten aktualisieren';

  @override
  String get failedToLoadSumsubData =>
      'Verifizierungsdaten konnten nicht geladen werden';

  @override
  String get sumsubDataLoading => 'Verifizierungsdaten werden geladen...';

  @override
  String get reviewResultGreen => 'Verifizierung bestanden';

  @override
  String get reviewResultRed => 'Verifizierung fehlgeschlagen';

  @override
  String get tabAssistant => 'Assistent';

  @override
  String get assistantConnecting => 'Verbinden…';

  @override
  String get assistantSpeaking => 'Sprechen…';

  @override
  String get assistantListening => 'Zuhören…';

  @override
  String get assistantTapToStart => 'Zum Starten tippen';

  @override
  String get assistantTapToTalk => 'Tippen, um mit AI zu sprechen';

  @override
  String get assistantRealtimeDesc =>
      'Assistent antwortet in Echtzeit mit Stimme';

  @override
  String get assistantConnectingToAssistant =>
      'Verbindung zum Assistenten wird hergestellt...';

  @override
  String get assistantAiSpeaking => 'KI spricht...';

  @override
  String get assistantAiListening => 'KI hört zu';

  @override
  String get assistantSpeakerOn => 'Lautsprecher an';

  @override
  String get assistantSpeaker => 'Lautsprecher';

  @override
  String get assistantEnd => 'Beenden';

  @override
  String get assistantUnmute => 'Stummschaltung aufheben';

  @override
  String get assistantMicrophone => 'Mikrofon';

  @override
  String get assistantConnectionError => 'Verbindungsfehler';

  @override
  String get tabMessenger => 'Nachrichten';

  @override
  String get tabCalls => 'Anrufe';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get appearanceSelect => 'Thema wählen';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get onboardingTitle1 => 'Einheitliche Identität';

  @override
  String get onboardingDesc1 =>
      'Taler ID ist Ihr digitaler Pass im Taler-Ökosystem. Ein Konto für alle Dienste.';

  @override
  String get onboardingTitle2 => 'Datensicherheit';

  @override
  String get onboardingDesc2 =>
      'KYC-Verifizierung, AES-256-Verschlüsselung und Zwei-Faktor-Authentifizierung schützen Ihre Identität.';

  @override
  String get onboardingTitle3 => 'Bleiben Sie informiert';

  @override
  String get onboardingDesc3 =>
      'Erhalten Sie Benachrichtigungen über den Verifizierungsstatus, Anmeldungen von neuen Geräten und eingehende Anrufe.';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingEnableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get onboardingTitle4 => 'Sprachanrufe';

  @override
  String get onboardingDesc4 =>
      'Erlauben Sie den Mikrofonzugriff für Sprachanrufe und den KI-Assistenten. Sie können dies später in den Einstellungen ändern.';

  @override
  String get onboardingEnableMicrophone => 'Mikrofon aktivieren';

  @override
  String get onboardingStart => 'Loslegen';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get meshLocalNetworkPromptTitle =>
      'Zugriff auf lokales Netzwerk erlauben';

  @override
  String get meshLocalNetworkPromptBody =>
      'Um Peers im WLAN zu finden (Offline-Gruppenanrufe), benötigt iOS die Berechtigung für das lokale Netzwerk. Öffnen Sie Einstellungen → Datenschutz & Sicherheit → Lokales Netzwerk → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Einstellungen öffnen';

  @override
  String get meshLocalNetworkPromptDismiss => 'Verstanden';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get forgotPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get forgotPasswordSubtitle =>
      'Geben Sie Ihre E-Mail ein, um einen Rücksetzcode zu erhalten';

  @override
  String resetCodeSent(String email) {
    return 'Code gesendet an $email';
  }

  @override
  String get enterResetCode => 'Code eingeben';

  @override
  String get resetPasswordButton => 'Passwort zurücksetzen';

  @override
  String get passwordResetSuccess => 'Passwort erfolgreich zurückgesetzt';

  @override
  String get sendCode => 'Code senden';

  @override
  String get resendCode => 'Code erneut senden';

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
  String get newGroup => 'Neue Gruppe';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get createGroup => 'Gruppe erstellen';

  @override
  String get groupInfo => 'Gruppeninfo';

  @override
  String groupMembers(int count) {
    return 'Mitglieder ($count)';
  }

  @override
  String get addMembers => 'Mitglieder hinzufügen';

  @override
  String get leaveGroup => 'Gruppe verlassen';

  @override
  String get leaveGroupConfirm => 'Diese Gruppe verlassen?';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String get deleteGroupConfirm =>
      'Diese Gruppe löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get groupRoleOwner => 'Besitzer';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Mitglied';

  @override
  String get selectParticipants => 'Teilnehmer auswählen';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get changeRole => 'Rolle ändern';

  @override
  String get groupCreated => 'Gruppe erstellt';

  @override
  String memberJoined(String name) {
    return '$name ist beigetreten';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name hat die Gruppe verlassen';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name wurde entfernt';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name ist jetzt $role';
  }

  @override
  String participantsCount(int count) {
    return '$count Teilnehmer';
  }

  @override
  String get enterGroupName => 'Gruppennamen eingeben';

  @override
  String get muteNotifications => 'Benachrichtigungen stummschalten';

  @override
  String get unmuteNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get muteFor1Hour => 'Für 1 Stunde';

  @override
  String get muteFor8Hours => 'Für 8 Stunden';

  @override
  String get muteFor2Days => 'Für 2 Tage';

  @override
  String get muteForever => 'Für immer';

  @override
  String get muted => 'Stummgeschaltet';

  @override
  String get tabTranslator => 'Übersetzen';

  @override
  String get translatorTitle => 'Übersetzer';

  @override
  String get translatorSelectLanguage => 'Sprache auswählen';

  @override
  String get translatorDownloading => 'Sprachmodelle werden heruntergeladen...';

  @override
  String get translatorDownloadingHint =>
      'Internet wird nur für den ersten Download benötigt';

  @override
  String get translatorTypeHint => 'Text eingeben oder Mikrofon antippen';

  @override
  String get translatorListening => 'Zuhören...';

  @override
  String get translatorTapToSpeak => 'Tippen, um zu sprechen';

  @override
  String get translatorTapToStop => 'Tippen, um zu stoppen';

  @override
  String get translatorAutoSpeak => 'Automatisch sprechen';

  @override
  String get translatorCopied => 'Kopiert';

  @override
  String get translatorLangRu => 'Russisch';

  @override
  String get translatorLangEn => 'Englisch';

  @override
  String get translatorLangDe => 'Deutsch';

  @override
  String get translatorLangFr => 'Französisch';

  @override
  String get translatorLangEs => 'Spanisch';

  @override
  String get translatorLangIt => 'Italienisch';

  @override
  String get translatorLangPt => 'Portugiesisch';

  @override
  String get translatorLangTr => 'Türkisch';

  @override
  String get translatorLangZh => 'Chinesisch';

  @override
  String get translatorLangJa => 'Japanisch';

  @override
  String get translatorLangKo => 'Koreanisch';

  @override
  String get translatorLangAr => 'Arabisch';

  @override
  String get translatorLangPl => 'Polnisch';

  @override
  String get translatorLangSk => 'Slowakisch';

  @override
  String get translatorLangCs => 'Tschechisch';

  @override
  String get translatorLangNl => 'Niederländisch';

  @override
  String get translatorLangSv => 'Schwedisch';

  @override
  String get translatorLangDa => 'Dänisch';

  @override
  String get translatorLangNo => 'Norwegisch';

  @override
  String get translatorLangFi => 'Finnisch';

  @override
  String get translatorLangUk => 'Ukrainisch';

  @override
  String get translatorLangEl => 'Griechisch';

  @override
  String get translatorLangRo => 'Rumänisch';

  @override
  String get translatorLangHu => 'Ungarisch';

  @override
  String get translatorLangBg => 'Bulgarisch';

  @override
  String get translatorLangHr => 'Kroatisch';

  @override
  String get translatorLangSr => 'Serbisch';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Thailändisch';

  @override
  String get translatorLangVi => 'Vietnamesisch';

  @override
  String get translatorLangId => 'Indonesisch';

  @override
  String get translatorLangMs => 'Malaiisch';

  @override
  String get translatorLangHe => 'Hebräisch';

  @override
  String get translatorLangFa => 'Persisch';

  @override
  String get callInProgress => 'Anruf läuft';

  @override
  String get joinCall => 'Beitreten';

  @override
  String get createCallLink => 'Anruflink';

  @override
  String get callLinkCopied => 'Link kopiert';

  @override
  String get callLinkTitle => 'Raumlink';

  @override
  String get connectionUnstable =>
      'Verbindung instabil — Überprüfen Sie Ihr Internet';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get errorTimeout =>
      'Verbindung abgelaufen. Überprüfen Sie Ihre Internetverbindung.';

  @override
  String get errorNoConnection => 'Keine Internetverbindung.';

  @override
  String get errorGeneral =>
      'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get notifChannelMessages => 'Nachrichten';

  @override
  String get notifChannelMessagesDesc =>
      'Benachrichtigungen über neue Nachrichten';

  @override
  String get notifChannelMissedCalls => 'Verpasste Anrufe';

  @override
  String get notifChannelMissedCallsDesc =>
      'Benachrichtigungen über verpasste Anrufe';

  @override
  String get notifMissedCall => 'Verpasster Anruf';

  @override
  String get notifAccept => 'Annehmen';

  @override
  String get notifDecline => 'Ablehnen';

  @override
  String get notifIncomingCall => 'Eingehender Anruf';

  @override
  String get notifIncomingCallChannel => 'Eingehender Anruf';

  @override
  String get notifMissedCallChannel => 'Verpasster Anruf';

  @override
  String get notifUnknown => 'Unbekannt';

  @override
  String get effectNone => 'Kein Hintergrund';

  @override
  String get effectBlur => 'Weichzeichnen';

  @override
  String get effectOffice => 'Büro';

  @override
  String get effectNature => 'Natur';

  @override
  String get effectGradient => 'Verlauf';

  @override
  String get effectLibrary => 'Bibliothek';

  @override
  String get effectCity => 'Stadt';

  @override
  String get effectMinimalism => 'Minimalismus';

  @override
  String get voiceParticipant => 'Teilnehmer';

  @override
  String get voiceInvitesToRoom => 'lädt Sie in den Raum ein';

  @override
  String get voiceRoom => 'Raum';

  @override
  String get voicePasswordProtected => 'Passwortgeschützt';

  @override
  String get voicePasswordHint => 'Passwort';

  @override
  String get voiceEnter => 'Eintreten';

  @override
  String get voiceJoinRoom => 'Dem Raum beitreten';

  @override
  String get voiceYourName => 'Ihr Name';

  @override
  String voiceInvitationSent(String name) {
    return 'Einladung an $name gesendet';
  }

  @override
  String get voiceNoActiveRoom => 'Kein aktiver Raum';

  @override
  String get voiceCameraPermission =>
      'Kamerazugriff erlauben unter Einstellungen → Datenschutz → Kamera → TalerID';

  @override
  String get voiceOpenSettings => 'Öffnen';

  @override
  String voiceCameraError(String error) {
    return 'Kamera konnte nicht aktiviert werden: $error';
  }

  @override
  String get voiceAllAgreedRecording =>
      'Alle einverstanden. Aufnahme gestartet.';

  @override
  String get voiceNewParticipantAgreed =>
      'Neuer Teilnehmer hat der Aufnahme zugestimmt.';

  @override
  String get voiceDeclinedRecording =>
      'Sie haben die Aufnahme abgelehnt. Verlassen des Anrufs.';

  @override
  String get voiceRecordingEnded => 'Aufnahme beendet';

  @override
  String get voiceRecordingInProgress => 'Aufnahme läuft';

  @override
  String get voiceTranscriptionRequest => 'Transkriptionsanfrage';

  @override
  String get voiceRecordingRequest => 'Aufnahmeanfrage';

  @override
  String get voiceAgree => 'Zustimmen';

  @override
  String get voiceDeclineAndLeave => 'Ablehnen und verlassen';

  @override
  String get voiceAudioOutput => 'Audioausgabe';

  @override
  String get voiceAudioPhone => 'Telefon';

  @override
  String get voiceAudioSpeaker => 'Lautsprecher';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Kopfhörer';

  @override
  String get voiceLinkCopied => 'Link kopiert';

  @override
  String get voiceTranslateTo => 'Übersetzen nach';

  @override
  String get voiceSearchLanguage => 'Sprache suchen...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Raum $name';
  }

  @override
  String get voiceVoiceCall => 'Sprachanruf';

  @override
  String get voiceOnHold => 'Wartend';

  @override
  String get voiceActiveCall => 'Aktiv';

  @override
  String get voiceEndAllCalls => 'Alle Anrufe beenden';

  @override
  String get voiceEndThisCall => 'Diesen Anruf beenden';

  @override
  String get voiceCopyLink => 'Link kopieren';

  @override
  String get voiceAddParticipant => 'Teilnehmer hinzufügen';

  @override
  String get voiceReconnecting => 'Wiederverbinden...';

  @override
  String get voiceConnectionError => 'Verbindungsfehler';

  @override
  String get voiceClose => 'Schließen';

  @override
  String get voiceCalling => 'Anrufen...';

  @override
  String get voiceCallActive => 'Anruf aktiv';

  @override
  String get voiceWaiting => 'Warten';

  @override
  String get voiceWaitingUpper => 'WARTEN';

  @override
  String get voiceRec => 'AUF';

  @override
  String get voiceStop => 'Stopp';

  @override
  String get voiceRecord => 'Aufnahme';

  @override
  String get voiceTranslation => 'Übersetzung';

  @override
  String get voiceAudio => 'Audio';

  @override
  String get voiceFlipCamera => 'Kamera wechseln';

  @override
  String get voiceBackground => 'Hintergrund';

  @override
  String get voiceAssistantSpeakingStatus => 'Assistent spricht...';

  @override
  String get voiceAssistantListeningStatus => 'Assistent hört zu...';

  @override
  String get voiceUnmute => 'Stummschaltung aufheben';

  @override
  String get voiceMic => 'Mikrofon';

  @override
  String get voiceAssistantLabel => 'Assistent';

  @override
  String get voiceCameraOn => 'Kamera an';

  @override
  String get voiceCameraLabel => 'Kamera';

  @override
  String get voiceEndCall => 'Anruf beenden';

  @override
  String get voiceWaitingParticipants => 'Warten auf Teilnehmer...';

  @override
  String get voiceYou => 'Du';

  @override
  String get voiceAiAssistant => 'AI-Assistent';

  @override
  String get voiceVideoUnavailable => 'Video nicht verfügbar';

  @override
  String get voiceSearchNickname => 'Nach Spitzname suchen...';

  @override
  String get voiceTranscriptionWord => 'Transkription';

  @override
  String get voiceRecordingWord => 'Aufnahme';

  @override
  String get voiceConnecting => 'Verbinden...';

  @override
  String get voiceVideoBackground => 'Videohintergrund';

  @override
  String get voiceCallSettings => 'Anrufeinstellungen';

  @override
  String get voiceEnableAI => 'AI-Assistent aktivieren';

  @override
  String get voiceAIParticipating => 'AI wird an der Unterhaltung teilnehmen';

  @override
  String get voiceNormalCall => 'Normaler Anruf ohne AI';

  @override
  String get voiceCallConfirm => 'Anruf tätigen?';

  @override
  String get chatAlreadyInCall => 'Bereits im Anruf';

  @override
  String chatCallError(String error) {
    return 'Anruf Fehler: $error';
  }

  @override
  String get chatPhotoVideo => 'Foto / Video';

  @override
  String get chatCamera => 'Kamera';

  @override
  String get chatFile => 'Datei';

  @override
  String get chatContact => 'Kontakt';

  @override
  String get chatSelectContact => 'Einen Kontakt auswählen';

  @override
  String get chatNoContacts => 'Keine Kontakte';

  @override
  String get chatUser => 'Benutzer';

  @override
  String get chatFileAttachment => '📎 Datei';

  @override
  String chatFileUploadError(String error) {
    return 'Datei-Upload-Fehler: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Sprachnachricht';

  @override
  String get chatGroup => 'Gruppe';

  @override
  String get chatDialog => 'Dialog';

  @override
  String get chatCall => 'Anruf';

  @override
  String get chatStartConversation => 'Unterhaltung beginnen';

  @override
  String get chatYou => 'Du';

  @override
  String get chatIsTyping => 'schreibt...';

  @override
  String chatUserIsTyping(String name) {
    return '$name schreibt...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names schreiben...';
  }

  @override
  String get chatPreparingFile => 'Datei wird vorbereitet…';

  @override
  String chatUploading(int progress) {
    return 'Hochladen… $progress%';
  }

  @override
  String get chatEdited => 'Bearbeitet';

  @override
  String get chatViaMesh => 'über Mesh';

  @override
  String get chatReply => 'Antworten';

  @override
  String get chatEdit => 'Bearbeiten';

  @override
  String get chatCopy => 'Kopieren';

  @override
  String get chatCopied => 'Kopiert';

  @override
  String get chatSaveMedia => 'Speichern';

  @override
  String get chatForward => 'Weiterleiten';

  @override
  String get chatSaving => 'Speichern...';

  @override
  String get chatSavedToGallery => 'In Galerie gespeichert';

  @override
  String get chatNoSavePermission =>
      'Keine Berechtigung zum Speichern. Einstellungen prüfen.';

  @override
  String get chatFileSaveError => 'Fehler beim Speichern der Datei';

  @override
  String get chatDeleteMessage => 'Nachricht löschen';

  @override
  String get chatDeleteForMe => 'Für mich löschen';

  @override
  String get chatDeleteForEveryone => 'Für alle löschen';

  @override
  String get chatMessageForwarded => 'Nachricht weitergeleitet';

  @override
  String get chatContactTapToOpen => 'Kontakt · tippen zum Öffnen';

  @override
  String get chatForwardTo => 'Weiterleiten an...';

  @override
  String get chatSearchHint => 'Suchen...';

  @override
  String get chatRecording => 'Aufnahme...';

  @override
  String get chatMessageHint => 'Nachricht...';

  @override
  String get chatHideKeyboard => 'Tastatur ausblenden';

  @override
  String get chatEditing => 'Bearbeiten';

  @override
  String get chatFileDownloadError => 'Fehler beim Herunterladen der Datei';

  @override
  String get chatVoiceMessageShort => 'Sprachnachricht';

  @override
  String get chatVideoSavedToGallery => 'Video in Galerie gespeichert';

  @override
  String get chatSavingError => 'Fehler beim Speichern';

  @override
  String get convSetNickname => 'Spitznamen festlegen';

  @override
  String get convNicknameRequired =>
      'Ein Spitzname ist erforderlich, um den Messenger zu nutzen. Andere Nutzer können Sie darüber finden.';

  @override
  String get convNicknameRules => '3–30 Zeichen: Buchstaben, Ziffern, _';

  @override
  String get convNicknameTaken => 'Spitzname bereits vergeben';

  @override
  String get convSaveError => 'Fehler beim Speichern';

  @override
  String get convContactsLabel => 'Kontakte';

  @override
  String get convDefaultUser => 'Benutzer';

  @override
  String get convNoDialogs => 'Keine Unterhaltungen';

  @override
  String get convFindUserToChat => 'Finde einen Benutzer, um zu chatten';

  @override
  String get convDefaultContact => 'Kontakt';

  @override
  String get dashboardUser => 'Benutzer';

  @override
  String get dashboardIncomingCall => 'Eingehender Anruf';

  @override
  String get dashboardDecline => 'Ablehnen';

  @override
  String get dashboardAccept => 'Annehmen';

  @override
  String get dashboardActiveCall => 'Aktiver Anruf — tippen, um zurückzukehren';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Update verfügbar $version';
  }

  @override
  String get dashboardUpdate => 'Aktualisieren';

  @override
  String get dashboardWhatsNew => 'Neues';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Neues in $version';
  }

  @override
  String get dashboardInstalling => 'Installiere...';

  @override
  String get contactRequestsTitle => 'Kontakte';

  @override
  String get messengerContactRequestsSection => 'Kontaktanfragen';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Anfragen',
      one: '1 neue Anfrage',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Suchen';

  @override
  String get contactRequestsIncoming => 'Eingehend';

  @override
  String get contactRequestsSent => 'Gesendet';

  @override
  String get contactRequestsSearchHint => 'Spitzname oder E-Mail';

  @override
  String get contactRequestSent => 'Anfrage gesendet';

  @override
  String get contactRequestsNoUsers => 'Keine Benutzer gefunden';

  @override
  String get contactRequestsSearchHelp =>
      'Geben Sie den genauen Spitznamen oder die E-Mail ein\nund drücken Sie auf Suchen';

  @override
  String get contactRequestsSendTooltip => 'Anfrage senden';

  @override
  String get contactRequestTitle => 'Kontaktanfrage';

  @override
  String contactRequestConfirm(String name) {
    return 'Kontaktanfrage an $name senden?';
  }

  @override
  String get contactRequestSend => 'Senden';

  @override
  String get contactRequestsNoIncoming => 'Keine eingehenden Anfragen';

  @override
  String get contactRequestsNoSent => 'Keine gesendeten Anfragen';

  @override
  String get contactRequestStatusPending => 'Warte auf Antwort';

  @override
  String get contactRequestStatusAccepted => 'Akzeptiert';

  @override
  String get contactRequestStatusRejected => 'Abgelehnt';

  @override
  String get userSearchTitle => 'Benutzer finden';

  @override
  String get userSearchHint => 'Spitzname, Telefon oder E-Mail';

  @override
  String get userSearchHelper =>
      'Geben Sie @Spitzname, E-Mail oder Name ein, um zu suchen';

  @override
  String get userSearchNoUsers => 'Keine Benutzer gefunden';

  @override
  String get userProfileShareContact => 'Kontakt teilen';

  @override
  String get userProfileShareContactDesc => 'Kontaktlink senden';

  @override
  String get userProfileCopyLink => 'Link kopieren';

  @override
  String get userProfileCopied => 'Kopiert';

  @override
  String get userProfileTitle => 'Profil';

  @override
  String get userProfileLoadError => 'Profil-Ladefehler';

  @override
  String get userProfileMessage => 'Nachricht';

  @override
  String get userProfileCall => 'Anruf';

  @override
  String get userProfileRequestSent => 'Anfrage gesendet';

  @override
  String get userProfileAccept => 'Akzeptieren';

  @override
  String get userProfileDecline => 'Ablehnen';

  @override
  String get userProfileAddToContacts => 'Zu Kontakten hinzufügen';

  @override
  String get userProfileMediaTab => 'Medien';

  @override
  String get userProfileFilesTab => 'Dateien';

  @override
  String get userProfileLinksTab => 'Links';

  @override
  String get userProfileRecordingsTab => 'Aufnahmen';

  @override
  String get userProfileSummariesTab => 'Zusammenfassungen';

  @override
  String get userProfileNoMedia => 'Keine Mediendateien';

  @override
  String get userProfileNoFiles => 'Keine Dateien';

  @override
  String get userProfileNoLinks => 'Keine Links';

  @override
  String get userProfileNoRecordings => 'Keine Aufnahmen';

  @override
  String get userProfileNoSummaries => 'Keine Zusammenfassungen';

  @override
  String get userProfileMeetingSummary => 'Besprechungszusammenfassung';

  @override
  String get userProfileFailedOpenChat => 'Chat konnte nicht geöffnet werden';

  @override
  String get sharedMediaTitle => 'Medien und Dateien';

  @override
  String get sharedMediaTab => 'Medien';

  @override
  String get sharedFilesTab => 'Dateien';

  @override
  String get sharedLinksTab => 'Links';

  @override
  String get sharedNoMedia => 'Keine Mediendateien';

  @override
  String get sharedNoFiles => 'Keine Dateien';

  @override
  String get sharedNoLinks => 'Keine Links';

  @override
  String get shareToChat => 'An Chat weiterleiten';

  @override
  String get shareSelectChat => 'Chat auswählen';

  @override
  String get shareNoChats => 'Keine Chats';

  @override
  String shareFilesCount(int count) {
    return '$count Dateien';
  }

  @override
  String get contactsTitle => 'Kontakte';

  @override
  String get contactsAddTooltip => 'Kontakt hinzufügen';

  @override
  String get contactsSearchHint => 'Kontakte suchen...';

  @override
  String get contactsNotFound => 'Nichts gefunden';

  @override
  String get contactsEmpty => 'Keine Kontakte';

  @override
  String get contactsAdd => 'Kontakt hinzufügen';

  @override
  String get contactsPendingConfirmation => 'Warten auf Bestätigung';

  @override
  String get contactsMessage => 'Nachricht';

  @override
  String get contactsCall => 'Anruf';

  @override
  String get contactsResend => 'Anfrage erneut senden';

  @override
  String get contactsResendTimeout => 'Erneut versuchen in 24h';

  @override
  String get contactsResent => 'Anfrage erneut gesendet';

  @override
  String get contactsWantsToConnect => 'Möchte sich mit Ihnen verbinden';

  @override
  String get contactsSearchPeople => 'Personen finden';

  @override
  String get notesTitle => 'Notizen';

  @override
  String get notesAssistantSpeaking => 'Assistent spricht...';

  @override
  String get notesListening => 'Hört zu...';

  @override
  String get notesEmpty => 'Keine Notizen';

  @override
  String get notesEmptyHint =>
      'Drücken Sie das Mikrofon für Diktat\noder + für manuelle Eingabe';

  @override
  String get notesDeleteConfirm => 'Notiz löschen?';

  @override
  String get notesNew => 'Neue Notiz';

  @override
  String get notesEdit => 'Bearbeiten';

  @override
  String get notesTitleHint => 'Titel';

  @override
  String get notesContentHint => 'Schreiben Sie Ihre Gedanken...';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get calendarStop => 'Stopp';

  @override
  String get calendarVoiceInput => 'Spracheingabe';

  @override
  String get calendarNewEvent => 'Neues Ereignis';

  @override
  String get calendarAssistantSpeaking => 'Assistent spricht...';

  @override
  String get calendarListening => 'Hört zu...';

  @override
  String calendarInvitations(int count) {
    return 'Einladungen ($count)';
  }

  @override
  String get calendarNoEvents => 'Keine Ereignisse';

  @override
  String get calendarDayMon => 'Mo';

  @override
  String get calendarDayTue => 'Di';

  @override
  String get calendarDayWed => 'Mi';

  @override
  String get calendarDayThu => 'Do';

  @override
  String get calendarDayFri => 'Fr';

  @override
  String get calendarDaySat => 'Sa';

  @override
  String get calendarDaySun => 'So';

  @override
  String get calendarEnterRoom => 'Raum betreten';

  @override
  String get calendarMeeting => 'Besprechung';

  @override
  String calendarLocationPrefix(String location) {
    return 'Ort: $location';
  }

  @override
  String get calendarEditEvent => 'Bearbeiten';

  @override
  String get calendarTitleHint => 'Titel';

  @override
  String get calendarDescriptionHint => 'Beschreibung';

  @override
  String get calendarTypeEvent => 'Ereignis';

  @override
  String get calendarTypeMeeting => 'Besprechung';

  @override
  String get calendarTypeReminder => 'Erinnerung';

  @override
  String get calendarTypeLabel => 'Typ';

  @override
  String get calendarMeetingLink => 'Besprechungslink';

  @override
  String get calendarLocationHint => 'Ort';

  @override
  String get calendarDateLabel => 'Datum';

  @override
  String get calendarTimeLabel => 'Uhrzeit';

  @override
  String get calendarReminderLabel => 'Erinnerung';

  @override
  String get calendarReminderNone => 'Keine';

  @override
  String get calendarReminder15min => '15 Min. vorher';

  @override
  String get calendarReminder30min => '30 Min. vorher';

  @override
  String get calendarReminder1hour => '1 Stunde vorher';

  @override
  String get calendarRepeatLabel => 'Wiederholen';

  @override
  String get calendarRepeatNone => 'Keine Wiederholung';

  @override
  String get calendarRepeatDaily => 'Jeden Tag';

  @override
  String get calendarRepeatWeekly => 'Jede Woche';

  @override
  String get calendarRepeatMonthly => 'Jeden Monat';

  @override
  String get calendarRepeatYearly => 'Jedes Jahr';

  @override
  String get calendarParticipants => 'Teilnehmer';

  @override
  String get calendarAddParticipant => 'Hinzufügen';

  @override
  String get calendarSearchContacts => 'Kontakte suchen...';

  @override
  String get calendarNoContacts => 'Keine Kontakte';

  @override
  String get calendarStatusAccepted => 'Angenommen';

  @override
  String get calendarStatusDeclined => 'Abgelehnt';

  @override
  String get calendarStatusMaybe => 'Vielleicht';

  @override
  String get calendarStatusPending => 'Ausstehend';

  @override
  String get calendarEndTime => 'Endzeit';

  @override
  String get calendarYourAnswer => 'Ihre Antwort:';

  @override
  String get calendarOrganizer => 'Organisator';

  @override
  String calendarDeleteError(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get calendarRsvpAccept => 'Annehmen';

  @override
  String get calendarRsvpMaybe => 'Vielleicht';

  @override
  String get calendarRsvpDecline => 'Ablehnen';

  @override
  String get callHistoryTitle => 'Anrufe';

  @override
  String get callHistoryTab => 'Anrufverlauf';

  @override
  String get callHistoryTempMeeting => 'Temporäres Meeting';

  @override
  String get callHistoryCopy => 'Kopieren';

  @override
  String get callHistoryLinkCopied => 'Link kopiert';

  @override
  String get callHistoryShare => 'Teilen';

  @override
  String get callHistoryEnter => 'Betreten';

  @override
  String get callHistoryAlreadyInCall => 'Bereits in einem Anruf';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Konnte die andere Partei nicht bestimmen';

  @override
  String get callHistoryContacts => 'Kontakte';

  @override
  String get callHistoryFailedLoadRoom => 'Laden Ihres Raumes fehlgeschlagen';

  @override
  String get callHistoryYourRoom => 'Ihr Raum';

  @override
  String get callHistoryCreateMeeting => 'Meeting erstellen';

  @override
  String get callHistoryMeetingSummaries => 'Besprechungszusammenfassungen';

  @override
  String get callHistoryMeetingRecordings => 'Besprechungsaufzeichnungen';

  @override
  String get callHistoryNoCalls => 'Keine Anrufe';

  @override
  String get callHistoryMissed => 'Verpasst';

  @override
  String get callHistoryRecording => 'Aufnahme';

  @override
  String get callHistorySummary => 'Zusammenfassung';

  @override
  String get callHistoryCallAgain => 'Erneut anrufen';

  @override
  String callHistoryTodayTime(String time) {
    return 'Heute, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Gestern, $time';
  }

  @override
  String get callHistoryUnknown => 'Unbekannt';

  @override
  String get callHistoryDetails => 'Anrufdetails';

  @override
  String get callHistoryOutgoing => 'Ausgehender Anruf';

  @override
  String get callHistoryIncoming => 'Eingehender Anruf';

  @override
  String callHistoryDuration(String duration) {
    return 'Dauer: $duration';
  }

  @override
  String get callHistoryWithAI => 'Mit AI-Assistent';

  @override
  String get callHistoryParticipants => 'Teilnehmer';

  @override
  String get callDetailYouSuffix => '(Sie)';

  @override
  String get callHistoryMeetingSummary => 'Besprechungszusammenfassung';

  @override
  String get callHistoryMoreDetails => 'Mehr Details';

  @override
  String get callHistorySummaryProcessing =>
      'Zusammenfassung wird verarbeitet...';

  @override
  String get callHistoryMeetingRecording => 'Besprechungsaufzeichnung';

  @override
  String get callHistoryProcessing => 'Wird verarbeitet...';

  @override
  String get callHistoryCreateTranscript => 'Transkript erstellen';

  @override
  String get callHistoryNoSummaries => 'Keine Zusammenfassungen';

  @override
  String get callHistoryRecordDuringCall =>
      'Drücken Sie \"Aufnehmen\" während eines Anrufs';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Besprechung $time';
  }

  @override
  String get callHistoryTranscribing => 'Transkribieren und zusammenfassen...';

  @override
  String get callHistoryTranscriptCreated => 'Transkript erstellt';

  @override
  String get callHistoryNoRecordings => 'Keine Aufnahmen';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Aufnahme $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Aufnahme nicht verfügbar';

  @override
  String get callHistoryTranscriptReady => 'Transkript bereit';

  @override
  String get callHistoryTranscript => 'Transkript';

  @override
  String get callHistoryKeyPoints => 'Wichtige Punkte';

  @override
  String get callHistoryTasks => 'Aufgaben';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Zugewiesen an: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Entscheidungen';

  @override
  String get callHistoryShowTranscript => 'Vollständiges Transkript anzeigen';

  @override
  String get profileScanQr => 'QR scannen';

  @override
  String get profileMyQrCode => 'Mein QR-Code';

  @override
  String profileAddMeShare(String userId) {
    return 'Füge mich in Taler ID hinzu!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Zeige diesen Code, um dich hinzuzufügen';

  @override
  String get profileEditDesc => 'Name, Nachname, Vatersname, Geburtsdatum';

  @override
  String get profileAboutMe => 'Über mich';

  @override
  String get profileAboutMeDesc => 'Werte, Fähigkeiten, Interessen und mehr';

  @override
  String get profileNotes => 'Notizen';

  @override
  String get profileNotesDesc => 'Gedanken, Ideen und Notizen';

  @override
  String get profileAvatarUpdated => 'Avatar aktualisiert';

  @override
  String get profileNickname => 'Spitzname';

  @override
  String get profileNotSet => 'Nicht festgelegt';

  @override
  String get profileChangeNickname => 'Spitzname ändern';

  @override
  String get profileNicknameUpdated => 'Spitzname aktualisiert';

  @override
  String get profileShareLabel => 'Teilen';

  @override
  String get profileScanQrCode => 'QR-Code scannen';

  @override
  String get profilePointCamera => 'Kamera auf QR-Code richten';

  @override
  String get profilePhotoCamera => 'Foto aufnehmen';

  @override
  String get profilePhotoGallery => 'Aus Galerie wählen';

  @override
  String get editProfilePatronymic => 'Vatersname (optional)';

  @override
  String get editProfileDateFormat => 'TT.MM.JJJJ';

  @override
  String get aboutMeTitle => 'Über mich';

  @override
  String get aboutMeClickToFill => 'Zum Ausfüllen klicken';

  @override
  String get aboutMeCoreValues => 'Werte';

  @override
  String get aboutMeWorldview => 'Weltanschauung';

  @override
  String get aboutMeSkills => 'Fähigkeiten';

  @override
  String get aboutMeInterests => 'Interessen';

  @override
  String get aboutMeDesires => 'Wünsche';

  @override
  String get aboutMeBackground => 'Profil';

  @override
  String get aboutMeLikes => 'Vorlieben';

  @override
  String get aboutMeDislikes => 'Abneigungen';

  @override
  String get aboutMeDeleteSection => 'Abschnitt löschen?';

  @override
  String get aboutMeDeleteConfirm =>
      'Alle Daten in diesem Abschnitt werden gelöscht.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Verbindungsfehler: $error';
  }

  @override
  String get aboutMeVisibility => 'Sichtbarkeit';

  @override
  String get aboutMeTags => 'Tags';

  @override
  String get aboutMeAddTag => 'Tag hinzufügen...';

  @override
  String get aboutMeDescription => 'Beschreibung';

  @override
  String get aboutMeDescribeLong => 'Erzähle uns mehr...';

  @override
  String get aboutMeVisibilityEveryone => 'Jeder';

  @override
  String get aboutMeVisibilityContacts => 'Kontakte';

  @override
  String get aboutMeVisibilityOnlyMe => 'Nur ich';

  @override
  String get settingsProfileSubtitle => 'Profil';

  @override
  String get settingsWallpaper => 'Hintergrundbild';

  @override
  String get settingsWallpaperDesc => 'Hintergrundbild für die gesamte App';

  @override
  String get settingsWallpaperNone => 'Kein';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsKycVerification => 'Identitätsprüfung (KYC)';

  @override
  String get settingsOrganizations => 'Organisationen';

  @override
  String get incomingCallLabel => 'Eingehender Anruf';

  @override
  String get incomingCallDecline => 'Ablehnen';

  @override
  String get incomingCallAccept => 'Annehmen';

  @override
  String get meshIncomingCallLabel => '📡 Eingehender Mesh-Anruf';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Mesh-Gerät $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall =>
      'Beenden Sie zuerst den aktuellen Anruf';

  @override
  String get callPopupTransportTitle => 'Anruf über';

  @override
  String get callPopupTransportMesh => '📡 Mesh (Peer-to-Peer)';

  @override
  String get callPopupTransportLk => '📞 Server';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Kontakt über Mesh nicht erreichbar';

  @override
  String get meshOnboardingTitle =>
      '📡 Mesh-Anrufe benötigen die geöffnete App';

  @override
  String get meshOnboardingBody =>
      'Wenn das Telefon gesperrt ist, können Mesh-Anrufe nach ~30 Sekunden abbrechen (iOS-Einschränkung).';

  @override
  String get meshOnboardingAck => 'Verstanden';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Kontakt ist nicht in Ihrer Liste';

  @override
  String get meshCallStatusInviting => 'Rufe an…';

  @override
  String get meshCallStatusConnecting => 'Verbinden…';

  @override
  String get meshCallEndedUserHangup => 'Anruf beendet';

  @override
  String get meshCallEndedRemoteHangup => 'Vom Teilnehmer beendet';

  @override
  String get meshCallEndedRejected => 'Abgelehnt';

  @override
  String get meshCallEndedNoAnswer => 'Keine Antwort';

  @override
  String get meshCallEndedConnectionLost => 'Verbindung verloren';

  @override
  String get meshCallEndedError => 'Verbindungsfehler';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Zuverlässige Mesh-Anrufe';

  @override
  String get batteryExemptionBody =>
      'Erlauben Sie der App, ohne Batterieeinschränkungen zu laufen, damit Android das Mesh im Hintergrund nicht beendet.';

  @override
  String get batteryExemptionAccept => 'Einstellungen öffnen';

  @override
  String get batteryExemptionDismiss => 'Nicht jetzt';

  @override
  String get groupCamera => 'Kamera';

  @override
  String get groupGallery => 'Galerie';

  @override
  String get groupAvatarUpdated => 'Gruppenavatar aktualisiert';

  @override
  String get groupNameTitle => 'Gruppenname';

  @override
  String get groupEnterName => 'Name eingeben';

  @override
  String get groupDescriptionTitle => 'Gruppenbeschreibung';

  @override
  String get groupEnterDescription => 'Gruppenbeschreibung eingeben';

  @override
  String get groupChangeRoleTitle => 'Rolle ändern';

  @override
  String get groupRemoveMemberTitle => 'Mitglied entfernen';

  @override
  String get groupDescription => 'Beschreibung';

  @override
  String get groupAddDescription => 'Gruppenbeschreibung hinzufügen';

  @override
  String get groupNoDescription => 'Keine Beschreibung';

  @override
  String get groupMediaAndFiles => 'Medien und Dateien';

  @override
  String get groupMuteNotifications => 'Benachrichtigungen stummschalten';

  @override
  String get groupMuted => 'Stummgeschaltet';

  @override
  String get groupNoResults => 'Keine Ergebnisse';

  @override
  String get authInvalidCode => 'Ungültiger Code. Versuchen Sie es erneut.';

  @override
  String get loginSubtitle => 'Verwenden Sie E-Mail und Passwort';

  @override
  String get emailRequired => 'E-Mail eingeben';

  @override
  String get emailInvalid => 'Ungültige E-Mail';

  @override
  String get passwordRequired => 'Passwort eingeben';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Ein Konto für das gesamte Taler-Ökosystem';

  @override
  String get usernameOptional => 'Benutzername (optional)';

  @override
  String get usernameMinLength => 'Mindestens 3 Zeichen';

  @override
  String get usernameMaxLength => 'Maximal 30 Zeichen';

  @override
  String get usernameInvalid => 'Nur Buchstaben, Ziffern und _';

  @override
  String get biometricLoginReason => 'Bei Taler ID anmelden';

  @override
  String get docTypePassport => 'Reisepass';

  @override
  String get docTypeIdCard => 'Personalausweis';

  @override
  String get docTypeDriverLicense => 'Führerschein';

  @override
  String get docTypeResidencePermit => 'Aufenthaltserlaubnis';

  @override
  String addressApartment(String number) {
    return 'Whg. $number';
  }

  @override
  String get failedToUpdateProfile => 'Profilaktualisierung fehlgeschlagen';

  @override
  String get failedToStartKyb =>
      'KYB-Verifizierung konnte nicht gestartet werden';

  @override
  String get orgUpdated => 'Organisation aktualisiert';

  @override
  String get failedToUpdateOrg =>
      'Organisation konnte nicht aktualisiert werden';

  @override
  String get failedToChangeRole => 'Rollenänderung fehlgeschlagen';

  @override
  String get failedToRemoveMember => 'Mitglied konnte nicht entfernt werden';

  @override
  String get capabilityMessagesTitle => 'Nachrichten';

  @override
  String get capabilityMessagesDesc =>
      'Nachrichten prüfen oder jemandem schreiben. Zum Beispiel: \"Schreibe an Viktor: bin in einer Stunde da\"';

  @override
  String get capabilityCallsTitle => 'Anrufe';

  @override
  String get capabilityCallsDesc =>
      'Jeden Kontakt per Sprache anrufen. Zum Beispiel: \"Rufe Viktor Viktorov an\"';

  @override
  String get capabilityChatTitle => 'Chatverlauf';

  @override
  String get capabilityChatDesc =>
      'Ich analysiere den Chatverlauf. Zum Beispiel: \"Was haben wir mit Viktor besprochen?\"';

  @override
  String get capabilityProfileTitle => 'Profil';

  @override
  String get capabilityProfileDesc =>
      'Ich zeige oder aktualisiere dein Profil. Zum Beispiel: \"Zeige mein Profil\"';

  @override
  String get capabilityCoachingTitle => 'Coaching';

  @override
  String get capabilityCoachingDesc =>
      'Modi: ICF-Coaching, Psychologe, HR-Beratung. Sage: \"Lass uns Coaching machen\"';

  @override
  String get capabilityCalendarTitle => 'Kalender';

  @override
  String get capabilityCalendarDesc =>
      'Plane ein Meeting oder setze eine Erinnerung. Zum Beispiel: \"Plane ein Meeting mit Viktor für morgen um 15:00\"';

  @override
  String get capabilityNotesTitle => 'Notizen';

  @override
  String get capabilityNotesDesc =>
      'Speichere einen Gedanken oder lies aktuelle Notizen. Zum Beispiel: \"Schreibe eine Idee auf...\" oder \"Lies aktuelle Notizen\"';

  @override
  String get assistantCallConfirm => 'Anruf tätigen?';

  @override
  String get callNoAnswer => 'Keine Antwort';

  @override
  String get contactDelete => 'Kontakt entfernen';

  @override
  String get contactDeleteTitle => 'Kontakt entfernen';

  @override
  String get contactDeleteConfirm =>
      'Bist du sicher? Dieser Kontakt wird entfernt.';

  @override
  String get contactBlock => 'Blockieren';

  @override
  String get contactBlockTitle => 'Benutzer blockieren';

  @override
  String get contactBlockConfirm =>
      'Dieser Benutzer kann dir keine Nachrichten senden oder dich anrufen.';

  @override
  String get contactUnblock => 'Entblocken';

  @override
  String get contactBlocked => 'Blockiert';

  @override
  String get contactYouAreBlocked => 'Dieser Benutzer hat dich blockiert';

  @override
  String get chatBlockedByYou => 'Du hast diesen Benutzer blockiert';

  @override
  String get chatYouAreBlocked => 'Du wurdest von diesem Benutzer blockiert';

  @override
  String get chatNotContacts =>
      'Füge diesen Benutzer zu den Kontakten hinzu, um ihm Nachrichten zu senden';

  @override
  String get contactRevokeRequest => 'Anfrage widerrufen';

  @override
  String get messengerPoll => 'Umfrage';

  @override
  String get messengerCreatePoll => 'Umfrage erstellen';

  @override
  String get messengerPollQuestion => 'Frage';

  @override
  String messengerPollOption(int number) {
    return 'Option $number';
  }

  @override
  String get messengerPollAddOption => 'Option hinzufügen';

  @override
  String get messengerPollAnonymous => 'Anonyme Abstimmung';

  @override
  String get messengerPollMultiple => 'Mehrfachauswahl';

  @override
  String get messengerPollCreateError => 'Umfrage konnte nicht erstellt werden';

  @override
  String get messengerPollUnavailable => 'Umfrage nicht verfügbar';

  @override
  String get messengerPollMultipleNote => 'Du kannst mehrere auswählen';

  @override
  String messengerPollVotes(int count) {
    return '$count Stimmen';
  }

  @override
  String get messengerVideoMessage => 'Videonachricht';

  @override
  String get messengerVideoRecordError => 'Fehler bei der Videoaufnahme';

  @override
  String get messengerVideoPlaybackError =>
      'Video konnte nicht abgespielt werden';

  @override
  String get messengerGalleryAccessError => 'Kein Zugriff auf die Galerie';

  @override
  String get messengerSearchInChat => 'Im Chat suchen...';

  @override
  String get messengerSaveToFavorites => 'Zu Favoriten speichern';

  @override
  String get messengerSavedToFavorites => 'Zu Favoriten gespeichert';

  @override
  String get messengerSearchInMessages => 'In Nachrichten suchen...';

  @override
  String messengerFoundInMessages(int count) {
    return 'In Nachrichten gefunden ($count)';
  }

  @override
  String get messengerGroupDefault => 'Gruppe';

  @override
  String get messengerUserDefault => 'Benutzer';

  @override
  String get messengerPin => 'Anheften';

  @override
  String get messengerUnpin => 'Lösen';

  @override
  String get messengerArchive => 'Archivieren';

  @override
  String get messengerUnarchive => 'Wiederherstellen';

  @override
  String get messengerDeleteChat => 'Chat löschen';

  @override
  String get messengerDeleteChatTitle => 'Chat löschen?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Chat mit $name löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get messengerCreateChannel => 'Kanal erstellen';

  @override
  String get messengerChannelName => 'Name';

  @override
  String get messengerChannelDescription => 'Beschreibung (optional)';

  @override
  String get messengerChannelCreateError =>
      'Kanal konnte nicht erstellt werden';

  @override
  String get messengerFilterAll => 'Alle';

  @override
  String get messengerFilterUnread => 'Ungelesen';

  @override
  String get messengerFilterPersonal => 'Persönlich';

  @override
  String get messengerFilterGroups => 'Gruppen';

  @override
  String get messengerFilterChannels => 'Kanäle';

  @override
  String get messengerArchivedSection => 'Archiviert';

  @override
  String get messengerSavedSection => 'Favoriten';

  @override
  String get messengerSavedSubtitle => 'Zur Erinnerung speichern';

  @override
  String messengerArchiveTitle(int count) {
    return 'Archiv ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Archiv ist leer';

  @override
  String messengerYouPrefix(String message) {
    return 'Du: $message';
  }

  @override
  String get messengerMissedCall => 'Verpasster Anruf';

  @override
  String get messengerSavedTitle => 'Favoriten';

  @override
  String get messengerNoSavedMessages => 'Keine gespeicherten Nachrichten';

  @override
  String get messengerSavedHint =>
      'Nachricht lange drücken → \"Zu Favoriten speichern\"';

  @override
  String get messengerDefaultFile => 'Datei';

  @override
  String get messengerTopicDefault => 'Allgemein';

  @override
  String get messengerTopicNew => 'Neues Thema';

  @override
  String get messengerTopicNameHint => 'Themenname';

  @override
  String get messengerTopicIcon => 'Symbol';

  @override
  String messengerTopicCount(int count) {
    return '$count Themen';
  }

  @override
  String get messengerNoTopics => 'Keine Themen';

  @override
  String get messengerNoMessages => 'Keine Nachrichten';

  @override
  String get you => 'Du';

  @override
  String get messengerThread => 'Thread';

  @override
  String get messengerThreadReply => 'antworten';

  @override
  String get messengerThreadReplies => 'Antworten';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Keine Antworten';

  @override
  String get messengerReplyHint => 'Auf Thread antworten...';

  @override
  String get messengerContactName => 'Kontaktname';

  @override
  String messengerOriginalName(String name) {
    return 'Originalname: $name';
  }

  @override
  String get messengerDisplayName => 'Anzeigename';

  @override
  String messengerShareContact(String name) {
    return 'Kontakt in Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Nachrichten automatisch löschen';

  @override
  String get messengerAutoDeleteOff => 'Aus';

  @override
  String get messengerAutoDelete7d => '7 Tage';

  @override
  String get messengerAutoDelete30d => '30 Tage';

  @override
  String get messengerAutoDelete90d => '90 Tage';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count Tage';
  }

  @override
  String get messengerSettingsHeader => 'Einstellungen';

  @override
  String get messengerAdminOnly => 'Nur Admin-Postings';

  @override
  String get messengerAdminOnlyDesc => 'Mitglieder können nur lesen';

  @override
  String get messengerTopics => 'Themen';

  @override
  String get messengerTopicsDesc => 'Chat in Themen aufteilen';

  @override
  String get aiTwinSection => 'AI Voice Twin';

  @override
  String get aiTwinEnabled => 'AI Twin aktivieren';

  @override
  String get aiTwinEnabledDesc =>
      'Wenn du nicht antwortest, übernimmt dein AI Twin den Anruf in deiner Stimme';

  @override
  String get aiTwinTimeout => 'Antwort-Timeout';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds Sek';
  }

  @override
  String get aiTwinPrompt => 'AI-Anweisungen';

  @override
  String get aiTwinPromptSubtitle =>
      'Wie sich der AI Twin vorstellen soll und worüber er sprechen soll';

  @override
  String aiTwinPromptHint(String name) {
    return 'Hallo, hier ist ${name}s AI Voice Twin. $name konnte gerade nicht rangehen. Sag mir, wer anruft und worum es geht — ich gebe es weiter.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Individuelles Stimmenklonen kommt bald. Derzeit spricht die AI mit ${name}s Stimme.';
  }

  @override
  String get aiTwinDefaultName => 'der Besitzer';

  @override
  String get aiTwinPromptReset => 'Zurücksetzen';

  @override
  String get callHistoryAiTwinAnswered => 'AI TWIN HAT GEANTWORTET';

  @override
  String get callHistoryAiTwinSummary => 'ANRUFZUSAMMENFASSUNG';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSKRIPT';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'Von $name';
  }

  @override
  String get aiTwinOfferTitle => 'Nicht antworten';

  @override
  String aiTwinOfferBody(String name) {
    return '$name geht nicht ran. Eine Nachricht mit ihrem AI-Stimmzwilling hinterlassen?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Benutzer';

  @override
  String get aiTwinOfferAccept => 'Ja, Nachricht hinterlassen';

  @override
  String get aiTwinOfferKeepWaiting => 'Weiter warten';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Dein AI-Vertreter';

  @override
  String get aiTwinHeroSubtitle =>
      'Nimmt Anrufe in deiner Stimme entgegen, wenn du nicht kannst.';

  @override
  String get aiTwinProfileTitle => 'AI-Vertreter';

  @override
  String get aiTwinProfileDesc => 'Nimmt Anrufe in deiner Stimme entgegen';

  @override
  String get aiTwinBadgeOn => 'AN';

  @override
  String get aiAnalystTitle => 'AI-Analyst';

  @override
  String get aiAnalystSubtitle => 'Dateien, Aufgaben, Analyse — Claude';

  @override
  String get channelsDiscover => 'Kanal finden';

  @override
  String get channelsSearchHint => 'Kanäle suchen';

  @override
  String get channelsSubscribers => 'Abonnenten';

  @override
  String get channelsSubscribe => 'Abonnieren';

  @override
  String get channelsUnsubscribe => 'Abbestellen';

  @override
  String get channelsSubscribedLabel => 'Du bist abonniert';

  @override
  String get channelsSettings => 'Kanaleinstellungen';

  @override
  String get channelsDelete => 'Kanal löschen';

  @override
  String get channelsDeleteConfirm => 'Kanal dauerhaft löschen?';

  @override
  String get channelsEmpty => 'Noch keine Kanäle';

  @override
  String get channelsOpen => 'Öffnen';

  @override
  String get channelsNameLabel => 'Name';

  @override
  String get channelsDescriptionLabel => 'Beschreibung';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Eigentümer kann nicht abbestellen. Lösche stattdessen den Kanal.';

  @override
  String get channelsNotFoundRedirect => 'Kanal existiert nicht mehr';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Suchen',
      one: '$count Suche',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '$count Datei',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Befehle',
      one: '$count Befehl',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '$count Bild',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schritte',
      one: '$count Schritt',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Gespeicherte Nachrichten';

  @override
  String get savedSubtitle => 'Deine private Cloud';

  @override
  String get savedOpenError => 'Konnte Gespeicherte Nachrichten nicht öffnen';

  @override
  String get billingWalletTitle => 'Geldbörse';

  @override
  String get billingBuyPackage => 'Paket kaufen';

  @override
  String get billingCurrentBalance => 'Aktueller Kontostand';

  @override
  String get billingPackagesTitle => 'Pakete';

  @override
  String get billingPackagesUnavailable => 'Pakete nicht verfügbar';

  @override
  String get billingRecentOperations => 'Letzte Vorgänge';

  @override
  String get billingAllOperations => 'Alle Vorgänge';

  @override
  String get billingNoOperations => 'Keine Vorgänge';

  @override
  String get billingOperationsTitle => 'Vorgänge';

  @override
  String get billingOperationsEmptyTitle => 'Noch keine Vorgänge';

  @override
  String get billingOperationsEmptySubtitle =>
      'Aufladungen und Gebühren für AI-Funktionen werden hier angezeigt';

  @override
  String get billingPricebookTitle => 'Funktionspreise';

  @override
  String get billingPricebookUnavailable => 'Preisliste nicht verfügbar';

  @override
  String get billingAiFeaturesTitle => 'AI-Funktionen';

  @override
  String get billingInsufficientFundsTitle => 'Unzureichende Mittel';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Laden Sie Ihr Guthaben auf, um diese Funktion zu nutzen.';

  @override
  String billingRequiredLine(String required) {
    return 'Benötigt: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Verfügbar: $available μTAL';
  }

  @override
  String get billingTopUp => 'Aufladen';

  @override
  String get billingCancel => 'Abbrechen';

  @override
  String get billingRetry => 'Erneut versuchen';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Guthaben niedrig: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Wallet & Guthaben';

  @override
  String get billingSectionHeader => 'Abrechnung & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Sprachassistent';

  @override
  String get billingFeatureWebSearch => 'Assistent Websuche';

  @override
  String get billingFeatureAiTwin => 'Stimmzwilling';

  @override
  String get billingFeatureAiTwinLong => 'Stimmzwilling (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Ausgehender Bot';

  @override
  String get billingFeatureOutboundCallLong => 'Ausgehender Anrufbot';

  @override
  String get billingFeatureWhisperTranscribe => 'Anruftranskription';

  @override
  String get billingFeatureMeetingSummary => 'AI-Anrufzusammenfassungen';

  @override
  String get billingConfigureAiTwin => 'AI Twin konfigurieren';

  @override
  String get billingWebSearchSubtitle => '(vom Assistenten verwendet)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Paket gekauft: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Empfohlen';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Guthaben aufgebraucht — Sitzung beendet';

  @override
  String get billingSessionTerminatedGeneric => 'Assistentensitzung beendet';

  @override
  String billingBuyForPrice(String price) {
    return 'Kaufen für €$price';
  }

  @override
  String get billingTxTypeTopup => 'Aufladung';

  @override
  String get billingTxTypeRefund => 'Rückerstattung';

  @override
  String get billingTxTypeSpend => 'Gebühr';

  @override
  String get billingUnitMinute => 'Minute';

  @override
  String get billingUnitRequest => 'Anfrage';

  @override
  String get billingUnitToken => 'Token';

  @override
  String get billingUnitTokens1k => '1K Tokens';

  @override
  String get billingUnitCall => 'Anruf';

  @override
  String get groupCallSelectParticipants => 'Teilnehmer auswählen';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Suchen';

  @override
  String get groupCallMaxReached => 'Maximal 7 Teilnehmer';

  @override
  String get groupCallLobbyTitle => 'Gruppe • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Host: $name';
  }

  @override
  String get groupCallMicHint => 'Mikrofon wird bei Verbindung aktiviert';

  @override
  String get groupCallCancel => 'Abbrechen';

  @override
  String get groupCallNoAnswer => 'Niemand hat geantwortet';

  @override
  String get groupCallEndedByHost => 'Anruf vom Host beendet';

  @override
  String get groupCallAllLeft => 'Alle haben den Anruf verlassen';

  @override
  String get groupCallEnded => 'Anruf beendet';

  @override
  String groupCallActiveTitle(int count) {
    return 'Gruppe • $count';
  }

  @override
  String get groupCallConnectionLost => 'Verbindung verloren';

  @override
  String get groupCallMuteRequested => 'Host hat alle gebeten, stummzuschalten';

  @override
  String get groupCallUnmute => 'Stummschaltung aufheben';

  @override
  String get groupCallMute => 'Stummschalten';

  @override
  String get groupCallMuteAll => 'Alle stummschalten';

  @override
  String get groupCallLeave => 'Verlassen';

  @override
  String get groupCallStatusCalling => 'ruft an…';

  @override
  String get groupCallStatusDeclined => 'abgelehnt';

  @override
  String get groupCallStatusTimeout => 'keine Antwort';

  @override
  String get groupCallStatusLeft => 'verlassen';

  @override
  String groupCallKickConfirm(String name) {
    return '$name aus dem Anruf entfernen';
  }

  @override
  String get groupCallCancelAction => 'Abbrechen';

  @override
  String get groupCallActiveBanner => 'Aktiver Anruf';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Gruppe: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Gruppe: $host';
  }

  @override
  String get groupCallCreateError => 'Anruf konnte nicht erstellt werden';

  @override
  String get groupCallJoinError => 'Anruf konnte nicht beigetreten werden';

  @override
  String get groupCallLivekitError => 'LiveKit-Fehler';

  @override
  String get groupCallDone => 'Fertig';

  @override
  String get groupCallNoResults => 'Keine Ergebnisse';

  @override
  String get groupCallNoContacts => 'Keine Kontakte';

  @override
  String get meshGcContactOffline => 'Nicht in diesem WLAN';

  @override
  String get meshGcOnlineViaMesh => 'Online über Mesh';

  @override
  String get meshGcMaxInvitees =>
      'Gruppenanrufe unterstützen bis zu 4 Eingeladene (insgesamt 5 Personen).';

  @override
  String get meshGcStart => 'Gruppenanruf starten';

  @override
  String get meshGcCancel => 'Abbrechen';

  @override
  String get meshGcStatusCalling => 'Ruft an…';

  @override
  String get meshGcStatusJoined => 'Beigetreten';

  @override
  String get meshGcStatusDeclined => 'Abgelehnt';

  @override
  String get meshGcStatusNoAnswer => 'Keine Antwort';

  @override
  String get meshGcStatusConnectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get meshGcStatusLeft => 'Verlassen';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Beenden Sie zuerst Ihren aktuellen Anruf.';

  @override
  String get presenceOnline => 'online';

  @override
  String get presenceLastSeenJustNow => 'zuletzt gesehen gerade eben';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'zuletzt gesehen vor $minutes Min.';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'zuletzt gesehen heute um $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'zuletzt gesehen gestern um $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'zuletzt gesehen am $date';
  }

  @override
  String get presenceLastSeenRecently => 'zuletzt gesehen kürzlich';

  @override
  String get privacySectionTitle => 'Datenschutz';

  @override
  String get privacyLastSeenLabel => 'Wer sieht Ihre zuletzt gesehen Zeit';

  @override
  String get privacyEveryone => 'Jeder';

  @override
  String get privacyContacts => 'Nur Kontakte';

  @override
  String get privacyNobody => 'Niemand';
}
