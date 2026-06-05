import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/models/user_model.dart';
import '../../../models/announcement_model.dart';
import '../../../models/assignment_model.dart';
import '../../../models/attendance_model.dart';
import '../../../models/grade_model.dart';

class ClassDetailScreen extends StatelessWidget {
  final String classId;
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
      length: 5,
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: [
                Tab(text: 'Thông báo'),
                Tab(text: 'Bài tập'),
                Tab(text: 'Điểm'),
                Tab(text: 'Điểm danh'),
                Tab(text: 'Mọi người'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationTab(databaseService, context),
                  _buildQuizTab(databaseService, context),
                  _buildGradesTab(databaseService, context),
                  _buildAttendanceTab(databaseService, context),
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
          const Text(
            'Giảng viên',
            style: TextStyle(
              fontSize: 28,
              color: Colors.blue,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Divider(color: Colors.blue, thickness: 1),
          FutureBuilder<UserModel?>(
            future: db.getUser(teacherId),
            builder: (context, snapshot) {
              final teacherModel = snapshot.data;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      teacherModel?.profileImageUrl != null &&
                          teacherModel!.profileImageUrl!.isNotEmpty
                      ? NetworkImage(teacherModel.profileImageUrl!)
                      : null,
                  child:
                      teacherModel?.profileImageUrl == null ||
                          teacherModel!.profileImageUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  teacher,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bạn cùng lớp',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.blue,
                  fontWeight: FontWeight.w400,
                ),
              ),
              StreamBuilder<List<UserModel>>(
                stream: db.getClassMembers(classId),
                builder: (context, snapshot) {
                  int count = snapshot.data?.length ?? 0;
                  return Text(
                    '$count học viên',
                    style: const TextStyle(color: Colors.grey),
                  );
                },
              ),
            ],
          ),
          const Divider(color: Colors.blue, thickness: 1),
          StreamBuilder<List<UserModel>>(
            stream: db.getClassMembers(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final members = snapshot.data ?? [];
              if (members.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có học viên nào tham gia'),
                );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          member.profileImageUrl != null &&
                              member.profileImageUrl!.isNotEmpty
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child:
                          member.profileImageUrl == null ||
                              member.profileImageUrl!.isEmpty
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
                  Navigator.pushNamed(
                    context,
                    '/create_announcement',
                    arguments: {'classId': classId, 'className': className},
                  );
                },
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: db.getAnnouncementsByClass(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('Lỗi: ${snapshot.error}'));

              final announcements = List<dynamic>.from(snapshot.data ?? []);

              announcements.sort((a, b) {
                final aTime =
                    (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final bTime =
                    (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                return bTime.compareTo(aTime);
              });

              if (announcements.isEmpty)
                return const Center(
                  child: Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final a = announcements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.campaign, color: Colors.orange),
                      ),
                      title: Text(
                        a['title'] ?? 'Thông báo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        a['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        final model = AnnouncementModel.fromMap(
                          Map<String, dynamic>.from(a),
                          a['id'],
                        );
                        Navigator.pushNamed(
                          context,
                          '/announcement_detail',
                          arguments: model,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showQuizResults(
    BuildContext context,
    DatabaseService db,
    String quizId,
    String quizTitle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Kết quả: $quizTitle',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<dynamic>>(
                  stream: db.getQuizResults(quizId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    final results = snapshot.data ?? [];
                    if (results.isEmpty)
                      return const Center(
                        child: Text('Chưa có học viên nào nộp bài.'),
                      );
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final r = results[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(r['studentName'] ?? 'Học viên'),
                          trailing: Text(
                            '${r['score']}/${r['total']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Tạo bài tập có deadline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create_assignment',
                        arguments: {'classId': classId, 'className': className},
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Tạo bài kiểm tra AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create_quiz'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAssignmentSection(db, context, isTeacher, currentUserUid),
                const SizedBox(height: 24),
                _buildQuizSection(db, context, isTeacher, currentUserUid),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentSection(
    DatabaseService db,
    BuildContext context,
    bool isTeacher,
    String? currentUserUid,
  ) {
    return StreamBuilder<List<AssignmentModel>>(
      stream: db.getAssignmentsByClass(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final assignments = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Bài tập deadline', Icons.event_note_outlined),
            if (assignments.isEmpty)
              _buildEmptyText('Chưa có bài tập deadline nào')
            else
              ...assignments.map(
                (assignment) => _buildAssignmentCard(
                  context,
                  db,
                  assignment,
                  isTeacher,
                  currentUserUid,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    DatabaseService db,
    AssignmentModel assignment,
    bool isTeacher,
    String? currentUserUid,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isClosed = assignment.isOverdue && !assignment.allowLateSubmissions;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: assignment.isOverdue
              ? const Color(0xFFFFFBEB)
              : const Color(0xFFEFF6FF),
          child: Icon(
            assignment.isOverdue
                ? Icons.warning_amber_rounded
                : Icons.assignment_outlined,
            color: assignment.isOverdue ? Colors.orange : Colors.blue,
          ),
        ),
        title: Text(
          assignment.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Hạn nộp: ${dateFormat.format(assignment.dueDate)}',
                style: TextStyle(
                  color: assignment.isOverdue
                      ? Colors.orange.shade800
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isClosed)
                const Text(
                  'Đã đóng',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        trailing: isTeacher
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () =>
                    _showAssignmentSubmissions(context, db, assignment),
                child: const Text('Bài nộp'),
              )
            : _buildSubmissionAction(
                context,
                db,
                assignment,
                currentUserUid,
                isClosed,
              ),
      ),
    );
  }

  Widget _buildSubmissionAction(
    BuildContext context,
    DatabaseService db,
    AssignmentModel assignment,
    String? currentUserUid,
    bool isClosed,
  ) {
    if (currentUserUid == null) return const SizedBox.shrink();

    return FutureBuilder<AssignmentSubmissionModel?>(
      future: db.getAssignmentSubmission(
        assignment.assignmentId,
        currentUserUid,
      ),
      builder: (context, snapshot) {
        final submitted = snapshot.data != null;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: submitted ? Colors.green : const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isClosed && !submitted
              ? null
              : () => Navigator.pushNamed(
                  context,
                  '/submit_assignment',
                  arguments: assignment,
                ),
          child: Text(submitted ? 'Đã nộp' : 'Nộp bài'),
        );
      },
    );
  }

  Widget _buildQuizSection(
    DatabaseService db,
    BuildContext context,
    bool isTeacher,
    String? currentUserUid,
  ) {
    return StreamBuilder<List<dynamic>>(
      stream: db.getQuizzesByClass(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text('Lỗi: ${snapshot.error}'));

        final quizzes = List<dynamic>.from(snapshot.data ?? []);
        quizzes.sort((a, b) {
          final aTime =
              (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime =
              (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Bài kiểm tra AI', Icons.quiz_outlined),
            if (quizzes.isEmpty)
              _buildEmptyText('Chưa có bài kiểm tra nào')
            else
              ...quizzes.map(
                (q) =>
                    _buildQuizCard(context, db, q, isTeacher, currentUserUid),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    DatabaseService db,
    dynamic q,
    bool isTeacher,
    String? currentUserUid,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(Icons.assignment, color: Colors.blue),
        ),
        title: Text(
          q['title'] ?? 'Bài tập',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${q['questions']?.length ?? 0} câu hỏi trắc nghiệm'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            final quizId = q['quizId'] ?? q['id'] ?? '';
            if (isTeacher) {
              _showQuizResults(context, db, quizId, q['title'] ?? 'Bài tập');
            } else {
              if (quizId.isNotEmpty && currentUserUid != null) {
                bool completed = await db.hasCompletedQuiz(
                  quizId,
                  currentUserUid,
                );
                if (completed && context.mounted) {
                  _showAlreadyCompletedDialog(context);
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

  void _showAlreadyCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Thông báo',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Bạn đã làm bài này rồi, không thể làm lại.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAssignmentSubmissions(
    BuildContext context,
    DatabaseService db,
    AssignmentModel assignment,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Bài nộp: ${assignment.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<AssignmentSubmissionModel>>(
                  stream: db.getAssignmentSubmissions(assignment.assignmentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError)
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    final submissions = snapshot.data ?? [];
                    if (submissions.isEmpty)
                      return const Center(
                        child: Text('Chưa có học viên nào nộp bài.'),
                      );

                    return ListView.builder(
                      itemCount: submissions.length,
                      itemBuilder: (context, index) {
                        final submission = submissions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(submission.studentName),
                            subtitle: Text(
                              '${dateFormat.format(submission.submittedAt)}${submission.isLate ? ' - Nộp muộn' : ''}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                _showSubmissionDetail(context, submission),
                          ),
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

  void _showSubmissionDetail(
    BuildContext context,
    AssignmentSubmissionModel submission,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          submission.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thời gian nộp: ${dateFormat.format(submission.submittedAt)}',
              ),
              if (submission.isLate)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Nộp muộn',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Nội dung:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                submission.content.isEmpty
                    ? '(Không có nội dung)'
                    : submission.content,
              ),
              if (submission.fileUrl != null &&
                  submission.fileName != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _openUrl(submission.fileUrl!),
                  icon: const Icon(Icons.attach_file),
                  label: Text(submission.fileName!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTab(DatabaseService db, BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isTeacher = currentUserUid == teacherId;

    return StreamBuilder<List<dynamic>>(
      stream: db.getQuizResultsByClass(classId),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (quizSnapshot.hasError) {
          return Center(child: Text('Lỗi: ${quizSnapshot.error}'));
        }

        return StreamBuilder<List<ManualGradeModel>>(
          stream: db.getManualGradesByClass(classId),
          builder: (context, manualSnapshot) {
            if (manualSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (manualSnapshot.hasError) {
              return Center(child: Text('Lỗi: ${manualSnapshot.error}'));
            }

            final entries = _buildGradeEntries(
              quizSnapshot.data ?? [],
              manualSnapshot.data ?? [],
            );

            if (isTeacher) {
              return StreamBuilder<List<UserModel>>(
                stream: db.getClassMembers(classId),
                builder: (context, membersSnapshot) {
                  if (membersSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = membersSnapshot.data ?? [];
                  return _buildTeacherGradesView(context, db, members, entries);
                },
              );
            }

            return _buildStudentGradesView(currentUserUid, entries);
          },
        );
      },
    );
  }

  List<_GradeEntry> _buildGradeEntries(
    List<dynamic> quizResults,
    List<ManualGradeModel> manualGrades,
  ) {
    final entries = <_GradeEntry>[
      ...quizResults.map((result) {
        final submittedAt = result['submittedAt'] is Timestamp
            ? (result['submittedAt'] as Timestamp).toDate()
            : DateTime.now();
        return _GradeEntry(
          id: result['id'] ?? '',
          studentId: result['studentId'] ?? '',
          studentName: result['studentName'] ?? 'Học viên',
          title: result['quizTitle'] ?? 'Quiz',
          score: (result['score'] as num?)?.toDouble() ?? 0,
          total: (result['total'] as num?)?.toDouble() ?? 0,
          type: 'Quiz',
          date: submittedAt,
        );
      }),
      ...manualGrades.map((grade) {
        return _GradeEntry(
          id: grade.gradeId,
          studentId: grade.studentId,
          studentName: grade.studentName,
          title: grade.title,
          score: grade.score,
          total: grade.total,
          type: 'Thủ công',
          date: grade.updatedAt,
          manualGrade: grade,
        );
      }),
    ];

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Widget _buildTeacherGradesView(
    BuildContext context,
    DatabaseService db,
    List<UserModel> members,
    List<_GradeEntry> entries,
  ) {
    final stats = _calculateGradeStats(entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGradeStats(stats),
          const SizedBox(height: 18),
          _buildSectionTitle('Bảng điểm học viên', Icons.leaderboard_outlined),
          if (members.isEmpty)
            _buildEmptyText('Chưa có học viên nào trong lớp')
          else
            ...members.map((member) {
              final studentEntries = entries
                  .where((entry) => entry.studentId == member.uid)
                  .toList();
              final studentStats = _calculateGradeStats(studentEntries);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        member.profileImageUrl != null &&
                            member.profileImageUrl!.isNotEmpty
                        ? NetworkImage(member.profileImageUrl!)
                        : null,
                    child:
                        member.profileImageUrl == null ||
                            member.profileImageUrl!.isEmpty
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  title: Text(
                    member.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${studentEntries.length} cột điểm'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        studentStats.hasData
                            ? '${studentStats.average.toStringAsFixed(1)}%'
                            : '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'TB',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _showStudentGradeDetail(
                    context,
                    db,
                    member,
                    studentEntries,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudentGradesView(
    String? currentUserUid,
    List<_GradeEntry> entries,
  ) {
    if (currentUserUid == null) {
      return const Center(child: Text('Không tìm thấy tài khoản'));
    }

    final myEntries = entries
        .where((entry) => entry.studentId == currentUserUid)
        .toList();
    final stats = _calculateGradeStats(myEntries);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGradeStats(stats),
          const SizedBox(height: 18),
          _buildSectionTitle('Điểm của tôi', Icons.grade_outlined),
          if (myEntries.isEmpty)
            _buildEmptyText('Bạn chưa có điểm nào')
          else
            ...myEntries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.type == 'Quiz'
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF0FDF4),
                    child: Icon(
                      entry.type == 'Quiz'
                          ? Icons.quiz_outlined
                          : Icons.edit_note_outlined,
                      color: entry.type == 'Quiz' ? Colors.blue : Colors.green,
                    ),
                  ),
                  title: Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${entry.type} - ${dateFormat.format(entry.date)}',
                  ),
                  trailing: Text(
                    '${entry.score.toStringAsFixed(1)}/${entry.total.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildGradeStats(_GradeStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Trung bình',
            stats.hasData ? '${stats.average.toStringAsFixed(1)}%' : '-',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Cao nhất',
            stats.hasData ? '${stats.highest.toStringAsFixed(1)}%' : '-',
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Thấp nhất',
            stats.hasData ? '${stats.lowest.toStringAsFixed(1)}%' : '-',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  _GradeStats _calculateGradeStats(List<_GradeEntry> entries) {
    final validPercents = entries
        .where((entry) => entry.total > 0)
        .map((entry) => entry.percent)
        .toList();
    if (validPercents.isEmpty) return const _GradeStats.empty();

    final total = validPercents.reduce((a, b) => a + b);
    validPercents.sort();
    return _GradeStats(
      average: total / validPercents.length,
      highest: validPercents.last,
      lowest: validPercents.first,
    );
  }

  void _showStudentGradeDetail(
    BuildContext context,
    DatabaseService db,
    UserModel student,
    List<_GradeEntry> entries,
  ) {
    final stats = _calculateGradeStats(entries);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showManualGradeDialog(context, db, student),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nhập điểm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildGradeStats(stats),
              const SizedBox(height: 14),
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyText('Học viên chưa có điểm nào')
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: entry.type == 'Quiz'
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF0FDF4),
                              child: Icon(
                                entry.type == 'Quiz'
                                    ? Icons.quiz_outlined
                                    : Icons.edit_note_outlined,
                                color: entry.type == 'Quiz'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                            title: Text(entry.title),
                            subtitle: Text(
                              '${entry.type} - ${dateFormat.format(entry.date)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${entry.score.toStringAsFixed(1)}/${entry.total.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (entry.manualGrade != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showManualGradeDialog(
                                      context,
                                      db,
                                      student,
                                      existingGrade: entry.manualGrade,
                                    ),
                                  ),
                              ],
                            ),
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

  void _showManualGradeDialog(
    BuildContext context,
    DatabaseService db,
    UserModel student, {
    ManualGradeModel? existingGrade,
  }) {
    final titleController = TextEditingController(
      text: existingGrade?.title ?? '',
    );
    final scoreController = TextEditingController(
      text: existingGrade?.score.toString() ?? '',
    );
    final totalController = TextEditingController(
      text: existingGrade?.total.toString() ?? '10',
    );
    final noteController = TextEditingController(
      text: existingGrade?.note ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existingGrade == null ? 'Nhập điểm thủ công' : 'Sửa điểm thủ công',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên cột điểm'),
                ),
                TextField(
                  controller: scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Điểm đạt được'),
                ),
                TextField(
                  controller: totalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Điểm tối đa'),
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      final score = double.tryParse(
                        scoreController.text.trim(),
                      );
                      final total = double.tryParse(
                        totalController.text.trim(),
                      );
                      if (title.isEmpty ||
                          score == null ||
                          total == null ||
                          total <= 0) {
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      final now = DateTime.now();
                      final grade = ManualGradeModel(
                        gradeId:
                            existingGrade?.gradeId ??
                            now.microsecondsSinceEpoch.toString(),
                        classId: classId,
                        studentId: student.uid,
                        studentName: student.fullName,
                        title: title,
                        score: score,
                        total: total,
                        note: noteController.text.trim(),
                        createdAt: existingGrade?.createdAt ?? now,
                        updatedAt: now,
                      );

                      await db.saveManualGrade(grade);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã lưu điểm thủ công!'),
                            backgroundColor: Color(0xFF22C55E),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(DatabaseService db, BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isTeacher = currentUserUid == teacherId;

    return Column(
      children: [
        if (isTeacher)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateAttendanceDialog(context, db),
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Tạo buổi điểm danh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<AttendanceSessionModel>>(
            stream: db.getAttendanceSessionsByClass(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError)
                return Center(child: Text('Lỗi: ${snapshot.error}'));

              final sessions = snapshot.data ?? [];
              if (sessions.isEmpty) {
                return _buildEmptyText('Chưa có buổi điểm danh nào');
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return isTeacher
                      ? _buildTeacherAttendanceCard(context, db, session)
                      : _buildStudentAttendanceCard(
                          context,
                          db,
                          session,
                          currentUserUid,
                        );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherAttendanceCard(
    BuildContext context,
    DatabaseService db,
    AttendanceSessionModel session,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.isOpen
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFF1F5F9),
          child: Icon(
            session.isOpen
                ? Icons.how_to_reg_outlined
                : Icons.lock_clock_outlined,
            color: session.isOpen ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(session.sessionDate)} - Mã: ${session.code}',
        ),
        trailing: Switch(
          value: session.isOpen,
          activeThumbColor: const Color(0xFF0F172A),
          onChanged: (value) =>
              db.updateAttendanceSessionStatus(session.sessionId, value),
        ),
        onTap: () => _showAttendanceRecords(context, db, session),
      ),
    );
  }

  Widget _buildStudentAttendanceCard(
    BuildContext context,
    DatabaseService db,
    AttendanceSessionModel session,
    String? currentUserUid,
  ) {
    if (currentUserUid == null) return const SizedBox.shrink();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return FutureBuilder<AttendanceRecordModel?>(
      future: db.getAttendanceRecord(session.sessionId, currentUserUid),
      builder: (context, snapshot) {
        final record = snapshot.data;
        final marked = record != null;
        final canSubmit =
            session.isOpen && (record == null || record.isRejected);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _attendanceStatusBackground(record),
              child: Icon(
                _attendanceStatusIcon(record),
                color: _attendanceStatusColor(record),
              ),
            ),
            title: Text(
              session.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dateFormat.format(session.sessionDate)} - ${session.isOpen ? 'Đang mở' : 'Đã đóng'}',
                  ),
                  if (marked)
                    Text(
                      _attendanceStatusLabel(record),
                      style: TextStyle(
                        color: _attendanceStatusColor(record),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            trailing: ElevatedButton(
              onPressed: !canSubmit
                  ? null
                  : () => _markAttendance(context, db, session, currentUserUid),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_studentAttendanceButtonLabel(record, session)),
            ),
          ),
        );
      },
    );
  }

  void _showCreateAttendanceDialog(BuildContext context, DatabaseService db) {
    final titleController = TextEditingController(
      text: 'Điểm danh ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Tạo buổi điểm danh'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Tên buổi điểm danh'),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      setDialogState(() => isSaving = true);
                      final now = DateTime.now();
                      final session = AttendanceSessionModel(
                        sessionId: now.microsecondsSinceEpoch.toString(),
                        classId: classId,
                        title: title,
                        code: _generateAttendanceCode(),
                        isOpen: true,
                        sessionDate: now,
                        createdAt: now,
                      );
                      await db.createAttendanceSession(session);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateAttendanceCode() {
    return (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
  }

  Future<void> _markAttendance(
    BuildContext context,
    DatabaseService db,
    AttendanceSessionModel session,
    String studentId,
  ) async {
    try {
      final storageService = StorageService();
      final photoUrl = await storageService.captureAndUploadAttendancePhoto(
        uid: studentId,
        sessionId: session.sessionId,
      );

      if (photoUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn chưa chụp ảnh điểm danh.')),
          );
        }
        return;
      }

      String studentName =
          FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.email ??
          'Học viên';

      final userModel = await db.getUser(studentId);
      if (userModel != null && userModel.fullName.isNotEmpty) {
        studentName = userModel.fullName;
      }

      final record = AttendanceRecordModel(
        recordId: '${session.sessionId}_$studentId',
        sessionId: session.sessionId,
        classId: classId,
        studentId: studentId,
        studentName: studentName,
        checkedAt: DateTime.now(),
        photoUrl: photoUrl,
        approvalStatus: AttendanceRecordModel.statusPending,
      );
      await db.markAttendance(record);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi ảnh điểm danh, chờ giảng viên duyệt!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể điểm danh: $e')));
      }
    }
  }

  void _showAttendanceRecords(
    BuildContext context,
    DatabaseService db,
    AttendanceSessionModel session,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã điểm danh: ${session.code}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<AttendanceRecordModel>>(
                  stream: db.getAttendanceRecords(session.sessionId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final records = snapshot.data ?? [];
                    if (records.isEmpty)
                      return const Center(
                        child: Text('Chưa có học viên điểm danh.'),
                      );
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return ListTile(
                          leading: _buildAttendancePhotoThumb(record, index),
                          title: Text(record.studentName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormat.format(record.checkedAt)),
                              Text(
                                _attendanceStatusLabel(record),
                                style: TextStyle(
                                  color: _attendanceStatusColor(record),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: _buildAttendanceReviewActions(
                            context,
                            db,
                            record,
                          ),
                          onTap:
                              record.photoUrl == null ||
                                  record.photoUrl!.isEmpty
                              ? null
                              : () => _showAttendancePhotoDialog(
                                  context,
                                  db,
                                  record,
                                  dateFormat,
                                ),
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

  Widget _buildAttendancePhotoThumb(AttendanceRecordModel record, int index) {
    final photoUrl = record.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return CircleAvatar(child: Text('${index + 1}'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        photoUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(child: Text('${index + 1}')),
      ),
    );
  }

  Widget _buildAttendanceReviewActions(
    BuildContext context,
    DatabaseService db,
    AttendanceRecordModel record,
  ) {
    if (!record.isPending) {
      return Icon(
        _attendanceStatusIcon(record),
        color: _attendanceStatusColor(record),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Từ chối',
          icon: const Icon(Icons.close_rounded, color: Colors.red),
          onPressed: () => _reviewAttendanceRecord(
            context,
            db,
            record,
            AttendanceRecordModel.statusRejected,
          ),
        ),
        IconButton(
          tooltip: 'Duyệt',
          icon: const Icon(Icons.check_rounded, color: Colors.green),
          onPressed: () => _reviewAttendanceRecord(
            context,
            db,
            record,
            AttendanceRecordModel.statusApproved,
          ),
        ),
      ],
    );
  }

  void _showAttendancePhotoDialog(
    BuildContext context,
    DatabaseService db,
    AttendanceRecordModel record,
    DateFormat dateFormat,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(record.studentName),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.network(
                    record.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: const Text('Không tải được ảnh'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Thời gian: ${dateFormat.format(record.checkedAt)}'),
              Text(
                _attendanceStatusLabel(record),
                style: TextStyle(
                  color: _attendanceStatusColor(record),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          if (record.isPending || record.isApproved)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _reviewAttendanceRecord(
                  context,
                  db,
                  record,
                  AttendanceRecordModel.statusRejected,
                );
              },
              child: const Text('Từ chối'),
            ),
          if (record.isPending || record.isRejected)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _reviewAttendanceRecord(
                  context,
                  db,
                  record,
                  AttendanceRecordModel.statusApproved,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Duyệt'),
            ),
        ],
      ),
    );
  }

  Future<void> _reviewAttendanceRecord(
    BuildContext context,
    DatabaseService db,
    AttendanceRecordModel record,
    String approvalStatus,
  ) async {
    try {
      await db.updateAttendanceRecordApproval(
        recordId: record.recordId,
        approvalStatus: approvalStatus,
        reviewedBy: FirebaseAuth.instance.currentUser?.uid ?? teacherId,
      );

      if (context.mounted) {
        final message = approvalStatus == AttendanceRecordModel.statusApproved
            ? 'Đã duyệt điểm danh.'
            : 'Đã từ chối điểm danh.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                approvalStatus == AttendanceRecordModel.statusApproved
                ? const Color(0xFF22C55E)
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật điểm danh: $e')),
        );
      }
    }
  }

  String _studentAttendanceButtonLabel(
    AttendanceRecordModel? record,
    AttendanceSessionModel session,
  ) {
    if (record == null) return session.isOpen ? 'Điểm danh' : 'Đã đóng';
    if (record.isRejected && session.isOpen) return 'Chụp lại';
    if (record.isPending) return 'Chờ duyệt';
    if (record.isApproved) return 'Đã duyệt';
    return 'Từ chối';
  }

  String _attendanceStatusLabel(AttendanceRecordModel? record) {
    if (record == null) return 'Chưa điểm danh';
    if (record.isPending) return 'Chờ giảng viên duyệt';
    if (record.isApproved) return 'Đã duyệt';
    if (record.isRejected) return 'Từ chối';
    return 'Đã gửi';
  }

  IconData _attendanceStatusIcon(AttendanceRecordModel? record) {
    if (record == null) return Icons.how_to_reg_outlined;
    if (record.isPending) return Icons.pending_actions_outlined;
    if (record.isApproved) return Icons.check_circle;
    if (record.isRejected) return Icons.cancel_outlined;
    return Icons.how_to_reg_outlined;
  }

  Color _attendanceStatusColor(AttendanceRecordModel? record) {
    if (record == null) return Colors.blue;
    if (record.isPending) return Colors.orange;
    if (record.isApproved) return Colors.green;
    if (record.isRejected) return Colors.red;
    return Colors.blue;
  }

  Color _attendanceStatusBackground(AttendanceRecordModel? record) {
    if (record == null) return const Color(0xFFEFF6FF);
    if (record.isPending) return const Color(0xFFFFFBEB);
    if (record.isApproved) return const Color(0xFFF0FDF4);
    if (record.isRejected) return const Color(0xFFFEF2F2);
    return const Color(0xFFEFF6FF);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F172A), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyText(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _GradeEntry {
  final String id;
  final String studentId;
  final String studentName;
  final String title;
  final double score;
  final double total;
  final String type;
  final DateTime date;
  final ManualGradeModel? manualGrade;

  const _GradeEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.score,
    required this.total,
    required this.type,
    required this.date,
    this.manualGrade,
  });

  double get percent => total <= 0 ? 0 : (score / total) * 100;
}

class _GradeStats {
  final double average;
  final double highest;
  final double lowest;
  final bool hasData;

  const _GradeStats({
    required this.average,
    required this.highest,
    required this.lowest,
  }) : hasData = true;

  const _GradeStats.empty()
    : average = 0,
      highest = 0,
      lowest = 0,
      hasData = false;
}
