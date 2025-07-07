import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:future_self/features/home/presentation/widgets/daily_message_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Horizon"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Welcome Back,',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            'Aman', // This will be dynamic later
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),
          const DailyMessageCard(),
          const SizedBox(height: 32),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/chat');
        },
        label: const Text('Talk to Future Self'),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          context,
          icon: Icons.photo_library_outlined,
          label: 'Vision Board',
          subtitle: 'Visualize your future',
          onTap: () {
            context.go('/vision-board');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.mic_none_outlined,
          label: 'Affirmations',
          subtitle: 'Record & listen',
          onTap: () {
            context.go('/affirmations');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.book_outlined,
          label: 'Journal',
          subtitle: 'Reflect on your day',
          onTap: () {
            context.go('/journal');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.explore_outlined,
          label: 'Activities',
          subtitle: 'For your mood',
          onTap: () {
            context.go('/activities');
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
