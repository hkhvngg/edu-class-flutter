import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';
import '../models/material_model.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  Future<void> _deleteSummary(String docId) async {
    await _db.collection('materials').doc(docId).delete();
    if (mounted) {
      UIUtils.showMessageDialog(context, 'Thông báo', 'Đã xoá bản tóm tắt');
    }
  }

  Future<void> _deleteAllSummaries() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xoá tất cả lịch sử tóm tắt không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              var query = await _db.collection('materials')
                  .where('uploaderId', isEqualTo: _uid)
                  .where('classId', isEqualTo: 'personal')
                  .get();
              for (var doc in query.docs) {
                await doc.reference.delete();
              }
              if (mounted) {
                UIUtils.showMessageDialog(context, 'Thông báo', 'Đã xoá tất cả bản tóm tắt');
              }
            },
            child: const Text('Xoá tất cả'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: Color(0xFF0F172A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0F172A),
            tabs: [
              Tab(text: 'Tóm tắt AI'),
              Tab(text: 'Bài tập'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryHistory(),
            _buildQuizHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('materials')
          .where('uploaderId', isEqualTo: _uid)
          .where('classId', isEqualTo: 'personal')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Bạn chưa có bản tóm tắt nào', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        // Map to keep track of docId and material
        final items = docs.map((doc) {
          return {
            'docId': doc.id,
            'material': MaterialModel.fromMap(doc.data() as Map<String, dynamic>)
          };
        }).toList();
        
        items.sort((a, b) {
          final ma = a['material'] as MaterialModel;
          final mb = b['material'] as MaterialModel;
          return mb.createdAt.compareTo(ma.createdAt);
        });

        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _deleteAllSummaries,
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text('Xoá tất cả', style: TextStyle(color: Colors.red)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final docId = items[index]['docId'] as String;
                  final material = items[index]['material'] as MaterialModel;
                  
                  String summaryText = "Không có nội dung";
                  if (material.aiResult != null && material.aiResult!['summary'] != null) {
                    summaryText = material.aiResult!['summary'];
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              material.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteSummary(docId),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(material.createdAt),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            summaryText,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizHistory() {
    return StreamBuilder<List<dynamic>>(
      stream: _dbService.getStudentQuizResults(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

        final results = snapshot.data ?? [];
        
        results.sort((a, b) {
          final aTime = (a['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (b['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Bạn chưa làm bài tập nào', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final r = results[index];
            final submittedAt = (r['submittedAt'] as Timestamp?)?.toDate();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.assignment, color: Colors.blue),
                ),
                title: Text(r['quizTitle'] ?? 'Bài tập', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(submittedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(submittedAt) : ''),
                trailing: Text('${r['score']}/${r['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ),
            );
          },
        );
      }
    );
  }
}
