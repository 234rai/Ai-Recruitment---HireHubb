import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationManagerService {
  static final NotificationManagerService _instance = NotificationManagerService._internal();
  factory NotificationManagerService() => _instance;
  NotificationManagerService._internal();

  final DatabaseReference _realtimeDb = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize notification listener
  Future<void> initializeNotificationListener() async {
    if (_isInitialized) return;

    print('🔔 Initializing Notification Listener...');

    try {
      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Listen to notification triggers in Realtime Database
      _realtimeDb.child('notification_triggers').onChildAdded.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          _handleNotificationTrigger(data, event.snapshot.key!);
        }
      });

      _isInitialized = true;
      print('✅ Notification Listener active');
    } catch (e) {
      print('❌ Error initializing notification listener: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'job_alerts_channel',
        'Job Alerts',
        description: 'Notifications for job updates and alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  // Handle incoming notification triggers
  Future<void> _handleNotificationTrigger(Map<String, dynamic> data, String triggerId) async {
    try {
      final type = data['type'] as String?;
      final targetUserId = data['targetUserId'] as String?;
      final currentUserId = _auth.currentUser?.uid;

      print('📨 Processing notification trigger: $type');

      // If no current user, skip
      if (currentUserId == null) {
        print('⏭️ No user logged in, skipping');
        return;
      }

      // Don't send notification to yourself if you're the sender
      final senderId = data['senderId'] as String?;
      if (senderId != null && senderId == currentUserId) {
        print('⏭️ Skipping self-notification (you sent it)');
        return;
      }

      // If targetUserId is specified, only process if it's for current user
      if (targetUserId != null && targetUserId != currentUserId) {
        print('⏭️ Not for this user');
        return;
      }

      // Save notification to Firestore for current user
      await _saveNotificationToFirestore(currentUserId, data);

      // Show local notification
      await _showLocalNotification(data);

      // Mark trigger as processed (optional - for debugging)
      await _realtimeDb
          .child('notification_triggers')
          .child(triggerId)
          .child('processed_by')
          .child(currentUserId)
          .set(true);

      print('✅ Notification processed successfully');
    } catch (e) {
      print('❌ Error handling notification: $e');
    }
  }

  // Show local notification - FIXED VERSION
  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    try {
      // Use non-const constructor for AndroidNotificationDetails
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'job_alerts_channel',
        'Job Alerts',
        channelDescription: 'Notifications for job updates and alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: const Color(0xFFFF2D55),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        data['title']?.toString() ?? 'Notification',
        data['body']?.toString() ?? '',
        details,
        payload: data['jobId']?.toString(),
      );

      print('✅ Local notification shown');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(String userId, Map<String, dynamic> data) async {
    try {
      // Create notification document
      final notificationData = {
        'title': data['title']?.toString() ?? 'Notification',
        'body': data['body']?.toString() ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'type': data['type']?.toString() ?? 'general',
        'isRead': false,
        'jobId': data['jobId']?.toString(),
        'company': data['company']?.toString() ?? '',
        'data': data,
      };

      // Add to Firestore
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .add(notificationData);

      print('✅ Notification saved to Firestore for user: $userId');
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
      // Try alternative approach if the above fails
      await _saveNotificationAlternative(userId, data);
    }
  }

  // Alternative saving method
  Future<void> _saveNotificationAlternative(String userId, Map<String, dynamic> data) async {
    try {
      final notificationData = {
        'title': data['title']?.toString() ?? 'Notification',
        'body': data['body']?.toString() ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Use timestamp as int
        'type': data['type']?.toString() ?? 'general',
        'isRead': false,
        'jobId': data['jobId']?.toString(),
        'company': data['company']?.toString() ?? '',
      };

      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .add(notificationData);

      print('✅ Notification saved using alternative method');
    } catch (e) {
      print('❌ Alternative save also failed: $e');
    }
  }

  // Trigger notification for all users
  Future<bool> sendNotificationToAll({
    required String title,
    required String body,
    String? jobId,
    String? company,
    String type = 'general',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final trigger = {
        'type': type,
        'title': title,
        'body': body,
        'jobId': jobId,
        'company': company,
        'timestamp': ServerValue.timestamp,
        'senderId': currentUser?.uid,
        ...?additionalData,
      };

      // Push to Realtime Database
      await _realtimeDb.child('notification_triggers').push().set(trigger);

      print('✅ Notification trigger created for all users');
      return true;
    } catch (e) {
      print('❌ Error creating notification trigger: $e');
      return false;
    }
  }

  // Trigger notification for specific user
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? jobId,
    String? company,
    String type = 'general',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final trigger = {
        'type': type,
        'title': title,
        'body': body,
        'targetUserId': userId,
        'jobId': jobId,
        'company': company,
        'timestamp': ServerValue.timestamp,
        'senderId': currentUser?.uid,
        ...?additionalData,
      };

      await _realtimeDb.child('notification_triggers').push().set(trigger);

      print('✅ Notification trigger created for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error creating notification trigger: $e');
      return false;
    }
  }

  // Send job notification
  Future<bool> sendJobNotification({
    required String userId,
    required String jobTitle,
    required String company,
    String? jobId,
    String type = 'new_job',
  }) async {
    String title, body;

    switch(type) {
      case 'new_job':
        title = '🎯 New Job Match!';
        body = '$jobTitle at $company - Apply now!';
        break;
      case 'application_update':
        title = '📋 Application Update';
        body = 'Your application for $jobTitle at $company has been updated';
        break;
      case 'interview':
        title = '🎉 Interview Scheduled!';
        body = 'You have an interview for $jobTitle at $company';
        break;
      default:
        title = '💼 Job Update';
        body = '$jobTitle at $company';
    }

    return await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      jobId: jobId,
      company: company,
      type: type,
      additionalData: {'jobTitle': jobTitle},
    );
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user logged in');
      return;
    }

    print('📤 Sending test notification...');

    await sendNotificationToUser(
      userId: currentUser.uid,
      title: '🎉 Test Notification',
      body: 'This is a test notification from your app!',
      type: 'test',
    );

    print('✅ Test notification sent');
  }

  // Debug method to test Firestore permissions
  Future<void> testFirestorePermissions() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      print('🔐 Testing Firestore permissions for user: ${currentUser.uid}');

      // Test write permission
      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .add({
        'title': 'Test Notification',
        'body': 'Testing permissions',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'test',
        'isRead': false,
      });

      print('✅ Write permission: GRANTED');

      // Test read permission
      final snapshot = await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .limit(1)
          .get();

      print('✅ Read permission: GRANTED');
      print('📊 Found ${snapshot.docs.length} notifications');

    } catch (e) {
      print('❌ Permission test failed: $e');
    }
  }

  // Check if user has any notifications
  Future<bool> hasNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final snapshot = await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking notifications: $e');
      return false;
    }
  }
}