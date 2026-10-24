import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:kharcha_app/core/error/exceptions.dart';
import 'package:kharcha_app/features/auth/data/models/user_model.dart';

/// The only place that talks to firebase_auth. Throws [AuthException] on failure.
abstract interface class AuthRemoteDataSource {
  Stream<UserModel?> authStateChanges();

  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signInWithGoogle();

  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._auth);

  final FirebaseAuth _auth;
  Future<void>? _googleSignInInitialization;

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : UserModel.fromFirebase(user),
        );
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw const AuthException(code: 'unknown');
      return UserModel.fromFirebase(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final credential = kIsWeb
          ? await _auth.signInWithPopup(GoogleAuthProvider())
          : await _signInWithNativeGoogle();
      final user = credential.user;
      if (user == null) throw const AuthException(code: 'unknown');
      return UserModel.fromFirebase(user);
    } on GoogleSignInException catch (e) {
      throw AuthException(code: e.code.name, message: e.description);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  Future<UserCredential> _signInWithNativeGoogle() async {
    _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
    await _googleSignInInitialization;

    final googleAccount = await GoogleSignIn.instance.authenticate();
    final idToken = googleAccount.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw const AuthException(code: 'unknown');

      final name = displayName?.trim() ?? '';
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      return UserModel.fromFirebase(_auth.currentUser ?? user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }
}
