import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../landing_page_screen.dart';
import '../profile/profile_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_job_posts_screen.dart';
import 'explore_services_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  final int initialIndex;

  const CustomerMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CustomerMainScreen> createState() => CustomerMainScreenState();
}

class CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) {
    setState(() => _currentIndex = index);
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([MySqlService(), AuthService()]),
      builder: (context, _) {
        final auth = AuthService();
        final user = auth.currentUser;
        final userName = user?.fullName ?? user?.name ?? 'User';
        final currentUserId = user?.id;
        final currentUserUid = user?.uid;
        final currentUserEmail = user?.email.toLowerCase().trim();

        final activeBookingsCount = MySqlService().bookings.where((b) {
          if (user == null) return false;
          if (b.status != 'pending' && b.status != 'accepted' && b.status != 'in_progress') return false;
          if (currentUserId != null && currentUserId != 0 && b.customerId == currentUserId) return true;
          if (b.customer != null) {
            if (currentUserId != null && currentUserId != 0 && b.customer!.id == currentUserId) return true;
            if (currentUserUid != null && currentUserUid.isNotEmpty && b.customer!.uid == currentUserUid) return true;
            if (currentUserEmail != null && currentUserEmail.isNotEmpty && b.customer!.email.toLowerCase().trim() == currentUserEmail) return true;
          }
          return false;
        }).length;

        final screens = [
          ExploreServicesScreen(onOpenDrawer: openDrawer, onNavigateTab: setTab),
          CustomerBookingsScreen(onOpenDrawer: openDrawer),
          CustomerJobPostsScreen(onOpenDrawer: openDrawer),
          ChatListScreen(onOpenDrawer: openDrawer),
          ProfileScreen(onOpenDrawer: openDrawer),
        ];

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.sbSurface,
          endDrawer: _buildDrawer(context, userName),
          body: Stack(
            children: [
              // Current Tab Page
              Positioned.fill(
                bottom: 74, // space for floating bottom tab bar
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),

              // Floating Glass Bottom Tab Bar
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: StreamBuilder<List<MessageModel>>(
                  stream: FirestoreService().getAllMessagesStream(),
                  builder: (context, msgSnap) {
                    final allMsgs = msgSnap.data ?? MySqlService().messages;
                    final currentUserIdNum = user?.id ?? 0;
                    final unreadChatCount = currentUserIdNum != 0
                        ? allMsgs.where((m) => m.receiverId == currentUserIdNum && !m.isRead).length
                        : 0;
                    return _buildBottomBar(activeBookingsCount, unreadChatCount);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(int activeBookingsCount, int unreadChatCount) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0F0A), Color(0xFF111C15)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D0B1B33),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(0, Icons.home_rounded, 'Home'),
          _buildTabItem(1, Icons.calendar_today_rounded, 'Bookings', badgeCount: activeBookingsCount),
          _buildTabItem(2, Icons.add_rounded, 'Post'),
          _buildTabItem(3, Icons.chat_bubble_rounded, 'Chat', badgeCount: unreadChatCount),
          _buildTabItem(4, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setTab(index),
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Positioned(
                  top: 7,
                  child: Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.sbSky,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? AppTheme.sbSky : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.sbSky : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 7,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.sbYellowGreen,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFF10140F), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Color(0xFF0F1710),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setTab(index),
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -16,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gBlue,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF0A0F0A), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66148E4F),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.sbSky : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String userName) {
    return Drawer(
      backgroundColor: AppTheme.sbCard,
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 16, 22),
            decoration: const BoxDecoration(
              gradient: AppTheme.gHero,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -60,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3FD483).withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: const Center(
                            child: Text(
                              'JD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Customer · Matina, Davao City',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '★ 5.0',
                            style: TextStyle(
                              color: AppTheme.sbAmber,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '12 reviews',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Drawer Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.sbInk4,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setTab(0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'My Bookings',
                  pill: '2',
                  isSelected: _currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setTab(1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  pill: '4',
                  isSelected: _currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    setTab(3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.post_add_rounded,
                  label: 'My Job Posts',
                  isSelected: _currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setTab(2);
                  },
                ),
                const Divider(height: 24, color: AppTheme.sbLine2),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.sbInk4,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 4,
                  onTap: () {
                    Navigator.pop(context);
                    setTab(4);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    setTab(4); // Profile / Settings
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help Center',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help Center opened')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shield_outlined,
                  label: 'Privacy & Security',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Drawer Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _confirmSignOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sbRedSoft,
                  foregroundColor: AppTheme.sbRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    String? pill,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: isSelected ? AppTheme.sbBlueSoft : Colors.transparent,
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? AppTheme.sbBlue : AppTheme.sbInk3,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppTheme.sbBlue : AppTheme.sbInk2,
        ),
      ),
      trailing: pill != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.gWarm,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                pill,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out from Serviko?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingPageScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sbRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
