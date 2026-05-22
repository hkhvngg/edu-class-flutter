import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminClassesScreen extends StatelessWidget {
  const AdminClassesScreen({super.key});

  Future<void> _deleteClass(BuildContext context, String classId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá lớp học này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
        if (context.mounted) {
          UIUtils.showMessageDialog(context, 'Thông báo', 'Đã xoá lớp học');
        }
      } catch (e) {
        if (context.mounted) {
          UIUtils.showMessageDialog(context, 'Thông báo', 'Lỗi: $e');
        }
      }
    }
  }

  void _showEditClassDialog(BuildContext context, Map<String, dynamic> classData, String classId) {
    final nameController = TextEditingController(text: classData['className']);
    final subNameController = TextEditingController(text: classData['subName']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa lớp học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên lớp')),
            TextField(controller: subNameController, decoration: const InputDecoration(labelText: 'Mô tả ngắn')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('classes').doc(classId).update({
                'className': nameController.text,
                'subName': subNameController.text,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lớp học'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          
          final classes = snapshot.data?.docs ?? [];
          
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index].data() as Map<String, dynamic>;
              final classId = classes[index].id;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.class_, color: Colors.white)),
                  title: Text(classData['className'] ?? 'Không tên'),
                  subtitle: Text('${classData['subName']}\nMã lớp: ${classData['inviteCode']} | Học viên: ${classData['studentCount']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditClassDialog(context, classData, classId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteClass(context, classId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
