import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/notification_service.dart';
import '../models/user_model.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService _authService;
  final DatabaseService _databaseService;

  LoginCubit({
    required AuthService authService,
    required DatabaseService databaseService,
  }) : _authService = authService,
       _databaseService = databaseService,
       super(LoginInitial());

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      emit(const LoginFailure(message: 'Vui lòng nhập Email và Mật khẩu!'));
      return;
    }

    emit(LoginLoading());

    try {
      print("DEBUG: Bắt đầu đăng nhập cho $email...");
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Đăng nhập với Timeout 15 giây
      UserCredential? userCredential;

      // Auto-create admin account if it's admin credentials
      if (normalizedEmail == 'admin@educlass.com' && password == 'admin123') {
        try {
          userCredential = await _authService
              .signIn(email, password, requireEmailVerification: false)
              .timeout(const Duration(seconds: 15));
        } catch (e) {
          print(
            "DEBUG: Admin account not found or invalid, creating new one...",
          );
          userCredential = await _authService
              .signUp(email, password)
              .timeout(const Duration(seconds: 15));
          await _databaseService.saveUser(
            UserModel(
              uid: userCredential.user!.uid,
              email: email,
              fullName: 'Administrator',
              role: 'admin',
              createdAt: DateTime.now(),
            ),
          );
        }
      } else {
        userCredential = await _authService
            .signIn(email, password, requireEmailVerification: false)
            .timeout(const Duration(seconds: 15));
      }

      print("DEBUG: Auth thành công, UID: ${userCredential.user!.uid}");

      // 2. Lấy role từ Firestore với Timeout 10 giây
      print("DEBUG: Đang lấy role từ Firestore...");
      UserModel? userModel = await _databaseService
          .getUser(userCredential.user!.uid)
          .timeout(const Duration(seconds: 10));

      if (userModel != null) {
        print("DEBUG: Role tìm thấy: ${userModel.role}");
        final systemSettings = await _databaseService
            .getSystemSettings()
            .timeout(const Duration(seconds: 10));
        final maintenanceMode = systemSettings['maintenanceMode'] == true;
        final requireEmailVerification =
            systemSettings['requireEmailVerification'] != false;
        final isAdmin =
            userModel.role == 'admin' ||
            normalizedEmail == 'admin@educlass.com';

        if (maintenanceMode && !isAdmin) {
          await _authService.signOut();
          emit(
            const LoginFailure(
              message:
                  'Hệ thống đang bảo trì. Vui lòng quay lại sau hoặc liên hệ admin.',
            ),
          );
          return;
        }

        if (requireEmailVerification &&
            !isAdmin &&
            !_canSkipEmailVerification(userCredential.user!)) {
          await _authService.signOut();
          emit(
            const LoginFailure(
              message:
                  'Vui lòng xác thực email của bạn qua đường link đã được gửi tới hộp thư trước khi đăng nhập!',
            ),
          );
          return;
        }

        // Khởi tạo và lưu FCM Token
        final notiService = NotificationService();
        await notiService.init();
        await notiService.saveTokenToDatabase();

        emit(LoginSuccess(role: userModel.role));
      } else {
        emit(
          const LoginFailure(
            message:
                'Tài khoản Auth tồn tại nhưng không có dữ liệu trong Firestore!',
          ),
        );
      }
    } on TimeoutException {
      emit(
        const LoginFailure(
          message:
              'Quá thời gian kết nối! Vui lòng kiểm tra mạng hoặc cấu hình Firebase.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("DEBUG: Lỗi Firebase Auth: ${e.code} - ${e.message}");
      emit(LoginFailure(message: 'Lỗi đăng nhập: ${e.message}'));
    } catch (e) {
      print("DEBUG: Lỗi không xác định: $e");
      emit(LoginFailure(message: 'Đã có lỗi xảy ra: $e'));
    }
  }

  bool _canSkipEmailVerification(User user) {
    if (user.emailVerified) return true;

    final creationTime = user.metadata.creationTime;
    return creationTime != null && creationTime.isBefore(DateTime(2026, 5, 22));
  }
}
