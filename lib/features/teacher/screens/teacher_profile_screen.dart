import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/models/user_model.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final user = FirebaseAuth.instance.currentUser;

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (user != null) {
        final userData = await _databaseService.getUser(user!.uid);
        if (mounted) {
          setState(() {
            _userModel = userData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleChangeAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final String? imageUrl = await _storageService.pickAndUploadAvatar(user!.uid);
      if (imageUrl != null) {
        await _databaseService.updateProfileImage(user!.uid, imageUrl);
        await user!.updatePhotoURL(imageUrl);
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật ảnh đại diện!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(context, 'Lỗi', 'Không thể cập nhật ảnh: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userModel?.fullName ?? user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFF0F172A)),
            SizedBox(width: 10),
            Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              try {
                await _databaseService.updateUserProfile(user!.uid, {'fullName': newName});
                await user!.updateDisplayName(newName);
                await _loadUserData();
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật hồ sơ!'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  UIUtils.showMessageDialog(this.context, 'Lỗi', 'Không thể cập nhật: $e', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFF0F172A)),
              SizedBox(width: 10),
              Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField(currentPasswordController, 'Mật khẩu hiện tại'),
              const SizedBox(height: 12),
              _buildPasswordField(newPasswordController, 'Mật khẩu mới'),
              const SizedBox(height: 12),
              _buildPasswordField(confirmPasswordController, 'Xác nhận mật khẩu mới'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: isChanging
                  ? null
                  : () async {
                      if (newPasswordController.text != confirmPasswordController.text) {
                        UIUtils.showMessageDialog(this.context, 'Lỗi', 'Mật khẩu xác nhận không khớp!', isError: true);
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        UIUtils.showMessageDialog(this.context, 'Lỗi', 'Mật khẩu mới phải có ít nhất 6 ký tự!', isError: true);
                        return;
                      }
                      setDialogState(() => isChanging = true);
                      try {
                        final credential = EmailAuthProvider.credential(
                          email: user!.email!,
                          password: currentPasswordController.text,
                        );
                        await user!.reauthenticateWithCredential(credential);
                        await user!.updatePassword(newPasswordController.text);
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đổi mật khẩu thành công!'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => isChanging = false);
                        String message = 'Lỗi không xác định';
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          message = 'Mật khẩu hiện tại không đúng!';
                        } else if (e.code == 'weak-password') {
                          message = 'Mật khẩu mới quá yếu!';
                        } else {
                          message = e.message ?? message;
                        }
                        if (mounted) {
                          UIUtils.showMessageDialog(this.context, 'Lỗi', message, isError: true);
                        }
                      } catch (e) {
                        setDialogState(() => isChanging = false);
                        if (mounted) {
                          UIUtils.showMessageDialog(this.context, 'Lỗi', 'Lỗi: $e', isError: true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isChanging
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Tính năng đang phát triển'),
        backgroundColor: const Color(0xFF64748B),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFD31D3F)),
            SizedBox(width: 10),
            Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD31D3F))),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD31D3F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showMessageDialog(context, 'Thông báo', 'Lỗi đăng xuất: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    final String displayName = _userModel?.fullName ?? user?.displayName ?? 'Chưa cập nhật tên';
    final String email = _userModel?.email ?? user?.email ?? '';
    final String? avatarUrl = _userModel?.profileImageUrl;
    final String initial = (displayName.isNotEmpty ? displayName : email).substring(0, 1).toUpperCase();
    final String memberSince = _userModel != null
        ? '${_userModel!.createdAt.day}/${_userModel!.createdAt.month}/${_userModel!.createdAt.year}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: const Color(0xFF0F172A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Avatar + Info Card ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _handleChangeAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: avatarUrl == null
                                  ? const LinearGradient(
                                      colors: [Color(0xFF0F172A), Color(0xFF334155)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              image: avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: avatarUrl == null
                                ? Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          // Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isUploadingAvatar
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Giảng viên',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Name
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    if (memberSince.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tham gia từ $memberSince',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Menu Items ---
              _buildMenuItem(
                icon: Icons.edit_outlined,
                title: 'Chỉnh sửa hồ sơ',
                subtitle: 'Cập nhật thông tin cá nhân',
                onTap: _showEditProfileDialog,
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Đổi mật khẩu',
                subtitle: 'Bảo mật tài khoản',
                onTap: _showChangePasswordDialog,
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.photo_camera_outlined,
                title: 'Đổi ảnh đại diện',
                subtitle: 'Chọn ảnh từ thư viện',
                onTap: _isUploadingAvatar ? null : _handleChangeAvatar,
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Cài đặt thông báo',
                subtitle: 'Email, push notification',
                onTap: () => _showComingSoon('Cài đặt thông báo'),
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Trợ giúp',
                subtitle: 'Hướng dẫn sử dụng',
                onTap: () => _showComingSoon('Trợ giúp'),
              ),

              const SizedBox(height: 28),

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD31D3F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0F172A),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/teacher_dashboard');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/create_quiz');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Lớp học',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.file_upload_outlined),
          label: 'Tải lên',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          activeIcon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
