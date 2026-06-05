import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<void>? _googleInitFuture;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(
    String email,
    String password, {
    bool requireEmailVerification = true,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Bỏ qua kiểm tra xác minh email cho tài khoản admin test
      if (requireEmailVerification && email.trim() != 'admin@educlass.com') {
        final user = credential.user;
        if (user != null && !user.emailVerified) {
          // Bỏ qua kiểm tra cho các tài khoản "cũ" (tạo trước khi có tính năng này)
          // Giả sử tính năng này được thêm vào ngày 22/05/2026
          final creationTime = user.metadata.creationTime;
          final isLegacyAccount =
              creationTime != null &&
              creationTime.isBefore(DateTime(2026, 5, 22));

          if (!isLegacyAccount) {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'email-not-verified',
              message:
                  'Vui lòng xác thực email của bạn qua đường link đã được gửi tới hộp thư trước khi đăng nhập!',
            );
          }
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      print("AUTH_ERROR_SIGNIN: ${e.code}");
      rethrow;
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print("AUTH_ERROR_SIGNUP: ${e.code}");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _googleInitFuture ??= GoogleSignIn.instance.initialize();
      await _googleInitFuture;

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw FirebaseAuthException(
          code: 'google-sign-in-not-supported',
          message: 'Thiết bị hiện tại không hỗ trợ đăng nhập bằng Google.',
        );
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Không nhận được Google ID token. Vui lòng kiểm tra cấu hình Firebase Google Sign-In.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw FirebaseAuthException(
        code: e.code.name,
        message: e.description ?? 'Không thể đăng nhập bằng Google.',
      );
    } on FirebaseAuthException catch (e) {
      print("AUTH_ERROR_GOOGLE_SIGNIN: ${e.code}");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _googleInitFuture ??= GoogleSignIn.instance.initialize();
      await _googleInitFuture;
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
