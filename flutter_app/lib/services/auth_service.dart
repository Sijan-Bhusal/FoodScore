import 'package:google_sign_in/google_sign_in.dart';

import '../data/auth_data_source.dart';

const _googleClientId = '345865041596-4fu1h7sqh8cg8nr1or8ogtjjoorv235e.apps.googleusercontent.com';

class UserProfile {
  final String userId;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
  };
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

class AuthService {
  AuthService({AuthDataSource? dataSource})
    : _dataSource = dataSource ?? AuthDataSource();

  final AuthDataSource _dataSource;
  final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: _googleClientId);

  Future<AuthResult> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthException('Google sign-in was cancelled');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw AuthException('Failed to get Google ID token');
    }

    final tokenData = await _dataSource.googleLogin(idToken);

    return AuthResult(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
      user: UserProfile.fromJson(tokenData['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    final tokenData = await _dataSource.emailLogin(email, password);

    return AuthResult(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
      user: UserProfile.fromJson(tokenData['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthResult> register(String username, String email, String password) async {
    final tokenData = await _dataSource.register(username, email, password);

    return AuthResult(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
      user: UserProfile.fromJson(tokenData['user'] as Map<String, dynamic>),
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
