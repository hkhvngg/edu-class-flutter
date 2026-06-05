import 'package:flutter/material.dart';

import '../../../services/database_service.dart';
import '../../../utils/ui_utils.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _maintenanceMode = false;
  bool _allowStudentRegistration = true;
  bool _allowTeacherRegistration = true;
  bool _requireEmailVerification = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _databaseService.getSystemSettings();
      if (!mounted) return;
      _applySettings(settings);
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(context, 'Thông báo', 'Lỗi tải cài đặt: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySettings(Map<String, dynamic> settings) {
    setState(() {
      _appNameController.text = settings['appName'] ?? 'EduClass';
      _supportEmailController.text =
          settings['supportEmail'] ?? 'admin@educlass.com';
      _maintenanceMode = settings['maintenanceMode'] == true;
      _allowStudentRegistration = settings['allowStudentRegistration'] != false;
      _allowTeacherRegistration = settings['allowTeacherRegistration'] != false;
      _requireEmailVerification = settings['requireEmailVerification'] != false;
    });
  }

  Future<void> _saveSettings() async {
    final appName = _appNameController.text.trim();
    final supportEmail = _supportEmailController.text.trim();

    if (appName.isEmpty || supportEmail.isEmpty) {
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Vui lòng nhập tên hệ thống và email hỗ trợ.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _databaseService.updateSystemSettings({
        'appName': appName,
        'supportEmail': supportEmail,
        'maintenanceMode': _maintenanceMode,
        'allowStudentRegistration': _allowStudentRegistration,
        'allowTeacherRegistration': _allowTeacherRegistration,
        'requireEmailVerification': _requireEmailVerification,
      });

      if (mounted) {
        UIUtils.showMessageDialog(
          context,
          'Thông báo',
          'Đã lưu cài đặt hệ thống.',
        );
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(context, 'Thông báo', 'Lỗi lưu cài đặt: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetDefaults() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Khôi phục mặc định'),
            content: const Text(
              'Bạn có muốn đưa toàn bộ cài đặt hệ thống về mặc định không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Khôi phục'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    _applySettings(DatabaseService.defaultSystemSettings);
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    title: 'Thông tin chung',
                    icon: Icons.tune_rounded,
                    children: [
                      _buildTextField(
                        controller: _appNameController,
                        label: 'Tên hệ thống',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _supportEmailController,
                        label: 'Email hỗ trợ',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Trạng thái hệ thống',
                    icon: Icons.admin_panel_settings_outlined,
                    children: [
                      _buildSwitchTile(
                        title: 'Chế độ bảo trì',
                        subtitle: 'Chỉ tài khoản admin được đăng nhập',
                        value: _maintenanceMode,
                        icon: Icons.construction_outlined,
                        activeColor: Colors.orange,
                        onChanged: (value) =>
                            setState(() => _maintenanceMode = value),
                      ),
                      if (_maintenanceMode) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Khi bật bảo trì, học viên và giảng viên sẽ tạm thời không đăng nhập được.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Đăng ký tài khoản',
                    icon: Icons.person_add_alt_1_outlined,
                    children: [
                      _buildSwitchTile(
                        title: 'Cho phép học viên đăng ký',
                        subtitle: 'Bật hoặc tắt đăng ký tài khoản học viên',
                        value: _allowStudentRegistration,
                        icon: Icons.person_outline,
                        onChanged: (value) =>
                            setState(() => _allowStudentRegistration = value),
                      ),
                      const Divider(height: 20),
                      _buildSwitchTile(
                        title: 'Cho phép giảng viên đăng ký',
                        subtitle: 'Bật hoặc tắt đăng ký tài khoản giảng viên',
                        value: _allowTeacherRegistration,
                        icon: Icons.co_present_outlined,
                        onChanged: (value) =>
                            setState(() => _allowTeacherRegistration = value),
                      ),
                      const Divider(height: 20),
                      _buildSwitchTile(
                        title: 'Yêu cầu xác thực email',
                        subtitle:
                            'Tài khoản mới cần xác thực email trước khi đăng nhập',
                        value: _requireEmailVerification,
                        icon: Icons.verified_user_outlined,
                        onChanged: (value) =>
                            setState(() => _requireEmailVerification = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetDefaults,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Khôi phục mặc định'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Đang lưu...' : 'Lưu cài đặt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0F172A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    Color activeColor = const Color(0xFF0F172A),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: activeColor.withValues(alpha: 0.1),
          child: Icon(icon, color: activeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
