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
  String get passwordChanged => 'Password changed';

  @override
  String get wrongCurrentPassword => 'Wrong current password';

  @override
  String get passwordTooWeak =>
      'Password too weak: at least 8 chars, letter and digit required';

  @override
  String get passwordChangeFailed => 'Failed to change password';

  @override
  String get notifications => 'Notifications';

  @override
  String get permissions => 'Permissions';

  @override
  String get permissionNotifications => 'Push Notifications';

  @override
  String get permissionNotificationsDesc => 'Calls, messages, statuses';

  @override
  String get permissionMicrophone => 'Microphone';

  @override
  String get permissionMicrophoneDesc => 'Calls and voice assistant';

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionCameraDesc => 'Video calls and verification';

  @override
  String get permissionLocation => 'Location';

  @override
  String get permissionLocationDesc => 'Used for verification';

  @override
  String get permissionOpenSettings =>
      'To revoke a permission, open system settings';

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
  String get tabCalls => 'Calls';

  @override
  String get tabCalendar => 'Calendar';

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

  @override
  String get errorTimeout =>
      'Connection timed out. Check your internet connection.';

  @override
  String get errorNoConnection => 'No internet connection.';

  @override
  String get errorGeneral => 'An error occurred. Please try again.';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get notifChannelMessages => 'Messages';

  @override
  String get notifChannelMessagesDesc => 'New message notifications';

  @override
  String get notifChannelMissedCalls => 'Missed calls';

  @override
  String get notifChannelMissedCallsDesc => 'Missed call notifications';

  @override
  String get notifMissedCall => 'Missed call';

  @override
  String get notifAccept => 'Accept';

  @override
  String get notifDecline => 'Decline';

  @override
  String get notifIncomingCall => 'Incoming call';

  @override
  String get notifIncomingCallChannel => 'Incoming call';

  @override
  String get notifMissedCallChannel => 'Missed call';

  @override
  String get notifUnknown => 'Unknown';

  @override
  String get effectNone => 'No background';

  @override
  String get effectBlur => 'Blur';

  @override
  String get effectOffice => 'Office';

  @override
  String get effectNature => 'Nature';

  @override
  String get effectGradient => 'Gradient';

  @override
  String get effectLibrary => 'Library';

  @override
  String get effectCity => 'City';

  @override
  String get effectMinimalism => 'Minimalism';

  @override
  String get voiceParticipant => 'Participant';

  @override
  String get voiceInvitesToRoom => 'invites you to the room';

  @override
  String get voiceRoom => 'Room';

  @override
  String get voicePasswordProtected => 'Password protected';

  @override
  String get voicePasswordHint => 'Password';

  @override
  String get voiceEnter => 'Enter';

  @override
  String get voiceJoinRoom => 'Join the room';

  @override
  String get voiceYourName => 'Your name';

  @override
  String voiceInvitationSent(String name) {
    return 'Invitation sent to $name';
  }

  @override
  String get voiceNoActiveRoom => 'No active room';

  @override
  String get voiceCameraPermission =>
      'Allow camera access in Settings → Privacy → Camera → TalerID';

  @override
  String get voiceOpenSettings => 'Open';

  @override
  String voiceCameraError(String error) {
    return 'Failed to enable camera: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'All agreed. Recording started.';

  @override
  String get voiceNewParticipantAgreed =>
      'New participant agreed to recording.';

  @override
  String get voiceDeclinedRecording =>
      'You declined recording. Leaving the call.';

  @override
  String get voiceRecordingEnded => 'Recording ended';

  @override
  String get voiceRecordingInProgress => 'Recording in progress';

  @override
  String get voiceTranscriptionRequest => 'Transcription request';

  @override
  String get voiceRecordingRequest => 'Recording request';

  @override
  String get voiceAgree => 'Agree';

  @override
  String get voiceDeclineAndLeave => 'Decline and leave';

  @override
  String get voiceAudioOutput => 'Audio output';

  @override
  String get voiceAudioPhone => 'Phone';

  @override
  String get voiceAudioSpeaker => 'Speaker';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Headphones';

  @override
  String get voiceLinkCopied => 'Link copied';

  @override
  String get voiceTranslateTo => 'Translate to';

  @override
  String get voiceSearchLanguage => 'Search language...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Room $name';
  }

  @override
  String get voiceVoiceCall => 'Voice call';

  @override
  String get voiceOnHold => 'On hold';

  @override
  String get voiceActiveCall => 'Active';

  @override
  String get voiceEndAllCalls => 'End all calls';

  @override
  String get voiceEndThisCall => 'End this call';

  @override
  String get voiceCopyLink => 'Copy link';

  @override
  String get voiceAddParticipant => 'Add participant';

  @override
  String get voiceReconnecting => 'Reconnecting...';

  @override
  String get voiceConnectionError => 'Connection error';

  @override
  String get voiceClose => 'Close';

  @override
  String get voiceCalling => 'Calling...';

  @override
  String get voiceCallActive => 'Call active';

  @override
  String get voiceWaiting => 'Waiting';

  @override
  String get voiceWaitingUpper => 'WAITING';

  @override
  String get voiceRec => 'REC';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceRecord => 'Recording';

  @override
  String get voiceTranslation => 'Translation';

  @override
  String get voiceAudio => 'Audio';

  @override
  String get voiceFlipCamera => 'Flip';

  @override
  String get voiceBackground => 'Background';

  @override
  String get voiceAssistantSpeakingStatus => 'Assistant speaking...';

  @override
  String get voiceAssistantListeningStatus => 'Assistant listening...';

  @override
  String get voiceUnmute => 'Unmute';

  @override
  String get voiceMic => 'Microphone';

  @override
  String get voiceAssistantLabel => 'Assistant';

  @override
  String get voiceCameraOn => 'Camera on';

  @override
  String get voiceCameraLabel => 'Camera';

  @override
  String get voiceEndCall => 'End call';

  @override
  String get voiceWaitingParticipants => 'Waiting for participants...';

  @override
  String get voiceYou => 'You';

  @override
  String get voiceAiAssistant => 'AI Assistant';

  @override
  String get voiceVideoUnavailable => 'Video unavailable';

  @override
  String get voiceSearchNickname => 'Search by nickname...';

  @override
  String get voiceTranscriptionWord => 'transcription';

  @override
  String get voiceRecordingWord => 'recording';

  @override
  String get voiceConnecting => 'Connecting...';

  @override
  String get voiceVideoBackground => 'Video background';

  @override
  String get voiceCallSettings => 'Call settings';

  @override
  String get voiceEnableAI => 'Enable AI assistant';

  @override
  String get voiceAIParticipating => 'AI will participate in the conversation';

  @override
  String get voiceNormalCall => 'Normal call without AI';

  @override
  String get voiceCallConfirm => 'Make a call?';

  @override
  String get chatAlreadyInCall => 'Already in a call';

  @override
  String chatCallError(String error) {
    return 'Call error: $error';
  }

  @override
  String get chatPhotoVideo => 'Photo / Video';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatFile => 'File';

  @override
  String get chatContact => 'Contact';

  @override
  String get chatSelectContact => 'Select a contact';

  @override
  String get chatNoContacts => 'No contacts';

  @override
  String get chatUser => 'User';

  @override
  String get chatFileAttachment => '📎 File';

  @override
  String chatFileUploadError(String error) {
    return 'File upload error: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Voice message';

  @override
  String get chatGroup => 'Group';

  @override
  String get chatDialog => 'Dialog';

  @override
  String get chatCall => 'Call';

  @override
  String get chatStartConversation => 'Start a conversation';

  @override
  String get chatYou => 'You';

  @override
  String get chatIsTyping => 'is typing...';

  @override
  String chatUserIsTyping(String name) {
    return '$name is typing...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names are typing...';
  }

  @override
  String get chatPreparingFile => 'Preparing file…';

  @override
  String chatUploading(int progress) {
    return 'Uploading… $progress%';
  }

  @override
  String get chatEdited => 'Edited';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatEdit => 'Edit';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatCopied => 'Copied';

  @override
  String get chatSaveMedia => 'Save';

  @override
  String get chatForward => 'Forward';

  @override
  String get chatSaving => 'Saving...';

  @override
  String get chatSavedToGallery => 'Saved to gallery';

  @override
  String get chatNoSavePermission => 'No permission to save. Check settings.';

  @override
  String get chatFileSaveError => 'File save error';

  @override
  String get chatDeleteMessage => 'Delete message';

  @override
  String get chatDeleteForMe => 'Delete for me';

  @override
  String get chatDeleteForEveryone => 'Delete for everyone';

  @override
  String get chatMessageForwarded => 'Message forwarded';

  @override
  String get chatContactTapToOpen => 'Contact · tap to open';

  @override
  String get chatForwardTo => 'Forward to...';

  @override
  String get chatSearchHint => 'Search...';

  @override
  String get chatRecording => 'Recording...';

  @override
  String get chatMessageHint => 'Message...';

  @override
  String get chatHideKeyboard => 'Hide keyboard';

  @override
  String get chatEditing => 'Editing';

  @override
  String get chatFileDownloadError => 'File download error';

  @override
  String get chatVoiceMessageShort => 'Voice message';

  @override
  String get chatVideoSavedToGallery => 'Video saved to gallery';

  @override
  String get chatSavingError => 'Saving error';

  @override
  String get convSetNickname => 'Set a nickname';

  @override
  String get convNicknameRequired =>
      'A nickname is required to use the messenger. Other users can find you by it.';

  @override
  String get convNicknameRules => '3–30 characters: letters, digits, _';

  @override
  String get convNicknameTaken => 'Nickname already taken';

  @override
  String get convSaveError => 'Save error';

  @override
  String get convContactsLabel => 'Contacts';

  @override
  String get convDefaultUser => 'User';

  @override
  String get convNoDialogs => 'No conversations';

  @override
  String get convFindUserToChat => 'Find a user to start chatting';

  @override
  String get convDefaultContact => 'Contact';

  @override
  String get dashboardUser => 'User';

  @override
  String get dashboardIncomingCall => 'Incoming call';

  @override
  String get dashboardDecline => 'Decline';

  @override
  String get dashboardAccept => 'Accept';

  @override
  String get dashboardActiveCall => 'Active call — tap to return';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Update available $version';
  }

  @override
  String get dashboardUpdate => 'Update';

  @override
  String get contactRequestsTitle => 'Contacts';

  @override
  String get messengerContactRequestsSection => 'Contact requests';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new requests',
      one: '1 new request',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Search';

  @override
  String get contactRequestsIncoming => 'Incoming';

  @override
  String get contactRequestsSent => 'Sent';

  @override
  String get contactRequestsSearchHint => 'Nickname or email';

  @override
  String get contactRequestSent => 'Request sent';

  @override
  String get contactRequestsNoUsers => 'No users found';

  @override
  String get contactRequestsSearchHelp =>
      'Enter exact nickname or email\nand press search';

  @override
  String get contactRequestsSendTooltip => 'Send request';

  @override
  String get contactRequestTitle => 'Contact request';

  @override
  String contactRequestConfirm(String name) {
    return 'Send contact request to $name?';
  }

  @override
  String get contactRequestSend => 'Send';

  @override
  String get contactRequestsNoIncoming => 'No incoming requests';

  @override
  String get contactRequestsNoSent => 'No sent requests';

  @override
  String get contactRequestStatusPending => 'Awaiting response';

  @override
  String get contactRequestStatusAccepted => 'Accepted';

  @override
  String get contactRequestStatusRejected => 'Rejected';

  @override
  String get userSearchTitle => 'Find user';

  @override
  String get userSearchHint => 'Nickname, phone or email';

  @override
  String get userSearchHelper => 'Enter @nickname, email or name to search';

  @override
  String get userSearchNoUsers => 'No users found';

  @override
  String get userProfileShareContact => 'Share contact';

  @override
  String get userProfileShareContactDesc => 'Send contact link';

  @override
  String get userProfileCopyLink => 'Copy link';

  @override
  String get userProfileCopied => 'Copied';

  @override
  String get userProfileTitle => 'Profile';

  @override
  String get userProfileLoadError => 'Profile load error';

  @override
  String get userProfileMessage => 'Message';

  @override
  String get userProfileCall => 'Call';

  @override
  String get userProfileRequestSent => 'Request sent';

  @override
  String get userProfileAccept => 'Accept';

  @override
  String get userProfileDecline => 'Decline';

  @override
  String get userProfileAddToContacts => 'Add to contacts';

  @override
  String get userProfileMediaTab => 'Media';

  @override
  String get userProfileFilesTab => 'Files';

  @override
  String get userProfileLinksTab => 'Links';

  @override
  String get userProfileRecordingsTab => 'Recordings';

  @override
  String get userProfileSummariesTab => 'Summaries';

  @override
  String get userProfileNoMedia => 'No media files';

  @override
  String get userProfileNoFiles => 'No files';

  @override
  String get userProfileNoLinks => 'No links';

  @override
  String get userProfileNoRecordings => 'No recordings';

  @override
  String get userProfileNoSummaries => 'No summaries';

  @override
  String get userProfileMeetingSummary => 'Meeting summary';

  @override
  String get userProfileFailedOpenChat => 'Failed to open chat';

  @override
  String get sharedMediaTitle => 'Media and files';

  @override
  String get sharedMediaTab => 'Media';

  @override
  String get sharedFilesTab => 'Files';

  @override
  String get sharedLinksTab => 'Links';

  @override
  String get sharedNoMedia => 'No media files';

  @override
  String get sharedNoFiles => 'No files';

  @override
  String get sharedNoLinks => 'No links';

  @override
  String get shareToChat => 'Forward to chat';

  @override
  String get shareSelectChat => 'Select chat';

  @override
  String get shareNoChats => 'No chats';

  @override
  String shareFilesCount(int count) {
    return '$count files';
  }

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsAddTooltip => 'Add contact';

  @override
  String get contactsSearchHint => 'Search contacts...';

  @override
  String get contactsNotFound => 'Nothing found';

  @override
  String get contactsEmpty => 'No contacts';

  @override
  String get contactsAdd => 'Add contact';

  @override
  String get contactsPendingConfirmation => 'Awaiting confirmation';

  @override
  String get contactsMessage => 'Message';

  @override
  String get contactsCall => 'Call';

  @override
  String get contactsResend => 'Resend request';

  @override
  String get contactsResendTimeout => 'Retry in 24h';

  @override
  String get contactsResent => 'Request resent';

  @override
  String get contactsWantsToConnect => 'Wants to connect with you';

  @override
  String get contactsSearchPeople => 'Find people';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesAssistantSpeaking => 'Assistant speaking...';

  @override
  String get notesListening => 'Listening...';

  @override
  String get notesEmpty => 'No notes';

  @override
  String get notesEmptyHint => 'Press mic for dictation\nor + for manual entry';

  @override
  String get notesDeleteConfirm => 'Delete note?';

  @override
  String get notesNew => 'New note';

  @override
  String get notesEdit => 'Edit';

  @override
  String get notesTitleHint => 'Title';

  @override
  String get notesContentHint => 'Write your thoughts...';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarStop => 'Stop';

  @override
  String get calendarVoiceInput => 'Voice input';

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarAssistantSpeaking => 'Assistant speaking...';

  @override
  String get calendarListening => 'Listening...';

  @override
  String calendarInvitations(int count) {
    return 'Invitations ($count)';
  }

  @override
  String get calendarNoEvents => 'No events';

  @override
  String get calendarDayMon => 'Mon';

  @override
  String get calendarDayTue => 'Tue';

  @override
  String get calendarDayWed => 'Wed';

  @override
  String get calendarDayThu => 'Thu';

  @override
  String get calendarDayFri => 'Fri';

  @override
  String get calendarDaySat => 'Sat';

  @override
  String get calendarDaySun => 'Sun';

  @override
  String get calendarEnterRoom => 'Enter room';

  @override
  String get calendarMeeting => 'Meeting';

  @override
  String calendarLocationPrefix(String location) {
    return 'Location: $location';
  }

  @override
  String get calendarEditEvent => 'Edit';

  @override
  String get calendarTitleHint => 'Title';

  @override
  String get calendarDescriptionHint => 'Description';

  @override
  String get calendarTypeEvent => 'Event';

  @override
  String get calendarTypeMeeting => 'Meeting';

  @override
  String get calendarTypeReminder => 'Reminder';

  @override
  String get calendarTypeLabel => 'Type';

  @override
  String get calendarMeetingLink => 'Meeting link';

  @override
  String get calendarLocationHint => 'Location';

  @override
  String get calendarDateLabel => 'Date';

  @override
  String get calendarTimeLabel => 'Time';

  @override
  String get calendarReminderLabel => 'Reminder';

  @override
  String get calendarReminderNone => 'None';

  @override
  String get calendarReminder15min => '15 min before';

  @override
  String get calendarReminder30min => '30 min before';

  @override
  String get calendarReminder1hour => '1 hour before';

  @override
  String get calendarRepeatLabel => 'Repeat';

  @override
  String get calendarRepeatNone => 'No repeat';

  @override
  String get calendarRepeatDaily => 'Every day';

  @override
  String get calendarRepeatWeekly => 'Every week';

  @override
  String get calendarRepeatMonthly => 'Every month';

  @override
  String get calendarRepeatYearly => 'Every year';

  @override
  String get calendarParticipants => 'Participants';

  @override
  String get calendarAddParticipant => 'Add';

  @override
  String get calendarSearchContacts => 'Search contacts...';

  @override
  String get calendarNoContacts => 'No contacts';

  @override
  String get calendarStatusAccepted => 'Accepted';

  @override
  String get calendarStatusDeclined => 'Declined';

  @override
  String get calendarStatusMaybe => 'Maybe';

  @override
  String get calendarStatusPending => 'Pending';

  @override
  String get calendarEndTime => 'End time';

  @override
  String get calendarYourAnswer => 'Your answer:';

  @override
  String get calendarOrganizer => 'Organizer';

  @override
  String calendarDeleteError(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get calendarRsvpAccept => 'Accept';

  @override
  String get calendarRsvpMaybe => 'Maybe';

  @override
  String get calendarRsvpDecline => 'Decline';

  @override
  String get callHistoryTitle => 'Calls';

  @override
  String get callHistoryTab => 'Call history';

  @override
  String get callHistoryTempMeeting => 'Temporary meeting';

  @override
  String get callHistoryCopy => 'Copy';

  @override
  String get callHistoryLinkCopied => 'Link copied';

  @override
  String get callHistoryShare => 'Share';

  @override
  String get callHistoryEnter => 'Enter';

  @override
  String get callHistoryAlreadyInCall => 'Already in a call';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Could not determine the other party';

  @override
  String get callHistoryContacts => 'Contacts';

  @override
  String get callHistoryFailedLoadRoom => 'Failed to load your room';

  @override
  String get callHistoryYourRoom => 'Your room';

  @override
  String get callHistoryCreateMeeting => 'Create meeting';

  @override
  String get callHistoryMeetingSummaries => 'Meeting summaries';

  @override
  String get callHistoryMeetingRecordings => 'Meeting recordings';

  @override
  String get callHistoryNoCalls => 'No calls';

  @override
  String get callHistoryMissed => 'Missed';

  @override
  String get callHistoryRecording => 'Recording';

  @override
  String get callHistorySummary => 'Summary';

  @override
  String get callHistoryCallAgain => 'Call again';

  @override
  String callHistoryTodayTime(String time) {
    return 'Today, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Yesterday, $time';
  }

  @override
  String get callHistoryUnknown => 'Unknown';

  @override
  String get callHistoryDetails => 'Call details';

  @override
  String get callHistoryOutgoing => 'Outgoing call';

  @override
  String get callHistoryIncoming => 'Incoming call';

  @override
  String callHistoryDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get callHistoryWithAI => 'With AI assistant';

  @override
  String get callHistoryParticipants => 'Participants';

  @override
  String get callHistoryMeetingSummary => 'Meeting summary';

  @override
  String get callHistoryMoreDetails => 'More details';

  @override
  String get callHistorySummaryProcessing => 'Summary processing...';

  @override
  String get callHistoryMeetingRecording => 'Meeting recording';

  @override
  String get callHistoryProcessing => 'Processing...';

  @override
  String get callHistoryCreateTranscript => 'Create transcript';

  @override
  String get callHistoryNoSummaries => 'No summaries';

  @override
  String get callHistoryRecordDuringCall => 'Press \"Record\" during a call';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Meeting $time';
  }

  @override
  String get callHistoryTranscribing => 'Transcribing and summarizing...';

  @override
  String get callHistoryTranscriptCreated => 'Transcript created';

  @override
  String get callHistoryNoRecordings => 'No recordings';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Recording $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Recording unavailable';

  @override
  String get callHistoryTranscriptReady => 'Transcript ready';

  @override
  String get callHistoryTranscript => 'Transcript';

  @override
  String get callHistoryKeyPoints => 'Key points';

  @override
  String get callHistoryTasks => 'Tasks';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Assigned to: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Decisions';

  @override
  String get callHistoryShowTranscript => 'Show full transcript';

  @override
  String get profileScanQr => 'Scan QR';

  @override
  String get profileMyQrCode => 'My QR code';

  @override
  String profileAddMeShare(String userId) {
    return 'Add me in Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Show this code to add you';

  @override
  String get profileEditDesc => 'Name, surname, patronymic, date of birth';

  @override
  String get profileAboutMe => 'About me';

  @override
  String get profileAboutMeDesc => 'Values, skills, interests and more';

  @override
  String get profileNotes => 'Notes';

  @override
  String get profileNotesDesc => 'Thoughts, ideas and notes';

  @override
  String get profileAvatarUpdated => 'Avatar updated';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileChangeNickname => 'Change nickname';

  @override
  String get profileNicknameUpdated => 'Nickname updated';

  @override
  String get profileShareLabel => 'Share';

  @override
  String get profileScanQrCode => 'Scan QR code';

  @override
  String get profilePointCamera => 'Point camera at QR code';

  @override
  String get profilePhotoCamera => 'Take photo';

  @override
  String get profilePhotoGallery => 'Choose from gallery';

  @override
  String get editProfilePatronymic => 'Patronymic (optional)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'About me';

  @override
  String get aboutMeClickToFill => 'Click to fill';

  @override
  String get aboutMeCoreValues => 'Values';

  @override
  String get aboutMeWorldview => 'Worldview';

  @override
  String get aboutMeSkills => 'Skills';

  @override
  String get aboutMeInterests => 'Interests';

  @override
  String get aboutMeDesires => 'Desires';

  @override
  String get aboutMeBackground => 'Profile';

  @override
  String get aboutMeLikes => 'Likes';

  @override
  String get aboutMeDislikes => 'Dislikes';

  @override
  String get aboutMeDeleteSection => 'Delete section?';

  @override
  String get aboutMeDeleteConfirm =>
      'All data in this section will be deleted.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Connection error: $error';
  }

  @override
  String get aboutMeVisibility => 'Visibility';

  @override
  String get aboutMeTags => 'Tags';

  @override
  String get aboutMeAddTag => 'Add tag...';

  @override
  String get aboutMeDescription => 'Description';

  @override
  String get aboutMeDescribeLong => 'Tell us more...';

  @override
  String get aboutMeVisibilityEveryone => 'Everyone';

  @override
  String get aboutMeVisibilityContacts => 'Contacts';

  @override
  String get aboutMeVisibilityOnlyMe => 'Only me';

  @override
  String get settingsProfileSubtitle => 'Profile';

  @override
  String get settingsWallpaper => 'Wallpaper';

  @override
  String get settingsWallpaperDesc => 'Background image for the whole app';

  @override
  String get settingsWallpaperNone => 'None';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsKycVerification => 'Identity Verification (KYC)';

  @override
  String get settingsOrganizations => 'Organizations';

  @override
  String get incomingCallLabel => 'Incoming call';

  @override
  String get incomingCallDecline => 'Decline';

  @override
  String get incomingCallAccept => 'Accept';

  @override
  String get groupCamera => 'Camera';

  @override
  String get groupGallery => 'Gallery';

  @override
  String get groupAvatarUpdated => 'Group avatar updated';

  @override
  String get groupNameTitle => 'Group name';

  @override
  String get groupEnterName => 'Enter name';

  @override
  String get groupDescriptionTitle => 'Group description';

  @override
  String get groupEnterDescription => 'Enter group description';

  @override
  String get groupChangeRoleTitle => 'Change role';

  @override
  String get groupRemoveMemberTitle => 'Remove member';

  @override
  String get groupDescription => 'Description';

  @override
  String get groupAddDescription => 'Add group description';

  @override
  String get groupNoDescription => 'No description';

  @override
  String get groupMediaAndFiles => 'Media and files';

  @override
  String get groupMuteNotifications => 'Mute notifications';

  @override
  String get groupMuted => 'Muted';

  @override
  String get groupNoResults => 'No results';

  @override
  String get authInvalidCode => 'Invalid code. Try again.';

  @override
  String get loginSubtitle => 'Use email and password';

  @override
  String get emailRequired => 'Enter email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordRequired => 'Enter password';

  @override
  String get registerSubtitle => 'One account for the entire Taler ecosystem';

  @override
  String get usernameOptional => 'Username (optional)';

  @override
  String get usernameMinLength => 'Minimum 3 characters';

  @override
  String get usernameMaxLength => 'Maximum 30 characters';

  @override
  String get usernameInvalid => 'Only letters, digits and _';

  @override
  String get biometricLoginReason => 'Sign in to Taler ID';

  @override
  String get docTypePassport => 'Passport';

  @override
  String get docTypeIdCard => 'ID Card';

  @override
  String get docTypeDriverLicense => 'Driver\'s License';

  @override
  String get docTypeResidencePermit => 'Residence Permit';

  @override
  String addressApartment(String number) {
    return 'apt. $number';
  }

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get failedToStartKyb => 'Failed to start KYB verification';

  @override
  String get orgUpdated => 'Organization updated';

  @override
  String get failedToUpdateOrg => 'Failed to update organization';

  @override
  String get failedToChangeRole => 'Failed to change role';

  @override
  String get failedToRemoveMember => 'Failed to remove member';

  @override
  String get capabilityMessagesTitle => 'Messages';

  @override
  String get capabilityMessagesDesc =>
      'Check messages or write to someone. For example: \"Write to Viktor: will be there in an hour\"';

  @override
  String get capabilityCallsTitle => 'Calls';

  @override
  String get capabilityCallsDesc =>
      'Call any contact by voice. For example: \"Call Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Chat History';

  @override
  String get capabilityChatDesc =>
      'I\'ll analyze the chat history. For example: \"What did we discuss with Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Profile';

  @override
  String get capabilityProfileDesc =>
      'I\'ll show or update your profile. For example: \"Show my profile\"';

  @override
  String get capabilityCoachingTitle => 'Coaching';

  @override
  String get capabilityCoachingDesc =>
      'Modes: ICF coaching, psychologist, HR consultation. Say: \"Let\'s do coaching\"';

  @override
  String get capabilityCalendarTitle => 'Calendar';

  @override
  String get capabilityCalendarDesc =>
      'Schedule a meeting or set a reminder. For example: \"Schedule a meeting with Viktor for tomorrow at 15:00\"';

  @override
  String get capabilityNotesTitle => 'Notes';

  @override
  String get capabilityNotesDesc =>
      'Save a thought or read recent notes. For example: \"Write down an idea...\" or \"Read recent notes\"';

  @override
  String get assistantCallConfirm => 'Make a call?';

  @override
  String get callNoAnswer => 'No answer';

  @override
  String get contactDelete => 'Remove contact';

  @override
  String get contactDeleteTitle => 'Remove contact';

  @override
  String get contactDeleteConfirm =>
      'Are you sure? This contact will be removed.';

  @override
  String get contactBlock => 'Block';

  @override
  String get contactBlockTitle => 'Block user';

  @override
  String get contactBlockConfirm =>
      'This user will not be able to message or call you.';

  @override
  String get contactUnblock => 'Unblock';

  @override
  String get contactBlocked => 'Blocked';

  @override
  String get contactYouAreBlocked => 'This user has blocked you';

  @override
  String get chatBlockedByYou => 'You have blocked this user';

  @override
  String get chatYouAreBlocked => 'You have been blocked by this user';

  @override
  String get chatNotContacts => 'Add this user to contacts to message them';

  @override
  String get contactRevokeRequest => 'Revoke request';

  @override
  String get messengerPoll => 'Poll';

  @override
  String get messengerCreatePoll => 'Create Poll';

  @override
  String get messengerPollQuestion => 'Question';

  @override
  String messengerPollOption(int number) {
    return 'Option $number';
  }

  @override
  String get messengerPollAddOption => 'Add option';

  @override
  String get messengerPollAnonymous => 'Anonymous voting';

  @override
  String get messengerPollMultiple => 'Multiple choice';

  @override
  String get messengerPollCreateError => 'Failed to create poll';

  @override
  String get messengerPollUnavailable => 'Poll unavailable';

  @override
  String get messengerPollMultipleNote => 'You can select multiple';

  @override
  String messengerPollVotes(int count) {
    return '$count votes';
  }

  @override
  String get messengerVideoMessage => 'Video message';

  @override
  String get messengerVideoRecordError => 'Video recording error';

  @override
  String get messengerVideoPlaybackError => 'Could not play video';

  @override
  String get messengerGalleryAccessError => 'No access to gallery';

  @override
  String get messengerSearchInChat => 'Search in chat...';

  @override
  String get messengerSaveToFavorites => 'Save to favorites';

  @override
  String get messengerSavedToFavorites => 'Saved to favorites';

  @override
  String get messengerSearchInMessages => 'Search in messages...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Found in messages ($count)';
  }

  @override
  String get messengerGroupDefault => 'Group';

  @override
  String get messengerUserDefault => 'User';

  @override
  String get messengerPin => 'Pin';

  @override
  String get messengerUnpin => 'Unpin';

  @override
  String get messengerArchive => 'Archive';

  @override
  String get messengerUnarchive => 'Unarchive';

  @override
  String get messengerDeleteChat => 'Delete chat';

  @override
  String get messengerDeleteChatTitle => 'Delete chat?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Delete chat with $name? This cannot be undone.';
  }

  @override
  String get messengerCreateChannel => 'Create Channel';

  @override
  String get messengerChannelName => 'Name';

  @override
  String get messengerChannelDescription => 'Description (optional)';

  @override
  String get messengerChannelCreateError => 'Failed to create channel';

  @override
  String get messengerFilterAll => 'All';

  @override
  String get messengerFilterUnread => 'Unread';

  @override
  String get messengerFilterPersonal => 'Personal';

  @override
  String get messengerFilterGroups => 'Groups';

  @override
  String get messengerFilterChannels => 'Channels';

  @override
  String get messengerArchivedSection => 'Archived';

  @override
  String get messengerSavedSection => 'Favorites';

  @override
  String get messengerSavedSubtitle => 'Save to memory';

  @override
  String messengerArchiveTitle(int count) {
    return 'Archive ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Archive is empty';

  @override
  String messengerYouPrefix(String message) {
    return 'You: $message';
  }

  @override
  String get messengerMissedCall => 'Missed call';

  @override
  String get messengerSavedTitle => 'Favorites';

  @override
  String get messengerNoSavedMessages => 'No saved messages';

  @override
  String get messengerSavedHint =>
      'Long press a message → \"Save to favorites\"';

  @override
  String get messengerDefaultFile => 'File';

  @override
  String get messengerTopicDefault => 'General';

  @override
  String get messengerTopicNew => 'New Topic';

  @override
  String get messengerTopicNameHint => 'Topic name';

  @override
  String get messengerTopicIcon => 'Icon';

  @override
  String messengerTopicCount(int count) {
    return '$count topics';
  }

  @override
  String get messengerNoTopics => 'No topics';

  @override
  String get messengerNoMessages => 'No messages';

  @override
  String get you => 'You';

  @override
  String get messengerThread => 'Thread';

  @override
  String get messengerThreadReply => 'reply';

  @override
  String get messengerThreadReplies => 'replies';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'No replies';

  @override
  String get messengerReplyHint => 'Reply to thread...';

  @override
  String get messengerContactName => 'Contact name';

  @override
  String messengerOriginalName(String name) {
    return 'Original name: $name';
  }

  @override
  String get messengerDisplayName => 'Display name';

  @override
  String messengerShareContact(String name) {
    return 'Contact in Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Auto-delete messages';

  @override
  String get messengerAutoDeleteOff => 'Off';

  @override
  String get messengerAutoDelete7d => '7 days';

  @override
  String get messengerAutoDelete30d => '30 days';

  @override
  String get messengerAutoDelete90d => '90 days';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count days';
  }

  @override
  String get messengerSettingsHeader => 'Settings';

  @override
  String get messengerAdminOnly => 'Admin-only posting';

  @override
  String get messengerAdminOnlyDesc => 'Members can only read';

  @override
  String get messengerTopics => 'Topics';

  @override
  String get messengerTopicsDesc => 'Split chat into topics';

  @override
  String get aiTwinSection => 'AI Voice Twin';

  @override
  String get aiTwinEnabled => 'Enable AI Twin';

  @override
  String get aiTwinEnabledDesc =>
      'If you don\'t answer, your AI twin takes the call in your voice';

  @override
  String get aiTwinTimeout => 'Response timeout';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds sec';
  }

  @override
  String get aiTwinPrompt => 'AI instructions';

  @override
  String get aiTwinPromptSubtitle =>
      'How the AI twin should introduce itself and what to talk about';

  @override
  String aiTwinPromptHint(String name) {
    return 'Hi, this is $name\'s AI voice twin. $name couldn\'t pick up right now. Tell me who\'s calling and what it\'s about — I\'ll pass it on.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Custom voice cloning coming soon. For now the AI speaks with $name\'s voice.';
  }

  @override
  String get aiTwinDefaultName => 'the owner';

  @override
  String get aiTwinPromptReset => 'Reset';

  @override
  String get callHistoryAiTwinAnswered => 'AI TWIN ANSWERED';

  @override
  String get callHistoryAiTwinSummary => 'CALL SUMMARY';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSCRIPT';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'From $name';
  }

  @override
  String get aiTwinOfferTitle => 'Not answering';

  @override
  String aiTwinOfferBody(String name) {
    return '$name isn\'t picking up. Leave a message with their AI voice twin?';
  }

  @override
  String get aiTwinOfferBodyUser => 'User';

  @override
  String get aiTwinOfferAccept => 'Yes, leave message';

  @override
  String get aiTwinOfferKeepWaiting => 'Keep waiting';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Your AI stand-in';

  @override
  String get aiTwinHeroSubtitle =>
      'Answers calls in your voice when you can\'t.';

  @override
  String get aiTwinProfileTitle => 'AI Stand-in';

  @override
  String get aiTwinProfileDesc => 'Answers calls in your voice';

  @override
  String get aiTwinBadgeOn => 'ON';

  @override
  String get aiAnalystTitle => 'AI Analyst';

  @override
  String get aiAnalystSubtitle => 'Files, tasks, analysis — Claude';

  @override
  String get channelsDiscover => 'Find channel';

  @override
  String get channelsSearchHint => 'Search channels';

  @override
  String get channelsSubscribers => 'subscribers';

  @override
  String get channelsSubscribe => 'Subscribe';

  @override
  String get channelsUnsubscribe => 'Unsubscribe';

  @override
  String get channelsSubscribedLabel => 'You are subscribed';

  @override
  String get channelsSettings => 'Channel settings';

  @override
  String get channelsDelete => 'Delete channel';

  @override
  String get channelsDeleteConfirm => 'Delete channel permanently?';

  @override
  String get channelsEmpty => 'No channels yet';

  @override
  String get channelsOpen => 'Open';

  @override
  String get channelsNameLabel => 'Name';

  @override
  String get channelsDescriptionLabel => 'Description';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Owner cannot unsubscribe. Delete the channel instead.';

  @override
  String get channelsNotFoundRedirect => 'Channel no longer exists';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count searches',
      one: '$count search',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '$count file',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commands',
      one: '$count command',
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
      other: '$count steps',
      one: '$count step',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Saved Messages';

  @override
  String get savedSubtitle => 'Your private cloud';

  @override
  String get savedOpenError => 'Couldn\'t open Saved Messages';
}
