/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<User?>? _authSub;

  UserProfile _user = const UserProfile(
    id: '',
    displayName: 'Anonymous',
    reportCount: 0,
    trustScore: 1.0,
  );

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  UserProfile get user => _user;
  bool get isAdmin => _user.isAdmin;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  Locale? get locale => _locale;

  /// True when the user has linked email/password or Google credentials.
  bool get isAuthenticated {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;
    return firebaseUser.providerData.any(
      (info) =>
          info.providerId == 'password' || info.providerId == 'google.com',
    );
  }

  /// Returns a key identifying the account type. Use with l10n at the UI layer.
  AccountType get accountType {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return AccountType.anonymous;

    final providers = firebaseUser.providerData
        .map((i) => i.providerId)
        .toSet();
    final hasEmail = providers.contains('password');
    final hasGoogle = providers.contains('google.com');

    if (hasEmail && hasGoogle) return AccountType.googleEmail;
    if (hasGoogle) return AccountType.google;
    if (hasEmail) return AccountType.email;
    return AccountType.anonymous;
  }

  /// Called once at app startup before runApp.
  Future<void> initialize() async {
    // Load saved preferences
    final prefs = await SharedPreferences.getInstance();
    final themePref = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themePref,
      orElse: () => ThemeMode.system,
    );

    final localePref = prefs.getString('locale');
    if (localePref != null) {
      _locale = Locale(localePref);
    }

    // Wait for Firebase Auth to restore the persisted session before
    // deciding whether to create a new anonymous account.
    final restoredUser = await _auth.authStateChanges().first;

    if (restoredUser == null) {
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

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await currentUser.linkWithCredential(credential);
      await currentUser.updateDisplayName(displayName);
    } else {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _auth.currentUser?.updateDisplayName(displayName);
    }

    // Read existing profile to preserve reportCount/trustScore,
    // only create a new one if the user has never been seen before.
    final uid = _auth.currentUser!.uid;
    final existing = await FirestoreService.getUserProfile(uid);
    if (existing != null) {
      _user = UserProfile(
        id: uid,
        displayName: displayName,
        reportCount: existing.reportCount,
        trustScore: existing.trustScore,
        isAdmin: existing.isAdmin,
      );
    } else {
      _user = UserProfile(
        id: uid,
        displayName: displayName,
        reportCount: 0,
        trustScore: 1.0,
      );
    }
    await FirestoreService.setUserProfile(_user);
    notifyListeners();
  }

  /// Sign in with an existing email/password account.
  Future<void> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _loadProfile(result.user!);
  }

  /// Sign in with Google. Links to anonymous account when possible;
  /// falls back to direct sign-in if the credential is already used.
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in failed: ${e.code}',
      );
    }

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Try linking to the current anonymous account
        await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // Credential belongs to another account — sign in directly
          await _auth.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }
    } else {
      // No current user — sign in directly
      await _auth.signInWithCredential(credential);
    }

    // Use Google display name if available
    final signedInUser = _auth.currentUser;
    if (signedInUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Google sign-in completed but no Firebase user found.',
      );
    }

    final displayName =
        signedInUser.displayName ?? googleUser.displayName ?? 'User';
    // Read existing profile to preserve reportCount/trustScore
    final existing = await FirestoreService.getUserProfile(signedInUser.uid);
    if (existing != null) {
      _user = UserProfile(
        id: signedInUser.uid,
        displayName: displayName,
        reportCount: existing.reportCount,
        trustScore: existing.trustScore,
        isAdmin: existing.isAdmin,
      );
    } else {
      _user = UserProfile(
        id: signedInUser.uid,
        displayName: displayName,
        reportCount: 0,
        trustScore: 1.0,
      );
    }
    await FirestoreService.setUserProfile(_user);
    notifyListeners();
  }

  /// Delete the user's account and all associated Firestore data,
  /// then sign in anonymously for continued browsing.
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser!.uid;
    await FirestoreService.deleteUserData(uid);
    await _auth.currentUser!.delete();
    await _auth.signInAnonymously();
    await _loadProfile(_auth.currentUser!);
  }

  /// Sign out and re-create an anonymous session for browsing.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _auth.signInAnonymously();
    await _loadProfile(_auth.currentUser!);
  }

  /// Refresh the user profile from Firestore to pick up the latest report count.
  /// Called after submitting reports (the count is incremented atomically
  /// inside the same Firestore batch as the report write).
  Future<void> refreshProfile() async {
    final existing = await FirestoreService.getUserProfile(_user.id);
    if (existing != null) {
      _user = existing;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('themeMode', mode.name);
    });
  }

  /// Set locale. Pass null for system default.
  void setLocale(Locale? locale) {
    _locale = locale;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      if (locale == null) {
        prefs.remove('locale');
      } else {
        prefs.setString('locale', locale.languageCode);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

enum AccountType { anonymous, email, google, googleEmail }
