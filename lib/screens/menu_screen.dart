import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/cart_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String id;
  const MenuScreen({super.key, required this.id});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _restaurantName = '';
  String _heroImage = '';
  bool _headerLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantHeader();
  }

  Future<void> _fetchRestaurantHeader() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.id)
          .get();

      if (mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _restaurantName = data['name'] ?? 'Restaurant';
          _heroImage = data['image'] ?? '';
          _headerLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching restaurant header: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final int cartItemCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    final double cartTotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: !_headerLoaded
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
                    child: _buildGroupedMenuStream(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cartItemCount > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => context.push('/cart'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$cartItemCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Text(
                          'View Cart',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '\$${cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: AppColors.surfaceContainer,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: _headerLoaded
          ? Text(
              _restaurantName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
          : const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
      flexibleSpace: _heroImage.isEmpty
          ? Container(color: AppColors.surfaceContainerHighest)
          : CachedNetworkImage(
              imageUrl: _heroImage,
              fit: BoxFit.cover,
              color: Colors.black54,
              colorBlendMode: BlendMode.darken,
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceContainerHighest,
                child: const Icon(LucideIcons.imageOff, color: Colors.white24, size: 40),
              ),
            ),
    );
  }

  Widget _buildGroupedMenuStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.id)
          .collection('menu')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading menu', style: TextStyle(color: Colors.white)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No items yet.', style: TextStyle(color: Colors.white54)),
          );
        }

        final Map<String, List<QueryDocumentSnapshot>> groupedMenu = {};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] ?? 'General';
          groupedMenu.putIfAbsent(category, () => []).add(doc);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: groupedMenu.keys.length,
          itemBuilder: (context, index) {
            final categoryName = groupedMenu.keys.elementAt(index);
            final items = groupedMenu[categoryName]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final doc = items[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildMenuItemCard(doc.id, data);
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItemCard(String itemId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Unknown';
    final price = (data['price'] as num? ?? 0.0).toDouble();
    final image = data['image'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!_headerLoaded) return;
            HapticFeedback.mediumImpact();
            ref.read(cartProvider.notifier).addItem(
              id: itemId,
              name: name,
              price: price,
              image: image,
              restaurantId: widget.id,
              restaurantName: _restaurantName,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] as String? ?? '',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.plus,
                                  size: 16,
                                  color: _headerLoaded ? AppColors.primary : Colors.white24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: _headerLoaded ? AppColors.primary : Colors.white24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      width: 90,
                      height: 90,
                      color: AppColors.surfaceContainerHighest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
