import '../../l10n/app_localizations.dart';

/// Error/success message keys used by BLoCs.
/// UI resolves these to localized strings via [resolveErrorMessage].
class ErrorKeys {
  static const generalError = 'error.general';
  static const timeout = 'error.timeout';
  static const noConnection = 'error.noConnection';
  static const invalidCode = 'error.invalidCode';
  static const failedToLoadProfile = 'error.failedToLoadProfile';
  static const failedToUpdateProfile = 'error.failedToUpdateProfile';
  static const failedToLoadKycStatus = 'error.failedToLoadKycStatus';
  static const failedToLoadKycData = 'error.failedToLoadKycData';
  static const failedToStartKyc = 'error.failedToStartKyc';
  static const failedToLoadOrgs = 'error.failedToLoadOrgs';
  static const failedToLoadOrg = 'error.failedToLoadOrg';
  static const failedToCreateOrg = 'error.failedToCreateOrg';
  static const orgUpdated = 'success.orgUpdated';
  static const failedToUpdateOrg = 'error.failedToUpdateOrg';
  static const failedToInvite = 'error.failedToInvite';
  static const roleChanged = 'success.roleChanged';
  static const failedToChangeRole = 'error.failedToChangeRole';
  static const memberRemoved = 'success.memberRemoved';
  static const failedToRemoveMember = 'error.failedToRemoveMember';
  static const failedToAcceptInvite = 'error.failedToAcceptInvite';
  static const failedToStartKyb = 'error.failedToStartKyb';
  static const failedToLoadSessions = 'error.failedToLoadSessions';
  static const failedToDeleteSession = 'error.failedToDeleteSession';
}

/// Resolves a BLoC error/success key to a localized string.
///
/// If [message] matches a known key, the corresponding l10n string is returned.
/// Parameterized messages (e.g. `inviteSent:<email>`, `verificationError:<code>`)
/// are parsed and resolved with their argument.
/// Unknown messages are passed through as-is (e.g. server error messages).
String resolveErrorMessage(AppLocalizations l10n, String message) {
  // Parameterized messages
  if (message.startsWith('inviteSent:')) {
    return l10n.inviteSent(message.substring('inviteSent:'.length));
  }
  if (message.startsWith('verificationError:')) {
    return l10n.verificationError(message.substring('verificationError:'.length));
  }

  switch (message) {
    case ErrorKeys.generalError:
      return l10n.errorGeneral;
    case ErrorKeys.timeout:
      return l10n.errorTimeout;
    case ErrorKeys.noConnection:
      return l10n.errorNoConnection;
    case ErrorKeys.invalidCode:
      return l10n.authInvalidCode;
    case ErrorKeys.failedToLoadProfile:
      return l10n.failedToLoadProfile;
    case ErrorKeys.failedToUpdateProfile:
      return l10n.failedToUpdateProfile;
    case ErrorKeys.failedToLoadKycStatus:
      return l10n.failedToLoadKyc;
    case ErrorKeys.failedToLoadKycData:
      return l10n.failedToLoadSumsubData;
    case ErrorKeys.failedToStartKyc:
      return l10n.failedToStartKyc;
    case ErrorKeys.failedToLoadOrgs:
      return l10n.failedToLoadOrgs;
    case ErrorKeys.failedToLoadOrg:
      return l10n.failedToLoadOrg;
    case ErrorKeys.failedToCreateOrg:
      return l10n.failedToCreateOrg;
    case ErrorKeys.orgUpdated:
      return l10n.orgUpdated;
    case ErrorKeys.failedToUpdateOrg:
      return l10n.failedToUpdateOrg;
    case ErrorKeys.failedToInvite:
      return l10n.failedToInvite;
    case ErrorKeys.roleChanged:
      return l10n.roleChanged;
    case ErrorKeys.failedToChangeRole:
      return l10n.failedToChangeRole;
    case ErrorKeys.memberRemoved:
      return l10n.memberRemoved;
    case ErrorKeys.failedToRemoveMember:
      return l10n.failedToRemoveMember;
    case ErrorKeys.failedToAcceptInvite:
      return l10n.failedToAcceptInvite;
    case ErrorKeys.failedToStartKyb:
      return l10n.failedToStartKyb;
    case ErrorKeys.failedToLoadSessions:
      return l10n.failedToLoadSessions;
    case ErrorKeys.failedToDeleteSession:
      return l10n.failedToDeleteSession;
    default:
      return message; // Pass through server messages as-is
  }
}
