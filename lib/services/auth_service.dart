import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy User hiện tại
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      // Đảm bảo trim email để tránh lỗi khoảng trắng thừa
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // Bỏ qua kiểm tra xác minh email cho tài khoản admin test
      if (email.trim() != 'admin@educlass.com') {
        final user = credential.user;
        if (user != null && !user.emailVerified) {
          // Bỏ qua kiểm tra cho các tài khoản "cũ" (tạo trước khi có tính năng này)
          // Giả sử tính năng này được thêm vào ngày 22/05/2026
          final creationTime = user.metadata.creationTime;
          final isLegacyAccount = creationTime != null && creationTime.isBefore(DateTime(2026, 5, 22));

          if (!isLegacyAccount) {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'email-not-verified',
              message: 'Vui lòng xác thực email của bạn qua đường link đã được gửi tới hộp thư trước khi đăng nhập!',
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

  // Đăng ký
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

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
