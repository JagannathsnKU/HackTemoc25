import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth0_service.dart';

// Events
abstract class AuthEvent {}

class LoginWithGoogle extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class Logout extends AuthEvent {}

// States
enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userProfile,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? userProfile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Legacy support
  String? get userName => userProfile?.name;
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Auth0Service _auth0Service = Auth0Service.instance;

  AuthBloc() : super(AuthState()) {
    on<LoginWithGoogle>(_onLoginWithGoogle);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<Logout>(_onLogout);

    // Check auth status on startup
    add(CheckAuthStatus());
  }

  void _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      print('🔍 Checking auth status...');
      
      // First check if we're handling a web callback
      final callbackProfile = await _auth0Service.handleWebCallback();
      if (callbackProfile != null) {
        print('✅ Authenticated via callback: ${callbackProfile.email}');
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: callbackProfile,
        ));
        return;
      }

      print('🔍 No callback detected, checking stored credentials...');

      // Check stored auth status
      final isAuth = await _auth0Service.isAuthenticated();
      if (isAuth) {
        print('✅ Found stored authentication');
        final profile = await _auth0Service.getStoredUserProfile();
        if (profile != null) {
          print('✅ Found stored profile: ${profile.email}');
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            userProfile: profile,
          ));
          return;
        }
      }
      
      print('❌ No stored credentials found');
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } catch (e) {
      print('❌ Auth check error: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onLoginWithGoogle(LoginWithGoogle event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final profile = await _auth0Service.loginWithGoogle();

      if (profile != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: profile,
        ));
      } else {
        // Show error if Auth0 fails
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Auth0 authentication failed. Please check your configuration.',
        ));
      }
    } catch (e) {
      print('❌ Login Error: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Authentication failed: ${e.toString()}',
      ));
    }
  }

  void _onLogout(Logout event, Emitter<AuthState> emit) async {
    await _auth0Service.logout();
    emit(AuthState(status: AuthStatus.unauthenticated));
  }
}
