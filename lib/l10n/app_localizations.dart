import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('ha'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('mr'),
    Locale('pa'),
    Locale('pt'),
    Locale('ru'),
    Locale('sk'),
    Locale('ta'),
    Locale('te'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh')
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

  /// No description provided for @continueVerification.
  ///
  /// In en, this message translates to:
  /// **'Continue Verification'**
  String get continueVerification;

  /// No description provided for @kycInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get kycInProgress;

  /// No description provided for @kycInProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'You started verification but didn\'t finish it. Pick up right where you left off.'**
  String get kycInProgressDesc;

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

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong current password'**
  String get wrongCurrentPassword;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password too weak: at least 8 chars, letter and digit required'**
  String get passwordTooWeak;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get passwordChangeFailed;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @permissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get permissionNotifications;

  /// No description provided for @permissionNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Calls, messages, statuses'**
  String get permissionNotificationsDesc;

  /// No description provided for @permissionMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permissionMicrophone;

  /// No description provided for @permissionMicrophoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Calls and voice assistant'**
  String get permissionMicrophoneDesc;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Video calls and verification'**
  String get permissionCameraDesc;

  /// No description provided for @permissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionLocation;

  /// No description provided for @permissionLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Used for verification'**
  String get permissionLocationDesc;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'To revoke a permission, open system settings'**
  String get permissionOpenSettings;

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

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordMismatch;

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

  /// No description provided for @tabAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get tabAssistant;

  /// No description provided for @assistantChatHint.
  ///
  /// In en, this message translates to:
  /// **'Message the assistant'**
  String get assistantChatHint;

  /// No description provided for @assistantActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Item is no longer available'**
  String get assistantActionUnavailable;

  /// No description provided for @assistantAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get assistantAttachFile;

  /// No description provided for @assistantTyping.
  ///
  /// In en, this message translates to:
  /// **'Assistant is thinking…'**
  String get assistantTyping;

  /// No description provided for @assistantEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything — by voice or text'**
  String get assistantEmptyHint;

  /// No description provided for @assistantToolLoopError.
  ///
  /// In en, this message translates to:
  /// **'The assistant couldn\'t complete the request'**
  String get assistantToolLoopError;

  /// No description provided for @assistantError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again'**
  String get assistantError;

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

  /// No description provided for @tabCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get tabCalls;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

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

  /// No description provided for @meshLocalNetworkPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow local network access'**
  String get meshLocalNetworkPromptTitle;

  /// No description provided for @meshLocalNetworkPromptBody.
  ///
  /// In en, this message translates to:
  /// **'To find peers on Wi-Fi (offline group calls), iOS requires the Local Network permission. Open Settings → Privacy & Security → Local Network → Taler ID.'**
  String get meshLocalNetworkPromptBody;

  /// No description provided for @meshLocalNetworkPromptOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get meshLocalNetworkPromptOpenSettings;

  /// No description provided for @meshLocalNetworkPromptDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get meshLocalNetworkPromptDismiss;

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

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a 6-digit code to {email}.'**
  String verifyEmailSubtitle(String email);

  /// No description provided for @verifyEmailCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}. Enter it below.'**
  String verifyEmailCodeSent(String email);

  /// No description provided for @verifyEmailSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get verifyEmailSendCode;

  /// No description provided for @verifyEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyEmailConfirm;

  /// No description provided for @verifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified ✓'**
  String get verifyEmailSuccess;

  /// No description provided for @verifyEmailAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Email is already verified'**
  String get verifyEmailAlreadyVerified;

  /// No description provided for @verifyEmailBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailBannerTitle;

  /// No description provided for @verifyEmailBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to receive a 6-digit code and confirm your address.'**
  String get verifyEmailBannerSubtitle;

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

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check your internet connection.'**
  String get errorTimeout;

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoConnection;

  /// No description provided for @errorGeneral.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorGeneral;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @notifChannelMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifChannelMessages;

  /// No description provided for @notifChannelMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'New message notifications'**
  String get notifChannelMessagesDesc;

  /// No description provided for @notifChannelMissedCalls.
  ///
  /// In en, this message translates to:
  /// **'Missed calls'**
  String get notifChannelMissedCalls;

  /// No description provided for @notifChannelMissedCallsDesc.
  ///
  /// In en, this message translates to:
  /// **'Missed call notifications'**
  String get notifChannelMissedCallsDesc;

  /// No description provided for @notifMissedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get notifMissedCall;

  /// No description provided for @notifAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get notifAccept;

  /// No description provided for @notifDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get notifDecline;

  /// No description provided for @notifIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get notifIncomingCall;

  /// No description provided for @notifIncomingCallChannel.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get notifIncomingCallChannel;

  /// No description provided for @notifMissedCallChannel.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get notifMissedCallChannel;

  /// No description provided for @notifUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get notifUnknown;

  /// No description provided for @effectNone.
  ///
  /// In en, this message translates to:
  /// **'No background'**
  String get effectNone;

  /// No description provided for @effectBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get effectBlur;

  /// No description provided for @effectOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get effectOffice;

  /// No description provided for @effectNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get effectNature;

  /// No description provided for @effectGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get effectGradient;

  /// No description provided for @effectLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get effectLibrary;

  /// No description provided for @effectCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get effectCity;

  /// No description provided for @effectMinimalism.
  ///
  /// In en, this message translates to:
  /// **'Minimalism'**
  String get effectMinimalism;

  /// No description provided for @voiceParticipant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get voiceParticipant;

  /// No description provided for @voiceInvitesToRoom.
  ///
  /// In en, this message translates to:
  /// **'invites you to the room'**
  String get voiceInvitesToRoom;

  /// No description provided for @voiceRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get voiceRoom;

  /// No description provided for @voicePasswordProtected.
  ///
  /// In en, this message translates to:
  /// **'Password protected'**
  String get voicePasswordProtected;

  /// No description provided for @voicePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get voicePasswordHint;

  /// No description provided for @voiceEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get voiceEnter;

  /// No description provided for @voiceJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join the room'**
  String get voiceJoinRoom;

  /// No description provided for @voiceYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get voiceYourName;

  /// No description provided for @voiceInvitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {name}'**
  String voiceInvitationSent(String name);

  /// No description provided for @voiceNoActiveRoom.
  ///
  /// In en, this message translates to:
  /// **'No active room'**
  String get voiceNoActiveRoom;

  /// No description provided for @voiceCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings → Privacy → Camera → TalerID'**
  String get voiceCameraPermission;

  /// No description provided for @voiceOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get voiceOpenSettings;

  /// No description provided for @voiceCameraError.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable camera: {error}'**
  String voiceCameraError(String error);

  /// No description provided for @voiceAllAgreedRecording.
  ///
  /// In en, this message translates to:
  /// **'All agreed. Recording started.'**
  String get voiceAllAgreedRecording;

  /// No description provided for @voiceNewParticipantAgreed.
  ///
  /// In en, this message translates to:
  /// **'New participant agreed to recording.'**
  String get voiceNewParticipantAgreed;

  /// No description provided for @voiceDeclinedRecording.
  ///
  /// In en, this message translates to:
  /// **'You declined recording. Leaving the call.'**
  String get voiceDeclinedRecording;

  /// No description provided for @voiceRecordingEnded.
  ///
  /// In en, this message translates to:
  /// **'Recording ended'**
  String get voiceRecordingEnded;

  /// No description provided for @voiceRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording in progress'**
  String get voiceRecordingInProgress;

  /// No description provided for @voiceTranscriptionRequest.
  ///
  /// In en, this message translates to:
  /// **'Transcription request'**
  String get voiceTranscriptionRequest;

  /// No description provided for @voiceRecordingRequest.
  ///
  /// In en, this message translates to:
  /// **'Recording request'**
  String get voiceRecordingRequest;

  /// No description provided for @voiceAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get voiceAgree;

  /// No description provided for @voiceDeclineAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Decline and leave'**
  String get voiceDeclineAndLeave;

  /// No description provided for @voiceAudioOutput.
  ///
  /// In en, this message translates to:
  /// **'Audio output'**
  String get voiceAudioOutput;

  /// No description provided for @voiceAudioPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get voiceAudioPhone;

  /// No description provided for @voiceAudioSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get voiceAudioSpeaker;

  /// No description provided for @voiceAudioBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get voiceAudioBluetooth;

  /// No description provided for @voiceAudioHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get voiceAudioHeadphones;

  /// No description provided for @voiceLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get voiceLinkCopied;

  /// No description provided for @voiceTranslateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get voiceTranslateTo;

  /// No description provided for @voiceSearchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Search language...'**
  String get voiceSearchLanguage;

  /// No description provided for @voiceRoomWithCreator.
  ///
  /// In en, this message translates to:
  /// **'Room {name}'**
  String voiceRoomWithCreator(String name);

  /// No description provided for @voiceVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get voiceVoiceCall;

  /// No description provided for @voiceOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get voiceOnHold;

  /// No description provided for @voiceActiveCall.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get voiceActiveCall;

  /// No description provided for @voiceEndAllCalls.
  ///
  /// In en, this message translates to:
  /// **'End all calls'**
  String get voiceEndAllCalls;

  /// No description provided for @voiceEndThisCall.
  ///
  /// In en, this message translates to:
  /// **'End this call'**
  String get voiceEndThisCall;

  /// No description provided for @voiceCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get voiceCopyLink;

  /// No description provided for @voiceAddParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get voiceAddParticipant;

  /// No description provided for @voiceReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get voiceReconnecting;

  /// No description provided for @voiceConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get voiceConnectionError;

  /// No description provided for @voiceClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get voiceClose;

  /// No description provided for @voiceCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get voiceCalling;

  /// No description provided for @voiceCallActive.
  ///
  /// In en, this message translates to:
  /// **'Call active'**
  String get voiceCallActive;

  /// No description provided for @voiceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get voiceWaiting;

  /// No description provided for @voiceWaitingUpper.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get voiceWaitingUpper;

  /// No description provided for @voiceRec.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get voiceRec;

  /// No description provided for @voiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voiceStop;

  /// No description provided for @voiceRecord.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get voiceRecord;

  /// No description provided for @voiceTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get voiceTranslation;

  /// No description provided for @voiceAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get voiceAudio;

  /// No description provided for @voiceFlipCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get voiceFlipCamera;

  /// No description provided for @voiceBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get voiceBackground;

  /// No description provided for @voiceAssistantSpeakingStatus.
  ///
  /// In en, this message translates to:
  /// **'Assistant speaking...'**
  String get voiceAssistantSpeakingStatus;

  /// No description provided for @voiceAssistantListeningStatus.
  ///
  /// In en, this message translates to:
  /// **'Assistant listening...'**
  String get voiceAssistantListeningStatus;

  /// No description provided for @voiceUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get voiceUnmute;

  /// No description provided for @voiceMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get voiceMic;

  /// No description provided for @voiceAssistantLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get voiceAssistantLabel;

  /// No description provided for @voiceCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get voiceCameraOn;

  /// No description provided for @voiceCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get voiceCameraLabel;

  /// No description provided for @voiceEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get voiceEndCall;

  /// No description provided for @voiceWaitingParticipants.
  ///
  /// In en, this message translates to:
  /// **'Waiting for participants...'**
  String get voiceWaitingParticipants;

  /// No description provided for @voiceYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get voiceYou;

  /// No description provided for @voiceAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get voiceAiAssistant;

  /// No description provided for @voiceVideoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable'**
  String get voiceVideoUnavailable;

  /// No description provided for @voiceSearchNickname.
  ///
  /// In en, this message translates to:
  /// **'Search by nickname...'**
  String get voiceSearchNickname;

  /// No description provided for @voiceTranscriptionWord.
  ///
  /// In en, this message translates to:
  /// **'transcription'**
  String get voiceTranscriptionWord;

  /// No description provided for @voiceRecordingWord.
  ///
  /// In en, this message translates to:
  /// **'recording'**
  String get voiceRecordingWord;

  /// No description provided for @voiceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get voiceConnecting;

  /// No description provided for @voiceVideoBackground.
  ///
  /// In en, this message translates to:
  /// **'Video background'**
  String get voiceVideoBackground;

  /// No description provided for @voiceCallSettings.
  ///
  /// In en, this message translates to:
  /// **'Call settings'**
  String get voiceCallSettings;

  /// No description provided for @voiceEnableAI.
  ///
  /// In en, this message translates to:
  /// **'Enable AI assistant'**
  String get voiceEnableAI;

  /// No description provided for @voiceAIParticipating.
  ///
  /// In en, this message translates to:
  /// **'AI will participate in the conversation'**
  String get voiceAIParticipating;

  /// No description provided for @voiceNormalCall.
  ///
  /// In en, this message translates to:
  /// **'Normal call without AI'**
  String get voiceNormalCall;

  /// No description provided for @voiceCallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make a call?'**
  String get voiceCallConfirm;

  /// No description provided for @chatAlreadyInCall.
  ///
  /// In en, this message translates to:
  /// **'Already in a call'**
  String get chatAlreadyInCall;

  /// No description provided for @chatCallError.
  ///
  /// In en, this message translates to:
  /// **'Call error: {error}'**
  String chatCallError(String error);

  /// No description provided for @chatPhotoVideo.
  ///
  /// In en, this message translates to:
  /// **'Photo / Video'**
  String get chatPhotoVideo;

  /// No description provided for @chatCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatCamera;

  /// No description provided for @chatFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatFile;

  /// No description provided for @chatContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get chatContact;

  /// No description provided for @chatSelectContact.
  ///
  /// In en, this message translates to:
  /// **'Select a contact'**
  String get chatSelectContact;

  /// No description provided for @chatNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts'**
  String get chatNoContacts;

  /// No description provided for @chatUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get chatUser;

  /// No description provided for @chatFileAttachment.
  ///
  /// In en, this message translates to:
  /// **'📎 File'**
  String get chatFileAttachment;

  /// No description provided for @chatFileUploadError.
  ///
  /// In en, this message translates to:
  /// **'File upload error: {error}'**
  String chatFileUploadError(String error);

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'🎤 Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get chatGroup;

  /// No description provided for @chatDialog.
  ///
  /// In en, this message translates to:
  /// **'Dialog'**
  String get chatDialog;

  /// No description provided for @chatCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatCall;

  /// No description provided for @chatStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chatStartConversation;

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatIsTyping.
  ///
  /// In en, this message translates to:
  /// **'is typing...'**
  String get chatIsTyping;

  /// No description provided for @chatUserIsTyping.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing...'**
  String chatUserIsTyping(String name);

  /// No description provided for @chatUsersAreTyping.
  ///
  /// In en, this message translates to:
  /// **'{names} are typing...'**
  String chatUsersAreTyping(String names);

  /// No description provided for @chatPreparingFile.
  ///
  /// In en, this message translates to:
  /// **'Preparing file…'**
  String get chatPreparingFile;

  /// No description provided for @chatUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {progress}%'**
  String chatUploading(int progress);

  /// No description provided for @chatEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get chatEdited;

  /// No description provided for @chatViaMesh.
  ///
  /// In en, this message translates to:
  /// **'via mesh'**
  String get chatViaMesh;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatEdit;

  /// No description provided for @chatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// No description provided for @chatCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get chatCopied;

  /// No description provided for @chatSaveMedia.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get chatSaveMedia;

  /// No description provided for @chatForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForward;

  /// No description provided for @chatSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get chatSaving;

  /// No description provided for @chatSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get chatSavedToGallery;

  /// No description provided for @chatNoSavePermission.
  ///
  /// In en, this message translates to:
  /// **'No permission to save. Check settings.'**
  String get chatNoSavePermission;

  /// No description provided for @chatFileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get chatFileSaved;

  /// No description provided for @chatFileSaveError.
  ///
  /// In en, this message translates to:
  /// **'File save error'**
  String get chatFileSaveError;

  /// No description provided for @chatDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chatDeleteMessage;

  /// No description provided for @chatDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteForMe;

  /// No description provided for @chatDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForEveryone;

  /// No description provided for @chatMessageForwarded.
  ///
  /// In en, this message translates to:
  /// **'Message forwarded'**
  String get chatMessageForwarded;

  /// No description provided for @chatContactTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Contact · tap to open'**
  String get chatContactTapToOpen;

  /// No description provided for @chatForwardTo.
  ///
  /// In en, this message translates to:
  /// **'Forward to...'**
  String get chatForwardTo;

  /// No description provided for @chatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get chatSearchHint;

  /// No description provided for @chatRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get chatRecording;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatMessageHint;

  /// No description provided for @chatHideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get chatHideKeyboard;

  /// No description provided for @chatEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get chatEditing;

  /// No description provided for @chatFileDownloadError.
  ///
  /// In en, this message translates to:
  /// **'File download error'**
  String get chatFileDownloadError;

  /// No description provided for @chatVoiceMessageShort.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessageShort;

  /// No description provided for @chatVideoSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Video saved to gallery'**
  String get chatVideoSavedToGallery;

  /// No description provided for @chatSavingError.
  ///
  /// In en, this message translates to:
  /// **'Saving error'**
  String get chatSavingError;

  /// No description provided for @convSetNickname.
  ///
  /// In en, this message translates to:
  /// **'Set a nickname'**
  String get convSetNickname;

  /// No description provided for @convNicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'A nickname is required to use the messenger. Other users can find you by it.'**
  String get convNicknameRequired;

  /// No description provided for @convNicknameRules.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters: letters, digits, _'**
  String get convNicknameRules;

  /// No description provided for @convNicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'Nickname already taken'**
  String get convNicknameTaken;

  /// No description provided for @convSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save error'**
  String get convSaveError;

  /// No description provided for @convContactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get convContactsLabel;

  /// No description provided for @convDefaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get convDefaultUser;

  /// No description provided for @convNoDialogs.
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get convNoDialogs;

  /// No description provided for @convFindUserToChat.
  ///
  /// In en, this message translates to:
  /// **'Find a user to start chatting'**
  String get convFindUserToChat;

  /// No description provided for @convDefaultContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get convDefaultContact;

  /// No description provided for @dashboardUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get dashboardUser;

  /// No description provided for @dashboardIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get dashboardIncomingCall;

  /// No description provided for @dashboardDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get dashboardDecline;

  /// No description provided for @dashboardAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get dashboardAccept;

  /// No description provided for @dashboardActiveCall.
  ///
  /// In en, this message translates to:
  /// **'Active call — tap to return'**
  String get dashboardActiveCall;

  /// No description provided for @dashboardUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available {version}'**
  String dashboardUpdateAvailable(String version);

  /// No description provided for @dashboardUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get dashboardUpdate;

  /// No description provided for @dashboardWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get dashboardWhatsNew;

  /// No description provided for @dashboardWhatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String dashboardWhatsNewTitle(String version);

  /// No description provided for @dashboardInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get dashboardInstalling;

  /// No description provided for @updateInstallConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update in place'**
  String get updateInstallConflictTitle;

  /// No description provided for @updateInstallConflictBody.
  ///
  /// In en, this message translates to:
  /// **'The installed version is signed with a different certificate, so Android refuses to update it. Uninstall the app via Settings → Apps → Taler ID, then open the Downloads folder in your file manager and tap {filename} to install fresh. This step is only needed once.'**
  String updateInstallConflictBody(String filename);

  /// No description provided for @updateInstallFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get updateInstallFailedTitle;

  /// No description provided for @updateInstallFailedBody.
  ///
  /// In en, this message translates to:
  /// **'{reason}\n\nThe APK was saved to your Downloads folder as {filename} — you can try installing it manually from a file manager.'**
  String updateInstallFailedBody(String reason, String filename);

  /// No description provided for @updateInstallOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get updateInstallOk;

  /// No description provided for @contactRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactRequestsTitle;

  /// No description provided for @messengerContactRequestsSection.
  ///
  /// In en, this message translates to:
  /// **'Contact requests'**
  String get messengerContactRequestsSection;

  /// No description provided for @messengerContactRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new request} other{{count} new requests}}'**
  String messengerContactRequestsCount(int count);

  /// No description provided for @contactRequestsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get contactRequestsSearch;

  /// No description provided for @contactRequestsIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get contactRequestsIncoming;

  /// No description provided for @contactRequestsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get contactRequestsSent;

  /// No description provided for @contactRequestsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Nickname or email'**
  String get contactRequestsSearchHint;

  /// No description provided for @contactRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get contactRequestSent;

  /// No description provided for @contactRequestsNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get contactRequestsNoUsers;

  /// No description provided for @contactRequestsSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter exact nickname or email\nand press search'**
  String get contactRequestsSearchHelp;

  /// No description provided for @contactRequestsSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get contactRequestsSendTooltip;

  /// No description provided for @contactRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact request'**
  String get contactRequestTitle;

  /// No description provided for @contactRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send contact request to {name}?'**
  String contactRequestConfirm(String name);

  /// No description provided for @contactRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactRequestSend;

  /// No description provided for @contactRequestsNoIncoming.
  ///
  /// In en, this message translates to:
  /// **'No incoming requests'**
  String get contactRequestsNoIncoming;

  /// No description provided for @contactRequestsNoSent.
  ///
  /// In en, this message translates to:
  /// **'No sent requests'**
  String get contactRequestsNoSent;

  /// No description provided for @contactRequestStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get contactRequestStatusPending;

  /// No description provided for @contactRequestStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get contactRequestStatusAccepted;

  /// No description provided for @contactRequestStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get contactRequestStatusRejected;

  /// No description provided for @userSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find user'**
  String get userSearchTitle;

  /// No description provided for @userSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Nickname, phone or email'**
  String get userSearchHint;

  /// No description provided for @userSearchHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter @nickname, email or name to search'**
  String get userSearchHelper;

  /// No description provided for @userSearchNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get userSearchNoUsers;

  /// No description provided for @userProfileShareContact.
  ///
  /// In en, this message translates to:
  /// **'Share contact'**
  String get userProfileShareContact;

  /// No description provided for @userProfileShareContactDesc.
  ///
  /// In en, this message translates to:
  /// **'Send contact link'**
  String get userProfileShareContactDesc;

  /// No description provided for @userProfileCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get userProfileCopyLink;

  /// No description provided for @userProfileCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get userProfileCopied;

  /// No description provided for @userProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get userProfileTitle;

  /// No description provided for @userProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Profile load error'**
  String get userProfileLoadError;

  /// No description provided for @userProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get userProfileMessage;

  /// No description provided for @userProfileCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get userProfileCall;

  /// No description provided for @userProfileRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get userProfileRequestSent;

  /// No description provided for @userProfileAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get userProfileAccept;

  /// No description provided for @userProfileDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get userProfileDecline;

  /// No description provided for @userProfileAddToContacts.
  ///
  /// In en, this message translates to:
  /// **'Add to contacts'**
  String get userProfileAddToContacts;

  /// No description provided for @userProfileMediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get userProfileMediaTab;

  /// No description provided for @userProfileFilesTab.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get userProfileFilesTab;

  /// No description provided for @userProfileLinksTab.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get userProfileLinksTab;

  /// No description provided for @userProfileRecordingsTab.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get userProfileRecordingsTab;

  /// No description provided for @userProfileSummariesTab.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get userProfileSummariesTab;

  /// No description provided for @userProfileNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media files'**
  String get userProfileNoMedia;

  /// No description provided for @userProfileNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get userProfileNoFiles;

  /// No description provided for @userProfileNoLinks.
  ///
  /// In en, this message translates to:
  /// **'No links'**
  String get userProfileNoLinks;

  /// No description provided for @userProfileNoRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings'**
  String get userProfileNoRecordings;

  /// No description provided for @userProfileNoSummaries.
  ///
  /// In en, this message translates to:
  /// **'No summaries'**
  String get userProfileNoSummaries;

  /// No description provided for @userProfileMeetingSummary.
  ///
  /// In en, this message translates to:
  /// **'Meeting summary'**
  String get userProfileMeetingSummary;

  /// No description provided for @userProfileFailedOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat'**
  String get userProfileFailedOpenChat;

  /// No description provided for @sharedMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Media and files'**
  String get sharedMediaTitle;

  /// No description provided for @sharedMediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get sharedMediaTab;

  /// No description provided for @sharedFilesTab.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get sharedFilesTab;

  /// No description provided for @sharedLinksTab.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get sharedLinksTab;

  /// No description provided for @sharedNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media files'**
  String get sharedNoMedia;

  /// No description provided for @sharedNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get sharedNoFiles;

  /// No description provided for @sharedNoLinks.
  ///
  /// In en, this message translates to:
  /// **'No links'**
  String get sharedNoLinks;

  /// No description provided for @shareToChat.
  ///
  /// In en, this message translates to:
  /// **'Forward to chat'**
  String get shareToChat;

  /// No description provided for @shareSelectChat.
  ///
  /// In en, this message translates to:
  /// **'Select chat'**
  String get shareSelectChat;

  /// No description provided for @shareNoChats.
  ///
  /// In en, this message translates to:
  /// **'No chats'**
  String get shareNoChats;

  /// No description provided for @shareFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String shareFilesCount(int count);

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get contactsAddTooltip;

  /// No description provided for @contactsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get contactsSearchHint;

  /// No description provided for @contactsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get contactsNotFound;

  /// No description provided for @contactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts'**
  String get contactsEmpty;

  /// No description provided for @contactsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get contactsAdd;

  /// No description provided for @contactsPendingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get contactsPendingConfirmation;

  /// No description provided for @contactsMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactsMessage;

  /// No description provided for @contactsCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get contactsCall;

  /// No description provided for @contactsResend.
  ///
  /// In en, this message translates to:
  /// **'Resend request'**
  String get contactsResend;

  /// No description provided for @contactsResendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Retry in 24h'**
  String get contactsResendTimeout;

  /// No description provided for @contactsResent.
  ///
  /// In en, this message translates to:
  /// **'Request resent'**
  String get contactsResent;

  /// No description provided for @contactsWantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect with you'**
  String get contactsWantsToConnect;

  /// No description provided for @contactsSearchPeople.
  ///
  /// In en, this message translates to:
  /// **'Find people'**
  String get contactsSearchPeople;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @notesAssistantSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Assistant speaking...'**
  String get notesAssistantSpeaking;

  /// No description provided for @notesListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get notesListening;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get notesEmpty;

  /// No description provided for @notesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Press mic for dictation\nor + for manual entry'**
  String get notesEmptyHint;

  /// No description provided for @notesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get notesDeleteConfirm;

  /// No description provided for @notesNew.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get notesNew;

  /// No description provided for @notesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get notesEdit;

  /// No description provided for @notesTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notesTitleHint;

  /// No description provided for @notesContentHint.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get notesContentHint;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get calendarStop;

  /// No description provided for @calendarVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get calendarVoiceInput;

  /// No description provided for @calendarNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarNewEvent;

  /// No description provided for @calendarAssistantSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Assistant speaking...'**
  String get calendarAssistantSpeaking;

  /// No description provided for @calendarListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get calendarListening;

  /// No description provided for @calendarInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations ({count})'**
  String calendarInvitations(int count);

  /// No description provided for @calendarNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get calendarNoEvents;

  /// No description provided for @calendarDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calendarDayMon;

  /// No description provided for @calendarDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calendarDayTue;

  /// No description provided for @calendarDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calendarDayWed;

  /// No description provided for @calendarDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calendarDayThu;

  /// No description provided for @calendarDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calendarDayFri;

  /// No description provided for @calendarDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calendarDaySat;

  /// No description provided for @calendarDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calendarDaySun;

  /// No description provided for @calendarEnterRoom.
  ///
  /// In en, this message translates to:
  /// **'Enter room'**
  String get calendarEnterRoom;

  /// No description provided for @calendarMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get calendarMeeting;

  /// No description provided for @calendarLocationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String calendarLocationPrefix(String location);

  /// No description provided for @calendarEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get calendarEditEvent;

  /// No description provided for @calendarTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get calendarTitleHint;

  /// No description provided for @calendarDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get calendarDescriptionHint;

  /// No description provided for @calendarTypeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get calendarTypeEvent;

  /// No description provided for @calendarTypeMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get calendarTypeMeeting;

  /// No description provided for @calendarTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get calendarTypeReminder;

  /// No description provided for @calendarKindEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get calendarKindEvent;

  /// No description provided for @calendarKindTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get calendarKindTask;

  /// No description provided for @calendarTaskMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get calendarTaskMarkDone;

  /// No description provided for @calendarTaskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get calendarTaskDelete;

  /// No description provided for @calendarTaskDoneMsg.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get calendarTaskDoneMsg;

  /// No description provided for @calendarTaskDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get calendarTaskDeletedMsg;

  /// No description provided for @calendarTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get calendarTypeLabel;

  /// No description provided for @calendarMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get calendarMeetingLink;

  /// No description provided for @calendarLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get calendarLocationHint;

  /// No description provided for @calendarDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get calendarDateLabel;

  /// No description provided for @calendarTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get calendarTimeLabel;

  /// No description provided for @calendarReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get calendarReminderLabel;

  /// No description provided for @calendarReminderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get calendarReminderNone;

  /// No description provided for @calendarReminder15min.
  ///
  /// In en, this message translates to:
  /// **'15 min before'**
  String get calendarReminder15min;

  /// No description provided for @calendarReminder30min.
  ///
  /// In en, this message translates to:
  /// **'30 min before'**
  String get calendarReminder30min;

  /// No description provided for @calendarReminder1hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get calendarReminder1hour;

  /// No description provided for @calendarRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get calendarRepeatLabel;

  /// No description provided for @calendarRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'No repeat'**
  String get calendarRepeatNone;

  /// No description provided for @calendarRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get calendarRepeatDaily;

  /// No description provided for @calendarRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get calendarRepeatWeekly;

  /// No description provided for @calendarRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get calendarRepeatMonthly;

  /// No description provided for @calendarRepeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get calendarRepeatYearly;

  /// No description provided for @calendarParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get calendarParticipants;

  /// No description provided for @calendarAddParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get calendarAddParticipant;

  /// No description provided for @calendarSearchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get calendarSearchContacts;

  /// No description provided for @calendarNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts'**
  String get calendarNoContacts;

  /// No description provided for @calendarStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get calendarStatusAccepted;

  /// No description provided for @calendarStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get calendarStatusDeclined;

  /// No description provided for @calendarStatusMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get calendarStatusMaybe;

  /// No description provided for @calendarStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get calendarStatusPending;

  /// No description provided for @calendarEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get calendarEndTime;

  /// No description provided for @calendarYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer:'**
  String get calendarYourAnswer;

  /// No description provided for @calendarOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get calendarOrganizer;

  /// No description provided for @calendarDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String calendarDeleteError(String error);

  /// No description provided for @calendarRsvpAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get calendarRsvpAccept;

  /// No description provided for @calendarRsvpMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get calendarRsvpMaybe;

  /// No description provided for @calendarRsvpDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get calendarRsvpDecline;

  /// No description provided for @callHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get callHistoryTitle;

  /// No description provided for @callHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callHistoryTab;

  /// No description provided for @callHistoryTempMeeting.
  ///
  /// In en, this message translates to:
  /// **'Temporary meeting'**
  String get callHistoryTempMeeting;

  /// No description provided for @callHistoryCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get callHistoryCopy;

  /// No description provided for @callHistoryLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get callHistoryLinkCopied;

  /// No description provided for @callHistoryShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get callHistoryShare;

  /// No description provided for @callHistoryEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get callHistoryEnter;

  /// No description provided for @callHistoryAlreadyInCall.
  ///
  /// In en, this message translates to:
  /// **'Already in a call'**
  String get callHistoryAlreadyInCall;

  /// No description provided for @callHistoryCouldNotDeterminePeer.
  ///
  /// In en, this message translates to:
  /// **'Could not determine the other party'**
  String get callHistoryCouldNotDeterminePeer;

  /// No description provided for @callHistoryContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get callHistoryContacts;

  /// No description provided for @callHistoryFailedLoadRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your room'**
  String get callHistoryFailedLoadRoom;

  /// No description provided for @callHistoryYourRoom.
  ///
  /// In en, this message translates to:
  /// **'Your room'**
  String get callHistoryYourRoom;

  /// No description provided for @callHistoryCreateMeeting.
  ///
  /// In en, this message translates to:
  /// **'Create meeting'**
  String get callHistoryCreateMeeting;

  /// No description provided for @callHistoryMeetingSummaries.
  ///
  /// In en, this message translates to:
  /// **'Meeting summaries'**
  String get callHistoryMeetingSummaries;

  /// No description provided for @callHistoryMeetingRecordings.
  ///
  /// In en, this message translates to:
  /// **'Meeting recordings'**
  String get callHistoryMeetingRecordings;

  /// No description provided for @callHistoryNoCalls.
  ///
  /// In en, this message translates to:
  /// **'No calls'**
  String get callHistoryNoCalls;

  /// No description provided for @callHistoryMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get callHistoryMissed;

  /// No description provided for @callHistoryRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get callHistoryRecording;

  /// No description provided for @callHistorySummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get callHistorySummary;

  /// No description provided for @callHistoryCallAgain.
  ///
  /// In en, this message translates to:
  /// **'Call again'**
  String get callHistoryCallAgain;

  /// No description provided for @callHistoryTodayTime.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String callHistoryTodayTime(String time);

  /// No description provided for @callHistoryYesterdayTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String callHistoryYesterdayTime(String time);

  /// No description provided for @callHistoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get callHistoryUnknown;

  /// No description provided for @callHistoryDetails.
  ///
  /// In en, this message translates to:
  /// **'Call details'**
  String get callHistoryDetails;

  /// No description provided for @callHistoryOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing call'**
  String get callHistoryOutgoing;

  /// No description provided for @callHistoryIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callHistoryIncoming;

  /// No description provided for @callHistoryDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String callHistoryDuration(String duration);

  /// No description provided for @callHistoryWithAI.
  ///
  /// In en, this message translates to:
  /// **'With AI assistant'**
  String get callHistoryWithAI;

  /// No description provided for @callHistoryParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get callHistoryParticipants;

  /// Suffix appended to the current user's display name in the call details participants list.
  ///
  /// In en, this message translates to:
  /// **'(You)'**
  String get callDetailYouSuffix;

  /// No description provided for @callHistoryMeetingSummary.
  ///
  /// In en, this message translates to:
  /// **'Meeting summary'**
  String get callHistoryMeetingSummary;

  /// No description provided for @callHistoryMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get callHistoryMoreDetails;

  /// No description provided for @callHistorySummaryProcessing.
  ///
  /// In en, this message translates to:
  /// **'Summary processing...'**
  String get callHistorySummaryProcessing;

  /// No description provided for @callHistoryMeetingRecording.
  ///
  /// In en, this message translates to:
  /// **'Meeting recording'**
  String get callHistoryMeetingRecording;

  /// No description provided for @callHistoryProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get callHistoryProcessing;

  /// No description provided for @callHistoryCreateTranscript.
  ///
  /// In en, this message translates to:
  /// **'Create transcript'**
  String get callHistoryCreateTranscript;

  /// No description provided for @callHistoryNoSummaries.
  ///
  /// In en, this message translates to:
  /// **'No summaries'**
  String get callHistoryNoSummaries;

  /// No description provided for @callHistoryRecordDuringCall.
  ///
  /// In en, this message translates to:
  /// **'Press \"Record\" during a call'**
  String get callHistoryRecordDuringCall;

  /// No description provided for @callHistoryMeetingTime.
  ///
  /// In en, this message translates to:
  /// **'Meeting {time}'**
  String callHistoryMeetingTime(String time);

  /// No description provided for @callHistoryTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing and summarizing...'**
  String get callHistoryTranscribing;

  /// No description provided for @callHistoryTranscriptCreated.
  ///
  /// In en, this message translates to:
  /// **'Transcript created'**
  String get callHistoryTranscriptCreated;

  /// No description provided for @callHistoryNoRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings'**
  String get callHistoryNoRecordings;

  /// No description provided for @callHistoryRecordingDate.
  ///
  /// In en, this message translates to:
  /// **'Recording {date}'**
  String callHistoryRecordingDate(String date);

  /// No description provided for @callHistoryRecordingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Recording unavailable'**
  String get callHistoryRecordingUnavailable;

  /// No description provided for @callHistoryTranscriptReady.
  ///
  /// In en, this message translates to:
  /// **'Transcript ready'**
  String get callHistoryTranscriptReady;

  /// No description provided for @callHistoryTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get callHistoryTranscript;

  /// No description provided for @callHistoryKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key points'**
  String get callHistoryKeyPoints;

  /// No description provided for @callHistoryTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get callHistoryTasks;

  /// No description provided for @callHistoryAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to: {assignee}'**
  String callHistoryAssignedTo(String assignee);

  /// No description provided for @callHistoryDecisions.
  ///
  /// In en, this message translates to:
  /// **'Decisions'**
  String get callHistoryDecisions;

  /// No description provided for @callHistoryShowTranscript.
  ///
  /// In en, this message translates to:
  /// **'Show full transcript'**
  String get callHistoryShowTranscript;

  /// No description provided for @profileScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get profileScanQr;

  /// No description provided for @profileMyQrCode.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get profileMyQrCode;

  /// No description provided for @profileAddMeShare.
  ///
  /// In en, this message translates to:
  /// **'Add me in Taler ID!\ntalerid://user/{userId}'**
  String profileAddMeShare(String userId);

  /// No description provided for @profileShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show this code to add you'**
  String get profileShowCode;

  /// No description provided for @profileEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Name, surname, patronymic, date of birth'**
  String get profileEditDesc;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get profileAboutMe;

  /// No description provided for @profileAboutMeDesc.
  ///
  /// In en, this message translates to:
  /// **'Values, skills, interests and more'**
  String get profileAboutMeDesc;

  /// No description provided for @profileNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get profileNotes;

  /// No description provided for @profileNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Thoughts, ideas and notes'**
  String get profileNotesDesc;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get profileAvatarUpdated;

  /// No description provided for @profileNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNickname;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileChangeNickname.
  ///
  /// In en, this message translates to:
  /// **'Change nickname'**
  String get profileChangeNickname;

  /// No description provided for @profileNicknameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated'**
  String get profileNicknameUpdated;

  /// No description provided for @profileShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileShareLabel;

  /// No description provided for @profileScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get profileScanQrCode;

  /// No description provided for @profilePointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point camera at QR code'**
  String get profilePointCamera;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoGallery;

  /// No description provided for @editProfilePatronymic.
  ///
  /// In en, this message translates to:
  /// **'Patronymic (optional)'**
  String get editProfilePatronymic;

  /// No description provided for @editProfileDateFormat.
  ///
  /// In en, this message translates to:
  /// **'DD.MM.YYYY'**
  String get editProfileDateFormat;

  /// No description provided for @aboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMeTitle;

  /// No description provided for @aboutMeClickToFill.
  ///
  /// In en, this message translates to:
  /// **'Click to fill'**
  String get aboutMeClickToFill;

  /// No description provided for @aboutMeCoreValues.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get aboutMeCoreValues;

  /// No description provided for @aboutMeWorldview.
  ///
  /// In en, this message translates to:
  /// **'Worldview'**
  String get aboutMeWorldview;

  /// No description provided for @aboutMeSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get aboutMeSkills;

  /// No description provided for @aboutMeInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get aboutMeInterests;

  /// No description provided for @aboutMeDesires.
  ///
  /// In en, this message translates to:
  /// **'Desires'**
  String get aboutMeDesires;

  /// No description provided for @aboutMeBackground.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get aboutMeBackground;

  /// No description provided for @aboutMeLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get aboutMeLikes;

  /// No description provided for @aboutMeDislikes.
  ///
  /// In en, this message translates to:
  /// **'Dislikes'**
  String get aboutMeDislikes;

  /// No description provided for @aboutMeDeleteSection.
  ///
  /// In en, this message translates to:
  /// **'Delete section?'**
  String get aboutMeDeleteSection;

  /// No description provided for @aboutMeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'All data in this section will be deleted.'**
  String get aboutMeDeleteConfirm;

  /// No description provided for @aboutMeConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {error}'**
  String aboutMeConnectionError(String error);

  /// No description provided for @aboutMeVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get aboutMeVisibility;

  /// No description provided for @aboutMeTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get aboutMeTags;

  /// No description provided for @aboutMeAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag...'**
  String get aboutMeAddTag;

  /// No description provided for @aboutMeDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get aboutMeDescription;

  /// No description provided for @aboutMeDescribeLong.
  ///
  /// In en, this message translates to:
  /// **'Tell us more...'**
  String get aboutMeDescribeLong;

  /// No description provided for @aboutMeVisibilityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get aboutMeVisibilityEveryone;

  /// No description provided for @aboutMeVisibilityContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get aboutMeVisibilityContacts;

  /// No description provided for @aboutMeVisibilityOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get aboutMeVisibilityOnlyMe;

  /// No description provided for @settingsProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfileSubtitle;

  /// No description provided for @settingsWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get settingsWallpaper;

  /// No description provided for @settingsWallpaperDesc.
  ///
  /// In en, this message translates to:
  /// **'Background image for the whole app'**
  String get settingsWallpaperDesc;

  /// No description provided for @settingsWallpaperNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsWallpaperNone;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsKycVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification (KYC)'**
  String get settingsKycVerification;

  /// No description provided for @settingsOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get settingsOrganizations;

  /// No description provided for @incomingCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get incomingCallLabel;

  /// No description provided for @incomingCallDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get incomingCallDecline;

  /// No description provided for @incomingCallAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get incomingCallAccept;

  /// Title of the dialog shown when the person we are calling out to dials us at the same time.
  ///
  /// In en, this message translates to:
  /// **'{name} is also calling you'**
  String callGlareTitle(String name);

  /// No description provided for @callGlareBody.
  ///
  /// In en, this message translates to:
  /// **'You both dialled each other at the same moment. Pick up theirs or stay on yours?'**
  String get callGlareBody;

  /// No description provided for @callGlareSwitch.
  ///
  /// In en, this message translates to:
  /// **'Pick up theirs'**
  String get callGlareSwitch;

  /// No description provided for @callGlareKeepOwn.
  ///
  /// In en, this message translates to:
  /// **'Stay on mine'**
  String get callGlareKeepOwn;

  /// No description provided for @meshIncomingCallLabel.
  ///
  /// In en, this message translates to:
  /// **'📡 Incoming mesh call'**
  String get meshIncomingCallLabel;

  /// No description provided for @meshDeviceFallback.
  ///
  /// In en, this message translates to:
  /// **'Mesh device {hexPrefix}'**
  String meshDeviceFallback(String hexPrefix);

  /// No description provided for @callConflictAlreadyInCall.
  ///
  /// In en, this message translates to:
  /// **'Finish the current call first'**
  String get callConflictAlreadyInCall;

  /// No description provided for @callPopupTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Call via'**
  String get callPopupTransportTitle;

  /// No description provided for @callPopupTransportMesh.
  ///
  /// In en, this message translates to:
  /// **'📡 Mesh (peer-to-peer)'**
  String get callPopupTransportMesh;

  /// No description provided for @callPopupTransportLk.
  ///
  /// In en, this message translates to:
  /// **'📞 Server'**
  String get callPopupTransportLk;

  /// No description provided for @callPopupTransportMeshUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact not reachable via mesh'**
  String get callPopupTransportMeshUnavailable;

  /// No description provided for @meshOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'📡 Mesh calls need the app open'**
  String get meshOnboardingTitle;

  /// No description provided for @meshOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'When the phone is locked, mesh calls may drop after ~30 seconds (iOS limitation).'**
  String get meshOnboardingBody;

  /// No description provided for @meshOnboardingAck.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get meshOnboardingAck;

  /// No description provided for @meshHistoryBadge.
  ///
  /// In en, this message translates to:
  /// **'📡 Mesh'**
  String get meshHistoryBadge;

  /// No description provided for @meshHistoryNoChatAvailable.
  ///
  /// In en, this message translates to:
  /// **'Contact is not in your list'**
  String get meshHistoryNoChatAvailable;

  /// No description provided for @meshCallStatusInviting.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get meshCallStatusInviting;

  /// No description provided for @meshCallStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get meshCallStatusConnecting;

  /// No description provided for @meshCallEndedUserHangup.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get meshCallEndedUserHangup;

  /// No description provided for @meshCallEndedRemoteHangup.
  ///
  /// In en, this message translates to:
  /// **'Ended by peer'**
  String get meshCallEndedRemoteHangup;

  /// No description provided for @meshCallEndedRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get meshCallEndedRejected;

  /// No description provided for @meshCallEndedNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get meshCallEndedNoAnswer;

  /// No description provided for @meshCallEndedConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get meshCallEndedConnectionLost;

  /// No description provided for @meshCallEndedError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get meshCallEndedError;

  /// No description provided for @meshCallTransportBadge.
  ///
  /// In en, this message translates to:
  /// **'📡 Mesh · {transport}'**
  String meshCallTransportBadge(String transport);

  /// No description provided for @meshCallTransportBadgePlain.
  ///
  /// In en, this message translates to:
  /// **'📡 Mesh'**
  String get meshCallTransportBadgePlain;

  /// No description provided for @batteryExemptionTitle.
  ///
  /// In en, this message translates to:
  /// **'📡 Reliable mesh calls'**
  String get batteryExemptionTitle;

  /// No description provided for @batteryExemptionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow the app to run without battery restrictions so Android doesn\'t kill the mesh in the background.'**
  String get batteryExemptionBody;

  /// No description provided for @batteryExemptionAccept.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get batteryExemptionAccept;

  /// No description provided for @batteryExemptionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get batteryExemptionDismiss;

  /// No description provided for @groupCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get groupCamera;

  /// No description provided for @groupGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get groupGallery;

  /// No description provided for @groupAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group avatar updated'**
  String get groupAvatarUpdated;

  /// No description provided for @groupNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameTitle;

  /// No description provided for @groupEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get groupEnterName;

  /// No description provided for @groupDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Group description'**
  String get groupDescriptionTitle;

  /// No description provided for @groupEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter group description'**
  String get groupEnterDescription;

  /// No description provided for @groupChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get groupChangeRoleTitle;

  /// No description provided for @groupRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get groupRemoveMemberTitle;

  /// No description provided for @groupDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupDescription;

  /// No description provided for @groupAddDescription.
  ///
  /// In en, this message translates to:
  /// **'Add group description'**
  String get groupAddDescription;

  /// No description provided for @groupNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get groupNoDescription;

  /// No description provided for @groupMediaAndFiles.
  ///
  /// In en, this message translates to:
  /// **'Media and files'**
  String get groupMediaAndFiles;

  /// No description provided for @groupMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get groupMuteNotifications;

  /// No description provided for @groupMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get groupMuted;

  /// No description provided for @groupNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get groupNoResults;

  /// No description provided for @authInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Try again.'**
  String get authInvalidCode;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use email and password'**
  String get loginSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordRequired;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account for the entire Taler ecosystem'**
  String get registerSubtitle;

  /// No description provided for @usernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get usernameOptional;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum 30 characters'**
  String get usernameMaxLength;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Only letters, digits and _'**
  String get usernameInvalid;

  /// No description provided for @biometricLoginReason.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Taler ID'**
  String get biometricLoginReason;

  /// No description provided for @docTypePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get docTypePassport;

  /// No description provided for @docTypeIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get docTypeIdCard;

  /// No description provided for @docTypeDriverLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get docTypeDriverLicense;

  /// No description provided for @docTypeResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence Permit'**
  String get docTypeResidencePermit;

  /// No description provided for @addressApartment.
  ///
  /// In en, this message translates to:
  /// **'apt. {number}'**
  String addressApartment(String number);

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @failedToStartKyb.
  ///
  /// In en, this message translates to:
  /// **'Failed to start KYB verification'**
  String get failedToStartKyb;

  /// No description provided for @orgUpdated.
  ///
  /// In en, this message translates to:
  /// **'Organization updated'**
  String get orgUpdated;

  /// No description provided for @failedToUpdateOrg.
  ///
  /// In en, this message translates to:
  /// **'Failed to update organization'**
  String get failedToUpdateOrg;

  /// No description provided for @failedToChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to change role'**
  String get failedToChangeRole;

  /// No description provided for @failedToRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member'**
  String get failedToRemoveMember;

  /// No description provided for @capabilityMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get capabilityMessagesTitle;

  /// No description provided for @capabilityMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Check messages or write to someone. For example: \"Write to Viktor: will be there in an hour\"'**
  String get capabilityMessagesDesc;

  /// No description provided for @capabilityCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get capabilityCallsTitle;

  /// No description provided for @capabilityCallsDesc.
  ///
  /// In en, this message translates to:
  /// **'Call any contact by voice. For example: \"Call Viktor Viktorov\"'**
  String get capabilityCallsDesc;

  /// No description provided for @capabilityChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get capabilityChatTitle;

  /// No description provided for @capabilityChatDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'ll analyze the chat history. For example: \"What did we discuss with Viktor?\"'**
  String get capabilityChatDesc;

  /// No description provided for @capabilityProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get capabilityProfileTitle;

  /// No description provided for @capabilityProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'ll show or update your profile. For example: \"Show my profile\"'**
  String get capabilityProfileDesc;

  /// No description provided for @capabilityCoachingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching'**
  String get capabilityCoachingTitle;

  /// No description provided for @capabilityCoachingDesc.
  ///
  /// In en, this message translates to:
  /// **'Modes: ICF coaching, psychologist, HR consultation. Say: \"Let\'s do coaching\"'**
  String get capabilityCoachingDesc;

  /// No description provided for @capabilityCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get capabilityCalendarTitle;

  /// No description provided for @capabilityCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedule a meeting or set a reminder. For example: \"Schedule a meeting with Viktor for tomorrow at 15:00\"'**
  String get capabilityCalendarDesc;

  /// No description provided for @capabilityNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get capabilityNotesTitle;

  /// No description provided for @capabilityNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Save a thought or read recent notes. For example: \"Write down an idea...\" or \"Read recent notes\"'**
  String get capabilityNotesDesc;

  /// No description provided for @assistantCallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make a call?'**
  String get assistantCallConfirm;

  /// No description provided for @callNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get callNoAnswer;

  /// No description provided for @contactDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove contact'**
  String get contactDelete;

  /// No description provided for @contactDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove contact'**
  String get contactDeleteTitle;

  /// No description provided for @contactDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This contact will be removed.'**
  String get contactDeleteConfirm;

  /// No description provided for @contactBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get contactBlock;

  /// No description provided for @contactBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get contactBlockTitle;

  /// No description provided for @contactBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'This user will not be able to message or call you.'**
  String get contactBlockConfirm;

  /// No description provided for @contactUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get contactUnblock;

  /// No description provided for @contactBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get contactBlocked;

  /// No description provided for @contactYouAreBlocked.
  ///
  /// In en, this message translates to:
  /// **'This user has blocked you'**
  String get contactYouAreBlocked;

  /// No description provided for @chatBlockedByYou.
  ///
  /// In en, this message translates to:
  /// **'You have blocked this user'**
  String get chatBlockedByYou;

  /// No description provided for @chatYouAreBlocked.
  ///
  /// In en, this message translates to:
  /// **'You have been blocked by this user'**
  String get chatYouAreBlocked;

  /// No description provided for @chatNotContacts.
  ///
  /// In en, this message translates to:
  /// **'Add this user to contacts to message them'**
  String get chatNotContacts;

  /// No description provided for @contactRevokeRequest.
  ///
  /// In en, this message translates to:
  /// **'Revoke request'**
  String get contactRevokeRequest;

  /// No description provided for @messengerPoll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get messengerPoll;

  /// No description provided for @messengerCreatePoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get messengerCreatePoll;

  /// No description provided for @messengerPollQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get messengerPollQuestion;

  /// No description provided for @messengerPollOption.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String messengerPollOption(int number);

  /// No description provided for @messengerPollAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get messengerPollAddOption;

  /// No description provided for @messengerPollAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous voting'**
  String get messengerPollAnonymous;

  /// No description provided for @messengerPollMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get messengerPollMultiple;

  /// No description provided for @messengerPollCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create poll'**
  String get messengerPollCreateError;

  /// No description provided for @messengerPollUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Poll unavailable'**
  String get messengerPollUnavailable;

  /// No description provided for @messengerPollMultipleNote.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple'**
  String get messengerPollMultipleNote;

  /// No description provided for @messengerPollVotes.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String messengerPollVotes(int count);

  /// No description provided for @messengerVideoMessage.
  ///
  /// In en, this message translates to:
  /// **'Video message'**
  String get messengerVideoMessage;

  /// No description provided for @messengerVideoRecordError.
  ///
  /// In en, this message translates to:
  /// **'Video recording error'**
  String get messengerVideoRecordError;

  /// No description provided for @messengerVideoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Could not play video'**
  String get messengerVideoPlaybackError;

  /// No description provided for @messengerGalleryAccessError.
  ///
  /// In en, this message translates to:
  /// **'No access to gallery'**
  String get messengerGalleryAccessError;

  /// No description provided for @messengerSearchInChat.
  ///
  /// In en, this message translates to:
  /// **'Search in chat...'**
  String get messengerSearchInChat;

  /// No description provided for @messengerSaveToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get messengerSaveToFavorites;

  /// No description provided for @messengerSavedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Saved to favorites'**
  String get messengerSavedToFavorites;

  /// No description provided for @messengerSearchInMessages.
  ///
  /// In en, this message translates to:
  /// **'Search in messages...'**
  String get messengerSearchInMessages;

  /// No description provided for @messengerFoundInMessages.
  ///
  /// In en, this message translates to:
  /// **'Found in messages ({count})'**
  String messengerFoundInMessages(int count);

  /// No description provided for @messengerGroupDefault.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get messengerGroupDefault;

  /// No description provided for @messengerUserDefault.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get messengerUserDefault;

  /// No description provided for @messengerPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get messengerPin;

  /// No description provided for @messengerUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get messengerUnpin;

  /// No description provided for @messengerArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get messengerArchive;

  /// No description provided for @messengerUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get messengerUnarchive;

  /// No description provided for @messengerDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get messengerDeleteChat;

  /// No description provided for @messengerDeleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get messengerDeleteChatTitle;

  /// No description provided for @messengerDeleteChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete chat with {name}? This cannot be undone.'**
  String messengerDeleteChatConfirm(String name);

  /// No description provided for @messengerCreateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create Channel'**
  String get messengerCreateChannel;

  /// No description provided for @messengerChannelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get messengerChannelName;

  /// No description provided for @messengerChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get messengerChannelDescription;

  /// No description provided for @messengerChannelCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create channel'**
  String get messengerChannelCreateError;

  /// No description provided for @messengerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get messengerFilterAll;

  /// No description provided for @messengerFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get messengerFilterUnread;

  /// No description provided for @messengerFilterPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get messengerFilterPersonal;

  /// No description provided for @messengerFilterGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get messengerFilterGroups;

  /// No description provided for @messengerFilterChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get messengerFilterChannels;

  /// No description provided for @messengerArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get messengerArchivedSection;

  /// No description provided for @messengerSavedSection.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get messengerSavedSection;

  /// No description provided for @messengerSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save to memory'**
  String get messengerSavedSubtitle;

  /// No description provided for @messengerArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive ({count})'**
  String messengerArchiveTitle(int count);

  /// No description provided for @messengerArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get messengerArchiveEmpty;

  /// No description provided for @messengerYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {message}'**
  String messengerYouPrefix(String message);

  /// No description provided for @messengerMissedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get messengerMissedCall;

  /// No description provided for @messengerSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get messengerSavedTitle;

  /// No description provided for @messengerNoSavedMessages.
  ///
  /// In en, this message translates to:
  /// **'No saved messages'**
  String get messengerNoSavedMessages;

  /// No description provided for @messengerSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Long press a message → \"Save to favorites\"'**
  String get messengerSavedHint;

  /// No description provided for @messengerDefaultFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get messengerDefaultFile;

  /// No description provided for @messengerTopicDefault.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get messengerTopicDefault;

  /// No description provided for @messengerTopicNew.
  ///
  /// In en, this message translates to:
  /// **'New Topic'**
  String get messengerTopicNew;

  /// No description provided for @messengerTopicNameHint.
  ///
  /// In en, this message translates to:
  /// **'Topic name'**
  String get messengerTopicNameHint;

  /// No description provided for @messengerTopicIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get messengerTopicIcon;

  /// No description provided for @messengerTopicCount.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String messengerTopicCount(int count);

  /// No description provided for @messengerNoTopics.
  ///
  /// In en, this message translates to:
  /// **'No topics'**
  String get messengerNoTopics;

  /// No description provided for @messengerNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get messengerNoMessages;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @messengerThread.
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get messengerThread;

  /// No description provided for @messengerThreadReply.
  ///
  /// In en, this message translates to:
  /// **'reply'**
  String get messengerThreadReply;

  /// No description provided for @messengerThreadReplies.
  ///
  /// In en, this message translates to:
  /// **'replies'**
  String get messengerThreadReplies;

  /// No description provided for @messengerThreadReplyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {word}'**
  String messengerThreadReplyCount(int count, String word);

  /// No description provided for @messengerNoReplies.
  ///
  /// In en, this message translates to:
  /// **'No replies'**
  String get messengerNoReplies;

  /// No description provided for @messengerReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply to thread...'**
  String get messengerReplyHint;

  /// No description provided for @messengerContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get messengerContactName;

  /// No description provided for @messengerOriginalName.
  ///
  /// In en, this message translates to:
  /// **'Original name: {name}'**
  String messengerOriginalName(String name);

  /// No description provided for @messengerDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get messengerDisplayName;

  /// No description provided for @messengerShareContact.
  ///
  /// In en, this message translates to:
  /// **'Contact in Taler ID: {name}'**
  String messengerShareContact(String name);

  /// No description provided for @messengerAutoDelete.
  ///
  /// In en, this message translates to:
  /// **'Auto-delete messages'**
  String get messengerAutoDelete;

  /// No description provided for @messengerAutoDeleteOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get messengerAutoDeleteOff;

  /// No description provided for @messengerAutoDelete7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get messengerAutoDelete7d;

  /// No description provided for @messengerAutoDelete30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get messengerAutoDelete30d;

  /// No description provided for @messengerAutoDelete90d.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get messengerAutoDelete90d;

  /// No description provided for @messengerAutoDeleteDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String messengerAutoDeleteDays(int count);

  /// No description provided for @messengerSettingsHeader.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get messengerSettingsHeader;

  /// No description provided for @messengerAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Admin-only posting'**
  String get messengerAdminOnly;

  /// No description provided for @messengerAdminOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Members can only read'**
  String get messengerAdminOnlyDesc;

  /// No description provided for @messengerTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get messengerTopics;

  /// No description provided for @messengerTopicsDesc.
  ///
  /// In en, this message translates to:
  /// **'Split chat into topics'**
  String get messengerTopicsDesc;

  /// No description provided for @aiTwinSection.
  ///
  /// In en, this message translates to:
  /// **'AI Voice Twin'**
  String get aiTwinSection;

  /// No description provided for @aiTwinEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable AI Twin'**
  String get aiTwinEnabled;

  /// No description provided for @aiTwinEnabledDesc.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t answer, your AI twin takes the call in your voice'**
  String get aiTwinEnabledDesc;

  /// No description provided for @aiTwinTimeout.
  ///
  /// In en, this message translates to:
  /// **'Response timeout'**
  String get aiTwinTimeout;

  /// No description provided for @aiTwinTimeoutValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String aiTwinTimeoutValue(int seconds);

  /// No description provided for @aiTwinPrompt.
  ///
  /// In en, this message translates to:
  /// **'AI instructions'**
  String get aiTwinPrompt;

  /// No description provided for @aiTwinPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How the AI twin should introduce itself and what to talk about'**
  String get aiTwinPromptSubtitle;

  /// No description provided for @aiTwinPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Hi, this is {name}\'s AI voice twin. {name} couldn\'t pick up right now. Tell me who\'s calling and what it\'s about — I\'ll pass it on.'**
  String aiTwinPromptHint(String name);

  /// No description provided for @aiTwinComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Custom voice cloning coming soon. For now the AI speaks with {name}\'s voice.'**
  String aiTwinComingSoon(String name);

  /// No description provided for @aiTwinDefaultName.
  ///
  /// In en, this message translates to:
  /// **'the owner'**
  String get aiTwinDefaultName;

  /// No description provided for @aiTwinPromptReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get aiTwinPromptReset;

  /// No description provided for @callHistoryAiTwinAnswered.
  ///
  /// In en, this message translates to:
  /// **'AI TWIN ANSWERED'**
  String get callHistoryAiTwinAnswered;

  /// No description provided for @callHistoryAiTwinSummary.
  ///
  /// In en, this message translates to:
  /// **'CALL SUMMARY'**
  String get callHistoryAiTwinSummary;

  /// No description provided for @callHistoryAiTwinTranscript.
  ///
  /// In en, this message translates to:
  /// **'TRANSCRIPT'**
  String get callHistoryAiTwinTranscript;

  /// No description provided for @callHistoryAiTwinLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get callHistoryAiTwinLabel;

  /// No description provided for @callHistoryFromCaller.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String callHistoryFromCaller(String name);

  /// No description provided for @aiTwinOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Not answering'**
  String get aiTwinOfferTitle;

  /// No description provided for @aiTwinOfferBody.
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t picking up. Leave a message with their AI voice twin?'**
  String aiTwinOfferBody(String name);

  /// No description provided for @aiTwinOfferBodyUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get aiTwinOfferBodyUser;

  /// No description provided for @aiTwinOfferAccept.
  ///
  /// In en, this message translates to:
  /// **'Yes, leave message'**
  String get aiTwinOfferAccept;

  /// No description provided for @aiTwinOfferKeepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get aiTwinOfferKeepWaiting;

  /// No description provided for @aiTwinLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiTwinLabel;

  /// No description provided for @aiTwinHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI stand-in'**
  String get aiTwinHeroTitle;

  /// No description provided for @aiTwinHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers calls in your voice when you can\'t.'**
  String get aiTwinHeroSubtitle;

  /// No description provided for @aiTwinProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Stand-in'**
  String get aiTwinProfileTitle;

  /// No description provided for @aiTwinProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Answers calls in your voice'**
  String get aiTwinProfileDesc;

  /// No description provided for @aiTwinBadgeOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get aiTwinBadgeOn;

  /// No description provided for @aiAnalystTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analyst'**
  String get aiAnalystTitle;

  /// No description provided for @aiAnalystSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Files, tasks, analysis — Claude'**
  String get aiAnalystSubtitle;

  /// No description provided for @channelsDiscover.
  ///
  /// In en, this message translates to:
  /// **'Find channel'**
  String get channelsDiscover;

  /// No description provided for @channelsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels'**
  String get channelsSearchHint;

  /// No description provided for @channelsSubscribers.
  ///
  /// In en, this message translates to:
  /// **'subscribers'**
  String get channelsSubscribers;

  /// No description provided for @channelsSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get channelsSubscribe;

  /// No description provided for @channelsUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get channelsUnsubscribe;

  /// No description provided for @channelsSubscribedLabel.
  ///
  /// In en, this message translates to:
  /// **'You are subscribed'**
  String get channelsSubscribedLabel;

  /// No description provided for @channelsSettings.
  ///
  /// In en, this message translates to:
  /// **'Channel settings'**
  String get channelsSettings;

  /// No description provided for @channelsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get channelsDelete;

  /// No description provided for @channelsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete channel permanently?'**
  String get channelsDeleteConfirm;

  /// No description provided for @channelsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No channels yet'**
  String get channelsEmpty;

  /// No description provided for @channelsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get channelsOpen;

  /// No description provided for @channelsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get channelsNameLabel;

  /// No description provided for @channelsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get channelsDescriptionLabel;

  /// No description provided for @channelsCannotUnsubscribeOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner cannot unsubscribe. Delete the channel instead.'**
  String get channelsCannotUnsubscribeOwner;

  /// No description provided for @channelsNotFoundRedirect.
  ///
  /// In en, this message translates to:
  /// **'Channel no longer exists'**
  String get channelsNotFoundRedirect;

  /// No description provided for @analystSeamSearches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} search} other{{count} searches}}'**
  String analystSeamSearches(int count);

  /// No description provided for @analystSeamFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} file} other{{count} files}}'**
  String analystSeamFiles(int count);

  /// No description provided for @analystSeamCommands.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} command} other{{count} commands}}'**
  String analystSeamCommands(int count);

  /// No description provided for @analystSeamImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} image} other{{count} images}}'**
  String analystSeamImages(int count);

  /// No description provided for @analystSeamOther.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} step} other{{count} steps}}'**
  String analystSeamOther(int count);

  /// No description provided for @analystSeamDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String analystSeamDurationSeconds(int seconds);

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Messages'**
  String get savedTitle;

  /// No description provided for @savedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your private cloud'**
  String get savedSubtitle;

  /// No description provided for @savedOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Saved Messages'**
  String get savedOpenError;

  /// No description provided for @billingWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get billingWalletTitle;

  /// No description provided for @billingBuyPackage.
  ///
  /// In en, this message translates to:
  /// **'Buy package'**
  String get billingBuyPackage;

  /// No description provided for @billingCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get billingCurrentBalance;

  /// No description provided for @billingPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get billingPackagesTitle;

  /// No description provided for @billingPackagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Packages unavailable'**
  String get billingPackagesUnavailable;

  /// No description provided for @billingRecentOperations.
  ///
  /// In en, this message translates to:
  /// **'Recent operations'**
  String get billingRecentOperations;

  /// No description provided for @billingAllOperations.
  ///
  /// In en, this message translates to:
  /// **'All operations'**
  String get billingAllOperations;

  /// No description provided for @billingNoOperations.
  ///
  /// In en, this message translates to:
  /// **'No operations'**
  String get billingNoOperations;

  /// No description provided for @billingOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get billingOperationsTitle;

  /// No description provided for @billingOperationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No operations yet'**
  String get billingOperationsEmptyTitle;

  /// No description provided for @billingOperationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top-ups and charges for AI features will appear here'**
  String get billingOperationsEmptySubtitle;

  /// No description provided for @billingPricebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature prices'**
  String get billingPricebookTitle;

  /// No description provided for @billingPricebookUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Price list unavailable'**
  String get billingPricebookUnavailable;

  /// No description provided for @billingAiFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'AI features'**
  String get billingAiFeaturesTitle;

  /// No description provided for @billingInsufficientFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get billingInsufficientFundsTitle;

  /// No description provided for @billingInsufficientFundsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top up your balance to use this feature.'**
  String get billingInsufficientFundsSubtitle;

  /// No description provided for @billingRequiredLine.
  ///
  /// In en, this message translates to:
  /// **'Need: {required} μTAL'**
  String billingRequiredLine(String required);

  /// No description provided for @billingAvailableLine.
  ///
  /// In en, this message translates to:
  /// **'Have: {available} μTAL'**
  String billingAvailableLine(String available);

  /// No description provided for @billingTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get billingTopUp;

  /// No description provided for @billingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get billingCancel;

  /// No description provided for @billingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get billingRetry;

  /// No description provided for @billingLowBalanceWarning.
  ///
  /// In en, this message translates to:
  /// **'Balance running low: {balance} μTAL'**
  String billingLowBalanceWarning(String balance);

  /// No description provided for @billingWalletAndBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Balance'**
  String get billingWalletAndBalance;

  /// No description provided for @billingSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Billing & AI'**
  String get billingSectionHeader;

  /// No description provided for @billingFeatureVoiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant'**
  String get billingFeatureVoiceAssistant;

  /// No description provided for @billingFeatureWebSearch.
  ///
  /// In en, this message translates to:
  /// **'Assistant web search'**
  String get billingFeatureWebSearch;

  /// No description provided for @billingFeatureAiTwin.
  ///
  /// In en, this message translates to:
  /// **'Voice twin'**
  String get billingFeatureAiTwin;

  /// No description provided for @billingFeatureAiTwinLong.
  ///
  /// In en, this message translates to:
  /// **'Voice twin (AI Twin)'**
  String get billingFeatureAiTwinLong;

  /// No description provided for @billingFeatureOutboundCall.
  ///
  /// In en, this message translates to:
  /// **'Outbound bot'**
  String get billingFeatureOutboundCall;

  /// No description provided for @billingFeatureOutboundCallLong.
  ///
  /// In en, this message translates to:
  /// **'Outbound calling bot'**
  String get billingFeatureOutboundCallLong;

  /// No description provided for @billingFeatureWhisperTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Call transcription'**
  String get billingFeatureWhisperTranscribe;

  /// No description provided for @billingFeatureMeetingSummary.
  ///
  /// In en, this message translates to:
  /// **'AI call summaries'**
  String get billingFeatureMeetingSummary;

  /// No description provided for @billingConfigureAiTwin.
  ///
  /// In en, this message translates to:
  /// **'Configure AI twin'**
  String get billingConfigureAiTwin;

  /// No description provided for @billingWebSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'(used by the assistant)'**
  String get billingWebSearchSubtitle;

  /// No description provided for @billingPackagePurchased.
  ///
  /// In en, this message translates to:
  /// **'Package purchased: {balance} μTAL'**
  String billingPackagePurchased(String balance);

  /// No description provided for @billingRecommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get billingRecommendedBadge;

  /// No description provided for @billingSessionTerminatedNoFunds.
  ///
  /// In en, this message translates to:
  /// **'Balance ran out — session ended'**
  String get billingSessionTerminatedNoFunds;

  /// No description provided for @billingSessionTerminatedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Assistant session ended'**
  String get billingSessionTerminatedGeneric;

  /// No description provided for @billingBuyForPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy for €{price}'**
  String billingBuyForPrice(String price);

  /// No description provided for @billingTxTypeTopup.
  ///
  /// In en, this message translates to:
  /// **'Top-up'**
  String get billingTxTypeTopup;

  /// No description provided for @billingTxTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get billingTxTypeRefund;

  /// No description provided for @billingTxTypeSpend.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get billingTxTypeSpend;

  /// No description provided for @billingUnitMinute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get billingUnitMinute;

  /// No description provided for @billingUnitRequest.
  ///
  /// In en, this message translates to:
  /// **'request'**
  String get billingUnitRequest;

  /// No description provided for @billingUnitToken.
  ///
  /// In en, this message translates to:
  /// **'token'**
  String get billingUnitToken;

  /// No description provided for @billingUnitTokens1k.
  ///
  /// In en, this message translates to:
  /// **'1K tokens'**
  String get billingUnitTokens1k;

  /// No description provided for @billingUnitCall.
  ///
  /// In en, this message translates to:
  /// **'call'**
  String get billingUnitCall;

  /// No description provided for @groupCallSelectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Select participants'**
  String get groupCallSelectParticipants;

  /// No description provided for @groupCallSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{n}/7'**
  String groupCallSelectedCount(int n);

  /// No description provided for @groupCallSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get groupCallSearch;

  /// No description provided for @groupCallMaxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 7 participants'**
  String get groupCallMaxReached;

  /// No description provided for @groupCallLobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Group • Lobby'**
  String get groupCallLobbyTitle;

  /// No description provided for @groupCallHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host: {name}'**
  String groupCallHostLabel(String name);

  /// No description provided for @groupCallMicHint.
  ///
  /// In en, this message translates to:
  /// **'Mic will activate on connect'**
  String get groupCallMicHint;

  /// No description provided for @groupCallCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groupCallCancel;

  /// No description provided for @groupCallNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No one answered'**
  String get groupCallNoAnswer;

  /// No description provided for @groupCallEndedByHost.
  ///
  /// In en, this message translates to:
  /// **'Call ended by host'**
  String get groupCallEndedByHost;

  /// No description provided for @groupCallAllLeft.
  ///
  /// In en, this message translates to:
  /// **'Everyone left the call'**
  String get groupCallAllLeft;

  /// No description provided for @groupCallEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get groupCallEnded;

  /// No description provided for @groupCallActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Group • {count}'**
  String groupCallActiveTitle(int count);

  /// No description provided for @groupCallConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get groupCallConnectionLost;

  /// No description provided for @groupCallMuteRequested.
  ///
  /// In en, this message translates to:
  /// **'Host asked everyone to mute'**
  String get groupCallMuteRequested;

  /// No description provided for @groupCallUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get groupCallUnmute;

  /// No description provided for @groupCallMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get groupCallMute;

  /// No description provided for @groupCallMuteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute all'**
  String get groupCallMuteAll;

  /// No description provided for @groupCallLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupCallLeave;

  /// No description provided for @groupCallStatusCalling.
  ///
  /// In en, this message translates to:
  /// **'calling…'**
  String get groupCallStatusCalling;

  /// No description provided for @groupCallStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'declined'**
  String get groupCallStatusDeclined;

  /// No description provided for @groupCallStatusTimeout.
  ///
  /// In en, this message translates to:
  /// **'no answer'**
  String get groupCallStatusTimeout;

  /// No description provided for @groupCallStatusLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get groupCallStatusLeft;

  /// No description provided for @groupCallKickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from call'**
  String groupCallKickConfirm(String name);

  /// No description provided for @groupCallCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groupCallCancelAction;

  /// No description provided for @groupCallActiveBanner.
  ///
  /// In en, this message translates to:
  /// **'Active call'**
  String get groupCallActiveBanner;

  /// No description provided for @groupCallBannerSummary.
  ///
  /// In en, this message translates to:
  /// **'Group: {host} + {count}'**
  String groupCallBannerSummary(String host, int count);

  /// No description provided for @groupCallBannerSummaryAlone.
  ///
  /// In en, this message translates to:
  /// **'Group: {host}'**
  String groupCallBannerSummaryAlone(String host);

  /// No description provided for @groupCallCreateError.
  ///
  /// In en, this message translates to:
  /// **'Could not create call'**
  String get groupCallCreateError;

  /// No description provided for @groupCallJoinError.
  ///
  /// In en, this message translates to:
  /// **'Could not join call'**
  String get groupCallJoinError;

  /// No description provided for @groupCallLivekitError.
  ///
  /// In en, this message translates to:
  /// **'LiveKit error'**
  String get groupCallLivekitError;

  /// No description provided for @groupCallDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get groupCallDone;

  /// No description provided for @groupCallNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get groupCallNoResults;

  /// No description provided for @groupCallNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts'**
  String get groupCallNoContacts;

  /// No description provided for @meshGcContactOffline.
  ///
  /// In en, this message translates to:
  /// **'Not on this Wi-Fi'**
  String get meshGcContactOffline;

  /// No description provided for @meshGcOnlineViaMesh.
  ///
  /// In en, this message translates to:
  /// **'Online via mesh'**
  String get meshGcOnlineViaMesh;

  /// No description provided for @meshGcMaxInvitees.
  ///
  /// In en, this message translates to:
  /// **'Group calls support up to 4 invitees (5 people total).'**
  String get meshGcMaxInvitees;

  /// No description provided for @meshGcStart.
  ///
  /// In en, this message translates to:
  /// **'Start group call'**
  String get meshGcStart;

  /// No description provided for @meshGcCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get meshGcCancel;

  /// No description provided for @meshGcStatusCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get meshGcStatusCalling;

  /// No description provided for @meshGcStatusJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get meshGcStatusJoined;

  /// No description provided for @meshGcStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get meshGcStatusDeclined;

  /// No description provided for @meshGcStatusNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get meshGcStatusNoAnswer;

  /// No description provided for @meshGcStatusConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get meshGcStatusConnectionFailed;

  /// No description provided for @meshGcStatusLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get meshGcStatusLeft;

  /// No description provided for @meshGcTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Mesh'**
  String get meshGcTopTitle;

  /// No description provided for @meshGcBusyOneOnOne.
  ///
  /// In en, this message translates to:
  /// **'Finish your current call first.'**
  String get meshGcBusyOneOnOne;

  /// No description provided for @presenceOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get presenceOnline;

  /// No description provided for @presenceLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'last seen just now'**
  String get presenceLastSeenJustNow;

  /// No description provided for @presenceLastSeenMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'last seen {minutes} min ago'**
  String presenceLastSeenMinutesAgo(int minutes);

  /// No description provided for @presenceLastSeenToday.
  ///
  /// In en, this message translates to:
  /// **'last seen today at {time}'**
  String presenceLastSeenToday(String time);

  /// No description provided for @presenceLastSeenYesterday.
  ///
  /// In en, this message translates to:
  /// **'last seen yesterday at {time}'**
  String presenceLastSeenYesterday(String time);

  /// No description provided for @presenceLastSeenOnDate.
  ///
  /// In en, this message translates to:
  /// **'last seen {date}'**
  String presenceLastSeenOnDate(String date);

  /// No description provided for @presenceLastSeenRecently.
  ///
  /// In en, this message translates to:
  /// **'last seen recently'**
  String get presenceLastSeenRecently;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// No description provided for @privacyLastSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'Who sees your last seen time'**
  String get privacyLastSeenLabel;

  /// No description provided for @privacyEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get privacyEveryone;

  /// No description provided for @privacyContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts only'**
  String get privacyContacts;

  /// No description provided for @privacyNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get privacyNobody;

  /// No description provided for @voiceTurnOffTranslation.
  ///
  /// In en, this message translates to:
  /// **'Turn off translator'**
  String get voiceTurnOffTranslation;

  /// Title of the pinned Informer bot tile in messenger
  ///
  /// In en, this message translates to:
  /// **'Informer'**
  String get informerBotTitle;

  /// Subtitle of the Informer bot tile
  ///
  /// In en, this message translates to:
  /// **'Wallet and balance monitoring'**
  String get informerBotSubtitle;

  /// No description provided for @seenByCount.
  ///
  /// In en, this message translates to:
  /// **'Seen by {count}'**
  String seenByCount(int count);

  /// No description provided for @messageInfo.
  ///
  /// In en, this message translates to:
  /// **'Message info'**
  String get messageInfo;

  /// No description provided for @readBy.
  ///
  /// In en, this message translates to:
  /// **'Read by'**
  String get readBy;

  /// No description provided for @notReadYet.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get notReadYet;

  /// No description provided for @reactionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactionsLabel;

  /// No description provided for @noReactions.
  ///
  /// In en, this message translates to:
  /// **'No reactions'**
  String get noReactions;

  /// No description provided for @mailTitle.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get mailTitle;

  /// No description provided for @mailSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get mailSectionHeader;

  /// No description provided for @mailInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No emails yet'**
  String get mailInboxEmpty;

  /// No description provided for @mailNoAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your @talerid.io address'**
  String get mailNoAccountTitle;

  /// No description provided for @mailNoAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Create your personal email address to send and receive mail.'**
  String get mailNoAccountBody;

  /// No description provided for @mailChooseAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose address'**
  String get mailChooseAddress;

  /// No description provided for @mailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get mailAddressHint;

  /// No description provided for @mailAddressTaken.
  ///
  /// In en, this message translates to:
  /// **'This address is already taken'**
  String get mailAddressTaken;

  /// No description provided for @mailAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Only latin letters, digits, dot, dash, underscore (3–64 chars)'**
  String get mailAddressInvalid;

  /// No description provided for @mailAddressReserved.
  ///
  /// In en, this message translates to:
  /// **'This name is reserved'**
  String get mailAddressReserved;

  /// No description provided for @mailAddressAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address is available'**
  String get mailAddressAvailable;

  /// No description provided for @mailCreateAddress.
  ///
  /// In en, this message translates to:
  /// **'Create address'**
  String get mailCreateAddress;

  /// No description provided for @mailSetupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get mailSetupLater;

  /// No description provided for @mailCompose.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get mailCompose;

  /// No description provided for @mailTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get mailTo;

  /// No description provided for @mailSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get mailSubject;

  /// No description provided for @mailBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get mailBody;

  /// No description provided for @mailSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get mailSend;

  /// No description provided for @mailSent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get mailSent;

  /// No description provided for @mailReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get mailReply;

  /// No description provided for @mailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mailDelete;

  /// No description provided for @mailMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get mailMarkUnread;

  /// No description provided for @mailAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get mailAttachments;

  /// No description provided for @mailAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get mailAttachFile;

  /// No description provided for @mailAppPasswords.
  ///
  /// In en, this message translates to:
  /// **'App passwords'**
  String get mailAppPasswords;

  /// No description provided for @mailAppPasswordsHint.
  ///
  /// In en, this message translates to:
  /// **'Use app passwords to connect Apple Mail, Gmail or other IMAP clients.'**
  String get mailAppPasswordsHint;

  /// No description provided for @mailAppPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. iPhone Apple Mail)'**
  String get mailAppPasswordLabel;

  /// No description provided for @mailAppPasswordCreate.
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get mailAppPasswordCreate;

  /// No description provided for @mailAppPasswordShownOnce.
  ///
  /// In en, this message translates to:
  /// **'Save this password now — it is shown only once.'**
  String get mailAppPasswordShownOnce;

  /// No description provided for @mailAppPasswordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get mailAppPasswordCopied;

  /// No description provided for @mailAppPasswordRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get mailAppPasswordRevoke;

  /// No description provided for @mailClientSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client settings'**
  String get mailClientSettingsTitle;

  /// No description provided for @mailSendLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily send limit reached'**
  String get mailSendLimitReached;

  /// No description provided for @mailSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send email'**
  String get mailSendFailed;

  /// No description provided for @mailAttachmentsTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Attachments must be under 10 MB total'**
  String get mailAttachmentsTooLarge;

  /// No description provided for @mailQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get mailQuotaTitle;

  /// No description provided for @mailFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get mailFolders;

  /// No description provided for @mailFolderInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get mailFolderInbox;

  /// No description provided for @mailFolderSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get mailFolderSent;

  /// No description provided for @mailFolderDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get mailFolderDrafts;

  /// No description provided for @mailFolderJunk.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get mailFolderJunk;

  /// No description provided for @mailFolderTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get mailFolderTrash;

  /// No description provided for @mailNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get mailNewFolder;

  /// No description provided for @mailDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder?'**
  String get mailDeleteFolder;

  /// No description provided for @mailMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get mailMoveTo;

  /// No description provided for @mailMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get mailMoved;

  /// No description provided for @mailSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft?'**
  String get mailSaveDraft;

  /// No description provided for @mailDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get mailDraftSaved;

  /// No description provided for @deviceApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm sign-in'**
  String get deviceApprovalTitle;

  /// No description provided for @deviceApprovalWaiting.
  ///
  /// In en, this message translates to:
  /// **'We sent a request to your trusted devices. Open the notification and confirm.'**
  String get deviceApprovalWaiting;

  /// No description provided for @deviceApprovalNoApprovers.
  ///
  /// In en, this message translates to:
  /// **'No device was available to ask. Get a code by email instead.'**
  String get deviceApprovalNoApprovers;

  /// No description provided for @deviceApprovalExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String deviceApprovalExpiresIn(String time);

  /// No description provided for @deviceApprovalRejected.
  ///
  /// In en, this message translates to:
  /// **'The sign-in was rejected from another device.'**
  String get deviceApprovalRejected;

  /// No description provided for @deviceApprovalExpired.
  ///
  /// In en, this message translates to:
  /// **'The confirmation window has expired.'**
  String get deviceApprovalExpired;

  /// No description provided for @deviceApprovalBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign-in'**
  String get deviceApprovalBackToLogin;

  /// No description provided for @deviceApprovalSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Email me a code'**
  String get deviceApprovalSendEmail;

  /// No description provided for @deviceApprovalEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your email'**
  String get deviceApprovalEmailSent;

  /// No description provided for @deviceApprovalEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from the email'**
  String get deviceApprovalEnterCode;

  /// No description provided for @deviceApprovalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in'**
  String get deviceApprovalSheetTitle;

  /// No description provided for @deviceApprovalSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Someone is signing in to your account from this device. Is this you?'**
  String get deviceApprovalSheetBody;

  /// No description provided for @deviceApprovalAllow.
  ///
  /// In en, this message translates to:
  /// **'Yes, allow'**
  String get deviceApprovalAllow;

  /// No description provided for @deviceApprovalDeny.
  ///
  /// In en, this message translates to:
  /// **'This wasn\'t me'**
  String get deviceApprovalDeny;

  /// No description provided for @deviceApprovalApproved.
  ///
  /// In en, this message translates to:
  /// **'Sign-in allowed'**
  String get deviceApprovalApproved;

  /// No description provided for @deviceApprovalDenied.
  ///
  /// In en, this message translates to:
  /// **'Sign-in rejected'**
  String get deviceApprovalDenied;

  /// No description provided for @trustedDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get trustedDevicesTitle;

  /// No description provided for @trustedDevicesToggle.
  ///
  /// In en, this message translates to:
  /// **'Confirm sign-ins from new devices'**
  String get trustedDevicesToggle;

  /// No description provided for @trustedDevicesToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Signing in on an unfamiliar device will need confirmation here, or a code by email'**
  String get trustedDevicesToggleHint;

  /// No description provided for @trustedDevicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trusted devices yet'**
  String get trustedDevicesEmpty;

  /// No description provided for @trustedDevicesThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get trustedDevicesThisDevice;

  /// No description provided for @trustedDevicesLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in: {when}'**
  String trustedDevicesLastSeen(String when);

  /// No description provided for @trustedDevicesRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get trustedDevicesRevoke;

  /// No description provided for @trustedDevicesRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke trust for this device? It will be signed out.'**
  String get trustedDevicesRevokeConfirm;

  /// No description provided for @pinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get pinnedMessage;

  /// No description provided for @pinnedMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedMessagesTitle;

  /// No description provided for @pinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinAction;

  /// No description provided for @unpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinAction;

  /// No description provided for @unpinAllAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin all'**
  String get unpinAllAction;

  /// No description provided for @noPinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'No pinned messages'**
  String get noPinnedMessages;

  /// No description provided for @pinnedCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String pinnedCounter(int current, int total);

  /// No description provided for @messagePinnedBy.
  ///
  /// In en, this message translates to:
  /// **'{actor} pinned a message'**
  String messagePinnedBy(String actor);

  /// No description provided for @unpinAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unpin all messages in this chat?'**
  String get unpinAllConfirm;

  /// No description provided for @pinnedMessageNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Message not loaded — scroll up to find it'**
  String get pinnedMessageNotLoaded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'de',
        'en',
        'es',
        'fa',
        'fr',
        'ha',
        'hi',
        'id',
        'it',
        'ja',
        'ko',
        'mr',
        'pa',
        'pt',
        'ru',
        'sk',
        'ta',
        'te',
        'tr',
        'ur',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'ha':
      return AppLocalizationsHa();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
