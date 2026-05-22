import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Báo cáo'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard(
              'Tổng số Người dùng',
              FirebaseFirestore.instance.collection('users').snapshots(),
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Tổng số Lớp học',
              FirebaseFirestore.instance.collection('classes').snapshots(),
              Icons.class_,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Tổng số Tài liệu & Tóm tắt',
              FirebaseFirestore.instance.collection('materials').snapshots(),
              Icons.library_books,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Tổng số Bài tập đã giao',
              FirebaseFirestore.instance.collection('quizzes').snapshots(),
              Icons.assignment,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, Stream<QuerySnapshot> stream, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      if (snapshot.hasError) return const Text('Lỗi');
                      
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
