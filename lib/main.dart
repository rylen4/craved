import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';

import 'screens/launchpad_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/account_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/order_delivered_screen.dart';
import 'courier/courier_auth.dart';
import 'courier/courier_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CraveApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isSplash = state.matchedLocation == '/splash';
    final isGoingToAuth = state.matchedLocation == '/auth';
    final isCourierRoute = state.matchedLocation.startsWith('/courier');
    final isAdminRoute = state.matchedLocation.startsWith('/admin');
    final isLaunchpad = state.matchedLocation == '/launchpad';
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (isSplash || isLaunchpad || isCourierRoute || isAdminRoute) return null;

    if (!isLoggedIn && !isGoingToAuth) return '/auth';
    if (isLoggedIn && isGoingToAuth) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/launchpad', builder: (context, state) => const LaunchpadScreen()),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/menu/:id', builder: (context, state) => MenuScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(path: '/addresses', builder: (context, state) => const AddressesScreen()),
    GoRoute(
      path: '/tracking/:orderId',
      builder: (context, state) => OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(path: '/delivered', builder: (context, state) => const OrderDeliveredScreen()),
    GoRoute(path: '/courier/auth', builder: (context, state) => const CourierAuthScreen()),
    GoRoute(path: '/courier/home', builder: (context, state) => const CourierHomeScreen()),
  ],
);

class CraveApp extends StatelessWidget {
  const CraveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Crave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF52F2F5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
