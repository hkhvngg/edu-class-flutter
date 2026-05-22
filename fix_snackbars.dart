import 'dart:io';

void main() {
  final files = [
    'lib/features/teacher/screens/teacher_profile_screen.dart',
    'lib/features/teacher/screens/teacher_dashboard_screen.dart',
    'lib/features/teacher/screens/create_quiz_screen.dart',
    'lib/features/teacher/screens/create_announcement_screen.dart',
    'lib/features/student/screens/upload_material_screen.dart',
    'lib/features/student/screens/take_quiz_screen.dart',
    'lib/features/student/screens/profile_screen.dart',
    'lib/features/student/screens/my_classes_screen.dart',
    'lib/features/student/screens/history_screen.dart',
    'lib/features/student/screens/announcement_detail_screen.dart',
    'lib/features/admin/screens/admin_users_screen.dart',
    'lib/features/admin/screens/admin_dashboard_screen.dart',
    'lib/features/admin/screens/admin_classes_screen.dart'
  ];

  final snackbarPattern = RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(\s*content:\s*Text\((.*?)\)\s*\),?\s*\);", multiLine: true, dotAll: true);

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    String content = file.readAsStringSync();
    if (content.contains('ScaffoldMessenger.of(context).showSnackBar')) {
      // replace the snackbar with UIUtils
      content = content.replaceAllMapped(snackbarPattern, (match) {
        final textArg = match.group(1);
        return "UIUtils.showMessageDialog(context, 'Thông báo', $textArg);";
      });
      
      // Calculate depth for import
      final depth = path.split('/').length - 2;
      final importPath = "${'../' * depth}utils/ui_utils.dart";
      
      // Add import if not present
      if (!content.contains('ui_utils.dart')) {
        content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '$importPath';");
      }
      
      file.writeAsStringSync(content);
      print('Updated $path');
    }
  }
}
