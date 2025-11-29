// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:major_project/services/notification_manager_service.dart';
import 'package:major_project/services/notification_debug_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot>? _getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      return _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error creating notifications stream: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay updated with job alerts',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Notifications List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getNotificationsStream(),
                  builder: (context, snapshot) {
                    // Handle no user case
                    if (_auth.currentUser == null) {
                      return _buildAuthRequiredState(isDarkMode);
                    }

                    // Handle stream null case
                    if (_getNotificationsStream() == null) {
                      return Center(
                        child: Text(
                          'Unable to load notifications',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey : Colors.black54,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print('Notification stream error: ${snapshot.error}');
                      return _buildErrorState(snapshot.error.toString(), isDarkMode);
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(isDarkMode);
                    }

                    final notifications = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                        notifications[index].data() as Map<String, dynamic>;
                        final notificationId = notifications[index].id;

                        return _buildNotificationCard(
                          notification,
                          notificationId,
                          isDarkMode,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D55),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthRequiredState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: const Color(0xFFFF2D55).withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to view your notifications',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      Map<String, dynamic> notification,
      String notificationId,
      bool isDarkMode,
      ) {
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';

    // IMPROVED: Better timestamp handling
    DateTime timestamp;
    try {
      if (notification['timestamp'] == null) {
        timestamp = DateTime.now();
      } else if (notification['timestamp'] is Timestamp) {
        timestamp = (notification['timestamp'] as Timestamp).toDate();
      } else if (notification['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(notification['timestamp']);
      } else if (notification['timestamp'] is String) {
        timestamp = DateTime.parse(notification['timestamp']);
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      timestamp = DateTime.now();
    }

    final type = notification['type'] ?? 'general';
    final isRead = notification['isRead'] ?? false;
    final jobId = notification['jobId'];
    final company = notification['company'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: () => _markAsRead(notificationId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: _getNotificationColor(type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        if (company.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              company,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade500,
                              ),
                            ),
                            Row(
                              children: [
                                _buildUsefulButton(notificationId, true, isDarkMode),
                                const SizedBox(width: 8),
                                _buildUsefulButton(notificationId, false, isDarkMode),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2D55),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (jobId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _markAsRead(notificationId);
                      // TODO: Navigate to job details
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2D55),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Job'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsefulButton(String notificationId, bool isUseful, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _handleUsefulFeedback(notificationId, isUseful),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUseful ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
              size: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              isUseful ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 80,
              color: const Color(0xFFFF2D55).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All of your job notifications will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Debug Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Debug Tools',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use these tools to test your notification system',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      // Comprehensive Test
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final debugService = NotificationDebugService();
                            await debugService.runComprehensiveTest(context);
                          },
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Run Comprehensive Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Test Realtime DB Notification
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final currentUser = _auth.currentUser;
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to test notifications'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final notificationManager = NotificationManagerService();
                            await notificationManager.sendTestNotification();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test notification sent via Realtime DB!'),
                                backgroundColor: Color(0xFF34C759),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Test Realtime DB Notification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2D55),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Test Direct Firestore - FIXED: Using public method
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final currentUser = _auth.currentUser;
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to test notifications'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final debugService = NotificationDebugService();
                            await debugService.createTestNotificationDirectly(context, currentUser.uid); // FIXED: Now using public method
                          },
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Test Direct Firestore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Clear All Notifications
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final debugService = NotificationDebugService();
                            await debugService.clearAllNotifications(context);
                            setState(() {}); // Refresh the UI
                          },
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Clear All Notifications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Test Permissions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final notificationManager = NotificationManagerService();
                            await notificationManager.testFirestorePermissions();
                          },
                          icon: const Icon(Icons.security),
                          label: const Text('Test Firestore Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('notifications')
                        .doc(_auth.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Checking status...');
                      }

                      final exists = snapshot.hasData && snapshot.data!.exists;
                      return Text(
                        exists ? '✅ Notifications collection exists' : '❌ Notifications collection missing',
                        style: TextStyle(
                          color: exists ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<QuerySnapshot>(
                    stream: _getNotificationsStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text(
                        '📊 Notifications in stream: $count',
                        style: TextStyle(
                          color: count > 0 ? Colors.green : Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'application_update':
        return const Color(0xFFFF2D55);
      case 'job_match':
        return const Color(0xFF34C759);
      case 'viewed_profile':
        return const Color(0xFF007AFF);
      case 'new_job':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFFFF2D55);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'application_update':
        return Icons.work_outline;
      case 'job_match':
        return Icons.auto_awesome_outlined;
      case 'viewed_profile':
        return Icons.remove_red_eye_outlined;
      case 'new_job':
        return Icons.new_releases_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  void _markAsRead(String notificationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleUsefulFeedback(String notificationId, bool isUseful) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('user_notifications')
          .doc(notificationId)
          .update({
        'feedback': isUseful ? 'useful' : 'not_useful',
        'feedbackTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for your feedback!'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving feedback: $e');
    }
  }

  // Add this method as a fallback if you prefer local implementation
  Future<void> _createTestNotificationDirectly() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

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
          .doc(currentUser.uid)
          .collection('user_notifications')
          .add(testNotification);

      print('✅ Direct test notification created');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Direct notification created!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('❌ Direct notification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Direct notification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}