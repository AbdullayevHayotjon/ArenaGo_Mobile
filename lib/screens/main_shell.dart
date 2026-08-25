import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';
import 'favorite_fields_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final tabs = [
      HomeScreen(
        controller: widget.controller,
        onOpenFavorites: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  FavoriteFieldsScreen(controller: widget.controller),
            ),
          );
        },
      ),
      MapScreen(controller: widget.controller, isActive: _selectedIndex == 1),
      OrdersScreen(
        controller: widget.controller,
        isActive: _selectedIndex == 2,
      ),
      ProfileScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: _selectedIndex, children: tabs),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavigationBar(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
              items: [
                _NavigationItem(
                  Icons.home_outlined,
                  Icons.home_rounded,
                  s.t('navHome'),
                ),
                _NavigationItem(
                  Icons.map_outlined,
                  Icons.map_rounded,
                  s.t('navMap'),
                ),
                _NavigationItem(
                  Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded,
                  s.t('navOrders'),
                ),
                _NavigationItem(
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  s.t('navProfile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_NavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (dark ? AppColors.darkSurface : Colors.white).withValues(
                alpha: .92,
              ),
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: .09)
                    : Colors.white.withValues(alpha: .88),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .28 : .11),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = selectedIndex == index;
                return Expanded(
                  child: Semantics(
                    selected: selected,
                    button: true,
                    label: item.label,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(23),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(
                                  alpha: dark ? .20 : .12,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                selected ? item.selectedIcon : item.icon,
                                key: ValueKey(selected),
                                size: 23,
                                color: selected
                                    ? AppColors.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.primaryDark
                                      : scheme.onSurfaceVariant,
                                  fontSize: 10.5,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
