import 'package:flutter/material.dart';
import 'package:clinicbackend/services/supabase_service.dart';
import 'package:clinicbackend/views/login_screen.dart';
import 'package:clinicbackend/views/dashboard_screen.dart';
import 'package:clinicbackend/views/doctor_management_screen.dart';
import 'package:clinicbackend/views/service_management_screen.dart';
import 'package:clinicbackend/views/user_management_screen.dart';

/// The main admin layout with a fixed Sidebar on the left
/// and a dynamic content area on the right.
/// Responsive: collapses sidebar into a Drawer below 900px.
class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Bảng điều khiển',
    ),
    _NavItem(
      icon: Icons.medical_services_rounded,
      label: 'Quản lý Bác sĩ',
    ),
    _NavItem(
      icon: Icons.miscellaneous_services_rounded,
      label: 'Quản lý Dịch vụ',
    ),
    _NavItem(
      icon: Icons.people_alt_rounded,
      label: 'Quản lý Người dùng',
    ),
  ];

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const DoctorManagementScreen();
      case 2:
        return const ServiceManagementScreen();
      case 3:
        return const UserManagementScreen();
      default:
        return const DashboardScreen();
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.logout_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 40,
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await SupabaseService.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đăng xuất thất bại. Vui lòng thử lại.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  // ─── Sidebar Widget ────────────────────────────────────────────

  Widget _buildSidebar({bool isDrawer = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = SupabaseService.instance.currentUser;

    return Container(
      width: 280,
      color: colorScheme.surface,
      child: Column(
        children: [
          // ─── Brand Header ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serene Health',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Trang quản trị',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // User info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quản trị viên',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              user?.email ?? 'admin@serenehealth.vn',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Menu Label ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU CHÍNH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─── Navigation Items ────────────────────────────────
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = _selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : Colors.transparent,
                      border: isSelected
                          ? Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // ─── Divider ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),

          // ─── Sign Out ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _handleSignOut,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 22, color: colorScheme.error),
                      const SizedBox(width: 14),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      // Drawer for narrow screens
      drawer: isWide ? null : Drawer(child: _buildSidebar(isDrawer: true)),
      body: Row(
        children: [
          // Sidebar visible only on wide screens
          if (isWide)
            Material(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: _buildSidebar(),
            ),

          // ─── Main Content Area ────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ─── Top Navbar ─────────────────────────────────
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Hamburger for narrow screens
                      if (!isWide)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          tooltip: 'Menu',
                        ),
                      if (!isWide) const SizedBox(width: 8),

                      // Page title
                      Text(
                        _navItems[_selectedIndex].label,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),

                      const Spacer(),

                      // Date display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              _formattedDate(),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Page Content ───────────────────────────────
                Expanded(
                  child: Container(
                    color: colorScheme.surfaceContainerLow,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
    ];
    final weekday = weekdays[now.weekday - 1];
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$weekday, $day/$month/${now.year}';
  }
}

/// Simple data class for navigation items
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
