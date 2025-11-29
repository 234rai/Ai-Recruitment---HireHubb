// lib/services/notification_debug_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotificationDebugService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _realtimeDb = FirebaseDatabase.instance.ref();

  Future<void> runComprehensiveTest(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar(context, '❌ No user logged in', Colors.red);
      return;
    }

    _showSnackBar(context, '🧪 Starting comprehensive test...', Colors.blue);

    // Test 1: Check Firestore structure
    await testFirestoreStructure(context, currentUser.uid);

    // Test 2: Check Realtime Database
    await testRealtimeDatabase(context);

    // Test 3: Create test notification directly
    await createTestNotificationDirectly(context, currentUser.uid);

    // Test 4: Test stream
    await testNotificationStream(context, currentUser.uid);
  }

  Future<void> testFirestoreStructure(BuildContext context, String userId) async {
    try {
      print('🔍 Testing Firestore structure...');

      // Check if notifications collection exists
      final notificationsDoc = await _firestore
          .collection('notifications')
          .doc(userId)
          .get();

      if (!notificationsDoc.exists) {
        print('❌ Notifications document does not exist for user: $userId');
        _showSnackBar(context, '❌ Notifications doc missing', Colors.orange);
        return;
      }

      // Check if user_notifications subcollection has any data
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .limit(1)
          .get();

      print('📊 Found ${notificationsSnapshot.docs.length} notifications in Firestore');

      if (notificationsSnapshot.docs.isNotEmpty) {
        final notification = notificationsSnapshot.docs.first.data();
        print('📄 Sample notification: $notification');
        _showSnackBar(context, '✅ Firestore: ${notificationsSnapshot.docs.length} notifications', Colors.green);
      } else {
        _showSnackBar(context, 'ℹ️ Firestore: No notifications yet', Colors.blue);
      }

    } catch (e) {
      print('❌ Firestore test error: $e');
      _showSnackBar(context, '❌ Firestore error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> testRealtimeDatabase(BuildContext context) async {
    try {
      print('🔍 Testing Realtime Database...');

      // Test connection
      final connectionRef = _realtimeDb.child('.info/connected');
      connectionRef.onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        print('🌐 Realtime DB connected: $connected');
      });

      // Check notification triggers
      final triggersSnapshot = await _realtimeDb
          .child('notification_triggers')
          .limitToLast(5)
          .once();

      final triggers = triggersSnapshot.snapshot.value;
      print('📨 Recent notification triggers: $triggers');

      _showSnackBar(context, '✅ Realtime DB: Connected', Colors.green);

    } catch (e) {
      print('❌ Realtime DB test error: $e');
      _showSnackBar(context, '❌ Realtime DB error', Colors.red);
    }
  }

  // FIXED: Made this method public by removing underscore
  Future<void> createTestNotificationDirectly(BuildContext context, String userId) async {
    try {
      print('📝 Creating test notification directly...');

      final testNotification = {
        'title': '🧪 Test Notification',
        'body': 'This is a direct test notification created at ${DateTime.now()}',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'test',
        'isRead': false,
        'company': 'Test Company',
        'data': {'test': true, 'debug': true}
      };

      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .add(testNotification);

      print('✅ Direct test notification created');
      _showSnackBar(context, '✅ Direct notification created!', Colors.green);

    } catch (e) {
      print('❌ Direct notification error: $e');
      _showSnackBar(context, '❌ Direct notification failed', Colors.red);
    }
  }

  Future<void> testNotificationStream(BuildContext context, String userId) async {
    try {
      print('🔍 Testing notification stream...');

      final stream = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();

      // Listen to the stream for 5 seconds
      final subscription = stream.listen(
              (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              print('✅ Stream is working! Got ${snapshot.docs.length} notifications');
              final notification = snapshot.docs.first.data();
              print('📨 Stream notification: ${notification['title']}');
            } else {
              print('ℹ️ Stream is working but no notifications');
            }
          },
          onError: (error) {
            print('❌ Stream error: $error');
            _showSnackBar(context, '❌ Stream error', Colors.red);
          }
      );

      // Cancel after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      subscription.cancel();

    } catch (e) {
      print('❌ Stream test error: $e');
    }
  }

  Future<void> clearAllNotifications(BuildContext context) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .get();

      final batch = _firestore.batch();
      for (final doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _showSnackBar(context, '🗑️ All notifications cleared', Colors.orange);
      print('✅ All notifications cleared');

    } catch (e) {
      print('❌ Error clearing notifications: $e');
      _showSnackBar(context, '❌ Clear failed', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}