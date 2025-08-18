import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthUpdateUserEvent>(_onUpdateUser);
  }

  Future<void> _onCheckStatus(AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      await _authService.initializeToken();
      final user = await _authService.getCurrentUser();
      
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await _authService.login(event.email, event.password);
      
      if (result.isSuccess && result.user != null) {
        emit(AuthAuthenticated(result.user!));
      } else {
        emit(AuthError(result.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(AuthRegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final result = await _authService.register(event.userData);
      
      if (result.isSuccess && result.user != null) {
        emit(AuthAuthenticated(result.user!));
      } else {
        emit(AuthError(result.error ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(AuthUpdateUserEvent event, Emitter<AuthState> emit) async {
    if (state is! AuthAuthenticated) return;
    
    final currentState = state as AuthAuthenticated;
    emit(AuthLoading());
    
    try {
      final updatedUser = await _authService.updateProfile(event.userData);
      
      if (updatedUser != null) {
        emit(AuthAuthenticated(updatedUser));
      } else {
        emit(AuthError('Failed to update profile'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}