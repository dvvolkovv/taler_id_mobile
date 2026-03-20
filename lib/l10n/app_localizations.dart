import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Taler ID'**
  String get appTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unified ecosystem identity'**
  String get appSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passwordMinLength;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get fieldRequired;

  /// No description provided for @twoFATitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFATitle;

  /// No description provided for @twoFASubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app'**
  String get twoFASubtitle;

  /// No description provided for @twoFACode.
  ///
  /// In en, this message translates to:
  /// **'2FA Code'**
  String get twoFACode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC'**
  String get tabKyc;

  /// No description provided for @tabOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get tabOrganization;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded'**
  String get noDocuments;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get drivingLicense;

  /// No description provided for @diploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma'**
  String get diploma;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @notSpecifiedFemale.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecifiedFemale;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @passportId.
  ///
  /// In en, this message translates to:
  /// **'Passport / ID'**
  String get passportId;

  /// No description provided for @diplomaCertificate.
  ///
  /// In en, this message translates to:
  /// **'Diploma / Certificate'**
  String get diplomaCertificate;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadError;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @countryAustria.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get countryAustria;

  /// No description provided for @countryGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get countryGermany;

  /// No description provided for @countryRussia.
  ///
  /// In en, this message translates to:
  /// **'Russia'**
  String get countryRussia;

  /// No description provided for @countryUkraine.
  ///
  /// In en, this message translates to:
  /// **'Ukraine'**
  String get countryUkraine;

  /// No description provided for @countryKazakhstan.
  ///
  /// In en, this message translates to:
  /// **'Kazakhstan'**
  String get countryKazakhstan;

  /// No description provided for @countryBelarus.
  ///
  /// In en, this message translates to:
  /// **'Belarus'**
  String get countryBelarus;

  /// No description provided for @countryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get countryOther;

  /// No description provided for @kycTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycTitle;

  /// No description provided for @kycVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycVerified;

  /// No description provided for @kycPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get kycPending;

  /// No description provided for @kycRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycRejected;

  /// No description provided for @kycUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get kycUnverified;

  /// No description provided for @kycVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been verified. You have full access to all Taler ecosystem features.'**
  String get kycVerifiedDesc;

  /// No description provided for @kycPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Your documents are being reviewed. This usually takes 1-2 business days.'**
  String get kycPendingDesc;

  /// No description provided for @kycRejectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please review the reason and resubmit your documents.'**
  String get kycRejectedDesc;

  /// No description provided for @kycUnverifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to unlock full access to Taler ecosystem financial features.'**
  String get kycUnverifiedDesc;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get startVerification;

  /// No description provided for @retryVerification.
  ///
  /// In en, this message translates to:
  /// **'Retry Verification'**
  String get retryVerification;

  /// No description provided for @verifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Verified: {date}'**
  String verifiedAt(String date);

  /// No description provided for @documentsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted for review'**
  String get documentsSubmitted;

  /// No description provided for @documentsSubmittedDesc.
  ///
  /// In en, this message translates to:
  /// **'Review usually takes 1-2 business days. You will receive a push notification with the result.'**
  String get documentsSubmittedDesc;

  /// No description provided for @securityAes.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected with AES-256 encryption'**
  String get securityAes;

  /// No description provided for @verificationTime.
  ///
  /// In en, this message translates to:
  /// **'Verification takes 1-2 business days'**
  String get verificationTime;

  /// No description provided for @pushNotification.
  ///
  /// In en, this message translates to:
  /// **'You will receive a push notification with the result'**
  String get pushNotification;

  /// No description provided for @kycWebOnly.
  ///
  /// In en, this message translates to:
  /// **'KYC verification is only available in the mobile app.'**
  String get kycWebOnly;

  /// No description provided for @verificationError.
  ///
  /// In en, this message translates to:
  /// **'Verification error: {code}'**
  String verificationError(String code);

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizations;

  /// No description provided for @noOrganizations.
  ///
  /// In en, this message translates to:
  /// **'No organizations'**
  String get noOrganizations;

  /// No description provided for @noOrganizationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create an organization or accept an invitation'**
  String get noOrganizationsDesc;

  /// No description provided for @createOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get createOrganization;

  /// No description provided for @newOrganization.
  ///
  /// In en, this message translates to:
  /// **'New Organization'**
  String get newOrganization;

  /// No description provided for @orgName.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get orgName;

  /// No description provided for @orgDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get orgDescription;

  /// No description provided for @orgEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get orgEmail;

  /// No description provided for @orgWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get orgWebsite;

  /// No description provided for @orgLegalAddress.
  ///
  /// In en, this message translates to:
  /// **'Legal Address'**
  String get orgLegalAddress;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String members(int count);

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMember;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvite;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}'**
  String inviteSent(String email);

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get roleOperator;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @editOrganization.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editOrganization;

  /// No description provided for @editOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Organization'**
  String get editOrganizationTitle;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from organization?'**
  String removeMemberConfirm(String name);

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// No description provided for @roleChanged.
  ///
  /// In en, this message translates to:
  /// **'Role changed'**
  String get roleChanged;

  /// No description provided for @kybVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kybVerified;

  /// No description provided for @kybPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get kybPending;

  /// No description provided for @kybRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kybRejected;

  /// No description provided for @kybNone.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get kybNone;

  /// No description provided for @kybVerification.
  ///
  /// In en, this message translates to:
  /// **'Start KYB Verification'**
  String get kybVerification;

  /// No description provided for @kybStartBusiness.
  ///
  /// In en, this message translates to:
  /// **'Start Business Verification'**
  String get kybStartBusiness;

  /// No description provided for @kybStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'KYB Status'**
  String get kybStatusLabel;

  /// No description provided for @noKyb.
  ///
  /// In en, this message translates to:
  /// **'No KYB'**
  String get noKyb;

  /// No description provided for @kybBusinessVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Verification (KYB)'**
  String get kybBusinessVerificationTitle;

  /// No description provided for @kybVerifiedOrgDesc.
  ///
  /// In en, this message translates to:
  /// **'Organization successfully verified.'**
  String get kybVerifiedOrgDesc;

  /// No description provided for @kybPendingOrgDesc.
  ///
  /// In en, this message translates to:
  /// **'Documents are being reviewed. This usually takes 1-3 business days.'**
  String get kybPendingOrgDesc;

  /// No description provided for @kybRejectedOrgDesc.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get kybRejectedOrgDesc;

  /// No description provided for @kybNoneOrgDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify your organization to access business features.'**
  String get kybNoneOrgDesc;

  /// No description provided for @invitePlus.
  ///
  /// In en, this message translates to:
  /// **'+ Invite'**
  String get invitePlus;

  /// No description provided for @kybVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'KYB Verification'**
  String get kybVerificationTitle;

  /// No description provided for @kybWebOnlyBusiness.
  ///
  /// In en, this message translates to:
  /// **'KYB verification is only available in the mobile app.'**
  String get kybWebOnlyBusiness;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDevice;

  /// No description provided for @ipUnknown.
  ///
  /// In en, this message translates to:
  /// **'IP unknown'**
  String get ipUnknown;

  /// No description provided for @currentSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentSessionLabel;

  /// No description provided for @endSessionAction.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endSessionAction;

  /// No description provided for @deviceLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Device will be signed out.'**
  String get deviceLoggedOut;

  /// No description provided for @acceptInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization Invitation'**
  String get acceptInvitationTitle;

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get acceptInvitation;

  /// No description provided for @acceptInvitationDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to join an organization in the Taler ecosystem.'**
  String get acceptInvitationDesc;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get sessions;

  /// No description provided for @currentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get currentSession;

  /// No description provided for @deleteSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get deleteSession;

  /// No description provided for @deleteSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get deleteSessionConfirm;

  /// No description provided for @sessionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get sessionDeleted;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No active sessions'**
  String get noSessions;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @biometricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick login with Face ID or fingerprint'**
  String get biometricsDesc;

  /// No description provided for @biometricsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm biometrics to enable quick login'**
  String get biometricsConfirm;

  /// No description provided for @biometricsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable biometrics. Check device settings.'**
  String get biometricsError;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushKycStatus.
  ///
  /// In en, this message translates to:
  /// **'KYC Status Push'**
  String get pushKycStatus;

  /// No description provided for @pushKycStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Verification result'**
  String get pushKycStatusDesc;

  /// No description provided for @pushLogins.
  ///
  /// In en, this message translates to:
  /// **'Login Push'**
  String get pushLogins;

  /// No description provided for @pushLoginsDesc.
  ///
  /// In en, this message translates to:
  /// **'When signing in from a new device'**
  String get pushLoginsDesc;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSelect.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get languageSelect;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data (GDPR)'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'All your data will be deleted (GDPR). This action is irreversible.'**
  String get deleteAccountDesc;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get logoutConfirm;

  /// No description provided for @logoutDesc.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of Taler ID on this device.'**
  String get logoutDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Taler ID v{version}'**
  String version(String version);

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pinCode;

  /// No description provided for @pinCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick login with 4-digit code'**
  String get pinCodeDesc;

  /// No description provided for @setupPin.
  ///
  /// In en, this message translates to:
  /// **'Set Up PIN'**
  String get setupPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match'**
  String get pinMismatch;

  /// No description provided for @pinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully'**
  String get pinSet;

  /// No description provided for @enterPinToLogin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to sign in'**
  String get enterPinToLogin;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get pinIncorrect;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @pinRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get pinRemoved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoad;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes'**
  String get failedToSave;

  /// No description provided for @failedToLoadOrgs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load organizations'**
  String get failedToLoadOrgs;

  /// No description provided for @failedToLoadOrg.
  ///
  /// In en, this message translates to:
  /// **'Failed to load organization data'**
  String get failedToLoadOrg;

  /// No description provided for @failedToCreateOrg.
  ///
  /// In en, this message translates to:
  /// **'Failed to create organization'**
  String get failedToCreateOrg;

  /// No description provided for @failedToInvite.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation'**
  String get failedToInvite;

  /// No description provided for @failedToAcceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invitation'**
  String get failedToAcceptInvite;

  /// No description provided for @failedToLoadSessions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sessions'**
  String get failedToLoadSessions;

  /// No description provided for @failedToDeleteSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to end session'**
  String get failedToDeleteSession;

  /// No description provided for @failedToLoadKyc.
  ///
  /// In en, this message translates to:
  /// **'Failed to load verification status'**
  String get failedToLoadKyc;

  /// No description provided for @failedToStartKyc.
  ///
  /// In en, this message translates to:
  /// **'Failed to start verification'**
  String get failedToStartKyc;

  /// No description provided for @verifiedPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Verified Data'**
  String get verifiedPersonalInfo;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// No description provided for @placeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Place of Birth'**
  String get placeOfBirth;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @docNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get docNumber;

  /// No description provided for @docIssuedDate.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get docIssuedDate;

  /// No description provided for @docValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get docValidUntil;

  /// No description provided for @docIssuedBy.
  ///
  /// In en, this message translates to:
  /// **'Issued By'**
  String get docIssuedBy;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @failedToLoadSumsubData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load verification data'**
  String get failedToLoadSumsubData;

  /// No description provided for @sumsubDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading verification data...'**
  String get sumsubDataLoading;

  /// No description provided for @reviewResultGreen.
  ///
  /// In en, this message translates to:
  /// **'Verification passed'**
  String get reviewResultGreen;

  /// No description provided for @reviewResultRed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get reviewResultRed;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get chatTitle;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatHint;

  /// No description provided for @chatListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get chatListening;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get chatError;

  /// No description provided for @chatClear.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get chatClear;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant a question'**
  String get chatEmpty;

  /// No description provided for @tabAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get tabAssistant;

  /// No description provided for @assistantConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get assistantConnecting;

  /// No description provided for @assistantSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking…'**
  String get assistantSpeaking;

  /// No description provided for @assistantListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get assistantListening;

  /// No description provided for @assistantTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get assistantTapToStart;

  /// No description provided for @assistantTapToTalk.
  ///
  /// In en, this message translates to:
  /// **'Tap to talk to AI'**
  String get assistantTapToTalk;

  /// No description provided for @assistantRealtimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Assistant responds with voice in real time'**
  String get assistantRealtimeDesc;

  /// No description provided for @assistantConnectingToAssistant.
  ///
  /// In en, this message translates to:
  /// **'Connecting to assistant...'**
  String get assistantConnectingToAssistant;

  /// No description provided for @assistantAiSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AI speaking...'**
  String get assistantAiSpeaking;

  /// No description provided for @assistantAiListening.
  ///
  /// In en, this message translates to:
  /// **'AI listening'**
  String get assistantAiListening;

  /// No description provided for @assistantSpeakerOn.
  ///
  /// In en, this message translates to:
  /// **'Speaker on'**
  String get assistantSpeakerOn;

  /// No description provided for @assistantSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get assistantSpeaker;

  /// No description provided for @assistantEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get assistantEnd;

  /// No description provided for @assistantUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get assistantUnmute;

  /// No description provided for @assistantMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get assistantMicrophone;

  /// No description provided for @assistantConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get assistantConnectionError;

  /// No description provided for @tabMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessenger;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get appearanceSelect;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Unified Identity'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Taler ID is your digital passport in the Taler ecosystem. One account for all services.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Data Security'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'KYC verification, AES-256 encryption, and two-factor authentication protect your identity.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Stay Informed'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Get notified about verification status, logins from new devices, and incoming calls.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get onboardingEnableNotifications;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Voice Calls'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'Grant microphone access for voice calls and AI assistant. You can change this later in settings.'**
  String get onboardingDesc4;

  /// No description provided for @onboardingEnableMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Enable Microphone'**
  String get onboardingEnableMicrophone;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset code'**
  String get forgotPasswordSubtitle;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String resetCodeSent(String email);

  /// No description provided for @enterResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get enterResetCode;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get groupInfo;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String groupMembers(int count);

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave this group?'**
  String get leaveGroupConfirm;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this group? This cannot be undone.'**
  String get deleteGroupConfirm;

  /// No description provided for @groupRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupRoleOwner;

  /// No description provided for @groupRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupRoleAdmin;

  /// No description provided for @groupRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupRoleMember;

  /// No description provided for @selectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Select participants'**
  String get selectParticipants;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created'**
  String get groupCreated;

  /// No description provided for @memberJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String memberJoined(String name);

  /// No description provided for @memberLeftGroup.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String memberLeftGroup(String name);

  /// No description provided for @memberWasRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed'**
  String memberWasRemoved(String name);

  /// No description provided for @roleChangedTo.
  ///
  /// In en, this message translates to:
  /// **'{name} is now {role}'**
  String roleChangedTo(String name, String role);

  /// No description provided for @participantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String participantsCount(int count);

  /// No description provided for @enterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get enterGroupName;

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get muteNotifications;

  /// No description provided for @unmuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get unmuteNotifications;

  /// No description provided for @muteFor1Hour.
  ///
  /// In en, this message translates to:
  /// **'For 1 hour'**
  String get muteFor1Hour;

  /// No description provided for @muteFor8Hours.
  ///
  /// In en, this message translates to:
  /// **'For 8 hours'**
  String get muteFor8Hours;

  /// No description provided for @muteFor2Days.
  ///
  /// In en, this message translates to:
  /// **'For 2 days'**
  String get muteFor2Days;

  /// No description provided for @muteForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get muteForever;

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muted;

  /// No description provided for @tabTranslator.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get tabTranslator;

  /// No description provided for @translatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get translatorTitle;

  /// No description provided for @translatorSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get translatorSelectLanguage;

  /// No description provided for @translatorDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading language models...'**
  String get translatorDownloading;

  /// No description provided for @translatorDownloadingHint.
  ///
  /// In en, this message translates to:
  /// **'Internet is needed only for the first download'**
  String get translatorDownloadingHint;

  /// No description provided for @translatorTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Type text or tap the microphone'**
  String get translatorTypeHint;

  /// No description provided for @translatorListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get translatorListening;

  /// No description provided for @translatorTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get translatorTapToSpeak;

  /// No description provided for @translatorTapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get translatorTapToStop;

  /// No description provided for @translatorAutoSpeak.
  ///
  /// In en, this message translates to:
  /// **'Auto-speak'**
  String get translatorAutoSpeak;

  /// No description provided for @translatorCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get translatorCopied;

  /// No description provided for @translatorLangRu.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get translatorLangRu;

  /// No description provided for @translatorLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get translatorLangEn;

  /// No description provided for @translatorLangDe.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get translatorLangDe;

  /// No description provided for @translatorLangFr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get translatorLangFr;

  /// No description provided for @translatorLangEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get translatorLangEs;

  /// No description provided for @translatorLangIt.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get translatorLangIt;

  /// No description provided for @translatorLangPt.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get translatorLangPt;

  /// No description provided for @translatorLangTr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get translatorLangTr;

  /// No description provided for @translatorLangZh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get translatorLangZh;

  /// No description provided for @translatorLangJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get translatorLangJa;

  /// No description provided for @translatorLangKo.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get translatorLangKo;

  /// No description provided for @translatorLangAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get translatorLangAr;

  /// No description provided for @translatorLangPl.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get translatorLangPl;

  /// No description provided for @translatorLangSk.
  ///
  /// In en, this message translates to:
  /// **'Slovak'**
  String get translatorLangSk;

  /// No description provided for @translatorLangCs.
  ///
  /// In en, this message translates to:
  /// **'Czech'**
  String get translatorLangCs;

  /// No description provided for @translatorLangNl.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get translatorLangNl;

  /// No description provided for @translatorLangSv.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get translatorLangSv;

  /// No description provided for @translatorLangDa.
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get translatorLangDa;

  /// No description provided for @translatorLangNo.
  ///
  /// In en, this message translates to:
  /// **'Norwegian'**
  String get translatorLangNo;

  /// No description provided for @translatorLangFi.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get translatorLangFi;

  /// No description provided for @translatorLangUk.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get translatorLangUk;

  /// No description provided for @translatorLangEl.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get translatorLangEl;

  /// No description provided for @translatorLangRo.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get translatorLangRo;

  /// No description provided for @translatorLangHu.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get translatorLangHu;

  /// No description provided for @translatorLangBg.
  ///
  /// In en, this message translates to:
  /// **'Bulgarian'**
  String get translatorLangBg;

  /// No description provided for @translatorLangHr.
  ///
  /// In en, this message translates to:
  /// **'Croatian'**
  String get translatorLangHr;

  /// No description provided for @translatorLangSr.
  ///
  /// In en, this message translates to:
  /// **'Serbian'**
  String get translatorLangSr;

  /// No description provided for @translatorLangHi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get translatorLangHi;

  /// No description provided for @translatorLangTh.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get translatorLangTh;

  /// No description provided for @translatorLangVi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get translatorLangVi;

  /// No description provided for @translatorLangId.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get translatorLangId;

  /// No description provided for @translatorLangMs.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get translatorLangMs;

  /// No description provided for @translatorLangHe.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get translatorLangHe;

  /// No description provided for @translatorLangFa.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get translatorLangFa;

  /// No description provided for @callInProgress.
  ///
  /// In en, this message translates to:
  /// **'Call in progress'**
  String get callInProgress;

  /// No description provided for @joinCall.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinCall;

  /// No description provided for @createCallLink.
  ///
  /// In en, this message translates to:
  /// **'Call link'**
  String get createCallLink;

  /// No description provided for @callLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get callLinkCopied;

  /// No description provided for @callLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Room link'**
  String get callLinkTitle;

  /// No description provided for @connectionUnstable.
  ///
  /// In en, this message translates to:
  /// **'Connection unstable — check your internet'**
  String get connectionUnstable;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
