import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../../services/database_service.dart';
import '../../auth/models/user_model.dart';
import '../../student/models/class_model.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Tạo lớp học'),
            onTap: () {
              Navigator.pop(context);
              _showCreateClassDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final subNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo lớp học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên lớp (bắt buộc)')),
            TextField(controller: subNameController, decoration: const InputDecoration(labelText: 'Phần/Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                String classId = DateTime.now().millisecondsSinceEpoch.toString();
                ClassModel newClass = ClassModel(
                  classId: classId,
                  className: nameController.text,
                  subName: subNameController.text,
                  description: '',
                  teacherId: _uid,
                  inviteCode: _generateInviteCode(),
                  color: Colors.blue.value,
                  studentCount: 0,
                  createdAt: DateTime.now(),
                );
                await _databaseService.createClass(newClass);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EduClass', style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.add, size: 28), onPressed: _showAddOptions),
        ],
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: _databaseService.getTeacherClasses(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final teacherClasses = snapshot.data ?? [];

          return StreamBuilder<List<ClassModel>>(
            stream: _databaseService.getStudentClasses(_uid),
            builder: (context, studentSnapshot) {
              final joinedClasses = studentSnapshot.data ?? [];
              final allVisibleClasses = [...teacherClasses, ...joinedClasses];

              if (allVisibleClasses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 100, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text('Chưa có lớp học nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: allVisibleClasses.length,
                itemBuilder: (context, index) => _buildClassCard(allVisibleClasses[index]),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/create_quiz');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/teacher_profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Lớp học'),
          BottomNavigationBarItem(icon: Icon(Icons.file_upload_outlined), label: 'Tải lên'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassModel item) {
    bool isOwner = item.teacherId == _uid;
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUser(item.teacherId),
      builder: (context, snapshot) {
        String teacherName = isOwner ? 'Tôi' : (snapshot.data?.fullName ?? 'Đang tải...');
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
            margin: const EdgeInsets.only(bottom: 12),
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: const NetworkImage('https://www.gstatic.com/classroom/themes/img_code.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isOwner ? Colors.blue.withOpacity(0.7) : Colors.green.withOpacity(0.7), 
                  BlendMode.multiply
                ),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.className, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(item.subName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const Spacer(),
                      Text(teacherName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      if (isOwner)
                        Text('Mã lớp: ${item.inviteCode}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
