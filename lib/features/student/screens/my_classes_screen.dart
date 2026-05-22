import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';
import '../../auth/models/user_model.dart';
import '../models/class_model.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  void _showJoinClassDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tham gia lớp học'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Mã lớp (ví dụ: ABC123)',
            labelText: 'Mã lớp',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                bool success = await _databaseService.joinClassWithCode(_uid, codeController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  UIUtils.showMessageDialog(context, 'Thông báo', success ? 'Đã tham gia lớp học thành công!' : 'Mã lớp không chính xác!');
                }
              }
            },
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Lớp học của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF0F0B1E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'join') {
                _showJoinClassDialog();
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacementNamed(context, '/login'));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'join',
                child: Text('Tham gia lớp học'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Đăng xuất'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: _databaseService.getStudentClasses(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa tham gia lớp học nào', style: TextStyle(color: Colors.grey)),
                  TextButton(onPressed: _showJoinClassDialog, child: const Text('Tham gia lớp đầu tiên')),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: classes.length,
            itemBuilder: (context, index) => _buildClassCard(classes[index]),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(ClassModel item) {
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUser(item.teacherId),
      builder: (context, snapshot) {
        String teacherName = snapshot.data?.fullName ?? 'Đang tải...';
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/class_detail', arguments: {
            'classId': item.classId,
            'className': item.className,
            'subName': item.subName,
            'teacher': teacherName,
            'teacherId': item.teacherId,
            'color': Color(item.color),
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(item.color),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.className, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item.subName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(teacherName, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('${item.studentCount} học viên', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
