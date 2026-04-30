import 'package:flutter/material.dart';
import '../models/my_class.dart';

class MyClassesScreen extends StatelessWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MyClass> classes = [
      MyClass(
        name: 'Lập trình di động',
        subName: 'Android & Flutter',
        teacher: 'TS. Nguyễn Văn A',
        studentCount: 45,
        color: const Color(0xFF1967D2),
      ),
      MyClass(
        name: 'Phát triển Web',
        subName: 'React & Node.js',
        teacher: 'ThS. Trần Thị B',
        studentCount: 38,
        color: const Color(0xFF1E8E3E),
      ),
      MyClass(
        name: 'Cơ sở dữ liệu',
        subName: 'SQL & NoSQL',
        teacher: 'TS. Lê Văn C',
        studentCount: 42,
        color: const Color(0xFFD97706),
      ),
      MyClass(
        name: 'Trí tuệ nhân tạo',
        subName: 'Machine Learning',
        teacher: 'PGS.TS. Phạm Thị D',
        studentCount: 30,
        color: const Color(0xFFD93025),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Lớp học của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final item = classes[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/class_detail',
                arguments: {
                  'className': item.name,
                  'subName': item.subName,
                  'teacher': item.teacher,
                  'color': item.color,
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book_outlined, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              item.teacher,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              '${item.studentCount} học viên',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
          if (index == 1) Navigator.pushReplacementNamed(context, '/upload_material');
          if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
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
    );
  }
}
