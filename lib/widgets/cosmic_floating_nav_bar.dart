import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Material navigation bar for the app's four primary observing spaces.
class CosmicNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const CosmicNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class CosmicPrimaryNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CosmicNavItem> items;

  const CosmicPrimaryNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AstroTrackColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AstroTrackColors.accentSoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          ),
      ],
    );
  }
}
