import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  final int quantity;
  final String restaurantId;
  final String restaurantName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.restaurantId,
    required this.restaurantName,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      image: image,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem({
    required String id,
    required String name,
    required double price,
    required String image,
    required String restaurantId,
    required String restaurantName,
  }) {
    final existingIndex = state.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [
        ...state,
        CartItem(
          id: id,
          name: name,
          price: price,
          image: image,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      ];
    }
  }

  void removeItem(String id) {
    final existingIndex = state.indexWhere((item) => item.id == id);
    if (existingIndex < 0) return;

    final item = state[existingIndex];
    if (item.quantity > 1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity - 1)
          else
            state[i]
      ];
    } else {
      state = state.where((item) => item.id != id).toList();
    }
  }

  void clearCart() => state = [];

  double get total => state.fold(0, (sum, item) => sum + (item.price * item.quantity));

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());
