import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'HocVien/my_classes_screen.dart';
import 'HocVien/upload_material_screen.dart';
import 'HocVien/class_detail/class_detail_screen.dart';
import 'HocVien/profile_screen.dart';
import 'GiangVien/teacher_dashboard_screen.dart';
import 'GiangVien/teacher_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduClass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF6366F1), // Indigo-500
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        if (settings.name == '/class_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return ClassDetailScreen(
                className: args['className'],
                subName: args['subName'],
                teacher: args['teacher'],
                color: args['color'],
              );
            },
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/my_classes': (context) => const MyClassesScreen(),
        '/upload_material': (context) => const UploadMaterialScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/teacher_dashboard': (context) => const TeacherDashboardScreen(),
        '/teacher_profile': (context) => const TeacherProfileScreen(),
      },
    );
  }
}
