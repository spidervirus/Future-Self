import 'package:flutter/material.dart';

class AffirmationsScreen extends StatelessWidget {
  const AffirmationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Affirmations'),
      ),
      body: const Center(
        child: Text('Affirmations UI will be built here.'),
      ),
    );
  }
}
