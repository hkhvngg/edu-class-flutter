import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String selectedRole = 'student';
  bool agreeToTerms = false;
  bool isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSnackBar('Đăng ký tài khoản thành công!');
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Đã có lỗi xảy ra';
      if (e.code == 'email-already-in-use') msg = 'Email này đã được sử dụng';
      else if (e.code == 'weak-password') msg = 'Mật khẩu quá yếu';
      _showSnackBar(msg);
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.1), Colors.white, primaryColor.withOpacity(0.05)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
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
        Container(width: 64, height: 64, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32)),
        const SizedBox(height: 16),
        const Text('EduClass', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const Text('Tạo tài khoản người dùng', style: TextStyle(color: Colors.black54, fontSize: 16)),
      ],
    );
  }

  Widget _buildRegisterCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đăng ký', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Vai trò', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRoleButton('Học viên', 'student'),
              const SizedBox(width: 8),
              _buildRoleButton('Giảng viên', 'teacher'),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('Họ và tên'),
          _buildTextField(_nameController, 'Nguyễn Văn A'),
          const SizedBox(height: 20),
          _buildLabel('Email'),
          _buildTextField(_emailController, 'your.email@edu.vn'),
          const SizedBox(height: 20),
          _buildLabel('Mật khẩu'),
          _buildTextField(_passwordController, '••••••••', obscureText: true),
          const SizedBox(height: 20),
          _buildLabel('Xác nhận mật khẩu'),
          _buildTextField(_confirmPasswordController, '••••••••', obscureText: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(value: agreeToTerms, onChanged: (val) => setState(() => agreeToTerms = val!), activeColor: color),
              const Expanded(child: Text('Tôi đồng ý với các chính sách bảo mật')),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Đăng ký ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color color) {
    return TextButton(onPressed: () => Navigator.pop(context), child: Text('Đã có tài khoản? Đăng nhập', style: TextStyle(color: color, fontWeight: FontWeight.bold)));
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)));
  Widget _buildTextField(TextEditingController controller, String hint, {bool obscureText = false}) => TextField(controller: controller, obscureText: obscureText, decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  Widget _buildRoleButton(String label, String role) {
    bool isSelected = selectedRole == role;
    return Expanded(child: GestureDetector(onTap: () => setState(() => selectedRole = role), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? Theme.of(context).primaryColor : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)))));
  }
}
