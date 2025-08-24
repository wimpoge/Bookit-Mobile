part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final Map<String, dynamic> userData;

  const AuthRegisterEvent({required this.userData});

  @override
  List<Object> get props => [userData];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthUpdateUserEvent extends AuthEvent {
  final Map<String, dynamic> userData;

  const AuthUpdateUserEvent({required this.userData});

  @override
  List<Object> get props => [userData];
}

class AuthGoogleLoginEvent extends AuthEvent {}