import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DailyMessageCard extends StatelessWidget {
  const DailyMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.quotes(),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A Message From Your Future Self',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideX(begin: 0.3, end: 0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  "\"Remember that feeling you wanted more of this year? Today is a perfect day to find a small piece of it. Don't look for the whole thing, just a spark. That's all you need to start.\"",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      context.go('/journal');
                    },
                    icon: PhosphorIcon(
                      PhosphorIcons.notebook(),
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Reflect on this',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .slideX(begin: 0.3, end: 0, curve: Curves.easeOutBack),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
        .then()
        .shimmer(
          delay: 2.seconds,
          duration: 2.seconds,
          color: theme.colorScheme.primary.withOpacity(0.1),
        );
  }
}
