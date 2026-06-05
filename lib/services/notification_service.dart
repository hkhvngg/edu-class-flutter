import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSendException implements Exception {
  final String message;

  const NotificationSendException(this.message);

  @override
  String toString() => message;
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Thông báo quan trọng của lớp học',
        importance: Importance.max,
      );
  static bool _isInitialized = false;
  static bool _isTokenRefreshBound = false;

  Future<void> init() async {
    if (!_isInitialized) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {},
      );

      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_androidChannel);
      await androidPlugin?.requestNotificationsPermission();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      _isInitialized = true;
    }

    if (!_isTokenRefreshBound) {
      _firebaseMessaging.onTokenRefresh.listen(_saveToken);
      _isTokenRefreshBound = true;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Thông báo quan trọng của lớp học',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> saveTokenToDatabase() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();
      final settings = userDoc.data()?['notificationSettings'];

      if (settings is Map && settings['pushEnabled'] == false) {
        await userRef.set({
          'fcmToken': FieldValue.delete(),
        }, SetOptions(merge: true));
        return;
      }

      await userRef.set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<String> _getAccessToken() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final Map<String, dynamic> serviceAccount = json.decode(response);

      final credentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccount,
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final auth.AccessCredentials access = await auth
          .clientViaServiceAccount(credentials, scopes)
          .then((client) {
            final credentials = client.credentials;
            client.close();
            return credentials;
          });

      return access.accessToken.data;
    } catch (e) {
      throw NotificationSendException(_friendlyMessagingCredentialError(e));
    }
  }

  Future<bool> sendNotification({
    required String title,
    required String body,
    required String fcmToken,
    Map<String, String> data = const {},
  }) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final Map<String, dynamic> serviceAccount = json.decode(response);
      final String projectId = serviceAccount['project_id'];

      final String endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      final String accessToken = await _getAccessToken();

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'title': title,
            'body': body,
            ...data,
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
        },
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
        return true;
      } else {
        throw NotificationSendException(
          _friendlyMessagingResponseError(
            httpResponse.statusCode,
            httpResponse.body,
          ),
        );
      }
    } catch (e) {
      print('Lỗi trong quá trình gửi thông báo: $e');
      rethrow;
    }
  }

  Future<int> sendNotificationToMultiple({
    required String title,
    required String body,
    required List<String> fcmTokens,
    Map<String, String> data = const {},
  }) async {
    int successCount = 0;
    final failures = <String>[];

    for (String token in fcmTokens) {
      try {
        final sent = await sendNotification(
          title: title,
          body: body,
          fcmToken: token,
          data: data,
        );
        if (sent) successCount++;
      } catch (e) {
        failures.add(e.toString());
      }
    }

    if (fcmTokens.isNotEmpty && successCount == 0) {
      throw NotificationSendException(
        failures.isEmpty ? 'Không gửi được thông báo.' : failures.first,
      );
    }

    return successCount;
  }

  String _friendlyMessagingCredentialError(Object error) {
    final message = error.toString();
    if (message.contains('invalid_grant') ||
        message.contains('Invalid JWT Signature') ||
        message.contains('Failed to obtain access credentials')) {
      return 'Khóa gửi thông báo Firebase không hợp lệ hoặc đã bị thu hồi. Vui lòng tạo lại service account đúng project Firebase rồi thay file assets/service_account.json.';
    }
    if (message.contains('Unable to load asset') ||
        message.contains('service_account.json')) {
      return 'Thiếu file cấu hình gửi thông báo assets/service_account.json. Vui lòng thêm service account của Firebase vào project.';
    }
    if (message.contains('SocketException') || message.contains('network')) {
      return 'Không thể kết nối Firebase Cloud Messaging. Vui lòng kiểm tra internet rồi thử lại.';
    }
    return 'Không thể lấy quyền gửi thông báo Firebase. Vui lòng kiểm tra lại service account.';
  }

  String _friendlyMessagingResponseError(int statusCode, String responseBody) {
    if (statusCode == 401 || statusCode == 403) {
      return 'Tài khoản dịch vụ chưa có quyền gửi thông báo Firebase Cloud Messaging. Vui lòng kiểm tra quyền IAM/Firebase Admin SDK.';
    }
    if (statusCode == 400 &&
        (responseBody.contains('UNREGISTERED') ||
            responseBody.contains('INVALID_ARGUMENT'))) {
      return 'Một số thiết bị học viên có mã thông báo cũ. Học viên cần mở app và đăng nhập lại để cập nhật thông báo.';
    }
    return 'Firebase Cloud Messaging từ chối gửi thông báo. Mã lỗi: $statusCode.';
  }
}
