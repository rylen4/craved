import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final LatLng _restaurantPoint = const LatLng(37.9715, 23.7257);
  final LatLng _customerPoint = const LatLng(37.9805, 23.7315);

  GoogleMapController? _mapController;
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('Track Your Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order', style: TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';

          if (status == 'delivered' && !_hasNavigated) {
            _hasNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/delivered');
            });
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              Expanded(flex: 60, child: _buildMap(status)),
              Expanded(
                flex: 40,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
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
                              Text(
                                '${_calculateEtaMinutes(status)} min',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('TOTAL PAID', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '\$${data['price']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildAnimatedProgressLine(_calculateProgress(status)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _fitMapToRoute(GoogleMapController controller) async {
    final bounds = LatLngBounds(southwest: _restaurantPoint, northeast: _customerPoint);
    final update = CameraUpdate.newLatLngBounds(bounds, 100);
    await controller.animateCamera(update);
  }

  Widget _buildMap(String status) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(target: _restaurantPoint, zoom: 14),
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('rest'),
          position: _restaurantPoint,
          infoWindow: const InfoWindow(title: 'Restaurant'),
        ),
        Marker(
          markerId: const MarkerId('cust'),
          position: _customerPoint,
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_restaurantPoint, _customerPoint],
          color: AppColors.primary,
          width: 6,
          patterns: status == 'pending'
              ? [PatternItem.dash(20), PatternItem.gap(10)]
              : [PatternItem.dash(20)],
        ),
      },
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _fitMapToRoute(controller);
      },
    );
  }

  int _calculateEtaMinutes(String status) {
    switch (status) {
      case 'pending':
        return 15;
      case 'assigned':
        return 10;
      default:
        return 5;
    }
  }

  double _calculateProgress(String status) {
    switch (status) {
      case 'pending':
        return 0.15;
      case 'assigned':
        return 0.50;
      default:
        return 0.90;
    }
  }

  Widget _buildAnimatedProgressLine(double targetProgress) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetProgress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo,
      builder: (context, progress, child) {
        return Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(String status) {
    final String text = status == 'assigned'
        ? 'Your Crave Courier has picked up your food!'
        : 'Hang tight, we are receiving your order.';
    final IconData icon = status == 'assigned' ? LucideIcons.truck : LucideIcons.loader;

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
}
