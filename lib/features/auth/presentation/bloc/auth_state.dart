import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String accessToken;
  AuthSuccess(this.accessToken);
  @override
  List<Object?> get props => [accessToken];
}

class AuthRequires2FA extends AuthState {
  final String email;
  final String tempToken;
  AuthRequires2FA({required this.email, required this.tempToken});
  @override
  List<Object?> get props => [email, tempToken];
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthLoggedOut extends AuthState {}

class PasswordResetCodeSent extends AuthState {
  final String email;
  PasswordResetCodeSent({required this.email});
  @override
  List<Object?> get props => [email];
}

class PasswordResetCodeVerified extends AuthState {
  final String email;
  final String resetToken;
  PasswordResetCodeVerified({required this.email, required this.resetToken});
  @override
  List<Object?> get props => [email, resetToken];
}

class PasswordResetSuccess extends AuthState {}

class EmailVerifyCodeSent extends AuthState {
  /// Set when the backend reports the address was already verified — the UI
  /// should treat that as success and not show the code-entry step.
  final bool alreadyVerified;
  EmailVerifyCodeSent({this.alreadyVerified = false});
  @override
  List<Object?> get props => [alreadyVerified];
}

class EmailVerifySuccess extends AuthState {}
