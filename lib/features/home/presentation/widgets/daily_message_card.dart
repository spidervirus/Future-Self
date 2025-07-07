import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DailyMessageCard extends StatelessWidget {
  const DailyMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A Message From Your Future Self',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              "\"Remember that feeling you wanted more of this year? Today is a perfect day to find a small piece of it. Don't look for the whole thing, just a spark. That's all you need to start.\"",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  context.go('/journal');
                },
                child: const Text('Reflect on this'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
