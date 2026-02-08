import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  StreamSubscription<User?>? _authSub;

  UserProfile _user = const UserProfile(
    id: '',
    displayName: 'Anonymous',
    reportCount: 0,
    trustScore: 1.0,
  );

  bool _isDarkMode = false;

  UserProfile get user => _user;
  bool get isDarkMode => _isDarkMode;

  /// True when the user has linked email/password or Google credentials.
  bool get isAuthenticated {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;
    return firebaseUser.providerData.any(
      (info) => info.providerId == 'password' || info.providerId == 'google.com',
    );
  }

  /// Human-readable label for the account type shown in settings.
  String get accountTypeLabel {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return 'Anonymous (browsing only)';

    final providers = firebaseUser.providerData.map((i) => i.providerId).toSet();
    final hasEmail = providers.contains('password');
    final hasGoogle = providers.contains('google.com');

    if (hasEmail && hasGoogle) return 'Google + Email account';
    if (hasGoogle) return 'Google account';
    if (hasEmail) return 'Email account';
    return 'Anonymous (browsing only)';
  }

  /// Called once at app startup before runApp.
  Future<void> initialize() async {
    // Sign in anonymously if no user exists
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    // Load or create profile for the current user
    await _loadProfile(_auth.currentUser!);

    // Listen for future auth state changes
    _authSub = _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadProfile(firebaseUser);
      }
    });
  }

  Future<void> _loadProfile(User firebaseUser) async {
    final existing = await FirestoreService.getUserProfile(firebaseUser.uid);
    if (existing != null) {
      _user = existing;
    } else {
      _user = UserProfile(
        id: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'Anonymous',
        reportCount: 0,
        trustScore: 1.0,
      );
      await FirestoreService.setUserProfile(_user);
    }
    notifyListeners();
  }

  /// Register by linking email/password credentials to the anonymous account.
  /// This preserves the UID so any data already associated with the user persists.
  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await _auth.currentUser!.linkWithCredential(credential);
    await _auth.currentUser!.updateDisplayName(displayName);

    _user = UserProfile(
      id: _user.id,
      displayName: displayName,
      reportCount: _user.reportCount,
      trustScore: _user.trustScore,
    );
    await FirestoreService.setUserProfile(_user);
    notifyListeners();
  }

  /// Sign in with an existing email/password account.
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _loadProfile(_auth.currentUser!);
  }

  /// Sign in with Google. Links to anonymous account when possible;
  /// falls back to direct sign-in if the credential is already used.
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      // Try linking to the current anonymous account
      await _auth.currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Credential belongs to another account — sign in directly
        await _auth.signInWithCredential(credential);
      } else {
        rethrow;
      }
    }

    // Use Google display name if available
    final displayName = _auth.currentUser!.displayName ?? googleUser.displayName ?? 'User';
    _user = UserProfile(
      id: _auth.currentUser!.uid,
      displayName: displayName,
      reportCount: _user.reportCount,
      trustScore: _user.trustScore,
    );
    await FirestoreService.setUserProfile(_user);
    notifyListeners();
  }

  /// Sign out and re-create an anonymous session for browsing.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _auth.signInAnonymously();
    await _loadProfile(_auth.currentUser!);
  }

  /// Increment the report count and persist to Firestore.
  Future<void> incrementReportCount() async {
    await FirestoreService.incrementUserReportCount(_user.id);
    _user = UserProfile(
      id: _user.id,
      displayName: _user.displayName,
      reportCount: _user.reportCount + 1,
      trustScore: _user.trustScore,
    );
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
