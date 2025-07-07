import 'package:flutter/material.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities for your Mood'),
      ),
      body: const Center(
        child: Text('Mood-based activities UI will be built here.'),
      ),
    );
  }
}
