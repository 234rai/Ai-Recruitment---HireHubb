// lib/screens/messaging_screen.dart
import 'package:flutter/material.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Video Call/Messaging Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}