import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

class Auth0Service {
  static Auth0Service? _instance;
  static Auth0Service get instance => _instance ??= Auth0Service._();

  Auth0Service._();

  // Auth0 Configuration
  static const String domain = 'dev-o8w33hmi08pzb24o.us.auth0.com';
  static const String clientId = 'MMpIensMhdqUcXNoDMauKtuAyMUKxPKV';

  late Auth0 auth0;
  final _storage = const FlutterSecureStorage();

  bool _initialized = false;

  /// Initialize Auth0
  Future<void> initialize() async {
    if (_initialized) return;

    auth0 = Auth0(domain, clientId);
    _initialized = true;
  }

  /// Login with Google via Auth0
  Future<UserProfile?> loginWithGoogle() async {
    try {
      await initialize();

      // For web, use a different approach
      if (kIsWeb) {
        return await _loginWithGoogleWeb();
      }

      final credentials = await auth0.webAuthentication().login(
            parameters: {
              'connection': 'google-oauth2',
            },
          );

      // Store credentials securely
      await _storeCredentials(credentials);

      // Get user profile
      final userProfile = await getUserProfile(credentials.accessToken);
      return userProfile;
    } catch (e) {
      print('❌ Auth0 Login Error: $e');
      return null;
    }
  }

  /// Web-specific login with Google
  Future<UserProfile?> _loginWithGoogleWeb() async {
    try {
      // Get current URL for redirect
      final redirectUri = html.window.location.origin;
      
      // Build Auth0 authorization URL
      final authUrl = Uri.https(
        domain,
        '/authorize',
        {
          'response_type': 'token id_token',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'scope': 'openid profile email',
          'connection': 'google-oauth2',
          'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      print('🔐 Opening Auth0 login: $authUrl');

      // Redirect to Auth0 login page
      html.window.location.href = authUrl.toString();

      // The page will reload after successful authentication
      // We'll handle the callback in _handleWebCallback()
      return null;
    } catch (e) {
      print('❌ Web Login Error: $e');
      return null;
    }
  }

  /// Decode JWT token to extract user profile
  UserProfile? _decodeIdToken(String idToken) {
    try {
      // JWT has 3 parts separated by dots: header.payload.signature
      final parts = idToken.split('.');
      if (parts.length != 3) {
        print('❌ Invalid JWT format');
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed (JWT base64 might not have padding)
      var normalized = base64Url.normalize(payload);
      var decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      print('📋 ID Token Claims: ${claims.keys.join(", ")}');

      // Extract user info from claims
      return UserProfile(
        id: claims['sub'] as String? ?? '',
        name: claims['name'] as String? ?? '',
        email: claims['email'] as String? ?? '',
        picture: claims['picture'] as String? ?? '',
        emailVerified: claims['email_verified'] as bool? ?? false,
      );
    } catch (e) {
      print('❌ Failed to decode ID token: $e');
      return null;
    }
  }

  /// Handle web callback after Auth0 redirect
  Future<UserProfile?> handleWebCallback() async {
    try {
      if (!kIsWeb) return null;

      // Check if we're coming back from Auth0
      final fragment = html.window.location.hash;
      
      print('🔍 Checking for Auth0 callback - Fragment: $fragment');
      
      if (fragment.isEmpty || !fragment.contains('access_token')) {
        print('🔍 No access token in URL');
        return null;
      }

      print('✅ Auth0 callback detected! Processing tokens...');

      // Parse the hash fragment (remove the # at the start)
      final fragmentWithoutHash = fragment.startsWith('#') ? fragment.substring(1) : fragment;
      final params = Uri.splitQueryString(fragmentWithoutHash);
      
      final accessToken = params['access_token'];
      final idToken = params['id_token'];

      print('🔐 Access Token: ${accessToken?.substring(0, 20)}...');
      print('🔐 ID Token: ${idToken?.substring(0, 20)}...');

      if (accessToken == null || idToken == null) {
        print('❌ Missing tokens in callback');
        return null;
      }

      // Store tokens
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'id_token', value: idToken);

      print('💾 Tokens stored successfully');

      // Decode ID token to get user profile (instead of API call)
      final userProfile = _decodeIdToken(idToken);
      
      if (userProfile != null) {
        print('✅ User profile decoded: ${userProfile.name} (${userProfile.email})');
        
        // Store profile
        final profileJson = jsonEncode(userProfile.toJson());
        await _storage.write(key: 'user_profile', value: profileJson);

        // Clean up URL (remove the hash)
        html.window.history.replaceState(null, '', html.window.location.pathname);
        
        print('🎉 Authentication complete!');
      } else {
        print('❌ Failed to decode user profile from ID token');
      }

      return userProfile;
    } catch (e) {
      print('❌ Callback Error: $e');
      return null;
    }
  }

  /// Login with email/password via Auth0
  Future<UserProfile?> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      await initialize();

      final credentials = await auth0.webAuthentication().login(
            parameters: {
              'username': email,
              'password': password,
            },
          );

      await _storeCredentials(credentials);
      final userProfile = await getUserProfile(credentials.accessToken);
      return userProfile;
    } catch (e) {
      print('❌ Auth0 Login Error: $e');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await auth0.webAuthentication().logout();
      await _clearCredentials();
    } catch (e) {
      print('❌ Auth0 Logout Error: $e');
    }
  }

