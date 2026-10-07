import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/network_service.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell? navigationShell;
  final Widget? child;

  const MainLayout({
    super.key,
    this.navigationShell,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell?.currentIndex ?? 0;

    final isOnlineAsyncValue = ref.watch(networkServiceProvider);
    final isOnline = isOnlineAsyncValue.value ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: const Color(0xFFDC2626),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                bottom: 4,
              ),
              child: const Text(
                '⚠️  No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(child: navigationShell ?? child ?? const SizedBox.shrink()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                    currentIndex: currentIndex),
                _buildNavItem(context,
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history,
                    label: 'History',
                    index: 1,
                    currentIndex: currentIndex),
                _buildNavItem(context,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Account',
                    index: 2,
                    currentIndex: currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected ? const Color(0xFFFFC107) : const Color(0xFF6B7280);

    return InkWell(
      onTap: () {
        if (navigationShell != null) {
          navigationShell!.goBranch(
            index,
            initialLocation: index == navigationShell!.currentIndex,
          );
        } else {
          if (index == 0) context.go('/dashboard');
          else if (index == 1) context.go('/history');
          else if (index == 2) context.go('/account');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
