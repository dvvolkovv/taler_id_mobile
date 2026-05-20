// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Cerca';

  @override
  String get appSubtitle => 'Identità dell\'ecosistema unificato';

  @override
  String get login => 'Accedi';

  @override
  String get loginButton => 'Accedi';

  @override
  String get register => 'Crea Account';

  @override
  String get registerButton => 'Crea Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Conferma Password';

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Cognome';

  @override
  String get noAccount => 'Non hai un account?';

  @override
  String get createOne => 'Creane uno';

  @override
  String get haveAccount => 'Hai già un account?';

  @override
  String get signIn => 'Accedi';

  @override
  String get passwordMinLength => 'Minimo 8 caratteri';

  @override
  String get invalidEmail => 'Inserisci un\'email valida';

  @override
  String get fieldRequired => 'Campo obbligatorio';

  @override
  String get twoFATitle => 'Autenticazione a due fattori';

  @override
  String get twoFASubtitle =>
      'Inserisci il codice a 6 cifre dalla tua app di autenticazione';

  @override
  String get twoFACode => 'Codice 2FA';

  @override
  String get verify => 'Verifica';

  @override
  String get tabProfile => 'Profilo';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organizzazione';

  @override
  String get tabSettings => 'Impostazioni';

  @override
  String get profile => 'Profilo';

  @override
  String get editProfile => 'Modifica Profilo';

  @override
  String get phone => 'Telefono';

  @override
  String get country => 'Paese';

  @override
  String get dateOfBirth => 'Data di Nascita';

  @override
  String get documents => 'Documenti';

  @override
  String get addDocument => 'Aggiungi Documento';

  @override
  String get noDocuments => 'Nessun documento caricato';

  @override
  String get save => 'Salva';

  @override
  String get profileUpdated => 'Profilo aggiornato';

  @override
  String get personalData => 'Dati Personali';

  @override
  String get passport => 'Passaporto';

  @override
  String get drivingLicense => 'Patente di Guida';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'Carta d\'identità';

  @override
  String get certificate => 'Certificato';

  @override
  String get notSpecified => 'Non specificato';

  @override
  String get notSpecifiedFemale => 'Non specificato';

  @override
  String get documentType => 'Tipo di documento';

  @override
  String get passportId => 'Passaporto / Carta d\'identità';

  @override
  String get diplomaCertificate => 'Diploma / Certificato';

  @override
  String get loadError => 'Errore di caricamento';

  @override
  String get verification => 'Verifica';

  @override
  String get countryAustria => 'Austria';

  @override
  String get countryGermany => 'Germania';

  @override
  String get countryRussia => 'Russia';

  @override
  String get countryUkraine => 'Ucraina';

  @override
  String get countryKazakhstan => 'Kazakistan';

  @override
  String get countryBelarus => 'Bielorussia';

  @override
  String get countryOther => 'Altro';

  @override
  String get kycTitle => 'Verifica KYC';

  @override
  String get kycVerified => 'Verificato';

  @override
  String get kycPending => 'In sospeso';

  @override
  String get kycRejected => 'Rifiutato';

  @override
  String get kycUnverified => 'Non verificato';

  @override
  String get kycVerifiedDesc =>
      'La tua identità è stata verificata. Hai pieno accesso a tutte le funzionalità dell\'ecosistema Taler.';

  @override
  String get kycPendingDesc =>
      'I tuoi documenti sono in fase di revisione. Di solito richiede 1-2 giorni lavorativi.';

  @override
  String get kycRejectedDesc =>
      'Verifica fallita. Si prega di controllare il motivo e reinviare i documenti.';

  @override
  String get kycUnverifiedDesc =>
      'Completa la verifica per sbloccare l\'accesso completo alle funzionalità finanziarie dell\'ecosistema Taler.';

  @override
  String get startVerification => 'Inizia la verifica';

  @override
  String get retryVerification => 'Riprova la verifica';

  @override
  String verifiedAt(String date) {
    return 'Verificato: $date';
  }

  @override
  String get documentsSubmitted => 'Documenti inviati per la revisione';

  @override
  String get documentsSubmittedDesc =>
      'La revisione di solito richiede 1-2 giorni lavorativi. Riceverai una notifica push con il risultato.';

  @override
  String get securityAes =>
      'I tuoi dati sono protetti con crittografia AES-256';

  @override
  String get verificationTime => 'La verifica richiede 1-2 giorni lavorativi';

  @override
  String get pushNotification => 'Riceverai una notifica push con il risultato';

  @override
  String get kycWebOnly =>
      'La verifica KYC è disponibile solo nell\'app mobile.';

  @override
  String verificationError(String code) {
    return 'Errore di verifica: $code';
  }

  @override
  String get organizations => 'Organizzazioni';

  @override
  String get noOrganizations => 'Nessuna organizzazione';

  @override
  String get noOrganizationsDesc =>
      'Crea un\'organizzazione o accetta un invito';

  @override
  String get createOrganization => 'Crea organizzazione';

  @override
  String get newOrganization => 'Nuova Organizzazione';

  @override
  String get orgName => 'Nome *';

  @override
  String get orgDescription => 'Descrizione';

  @override
  String get orgEmail => 'Email di Contatto';

  @override
  String get orgWebsite => 'Sito Web';

  @override
  String get orgLegalAddress => 'Indirizzo Legale';

  @override
  String get create => 'Crea';

  @override
  String get organization => 'Organizzazione';

  @override
  String get contacts => 'Contatti';

  @override
  String members(int count) {
    return 'Membri ($count)';
  }

  @override
  String get inviteMember => 'Invita Membro';

  @override
  String get invite => 'Invita';

  @override
  String get sendInvite => 'Invia Invito';

  @override
  String inviteSent(String email) {
    return 'Invito inviato a $email';
  }

  @override
  String get role => 'Ruolo';

  @override
  String get roleOwner => 'Proprietario';

  @override
  String get roleAdmin => 'Amministratore';

  @override
  String get roleOperator => 'Operatore';

  @override
  String get roleViewer => 'Visualizzatore';

  @override
  String get editOrganization => 'Modifica';

  @override
  String get editOrganizationTitle => 'Modifica Organizzazione';

  @override
  String get removeMember => 'Rimuovi Membro';

  @override
  String removeMemberConfirm(String name) {
    return 'Rimuovere $name dall\'organizzazione?';
  }

  @override
  String get memberRemoved => 'Membro rimosso';

  @override
  String get roleChanged => 'Ruolo modificato';

  @override
  String get kybVerified => 'Verificato';

  @override
  String get kybPending => 'In attesa';

  @override
  String get kybRejected => 'Rifiutato';

  @override
  String get kybNone => 'Non verificato';

  @override
  String get kybVerification => 'Inizia Verifica KYB';

  @override
  String get kybStartBusiness => 'Inizia Verifica Aziendale';

  @override
  String get kybStatusLabel => 'Stato KYB';

  @override
  String get noKyb => 'Nessun KYB';

  @override
  String get kybBusinessVerificationTitle => 'Verifica Aziendale (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organizzazione verificata con successo.';

  @override
  String get kybPendingOrgDesc =>
      'I documenti sono in fase di revisione. Di solito richiede 1-3 giorni lavorativi.';

  @override
  String get kybRejectedOrgDesc => 'Verifica fallita. Per favore riprova.';

  @override
  String get kybNoneOrgDesc =>
      'Verifica la tua organizzazione per accedere alle funzionalità aziendali.';

  @override
  String get invitePlus => '+ Invita';

  @override
  String get kybVerificationTitle => 'Verifica KYB';

  @override
  String get kybWebOnlyBusiness =>
      'La verifica KYB è disponibile solo nell\'app mobile.';

  @override
  String get unknownDevice => 'Dispositivo sconosciuto';

  @override
  String get ipUnknown => 'IP sconosciuto';

  @override
  String get currentSessionLabel => 'Corrente';

  @override
  String get endSessionAction => 'Termina';

  @override
  String get deviceLoggedOut => 'Il dispositivo verrà disconnesso.';

  @override
  String get acceptInvitationTitle => 'Invito Organizzazione';

  @override
  String get acceptInvitation => 'Accetta Invito';

  @override
  String get acceptInvitationDesc =>
      'Sei stato invitato a unirti a un\'organizzazione nell\'ecosistema Taler.';

  @override
  String get accept => 'Accetta';

  @override
  String get reject => 'Rifiuta';

  @override
  String get sessions => 'Sessioni Attive';

  @override
  String get currentSession => 'Sessione corrente';

  @override
  String get deleteSession => 'Termina Sessione';

  @override
  String get deleteSessionConfirm => 'Terminare questa sessione?';

  @override
  String get sessionDeleted => 'Sessione terminata';

  @override
  String get noSessions => 'Nessuna sessione attiva';

  @override
  String minutesAgo(int count) {
    return '$count min fa';
  }

  @override
  String hoursAgo(int count) {
    return '$count hr fa';
  }

  @override
  String daysAgo(int count) {
    return '$count giorni fa';
  }

  @override
  String get justNow => 'Proprio ora';

  @override
  String get settings => 'Impostazioni';

  @override
  String get security => 'Sicurezza';

  @override
  String get biometrics => 'Biometria';

  @override
  String get biometricsDesc => 'Accesso rapido con Face ID o impronta digitale';

  @override
  String get biometricsConfirm =>
      'Conferma biometria per abilitare l\'accesso rapido';

  @override
  String get biometricsError =>
      'Impossibile abilitare la biometria. Controlla le impostazioni del dispositivo.';

  @override
  String get changePassword => 'Cambia Password';

  @override
  String get twoFactorAuth => 'Autenticazione a Due Fattori';

  @override
  String get currentPassword => 'Password Attuale';

  @override
  String get newPassword => 'Nuova Password';

  @override
  String get confirmNewPassword => 'Conferma Nuova Password';

  @override
  String get passwordChanged => 'Password cambiata';

  @override
  String get wrongCurrentPassword => 'Password attuale errata';

  @override
  String get passwordTooWeak =>
      'Password troppo debole: almeno 8 caratteri, richiesta lettera e cifra';

  @override
  String get passwordChangeFailed => 'Impossibile cambiare la password';

  @override
  String get notifications => 'Notifiche';

  @override
  String get permissions => 'Permessi';

  @override
  String get permissionNotifications => 'Notifiche Push';

  @override
  String get permissionNotificationsDesc => 'Chiamate, messaggi, stati';

  @override
  String get permissionMicrophone => 'Microfono';

  @override
  String get permissionMicrophoneDesc => 'Chiamate e assistente vocale';

  @override
  String get permissionCamera => 'Fotocamera';

  @override
  String get permissionCameraDesc => 'Videochiamate e verifica';

  @override
  String get permissionLocation => 'Posizione';

  @override
  String get permissionLocationDesc => 'Utilizzato per la verifica';

  @override
  String get permissionOpenSettings =>
      'Per revocare un permesso, apri le impostazioni di sistema';

  @override
  String get pushKycStatus => 'Stato KYC Push';

  @override
  String get pushKycStatusDesc => 'Risultato della verifica';

  @override
  String get pushLogins => 'Accesso Push';

  @override
  String get pushLoginsDesc => 'Quando accedi da un nuovo dispositivo';

  @override
  String get account => 'Account';

  @override
  String get language => 'Lingua';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Lingua dell\'interfaccia';

  @override
  String get exportData => 'Esporta Dati (GDPR)';

  @override
  String get deleteAccount => 'Elimina Account';

  @override
  String get deleteAccountConfirm => 'Eliminare l\'account?';

  @override
  String get deleteAccountDesc =>
      'Tutti i tuoi dati saranno eliminati (GDPR). Questa azione è irreversibile.';

  @override
  String get logout => 'Disconnetti';

  @override
  String get logoutConfirm => 'Disconnettersi?';

  @override
  String get logoutDesc =>
      'Sarai disconnesso da Taler ID su questo dispositivo.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Codice PIN';

  @override
  String get pinCodeDesc => 'Accesso rapido con codice a 4 cifre';

  @override
  String get setupPin => 'Imposta PIN';

  @override
  String get enterPin => 'Inserisci PIN';

  @override
  String get confirmPin => 'Conferma PIN';

  @override
  String get pinMismatch => 'I PIN non corrispondono';

  @override
  String get pinSet => 'PIN impostato con successo';

  @override
  String get enterPinToLogin => 'Inserisci PIN per accedere';

  @override
  String get pinIncorrect => 'PIN errato';

  @override
  String get removePin => 'Rimuovi PIN';

  @override
  String get pinRemoved => 'PIN rimosso';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Riprova';

  @override
  String get loading => 'Caricamento...';

  @override
  String get error => 'Errore';

  @override
  String get success => 'Successo';

  @override
  String get noData => 'Nessun dato';

  @override
  String get failedToLoad => 'Impossibile caricare i dati';

  @override
  String get failedToLoadProfile => 'Impossibile caricare il profilo';

  @override
  String get failedToSave => 'Impossibile salvare le modifiche';

  @override
  String get failedToLoadOrgs => 'Impossibile caricare le organizzazioni';

  @override
  String get failedToLoadOrg =>
      'Impossibile caricare i dati dell\'organizzazione';

  @override
  String get failedToCreateOrg => 'Impossibile creare l\'organizzazione';

  @override
  String get failedToInvite => 'Impossibile inviare l\'invito';

  @override
  String get failedToAcceptInvite => 'Impossibile accettare l\'invito';

  @override
  String get failedToLoadSessions => 'Impossibile caricare le sessioni';

  @override
  String get failedToDeleteSession => 'Impossibile terminare la sessione';

  @override
  String get failedToLoadKyc => 'Impossibile caricare lo stato di verifica';

  @override
  String get failedToStartKyc => 'Impossibile avviare la verifica';

  @override
  String get verifiedPersonalInfo => 'Dati verificati';

  @override
  String get middleName => 'Secondo Nome';

  @override
  String get placeOfBirth => 'Luogo di Nascita';

  @override
  String get nationality => 'Nazionalità';

  @override
  String get gender => 'Genere';

  @override
  String get genderMale => 'Maschio';

  @override
  String get genderFemale => 'Femmina';

  @override
  String get docNumber => 'Numero';

  @override
  String get docIssuedDate => 'Rilasciato';

  @override
  String get docValidUntil => 'Valido Fino a';

  @override
  String get docIssuedBy => 'Rilasciato Da';

  @override
  String get address => 'Indirizzo';

  @override
  String get refreshData => 'Aggiorna Dati';

  @override
  String get failedToLoadSumsubData =>
      'Impossibile caricare i dati di verifica';

  @override
  String get sumsubDataLoading => 'Caricamento dei dati di verifica...';

  @override
  String get reviewResultGreen => 'Verifica superata';

  @override
  String get reviewResultRed => 'Verifica fallita';

  @override
  String get tabAssistant => 'Assistente';

  @override
  String get assistantConnecting => 'Connessione…';

  @override
  String get assistantSpeaking => 'Parlando…';

  @override
  String get assistantListening => 'Ascoltando…';

  @override
  String get assistantTapToStart => 'Tocca per iniziare';

  @override
  String get assistantTapToTalk => 'Tocca per parlare con l\'AI';

  @override
  String get assistantRealtimeDesc =>
      'L\'assistente risponde con voce in tempo reale';

  @override
  String get assistantConnectingToAssistant => 'Connessione all\'assistente...';

  @override
  String get assistantAiSpeaking => 'AI in conversazione...';

  @override
  String get assistantAiListening => 'AI in ascolto';

  @override
  String get assistantSpeakerOn => 'Altoparlante attivo';

  @override
  String get assistantSpeaker => 'Altoparlante';

  @override
  String get assistantEnd => 'Fine';

  @override
  String get assistantUnmute => 'Riattiva audio';

  @override
  String get assistantMicrophone => 'Microfono';

  @override
  String get assistantConnectionError => 'Errore di connessione';

  @override
  String get tabMessenger => 'Messaggi';

  @override
  String get tabCalls => 'Chiamate';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get appearance => 'Aspetto';

  @override
  String get appearanceSelect => 'Scegli tema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get onboardingTitle1 => 'Identità Unificata';

  @override
  String get onboardingDesc1 =>
      'Taler ID è il tuo passaporto digitale nell\'ecosistema Taler. Un account per tutti i servizi.';

  @override
  String get onboardingTitle2 => 'Sicurezza dei Dati';

  @override
  String get onboardingDesc2 =>
      'Verifica KYC, crittografia AES-256 e autenticazione a due fattori proteggono la tua identità.';

  @override
  String get onboardingTitle3 => 'Rimani Informato';

  @override
  String get onboardingDesc3 =>
      'Ricevi notifiche sullo stato della verifica, accessi da nuovi dispositivi e chiamate in arrivo.';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingEnableNotifications => 'Abilita notifiche';

  @override
  String get onboardingTitle4 => 'Chiamate Vocali';

  @override
  String get onboardingDesc4 =>
      'Concedi l\'accesso al microfono per le chiamate vocali e l\'assistente AI. Puoi modificare questa impostazione in seguito.';

  @override
  String get onboardingEnableMicrophone => 'Abilita microfono';

  @override
  String get onboardingStart => 'Inizia';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get meshLocalNetworkPromptTitle => 'Consenti accesso alla rete locale';

  @override
  String get meshLocalNetworkPromptBody =>
      'Per trovare i peer su Wi-Fi (chiamate di gruppo offline), iOS richiede il permesso di Rete Locale. Apri Impostazioni → Privacy e Sicurezza → Rete Locale → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Apri Impostazioni';

  @override
  String get meshLocalNetworkPromptDismiss => 'Capito';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get forgotPasswordTitle => 'Reimposta Password';

  @override
  String get forgotPasswordSubtitle =>
      'Inserisci la tua email per ricevere un codice di reimpostazione';

  @override
  String resetCodeSent(String email) {
    return 'Codice inviato a $email';
  }

  @override
  String get enterResetCode => 'Inserisci il codice';

  @override
  String get resetPasswordButton => 'Reimposta Password';

  @override
  String get passwordResetSuccess => 'Password reimpostata con successo';

  @override
  String get sendCode => 'Invia codice';

  @override
  String get resendCode => 'Reinvia codice';

  @override
  String get newGroup => 'Nuovo gruppo';

  @override
  String get newChat => 'Nuova chat';

  @override
  String get groupName => 'Nome del gruppo';

  @override
  String get createGroup => 'Crea gruppo';

  @override
  String get groupInfo => 'Informazioni sul gruppo';

  @override
  String groupMembers(int count) {
    return 'Membri ($count)';
  }

  @override
  String get addMembers => 'Aggiungi membri';

  @override
  String get leaveGroup => 'Lascia il gruppo';

  @override
  String get leaveGroupConfirm => 'Lasciare questo gruppo?';

  @override
  String get deleteGroup => 'Elimina gruppo';

  @override
  String get deleteGroupConfirm =>
      'Eliminare questo gruppo? Questa azione non può essere annullata.';

  @override
  String get groupRoleOwner => 'Proprietario';

  @override
  String get groupRoleAdmin => 'Amministratore';

  @override
  String get groupRoleMember => 'Membro';

  @override
  String get selectParticipants => 'Seleziona partecipanti';

  @override
  String selectedCount(int count) {
    return '$count selezionati';
  }

  @override
  String get changeRole => 'Cambia ruolo';

  @override
  String get groupCreated => 'Gruppo creato';

  @override
  String memberJoined(String name) {
    return '$name si è unito';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name ha lasciato';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name è stato rimosso';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name è ora $role';
  }

  @override
  String participantsCount(int count) {
    return '$count partecipanti';
  }

  @override
  String get enterGroupName => 'Inserisci il nome del gruppo';

  @override
  String get muteNotifications => 'Disattiva notifiche';

  @override
  String get unmuteNotifications => 'Attiva notifiche';

  @override
  String get muteFor1Hour => 'Per 1 ora';

  @override
  String get muteFor8Hours => 'Per 8 ore';

  @override
  String get muteFor2Days => 'Per 2 giorni';

  @override
  String get muteForever => 'Per sempre';

  @override
  String get muted => 'Disattivato';

  @override
  String get tabTranslator => 'Traduci';

  @override
  String get translatorTitle => 'Traduttore';

  @override
  String get translatorSelectLanguage => 'Seleziona lingua';

  @override
  String get translatorDownloading => 'Scaricamento dei modelli di lingua...';

  @override
  String get translatorDownloadingHint =>
      'Internet è necessario solo per il primo download';

  @override
  String get translatorTypeHint => 'Digita il testo o tocca il microfono';

  @override
  String get translatorListening => 'Ascoltando...';

  @override
  String get translatorTapToSpeak => 'Tocca per parlare';

  @override
  String get translatorTapToStop => 'Tocca per fermare';

  @override
  String get translatorAutoSpeak => 'Parla automaticamente';

  @override
  String get translatorCopied => 'Copiato';

  @override
  String get translatorLangRu => 'Russo';

  @override
  String get translatorLangEn => 'Inglese';

  @override
  String get translatorLangDe => 'Tedesco';

  @override
  String get translatorLangFr => 'Francese';

  @override
  String get translatorLangEs => 'Spagnolo';

  @override
  String get translatorLangIt => 'Italiano';

  @override
  String get translatorLangPt => 'Portoghese';

  @override
  String get translatorLangTr => 'Turco';

  @override
  String get translatorLangZh => 'Cinese';

  @override
  String get translatorLangJa => 'Giapponese';

  @override
  String get translatorLangKo => 'Coreano';

  @override
  String get translatorLangAr => 'Arabo';

  @override
  String get translatorLangPl => 'Polacco';

  @override
  String get translatorLangSk => 'Slovacco';

  @override
  String get translatorLangCs => 'Ceco';

  @override
  String get translatorLangNl => 'Olandese';

  @override
  String get translatorLangSv => 'Svedese';

  @override
  String get translatorLangDa => 'Danese';

  @override
  String get translatorLangNo => 'Norvegese';

  @override
  String get translatorLangFi => 'Finlandese';

  @override
  String get translatorLangUk => 'Ucraino';

  @override
  String get translatorLangEl => 'Greco';

  @override
  String get translatorLangRo => 'Rumeno';

  @override
  String get translatorLangHu => 'Ungherese';

  @override
  String get translatorLangBg => 'Bulgaro';

  @override
  String get translatorLangHr => 'Croato';

  @override
  String get translatorLangSr => 'Serbo';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Thailandese';

  @override
  String get translatorLangVi => 'Vietnamita';

  @override
  String get translatorLangId => 'Indonesiano';

  @override
  String get translatorLangMs => 'Malese';

  @override
  String get translatorLangHe => 'Ebraico';

  @override
  String get translatorLangFa => 'Persiano';

  @override
  String get callInProgress => 'Chiamata in corso';

  @override
  String get joinCall => 'Partecipa';

  @override
  String get createCallLink => 'Link chiamata';

  @override
  String get callLinkCopied => 'Link copiato';

  @override
  String get callLinkTitle => 'Link stanza';

  @override
  String get connectionUnstable =>
      'Connessione instabile — controlla la tua connessione internet';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get errorTimeout =>
      'Connessione scaduta. Controlla la tua connessione internet.';

  @override
  String get errorNoConnection => 'Nessuna connessione internet.';

  @override
  String get errorGeneral => 'Si è verificato un errore. Riprova.';

  @override
  String errorWithMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get notifChannelMessages => 'Messaggi';

  @override
  String get notifChannelMessagesDesc => 'Notifiche nuovi messaggi';

  @override
  String get notifChannelMissedCalls => 'Chiamate perse';

  @override
  String get notifChannelMissedCallsDesc => 'Notifiche chiamate perse';

  @override
  String get notifMissedCall => 'Chiamata persa';

  @override
  String get notifAccept => 'Accetta';

  @override
  String get notifDecline => 'Rifiuta';

  @override
  String get notifIncomingCall => 'Chiamata in arrivo';

  @override
  String get notifIncomingCallChannel => 'Chiamata in arrivo';

  @override
  String get notifMissedCallChannel => 'Chiamata persa';

  @override
  String get notifUnknown => 'Sconosciuto';

  @override
  String get effectNone => 'Nessuno sfondo';

  @override
  String get effectBlur => 'Sfocatura';

  @override
  String get effectOffice => 'Ufficio';

  @override
  String get effectNature => 'Natura';

  @override
  String get effectGradient => 'Gradiente';

  @override
  String get effectLibrary => 'Libreria';

  @override
  String get effectCity => 'Città';

  @override
  String get effectMinimalism => 'Minimalismo';

  @override
  String get voiceParticipant => 'Partecipante';

  @override
  String get voiceInvitesToRoom => 'ti invita nella stanza';

  @override
  String get voiceRoom => 'Stanza';

  @override
  String get voicePasswordProtected => 'Protetto da password';

  @override
  String get voicePasswordHint => 'Password';

  @override
  String get voiceEnter => 'Entra';

  @override
  String get voiceJoinRoom => 'Entra nella stanza';

  @override
  String get voiceYourName => 'Il tuo nome';

  @override
  String voiceInvitationSent(String name) {
    return 'Invito inviato a $name';
  }

  @override
  String get voiceNoActiveRoom => 'Nessuna stanza attiva';

  @override
  String get voiceCameraPermission =>
      'Consenti l\'accesso alla fotocamera in Impostazioni → Privacy → Fotocamera → TalerID';

  @override
  String get voiceOpenSettings => 'Apri';

  @override
  String voiceCameraError(String error) {
    return 'Impossibile abilitare la fotocamera: $error';
  }

  @override
  String get voiceAllAgreedRecording =>
      'Tutti d\'accordo. Registrazione avviata.';

  @override
  String get voiceNewParticipantAgreed =>
      'Nuovo partecipante ha accettato la registrazione.';

  @override
  String get voiceDeclinedRecording =>
      'Hai rifiutato la registrazione. Uscita dalla chiamata.';

  @override
  String get voiceRecordingEnded => 'Registrazione terminata';

  @override
  String get voiceRecordingInProgress => 'Registrazione in corso';

  @override
  String get voiceTranscriptionRequest => 'Richiesta di trascrizione';

  @override
  String get voiceRecordingRequest => 'Richiesta di registrazione';

  @override
  String get voiceAgree => 'Accetta';

  @override
  String get voiceDeclineAndLeave => 'Rifiuta e lascia';

  @override
  String get voiceAudioOutput => 'Uscita audio';

  @override
  String get voiceAudioPhone => 'Telefono';

  @override
  String get voiceAudioSpeaker => 'Altoparlante';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Cuffie';

  @override
  String get voiceLinkCopied => 'Link copiato';

  @override
  String get voiceTranslateTo => 'Traduci in';

  @override
  String get voiceSearchLanguage => 'Cerca lingua...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Stanza $name';
  }

  @override
  String get voiceVoiceCall => 'Chiamata vocale';

  @override
  String get voiceOnHold => 'In attesa';

  @override
  String get voiceActiveCall => 'Attiva';

  @override
  String get voiceEndAllCalls => 'Termina tutte le chiamate';

  @override
  String get voiceEndThisCall => 'Termina questa chiamata';

  @override
  String get voiceCopyLink => 'Copia link';

  @override
  String get voiceAddParticipant => 'Aggiungi partecipante';

  @override
  String get voiceReconnecting => 'Riconnessione...';

  @override
  String get voiceConnectionError => 'Errore di connessione';

  @override
  String get voiceClose => 'Chiudi';

  @override
  String get voiceCalling => 'Chiamata in corso...';

  @override
  String get voiceCallActive => 'Chiamata attiva';

  @override
  String get voiceWaiting => 'In attesa';

  @override
  String get voiceWaitingUpper => 'IN ATTESA';

  @override
  String get voiceRec => 'REC';

  @override
  String get voiceStop => 'Ferma';

  @override
  String get voiceRecord => 'Registrazione';

  @override
  String get voiceTranslation => 'Traduzione';

  @override
  String get voiceAudio => 'Audio';

  @override
  String get voiceFlipCamera => 'Inverti';

  @override
  String get voiceBackground => 'Sfondo';

  @override
  String get voiceAssistantSpeakingStatus => 'Assistente sta parlando...';

  @override
  String get voiceAssistantListeningStatus => 'Assistente in ascolto...';

  @override
  String get voiceUnmute => 'Riattiva audio';

  @override
  String get voiceMic => 'Microfono';

  @override
  String get voiceAssistantLabel => 'Assistente';

  @override
  String get voiceCameraOn => 'Fotocamera attiva';

  @override
  String get voiceCameraLabel => 'Fotocamera';

  @override
  String get voiceEndCall => 'Termina chiamata';

  @override
  String get voiceWaitingParticipants => 'In attesa dei partecipanti...';

  @override
  String get voiceYou => 'Tu';

  @override
  String get voiceAiAssistant => 'Assistente AI';

  @override
  String get voiceVideoUnavailable => 'Video non disponibile';

  @override
  String get voiceSearchNickname => 'Cerca per soprannome...';

  @override
  String get voiceTranscriptionWord => 'trascrizione';

  @override
  String get voiceRecordingWord => 'registrazione';

  @override
  String get voiceConnecting => 'Connessione in corso...';

  @override
  String get voiceVideoBackground => 'Sfondo video';

  @override
  String get voiceCallSettings => 'Impostazioni chiamata';

  @override
  String get voiceEnableAI => 'Abilita assistente AI';

  @override
  String get voiceAIParticipating => 'AI parteciperà alla conversazione';

  @override
  String get voiceNormalCall => 'Chiamata normale senza AI';

  @override
  String get voiceCallConfirm => 'Effettuare una chiamata?';

  @override
  String get chatAlreadyInCall => 'Già in chiamata';

  @override
  String chatCallError(String error) {
    return 'Errore chiamata: $error';
  }

  @override
  String get chatPhotoVideo => 'Foto / Video';

  @override
  String get chatCamera => 'Fotocamera';

  @override
  String get chatFile => 'File';

  @override
  String get chatContact => 'Contatto';

  @override
  String get chatSelectContact => 'Seleziona un contatto';

  @override
  String get chatNoContacts => 'Nessun contatto';

  @override
  String get chatUser => 'Utente';

  @override
  String get chatFileAttachment => '📎 File';

  @override
  String chatFileUploadError(String error) {
    return 'Errore caricamento file: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Messaggio vocale';

  @override
  String get chatGroup => 'Gruppo';

  @override
  String get chatDialog => 'Dialogo';

  @override
  String get chatCall => 'Chiamata';

  @override
  String get chatStartConversation => 'Inizia una conversazione';

  @override
  String get chatYou => 'Tu';

  @override
  String get chatIsTyping => 'sta scrivendo...';

  @override
  String chatUserIsTyping(String name) {
    return '$name sta scrivendo...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names stanno scrivendo...';
  }

  @override
  String get chatPreparingFile => 'Preparazione del file…';

  @override
  String chatUploading(int progress) {
    return 'Caricamento… $progress%';
  }

  @override
  String get chatEdited => 'Modificato';

  @override
  String get chatViaMesh => 'via mesh';

  @override
  String get chatReply => 'Rispondi';

  @override
  String get chatEdit => 'Modifica';

  @override
  String get chatCopy => 'Copia';

  @override
  String get chatCopied => 'Copiato';

  @override
  String get chatSaveMedia => 'Salva';

  @override
  String get chatForward => 'Inoltra';

  @override
  String get chatSaving => 'Salvataggio...';

  @override
  String get chatSavedToGallery => 'Salvato nella galleria';

  @override
  String get chatNoSavePermission =>
      'Nessun permesso per salvare. Controlla le impostazioni.';

  @override
  String get chatFileSaveError => 'Errore nel salvataggio del file';

  @override
  String get chatDeleteMessage => 'Elimina messaggio';

  @override
  String get chatDeleteForMe => 'Elimina per me';

  @override
  String get chatDeleteForEveryone => 'Elimina per tutti';

  @override
  String get chatMessageForwarded => 'Messaggio inoltrato';

  @override
  String get chatContactTapToOpen => 'Contatto · tocca per aprire';

  @override
  String get chatForwardTo => 'Inoltra a...';

  @override
  String get chatSearchHint => 'Cerca...';

  @override
  String get chatRecording => 'Registrazione...';

  @override
  String get chatMessageHint => 'Messaggio...';

  @override
  String get chatHideKeyboard => 'Nascondi tastiera';

  @override
  String get chatEditing => 'Modifica in corso';

  @override
  String get chatFileDownloadError => 'Errore nel download del file';

  @override
  String get chatVoiceMessageShort => 'Messaggio vocale';

  @override
  String get chatVideoSavedToGallery => 'Video salvato nella galleria';

  @override
  String get chatSavingError => 'Errore di salvataggio';

  @override
  String get convSetNickname => 'Imposta un nickname';

  @override
  String get convNicknameRequired =>
      'È richiesto un nickname per usare il messenger. Gli altri utenti possono trovarti tramite esso.';

  @override
  String get convNicknameRules => '3–30 caratteri: lettere, cifre, _';

  @override
  String get convNicknameTaken => 'Nickname già in uso';

  @override
  String get convSaveError => 'Errore di salvataggio';

  @override
  String get convContactsLabel => 'Contatti';

  @override
  String get convDefaultUser => 'Utente';

  @override
  String get convNoDialogs => 'Nessuna conversazione';

  @override
  String get convFindUserToChat => 'Trova un utente per iniziare a chattare';

  @override
  String get convDefaultContact => 'Contatto';

  @override
  String get dashboardUser => 'Utente';

  @override
  String get dashboardIncomingCall => 'Chiamata in arrivo';

  @override
  String get dashboardDecline => 'Rifiuta';

  @override
  String get dashboardAccept => 'Accetta';

  @override
  String get dashboardActiveCall => 'Chiamata attiva — tocca per tornare';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Aggiornamento disponibile $version';
  }

  @override
  String get dashboardUpdate => 'Aggiorna';

  @override
  String get dashboardWhatsNew => 'Novità';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Novità in $version';
  }

  @override
  String get dashboardInstalling => 'Installazione in corso...';

  @override
  String get contactRequestsTitle => 'Contatti';

  @override
  String get messengerContactRequestsSection => 'Richieste di contatto';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuove richieste',
      one: '1 nuova richiesta',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Cerca';

  @override
  String get contactRequestsIncoming => 'In arrivo';

  @override
  String get contactRequestsSent => 'Inviate';

  @override
  String get contactRequestsSearchHint => 'Nickname o email';

  @override
  String get contactRequestSent => 'Richiesta inviata';

  @override
  String get contactRequestsNoUsers => 'Nessun utente trovato';

  @override
  String get contactRequestsSearchHelp =>
      'Inserisci nickname o email esatti\ne premi cerca';

  @override
  String get contactRequestsSendTooltip => 'Invia richiesta';

  @override
  String get contactRequestTitle => 'Richiesta di contatto';

  @override
  String contactRequestConfirm(String name) {
    return 'Inviare richiesta di contatto a $name?';
  }

  @override
  String get contactRequestSend => 'Invia';

  @override
  String get contactRequestsNoIncoming => 'Nessuna richiesta in arrivo';

  @override
  String get contactRequestsNoSent => 'Nessuna richiesta inviata';

  @override
  String get contactRequestStatusPending => 'In attesa di risposta';

  @override
  String get contactRequestStatusAccepted => 'Accettata';

  @override
  String get contactRequestStatusRejected => 'Rifiutata';

  @override
  String get userSearchTitle => 'Trova utente';

  @override
  String get userSearchHint => 'Nickname, telefono o email';

  @override
  String get userSearchHelper =>
      'Inserisci @nickname, email o nome per cercare';

  @override
  String get userSearchNoUsers => 'Nessun utente trovato';

  @override
  String get userProfileShareContact => 'Condividi contatto';

  @override
  String get userProfileShareContactDesc => 'Invia link del contatto';

  @override
  String get userProfileCopyLink => 'Copia link';

  @override
  String get userProfileCopied => 'Copiato';

  @override
  String get userProfileTitle => 'Profilo';

  @override
  String get userProfileLoadError => 'Errore nel caricamento del profilo';

  @override
  String get userProfileMessage => 'Messaggio';

  @override
  String get userProfileCall => 'Chiamata';

  @override
  String get userProfileRequestSent => 'Richiesta inviata';

  @override
  String get userProfileAccept => 'Accetta';

  @override
  String get userProfileDecline => 'Rifiuta';

  @override
  String get userProfileAddToContacts => 'Aggiungi ai contatti';

  @override
  String get userProfileMediaTab => 'Media';

  @override
  String get userProfileFilesTab => 'File';

  @override
  String get userProfileLinksTab => 'Link';

  @override
  String get userProfileRecordingsTab => 'Registrazioni';

  @override
  String get userProfileSummariesTab => 'Riepiloghi';

  @override
  String get userProfileNoMedia => 'Nessun file multimediale';

  @override
  String get userProfileNoFiles => 'Nessun file';

  @override
  String get userProfileNoLinks => 'Nessun link';

  @override
  String get userProfileNoRecordings => 'Nessuna registrazione';

  @override
  String get userProfileNoSummaries => 'Nessun riepilogo';

  @override
  String get userProfileMeetingSummary => 'Riepilogo riunione';

  @override
  String get userProfileFailedOpenChat => 'Impossibile aprire la chat';

  @override
  String get sharedMediaTitle => 'Media e file';

  @override
  String get sharedMediaTab => 'Media';

  @override
  String get sharedFilesTab => 'File';

  @override
  String get sharedLinksTab => 'Link';

  @override
  String get sharedNoMedia => 'Nessun file multimediale';

  @override
  String get sharedNoFiles => 'Nessun file';

  @override
  String get sharedNoLinks => 'Nessun link';

  @override
  String get shareToChat => 'Inoltra alla chat';

  @override
  String get shareSelectChat => 'Seleziona chat';

  @override
  String get shareNoChats => 'Nessuna chat';

  @override
  String shareFilesCount(int count) {
    return '$count file';
  }

  @override
  String get contactsTitle => 'Contatti';

  @override
  String get contactsAddTooltip => 'Aggiungi contatto';

  @override
  String get contactsSearchHint => 'Cerca contatti...';

  @override
  String get contactsNotFound => 'Nessun risultato';

  @override
  String get contactsEmpty => 'Nessun contatto';

  @override
  String get contactsAdd => 'Aggiungi contatto';

  @override
  String get contactsPendingConfirmation => 'In attesa di conferma';

  @override
  String get contactsMessage => 'Messaggio';

  @override
  String get contactsCall => 'Chiamata';

  @override
  String get contactsResend => 'Reinvia richiesta';

  @override
  String get contactsResendTimeout => 'Riprova tra 24h';

  @override
  String get contactsResent => 'Richiesta reinviata';

  @override
  String get contactsWantsToConnect => 'Vuole connettersi con te';

  @override
  String get contactsSearchPeople => 'Trova persone';

  @override
  String get notesTitle => 'Note';

  @override
  String get notesAssistantSpeaking => 'Assistente che parla...';

  @override
  String get notesListening => 'Ascoltando...';

  @override
  String get notesEmpty => 'Nessuna nota';

  @override
  String get notesEmptyHint =>
      'Premi il microfono per dettare\no + per inserire manualmente';

  @override
  String get notesDeleteConfirm => 'Eliminare la nota?';

  @override
  String get notesNew => 'Nuova nota';

  @override
  String get notesEdit => 'Modifica';

  @override
  String get notesTitleHint => 'Titolo';

  @override
  String get notesContentHint => 'Scrivi i tuoi pensieri...';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get calendarStop => 'Ferma';

  @override
  String get calendarVoiceInput => 'Input vocale';

  @override
  String get calendarNewEvent => 'Nuovo evento';

  @override
  String get calendarAssistantSpeaking => 'Assistente che parla...';

  @override
  String get calendarListening => 'Ascoltando...';

  @override
  String calendarInvitations(int count) {
    return 'Inviti ($count)';
  }

  @override
  String get calendarNoEvents => 'Nessun evento';

  @override
  String get calendarDayMon => 'Lun';

  @override
  String get calendarDayTue => 'Mar';

  @override
  String get calendarDayWed => 'Mer';

  @override
  String get calendarDayThu => 'Gio';

  @override
  String get calendarDayFri => 'Ven';

  @override
  String get calendarDaySat => 'Sab';

  @override
  String get calendarDaySun => 'Dom';

  @override
  String get calendarEnterRoom => 'Entra nella stanza';

  @override
  String get calendarMeeting => 'Riunione';

  @override
  String calendarLocationPrefix(String location) {
    return 'Luogo: $location';
  }

  @override
  String get calendarEditEvent => 'Modifica';

  @override
  String get calendarTitleHint => 'Titolo';

  @override
  String get calendarDescriptionHint => 'Descrizione';

  @override
  String get calendarTypeEvent => 'Evento';

  @override
  String get calendarTypeMeeting => 'Riunione';

  @override
  String get calendarTypeReminder => 'Promemoria';

  @override
  String get calendarTypeLabel => 'Tipo';

  @override
  String get calendarMeetingLink => 'Link riunione';

  @override
  String get calendarLocationHint => 'Luogo';

  @override
  String get calendarDateLabel => 'Data';

  @override
  String get calendarTimeLabel => 'Ora';

  @override
  String get calendarReminderLabel => 'Promemoria';

  @override
  String get calendarReminderNone => 'Nessuno';

  @override
  String get calendarReminder15min => '15 min prima';

  @override
  String get calendarReminder30min => '30 min prima';

  @override
  String get calendarReminder1hour => '1 ora prima';

  @override
  String get calendarRepeatLabel => 'Ripeti';

  @override
  String get calendarRepeatNone => 'Nessuna ripetizione';

  @override
  String get calendarRepeatDaily => 'Ogni giorno';

  @override
  String get calendarRepeatWeekly => 'Ogni settimana';

  @override
  String get calendarRepeatMonthly => 'Ogni mese';

  @override
  String get calendarRepeatYearly => 'Ogni anno';

  @override
  String get calendarParticipants => 'Partecipanti';

  @override
  String get calendarAddParticipant => 'Aggiungi';

  @override
  String get calendarSearchContacts => 'Cerca contatti...';

  @override
  String get calendarNoContacts => 'Nessun contatto';

  @override
  String get calendarStatusAccepted => 'Accettato';

  @override
  String get calendarStatusDeclined => 'Rifiutato';

  @override
  String get calendarStatusMaybe => 'Forse';

  @override
  String get calendarStatusPending => 'In attesa';

  @override
  String get calendarEndTime => 'Ora di fine';

  @override
  String get calendarYourAnswer => 'La tua risposta:';

  @override
  String get calendarOrganizer => 'Organizzatore';

  @override
  String calendarDeleteError(String error) {
    return 'Eliminazione fallita: $error';
  }

  @override
  String get calendarRsvpAccept => 'Accetta';

  @override
  String get calendarRsvpMaybe => 'Forse';

  @override
  String get calendarRsvpDecline => 'Rifiuta';

  @override
  String get callHistoryTitle => 'Chiamate';

  @override
  String get callHistoryTab => 'Cronologia chiamate';

  @override
  String get callHistoryTempMeeting => 'Riunione temporanea';

  @override
  String get callHistoryCopy => 'Copia';

  @override
  String get callHistoryLinkCopied => 'Link copiato';

  @override
  String get callHistoryShare => 'Condividi';

  @override
  String get callHistoryEnter => 'Entra';

  @override
  String get callHistoryAlreadyInCall => 'Già in chiamata';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Impossibile determinare l\'altra parte';

  @override
  String get callHistoryContacts => 'Contatti';

  @override
  String get callHistoryFailedLoadRoom =>
      'Caricamento della tua stanza fallito';

  @override
  String get callHistoryYourRoom => 'La tua stanza';

  @override
  String get callHistoryCreateMeeting => 'Crea riunione';

  @override
  String get callHistoryMeetingSummaries => 'Riepiloghi riunioni';

  @override
  String get callHistoryMeetingRecordings => 'Registrazioni riunioni';

  @override
  String get callHistoryNoCalls => 'Nessuna chiamata';

  @override
  String get callHistoryMissed => 'Perse';

  @override
  String get callHistoryRecording => 'Registrazione';

  @override
  String get callHistorySummary => 'Riepilogo';

  @override
  String get callHistoryCallAgain => 'Chiama di nuovo';

  @override
  String callHistoryTodayTime(String time) {
    return 'Oggi, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Ieri, $time';
  }

  @override
  String get callHistoryUnknown => 'Sconosciuto';

  @override
  String get callHistoryDetails => 'Dettagli chiamata';

  @override
  String get callHistoryOutgoing => 'Chiamata in uscita';

  @override
  String get callHistoryIncoming => 'Chiamata in entrata';

  @override
  String callHistoryDuration(String duration) {
    return 'Durata: $duration';
  }

  @override
  String get callHistoryWithAI => 'Con assistente AI';

  @override
  String get callHistoryParticipants => 'Partecipanti';

  @override
  String get callDetailYouSuffix => '(Tu)';

  @override
  String get callHistoryMeetingSummary => 'Riepilogo riunione';

  @override
  String get callHistoryMoreDetails => 'Ulteriori dettagli';

  @override
  String get callHistorySummaryProcessing => 'Elaborazione riepilogo...';

  @override
  String get callHistoryMeetingRecording => 'Registrazione riunione';

  @override
  String get callHistoryProcessing => 'Elaborazione...';

  @override
  String get callHistoryCreateTranscript => 'Crea trascrizione';

  @override
  String get callHistoryNoSummaries => 'Nessun riepilogo';

  @override
  String get callHistoryRecordDuringCall =>
      'Premi \"Registra\" durante una chiamata';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Riunione $time';
  }

  @override
  String get callHistoryTranscribing => 'Trascrizione e riepilogo...';

  @override
  String get callHistoryTranscriptCreated => 'Trascrizione creata';

  @override
  String get callHistoryNoRecordings => 'Nessuna registrazione';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Registrazione $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Registrazione non disponibile';

  @override
  String get callHistoryTranscriptReady => 'Trascrizione pronta';

  @override
  String get callHistoryTranscript => 'Trascrizione';

  @override
  String get callHistoryKeyPoints => 'Punti chiave';

  @override
  String get callHistoryTasks => 'Compiti';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Assegnato a: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Decisioni';

  @override
  String get callHistoryShowTranscript => 'Mostra trascrizione completa';

  @override
  String get profileScanQr => 'Scansiona QR';

  @override
  String get profileMyQrCode => 'Il mio codice QR';

  @override
  String profileAddMeShare(String userId) {
    return 'Aggiungimi in Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Mostra questo codice per aggiungerti';

  @override
  String get profileEditDesc => 'Nome, cognome, patronimico, data di nascita';

  @override
  String get profileAboutMe => 'Su di me';

  @override
  String get profileAboutMeDesc => 'Valori, competenze, interessi e altro';

  @override
  String get profileNotes => 'Note';

  @override
  String get profileNotesDesc => 'Pensieri, idee e note';

  @override
  String get profileAvatarUpdated => 'Avatar aggiornato';

  @override
  String get profileNickname => 'Soprannome';

  @override
  String get profileNotSet => 'Non impostato';

  @override
  String get profileChangeNickname => 'Cambia soprannome';

  @override
  String get profileNicknameUpdated => 'Soprannome aggiornato';

  @override
  String get profileShareLabel => 'Condividi';

  @override
  String get profileScanQrCode => 'Scansiona codice QR';

  @override
  String get profilePointCamera => 'Punta la fotocamera sul codice QR';

  @override
  String get profilePhotoCamera => 'Scatta foto';

  @override
  String get profilePhotoGallery => 'Scegli dalla galleria';

  @override
  String get editProfilePatronymic => 'Patronimico (opzionale)';

  @override
  String get editProfileDateFormat => 'GG.MM.AAAA';

  @override
  String get aboutMeTitle => 'Su di me';

  @override
  String get aboutMeClickToFill => 'Clicca per compilare';

  @override
  String get aboutMeCoreValues => 'Valori';

  @override
  String get aboutMeWorldview => 'Visione del mondo';

  @override
  String get aboutMeSkills => 'Competenze';

  @override
  String get aboutMeInterests => 'Interessi';

  @override
  String get aboutMeDesires => 'Desideri';

  @override
  String get aboutMeBackground => 'Profilo';

  @override
  String get aboutMeLikes => 'Mi piace';

  @override
  String get aboutMeDislikes => 'Non mi piace';

  @override
  String get aboutMeDeleteSection => 'Eliminare sezione?';

  @override
  String get aboutMeDeleteConfirm =>
      'Tutti i dati in questa sezione verranno eliminati.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Errore di connessione: $error';
  }

  @override
  String get aboutMeVisibility => 'Visibilità';

  @override
  String get aboutMeTags => 'Tag';

  @override
  String get aboutMeAddTag => 'Aggiungi tag...';

  @override
  String get aboutMeDescription => 'Descrizione';

  @override
  String get aboutMeDescribeLong => 'Raccontaci di più...';

  @override
  String get aboutMeVisibilityEveryone => 'Tutti';

  @override
  String get aboutMeVisibilityContacts => 'Contatti';

  @override
  String get aboutMeVisibilityOnlyMe => 'Solo io';

  @override
  String get settingsProfileSubtitle => 'Profilo';

  @override
  String get settingsWallpaper => 'Sfondo';

  @override
  String get settingsWallpaperDesc => 'Immagine di sfondo per tutta l\'app';

  @override
  String get settingsWallpaperNone => 'Nessuno';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsKycVerification => 'Verifica dell\'identità (KYC)';

  @override
  String get settingsOrganizations => 'Organizzazioni';

  @override
  String get incomingCallLabel => 'Chiamata in arrivo';

  @override
  String get incomingCallDecline => 'Rifiuta';

  @override
  String get incomingCallAccept => 'Accetta';

  @override
  String get meshIncomingCallLabel => '📡 Chiamata mesh in arrivo';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Dispositivo mesh $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Termina prima la chiamata corrente';

  @override
  String get callPopupTransportTitle => 'Chiama tramite';

  @override
  String get callPopupTransportMesh => '📡 Mesh (peer-to-peer)';

  @override
  String get callPopupTransportLk => '📞 Server';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Contatto non raggiungibile via mesh';

  @override
  String get meshOnboardingTitle =>
      '📡 Le chiamate mesh richiedono l\'app aperta';

  @override
  String get meshOnboardingBody =>
      'Quando il telefono è bloccato, le chiamate mesh possono interrompersi dopo ~30 secondi (limitazione di iOS).';

  @override
  String get meshOnboardingAck => 'Capito';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Il contatto non è nella tua lista';

  @override
  String get meshCallStatusInviting => 'Chiamata in corso…';

  @override
  String get meshCallStatusConnecting => 'Connessione in corso…';

  @override
  String get meshCallEndedUserHangup => 'Chiamata terminata';

  @override
  String get meshCallEndedRemoteHangup => 'Terminata dal peer';

  @override
  String get meshCallEndedRejected => 'Rifiutata';

  @override
  String get meshCallEndedNoAnswer => 'Nessuna risposta';

  @override
  String get meshCallEndedConnectionLost => 'Connessione persa';

  @override
  String get meshCallEndedError => 'Errore di connessione';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Chiamate mesh affidabili';

  @override
  String get batteryExemptionBody =>
      'Consenti all\'app di funzionare senza restrizioni di batteria affinché Android non interrompa il mesh in background.';

  @override
  String get batteryExemptionAccept => 'Apri impostazioni';

  @override
  String get batteryExemptionDismiss => 'Non ora';

  @override
  String get groupCamera => 'Fotocamera';

  @override
  String get groupGallery => 'Galleria';

  @override
  String get groupAvatarUpdated => 'Avatar del gruppo aggiornato';

  @override
  String get groupNameTitle => 'Nome del gruppo';

  @override
  String get groupEnterName => 'Inserisci nome';

  @override
  String get groupDescriptionTitle => 'Descrizione del gruppo';

  @override
  String get groupEnterDescription => 'Inserisci descrizione del gruppo';

  @override
  String get groupChangeRoleTitle => 'Cambia ruolo';

  @override
  String get groupRemoveMemberTitle => 'Rimuovi membro';

  @override
  String get groupDescription => 'Descrizione';

  @override
  String get groupAddDescription => 'Aggiungi descrizione del gruppo';

  @override
  String get groupNoDescription => 'Nessuna descrizione';

  @override
  String get groupMediaAndFiles => 'Media e file';

  @override
  String get groupMuteNotifications => 'Disattiva notifiche';

  @override
  String get groupMuted => 'Disattivato';

  @override
  String get groupNoResults => 'Nessun risultato';

  @override
  String get authInvalidCode => 'Codice non valido. Riprova.';

  @override
  String get loginSubtitle => 'Usa email e password';

  @override
  String get emailRequired => 'Inserisci email';

  @override
  String get emailInvalid => 'Email non valida';

  @override
  String get passwordRequired => 'Inserisci password';

  @override
  String get registerSubtitle => 'Un account per l\'intero ecosistema Taler';

  @override
  String get usernameOptional => 'Nome utente (opzionale)';

  @override
  String get usernameMinLength => 'Minimo 3 caratteri';

  @override
  String get usernameMaxLength => 'Massimo 30 caratteri';

  @override
  String get usernameInvalid => 'Solo lettere, cifre e _';

  @override
  String get biometricLoginReason => 'Accedi a Taler ID';

  @override
  String get docTypePassport => 'Passaporto';

  @override
  String get docTypeIdCard => 'Carta d\'identità';

  @override
  String get docTypeDriverLicense => 'Patente di guida';

  @override
  String get docTypeResidencePermit => 'Permesso di soggiorno';

  @override
  String addressApartment(String number) {
    return 'app. $number';
  }

  @override
  String get failedToUpdateProfile => 'Aggiornamento profilo non riuscito';

  @override
  String get failedToStartKyb => 'Avvio verifica KYB non riuscito';

  @override
  String get orgUpdated => 'Organizzazione aggiornata';

  @override
  String get failedToUpdateOrg => 'Aggiornamento organizzazione non riuscito';

  @override
  String get failedToChangeRole => 'Cambio ruolo non riuscito';

  @override
  String get failedToRemoveMember => 'Rimozione membro non riuscita';

  @override
  String get capabilityMessagesTitle => 'Messaggi';

  @override
  String get capabilityMessagesDesc =>
      'Controlla i messaggi o scrivi a qualcuno. Ad esempio: \"Scrivi a Viktor: sarò lì tra un\'ora\"';

  @override
  String get capabilityCallsTitle => 'Chiamate';

  @override
  String get capabilityCallsDesc =>
      'Chiama qualsiasi contatto tramite voce. Ad esempio: \"Chiama Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Cronologia chat';

  @override
  String get capabilityChatDesc =>
      'Analizzerò la cronologia delle chat. Ad esempio: \"Di cosa abbiamo discusso con Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Profilo';

  @override
  String get capabilityProfileDesc =>
      'Mostrerò o aggiornerò il tuo profilo. Ad esempio: \"Mostra il mio profilo\"';

  @override
  String get capabilityCoachingTitle => 'Coaching';

  @override
  String get capabilityCoachingDesc =>
      'Modalità: coaching ICF, psicologo, consulenza HR. Dì: \"Facciamo coaching\"';

  @override
  String get capabilityCalendarTitle => 'Calendario';

  @override
  String get capabilityCalendarDesc =>
      'Programma un incontro o imposta un promemoria. Ad esempio: \"Programma un incontro con Viktor per domani alle 15:00\"';

  @override
  String get capabilityNotesTitle => 'Note';

  @override
  String get capabilityNotesDesc =>
      'Salva un pensiero o leggi le note recenti. Ad esempio: \"Annota un\'idea...\" o \"Leggi le note recenti\"';

  @override
  String get assistantCallConfirm => 'Effettuare una chiamata?';

  @override
  String get callNoAnswer => 'Nessuna risposta';

  @override
  String get contactDelete => 'Rimuovi contatto';

  @override
  String get contactDeleteTitle => 'Rimuovi contatto';

  @override
  String get contactDeleteConfirm =>
      'Sei sicuro? Questo contatto verrà rimosso.';

  @override
  String get contactBlock => 'Blocca';

  @override
  String get contactBlockTitle => 'Blocca utente';

  @override
  String get contactBlockConfirm =>
      'Questo utente non potrà inviarti messaggi o chiamarti.';

  @override
  String get contactUnblock => 'Sblocca';

  @override
  String get contactBlocked => 'Bloccato';

  @override
  String get contactYouAreBlocked => 'Questo utente ti ha bloccato';

  @override
  String get chatBlockedByYou => 'Hai bloccato questo utente';

  @override
  String get chatYouAreBlocked => 'Sei stato bloccato da questo utente';

  @override
  String get chatNotContacts =>
      'Aggiungi questo utente ai contatti per inviargli messaggi';

  @override
  String get contactRevokeRequest => 'Revoca richiesta';

  @override
  String get messengerPoll => 'Sondaggio';

  @override
  String get messengerCreatePoll => 'Crea sondaggio';

  @override
  String get messengerPollQuestion => 'Domanda';

  @override
  String messengerPollOption(int number) {
    return 'Opzione $number';
  }

  @override
  String get messengerPollAddOption => 'Aggiungi opzione';

  @override
  String get messengerPollAnonymous => 'Votazione anonima';

  @override
  String get messengerPollMultiple => 'Scelta multipla';

  @override
  String get messengerPollCreateError => 'Creazione sondaggio fallita';

  @override
  String get messengerPollUnavailable => 'Sondaggio non disponibile';

  @override
  String get messengerPollMultipleNote => 'Puoi selezionare più opzioni';

  @override
  String messengerPollVotes(int count) {
    return '$count voti';
  }

  @override
  String get messengerVideoMessage => 'Messaggio video';

  @override
  String get messengerVideoRecordError => 'Errore di registrazione video';

  @override
  String get messengerVideoPlaybackError => 'Impossibile riprodurre il video';

  @override
  String get messengerGalleryAccessError => 'Nessun accesso alla galleria';

  @override
  String get messengerSearchInChat => 'Cerca nella chat...';

  @override
  String get messengerSaveToFavorites => 'Salva nei preferiti';

  @override
  String get messengerSavedToFavorites => 'Salvato nei preferiti';

  @override
  String get messengerSearchInMessages => 'Cerca nei messaggi...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Trovato nei messaggi ($count)';
  }

  @override
  String get messengerGroupDefault => 'Gruppo';

  @override
  String get messengerUserDefault => 'Utente';

  @override
  String get messengerPin => 'Fissa';

  @override
  String get messengerUnpin => 'Rimuovi';

  @override
  String get messengerArchive => 'Archivia';

  @override
  String get messengerUnarchive => 'Ripristina';

  @override
  String get messengerDeleteChat => 'Elimina chat';

  @override
  String get messengerDeleteChatTitle => 'Eliminare la chat?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Eliminare la chat con $name? Questa azione non può essere annullata.';
  }

  @override
  String get messengerCreateChannel => 'Crea canale';

  @override
  String get messengerChannelName => 'Nome';

  @override
  String get messengerChannelDescription => 'Descrizione (opzionale)';

  @override
  String get messengerChannelCreateError => 'Creazione del canale non riuscita';

  @override
  String get messengerFilterAll => 'Tutti';

  @override
  String get messengerFilterUnread => 'Non letti';

  @override
  String get messengerFilterPersonal => 'Personali';

  @override
  String get messengerFilterGroups => 'Gruppi';

  @override
  String get messengerFilterChannels => 'Canali';

  @override
  String get messengerArchivedSection => 'Archiviati';

  @override
  String get messengerSavedSection => 'Preferiti';

  @override
  String get messengerSavedSubtitle => 'Salva in memoria';

  @override
  String messengerArchiveTitle(int count) {
    return 'Archivio ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Archivio vuoto';

  @override
  String messengerYouPrefix(String message) {
    return 'Tu: $message';
  }

  @override
  String get messengerMissedCall => 'Chiamata persa';

  @override
  String get messengerSavedTitle => 'Preferiti';

  @override
  String get messengerNoSavedMessages => 'Nessun messaggio salvato';

  @override
  String get messengerSavedHint =>
      'Premi a lungo su un messaggio → \"Salva nei preferiti\"';

  @override
  String get messengerDefaultFile => 'File';

  @override
  String get messengerTopicDefault => 'Generale';

  @override
  String get messengerTopicNew => 'Nuovo argomento';

  @override
  String get messengerTopicNameHint => 'Nome dell\'argomento';

  @override
  String get messengerTopicIcon => 'Icona';

  @override
  String messengerTopicCount(int count) {
    return '$count argomenti';
  }

  @override
  String get messengerNoTopics => 'Nessun argomento';

  @override
  String get messengerNoMessages => 'Nessun messaggio';

  @override
  String get you => 'Tu';

  @override
  String get messengerThread => 'Discussione';

  @override
  String get messengerThreadReply => 'risposta';

  @override
  String get messengerThreadReplies => 'risposte';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Nessuna risposta';

  @override
  String get messengerReplyHint => 'Rispondi alla discussione...';

  @override
  String get messengerContactName => 'Nome contatto';

  @override
  String messengerOriginalName(String name) {
    return 'Nome originale: $name';
  }

  @override
  String get messengerDisplayName => 'Nome visualizzato';

  @override
  String messengerShareContact(String name) {
    return 'Contatto in Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Elimina automaticamente i messaggi';

  @override
  String get messengerAutoDeleteOff => 'Disattivato';

  @override
  String get messengerAutoDelete7d => '7 giorni';

  @override
  String get messengerAutoDelete30d => '30 giorni';

  @override
  String get messengerAutoDelete90d => '90 giorni';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count giorni';
  }

  @override
  String get messengerSettingsHeader => 'Impostazioni';

  @override
  String get messengerAdminOnly => 'Solo admin possono pubblicare';

  @override
  String get messengerAdminOnlyDesc => 'I membri possono solo leggere';

  @override
  String get messengerTopics => 'Argomenti';

  @override
  String get messengerTopicsDesc => 'Dividi la chat in argomenti';

  @override
  String get aiTwinSection => 'Gemello vocale AI';

  @override
  String get aiTwinEnabled => 'Abilita AI Twin';

  @override
  String get aiTwinEnabledDesc =>
      'Se non rispondi, il tuo gemello AI prende la chiamata con la tua voce';

  @override
  String get aiTwinTimeout => 'Timeout di risposta';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds sec';
  }

  @override
  String get aiTwinPrompt => 'Istruzioni AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Come il gemello AI dovrebbe presentarsi e di cosa parlare';

  @override
  String aiTwinPromptHint(String name) {
    return 'Ciao, sono il gemello vocale AI di $name. $name non può rispondere al momento. Dimmi chi chiama e di cosa si tratta — lo riferirò.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Clonazione vocale personalizzata in arrivo. Per ora l\'AI parla con la voce di $name.';
  }

  @override
  String get aiTwinDefaultName => 'il proprietario';

  @override
  String get aiTwinPromptReset => 'Reimposta';

  @override
  String get callHistoryAiTwinAnswered => 'RISPOSTA DA AI TWIN';

  @override
  String get callHistoryAiTwinSummary => 'RIASSUNTO CHIAMATA';

  @override
  String get callHistoryAiTwinTranscript => 'TRASCRIZIONE';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'Da $name';
  }

  @override
  String get aiTwinOfferTitle => 'Non risponde';

  @override
  String aiTwinOfferBody(String name) {
    return '$name non risponde. Lascia un messaggio con il loro gemello vocale AI?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Utente';

  @override
  String get aiTwinOfferAccept => 'Sì, lascia messaggio';

  @override
  String get aiTwinOfferKeepWaiting => 'Continua ad aspettare';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Il tuo sostituto AI';

  @override
  String get aiTwinHeroSubtitle =>
      'Risponde alle chiamate con la tua voce quando non puoi.';

  @override
  String get aiTwinProfileTitle => 'Sostituto AI';

  @override
  String get aiTwinProfileDesc => 'Risponde alle chiamate con la tua voce';

  @override
  String get aiTwinBadgeOn => 'ATTIVO';

  @override
  String get aiAnalystTitle => 'Analista AI';

  @override
  String get aiAnalystSubtitle => 'File, compiti, analisi — Claude';

  @override
  String get channelsDiscover => 'Trova canale';

  @override
  String get channelsSearchHint => 'Cerca canali';

  @override
  String get channelsSubscribers => 'iscritti';

  @override
  String get channelsSubscribe => 'Iscriviti';

  @override
  String get channelsUnsubscribe => 'Annulla iscrizione';

  @override
  String get channelsSubscribedLabel => 'Sei iscritto';

  @override
  String get channelsSettings => 'Impostazioni canale';

  @override
  String get channelsDelete => 'Elimina canale';

  @override
  String get channelsDeleteConfirm => 'Eliminare il canale definitivamente?';

  @override
  String get channelsEmpty => 'Nessun canale ancora';

  @override
  String get channelsOpen => 'Apri';

  @override
  String get channelsNameLabel => 'Nome';

  @override
  String get channelsDescriptionLabel => 'Descrizione';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Il proprietario non può annullare l\'iscrizione. Elimina invece il canale.';

  @override
  String get channelsNotFoundRedirect => 'Il canale non esiste più';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ricerche',
      one: '$count ricerca',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '$count file',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comandi',
      one: '$count comando',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count immagini',
      one: '$count immagine',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passaggi',
      one: '$count passaggio',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Messaggi Salvati';

  @override
  String get savedSubtitle => 'Il tuo cloud privato';

  @override
  String get savedOpenError => 'Impossibile aprire i Messaggi Salvati';

  @override
  String get billingWalletTitle => 'Portafoglio';

  @override
  String get billingBuyPackage => 'Acquista pacchetto';

  @override
  String get billingCurrentBalance => 'Saldo attuale';

  @override
  String get billingPackagesTitle => 'Pacchetti';

  @override
  String get billingPackagesUnavailable => 'Pacchetti non disponibili';

  @override
  String get billingRecentOperations => 'Operazioni recenti';

  @override
  String get billingAllOperations => 'Tutte le operazioni';

  @override
  String get billingNoOperations => 'Nessuna operazione';

  @override
  String get billingOperationsTitle => 'Operazioni';

  @override
  String get billingOperationsEmptyTitle => 'Nessuna operazione ancora';

  @override
  String get billingOperationsEmptySubtitle =>
      'Ricariche e addebiti per le funzionalità AI appariranno qui';

  @override
  String get billingPricebookTitle => 'Prezzi delle funzionalità';

  @override
  String get billingPricebookUnavailable => 'Listino prezzi non disponibile';

  @override
  String get billingAiFeaturesTitle => 'Funzionalità AI';

  @override
  String get billingInsufficientFundsTitle => 'Fondi insufficienti';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Ricarica il tuo saldo per utilizzare questa funzionalità.';

  @override
  String billingRequiredLine(String required) {
    return 'Necessario: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Disponibile: $available μTAL';
  }

  @override
  String get billingTopUp => 'Ricarica';

  @override
  String get billingCancel => 'Annulla';

  @override
  String get billingRetry => 'Riprova';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Saldo in esaurimento: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Portafoglio & Saldo';

  @override
  String get billingSectionHeader => 'Fatturazione & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Assistente vocale';

  @override
  String get billingFeatureWebSearch => 'Ricerca web assistente';

  @override
  String get billingFeatureAiTwin => 'Gemello vocale';

  @override
  String get billingFeatureAiTwinLong => 'Gemello vocale (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot in uscita';

  @override
  String get billingFeatureOutboundCallLong => 'Bot di chiamata in uscita';

  @override
  String get billingFeatureWhisperTranscribe => 'Trascrizione chiamata';

  @override
  String get billingFeatureMeetingSummary => 'Riepiloghi chiamate AI';

  @override
  String get billingConfigureAiTwin => 'Configura AI twin';

  @override
  String get billingWebSearchSubtitle => '(usato dall\'assistente)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Pacchetto acquistato: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Consigliato';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Saldo esaurito — sessione terminata';

  @override
  String get billingSessionTerminatedGeneric => 'Sessione assistente terminata';

  @override
  String billingBuyForPrice(String price) {
    return 'Acquista per €$price';
  }

  @override
  String get billingTxTypeTopup => 'Ricarica';

  @override
  String get billingTxTypeRefund => 'Rimborso';

  @override
  String get billingTxTypeSpend => 'Addebito';

  @override
  String get billingUnitMinute => 'minuto';

  @override
  String get billingUnitRequest => 'richiesta';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K token';

  @override
  String get billingUnitCall => 'chiamata';

  @override
  String get groupCallSelectParticipants => 'Seleziona partecipanti';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Cerca';

  @override
  String get groupCallMaxReached => 'Massimo 7 partecipanti';

  @override
  String get groupCallLobbyTitle => 'Gruppo • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Host: $name';
  }

  @override
  String get groupCallMicHint => 'Il microfono si attiverà al collegamento';

  @override
  String get groupCallCancel => 'Annulla';

  @override
  String get groupCallNoAnswer => 'Nessuno ha risposto';

  @override
  String get groupCallEndedByHost => 'Chiamata terminata dall\'host';

  @override
  String get groupCallAllLeft => 'Tutti hanno lasciato la chiamata';

  @override
  String get groupCallEnded => 'Chiamata terminata';

  @override
  String groupCallActiveTitle(int count) {
    return 'Gruppo • $count';
  }

  @override
  String get groupCallConnectionLost => 'Connessione persa';

  @override
  String get groupCallMuteRequested =>
      'L\'host ha chiesto a tutti di disattivare l\'audio';

  @override
  String get groupCallUnmute => 'Riattiva audio';

  @override
  String get groupCallMute => 'Disattiva audio';

  @override
  String get groupCallMuteAll => 'Disattiva audio a tutti';

  @override
  String get groupCallLeave => 'Lascia';

  @override
  String get groupCallStatusCalling => 'chiamando…';

  @override
  String get groupCallStatusDeclined => 'rifiutato';

  @override
  String get groupCallStatusTimeout => 'nessuna risposta';

  @override
  String get groupCallStatusLeft => 'uscito';

  @override
  String groupCallKickConfirm(String name) {
    return 'Rimuovere $name dalla chiamata';
  }

  @override
  String get groupCallCancelAction => 'Annulla';

  @override
  String get groupCallActiveBanner => 'Chiamata attiva';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Gruppo: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Gruppo: $host';
  }

  @override
  String get groupCallCreateError => 'Impossibile creare la chiamata';

  @override
  String get groupCallJoinError => 'Impossibile partecipare alla chiamata';

  @override
  String get groupCallLivekitError => 'Errore LiveKit';

  @override
  String get groupCallDone => 'Fatto';

  @override
  String get groupCallNoResults => 'Nessun risultato';

  @override
  String get groupCallNoContacts => 'Nessun contatto';

  @override
  String get meshGcContactOffline => 'Non su questo Wi-Fi';

  @override
  String get meshGcOnlineViaMesh => 'Online tramite mesh';

  @override
  String get meshGcMaxInvitees =>
      'Le chiamate di gruppo supportano fino a 4 invitati (5 persone in totale).';

  @override
  String get meshGcStart => 'Avvia chiamata di gruppo';

  @override
  String get meshGcCancel => 'Annulla';

  @override
  String get meshGcStatusCalling => 'Chiamata in corso…';

  @override
  String get meshGcStatusJoined => 'Partecipato';

  @override
  String get meshGcStatusDeclined => 'Rifiutato';

  @override
  String get meshGcStatusNoAnswer => 'Nessuna risposta';

  @override
  String get meshGcStatusConnectionFailed => 'Connessione fallita';

  @override
  String get meshGcStatusLeft => 'Uscito';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Termina prima la chiamata corrente.';

  @override
  String get presenceOnline => 'online';

  @override
  String get presenceLastSeenJustNow => 'ultimo accesso proprio ora';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'ultimo accesso $minutes min fa';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'ultimo accesso oggi alle $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'ultimo accesso ieri alle $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'ultimo accesso il $date';
  }

  @override
  String get presenceLastSeenRecently => 'ultimo accesso recentemente';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get privacyLastSeenLabel => 'Chi vede il tuo ultimo accesso';

  @override
  String get privacyEveryone => 'Tutti';

  @override
  String get privacyContacts => 'Solo contatti';

  @override
  String get privacyNobody => 'Nessuno';
}
