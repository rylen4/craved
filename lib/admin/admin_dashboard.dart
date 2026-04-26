import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
              icon: const Icon(LucideIcons.logOut, color: Colors.white54),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/launchpad');
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(LucideIcons.activity), text: 'LIVE ORDERS'),
              Tab(icon: Icon(LucideIcons.archive), text: 'ORDER HISTORY'),
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
                child: Text('Database Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final allOrders = snapshot.data!.docs;

            final liveOrders = allOrders.where((doc) {
              final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
              return status == 'pending' || status == 'assigned';
            }).toList();

            final historyOrders = allOrders.where((doc) {
              final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
              return status == 'delivered' || status == 'cancelled';
            }).toList();

            return TabBarView(
              children: [
                _buildOrderList(liveOrders, isLive: true),
                _buildOrderList(historyOrders, isLive: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<QueryDocumentSnapshot> orders, {required bool isLive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isLive ? LucideIcons.checkCircle2 : LucideIcons.inbox, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              isLive ? 'All clear. No live orders.' : 'No order history found.',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
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
        return _buildAdminOrderCard(doc.id, data);
      },
    );
  }

  Widget _buildAdminOrderCard(String id, Map<String, dynamic> data) {
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
      badgeColor = Colors.green;
      badgeText = 'DELIVERED';
    } else {
      badgeColor = Colors.white54;
      badgeText = status.toString().toUpperCase();
    }

    String timeString = 'Just now';
    if (data['createdAt'] != null) {
      final ts = data['createdAt'] as Timestamp;
      final date = ts.toDate();
      timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
          ' - ${date.day}/${date.month}/${date.year}';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(timeString, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CUSTOMER', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        data['customerName'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['deliveryAddress'] ?? 'No Address',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RESTAURANT', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
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
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.userCheck, size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Picked up by: ${data['courierName'] ?? 'Unknown Driver'}',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
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
