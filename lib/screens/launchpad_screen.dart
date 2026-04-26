import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class LaunchpadScreen extends StatelessWidget {
  const LaunchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BETA TESTING', style: TextStyle(color: Colors.white54, letterSpacing: 2)),
              Text('Select Environment', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 48),
              _buildLaunchButton(
                title: 'Client App',
                subtitle: 'Order food as a customer',
                icon: LucideIcons.smartphone,
                color: AppColors.primary,
                onTap: () => context.go('/auth'),
              ),
              const SizedBox(height: 24),
              _buildLaunchButton(
                title: 'Courier Dispatch',
                subtitle: 'Accept and deliver orders',
                icon: LucideIcons.truck,
                color: Colors.amberAccent,
                onTap: () => context.go('/courier/auth'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaunchButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color),
          ],
        ),
      ),
    );
  }
}
