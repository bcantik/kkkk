import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'responsive_layout.dart';

/// Public top bar: Logo (top-right per spec) · Home · Contact · Login.
/// Staff top bar (after login): Home · Contact(editable) · Calendar · Logout.
/// One widget, driven by [isStaffLoggedIn] so behaviour stays consistent
/// everywhere (HCI: consistency & predictability).
class KKKKTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isStaffLoggedIn;
  const KKKKTopBar({super.key, this.isStaffLoggedIn = false});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isMobile = deviceTypeOf(context) == DeviceType.mobile;

    final navItems = <Widget>[
      _NavButton(label: 'Home', onTap: () => context.go('/')),
      _NavButton(label: 'Contact', onTap: () => context.go('/contact')),
      if (isStaffLoggedIn) ...[
        _NavButton(label: 'Calendar', onTap: () => context.go('/booking/calendar')),
        _NavButton(
          label: 'Log Out',
          onTap: () async {
            await AuthService().signOut();
            if (context.mounted) context.go('/');
          },
        ),
      ] else
        _NavButton(label: 'Login', onTap: () => context.go('/login')),
    ];

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: const Row(
          children: [
            Text('KERJA KAHWIN', style: TextStyle(fontSize: 14, letterSpacing: 1)),
          ],
        ),
      ),
      actions: [
        if (isMobile)
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu),
            itemBuilder: (context) => List.generate(
              navItems.length,
              (i) => PopupMenuItem(value: i, child: navItems[i]),
            ),
          )
        else
          ...navItems,
        const SizedBox(width: 12),
        // Logo positioned top-right per spec
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Image.asset('assets/logo.png', height: 44),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(label),
    );
  }
}
