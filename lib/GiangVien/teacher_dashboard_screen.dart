import 'package:flutter/material.dart';

class TeacherClass {
  final String name;
  final String subName;
  final int studentCount;
  final int materialCount;
  final Color color;

  TeacherClass({
    required this.name,
    required this.subName,
    required this.studentCount,
    required this.materialCount,
    required this.color,
  });
}

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TeacherClass> classes = [
      TeacherClass(
        name: 'Lập trình di động',
        subName: 'Android & Flutter',
        studentCount: 45,
        materialCount: 8,
        color: const Color(0xFF1967D2),
      ),
      TeacherClass(
        name: 'Phát triển Web',
        subName: 'React & Node.js',
        studentCount: 38,
        materialCount: 6,
        color: const Color(0xFF1E8E3E),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats Section
            Row(
              children: [
                _buildStatCard(context, Icons.menu_book_rounded, '2', 'Lớp học'),
                const SizedBox(width: 12),
                _buildStatCard(context, Icons.people_outline, '83', 'Học viên'),
                const SizedBox(width: 12),
                _buildStatCard(context, Icons.description_outlined, '14', 'Tài liệu'),
              ],
            ),
            const SizedBox(height: 24),

            // Create New Class Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tạo lớp học mới',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Classes List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final item = classes[index];
                return Container(
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
                      // Card Header
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
                      // Card Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.studentCount} học viên',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.description_outlined, size: 18, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.materialCount} tài liệu',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text(
                                      'Gửi tài liệu',
                                      style: TextStyle(color: Colors.black87, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text(
                                      'Thông báo',
                                      style: TextStyle(color: Colors.black87, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text(
                                      'Chi tiết',
                                      style: TextStyle(color: Colors.black87, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/teacher_profile');
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
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade700),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
