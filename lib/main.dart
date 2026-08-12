import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/categories/category_list_screen.dart';
import 'screens/booking/booking_shell.dart';
import 'screens/booking/dashboard_screen.dart';
import 'screens/booking/booking_calendar_screen.dart';
import 'screens/booking/bookings_list_screen.dart';
import 'screens/booking/customers_screen.dart';
import 'screens/booking/appointments_screen.dart';
import 'screens/booking/payments_screen.dart';
import 'screens/booking/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fill in lib/config/supabase_config.dart with your project URL + anon key
  // before running. See README.md for the full setup checklist.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationService().init();

  runApp(const KKKKApp());
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    // Guard every /booking/* route behind staff/admin login.
    if (state.matchedLocation.startsWith('/booking')) {
      final role = await AuthService().currentRole();
      if (role == AppRole.guest) return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),

    GoRoute(
      path: '/pakej-perkahwinan',
      builder: (context, state) => const CategoryListScreen(pageKey: 'pakej_perkahwinan'),
    ),
    GoRoute(
      path: '/pelamin',
      builder: (context, state) => const CategoryListScreen(pageKey: 'pelamin'),
    ),
    GoRoute(
      path: '/baju-pengantin',
      builder: (context, state) => const CategoryListScreen(pageKey: 'baju_pengantin'),
    ),
    GoRoute(
      path: '/barang-pelamin',
      builder: (context, state) => const CategoryListScreen(pageKey: 'barang_pelamin'),
    ),
    GoRoute(
      path: '/dahlia',
      builder: (context, state) => const CategoryListScreen(pageKey: 'dahlia'),
    ),

    // Staff booking system — behind a persistent sidebar shell.
    GoRoute(
      path: '/booking/dashboard',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/dashboard', child: DashboardScreen()),
    ),
    GoRoute(
      path: '/booking/calendar',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/calendar', child: BookingCalendarScreen()),
    ),
    GoRoute(
      path: '/booking/bookings',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/bookings', child: BookingsListScreen()),
    ),
    GoRoute(
      path: '/booking/customers',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/customers', child: CustomersScreen()),
    ),
    GoRoute(
      path: '/booking/appointments',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/appointments', child: AppointmentsScreen()),
    ),
    GoRoute(
      path: '/booking/payments',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/payments', child: PaymentsScreen()),
    ),
    GoRoute(
      path: '/booking/reports',
      builder: (context, state) =>
          const BookingShell(currentRoute: '/booking/reports', child: ReportsScreen()),
    ),
  ],
);

class KKKKApp extends StatelessWidget {
  const KKKKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kerja Kahwin Kuala Kangsar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
