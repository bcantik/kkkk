import 'package:flutter/material.dart';

/// Central breakpoints so every screen agrees on desktop/tablet/mobile —
/// core HCI principle: consistency across the whole product.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

enum DeviceType { mobile, tablet, desktop }

DeviceType deviceTypeOf(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w < Breakpoints.mobile) return DeviceType.mobile;
  if (w < Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// Picks a different widget per breakpoint. Use for structurally
/// different layouts (e.g. sidebar vs bottom nav).
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  const ResponsiveLayout({super.key, required this.mobile, this.tablet, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final type = deviceTypeOf(context);
    if (type == DeviceType.desktop) return desktop;
    if (type == DeviceType.tablet) return tablet ?? desktop;
    return mobile;
  }
}

/// Responsive grid for card collections — adjusts column count by width
/// so cards never feel cramped on phones or sparse on desktop.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double maxTileWidth;
  final double spacing;
  final double childAspectRatio;
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.maxTileWidth = 300,
    this.spacing = 16,
    this.childAspectRatio = 0.78,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / maxTileWidth).floor().clamp(1, 6);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: children.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, i) => children[i],
      );
    });
  }
}

/// Constrains content width on very large desktop screens so text/cards
/// don't stretch edge-to-edge (readability — an HCI fundamental).
class ContentBounds extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentBounds({super.key, required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
