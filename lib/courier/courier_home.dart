import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';


class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  final User? driver = FirebaseAuth.instance.currentUser;

  Future<void> _acceptOrder(String orderId) async {
    if (driver == null) return;

    try {
      final driverDoc = await FirebaseFirestore.instance.collection('users').doc(driver!.uid).get();
      final emailName = driver!.email?.split('@')[0].toUpperCase() ?? 'COURIER';
      final driverName = driverDoc.data()?['name'] ?? emailName;

      final docRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Order no longer exists.');

        final data = snapshot.data()!;
        if (data['status'] != 'pending' || data['courierId'] != null) {
          throw Exception('Order already claimed.');
        }

        transaction.update(docRef, {
          'status': 'assigned',
          'courierId': driver!.uid,
          'courierName': driverName,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Claimed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order unavailable.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsDelivered(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery Confirmed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating order.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131313),
          title: const Text('DISPATCH', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: Colors.white54),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/courier/auth');
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [Tab(text: 'NEW ORDERS'), Tab(text: 'MY ROUTE')],
          ),
        ),
        body: TabBarView(
          children: [_buildOrdersStream(isNew: true), _buildOrdersStream(isNew: false)],
        ),
      ),
    );
  }

  Widget _buildOrdersStream({required bool isNew}) {
    if (!isNew && driver == null) return const SizedBox();

    Query query = FirebaseFirestore.instance.collection('orders').orderBy(isNew ? 'createdAt' : 'acceptedAt', descending: true);

    if (isNew) {
      query = query.where('status', isEqualTo: 'pending').where('courierId', isNull: true);
    } else {
      query = query.where('courierId', isEqualTo: driver!.uid).where('status', isEqualTo: 'assigned');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));

        final orders = snapshot.data!.docs;
        if (orders.isEmpty) return Center(child: Text(isNew ? 'No active orders.' : 'No assigned orders.', style: const TextStyle(color: Colors.white54)));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final data = orders[i].data() as Map<String, dynamic>;
            return _buildOrderCard(orders[i].id, data, isNew: isNew);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String id, Map<String, dynamic> data, {required bool isNew}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNew ? Colors.white10 : Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ORDER #${id.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(data['price'] != null ? '\$${data['price']}' : 'Paid', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow(LucideIcons.store, data['restaurantName'] ?? 'Unknown Restaurant'),
          const SizedBox(height: 12),
          _buildInfoRow(LucideIcons.user, data['customerName'] ?? 'Customer'),
          const SizedBox(height: 12),
          _buildInfoRow(LucideIcons.mapPin, data['deliveryAddress'] ?? 'No Address Provided', color: Colors.redAccent),

          if (data['notes']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: _buildInfoRow(LucideIcons.info, '"${data['notes']}"', style: const TextStyle(color: Colors.amberAccent, fontStyle: FontStyle.italic)),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isNew ? Colors.amberAccent : Colors.green,
                foregroundColor: isNew ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => isNew ? _acceptOrder(id) : _markAsDelivered(id),
              child: Text(isNew ? 'ACCEPT ORDER' : 'ORDER DELIVERED', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color color = Colors.amberAccent, TextStyle? style}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: style ?? const TextStyle(color: Colors.white, fontSize: 16))),
      ],
    );
  }
}