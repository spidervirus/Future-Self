import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:future_self/features/home/presentation/widgets/daily_message_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatingButtonController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Start animations
    _floatingButtonController.forward();
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _floatingButtonController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Horizon"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIcons.bell()),
            onPressed: () {},
          )
              .animate()
              .fadeIn(delay: 600.ms)
              .slideX(begin: 1, end: 0, curve: Curves.easeOutBack),
        ],
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildWelcomeSection(theme),
              const SizedBox(height: 32),
              const DailyMessageCard()
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge,
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.3, end: 0),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(context),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.1),
            child: FloatingActionButton.extended(
              onPressed: () {
                context.go('/chat');
              },
              label: const Text('Talk to Future Self'),
              icon: PhosphorIcon(PhosphorIcons.chatCircle()),
            )
                .animate(controller: _floatingButtonController)
                .fadeIn(begin: 0)
                .slideY(begin: 1, end: 0, curve: Curves.easeOutBack),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back,',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        )
            .animate()
            .fadeIn(delay: 100.ms)
            .slideX(begin: -0.5, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Aman', // This will be dynamic later
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideX(begin: -0.5, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(width: 8),
            PhosphorIcon(
              PhosphorIcons.sparkle(),
              color: theme.colorScheme.primary,
              size: 28,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(
                  begin: 0,
                  end: 1,
                  duration: 3.seconds,
                )
                .then()
                .scaleXY(begin: 1, end: 1.2, duration: 500.ms)
                .then()
                .scaleXY(begin: 1.2, end: 1, duration: 500.ms),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'icon': PhosphorIcons.image(),
        'label': 'Vision Board',
        'subtitle': 'Visualize your future',
        'route': '/vision-board',
        'color': Colors.purple,
      },
      {
        'icon': PhosphorIcons.microphone(),
        'label': 'Affirmations',
        'subtitle': 'Record & listen',
        'route': '/affirmations',
        'color': Colors.orange,
      },
      {
        'icon': PhosphorIcons.bookOpen(),
        'label': 'Journal',
        'subtitle': 'Reflect on your day',
        'route': '/journal',
        'color': Colors.green,
      },
      {
        'icon': PhosphorIcons.compass(),
        'label': 'Activities',
        'subtitle': 'For your mood',
        'route': '/activities',
        'color': Colors.blue,
      },
    ];

    return AnimationLimiter(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildActionCard(
                  context,
                  icon: action['icon'] as IconData,
                  label: action['label'] as String,
                  subtitle: action['subtitle'] as String,
                  color: action['color'] as Color,
                  onTap: () {
                    context.go(action['route'] as String);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PhosphorIcon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                    delay:
                        Duration(milliseconds: 1000 + (icon.hashCode % 1000)),
                    duration: 2.seconds,
                  ),
              const SizedBox(height: 16),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 700 + (icon.hashCode % 300)))
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack);
  }
}
