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

      await _completeLogin(userCredential, normalizedEmail: normalizedEmail);
    } on TimeoutException {
      emit(
        const LoginFailure(
          message:
              'Quá thời gian kết nối! Vui lòng kiểm tra mạng hoặc cấu hình Firebase.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("DEBUG: Lỗi Firebase Auth: ${e.code} - ${e.message}");
      emit(LoginFailure(message: _friendlyAuthError(e)));
    } catch (e) {
      print("DEBUG: Lỗi không xác định: $e");
      emit(LoginFailure(message: 'Đã có lỗi xảy ra: $e'));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(LoginLoading());

    try {
      final userCredential = await _authService.signInWithGoogle().timeout(
        const Duration(seconds: 30),
      );

      if (userCredential == null) {
        emit(LoginInitial());
        return;
      }

      await _completeLogin(
        userCredential,
        normalizedEmail: userCredential.user?.email?.toLowerCase() ?? '',
        enforceEmailVerification: false,
        requireGoogleProfileIfMissing: true,
      );
    } on TimeoutException {
      emit(
        const LoginFailure(
          message:
              'Quá thời gian đăng nhập Google! Vui lòng kiểm tra mạng hoặc thử lại.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("DEBUG: Lỗi Google Auth: ${e.code} - ${e.message}");
      emit(LoginFailure(message: _friendlyGoogleAuthError(e)));
    } catch (e) {
      print("DEBUG: Lỗi Google không xác định: $e");
      emit(LoginFailure(message: 'Không thể đăng nhập bằng Google: $e'));
    }
  }

  Future<void> _completeLogin(
    UserCredential userCredential, {
    required String normalizedEmail,
    bool enforceEmailVerification = true,
    bool requireGoogleProfileIfMissing = false,
  }) async {
    final user = userCredential.user;
    if (user == null) {
      emit(const LoginFailure(message: 'Không tìm thấy thông tin tài khoản.'));
      return;
    }

    print("DEBUG: Đang lấy role từ Firestore...");
    UserModel? userModel = await _databaseService
        .getUser(user.uid)
        .timeout(const Duration(seconds: 10));

    final systemSettings = await _databaseService.getSystemSettings().timeout(
      const Duration(seconds: 10),
    );

    if (userModel == null && requireGoogleProfileIfMissing) {
      emit(
        GoogleProfileRequired(
          email: user.email ?? normalizedEmail,
          suggestedName: user.displayName ?? '',
          photoUrl: user.photoURL,
        ),
      );
      return;
    }

    if (userModel == null) {
      emit(
        const LoginFailure(
          message:
              'Tài khoản Auth tồn tại nhưng không có dữ liệu trong Firestore!',
        ),
      );
      return;
    }

    await _finishLogin(
      user: user,
      userModel: userModel,
      systemSettings: systemSettings,
      normalizedEmail: normalizedEmail,
      enforceEmailVerification: enforceEmailVerification,
    );
  }

  Future<void> completeGoogleRegistration({
    required String fullName,
    required String role,
  }) async {
    final user = _authService.currentUser;
    final normalizedName = fullName.trim();

    if (user == null) {
      emit(const LoginFailure(message: 'Phiên đăng nhập Google đã hết hạn.'));
      return;
    }

    if (normalizedName.isEmpty) {
      emit(const LoginFailure(message: 'Vui lòng nhập họ tên đầy đủ.'));
      return;
    }

    if (role != 'student' && role != 'teacher') {
      emit(const LoginFailure(message: 'Vui lòng chọn vai trò hợp lệ.'));
      return;
    }

    emit(LoginLoading());

    try {
      final systemSettings = await _databaseService.getSystemSettings().timeout(
        const Duration(seconds: 10),
      );

      if (role == 'student' &&
          systemSettings['allowStudentRegistration'] == false) {
        await _authService.signOut();
        emit(
          const LoginFailure(
            message: 'Hệ thống hiện không cho phép đăng ký học viên mới.',
          ),
        );
        return;
      }

      if (role == 'teacher' &&
          systemSettings['allowTeacherRegistration'] == false) {
        await _authService.signOut();
        emit(
          const LoginFailure(
            message: 'Hệ thống hiện không cho phép đăng ký giảng viên mới.',
          ),
        );
        return;
      }

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        fullName: normalizedName,
        role: role,
        profileImageUrl: user.photoURL,
        createdAt: DateTime.now(),
      );

      await _databaseService.saveUser(userModel);
      await _finishLogin(
        user: user,
        userModel: userModel,
        systemSettings: systemSettings,
        normalizedEmail: user.email?.toLowerCase() ?? '',
        enforceEmailVerification: false,
      );
    } on TimeoutException {
      emit(
        const LoginFailure(
          message:
              'Quá thời gian lưu hồ sơ Google! Vui lòng kiểm tra mạng hoặc thử lại.',
        ),
      );
    } catch (e) {
      print("DEBUG: Lỗi hoàn tất hồ sơ Google: $e");
      emit(LoginFailure(message: 'Không thể lưu hồ sơ Google: $e'));
    }
  }

  Future<void> cancelGoogleRegistration() async {
    await _authService.signOut();
    emit(LoginInitial());
  }

  Future<void> _finishLogin({
    required User user,
    required UserModel userModel,
    required Map<String, dynamic> systemSettings,
    required String normalizedEmail,
    required bool enforceEmailVerification,
  }) async {
    print("DEBUG: Role tìm thấy: ${userModel.role}");
    final maintenanceMode = systemSettings['maintenanceMode'] == true;
    final requireEmailVerification =
        enforceEmailVerification &&
        systemSettings['requireEmailVerification'] != false;
    final isAdmin =
        userModel.role == 'admin' || normalizedEmail == 'admin@educlass.com';

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
        !_canSkipEmailVerification(user)) {
      await _authService.signOut();
      emit(
        const LoginFailure(
          message:
              'Vui lòng xác thực email của bạn qua đường link đã được gửi tới hộp thư trước khi đăng nhập!',
        ),
      );
      return;
    }

    final notiService = NotificationService();
    await notiService.init();
    await notiService.saveTokenToDatabase();

    emit(LoginSuccess(role: userModel.role));
  }

  bool _canSkipEmailVerification(User user) {
    if (user.emailVerified) return true;

    final creationTime = user.metadata.creationTime;
    return creationTime != null && creationTime.isBefore(DateTime(2026, 5, 22));
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Tài khoản hoặc mật khẩu không đúng.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'user-disabled':
        return 'Tài khoản này đã bị khóa. Vui lòng liên hệ quản trị viên.';
      case 'too-many-requests':
        return 'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng chờ một lúc rồi thử lại.';
      case 'network-request-failed':
        return 'Không thể kết nối mạng. Vui lòng kiểm tra internet rồi thử lại.';
      case 'email-not-verified':
        return 'Vui lòng xác thực email trước khi đăng nhập.';
      default:
        return e.message ?? 'Không thể đăng nhập lúc này. Vui lòng thử lại.';
    }
  }

  String _friendlyGoogleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Email này đã được đăng ký bằng phương thức khác. Vui lòng đăng nhập bằng email và mật khẩu.';
      case 'network-request-failed':
        return 'Không thể kết nối mạng. Vui lòng kiểm tra internet rồi thử lại.';
      case 'popup-closed-by-user':
      case 'canceled':
        return 'Bạn đã hủy đăng nhập Google.';
      case 'missing-google-id-token':
      case 'google-sign-in-not-supported':
        return e.message ?? 'Cấu hình đăng nhập Google chưa hoàn tất.';
      default:
        return e.message ?? 'Không thể đăng nhập bằng Google lúc này.';
    }
  }
}
