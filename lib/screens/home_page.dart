import 'package:flutter/material.dart';

import 'history_page.dart';
import 'map_page.dart';
import 'survey_form_page.dart';
import 'photo_history_page.dart';

//Nama Ariel Khan NIM V126241001

// Data model for a nav item

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  static const _navItems = [
    _NavItem(icon: Icons.map_rounded, label: 'Peta'),
    _NavItem(icon: Icons.edit_location_alt_rounded, label: 'Survei'),
    _NavItem(icon: Icons.history_rounded, label: 'Riwayat'),
    _NavItem(icon: Icons.photo_library_rounded, label: 'Foto')
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    _animationController.forward(from: 0);
    setState(() => _currentIndex = index);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const MapPage();
      case 1:
        return const SurveyFormPage();
      case 2:
        return const HistoryPage();
      default:
        return const PhotoHistoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mobile GIS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _TopNavBar(
            items: _navItems,
            selectedIndex: _currentIndex,
            onTap: _onTabSelected,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildPage(_currentIndex),
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _TopNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final trackColor = Color.alphaBlend(
      colorScheme.onSurface.withAlpha(20),
      colorScheme.surface,
    );
    final shadowColor = colorScheme.primary.withAlpha(46);

    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        items[index].icon,
                        key: ValueKey(selected),
                        size: 20,
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                items[index].label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
