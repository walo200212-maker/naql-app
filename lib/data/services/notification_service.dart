import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'naql_channel',
          'NaqlApp Notifications',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFF97316),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _handleTap(RemoteMessage message) {
    // Navigation handled by router listening to notification data
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> saveTokenToFirestore(String userId) async {
    final token = await getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token});
  }

  Future<void> subscribeToCity(String city) async {
    await _messaging.subscribeToTopic('city_${city.toLowerCase().replaceAll(' ', '_')}');
  }
}
