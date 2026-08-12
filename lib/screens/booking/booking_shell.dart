import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

/// Sidebar shell for the staff Booking Management System (spec section 18).
/// Desktop/tablet: fixed left sidebar. Mobile: drawer, so staff on a
/// phone still get every menu item without the layout breaking.
class BookingShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const BookingShell({super.key, required this.child, required this.currentRoute});

  static const _items = [
    _NavItem('Dashboard', Icons.dashboard_outlined, '/booking/dashboard'),
    _NavItem('Calendar', Icons.calendar_month_outlined, '/booking/calendar'),
    _NavItem('Bookings', Icons.event_note_outlined, '/booking/bookings'),
    _NavItem('Customers', Icons.people_outline, '/booking/customers'),
    _NavItem('Appointments', Icons.schedule_outlined, '/booking/appointments'),
    _NavItem('Payments', Icons.payments_outlined, '/booking/payments'),
    _NavItem('Reports', Icons.bar_chart_outlined, '/booking/reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = deviceTypeOf(context) != DeviceType.mobile;
    final sidebar = _Sidebar(currentRoute: currentRoute);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Public site',
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 230, child: sidebar),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final item in BookingShell._items)
            ListTile(
              leading: Icon(item.icon,
                  color: currentRoute == item.route ? AppColors.gold : Colors.white70),
              title: Text(item.label,
                  style: TextStyle(
                    color: currentRoute == item.route ? AppColors.gold : Colors.white70,
                    fontWeight: currentRoute == item.route ? FontWeight.bold : FontWeight.normal,
                  )),
              onTap: () {
                Navigator.of(context).maybePop();
                context.go(item.route);
              },
            ),
        ],
      ),
    );
  }
}
