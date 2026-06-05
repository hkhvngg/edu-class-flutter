import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String selectedRole = 'student';
  bool agreeToTerms = false;
  bool isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _allowStudentRegistration = true;
  bool _allowTeacherRegistration = true;
  bool _requireEmailVerification = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrationSettings();
  }

  Future<void> _loadRegistrationSettings() async {
    try {
      final settings = await _databaseService.getSystemSettings();
      if (!mounted) return;
      setState(() {
        _allowStudentRegistration =
            settings['allowStudentRegistration'] != false;
        _allowTeacherRegistration =
            settings['allowTeacherRegistration'] != false;
        _requireEmailVerification =
            settings['requireEmailVerification'] != false;

        if (!_allowStudentRegistration &&
            selectedRole == 'student' &&
            _allowTeacherRegistration) {
          selectedRole = 'teacher';
        }
      });
    } catch (_) {}
  }

  bool _isRoleAllowed(String role) {
    if (role == 'teacher') return _allowTeacherRegistration;
    return _allowStudentRegistration;
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin!');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp!');
      return;
    }
    if (!agreeToTerms) {
      _showSnackBar('Bạn phải đồng ý với Điều khoản!');
      return;
    }
    if (!_isRoleAllowed(selectedRole)) {
      _showSnackBar('Admin đang tạm khoá đăng ký vai trò này!');
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 20));

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());

        // Gửi email xác thực (Firebase Link) nếu admin đang bật yêu cầu này.
        if (_requireEmailVerification) {
          await user.sendEmailVerification();
        }

        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email!,
          fullName: _nameController.text.trim(),
          role: selectedRole,
          createdAt: DateTime.now(),
        );

        await _databaseService.saveUser(newUser);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    _requireEmailVerification
                        ? Icons.mark_email_unread_outlined
                        : Icons.check_circle_outline,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _requireEmailVerification
                        ? 'Xác thực Email'
                        : 'Đăng ký thành công',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                _requireEmailVerification
                    ? 'Đăng ký thành công! Vui lòng kiểm tra hộp thư email (hoặc mục Thư rác/Spam) và nhấp vào đường link đính kèm để kích hoạt tài khoản của bạn.'
                    : 'Đăng ký thành công! Bạn có thể quay lại màn hình đăng nhập ngay.',
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Đóng Dialog
                    Navigator.pop(context); // Về màn login
                  },
                  child: const Text('Về trang Đăng nhập'),
                ),
              ],
            ),
          );
        }
      }
    } on TimeoutException {
      _showSnackBar('Quá thời gian kết nối.');
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Lỗi xác thực: ${e.message}');
    } catch (e) {
      _showSnackBar('Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Thông báo',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.1),
              Colors.white,
              primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              children: [
                _buildHeader(primaryColor),
                const SizedBox(height: 40),
                _buildRegisterCard(primaryColor),
                const SizedBox(height: 32),
                _buildFooter(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'EduClass',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Tạo tài khoản người dùng',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRegisterCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng ký',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vai trò',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleButton('Học viên', 'student'),
                const SizedBox(width: 8),
                _buildRoleButton('Giảng viên', 'teacher'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('Họ và tên'),
          _buildTextField(_nameController, 'Nguyễn Văn A'),
          const SizedBox(height: 20),
          _buildLabel('Email'),
          _buildTextField(_emailController, 'your.email@edu.vn'),
          const SizedBox(height: 20),
          _buildLabel('Mật khẩu'),
          _buildTextField(_passwordController, '••••••••', isPassword: true),
          const SizedBox(height: 20),
          _buildLabel('Xác nhận mật khẩu'),
          _buildTextField(
            _confirmPasswordController,
            '••••••••',
            isConfirmPassword: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: agreeToTerms,
                onChanged: (val) => setState(() => agreeToTerms = val!),
                activeColor: color,
              ),
              const Expanded(
                child: Text('Tôi đồng ý với các chính sách bảo mật'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color color) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        'Đã có tài khoản? Đăng nhập',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    bool obscure = isPassword
        ? _obscurePassword
        : (isConfirmPassword ? _obscureConfirmPassword : false);
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: (isPassword || isConfirmPassword)
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) _obscurePassword = !_obscurePassword;
                    if (isConfirmPassword)
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildRoleButton(String label, String role) {
    bool isSelected = selectedRole == role;
    final isAllowed = _isRoleAllowed(role);
    return GestureDetector(
      onTap: isAllowed ? () => setState(() => selectedRole = role) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: !isAllowed
              ? Colors.grey.shade100
              : isSelected
              ? Theme.of(context).primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          isAllowed ? label : '$label (khoá)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: !isAllowed
                ? Colors.grey
                : isSelected
                ? Colors.white
                : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
