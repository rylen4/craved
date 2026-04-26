import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../core/auth_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Crave',
          style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, ref),
      body: SafeArea(
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              _buildSearchBar(ref),
              const SizedBox(height: 32),
              _buildCategories(),
              const SizedBox(height: 32),
              _buildLiveRestaurants(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'Guest';

    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surfaceContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Crave', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(userEmail, style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.user, color: AppColors.primary),
            title: const Text('Account', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              context.push('/account');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
            title: const Text('Addresses', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              context.push('/addresses');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.history, color: AppColors.primary),
            title: const Text('Order History', style: TextStyle(color: Colors.white)),
            onTap: () => context.pop(),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              context.pop();
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        decoration: const InputDecoration(
          prefixIcon: Icon(LucideIcons.search, color: AppColors.outlineVariant),
          hintText: 'Search cravings...',
          hintStyle: TextStyle(color: AppColors.outlineVariant),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'label': 'Burgers', 'icon': Icons.fastfood},
      {'label': 'Pizza', 'icon': Icons.local_pizza},
      {'label': 'Healthy', 'icon': Icons.eco},
      {'label': 'Drinks', 'icon': Icons.local_cafe},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
                  ),
                  child: Icon(cat['icon'] as IconData, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveRestaurants(WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text('No restaurants match your search.', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildRestaurantCard(context, docs[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildRestaurantCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => context.push('/menu/$docId'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Hero(
              tag: 'hero_image_$docId',
              child: CachedNetworkImage(
                imageUrl: data['image'] ?? '',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Container(height: 220, color: AppColors.surfaceContainerHighest),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.star, color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              data['rating']?.toString() ?? '5.0',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(data['time'] ?? '--', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 16),
                      Text(data['deliveryFee'] ?? 'Free', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
