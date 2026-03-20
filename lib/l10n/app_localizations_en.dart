// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Search';

  @override
  String get appSubtitle => 'Unified ecosystem identity';

  @override
  String get login => 'Sign In';

  @override
  String get loginButton => 'Sign In';

  @override
  String get register => 'Create Account';

  @override
  String get registerButton => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createOne => 'Create one';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign In';

  @override
  String get passwordMinLength => 'Minimum 8 characters';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get twoFATitle => 'Two-Factor Authentication';

  @override
  String get twoFASubtitle =>
      'Enter the 6-digit code from your authenticator app';

  @override
  String get twoFACode => '2FA Code';

  @override
  String get verify => 'Verify';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organization';

  @override
  String get tabSettings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get phone => 'Phone';

  @override
  String get country => 'Country';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get documents => 'Documents';

  @override
  String get addDocument => 'Add Document';

  @override
  String get noDocuments => 'No documents uploaded';

  @override
  String get save => 'Save';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get personalData => 'Personal Data';

  @override
  String get passport => 'Passport';

  @override
  String get drivingLicense => 'Driving License';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'National ID';

  @override
  String get certificate => 'Certificate';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get notSpecifiedFemale => 'Not specified';

  @override
  String get documentType => 'Document Type';

  @override
  String get passportId => 'Passport / ID';

  @override
  String get diplomaCertificate => 'Diploma / Certificate';

  @override
  String get loadError => 'Loading error';

  @override
  String get verification => 'Verification';

  @override
  String get countryAustria => 'Austria';

  @override
  String get countryGermany => 'Germany';

  @override
  String get countryRussia => 'Russia';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryKazakhstan => 'Kazakhstan';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryOther => 'Other';

  @override
  String get kycTitle => 'KYC Verification';

  @override
  String get kycVerified => 'Verified';

  @override
  String get kycPending => 'Pending';

  @override
  String get kycRejected => 'Rejected';

  @override
  String get kycUnverified => 'Unverified';

  @override
  String get kycVerifiedDesc =>
      'Your identity has been verified. You have full access to all Taler ecosystem features.';

  @override
  String get kycPendingDesc =>
      'Your documents are being reviewed. This usually takes 1-2 business days.';

  @override
  String get kycRejectedDesc =>
      'Verification failed. Please review the reason and resubmit your documents.';

  @override
  String get kycUnverifiedDesc =>
      'Complete verification to unlock full access to Taler ecosystem financial features.';

  @override
  String get startVerification => 'Start Verification';

  @override
  String get retryVerification => 'Retry Verification';

  @override
  String verifiedAt(String date) {
    return 'Verified: $date';
  }

  @override
  String get documentsSubmitted => 'Documents submitted for review';

  @override
  String get documentsSubmittedDesc =>
      'Review usually takes 1-2 business days. You will receive a push notification with the result.';

  @override
  String get securityAes => 'Your data is protected with AES-256 encryption';

  @override
  String get verificationTime => 'Verification takes 1-2 business days';

  @override
  String get pushNotification =>
      'You will receive a push notification with the result';

  @override
  String get kycWebOnly =>
      'KYC verification is only available in the mobile app.';

  @override
  String verificationError(String code) {
    return 'Verification error: $code';
  }

  @override
  String get organizations => 'Organizations';

  @override
  String get noOrganizations => 'No organizations';

  @override
  String get noOrganizationsDesc =>
      'Create an organization or accept an invitation';

  @override
  String get createOrganization => 'Create Organization';

  @override
  String get newOrganization => 'New Organization';

  @override
  String get orgName => 'Name *';

  @override
  String get orgDescription => 'Description';

  @override
  String get orgEmail => 'Contact Email';

  @override
  String get orgWebsite => 'Website';

  @override
  String get orgLegalAddress => 'Legal Address';

  @override
  String get create => 'Create';

  @override
  String get organization => 'Organization';

  @override
  String get contacts => 'Contacts';

  @override
  String members(int count) {
    return 'Members ($count)';
  }

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get invite => 'Invite';

  @override
  String get sendInvite => 'Send Invitation';

  @override
  String inviteSent(String email) {
    return 'Invitation sent to $email';
  }

  @override
  String get role => 'Role';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get editOrganization => 'Edit';

  @override
  String get editOrganizationTitle => 'Edit Organization';

  @override
  String get removeMember => 'Remove Member';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from organization?';
  }

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get roleChanged => 'Role changed';

  @override
  String get kybVerified => 'Verified';

  @override
  String get kybPending => 'Pending';

  @override
  String get kybRejected => 'Rejected';

  @override
  String get kybNone => 'Unverified';

  @override
  String get kybVerification => 'Start KYB Verification';

  @override
  String get kybStartBusiness => 'Start Business Verification';

  @override
  String get kybStatusLabel => 'KYB Status';

  @override
  String get noKyb => 'No KYB';

  @override
  String get kybBusinessVerificationTitle => 'Business Verification (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organization successfully verified.';

  @override
  String get kybPendingOrgDesc =>
      'Documents are being reviewed. This usually takes 1-3 business days.';

  @override
  String get kybRejectedOrgDesc => 'Verification failed. Please try again.';

  @override
  String get kybNoneOrgDesc =>
      'Verify your organization to access business features.';

  @override
  String get invitePlus => '+ Invite';

  @override
  String get kybVerificationTitle => 'KYB Verification';

  @override
  String get kybWebOnlyBusiness =>
      'KYB verification is only available in the mobile app.';

  @override
  String get unknownDevice => 'Unknown device';

  @override
  String get ipUnknown => 'IP unknown';

  @override
  String get currentSessionLabel => 'Current';

  @override
  String get endSessionAction => 'End';

  @override
  String get deviceLoggedOut => 'Device will be signed out.';

  @override
  String get acceptInvitationTitle => 'Organization Invitation';

  @override
  String get acceptInvitation => 'Accept Invitation';

  @override
  String get acceptInvitationDesc =>
      'You\'ve been invited to join an organization in the Taler ecosystem.';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get sessions => 'Active Sessions';

  @override
  String get currentSession => 'Current session';

  @override
  String get deleteSession => 'End Session';

  @override
  String get deleteSessionConfirm => 'End this session?';

  @override
  String get sessionDeleted => 'Session ended';

  @override
  String get noSessions => 'No active sessions';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get settings => 'Settings';

  @override
  String get security => 'Security';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get biometricsDesc => 'Quick login with Face ID or fingerprint';

  @override
  String get biometricsConfirm => 'Confirm biometrics to enable quick login';

  @override
  String get biometricsError =>
      'Failed to enable biometrics. Check device settings.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushKycStatus => 'KYC Status Push';

  @override
  String get pushKycStatusDesc => 'Verification result';

  @override
  String get pushLogins => 'Login Push';

  @override
  String get pushLoginsDesc => 'When signing in from a new device';

  @override
  String get account => 'Account';

  @override
  String get language => 'Language';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Interface Language';

  @override
  String get exportData => 'Export Data (GDPR)';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm => 'Delete account?';

  @override
  String get deleteAccountDesc =>
      'All your data will be deleted (GDPR). This action is irreversible.';

  @override
  String get logout => 'Sign Out';

  @override
  String get logoutConfirm => 'Sign out?';

  @override
  String get logoutDesc => 'You will be signed out of Taler ID on this device.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN Code';

  @override
  String get pinCodeDesc => 'Quick login with 4-digit code';

  @override
  String get setupPin => 'Set Up PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinMismatch => 'PINs don\'t match';

  @override
  String get pinSet => 'PIN set successfully';

  @override
  String get enterPinToLogin => 'Enter PIN to sign in';

  @override
  String get pinIncorrect => 'Incorrect PIN';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get pinRemoved => 'PIN removed';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noData => 'No data';

  @override
  String get failedToLoad => 'Failed to load data';

  @override
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get failedToSave => 'Failed to save changes';

  @override
  String get failedToLoadOrgs => 'Failed to load organizations';

  @override
  String get failedToLoadOrg => 'Failed to load organization data';

  @override
  String get failedToCreateOrg => 'Failed to create organization';

  @override
  String get failedToInvite => 'Failed to send invitation';

  @override
  String get failedToAcceptInvite => 'Failed to accept invitation';

  @override
  String get failedToLoadSessions => 'Failed to load sessions';

  @override
  String get failedToDeleteSession => 'Failed to end session';

  @override
  String get failedToLoadKyc => 'Failed to load verification status';

  @override
  String get failedToStartKyc => 'Failed to start verification';

  @override
  String get verifiedPersonalInfo => 'Verified Data';

  @override
  String get middleName => 'Middle Name';

  @override
  String get placeOfBirth => 'Place of Birth';

  @override
  String get nationality => 'Nationality';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get docNumber => 'Number';

  @override
  String get docIssuedDate => 'Issued';

  @override
  String get docValidUntil => 'Valid Until';

  @override
  String get docIssuedBy => 'Issued By';

  @override
  String get address => 'Address';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get failedToLoadSumsubData => 'Failed to load verification data';

  @override
  String get sumsubDataLoading => 'Loading verification data...';

  @override
  String get reviewResultGreen => 'Verification passed';

  @override
  String get reviewResultRed => 'Verification failed';

  @override
  String get chatTitle => 'Assistant';

  @override
  String get chatHint => 'Type a message...';

  @override
  String get chatListening => 'Listening...';

  @override
  String get chatError => 'Connection error';

  @override
  String get chatClear => 'Clear chat';

  @override
  String get chatEmpty => 'Ask the assistant a question';

  @override
  String get tabAssistant => 'Assistant';

  @override
  String get assistantConnecting => 'Connecting…';

  @override
  String get assistantSpeaking => 'Speaking…';

  @override
  String get assistantListening => 'Listening…';

  @override
  String get assistantTapToStart => 'Tap to start';

  @override
  String get assistantTapToTalk => 'Tap to talk to AI';

  @override
  String get assistantRealtimeDesc =>
      'Assistant responds with voice in real time';

  @override
  String get assistantConnectingToAssistant => 'Connecting to assistant...';

  @override
  String get assistantAiSpeaking => 'AI speaking...';

  @override
  String get assistantAiListening => 'AI listening';

  @override
  String get assistantSpeakerOn => 'Speaker on';

  @override
  String get assistantSpeaker => 'Speaker';

  @override
  String get assistantEnd => 'End';

  @override
  String get assistantUnmute => 'Unmute';

  @override
  String get assistantMicrophone => 'Microphone';

  @override
  String get assistantConnectionError => 'Connection error';

  @override
  String get tabMessenger => 'Messages';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSelect => 'Choose Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get onboardingTitle1 => 'Unified Identity';

  @override
  String get onboardingDesc1 =>
      'Taler ID is your digital passport in the Taler ecosystem. One account for all services.';

  @override
  String get onboardingTitle2 => 'Data Security';

  @override
  String get onboardingDesc2 =>
      'KYC verification, AES-256 encryption, and two-factor authentication protect your identity.';

  @override
  String get onboardingTitle3 => 'Stay Informed';

  @override
  String get onboardingDesc3 =>
      'Get notified about verification status, logins from new devices, and incoming calls.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingEnableNotifications => 'Enable Notifications';

  @override
  String get onboardingTitle4 => 'Voice Calls';

  @override
  String get onboardingDesc4 =>
      'Grant microphone access for voice calls and AI assistant. You can change this later in settings.';

  @override
  String get onboardingEnableMicrophone => 'Enable Microphone';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email to receive a reset code';

  @override
  String resetCodeSent(String email) {
    return 'Code sent to $email';
  }

  @override
  String get enterResetCode => 'Enter the code';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get sendCode => 'Send Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get newGroup => 'New Group';

  @override
  String get newChat => 'New Chat';

  @override
  String get groupName => 'Group Name';

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupInfo => 'Group Info';

  @override
  String groupMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String get addMembers => 'Add Members';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get leaveGroupConfirm => 'Leave this group?';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get deleteGroupConfirm => 'Delete this group? This cannot be undone.';

  @override
  String get groupRoleOwner => 'Owner';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Member';

  @override
  String get selectParticipants => 'Select participants';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get changeRole => 'Change Role';

  @override
  String get groupCreated => 'Group created';

  @override
  String memberJoined(String name) {
    return '$name joined';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name left';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name was removed';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name is now $role';
  }

  @override
  String participantsCount(int count) {
    return '$count participants';
  }

  @override
  String get enterGroupName => 'Enter group name';

  @override
  String get muteNotifications => 'Mute notifications';

  @override
  String get unmuteNotifications => 'Unmute notifications';

  @override
  String get muteFor1Hour => 'For 1 hour';

  @override
  String get muteFor8Hours => 'For 8 hours';

  @override
  String get muteFor2Days => 'For 2 days';

  @override
  String get muteForever => 'Forever';

  @override
  String get muted => 'Muted';

  @override
  String get tabTranslator => 'Translate';

  @override
  String get translatorTitle => 'Translator';

  @override
  String get translatorSelectLanguage => 'Select language';

  @override
  String get translatorDownloading => 'Downloading language models...';

  @override
  String get translatorDownloadingHint =>
      'Internet is needed only for the first download';

  @override
  String get translatorTypeHint => 'Type text or tap the microphone';

  @override
  String get translatorListening => 'Listening...';

  @override
  String get translatorTapToSpeak => 'Tap to speak';

  @override
  String get translatorTapToStop => 'Tap to stop';

  @override
  String get translatorAutoSpeak => 'Auto-speak';

  @override
  String get translatorCopied => 'Copied';

  @override
  String get translatorLangRu => 'Russian';

  @override
  String get translatorLangEn => 'English';

  @override
  String get translatorLangDe => 'German';

  @override
  String get translatorLangFr => 'French';

  @override
  String get translatorLangEs => 'Spanish';

  @override
  String get translatorLangIt => 'Italian';

  @override
  String get translatorLangPt => 'Portuguese';

  @override
  String get translatorLangTr => 'Turkish';

  @override
  String get translatorLangZh => 'Chinese';

  @override
  String get translatorLangJa => 'Japanese';

  @override
  String get translatorLangKo => 'Korean';

  @override
  String get translatorLangAr => 'Arabic';

  @override
  String get translatorLangPl => 'Polish';

  @override
  String get translatorLangSk => 'Slovak';

  @override
  String get translatorLangCs => 'Czech';

  @override
  String get translatorLangNl => 'Dutch';

  @override
  String get translatorLangSv => 'Swedish';

  @override
  String get translatorLangDa => 'Danish';

  @override
  String get translatorLangNo => 'Norwegian';

  @override
  String get translatorLangFi => 'Finnish';

  @override
  String get translatorLangUk => 'Ukrainian';

  @override
  String get translatorLangEl => 'Greek';

  @override
  String get translatorLangRo => 'Romanian';

  @override
  String get translatorLangHu => 'Hungarian';

  @override
  String get translatorLangBg => 'Bulgarian';

  @override
  String get translatorLangHr => 'Croatian';

  @override
  String get translatorLangSr => 'Serbian';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Thai';

  @override
  String get translatorLangVi => 'Vietnamese';

  @override
  String get translatorLangId => 'Indonesian';

  @override
  String get translatorLangMs => 'Malay';

  @override
  String get translatorLangHe => 'Hebrew';

  @override
  String get translatorLangFa => 'Persian';

  @override
  String get callInProgress => 'Call in progress';

  @override
  String get joinCall => 'Join';

  @override
  String get createCallLink => 'Call link';

  @override
  String get callLinkCopied => 'Link copied';

  @override
  String get callLinkTitle => 'Room link';

  @override
  String get connectionUnstable => 'Connection unstable — check your internet';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';
}
