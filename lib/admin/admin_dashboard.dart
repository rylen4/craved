import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131313),
          elevation: 2,
          title: const Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'CRAVE ADMIN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: Colors.white70),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/launchpad');
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(LucideIcons.activity), text: 'LIVE'),
              Tab(icon: Icon(LucideIcons.archive), text: 'HISTORY'),
              Tab(icon: Icon(LucideIcons.store), text: 'RESTAURANTS'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final all = snapshot.data!.docs;

            final live = all.where((doc) {
              final s = (doc.data() as Map<String, dynamic>)['status'] ?? '';
              return s == 'pending' || s == 'assigned';
            }).toList();

            final history = all.where((doc) {
              final s = (doc.data() as Map<String, dynamic>)['status'] ?? '';
              return s == 'delivered' || s == 'cancelled';
            }).toList();

            return TabBarView(
              children: [
                _LiveOrdersTab(orders: live),
                _HistoryTab(orders: history),
                const _RestaurantsTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiveOrdersTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _LiveOrdersTab({required this.orders});

  @override
  Widget build(BuildContext context) => _OrderList(orders: orders, isLive: true);
}

class _HistoryTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _HistoryTab({required this.orders});

  @override
  Widget build(BuildContext context) => _OrderList(orders: orders, isLive: false);
}

class _OrderList extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  final bool isLive;

  const _OrderList({required this.orders, required this.isLive});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLive ? LucideIcons.checkCircle2 : LucideIcons.inbox,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              isLive ? 'All clear. No live orders.' : 'No order history found.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final doc = orders[i];
        final data = doc.data() as Map<String, dynamic>;
        return _AdminOrderCard(id: doc.id, data: data);
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _AdminOrderCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'unknown';
    final isAssigned = status == 'assigned';
    final isDelivered = status == 'delivered';

    Color badgeColor;
    String badgeText;

    if (status == 'pending') {
      badgeColor = Colors.orangeAccent;
      badgeText = 'PENDING';
    } else if (isAssigned) {
      badgeColor = Colors.blueAccent;
      badgeText = 'PICKED UP';
    } else if (isDelivered) {
      badgeColor = Colors.greenAccent;
      badgeText = 'DELIVERED';
    } else {
      badgeColor = Colors.white70;
      badgeText = status.toString().toUpperCase();
    }

    String timeString = 'Just now';
    if (data['createdAt'] != null) {
      final ts = data['createdAt'] as Timestamp;
      final date = ts.toDate();
      timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(timeString, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CUSTOMER', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        data['customerName'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['deliveryAddress'] ?? 'No Address',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RESTAURANT', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        data['restaurantName'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: \$${data['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAssigned || isDelivered) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.userCheck, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Picked up by: ${data['courierName'] ?? 'Unknown Driver'}',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestaurantsTab extends StatelessWidget {
  const _RestaurantsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showRestaurantSheet(context, null, null),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.store, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text('No restaurants yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _RestaurantCard(
                id: doc.id,
                data: data,
                onEdit: () => _showRestaurantSheet(context, doc.id, data),
                onManageMenu: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _RestaurantMenuScreen(restaurantId: doc.id, restaurantName: data['name'] ?? 'Unknown')),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRestaurantSheet(BuildContext context, String? docId, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _RestaurantEditSheet(docId: docId, existing: existing),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onManageMenu;

  const _RestaurantCard({required this.id, required this.data, required this.onEdit, required this.onManageMenu});

  @override
  Widget build(BuildContext context) {
    final hasAddress = (data['address'] ?? '').toString().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasAddress ? AppColors.primary.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
          child: const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
        ),
        title: Text(data['name'] ?? 'Unnamed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (hasAddress)
              Text(data['address'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13))
            else
              Row(
                children: [
                  const Icon(LucideIcons.alertCircle, size: 14, color: Colors.orangeAccent),
                  const SizedBox(width: 6),
                  const Text('No address — map tracking disabled', style: TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                ],
              ),
            if (data['category'] != null && data['category'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(data['category'], style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
            if (data['time'] != null) ...[
              const SizedBox(height: 6),
              Text('${data['time']}  ·  ${data['deliveryFee'] ?? 'Free delivery'}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Manage Menu',
              icon: const Icon(LucideIcons.list, color: AppColors.primary, size: 24),
              onPressed: onManageMenu,
            ),
            IconButton(
              tooltip: 'Edit Settings',
              icon: const Icon(LucideIcons.pencil, color: Colors.white70, size: 22),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantMenuScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const _RestaurantMenuScreen({required this.restaurantId, required this.restaurantName});

  void _showMenuEditSheet(BuildContext context, String? docId, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _MenuItemEditSheet(restaurantId: restaurantId, docId: docId, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        elevation: 2,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Menu: $restaurantName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showMenuEditSheet(context, null, null),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('menu').orderBy('category').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.utensilsCrossed, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text('This menu is empty.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: data['image'] ?? '',
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(width: 60, height: 60, color: AppColors.surfaceContainerHighest, child: const Icon(LucideIcons.imageOff, color: Colors.white38)),
                    ),
                  ),
                  title: Text(data['name'] ?? 'Unnamed Item', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['category'] ?? 'General', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('\$${(data['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.pencil, color: Colors.white70),
                    onPressed: () => _showMenuEditSheet(context, doc.id, data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MenuItemEditSheet extends StatefulWidget {
  final String restaurantId;
  final String? docId;
  final Map<String, dynamic>? existing;

  const _MenuItemEditSheet({required this.restaurantId, this.docId, this.existing});

  @override
  State<_MenuItemEditSheet> createState() => _MenuItemEditSheetState();
}

class _MenuItemEditSheetState extends State<_MenuItemEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _imageController;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool get _isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? {};
    _nameController = TextEditingController(text: e['name'] ?? '');
    _descController = TextEditingController(text: e['description'] ?? '');
    _priceController = TextEditingController(text: e['price']?.toString() ?? '');
    _categoryController = TextEditingController(text: e['category'] ?? '');
    _imageController = TextEditingController(text: e['image'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price are required.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'category': _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      'image': _imageController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final collection = FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('menu');

      if (_isEditing) {
        await collection.doc(widget.docId).update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await collection.add(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Item updated.' : 'Item added.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('menu').doc(widget.docId).delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.redAccent));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditing ? 'Edit Menu Item' : 'Add Menu Item', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (_isEditing)
                  IconButton(
                    icon: _isDeleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2)) : const Icon(LucideIcons.trash2, color: Colors.redAccent),
                    onPressed: _isDeleting ? null : _delete,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _field(_nameController, 'Item Name', LucideIcons.utensils),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_priceController, 'Price (e.g. 12.50)', LucideIcons.badgeDollarSign, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(_categoryController, 'Category (e.g. Burgers)', LucideIcons.tag)),
              ],
            ),
            const SizedBox(height: 12),
            _field(_descController, 'Description', LucideIcons.textSelect),
            const SizedBox(height: 12),
            _field(_imageController, 'Image URL', LucideIcons.image),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)) : Text(_isEditing ? 'Save Item' : 'Add Item', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white60, size: 18),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        filled: true, fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _RestaurantEditSheet extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;

  const _RestaurantEditSheet({this.docId, this.existing});

  @override
  State<_RestaurantEditSheet> createState() => _RestaurantEditSheetState();
}

class _RestaurantEditSheetState extends State<_RestaurantEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _addressController;
  late final TextEditingController _timeController;
  late final TextEditingController _feeController;
  late final TextEditingController _imageController;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool get _isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? {};
    _nameController = TextEditingController(text: e['name'] ?? '');
    _categoryController = TextEditingController(text: e['category'] ?? '');
    _addressController = TextEditingController(text: e['address'] ?? '');
    _timeController = TextEditingController(text: e['time'] ?? '');
    _feeController = TextEditingController(text: e['deliveryFee'] ?? '');
    _imageController = TextEditingController(text: e['image'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _timeController.dispose();
    _feeController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant name is required.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'address': _addressController.text.trim(),
      'time': _timeController.text.trim(),
      'deliveryFee': _feeController.text.trim(),
      'image': _imageController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance.collection('restaurants').doc(widget.docId).update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('restaurants').add(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Restaurant updated.' : 'Restaurant added.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Delete Restaurant?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('This will permanently delete "${_nameController.text}". Orders already placed will not be affected.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(widget.docId).delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.redAccent));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditing ? 'Edit Restaurant' : 'Add Restaurant', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (_isEditing)
                  IconButton(
                    icon: _isDeleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2)) : const Icon(LucideIcons.trash2, color: Colors.redAccent),
                    onPressed: _isDeleting ? null : _delete,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _field(_nameController, 'e.g. The Athenian Grill', LucideIcons.store),
            const SizedBox(height: 16),
            _field(_categoryController, 'Category (e.g. Burgers, Pizza)', LucideIcons.tag),
            const SizedBox(height: 16),
            _field(_addressController, 'e.g. Ermou 12, Athens', LucideIcons.mapPin),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field(_timeController, '25-35 min', LucideIcons.clock)),
                const SizedBox(width: 16),
                Expanded(child: _field(_feeController, 'Free / €2.00', LucideIcons.badgeDollarSign)),
              ],
            ),
            const SizedBox(height: 16),
            _field(_imageController, 'Cover Image URL', LucideIcons.image),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)) : Text(_isEditing ? 'Save Changes' : 'Add Restaurant', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white60, size: 18),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        filled: true, fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}