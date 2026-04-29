import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';

const _fallbackRestaurant = LatLng(37.9715, 23.7257);
const _fallbackCustomer = LatLng(37.9805, 23.7315);

final ColorFilter _darkMapFilter = ColorFilter.matrix([
  -0.2126, -0.7152, -0.0722, 0, 255,
  -0.2126, -0.7152, -0.0722, 0, 255,
  -0.2126, -0.7152, -0.0722, 0, 255,
  0,       0,       0,       1, 0,
]);

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with TickerProviderStateMixin {
  bool _hasNavigated = false;
  late final AnimationController _pulseController;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  LatLng? _extractLatLng(Map<String, dynamic> data, String latKey, String lngKey) {
    final lat = (data[latKey] as num?)?.toDouble();
    final lng = (data[lngKey] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Track Your Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading order', style: TextStyle(color: Colors.redAccent)));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';

          if (status == 'delivered' && !_hasNavigated) {
            _hasNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/delivered');
            });
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final restaurantPoint = _extractLatLng(data, 'restaurantLat', 'restaurantLng');
          final customerPoint = _extractLatLng(data, 'customerLat', 'customerLng');
          final usingFallback = restaurantPoint == null || customerPoint == null;

          final from = restaurantPoint ?? _fallbackRestaurant;
          final to = customerPoint ?? _fallbackCustomer;
          final center = LatLng((from.latitude + to.latitude) / 2, (from.longitude + to.longitude) / 2);

          return Column(
            children: [
              Expanded(
                flex: 60,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulseController, _dotController]),
                      builder: (context, _) {
                        return FlutterMap(
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 14.5,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                          ),
                          children: [
                            ColorFiltered(
                              colorFilter: _darkMapFilter,
                              child: TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.crave.app',
                              ),
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(points: [from, to], color: AppColors.primary.withValues(alpha: 0.2), strokeWidth: 12),
                                Polyline(
                                  points: [from, to],
                                  color: AppColors.primary,
                                  strokeWidth: 4,
                                  pattern: status == 'pending' ? StrokePattern.dashed(segments: [15.0, 15.0]) : StrokePattern.solid(),
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                _buildRestaurantMarker(from, data['restaurantName'] ?? 'Restaurant'),
                                _buildCustomerMarker(to),
                                if (status != 'pending') _buildScooterMarker(from, to),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    if (usingFallback) _buildFallbackWarning(),
                  ],
                ),
              ),
              Expanded(flex: 40, child: _buildInfoPanel(data, status)),
            ],
          );
        },
      ),
    );
  }

  Marker _buildRestaurantMarker(LatLng point, String name) {
    return Marker(
      point: point,
      width: 120, height: 120,
      alignment: Alignment.center, // THE FIX: Aligns the exact center of the box to the coordinate
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. The Label (Pushed perfectly above the dot)
          Positioned(
            bottom: 68,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(6)),
              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          // 2. The Dot (Anchored exactly in the center)
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: const Color(0xFFFF6B35), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: const Center(child: Icon(LucideIcons.store, color: Colors.white, size: 14)),
          )
        ],
      ),
    );
  }



  Marker _buildCustomerMarker(LatLng point) {
    final scale = 1.0 + (_pulseController.value * 0.4);
    return Marker(
      point: point,
      width: 120, height: 120,
      alignment: Alignment.center, // THE FIX: Aligns the exact center of the box to the coordinate
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. The Label (Pushed perfectly above the dot)
          Positioned(
            bottom: 68,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
              child: const Text("You", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          // 2. The Pulse & Dot (Anchored exactly in the center)
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                  scale: scale,
                  child: Container(width: 24, height: 24, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.3), shape: BoxShape.circle))
              ),
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Center(child: Icon(LucideIcons.mapPin, color: Colors.black, size: 14)),
              )
            ],
          )
        ],
      ),
    );
  }

  Marker _buildScooterMarker(LatLng from, LatLng to) {
    final t = _dotController.value;
    final currentLat = from.latitude + (to.latitude - from.latitude) * t;
    final currentLng = from.longitude + (to.longitude - from.longitude) * t;

    return Marker(
      point: LatLng(currentLat, currentLng),
      width: 40, height: 40,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)]),
        child: const Center(child: Text('🛵', style: TextStyle(fontSize: 18))),
      ),
    );
  }

  Widget _buildFallbackWarning() {
    return Positioned(
      top: 12, left: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.black, size: 14),
            SizedBox(width: 8),
            Expanded(child: Text('Place a new order to see the live route.', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(Map<String, dynamic> data, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: const BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      child: Column(
        children: [
          _buildStatusCard(status),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ETA', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${_etaMinutes(status)} min', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL PAID', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('\$${(data['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildProgressBar(_progress(status)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    final text = status == 'assigned' ? 'Your Crave Courier has picked up your food!' : 'Your order has been sent to the restaurant';
    final icon = status == 'assigned' ? LucideIcons.truck : LucideIcons.loader;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double target) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: target),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutExpo,
      builder: (context, value, _) {
        return Container(
          height: 6, width: double.infinity,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10))),
          ),
        );
      },
    );
  }

  int _etaMinutes(String status) {
    if (status == 'assigned') return 10;
    return 15;
  }

  double _progress(String status) {
    if (status == 'pending') return 0.15;
    if (status == 'assigned') return 0.50;
    return 0.90;
  }
}