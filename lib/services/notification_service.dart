import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Xin quyền (cho iOS)
    await _firebaseMessaging.requestPermission();

    // Cấu hình local notification cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    // Lắng nghe thông báo khi app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // Lấy FCM token của thiết bị và lưu lên Firestore
  Future<void> saveTokenToDatabase() async {
    String? token = await _firebaseMessaging.getToken();
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (token != null && uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  // Lấy Access Token từ service_account.json
  Future<String> _getAccessToken() async {
    // Đọc file json từ assets
    final String response = await rootBundle.loadString('assets/service_account.json');
    final Map<String, dynamic> serviceAccount = json.decode(response);

    final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccount);
    
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    final auth.AccessCredentials access = 
        await auth.clientViaServiceAccount(credentials, scopes).then((client) {
          final credentials = client.credentials;
          client.close();
          return credentials;
        });

    return access.accessToken.data;
  }

  // Gửi thông báo bằng HTTP v1 API
  Future<void> sendNotification({
    required String title,
    required String body,
    required String fcmToken,
  }) async {
    try {
      final String response = await rootBundle.loadString('assets/service_account.json');
      final Map<String, dynamic> serviceAccount = json.decode(response);
      final String projectId = serviceAccount['project_id'];

      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      final String accessToken = await _getAccessToken();

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          }
        }
      };

      final http.Response httpResponse = await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (httpResponse.statusCode == 200) {
        print('Gửi thông báo thành công');
      } else {
        print('Lỗi gửi thông báo: ${httpResponse.body}');
      }
    } catch (e) {
      print('Lỗi trong quá trình gửi thông báo: $e');
    }
  }

  // Gửi thông báo cho nhiều token
  Future<void> sendNotificationToMultiple({
    required String title,
    required String body,
    required List<String> fcmTokens,
  }) async {
    for (String token in fcmTokens) {
      await sendNotification(title: title, body: body, fcmToken: token);
    }
  }
}
