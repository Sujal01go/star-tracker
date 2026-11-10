import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Four primary observing spaces shown in a compact, connected navigation rail.
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AstroTrackColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AstroTrackColors.line, width: 1),
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  flex: currentIndex == index ? 3 : 2,
                  child: _Destination(
                    item: items[index],
                    selected: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  final CosmicNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _Destination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AstroTrackColors.background
        : AstroTrackColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 0),
              decoration: BoxDecoration(
                color: selected ? AstroTrackColors.action : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 21,
                    color: color,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
