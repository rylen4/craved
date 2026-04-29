import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../core/cart_provider.dart';
import '../core/geocoding_service.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.shoppingBag, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty.',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Keep Browsing',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildCartItem(cart[index], ref),
                  ),
                ),
                _buildCheckoutBar(context, ref, total),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.minusCircle, color: Colors.white54),
                onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
                onPressed: () => ref.read(cartProvider.notifier).addItem(
                  id: item.id,
                  name: item.name,
                  price: item.price,
                  image: item.image,
                  restaurantId: item.restaurantId,
                  restaurantName: item.restaurantName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(width: 70, height: 70, color: AppColors.surfaceContainerHighest);
  }

  Widget _buildCheckoutBar(BuildContext context, WidgetRef ref, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _placeOrder(context, ref, total),
                child: const Text(
                  'Checkout',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref, double total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final firstItem = cartItems.first;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final addressesSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    if (addressesSnap.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a delivery address first!'),
            backgroundColor: Colors.orange,
          ),
        );
        context.push('/addresses');
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placing order...'), duration: Duration(seconds: 6)),
      );
    }

    final customerName = userDoc.data()?['name'] ?? 'Unknown Customer';
    final addressData = addressesSnap.docs.first.data();
    final floor = addressData['floor'].toString();
    final liveAddress = '${addressData['street']} ${addressData['number']}'
        '${floor.isNotEmpty ? ', Floor: $floor' : ''}';

    final geocodedCustomer = await GeocodingService.geocodeAddress(
      '${addressData['street']} ${addressData['number']}',
    );

    Map<String, double>? geocodedRestaurant;

    final restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(firstItem.restaurantId)
        .get();

    if (restaurantDoc.exists) {
      final rData = restaurantDoc.data() as Map<String, dynamic>;
      final restaurantAddress = rData['address'] as String?;
      if (restaurantAddress != null && restaurantAddress.isNotEmpty) {
        geocodedRestaurant = await GeocodingService.geocodeAddress(restaurantAddress);
      }
    }

    final orderPayload = <String, dynamic>{
      'customerId': user.uid,
      'customerName': customerName,
      'status': 'pending',
      'courierId': null,
      'price': double.parse(total.toStringAsFixed(2)),
      'restaurantId': firstItem.restaurantId,
      'restaurantName': firstItem.restaurantName,
      'deliveryAddress': liveAddress,
      'notes': 'Beta App Order',
      'createdAt': FieldValue.serverTimestamp(),
      if (geocodedCustomer != null) 'customerLat': geocodedCustomer['lat'],
      if (geocodedCustomer != null) 'customerLng': geocodedCustomer['lng'],
      if (geocodedRestaurant != null) 'restaurantLat': geocodedRestaurant['lat'],
      if (geocodedRestaurant != null) 'restaurantLng': geocodedRestaurant['lng'],
    };

    final orderDocRef = await FirebaseFirestore.instance.collection('orders').add(orderPayload);

    ref.read(cartProvider.notifier).clearCart();

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order Sent to Dispatch!'), backgroundColor: Colors.green),
      );
      context.go('/tracking/${orderDocRef.id}');
    }
  }
}
