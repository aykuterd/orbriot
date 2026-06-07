import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Kimlik doğrulama servisi.
/// İlk açılışta anonim giriş, opsiyonel kullanıcı adı + şifre ile hesap bağlama.
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rxn<User> currentUser = Rxn<User>();
  final RxBool isLinked = false.obs;

  String? get uid => _auth.currentUser?.uid;

  Future<AuthService> init() async {
    // Auth state değişikliklerini dinle
    _auth.authStateChanges().listen((user) {
      currentUser.value = user;
      _updateLinkedStatus();
    });

    // Kullanıcı yoksa anonim giriş yap
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    _updateLinkedStatus();
    return this;
  }

  void _updateLinkedStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      isLinked.value = false;
      return;
    }
    // Email/password provider bağlı mı?
    isLinked.value = user.providerData
        .any((info) => info.providerId == 'password');
  }

  /// Anonim hesabı kullanıcı adı + şifre ile sağlamlaştır.
  /// Dahili olarak `username@orbriot.game` formatında email oluşturur.
  /// Başarılıysa `true`, hata varsa hata mesajı döner.
  Future<({bool success, String? error})> linkWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final email = _buildEmail(username);
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser!.linkWithCredential(credential);
      _updateLinkedStatus();
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _mapAuthError(e.code));
    }
  }

  /// Mevcut hesaba giriş yap (cihaz değiştirme durumunda).
  Future<({bool success, String? error})> signInWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final email = _buildEmail(username);
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _updateLinkedStatus();
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _mapAuthError(e.code));
    }
  }

  /// Şifre değiştir.
  Future<({bool success, String? error})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser!;
      final email = user.email!;
      // Önce mevcut şifreyle yeniden doğrula
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _mapAuthError(e.code));
    }
  }

  /// Çıkış yap ve yeni anonim hesap oluştur.
  Future<void> signOut() async {
    await _auth.signOut();
    await _auth.signInAnonymously();
  }

  String _buildEmail(String username) =>
      '${username.toLowerCase().trim()}@orbriot.game';

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu kullanıcı adı zaten alınmış';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Kullanıcı adı veya şifre hatalı';
      case 'user-not-found':
        return 'Hesap bulunamadı';
      case 'credential-already-in-use':
        return 'Bu kullanıcı adı başka bir hesaba bağlı';
      case 'requires-recent-login':
        return 'Lütfen tekrar giriş yap';
      default:
        return 'Bir hata oluştu ($code)';
    }
  }
}
