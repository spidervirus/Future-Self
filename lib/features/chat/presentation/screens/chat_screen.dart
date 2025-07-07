import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with your Future Self'),
      ),
      body: const Center(
        child: Text('Chat UI will be built here.'),
      ),
    );
  }
}
