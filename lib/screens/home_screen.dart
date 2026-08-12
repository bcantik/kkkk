import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/top_bar.dart';
import '../widgets/responsive_layout.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

/// Public homepage — the one screen every visitor sees first. Six large,
/// unmistakable buttons routing to each section (HCI: recognition over
/// recall — icons + labels, no hidden menus for the core actions).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppRole _role = AppRole.guest;

  @override
  void initState() {
    super.initState();
    AuthService().currentRole().then((r) => setState(() => _role = r));
  }

  static const _buttons = [
    _HomeButtonData('Pakej Perkahwinan', Icons.card_giftcard, '/pakej-perkahwinan'),
    _HomeButtonData('Koleksi Pelamin', Icons.chair_alt, '/pelamin'),
    _HomeButtonData('Koleksi Baju Pengantin', Icons.checkroom, '/baju-pengantin'),
    _HomeButtonData('Barang Pelamin', Icons.inventory_2_outlined, '/barang-pelamin'),
    _HomeButtonData('Laman Dahlia', Icons.local_florist_outlined, '/dahlia'),
  ];

  @override
  Widget build(BuildContext context) {
    final isStaff = _role == AppRole.staff || _role == AppRole.admin || _role == AppRole.viewer;
    return Scaffold(
      appBar: KKKKTopBar(isStaffLoggedIn: _role != AppRole.guest),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ContentBounds(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 8),
              const Text(
                'Kerja Kahwin Kuala Kangsar',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Merancang majlis impian anda, dari awal hingga akhir.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ResponsiveGrid(
                maxTileWidth: 260,
                childAspectRatio: 1.1,
                children: [
                  for (final b in _buttons) _HomeButton(data: b),
                  if (isStaff)
                    const _HomeButton(
                      data: _HomeButtonData(
                          'Booking Jadual', Icons.event_available, '/booking/dashboard'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButtonData {
  final String label;
  final IconData icon;
  final String route;
  const _HomeButtonData(this.label, this.icon, this.route);
}

class _HomeButton extends StatelessWidget {
  final _HomeButtonData data;
  const _HomeButton({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(data.route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 40, color: AppColors.gold),
              const SizedBox(height: 12),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
