import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reflections'),
      ),
      body: const Center(
        child: Text('Journaling UI will be built here.'),
      ),
    );
  }
}
