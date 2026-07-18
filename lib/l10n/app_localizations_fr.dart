// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Rechercher';

  @override
  String get appSubtitle => 'Identité d\'écosystème unifié';

  @override
  String get login => 'Se connecter';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get register => 'Créer un compte';

  @override
  String get registerButton => 'Créer un compte';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get createOne => 'Créer un';

  @override
  String get haveAccount => 'Vous avez déjà un compte ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get passwordMinLength => 'Minimum 8 caractères';

  @override
  String get invalidEmail => 'Entrez un email valide';

  @override
  String get fieldRequired => 'Champ requis';

  @override
  String get twoFATitle => 'Authentification à deux facteurs';

  @override
  String get twoFASubtitle =>
      'Entrez le code à 6 chiffres de votre application d\'authentification';

  @override
  String get twoFACode => 'Code 2FA';

  @override
  String get verify => 'Vérifier';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organisation';

  @override
  String get tabSettings => 'Paramètres';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get phone => 'Téléphone';

  @override
  String get country => 'Pays';

  @override
  String get dateOfBirth => 'Date de naissance';

  @override
  String get documents => 'Documents';

  @override
  String get addDocument => 'Ajouter un document';

  @override
  String get noDocuments => 'Aucun document téléchargé';

  @override
  String get save => 'Enregistrer';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get personalData => 'Données personnelles';

  @override
  String get passport => 'Passeport';

  @override
  String get drivingLicense => 'Permis de conduire';

  @override
  String get diploma => 'Diplôme';

  @override
  String get nationalId => 'Carte d\'identité';

  @override
  String get certificate => 'Certificat';

  @override
  String get notSpecified => 'Non spécifié';

  @override
  String get notSpecifiedFemale => 'Non spécifiée';

  @override
  String get documentType => 'Type de document';

  @override
  String get passportId => 'Passeport / Carte d\'identité';

  @override
  String get diplomaCertificate => 'Diplôme / Certificat';

  @override
  String get loadError => 'Erreur de chargement';

  @override
  String get verification => 'Vérification';

  @override
  String get countryAustria => 'Autriche';

  @override
  String get countryGermany => 'Allemagne';

  @override
  String get countryRussia => 'Russie';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryKazakhstan => 'Kazakhstan';

  @override
  String get countryBelarus => 'Biélorussie';

  @override
  String get countryOther => 'Autre';

  @override
  String get kycTitle => 'Vérification KYC';

  @override
  String get kycVerified => 'Vérifié';

  @override
  String get kycPending => 'En attente';

  @override
  String get kycRejected => 'Rejeté';

  @override
  String get kycUnverified => 'Non vérifié';

  @override
  String get kycVerifiedDesc =>
      'Votre identité a été vérifiée. Vous avez un accès complet à toutes les fonctionnalités de l\'écosystème Taler.';

  @override
  String get kycPendingDesc =>
      'Vos documents sont en cours de vérification. Cela prend généralement 1 à 2 jours ouvrables.';

  @override
  String get kycRejectedDesc =>
      'Échec de la vérification. Veuillez vérifier la raison et soumettre à nouveau vos documents.';

  @override
  String get kycUnverifiedDesc =>
      'Complétez la vérification pour débloquer l\'accès complet aux fonctionnalités financières de l\'écosystème Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Commencer la vérification';

  @override
  String get retryVerification => 'Réessayer la vérification';

  @override
  String verifiedAt(String date) {
    return 'Vérifié : $date';
  }

  @override
  String get documentsSubmitted => 'Documents soumis pour vérification';

  @override
  String get documentsSubmittedDesc =>
      'La vérification prend généralement 1 à 2 jours ouvrables. Vous recevrez une notification push avec le résultat.';

  @override
  String get securityAes =>
      'Vos données sont protégées par un chiffrement AES-256';

  @override
  String get verificationTime => 'La vérification prend 1 à 2 jours ouvrables';

  @override
  String get pushNotification =>
      'Vous recevrez une notification push avec le résultat';

  @override
  String get kycWebOnly =>
      'La vérification KYC est uniquement disponible dans l\'application mobile.';

  @override
  String verificationError(String code) {
    return 'Erreur de vérification : $code';
  }

  @override
  String get organizations => 'Organisations';

  @override
  String get noOrganizations => 'Aucune organisation';

  @override
  String get noOrganizationsDesc =>
      'Créez une organisation ou acceptez une invitation';

  @override
  String get createOrganization => 'Créer une organisation';

  @override
  String get newOrganization => 'Nouvelle organisation';

  @override
  String get orgName => 'Nom *';

  @override
  String get orgDescription => 'Description';

  @override
  String get orgEmail => 'Email de contact';

  @override
  String get orgWebsite => 'Site web';

  @override
  String get orgLegalAddress => 'Adresse légale';

  @override
  String get create => 'Créer';

  @override
  String get organization => 'Organisation';

  @override
  String get contacts => 'Contacts';

  @override
  String members(int count) {
    return 'Membres ($count)';
  }

  @override
  String get inviteMember => 'Inviter un membre';

  @override
  String get invite => 'Inviter';

  @override
  String get sendInvite => 'Envoyer l\'invitation';

  @override
  String inviteSent(String email) {
    return 'Invitation envoyée à $email';
  }

  @override
  String get role => 'Rôle';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Opérateur';

  @override
  String get roleViewer => 'Observateur';

  @override
  String get editOrganization => 'Modifier';

  @override
  String get editOrganizationTitle => 'Modifier l\'organisation';

  @override
  String get removeMember => 'Supprimer le membre';

  @override
  String removeMemberConfirm(String name) {
    return 'Supprimer $name de l\'organisation ?';
  }

  @override
  String get memberRemoved => 'Membre supprimé';

  @override
  String get roleChanged => 'Rôle modifié';

  @override
  String get kybVerified => 'Vérifié';

  @override
  String get kybPending => 'En attente';

  @override
  String get kybRejected => 'Rejeté';

  @override
  String get kybNone => 'Non vérifié';

  @override
  String get kybVerification => 'Commencer la vérification KYB';

  @override
  String get kybStartBusiness => 'Commencer la vérification d\'entreprise';

  @override
  String get kybStatusLabel => 'Statut KYB';

  @override
  String get noKyb => 'Pas de KYB';

  @override
  String get kybBusinessVerificationTitle => 'Vérification d\'entreprise (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organisation vérifiée avec succès.';

  @override
  String get kybPendingOrgDesc =>
      'Les documents sont en cours de révision. Cela prend généralement 1 à 3 jours ouvrables.';

  @override
  String get kybRejectedOrgDesc =>
      'Échec de la vérification. Veuillez réessayer.';

  @override
  String get kybNoneOrgDesc =>
      'Vérifiez votre organisation pour accéder aux fonctionnalités professionnelles.';

  @override
  String get invitePlus => '+ Inviter';

  @override
  String get kybVerificationTitle => 'Vérification KYB';

  @override
  String get kybWebOnlyBusiness =>
      'La vérification KYB est uniquement disponible dans l\'application mobile.';

  @override
  String get unknownDevice => 'Appareil inconnu';

  @override
  String get ipUnknown => 'IP inconnue';

  @override
  String get currentSessionLabel => 'Actuel';

  @override
  String get endSessionAction => 'Terminer';

  @override
  String get deviceLoggedOut => 'L\'appareil sera déconnecté.';

  @override
  String get acceptInvitationTitle => 'Invitation à l\'organisation';

  @override
  String get acceptInvitation => 'Accepter l\'invitation';

  @override
  String get acceptInvitationDesc =>
      'Vous avez été invité à rejoindre une organisation dans l\'écosystème Taler.';

  @override
  String get accept => 'Accepter';

  @override
  String get reject => 'Refuser';

  @override
  String get sessions => 'Sessions actives';

  @override
  String get currentSession => 'Session actuelle';

  @override
  String get deleteSession => 'Terminer la session';

  @override
  String get deleteSessionConfirm => 'Terminer cette session ?';

  @override
  String get sessionDeleted => 'Session terminée';

  @override
  String get noSessions => 'Aucune session active';

  @override
  String minutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String daysAgo(int count) {
    return 'il y a $count jours';
  }

  @override
  String get justNow => 'À l\'instant';

  @override
  String get settings => 'Paramètres';

  @override
  String get security => 'Sécurité';

  @override
  String get biometrics => 'Biométrie';

  @override
  String get biometricsDesc =>
      'Connexion rapide avec Face ID ou empreinte digitale';

  @override
  String get biometricsConfirm =>
      'Confirmez la biométrie pour activer la connexion rapide';

  @override
  String get biometricsError =>
      'Échec de l\'activation de la biométrie. Vérifiez les paramètres de l\'appareil.';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get twoFactorAuth => 'Authentification à deux facteurs';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get passwordChanged => 'Mot de passe changé';

  @override
  String get wrongCurrentPassword => 'Mot de passe actuel incorrect';

  @override
  String get passwordTooWeak =>
      'Mot de passe trop faible : au moins 8 caractères, une lettre et un chiffre requis';

  @override
  String get passwordChangeFailed => 'Échec du changement de mot de passe';

  @override
  String get notifications => 'Notifications';

  @override
  String get permissions => 'Autorisations';

  @override
  String get permissionNotifications => 'Notifications push';

  @override
  String get permissionNotificationsDesc => 'Appels, messages, statuts';

  @override
  String get permissionMicrophone => 'Microphone';

  @override
  String get permissionMicrophoneDesc => 'Appels et assistant vocal';

  @override
  String get permissionCamera => 'Caméra';

  @override
  String get permissionCameraDesc => 'Appels vidéo et vérification';

  @override
  String get permissionLocation => 'Localisation';

  @override
  String get permissionLocationDesc => 'Utilisé pour la vérification';

  @override
  String get permissionOpenSettings =>
      'Pour révoquer une autorisation, ouvrez les paramètres système';

  @override
  String get pushKycStatus => 'Notification de statut KYC';

  @override
  String get pushKycStatusDesc => 'Résultat de la vérification';

  @override
  String get pushLogins => 'Notification de connexion';

  @override
  String get pushLoginsDesc => 'Lors de la connexion depuis un nouvel appareil';

  @override
  String get account => 'Compte';

  @override
  String get language => 'Langue';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Langue de l\'interface';

  @override
  String get exportData => 'Exporter les données (RGPD)';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountConfirm => 'Supprimer le compte ?';

  @override
  String get deleteAccountDesc =>
      'Toutes vos données seront supprimées (RGPD). Cette action est irréversible.';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutConfirm => 'Se déconnecter ?';

  @override
  String get logoutDesc =>
      'Vous serez déconnecté de Taler ID sur cet appareil.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Code PIN';

  @override
  String get pinCodeDesc => 'Connexion rapide avec un code à 4 chiffres';

  @override
  String get setupPin => 'Configurer le PIN';

  @override
  String get enterPin => 'Entrez le PIN';

  @override
  String get confirmPin => 'Confirmez le PIN';

  @override
  String get pinMismatch => 'Les PINs ne correspondent pas';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pinSet => 'PIN configuré avec succès';

  @override
  String get enterPinToLogin => 'Entrez le PIN pour vous connecter';

  @override
  String get pinIncorrect => 'PIN incorrect';

  @override
  String get removePin => 'Supprimer le PIN';

  @override
  String get pinRemoved => 'PIN supprimé';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get noData => 'Pas de données';

  @override
  String get failedToLoad => 'Échec du chargement des données';

  @override
  String get failedToLoadProfile => 'Échec du chargement du profil';

  @override
  String get failedToSave => 'Échec de l\'enregistrement des modifications';

  @override
  String get failedToLoadOrgs => 'Échec du chargement des organisations';

  @override
  String get failedToLoadOrg =>
      'Échec du chargement des données de l\'organisation';

  @override
  String get failedToCreateOrg => 'Échec de la création de l\'organisation';

  @override
  String get failedToInvite => 'Échec de l\'envoi de l\'invitation';

  @override
  String get failedToAcceptInvite => 'Échec de l\'acceptation de l\'invitation';

  @override
  String get failedToLoadSessions => 'Échec du chargement des sessions';

  @override
  String get failedToDeleteSession => 'Échec de la fin de la session';

  @override
  String get failedToLoadKyc => 'Échec du chargement du statut de vérification';

  @override
  String get failedToStartKyc => 'Échec du démarrage de la vérification';

  @override
  String get verifiedPersonalInfo => 'Données vérifiées';

  @override
  String get middleName => 'Deuxième prénom';

  @override
  String get placeOfBirth => 'Lieu de naissance';

  @override
  String get nationality => 'Nationalité';

  @override
  String get gender => 'Genre';

  @override
  String get genderMale => 'Homme';

  @override
  String get genderFemale => 'Femme';

  @override
  String get docNumber => 'Numéro';

  @override
  String get docIssuedDate => 'Délivré';

  @override
  String get docValidUntil => 'Valide jusqu\'à';

  @override
  String get docIssuedBy => 'Délivré par';

  @override
  String get address => 'Adresse';

  @override
  String get refreshData => 'Rafraîchir les données';

  @override
  String get failedToLoadSumsubData =>
      'Échec du chargement des données de vérification';

  @override
  String get sumsubDataLoading => 'Chargement des données de vérification...';

  @override
  String get reviewResultGreen => 'Vérification réussie';

  @override
  String get reviewResultRed => 'Vérification échouée';

  @override
  String get tabAssistant => 'Assistant';

  @override
  String get assistantChatHint => 'Message the assistant';

  @override
  String get assistantActionUnavailable => 'Item is no longer available';

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
  String get assistantConnecting => 'Connexion…';

  @override
  String get assistantSpeaking => 'Parle…';

  @override
  String get assistantListening => 'Écoute…';

  @override
  String get assistantTapToStart => 'Appuyez pour démarrer';

  @override
  String get assistantTapToTalk => 'Appuyez pour parler à l\'AI';

  @override
  String get assistantRealtimeDesc =>
      'L\'assistant répond par la voix en temps réel';

  @override
  String get assistantConnectingToAssistant => 'Connexion à l\'assistant...';

  @override
  String get assistantAiSpeaking => 'AI parle...';

  @override
  String get assistantAiListening => 'AI écoute';

  @override
  String get assistantSpeakerOn => 'Haut-parleur activé';

  @override
  String get assistantSpeaker => 'Haut-parleur';

  @override
  String get assistantEnd => 'Fin';

  @override
  String get assistantUnmute => 'Réactiver le son';

  @override
  String get assistantMicrophone => 'Microphone';

  @override
  String get assistantConnectionError => 'Erreur de connexion';

  @override
  String get tabMessenger => 'Messages';

  @override
  String get tabCalls => 'Appels';

  @override
  String get tabCalendar => 'Calendrier';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSelect => 'Choisir le thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get onboardingTitle1 => 'Identité unifiée';

  @override
  String get onboardingDesc1 =>
      'Taler ID est votre passeport numérique dans l\'écosystème Taler. Un compte pour tous les services.';

  @override
  String get onboardingTitle2 => 'Sécurité des données';

  @override
  String get onboardingDesc2 =>
      'La vérification KYC, le chiffrement AES-256 et l\'authentification à deux facteurs protègent votre identité.';

  @override
  String get onboardingTitle3 => 'Restez informé';

  @override
  String get onboardingDesc3 =>
      'Recevez des notifications sur le statut de vérification, les connexions depuis de nouveaux appareils et les appels entrants.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingEnableNotifications => 'Activer les notifications';

  @override
  String get onboardingTitle4 => 'Appels vocaux';

  @override
  String get onboardingDesc4 =>
      'Autorisez l\'accès au microphone pour les appels vocaux et l\'assistant AI. Vous pouvez modifier cela plus tard dans les paramètres.';

  @override
  String get onboardingEnableMicrophone => 'Activer le microphone';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get meshLocalNetworkPromptTitle =>
      'Autoriser l\'accès au réseau local';

  @override
  String get meshLocalNetworkPromptBody =>
      'Pour trouver des pairs sur le Wi-Fi (appels de groupe hors ligne), iOS nécessite l\'autorisation Réseau local. Ouvrez Réglages → Confidentialité et sécurité → Réseau local → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Ouvrir les réglages';

  @override
  String get meshLocalNetworkPromptDismiss => 'Compris';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre email pour recevoir un code de réinitialisation';

  @override
  String resetCodeSent(String email) {
    return 'Code envoyé à $email';
  }

  @override
  String get enterResetCode => 'Entrez le code';

  @override
  String get resetPasswordButton => 'Réinitialiser le mot de passe';

  @override
  String get passwordResetSuccess => 'Mot de passe réinitialisé avec succès';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get resendCode => 'Renvoyer le code';

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
  String get newGroup => 'Nouveau groupe';

  @override
  String get newChat => 'Nouvelle discussion';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get createGroup => 'Créer un groupe';

  @override
  String get groupInfo => 'Infos du groupe';

  @override
  String groupMembers(int count) {
    return 'Membres ($count)';
  }

  @override
  String get addMembers => 'Ajouter des membres';

  @override
  String get leaveGroup => 'Quitter le groupe';

  @override
  String get leaveGroupConfirm => 'Quitter ce groupe ?';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String get deleteGroupConfirm =>
      'Supprimer ce groupe ? Cela ne peut pas être annulé.';

  @override
  String get groupRoleOwner => 'Propriétaire';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Membre';

  @override
  String get selectParticipants => 'Sélectionner les participants';

  @override
  String selectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get changeRole => 'Changer de rôle';

  @override
  String get groupCreated => 'Groupe créé';

  @override
  String memberJoined(String name) {
    return '$name a rejoint';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name a quitté';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name a été retiré';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name est maintenant $role';
  }

  @override
  String participantsCount(int count) {
    return '$count participants';
  }

  @override
  String get enterGroupName => 'Entrer le nom du groupe';

  @override
  String get muteNotifications => 'Désactiver les notifications';

  @override
  String get unmuteNotifications => 'Activer les notifications';

  @override
  String get muteFor1Hour => 'Pendant 1 heure';

  @override
  String get muteFor8Hours => 'Pendant 8 heures';

  @override
  String get muteFor2Days => 'Pendant 2 jours';

  @override
  String get muteForever => 'Pour toujours';

  @override
  String get muted => 'Silencieux';

  @override
  String get tabTranslator => 'Traduire';

  @override
  String get translatorTitle => 'Traducteur';

  @override
  String get translatorSelectLanguage => 'Sélectionner la langue';

  @override
  String get translatorDownloading => 'Téléchargement des modèles de langue...';

  @override
  String get translatorDownloadingHint =>
      'Internet est nécessaire uniquement pour le premier téléchargement';

  @override
  String get translatorTypeHint =>
      'Tapez le texte ou appuyez sur le microphone';

  @override
  String get translatorListening => 'Écoute...';

  @override
  String get translatorTapToSpeak => 'Appuyez pour parler';

  @override
  String get translatorTapToStop => 'Appuyez pour arrêter';

  @override
  String get translatorAutoSpeak => 'Parole automatique';

  @override
  String get translatorCopied => 'Copié';

  @override
  String get translatorLangRu => 'Russe';

  @override
  String get translatorLangEn => 'Anglais';

  @override
  String get translatorLangDe => 'Allemand';

  @override
  String get translatorLangFr => 'Français';

  @override
  String get translatorLangEs => 'Espagnol';

  @override
  String get translatorLangIt => 'Italien';

  @override
  String get translatorLangPt => 'Portugais';

  @override
  String get translatorLangTr => 'Turc';

  @override
  String get translatorLangZh => 'Chinois';

  @override
  String get translatorLangJa => 'Japonais';

  @override
  String get translatorLangKo => 'Coréen';

  @override
  String get translatorLangAr => 'Arabe';

  @override
  String get translatorLangPl => 'Polonais';

  @override
  String get translatorLangSk => 'Slovaque';

  @override
  String get translatorLangCs => 'Tchèque';

  @override
  String get translatorLangNl => 'Néerlandais';

  @override
  String get translatorLangSv => 'Suédois';

  @override
  String get translatorLangDa => 'Danois';

  @override
  String get translatorLangNo => 'Norvégien';

  @override
  String get translatorLangFi => 'Finnois';

  @override
  String get translatorLangUk => 'Ukrainien';

  @override
  String get translatorLangEl => 'Grec';

  @override
  String get translatorLangRo => 'Roumain';

  @override
  String get translatorLangHu => 'Hongrois';

  @override
  String get translatorLangBg => 'Bulgare';

  @override
  String get translatorLangHr => 'Croate';

  @override
  String get translatorLangSr => 'Serbe';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Thaï';

  @override
  String get translatorLangVi => 'Vietnamien';

  @override
  String get translatorLangId => 'Indonésien';

  @override
  String get translatorLangMs => 'Malais';

  @override
  String get translatorLangHe => 'Hébreu';

  @override
  String get translatorLangFa => 'Persan';

  @override
  String get callInProgress => 'Appel en cours';

  @override
  String get joinCall => 'Rejoindre';

  @override
  String get createCallLink => 'Lien d\'appel';

  @override
  String get callLinkCopied => 'Lien copié';

  @override
  String get callLinkTitle => 'Lien de la salle';

  @override
  String get connectionUnstable =>
      'Connexion instable — vérifiez votre connexion internet';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get errorTimeout =>
      'Délai de connexion dépassé. Vérifiez votre connexion internet.';

  @override
  String get errorNoConnection => 'Pas de connexion internet.';

  @override
  String get errorGeneral => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get notifChannelMessages => 'Messages';

  @override
  String get notifChannelMessagesDesc => 'Notifications de nouveaux messages';

  @override
  String get notifChannelMissedCalls => 'Appels manqués';

  @override
  String get notifChannelMissedCallsDesc => 'Notifications d\'appels manqués';

  @override
  String get notifMissedCall => 'Appel manqué';

  @override
  String get notifAccept => 'Accepter';

  @override
  String get notifDecline => 'Refuser';

  @override
  String get notifIncomingCall => 'Appel entrant';

  @override
  String get notifIncomingCallChannel => 'Appel entrant';

  @override
  String get notifMissedCallChannel => 'Appel manqué';

  @override
  String get notifUnknown => 'Inconnu';

  @override
  String get effectNone => 'Pas de fond';

  @override
  String get effectBlur => 'Flou';

  @override
  String get effectOffice => 'Bureau';

  @override
  String get effectNature => 'Nature';

  @override
  String get effectGradient => 'Dégradé';

  @override
  String get effectLibrary => 'Bibliothèque';

  @override
  String get effectCity => 'Ville';

  @override
  String get effectMinimalism => 'Minimalisme';

  @override
  String get voiceParticipant => 'Participant';

  @override
  String get voiceInvitesToRoom => 'vous invite dans la salle';

  @override
  String get voiceRoom => 'Salle';

  @override
  String get voicePasswordProtected => 'Protégé par mot de passe';

  @override
  String get voicePasswordHint => 'Mot de passe';

  @override
  String get voiceEnter => 'Entrer';

  @override
  String get voiceJoinRoom => 'Rejoindre la salle';

  @override
  String get voiceYourName => 'Votre nom';

  @override
  String voiceInvitationSent(String name) {
    return 'Invitation envoyée à $name';
  }

  @override
  String get voiceNoActiveRoom => 'Aucune salle active';

  @override
  String get voiceCameraPermission =>
      'Autorisez l\'accès à la caméra dans Réglages → Confidentialité → Caméra → TalerID';

  @override
  String get voiceOpenSettings => 'Ouvrir';

  @override
  String voiceCameraError(String error) {
    return 'Échec de l\'activation de la caméra : $error';
  }

  @override
  String get voiceAllAgreedRecording =>
      'Tous d\'accord. Enregistrement démarré.';

  @override
  String get voiceNewParticipantAgreed =>
      'Nouveau participant d\'accord pour l\'enregistrement.';

  @override
  String get voiceDeclinedRecording =>
      'Vous avez refusé l\'enregistrement. Quitter l\'appel.';

  @override
  String get voiceRecordingEnded => 'Enregistrement terminé';

  @override
  String get voiceRecordingInProgress => 'Enregistrement en cours';

  @override
  String get voiceTranscriptionRequest => 'Demande de transcription';

  @override
  String get voiceRecordingRequest => 'Demande d\'enregistrement';

  @override
  String get voiceAgree => 'Accepter';

  @override
  String get voiceDeclineAndLeave => 'Refuser et quitter';

  @override
  String get voiceAudioOutput => 'Sortie audio';

  @override
  String get voiceAudioPhone => 'Téléphone';

  @override
  String get voiceAudioSpeaker => 'Haut-parleur';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Écouteurs';

  @override
  String get voiceLinkCopied => 'Lien copié';

  @override
  String get voiceTranslateTo => 'Traduire en';

  @override
  String get voiceSearchLanguage => 'Rechercher une langue...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Salle $name';
  }

  @override
  String get voiceVoiceCall => 'Appel vocal';

  @override
  String get voiceOnHold => 'En attente';

  @override
  String get voiceActiveCall => 'Actif';

  @override
  String get voiceEndAllCalls => 'Terminer tous les appels';

  @override
  String get voiceEndThisCall => 'Terminer cet appel';

  @override
  String get voiceCopyLink => 'Copier le lien';

  @override
  String get voiceAddParticipant => 'Ajouter un participant';

  @override
  String get voiceReconnecting => 'Reconnexion...';

  @override
  String get voiceConnectionError => 'Erreur de connexion';

  @override
  String get voiceClose => 'Fermer';

  @override
  String get voiceCalling => 'Appel en cours...';

  @override
  String get voiceCallActive => 'Appel actif';

  @override
  String get voiceWaiting => 'En attente';

  @override
  String get voiceWaitingUpper => 'EN ATTENTE';

  @override
  String get voiceRec => 'ENR';

  @override
  String get voiceStop => 'Arrêter';

  @override
  String get voiceRecord => 'Enregistrement';

  @override
  String get voiceTranslation => 'Traduction';

  @override
  String get voiceAudio => 'Audio';

  @override
  String get voiceFlipCamera => 'Retourner';

  @override
  String get voiceBackground => 'Arrière-plan';

  @override
  String get voiceAssistantSpeakingStatus => 'Assistant en train de parler...';

  @override
  String get voiceAssistantListeningStatus =>
      'Assistant en train d\'écouter...';

  @override
  String get voiceUnmute => 'Réactiver le son';

  @override
  String get voiceMic => 'Microphone';

  @override
  String get voiceAssistantLabel => 'Assistant';

  @override
  String get voiceCameraOn => 'Caméra activée';

  @override
  String get voiceCameraLabel => 'Caméra';

  @override
  String get voiceEndCall => 'Terminer l\'appel';

  @override
  String get voiceWaitingParticipants => 'En attente des participants...';

  @override
  String get voiceYou => 'Vous';

  @override
  String get voiceAiAssistant => 'Assistant AI';

  @override
  String get voiceVideoUnavailable => 'Vidéo indisponible';

  @override
  String get voiceSearchNickname => 'Rechercher par pseudo...';

  @override
  String get voiceTranscriptionWord => 'transcription';

  @override
  String get voiceRecordingWord => 'enregistrement';

  @override
  String get voiceConnecting => 'Connexion...';

  @override
  String get voiceVideoBackground => 'Arrière-plan vidéo';

  @override
  String get voiceCallSettings => 'Paramètres de l\'appel';

  @override
  String get voiceEnableAI => 'Activer l\'assistant AI';

  @override
  String get voiceAIParticipating => 'L\'AI participera à la conversation';

  @override
  String get voiceNormalCall => 'Appel normal sans AI';

  @override
  String get voiceCallConfirm => 'Passer un appel ?';

  @override
  String get chatAlreadyInCall => 'Déjà en appel';

  @override
  String chatCallError(String error) {
    return 'Erreur d\'appel : $error';
  }

  @override
  String get chatPhotoVideo => 'Photo / Vidéo';

  @override
  String get chatCamera => 'Caméra';

  @override
  String get chatFile => 'Fichier';

  @override
  String get chatContact => 'Contact';

  @override
  String get chatSelectContact => 'Sélectionner un contact';

  @override
  String get chatNoContacts => 'Aucun contact';

  @override
  String get chatUser => 'Utilisateur';

  @override
  String get chatFileAttachment => '📎 Fichier';

  @override
  String chatFileUploadError(String error) {
    return 'Erreur de téléchargement du fichier : $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Message vocal';

  @override
  String get chatGroup => 'Groupe';

  @override
  String get chatDialog => 'Dialogue';

  @override
  String get chatCall => 'Appel';

  @override
  String get chatStartConversation => 'Commencer une conversation';

  @override
  String get chatYou => 'Vous';

  @override
  String get chatIsTyping => 'est en train d\'écrire...';

  @override
  String chatUserIsTyping(String name) {
    return '$name est en train d\'écrire...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names sont en train d\'écrire...';
  }

  @override
  String get chatPreparingFile => 'Préparation du fichier…';

  @override
  String chatUploading(int progress) {
    return 'Téléchargement… $progress%';
  }

  @override
  String get chatEdited => 'Modifié';

  @override
  String get chatViaMesh => 'via mesh';

  @override
  String get chatReply => 'Répondre';

  @override
  String get chatEdit => 'Modifier';

  @override
  String get chatCopy => 'Copier';

  @override
  String get chatCopied => 'Copié';

  @override
  String get chatSaveMedia => 'Enregistrer';

  @override
  String get chatForward => 'Transférer';

  @override
  String get chatSaving => 'Enregistrement...';

  @override
  String get chatSavedToGallery => 'Enregistré dans la galerie';

  @override
  String get chatNoSavePermission =>
      'Pas d\'autorisation pour enregistrer. Vérifiez les paramètres.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Erreur d\'enregistrement du fichier';

  @override
  String get chatDeleteMessage => 'Supprimer le message';

  @override
  String get chatDeleteForMe => 'Supprimer pour moi';

  @override
  String get chatDeleteForEveryone => 'Supprimer pour tout le monde';

  @override
  String get chatMessageForwarded => 'Message transféré';

  @override
  String get chatContactTapToOpen => 'Contact · appuyer pour ouvrir';

  @override
  String get chatForwardTo => 'Transférer à...';

  @override
  String get chatSearchHint => 'Rechercher...';

  @override
  String get chatRecording => 'Enregistrement...';

  @override
  String get chatMessageHint => 'Message...';

  @override
  String get chatHideKeyboard => 'Masquer le clavier';

  @override
  String get chatEditing => 'Modification';

  @override
  String get chatFileDownloadError => 'Erreur de téléchargement du fichier';

  @override
  String get chatVoiceMessageShort => 'Message vocal';

  @override
  String get chatVideoSavedToGallery => 'Vidéo enregistrée dans la galerie';

  @override
  String get chatSavingError => 'Erreur d\'enregistrement';

  @override
  String get convSetNickname => 'Définir un pseudo';

  @override
  String get convNicknameRequired =>
      'Un pseudo est requis pour utiliser le messager. Les autres utilisateurs peuvent vous trouver grâce à lui.';

  @override
  String get convNicknameRules => '3–30 caractères : lettres, chiffres, _';

  @override
  String get convNicknameTaken => 'Pseudo déjà pris';

  @override
  String get convSaveError => 'Erreur d\'enregistrement';

  @override
  String get convContactsLabel => 'Contacts';

  @override
  String get convDefaultUser => 'Utilisateur';

  @override
  String get convNoDialogs => 'Pas de conversations';

  @override
  String get convFindUserToChat =>
      'Trouver un utilisateur pour commencer à discuter';

  @override
  String get convDefaultContact => 'Contact';

  @override
  String get dashboardUser => 'Utilisateur';

  @override
  String get dashboardIncomingCall => 'Appel entrant';

  @override
  String get dashboardDecline => 'Refuser';

  @override
  String get dashboardAccept => 'Accepter';

  @override
  String get dashboardActiveCall => 'Appel en cours — appuyez pour revenir';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Mise à jour disponible $version';
  }

  @override
  String get dashboardUpdate => 'Mettre à jour';

  @override
  String get dashboardWhatsNew => 'Quoi de neuf';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Nouveautés de la version $version';
  }

  @override
  String get dashboardInstalling => 'Installation...';

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
  String get contactRequestsTitle => 'Contacts';

  @override
  String get messengerContactRequestsSection => 'Demandes de contact';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles demandes',
      one: '1 nouvelle demande',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Rechercher';

  @override
  String get contactRequestsIncoming => 'Entrantes';

  @override
  String get contactRequestsSent => 'Envoyées';

  @override
  String get contactRequestsSearchHint => 'Pseudo ou email';

  @override
  String get contactRequestSent => 'Demande envoyée';

  @override
  String get contactRequestsNoUsers => 'Aucun utilisateur trouvé';

  @override
  String get contactRequestsSearchHelp =>
      'Entrez le pseudo exact ou l\'email\net appuyez sur rechercher';

  @override
  String get contactRequestsSendTooltip => 'Envoyer la demande';

  @override
  String get contactRequestTitle => 'Demande de contact';

  @override
  String contactRequestConfirm(String name) {
    return 'Envoyer une demande de contact à $name ?';
  }

  @override
  String get contactRequestSend => 'Envoyer';

  @override
  String get contactRequestsNoIncoming => 'Aucune demande entrante';

  @override
  String get contactRequestsNoSent => 'Aucune demande envoyée';

  @override
  String get contactRequestStatusPending => 'En attente de réponse';

  @override
  String get contactRequestStatusAccepted => 'Acceptée';

  @override
  String get contactRequestStatusRejected => 'Rejetée';

  @override
  String get userSearchTitle => 'Trouver un utilisateur';

  @override
  String get userSearchHint => 'Pseudo, téléphone ou email';

  @override
  String get userSearchHelper => 'Entrez @pseudo, email ou nom pour rechercher';

  @override
  String get userSearchNoUsers => 'Aucun utilisateur trouvé';

  @override
  String get userProfileShareContact => 'Partager le contact';

  @override
  String get userProfileShareContactDesc => 'Envoyer le lien du contact';

  @override
  String get userProfileCopyLink => 'Copier le lien';

  @override
  String get userProfileCopied => 'Copié';

  @override
  String get userProfileTitle => 'Profil';

  @override
  String get userProfileLoadError => 'Erreur de chargement du profil';

  @override
  String get userProfileMessage => 'Message';

  @override
  String get userProfileCall => 'Appeler';

  @override
  String get userProfileRequestSent => 'Demande envoyée';

  @override
  String get userProfileAccept => 'Accepter';

  @override
  String get userProfileDecline => 'Refuser';

  @override
  String get userProfileAddToContacts => 'Ajouter aux contacts';

  @override
  String get userProfileMediaTab => 'Médias';

  @override
  String get userProfileFilesTab => 'Fichiers';

  @override
  String get userProfileLinksTab => 'Liens';

  @override
  String get userProfileRecordingsTab => 'Enregistrements';

  @override
  String get userProfileSummariesTab => 'Résumés';

  @override
  String get userProfileNoMedia => 'Aucun fichier média';

  @override
  String get userProfileNoFiles => 'Aucun fichier';

  @override
  String get userProfileNoLinks => 'Aucun lien';

  @override
  String get userProfileNoRecordings => 'Aucun enregistrement';

  @override
  String get userProfileNoSummaries => 'Aucun résumé';

  @override
  String get userProfileMeetingSummary => 'Résumé de la réunion';

  @override
  String get userProfileFailedOpenChat => 'Échec de l\'ouverture du chat';

  @override
  String get sharedMediaTitle => 'Médias et fichiers';

  @override
  String get sharedMediaTab => 'Médias';

  @override
  String get sharedFilesTab => 'Fichiers';

  @override
  String get sharedLinksTab => 'Liens';

  @override
  String get sharedNoMedia => 'Aucun fichier média';

  @override
  String get sharedNoFiles => 'Aucun fichier';

  @override
  String get sharedNoLinks => 'Aucun lien';

  @override
  String get shareToChat => 'Transférer au chat';

  @override
  String get shareSelectChat => 'Sélectionner un chat';

  @override
  String get shareNoChats => 'Aucun chat';

  @override
  String shareFilesCount(int count) {
    return '$count fichiers';
  }

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsAddTooltip => 'Ajouter un contact';

  @override
  String get contactsSearchHint => 'Rechercher des contacts...';

  @override
  String get contactsNotFound => 'Aucun résultat';

  @override
  String get contactsEmpty => 'Aucun contact';

  @override
  String get contactsAdd => 'Ajouter un contact';

  @override
  String get contactsPendingConfirmation => 'En attente de confirmation';

  @override
  String get contactsMessage => 'Message';

  @override
  String get contactsCall => 'Appeler';

  @override
  String get contactsResend => 'Renvoyer la demande';

  @override
  String get contactsResendTimeout => 'Réessayer dans 24h';

  @override
  String get contactsResent => 'Demande renvoyée';

  @override
  String get contactsWantsToConnect => 'Veut se connecter avec vous';

  @override
  String get contactsSearchPeople => 'Trouver des personnes';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesAssistantSpeaking => 'Assistant en train de parler...';

  @override
  String get notesListening => 'Écoute...';

  @override
  String get notesEmpty => 'Aucune note';

  @override
  String get notesEmptyHint =>
      'Appuyez sur le micro pour dicter\nou + pour une entrée manuelle';

  @override
  String get notesDeleteConfirm => 'Supprimer la note ?';

  @override
  String get notesNew => 'Nouvelle note';

  @override
  String get notesEdit => 'Modifier';

  @override
  String get notesTitleHint => 'Titre';

  @override
  String get notesContentHint => 'Écrivez vos pensées...';

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get calendarStop => 'Arrêter';

  @override
  String get calendarVoiceInput => 'Entrée vocale';

  @override
  String get calendarNewEvent => 'Nouvel événement';

  @override
  String get calendarAssistantSpeaking => 'Assistant en train de parler...';

  @override
  String get calendarListening => 'Écoute...';

  @override
  String calendarInvitations(int count) {
    return 'Invitations ($count)';
  }

  @override
  String get calendarNoEvents => 'Aucun événement';

  @override
  String get calendarDayMon => 'Lun';

  @override
  String get calendarDayTue => 'Mar';

  @override
  String get calendarDayWed => 'Mer';

  @override
  String get calendarDayThu => 'Jeu';

  @override
  String get calendarDayFri => 'Ven';

  @override
  String get calendarDaySat => 'Sam';

  @override
  String get calendarDaySun => 'Dim';

  @override
  String get calendarEnterRoom => 'Entrer dans la salle';

  @override
  String get calendarMeeting => 'Réunion';

  @override
  String calendarLocationPrefix(String location) {
    return 'Lieu : $location';
  }

  @override
  String get calendarEditEvent => 'Modifier';

  @override
  String get calendarTitleHint => 'Titre';

  @override
  String get calendarDescriptionHint => 'Description';

  @override
  String get calendarTypeEvent => 'Événement';

  @override
  String get calendarTypeMeeting => 'Réunion';

  @override
  String get calendarTypeReminder => 'Rappel';

  @override
  String get calendarTypeLabel => 'Type';

  @override
  String get calendarMeetingLink => 'Lien de la réunion';

  @override
  String get calendarLocationHint => 'Lieu';

  @override
  String get calendarDateLabel => 'Date';

  @override
  String get calendarTimeLabel => 'Heure';

  @override
  String get calendarReminderLabel => 'Rappel';

  @override
  String get calendarReminderNone => 'Aucun';

  @override
  String get calendarReminder15min => '15 min avant';

  @override
  String get calendarReminder30min => '30 min avant';

  @override
  String get calendarReminder1hour => '1 heure avant';

  @override
  String get calendarRepeatLabel => 'Répéter';

  @override
  String get calendarRepeatNone => 'Pas de répétition';

  @override
  String get calendarRepeatDaily => 'Tous les jours';

  @override
  String get calendarRepeatWeekly => 'Toutes les semaines';

  @override
  String get calendarRepeatMonthly => 'Tous les mois';

  @override
  String get calendarRepeatYearly => 'Tous les ans';

  @override
  String get calendarParticipants => 'Participants';

  @override
  String get calendarAddParticipant => 'Ajouter';

  @override
  String get calendarSearchContacts => 'Rechercher des contacts...';

  @override
  String get calendarNoContacts => 'Aucun contact';

  @override
  String get calendarStatusAccepted => 'Accepté';

  @override
  String get calendarStatusDeclined => 'Refusé';

  @override
  String get calendarStatusMaybe => 'Peut-être';

  @override
  String get calendarStatusPending => 'En attente';

  @override
  String get calendarEndTime => 'Heure de fin';

  @override
  String get calendarYourAnswer => 'Votre réponse :';

  @override
  String get calendarOrganizer => 'Organisateur';

  @override
  String calendarDeleteError(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get calendarRsvpAccept => 'Accepter';

  @override
  String get calendarRsvpMaybe => 'Peut-être';

  @override
  String get calendarRsvpDecline => 'Refuser';

  @override
  String get callHistoryTitle => 'Appels';

  @override
  String get callHistoryTab => 'Historique des appels';

  @override
  String get callHistoryTempMeeting => 'Réunion temporaire';

  @override
  String get callHistoryCopy => 'Copier';

  @override
  String get callHistoryLinkCopied => 'Lien copié';

  @override
  String get callHistoryShare => 'Partager';

  @override
  String get callHistoryEnter => 'Entrer';

  @override
  String get callHistoryAlreadyInCall => 'Déjà en appel';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Impossible de déterminer l\'autre partie';

  @override
  String get callHistoryContacts => 'Contacts';

  @override
  String get callHistoryFailedLoadRoom => 'Échec du chargement de votre salle';

  @override
  String get callHistoryYourRoom => 'Votre salle';

  @override
  String get callHistoryCreateMeeting => 'Créer une réunion';

  @override
  String get callHistoryMeetingSummaries => 'Résumés de réunion';

  @override
  String get callHistoryMeetingRecordings => 'Enregistrements de réunion';

  @override
  String get callHistoryNoCalls => 'Aucun appel';

  @override
  String get callHistoryMissed => 'Manqué';

  @override
  String get callHistoryRecording => 'Enregistrement';

  @override
  String get callHistorySummary => 'Résumé';

  @override
  String get callHistoryCallAgain => 'Rappeler';

  @override
  String callHistoryTodayTime(String time) {
    return 'Aujourd\'hui, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Hier, $time';
  }

  @override
  String get callHistoryUnknown => 'Inconnu';

  @override
  String get callHistoryDetails => 'Détails de l\'appel';

  @override
  String get callHistoryOutgoing => 'Appel sortant';

  @override
  String get callHistoryIncoming => 'Appel entrant';

  @override
  String callHistoryDuration(String duration) {
    return 'Durée : $duration';
  }

  @override
  String get callHistoryWithAI => 'Avec assistant AI';

  @override
  String get callHistoryParticipants => 'Participants';

  @override
  String get callDetailYouSuffix => '(Vous)';

  @override
  String get callHistoryMeetingSummary => 'Résumé de la réunion';

  @override
  String get callHistoryMoreDetails => 'Plus de détails';

  @override
  String get callHistorySummaryProcessing => 'Traitement du résumé...';

  @override
  String get callHistoryMeetingRecording => 'Enregistrement de la réunion';

  @override
  String get callHistoryProcessing => 'Traitement...';

  @override
  String get callHistoryCreateTranscript => 'Créer un transcript';

  @override
  String get callHistoryNoSummaries => 'Aucun résumé';

  @override
  String get callHistoryRecordDuringCall =>
      'Appuyez sur \"Enregistrer\" pendant un appel';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Réunion $time';
  }

  @override
  String get callHistoryTranscribing => 'Transcription et résumé...';

  @override
  String get callHistoryTranscriptCreated => 'Transcript créé';

  @override
  String get callHistoryNoRecordings => 'Aucun enregistrement';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Enregistrement $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Enregistrement indisponible';

  @override
  String get callHistoryTranscriptReady => 'Transcript prêt';

  @override
  String get callHistoryTranscript => 'Transcript';

  @override
  String get callHistoryKeyPoints => 'Points clés';

  @override
  String get callHistoryTasks => 'Tâches';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Assigné à : $assignee';
  }

  @override
  String get callHistoryDecisions => 'Décisions';

  @override
  String get callHistoryShowTranscript => 'Afficher le transcript complet';

  @override
  String get profileScanQr => 'Scanner QR';

  @override
  String get profileMyQrCode => 'Mon code QR';

  @override
  String profileAddMeShare(String userId) {
    return 'Ajoutez-moi dans Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Montrez ce code pour vous ajouter';

  @override
  String get profileEditDesc => 'Nom, prénom, patronyme, date de naissance';

  @override
  String get profileAboutMe => 'À propos de moi';

  @override
  String get profileAboutMeDesc => 'Valeurs, compétences, intérêts et plus';

  @override
  String get profileNotes => 'Notes';

  @override
  String get profileNotesDesc => 'Pensées, idées et notes';

  @override
  String get profileAvatarUpdated => 'Avatar mis à jour';

  @override
  String get profileNickname => 'Surnom';

  @override
  String get profileNotSet => 'Non défini';

  @override
  String get profileChangeNickname => 'Changer de surnom';

  @override
  String get profileNicknameUpdated => 'Surnom mis à jour';

  @override
  String get profileShareLabel => 'Partager';

  @override
  String get profileScanQrCode => 'Scanner le code QR';

  @override
  String get profilePointCamera => 'Pointez la caméra sur le code QR';

  @override
  String get profilePhotoCamera => 'Prendre une photo';

  @override
  String get profilePhotoGallery => 'Choisir depuis la galerie';

  @override
  String get editProfilePatronymic => 'Patronyme (facultatif)';

  @override
  String get editProfileDateFormat => 'JJ.MM.AAAA';

  @override
  String get aboutMeTitle => 'À propos de moi';

  @override
  String get aboutMeClickToFill => 'Cliquez pour remplir';

  @override
  String get aboutMeCoreValues => 'Valeurs';

  @override
  String get aboutMeWorldview => 'Vision du monde';

  @override
  String get aboutMeSkills => 'Compétences';

  @override
  String get aboutMeInterests => 'Intérêts';

  @override
  String get aboutMeDesires => 'Désirs';

  @override
  String get aboutMeBackground => 'Profil';

  @override
  String get aboutMeLikes => 'Aime';

  @override
  String get aboutMeDislikes => 'N\'aime pas';

  @override
  String get aboutMeDeleteSection => 'Supprimer la section?';

  @override
  String get aboutMeDeleteConfirm =>
      'Toutes les données de cette section seront supprimées.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get aboutMeVisibility => 'Visibilité';

  @override
  String get aboutMeTags => 'Tags';

  @override
  String get aboutMeAddTag => 'Ajouter un tag...';

  @override
  String get aboutMeDescription => 'Description';

  @override
  String get aboutMeDescribeLong => 'Dites-nous en plus...';

  @override
  String get aboutMeVisibilityEveryone => 'Tout le monde';

  @override
  String get aboutMeVisibilityContacts => 'Contacts';

  @override
  String get aboutMeVisibilityOnlyMe => 'Moi uniquement';

  @override
  String get settingsProfileSubtitle => 'Profil';

  @override
  String get settingsWallpaper => 'Fond d\'écran';

  @override
  String get settingsWallpaperDesc => 'Image de fond pour toute l\'application';

  @override
  String get settingsWallpaperNone => 'Aucun';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsKycVerification => 'Vérification d\'identité (KYC)';

  @override
  String get settingsOrganizations => 'Organisations';

  @override
  String get incomingCallLabel => 'Appel entrant';

  @override
  String get incomingCallDecline => 'Refuser';

  @override
  String get incomingCallAccept => 'Accepter';

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
  String get meshIncomingCallLabel => '📡 Appel mesh entrant';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Appareil mesh $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Terminez d\'abord l\'appel en cours';

  @override
  String get callPopupTransportTitle => 'Appeler via';

  @override
  String get callPopupTransportMesh => '📡 Mesh (pair-à-pair)';

  @override
  String get callPopupTransportLk => '📞 Serveur';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Contact non joignable via mesh';

  @override
  String get meshOnboardingTitle =>
      '📡 Les appels mesh nécessitent l\'application ouverte';

  @override
  String get meshOnboardingBody =>
      'Lorsque le téléphone est verrouillé, les appels mesh peuvent se couper après ~30 secondes (limitation iOS).';

  @override
  String get meshOnboardingAck => 'Compris';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable =>
      'Le contact n\'est pas dans votre liste';

  @override
  String get meshCallStatusInviting => 'Appel en cours…';

  @override
  String get meshCallStatusConnecting => 'Connexion…';

  @override
  String get meshCallEndedUserHangup => 'Appel terminé';

  @override
  String get meshCallEndedRemoteHangup => 'Terminé par le pair';

  @override
  String get meshCallEndedRejected => 'Refusé';

  @override
  String get meshCallEndedNoAnswer => 'Pas de réponse';

  @override
  String get meshCallEndedConnectionLost => 'Connexion perdue';

  @override
  String get meshCallEndedError => 'Erreur de connexion';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Appels mesh fiables';

  @override
  String get batteryExemptionBody =>
      'Autorisez l\'application à fonctionner sans restrictions de batterie pour qu\'Android ne coupe pas le mesh en arrière-plan.';

  @override
  String get batteryExemptionAccept => 'Ouvrir les paramètres';

  @override
  String get batteryExemptionDismiss => 'Pas maintenant';

  @override
  String get groupCamera => 'Caméra';

  @override
  String get groupGallery => 'Galerie';

  @override
  String get groupAvatarUpdated => 'Avatar du groupe mis à jour';

  @override
  String get groupNameTitle => 'Nom du groupe';

  @override
  String get groupEnterName => 'Entrez le nom';

  @override
  String get groupDescriptionTitle => 'Description du groupe';

  @override
  String get groupEnterDescription => 'Entrez la description du groupe';

  @override
  String get groupChangeRoleTitle => 'Changer de rôle';

  @override
  String get groupRemoveMemberTitle => 'Supprimer le membre';

  @override
  String get groupDescription => 'Description';

  @override
  String get groupAddDescription => 'Ajouter une description au groupe';

  @override
  String get groupNoDescription => 'Pas de description';

  @override
  String get groupMediaAndFiles => 'Médias et fichiers';

  @override
  String get groupMuteNotifications => 'Désactiver les notifications';

  @override
  String get groupMuted => 'Désactivé';

  @override
  String get groupNoResults => 'Aucun résultat';

  @override
  String get authInvalidCode => 'Code invalide. Réessayez.';

  @override
  String get loginSubtitle => 'Utilisez l\'email et le mot de passe';

  @override
  String get emailRequired => 'Entrez l\'email';

  @override
  String get emailInvalid => 'Email invalide';

  @override
  String get passwordRequired => 'Entrez le mot de passe';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Un compte pour tout l\'écosystème Taler';

  @override
  String get usernameOptional => 'Nom d\'utilisateur (facultatif)';

  @override
  String get usernameMinLength => 'Minimum 3 caractères';

  @override
  String get usernameMaxLength => 'Maximum 30 caractères';

  @override
  String get usernameInvalid => 'Seulement des lettres, chiffres et _';

  @override
  String get biometricLoginReason => 'Connectez-vous à Taler ID';

  @override
  String get docTypePassport => 'Passeport';

  @override
  String get docTypeIdCard => 'Carte d\'identité';

  @override
  String get docTypeDriverLicense => 'Permis de conduire';

  @override
  String get docTypeResidencePermit => 'Titre de séjour';

  @override
  String addressApartment(String number) {
    return 'app. $number';
  }

  @override
  String get failedToUpdateProfile => 'Échec de la mise à jour du profil';

  @override
  String get failedToStartKyb => 'Échec du démarrage de la vérification KYB';

  @override
  String get orgUpdated => 'Organisation mise à jour';

  @override
  String get failedToUpdateOrg => 'Échec de la mise à jour de l\'organisation';

  @override
  String get failedToChangeRole => 'Échec du changement de rôle';

  @override
  String get failedToRemoveMember => 'Échec de la suppression du membre';

  @override
  String get capabilityMessagesTitle => 'Messages';

  @override
  String get capabilityMessagesDesc =>
      'Consultez les messages ou écrivez à quelqu\'un. Par exemple : \"Écrire à Viktor : serai là dans une heure\"';

  @override
  String get capabilityCallsTitle => 'Appels';

  @override
  String get capabilityCallsDesc =>
      'Appelez un contact par voix. Par exemple : \"Appeler Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Historique de chat';

  @override
  String get capabilityChatDesc =>
      'Je vais analyser l\'historique de chat. Par exemple : \"De quoi avons-nous discuté avec Viktor ?\"';

  @override
  String get capabilityProfileTitle => 'Profil';

  @override
  String get capabilityProfileDesc =>
      'Je vais afficher ou mettre à jour votre profil. Par exemple : \"Afficher mon profil\"';

  @override
  String get capabilityCoachingTitle => 'Coaching';

  @override
  String get capabilityCoachingDesc =>
      'Modes : coaching ICF, psychologue, consultation RH. Dites : \"Faisons du coaching\"';

  @override
  String get capabilityCalendarTitle => 'Calendrier';

  @override
  String get capabilityCalendarDesc =>
      'Planifiez une réunion ou définissez un rappel. Par exemple : \"Planifier une réunion avec Viktor pour demain à 15:00\"';

  @override
  String get capabilityNotesTitle => 'Notes';

  @override
  String get capabilityNotesDesc =>
      'Enregistrez une idée ou lisez les notes récentes. Par exemple : \"Notez une idée...\" ou \"Lire les notes récentes\"';

  @override
  String get assistantCallConfirm => 'Passer un appel ?';

  @override
  String get callNoAnswer => 'Pas de réponse';

  @override
  String get contactDelete => 'Supprimer le contact';

  @override
  String get contactDeleteTitle => 'Supprimer le contact';

  @override
  String get contactDeleteConfirm =>
      'Êtes-vous sûr ? Ce contact sera supprimé.';

  @override
  String get contactBlock => 'Bloquer';

  @override
  String get contactBlockTitle => 'Bloquer l\'utilisateur';

  @override
  String get contactBlockConfirm =>
      'Cet utilisateur ne pourra pas vous envoyer de messages ou vous appeler.';

  @override
  String get contactUnblock => 'Débloquer';

  @override
  String get contactBlocked => 'Bloqué';

  @override
  String get contactYouAreBlocked => 'Cet utilisateur vous a bloqué';

  @override
  String get chatBlockedByYou => 'Vous avez bloqué cet utilisateur';

  @override
  String get chatYouAreBlocked => 'Vous avez été bloqué par cet utilisateur';

  @override
  String get chatNotContacts =>
      'Ajoutez cet utilisateur aux contacts pour lui envoyer un message';

  @override
  String get contactRevokeRequest => 'Révoquer la demande';

  @override
  String get messengerPoll => 'Sondage';

  @override
  String get messengerCreatePoll => 'Créer un sondage';

  @override
  String get messengerPollQuestion => 'Question';

  @override
  String messengerPollOption(int number) {
    return 'Option $number';
  }

  @override
  String get messengerPollAddOption => 'Ajouter une option';

  @override
  String get messengerPollAnonymous => 'Vote anonyme';

  @override
  String get messengerPollMultiple => 'Choix multiple';

  @override
  String get messengerPollCreateError => 'Échec de la création du sondage';

  @override
  String get messengerPollUnavailable => 'Sondage indisponible';

  @override
  String get messengerPollMultipleNote => 'Vous pouvez sélectionner plusieurs';

  @override
  String messengerPollVotes(int count) {
    return '$count votes';
  }

  @override
  String get messengerVideoMessage => 'Message vidéo';

  @override
  String get messengerVideoRecordError => 'Erreur d\'enregistrement vidéo';

  @override
  String get messengerVideoPlaybackError => 'Impossible de lire la vidéo';

  @override
  String get messengerGalleryAccessError => 'Pas d\'accès à la galerie';

  @override
  String get messengerSearchInChat => 'Rechercher dans le chat...';

  @override
  String get messengerSaveToFavorites => 'Enregistrer dans les favoris';

  @override
  String get messengerSavedToFavorites => 'Enregistré dans les favoris';

  @override
  String get messengerSearchInMessages => 'Rechercher dans les messages...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Trouvé dans les messages ($count)';
  }

  @override
  String get messengerGroupDefault => 'Groupe';

  @override
  String get messengerUserDefault => 'Utilisateur';

  @override
  String get messengerPin => 'Épingler';

  @override
  String get messengerUnpin => 'Désépingler';

  @override
  String get messengerArchive => 'Archiver';

  @override
  String get messengerUnarchive => 'Désarchiver';

  @override
  String get messengerDeleteChat => 'Supprimer le chat';

  @override
  String get messengerDeleteChatTitle => 'Supprimer le chat ?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Supprimer le chat avec $name ? Cela ne peut pas être annulé.';
  }

  @override
  String get messengerCreateChannel => 'Créer un canal';

  @override
  String get messengerChannelName => 'Nom';

  @override
  String get messengerChannelDescription => 'Description (facultatif)';

  @override
  String get messengerChannelCreateError => 'Échec de la création du canal';

  @override
  String get messengerFilterAll => 'Tous';

  @override
  String get messengerFilterUnread => 'Non lus';

  @override
  String get messengerFilterPersonal => 'Personnel';

  @override
  String get messengerFilterGroups => 'Groupes';

  @override
  String get messengerFilterChannels => 'Canaux';

  @override
  String get messengerArchivedSection => 'Archivés';

  @override
  String get messengerSavedSection => 'Favoris';

  @override
  String get messengerSavedSubtitle => 'Enregistrer en mémoire';

  @override
  String messengerArchiveTitle(int count) {
    return 'Archive ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'L\'archive est vide';

  @override
  String messengerYouPrefix(String message) {
    return 'Vous : $message';
  }

  @override
  String get messengerMissedCall => 'Appel manqué';

  @override
  String get messengerSavedTitle => 'Favoris';

  @override
  String get messengerNoSavedMessages => 'Aucun message enregistré';

  @override
  String get messengerSavedHint =>
      'Appuyez longuement sur un message → \"Enregistrer dans les favoris\"';

  @override
  String get messengerDefaultFile => 'Fichier';

  @override
  String get messengerTopicDefault => 'Général';

  @override
  String get messengerTopicNew => 'Nouveau sujet';

  @override
  String get messengerTopicNameHint => 'Nom du sujet';

  @override
  String get messengerTopicIcon => 'Icône';

  @override
  String messengerTopicCount(int count) {
    return '$count sujets';
  }

  @override
  String get messengerNoTopics => 'Aucun sujet';

  @override
  String get messengerNoMessages => 'Pas de messages';

  @override
  String get you => 'Vous';

  @override
  String get messengerThread => 'Fil';

  @override
  String get messengerThreadReply => 'réponse';

  @override
  String get messengerThreadReplies => 'réponses';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Pas de réponses';

  @override
  String get messengerReplyHint => 'Répondre au fil...';

  @override
  String get messengerContactName => 'Nom du contact';

  @override
  String messengerOriginalName(String name) {
    return 'Nom original : $name';
  }

  @override
  String get messengerDisplayName => 'Nom d\'affichage';

  @override
  String messengerShareContact(String name) {
    return 'Contact dans Taler ID : $name';
  }

  @override
  String get messengerAutoDelete => 'Suppression automatique des messages';

  @override
  String get messengerAutoDeleteOff => 'Désactivé';

  @override
  String get messengerAutoDelete7d => '7 jours';

  @override
  String get messengerAutoDelete30d => '30 jours';

  @override
  String get messengerAutoDelete90d => '90 jours';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count jours';
  }

  @override
  String get messengerSettingsHeader => 'Paramètres';

  @override
  String get messengerAdminOnly => 'Publication réservée aux admins';

  @override
  String get messengerAdminOnlyDesc => 'Les membres peuvent seulement lire';

  @override
  String get messengerTopics => 'Sujets';

  @override
  String get messengerTopicsDesc => 'Diviser le chat en sujets';

  @override
  String get aiTwinSection => 'Jumeau Vocal AI';

  @override
  String get aiTwinEnabled => 'Activer le Jumeau AI';

  @override
  String get aiTwinEnabledDesc =>
      'Si vous ne répondez pas, votre jumeau AI prend l\'appel avec votre voix';

  @override
  String get aiTwinTimeout => 'Délai de réponse';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds sec';
  }

  @override
  String get aiTwinPrompt => 'Instructions AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Comment le jumeau AI doit se présenter et de quoi parler';

  @override
  String aiTwinPromptHint(String name) {
    return 'Bonjour, c\'est le jumeau vocal AI de $name. $name ne peut pas répondre pour le moment. Dites-moi qui appelle et de quoi il s\'agit — je transmettrai le message.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Clonage vocal personnalisé bientôt disponible. Pour l\'instant, l\'AI parle avec la voix de $name.';
  }

  @override
  String get aiTwinDefaultName => 'le propriétaire';

  @override
  String get aiTwinPromptReset => 'Réinitialiser';

  @override
  String get callHistoryAiTwinAnswered => 'RÉPONDU PAR JUMEAU AI';

  @override
  String get callHistoryAiTwinSummary => 'RÉSUMÉ DE L\'APPEL';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSCRIPTION';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'De $name';
  }

  @override
  String get aiTwinOfferTitle => 'Pas de réponse';

  @override
  String aiTwinOfferBody(String name) {
    return '$name ne répond pas. Laisser un message avec son jumeau vocal AI ?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Utilisateur';

  @override
  String get aiTwinOfferAccept => 'Oui, laisser un message';

  @override
  String get aiTwinOfferKeepWaiting => 'Continuer d\'attendre';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Votre remplaçant AI';

  @override
  String get aiTwinHeroSubtitle =>
      'Répond aux appels avec votre voix quand vous ne pouvez pas.';

  @override
  String get aiTwinProfileTitle => 'Remplaçant AI';

  @override
  String get aiTwinProfileDesc => 'Répond aux appels avec votre voix';

  @override
  String get aiTwinBadgeOn => 'ACTIVÉ';

  @override
  String get aiAnalystTitle => 'Analyste AI';

  @override
  String get aiAnalystSubtitle => 'Fichiers, tâches, analyses — Claude';

  @override
  String get channelsDiscover => 'Trouver un canal';

  @override
  String get channelsSearchHint => 'Rechercher des canaux';

  @override
  String get channelsSubscribers => 'abonnés';

  @override
  String get channelsSubscribe => 'S\'abonner';

  @override
  String get channelsUnsubscribe => 'Se désabonner';

  @override
  String get channelsSubscribedLabel => 'Vous êtes abonné';

  @override
  String get channelsSettings => 'Paramètres du canal';

  @override
  String get channelsDelete => 'Supprimer le canal';

  @override
  String get channelsDeleteConfirm => 'Supprimer le canal définitivement ?';

  @override
  String get channelsEmpty => 'Pas encore de canaux';

  @override
  String get channelsOpen => 'Ouvrir';

  @override
  String get channelsNameLabel => 'Nom';

  @override
  String get channelsDescriptionLabel => 'Description';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Le propriétaire ne peut pas se désabonner. Supprimez le canal à la place.';

  @override
  String get channelsNotFoundRedirect => 'Le canal n\'existe plus';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recherches',
      one: '$count recherche',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '$count fichier',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes',
      one: '$count commande',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '$count image',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étapes',
      one: '$count étape',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Messages enregistrés';

  @override
  String get savedSubtitle => 'Votre cloud privé';

  @override
  String get savedOpenError => 'Impossible d\'ouvrir les messages enregistrés';

  @override
  String get billingWalletTitle => 'Portefeuille';

  @override
  String get billingBuyPackage => 'Acheter un forfait';

  @override
  String get billingCurrentBalance => 'Solde actuel';

  @override
  String get billingPackagesTitle => 'Forfaits';

  @override
  String get billingPackagesUnavailable => 'Forfaits indisponibles';

  @override
  String get billingRecentOperations => 'Opérations récentes';

  @override
  String get billingAllOperations => 'Toutes les opérations';

  @override
  String get billingNoOperations => 'Aucune opération';

  @override
  String get billingOperationsTitle => 'Opérations';

  @override
  String get billingOperationsEmptyTitle => 'Aucune opération pour le moment';

  @override
  String get billingOperationsEmptySubtitle =>
      'Les recharges et frais pour les fonctionnalités AI apparaîtront ici';

  @override
  String get billingPricebookTitle => 'Tarifs des fonctionnalités';

  @override
  String get billingPricebookUnavailable => 'Liste des prix indisponible';

  @override
  String get billingAiFeaturesTitle => 'Fonctionnalités AI';

  @override
  String get billingInsufficientFundsTitle => 'Fonds insuffisants';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Recharger votre solde pour utiliser cette fonctionnalité.';

  @override
  String billingRequiredLine(String required) {
    return 'Nécessaire : $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Disponible : $available μTAL';
  }

  @override
  String get billingTopUp => 'Recharger';

  @override
  String get billingCancel => 'Annuler';

  @override
  String get billingRetry => 'Réessayer';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Solde faible : $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Portefeuille & Solde';

  @override
  String get billingSectionHeader => 'Facturation & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Assistant vocal';

  @override
  String get billingFeatureWebSearch => 'Recherche web de l\'assistant';

  @override
  String get billingFeatureAiTwin => 'Jumeau vocal';

  @override
  String get billingFeatureAiTwinLong => 'Jumeau vocal (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot d\'appel sortant';

  @override
  String get billingFeatureOutboundCallLong => 'Bot d\'appels sortants';

  @override
  String get billingFeatureWhisperTranscribe => 'Transcription d\'appel';

  @override
  String get billingFeatureMeetingSummary => 'Résumés d\'appels AI';

  @override
  String get billingConfigureAiTwin => 'Configurer le jumeau AI';

  @override
  String get billingWebSearchSubtitle => '(utilisé par l\'assistant)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Forfait acheté : $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Recommandé';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Solde épuisé — session terminée';

  @override
  String get billingSessionTerminatedGeneric =>
      'Session de l\'assistant terminée';

  @override
  String billingBuyForPrice(String price) {
    return 'Acheter pour $price €';
  }

  @override
  String get billingTxTypeTopup => 'Recharge';

  @override
  String get billingTxTypeRefund => 'Remboursement';

  @override
  String get billingTxTypeSpend => 'Frais';

  @override
  String get billingUnitMinute => 'minute';

  @override
  String get billingUnitRequest => 'demande';

  @override
  String get billingUnitToken => 'jeton';

  @override
  String get billingUnitTokens1k => '1K jetons';

  @override
  String get billingUnitCall => 'appel';

  @override
  String get groupCallSelectParticipants => 'Sélectionner les participants';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Rechercher';

  @override
  String get groupCallMaxReached => 'Maximum 7 participants';

  @override
  String get groupCallLobbyTitle => 'Groupe • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Hôte : $name';
  }

  @override
  String get groupCallMicHint => 'Le micro s\'activera à la connexion';

  @override
  String get groupCallCancel => 'Annuler';

  @override
  String get groupCallNoAnswer => 'Personne n\'a répondu';

  @override
  String get groupCallEndedByHost => 'Appel terminé par l\'hôte';

  @override
  String get groupCallAllLeft => 'Tout le monde a quitté l\'appel';

  @override
  String get groupCallEnded => 'Appel terminé';

  @override
  String groupCallActiveTitle(int count) {
    return 'Groupe • $count';
  }

  @override
  String get groupCallConnectionLost => 'Connexion perdue';

  @override
  String get groupCallMuteRequested =>
      'L\'hôte a demandé à tout le monde de couper le son';

  @override
  String get groupCallUnmute => 'Réactiver le son';

  @override
  String get groupCallMute => 'Couper le son';

  @override
  String get groupCallMuteAll => 'Couper le son de tous';

  @override
  String get groupCallLeave => 'Quitter';

  @override
  String get groupCallStatusCalling => 'appel en cours…';

  @override
  String get groupCallStatusDeclined => 'refusé';

  @override
  String get groupCallStatusTimeout => 'pas de réponse';

  @override
  String get groupCallStatusLeft => 'quitté';

  @override
  String groupCallKickConfirm(String name) {
    return 'Retirer $name de l\'appel';
  }

  @override
  String get groupCallCancelAction => 'Annuler';

  @override
  String get groupCallActiveBanner => 'Appel en cours';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Groupe : $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Groupe : $host';
  }

  @override
  String get groupCallCreateError => 'Impossible de créer l\'appel';

  @override
  String get groupCallJoinError => 'Impossible de rejoindre l\'appel';

  @override
  String get groupCallLivekitError => 'Erreur LiveKit';

  @override
  String get groupCallDone => 'Terminé';

  @override
  String get groupCallNoResults => 'Aucun résultat';

  @override
  String get groupCallNoContacts => 'Aucun contact';

  @override
  String get meshGcContactOffline => 'Pas sur ce Wi-Fi';

  @override
  String get meshGcOnlineViaMesh => 'En ligne via le mesh';

  @override
  String get meshGcMaxInvitees =>
      'Les appels de groupe supportent jusqu\'à 4 invités (5 personnes au total).';

  @override
  String get meshGcStart => 'Démarrer l\'appel de groupe';

  @override
  String get meshGcCancel => 'Annuler';

  @override
  String get meshGcStatusCalling => 'Appel en cours…';

  @override
  String get meshGcStatusJoined => 'Rejoint';

  @override
  String get meshGcStatusDeclined => 'Refusé';

  @override
  String get meshGcStatusNoAnswer => 'Pas de réponse';

  @override
  String get meshGcStatusConnectionFailed => 'Échec de la connexion';

  @override
  String get meshGcStatusLeft => 'Parti';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Terminez d\'abord votre appel en cours.';

  @override
  String get presenceOnline => 'en ligne';

  @override
  String get presenceLastSeenJustNow => 'vu à l\'instant';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'vu il y a $minutes min';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'vu aujourd\'hui à $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'vu hier à $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'vu le $date';
  }

  @override
  String get presenceLastSeenRecently => 'vu récemment';

  @override
  String get privacySectionTitle => 'Confidentialité';

  @override
  String get privacyLastSeenLabel =>
      'Qui voit votre dernière heure de connexion';

  @override
  String get privacyEveryone => 'Tout le monde';

  @override
  String get privacyContacts => 'Contacts uniquement';

  @override
  String get privacyNobody => 'Personne';

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
