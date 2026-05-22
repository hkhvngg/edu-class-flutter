import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';
import '../../auth/models/user_model.dart';
import '../../../models/announcement_model.dart';

class ClassDetailScreen extends StatelessWidget {
  final String classId; // Thêm classId để fetch dữ liệu
  final String className;
  final String subName;
  final String teacher;
  final String teacherId;
  final Color color;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.subName,
    required this.teacher,
    required this.teacherId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();

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
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(className, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subName, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                ],
              ),
            ),
            const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: [
                Tab(text: 'Thông báo'),
                Tab(text: 'Bài tập'),
                Tab(text: 'Mọi người'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationTab(databaseService, context),
                  _buildQuizTab(databaseService, context),
                  _buildPeopleTab(databaseService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleTab(DatabaseService db) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Giảng viên', style: TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.w400)),
          const Divider(color: Colors.blue, thickness: 1),
          FutureBuilder<UserModel?>(
            future: db.getUser(teacherId),
            builder: (context, snapshot) {
              final teacherModel = snapshot.data;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: teacherModel?.profileImageUrl != null && teacherModel!.profileImageUrl!.isNotEmpty
                      ? NetworkImage(teacherModel.profileImageUrl!)
                      : null,
                  child: teacherModel?.profileImageUrl == null || teacherModel!.profileImageUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(teacher, style: const TextStyle(fontWeight: FontWeight.w500)),
              );
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bạn cùng lớp', style: TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.w400)),
              StreamBuilder<List<UserModel>>(
                stream: db.getClassMembers(classId),
                builder: (context, snapshot) {
                  int count = snapshot.data?.length ?? 0;
                  return Text('$count học viên', style: const TextStyle(color: Colors.grey));
                },
              ),
            ],
          ),
          const Divider(color: Colors.blue, thickness: 1),
          StreamBuilder<List<UserModel>>(
            stream: db.getClassMembers(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final members = snapshot.data ?? [];
              if (members.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Chưa có học viên nào tham gia'));
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl == null || member.profileImageUrl!.isEmpty
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    title: Text(member.fullName),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTab(DatabaseService db, BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isTeacher = currentUserUid == teacherId;

    return Column(
      children: [
        if (isTeacher)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Đăng thông báo mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/create_announcement', arguments: {
                    'classId': classId,
                    'className': className,
                  });
                },
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: db.getAnnouncementsByClass(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
              
              final announcements = List<dynamic>.from(snapshot.data ?? []);
              
              announcements.sort((a, b) {
                final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                return bTime.compareTo(aTime);
              });

              if (announcements.isEmpty) return const Center(child: Text('Chưa có thông báo nào', style: TextStyle(color: Colors.grey)));
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final a = announcements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.campaign, color: Colors.orange),
                      ),
                      title: Text(a['title'] ?? 'Thông báo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        a['description'] ?? '', 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        final model = AnnouncementModel.fromMap(
                          Map<String, dynamic>.from(a), 
                          a['id']
                        );
                        Navigator.pushNamed(context, '/announcement_detail', arguments: model);
                      },
                    ),
                  );
                }
              );
            }
          ),
        ),
      ],
    );
  }
  
  void _showQuizResults(BuildContext context, DatabaseService db, String quizId, String quizTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Kết quả: $quizTitle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<dynamic>>(
                  stream: db.getQuizResults(quizId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                    final results = snapshot.data ?? [];
                    if (results.isEmpty) return const Center(child: Text('Chưa có học viên nào nộp bài.'));
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final r = results[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(r['studentName'] ?? 'Học viên'),
                          trailing: Text('${r['score']}/${r['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizTab(DatabaseService db, BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isTeacher = currentUserUid == teacherId;
    return Column(
      children: [
        if (isTeacher)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tạo bài tập mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/create_quiz');
                },
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: db.getQuizzesByClass(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
              
              final quizzes = List<dynamic>.from(snapshot.data ?? []);
              
              // Sắp xếp phía client để tránh lỗi Composite Index
              quizzes.sort((a, b) {
                final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                return bTime.compareTo(aTime);
              });

              if (quizzes.isEmpty) return const Center(child: Text('Chưa có bài tập nào', style: TextStyle(color: Colors.grey)));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final q = quizzes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.assignment, color: Colors.blue),
                ),
                title: Text(q['title'] ?? 'Bài tập', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${q['questions']?.length ?? 0} câu hỏi trắc nghiệm'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final quizId = q['quizId'] ?? q['id'] ?? '';
                    if (isTeacher) {
                      _showQuizResults(context, db, quizId, q['title'] ?? 'Bài tập');
                    } else {
                      if (quizId.isNotEmpty && currentUserUid != null) {
                        bool completed = await db.hasCompletedQuiz(quizId, currentUserUid);
                        if (completed && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Thông báo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: const Text('Bạn đã làm bài này rồi, không thể làm lại.'),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Đóng'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                      }
                      if (context.mounted) {
                        Navigator.pushNamed(context, '/take_quiz', arguments: q);
                      }
                    }
                  },
                  child: Text(isTeacher ? 'Kết quả' : 'Làm bài'),
                ),
              ),
            );
          }
        );
      }
    ),
  ),
  ],
  );
  }
}
