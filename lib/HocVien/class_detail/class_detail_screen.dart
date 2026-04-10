import 'package:flutter/material.dart';

class ClassDetailScreen extends StatelessWidget {
  final String className;
  final String subName;
  final String teacher;
  final Color color;

  const ClassDetailScreen({
    super.key,
    required this.className,
    required this.subName,
    required this.teacher,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            className,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // TabBar Section
            const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: [
                Tab(text: 'Thông báo'),
                Tab(text: 'Tài liệu'),
                Tab(text: 'Học viên'),
              ],
            ),
            // TabBarView Section
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationTab(),
                  _buildDocumentTab(),
                  _buildStudentTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0F172A),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: 0,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/my_classes');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/upload_material');
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
              icon: Icon(Icons.menu),
              label: 'Danh mục',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNotificationCard(
          teacher,
          '5 tháng 4',
          'Chào mừng các bạn đến với lớp học! Hãy kiểm tra tài liệu bài giảng đã được tải lên.',
        ),
        const SizedBox(height: 16),
        _buildNotificationCard(
          teacher,
          '3 tháng 4',
          'Nhắc nhở: Bài tập tuần này cần nộp trước 23:59 ngày 8/4.',
        ),
      ],
    );
  }

  Widget _buildNotificationCard(String author, String date, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: Icon(Icons.chat_bubble_outline, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTab() {
    return const Center(child: Text('Danh sách tài liệu học tập'));
  }

  Widget _buildStudentTab() {
    return const Center(child: Text('Danh sách học viên trong lớp'));
  }
}
