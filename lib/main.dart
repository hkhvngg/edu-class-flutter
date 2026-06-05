import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/student/screens/class_detail_screen.dart';
import 'features/student/screens/take_quiz_screen.dart';
import 'features/student/screens/student_main_screen.dart';
import 'features/teacher/screens/teacher_dashboard_screen.dart';
import 'features/teacher/screens/teacher_profile_screen.dart';
import 'features/teacher/screens/create_quiz_screen.dart';
import 'features/teacher/screens/create_announcement_screen.dart';
import 'features/teacher/screens/create_assignment_screen.dart';
import 'features/student/screens/announcement_detail_screen.dart';
import 'features/student/screens/submit_assignment_screen.dart';
import 'models/announcement_model.dart';
import 'models/assignment_model.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_users_screen.dart';
import 'features/admin/screens/admin_classes_screen.dart';
import 'features/admin/screens/admin_stats_screen.dart';
import 'features/admin/screens/admin_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduClass',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF6366F1),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        if (settings.name == '/class_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ClassDetailScreen(
              classId: args['classId'],
              className: args['className'],
              subName: args['subName'],
              teacher: args['teacher'],
              teacherId: args['teacherId'],
              color: args['color'],
            ),
          );
        }
        if (settings.name == '/create_announcement') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CreateAnnouncementScreen(
              classId: args['classId'],
              className: args['className'],
            ),
          );
        }
        if (settings.name == '/announcement_detail') {
          final announcement = settings.arguments as AnnouncementModel;
          return MaterialPageRoute(
            builder: (context) =>
                AnnouncementDetailScreen(announcement: announcement),
          );
        }
        if (settings.name == '/create_assignment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CreateAssignmentScreen(
              classId: args['classId'],
              className: args['className'],
            ),
          );
        }
        if (settings.name == '/submit_assignment') {
          final assignment = settings.arguments as AssignmentModel;
          return MaterialPageRoute(
            builder: (context) =>
                SubmitAssignmentScreen(assignment: assignment),
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/student_main': (context) => const StudentMainScreen(),
        '/class_detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ClassDetailScreen(
            classId: args['classId'],
            className: args['className'],
            subName: args['subName'],
            teacher: args['teacher'],
            teacherId: args['teacherId'],
            color: args['color'],
          );
        },
        '/teacher_dashboard': (context) => const TeacherDashboardScreen(),
        '/teacher_profile': (context) => const TeacherProfileScreen(),
        '/create_quiz': (context) => const CreateQuizScreen(),
        '/take_quiz': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return TakeQuizScreen(quizData: args);
        },
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/admin_users': (context) => const AdminUsersScreen(),
        '/admin_classes': (context) => const AdminClassesScreen(),
        '/admin_stats': (context) => const AdminStatsScreen(),
        '/admin_settings': (context) => const AdminSettingsScreen(),
      },
    );
  }
}
