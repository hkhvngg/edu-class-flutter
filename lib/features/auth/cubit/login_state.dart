part of 'login_cubit.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String role;

  const LoginSuccess({required this.role});

  @override
  List<Object?> get props => [role];
}

class GoogleProfileRequired extends LoginState {
  final String email;
  final String suggestedName;
  final String? photoUrl;

  const GoogleProfileRequired({
    required this.email,
    required this.suggestedName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [email, suggestedName, photoUrl];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
