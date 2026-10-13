import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(auth: FirebaseAuth.instance);
});

/// Oturum/profil değişikliklerini (link dahil) yayınlar.
final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userChanges();
});

/// Google bağlama işleminin sonucu.
enum GoogleLinkStatus {
  /// Anonim hesap Google hesabına başarıyla bağlandı (uid korunur).
  linked,

  /// Hesap zaten Google ile bağlıydı, işlem yapılmadı.
  alreadyLinked,

  /// Google hesabı başka bir kullanıcıya bağlı; mevcut hesapla oturum açıldı.
  /// Not: Anonim oturumun uid'si değişir.
  signedInExisting,

  /// Google hesabı başka bir kullanıcıya bağlı ve oturum açılmadı.
  conflict,

  /// Kullanıcı pencereyi kapattı / iptal etti.
  cancelled,
}

class GoogleLinkResult {
  const GoogleLinkResult(this.status, {this.message});

  final GoogleLinkStatus status;
  final String? message;
}

class AuthService {
  AuthService({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  static Future<void>? _googleInit;

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= GoogleSignIn.instance.initialize();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> userChanges() => _auth.userChanges();

  bool get isGoogleLinked =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ??
      false;

  /// Mevcut anonim oturumu Google hesabına bağlar (linkWithCredential).
  ///
  /// Böylece uid ve `users/{uid}` altındaki Firestore verileri korunur.
  /// Hata durumunda [FirebaseAuthException] veya genel bir [Exception] fırlatır;
  /// iptal durumu hata değil [GoogleLinkStatus.cancelled] döner.
  Future<GoogleLinkResult> linkAnonymousWithGoogle({
    bool signInIfAlreadyInUse = false,
  }) async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous && isGoogleLinked) {
      return const GoogleLinkResult(GoogleLinkStatus.alreadyLinked);
    }

    final AuthCredential credential;
    try {
      credential = await _getGoogleCredential();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return const GoogleLinkResult(GoogleLinkStatus.cancelled);
      }
      rethrow;
    }

    try {
      if (user == null) {
        await _auth.signInWithCredential(credential);
        return const GoogleLinkResult(GoogleLinkStatus.signedInExisting);
      }
      await user.linkWithCredential(credential);
      await user.reload();
      return const GoogleLinkResult(GoogleLinkStatus.linked);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        if (signInIfAlreadyInUse) {
          // Eski anonim verisi bu hesaba taşınmaz; uid değişir.
          final newCredential = e.credential ?? credential;
          await _auth.signInWithCredential(newCredential);
          return const GoogleLinkResult(GoogleLinkStatus.signedInExisting);
        }
        return const GoogleLinkResult(
          GoogleLinkStatus.conflict,
          message: 'Bu Google hesabı zaten başka bir kullanıcıya bağlı.',
        );
      }
      if (e.code == 'provider-already-linked') {
        return const GoogleLinkResult(GoogleLinkStatus.alreadyLinked);
      }
      rethrow;
    }
  }

  Future<AuthCredential> _getGoogleCredential() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google kimlik doğrulama belirteci alınamadı.',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }
}
