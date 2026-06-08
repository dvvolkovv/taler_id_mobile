import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? username;
  RegisterSubmitted({required this.email, required this.password, this.firstName, this.lastName, this.username});
  @override
  List<Object?> get props => [email, password, firstName, lastName, username];
}

class TwoFASubmitted extends AuthEvent {
  final String email;
  final String code;
  final String tempToken;
  TwoFASubmitted({required this.email, required this.code, required this.tempToken});
  @override
  List<Object?> get props => [email, code, tempToken];
}

class LogoutRequested extends AuthEvent {}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  ForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class ForgotPasswordCodeVerified extends AuthEvent {
  final String email;
  final String code;
  ForgotPasswordCodeVerified({required this.email, required this.code});
  @override
  List<Object?> get props => [email, code];
}

class ForgotPasswordNewPassword extends AuthEvent {
  final String resetToken;
  final String newPassword;
  ForgotPasswordNewPassword({required this.resetToken, required this.newPassword});
  @override
  List<Object?> get props => [resetToken, newPassword];
}

class EmailVerifySendRequested extends AuthEvent {}

class EmailVerifySubmitted extends AuthEvent {
  final String code;
  EmailVerifySubmitted({required this.code});
  @override
  List<Object?> get props => [code];
}