  /// Get user profile from Auth0
  Future<UserProfile?> getUserProfile(String accessToken) async {
    try {
      final response = await auth0
          .api
          .userProfile(accessToken: accessToken);

      return UserProfile(
        id: response.sub,
        email: response.email ?? '',
        name: response.name ?? '',
        picture: response.pictureUrl?.toString() ?? '',
        emailVerified: true, // Auth0 user profile doesn't expose this directly
      );
    } catch (e) {
      print('❌ Get Profile Error: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final credentials = await _getStoredCredentials();
    return credentials != null;
  }

  /// Get stored user profile
  Future<UserProfile?> getStoredUserProfile() async {
    try {
      final profileJson = await _storage.read(key: 'user_profile');
      if (profileJson != null) {
        final Map<String, dynamic> profile = jsonDecode(profileJson);
        return UserProfile(
          id: profile['id'] ?? '',
          email: profile['email'] ?? '',
          name: profile['name'] ?? '',
          picture: profile['picture'] ?? '',
          emailVerified: profile['email_verified'] ?? false,
        );
      }
    } catch (e) {
      print('❌ Get Stored Profile Error: $e');
    }
    return null;
  }

  /// Store credentials securely
  Future<void> _storeCredentials(Credentials credentials) async {
    await _storage.write(key: 'access_token', value: credentials.accessToken);
    await _storage.write(key: 'id_token', value: credentials.idToken);
    await _storage.write(key: 'refresh_token', value: credentials.refreshToken);

    // Store user profile
    final profileJson = jsonEncode({
      'id': credentials.user.sub,
      'email': credentials.user.email ?? '',
      'name': credentials.user.name ?? '',
      'picture': credentials.user.pictureUrl?.toString() ?? '',
      'email_verified': true,
    });
    await _storage.write(key: 'user_profile', value: profileJson);
  }

  /// Get stored credentials
  Future<Map<String, String?>?> _getStoredCredentials() async {
    final accessToken = await _storage.read(key: 'access_token');
    final idToken = await _storage.read(key: 'id_token');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (accessToken != null) {
      return {
        'access_token': accessToken,
        'id_token': idToken,
        'refresh_token': refreshToken,
      };
    }
    return null;
  }

  /// Clear stored credentials
  Future<void> _clearCredentials() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'id_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_profile');
  }

  /// Refresh access token
  Future<String?> refreshAccessToken() async {
    try {
      final credentials = await _getStoredCredentials();
      final refreshToken = credentials?['refresh_token'];

      if (refreshToken != null) {
        final newCredentials = await auth0.api.renewCredentials(
          refreshToken: refreshToken,
        );

        await _storeCredentials(newCredentials);
        return newCredentials.accessToken;
      }
    } catch (e) {
      print('❌ Token Refresh Error: $e');
    }
    return null;
  }
}

/// User Profile Model
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String picture;
  final bool emailVerified;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.picture,
    required this.emailVerified,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'picture': picture,
        'email_verified': emailVerified,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        picture: json['picture'] ?? '',
        emailVerified: json['email_verified'] ?? false,
      );
}
