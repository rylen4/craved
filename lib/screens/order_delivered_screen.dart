import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme.dart';

class OrderDeliveredScreen extends StatelessWidget {
  const OrderDeliveredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, size: 80, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 48),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Order Delivered!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  'Your Crave Courier has confirmed delivery. We hope you enjoy your meal!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
              ),
              const Spacer(),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.go('/'),
                    child: const Text(
                      'Return Home',
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
