import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database_seeder.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_completion_modal.dart';
import '../customer/customer_main_screen.dart';
import '../landing_page_screen.dart';
import '../worker/worker_main_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ProfileScreen({super.key, this.onOpenDrawer});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingPhoto = false;
  bool _isDbPurging = false;
  bool _isDbSeeding = false;

  Future<void> _handlePickProfilePhoto() async {
    // Show source picker
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sbInk,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.sbGreen),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.sbGreen),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final result = await CloudinaryService().pickAndUploadImage(
        source: source,
        folder: 'serviko/profile_photos',
      );

      if (result != null) {
        final auth = AuthService();
        await auth.updateProfilePhoto(result.url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: AppTheme.sbGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.sbInk,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from your Serviko account?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.sbInkSoft,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.sbInkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPageScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully.'),
                    backgroundColor: AppTheme.sbInk,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSwitchRole(BuildContext context, String targetRole) {
    AuthService().switchDemoRole(targetRole);
    final destination = targetRole == 'worker'
        ? const WorkerMainScreen()
        : const CustomerMainScreen();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _confirmPurgeDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe to Clean Slate?'),
        content: const Text(
          'This will purge all Cloud Firestore test collections (users, workers, categories, bookings, job posts, messages, reviews) and reset caches for real CRUD testing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDbPurging = true);
    await DatabaseSeeder.clearAll();
    MySqlService().clearLocalCache();
    await MySqlService().refreshData();
    if (mounted) {
      setState(() => _isDbPurging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All collections purged! Database is now a 100% clean slate.'),
          backgroundColor: AppTheme.sbInk,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _runSeedDatabase(BuildContext context) async {
    setState(() => _isDbSeeding = true);
    await DatabaseSeeder.seedAll();
    await MySqlService().refreshData();
    if (mounted) {
      setState(() => _isDbSeeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample data successfully seeded to Cloud Firestore.'),
          backgroundColor: AppTheme.sbGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final auth = AuthService();
        final user = auth.currentUser;
        final isWorker = user?.isWorker ?? false;
        final photoUrl = user?.profilePhotoUrl;

        return Scaffold(
          backgroundColor: AppTheme.sbBg,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Hero Gradient Profile Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.gHero,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        children: [
                          // Header Nav bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
                                    tooltip: 'Sign Out',
                                    onPressed: () => _handleSignOut(context),
                                  ),
                                  if (widget.onOpenDrawer != null)
                                    IconButton(
                                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                                      onPressed: widget.onOpenDrawer,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Avatar with photo upload button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: photoUrl == null
                                      ? (isWorker ? AppTheme.gWarm : AppTheme.gBlue)
                                      : null,
                                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  image: photoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(photoUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: photoUrl == null
                                    ? Text(
                                        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              // "+" button to upload photo
                              GestureDetector(
                                onTap: _isUploadingPhoto ? null : _handlePickProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.sbGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0F1710), width: 2),
                                  ),
                                  child: _isUploadingPhoto
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Name and badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  (user?.displayName.isNotEmpty == true ? user!.displayName : null) ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?.isVerified == true) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),

                          Text(
                            (user?.email.isNotEmpty == true ? user!.email : null) ?? 'No email set',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Location and Role Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: AppTheme.sbGreen, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      user?.locationString ?? 'Location not set',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isWorker ? const Color(0xFFFDE68A).withOpacity(0.2) : AppTheme.sbGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isWorker ? const Color(0xFFFDE68A) : AppTheme.sbGreen,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isWorker ? 'PRO TRADESMAN' : 'CUSTOMER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isWorker ? const Color(0xFFFDE68A) : AppTheme.sbGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Body content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    children: [
                      // 4 Stats Cards in 2x2 Grid (pstat)
                      _buildStatsGrid(isWorker),
                      const SizedBox(height: 14),

                      // Role Switcher Card
                      _buildRoleSwitcher(context, isWorker),
                      const SizedBox(height: 14),

                      // Personal Information Card
                      _buildPersonalInfoCard(user),
                      const SizedBox(height: 14),

                      // Location Card
                      _buildLocationCard(user),
                      const SizedBox(height: 14),

                      // Professional Worker Card (if worker)
                      if (isWorker) ...[
                        _buildWorkerTradeCard(user),
                        const SizedBox(height: 14),
                      ],

                      // Verification Card
                      _buildVerificationCard(user),
                      const SizedBox(height: 14),

                      // Database Testing & CRUD Controls
                      _buildDatabaseToolsCard(context),
                      const SizedBox(height: 20),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSignOut(context),
                          icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFDC2626), size: 20),
                          label: const Text(
                            'Sign Out of Serviko',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: const Color(0xFFFEF2F2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(bool isWorker) {
    final allBookings = MySqlService().bookings;
    final user = AuthService().currentUser;
    final userId = user?.id;

    final userBookings = allBookings.where((b) {
      if (isWorker) {
        return b.workerId == userId || b.worker?.id == userId;
      } else {
        return b.customerId == userId || b.customer?.id == userId;
      }
    }).toList();

    final completedBookings = userBookings.where((b) => b.isCompleted || b.status.toLowerCase() == 'completed' || b.status.toLowerCase() == 'paid').toList();

    final stats = isWorker
        ? [
            {
              'val': '${completedBookings.length}',
              'lbl': 'Completed',
              'sub': 'successful tasks',
            },
            {
              'val': () {
                final earnings = completedBookings.fold<double>(0, (sum, b) => sum + (b.totalAmount ?? 0));
                if (earnings == 0) return '₱0';
                if (earnings >= 1000) return '₱${(earnings / 1000).toStringAsFixed(1)}k';
                return '₱${earnings.toInt()}';
              }(),
              'lbl': 'Earnings',
              'sub': 'total income',
            },
            {
              'val': completedBookings.isEmpty ? 'New' : '5.0 ★',
              'lbl': 'Rating',
              'sub': '${completedBookings.length} reviews',
            },
            {
              'val': userBookings.isEmpty
                  ? '0%'
                  : '${((completedBookings.length / userBookings.length) * 100).toInt()}%',
              'lbl': 'Completion',
              'sub': 'on-time rate',
            },
          ]
        : [
            {
              'val': '${userBookings.length}',
              'lbl': 'Bookings',
              'sub': 'total requests',
            },
            {
              'val': () {
                final spent = completedBookings.fold<double>(0, (sum, b) => sum + (b.totalAmount ?? 0));
                if (spent == 0) return '₱0';
                if (spent >= 1000) return '₱${(spent / 1000).toStringAsFixed(1)}k';
                return '₱${spent.toInt()}';
              }(),
              'lbl': 'Spent',
              'sub': 'services hired',
            },
            {
              'val': '5.0 ★',
              'lbl': 'Rating',
              'sub': 'as customer',
            },
            {
              'val': '${user?.memberSince?.year ?? DateTime.now().year}',
              'lbl': 'Member',
              'sub': 'joined year',
            },
          ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.sbLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s['val']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.sbInk,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s['lbl']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.sbInkSoft,
                ),
              ),
              Text(
                s['sub']!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.sbInkFaint,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleSwitcher(BuildContext context, bool isWorker) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.sbLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch Experience (Role Switcher)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.sbInk,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Test the app from Customer or Service Worker perspective:',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.sbInkSoft,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isWorker ? () => _handleSwitchRole(context, 'customer') : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: !isWorker ? const Color(0xFFF1F7F4) : AppTheme.sbField,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isWorker ? AppTheme.sbGreen : AppTheme.sbLine,
                        width: !isWorker ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: !isWorker ? AppTheme.sbGreen : AppTheme.sbInkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Customer View',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: !isWorker ? AppTheme.sbGreen : AppTheme.sbInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: !isWorker ? () => _handleSwitchRole(context, 'worker') : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isWorker ? const Color(0xFFF1F7F4) : AppTheme.sbField,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWorker ? AppTheme.sbGreen : AppTheme.sbLine,
                        width: isWorker ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.handyman_rounded,
                          size: 16,
                          color: isWorker ? AppTheme.sbGreen : AppTheme.sbInkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Worker View',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isWorker ? AppTheme.sbGreen : AppTheme.sbInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(dynamic user) {
    final name = (user?.displayName?.isNotEmpty == true ? user.displayName : user?.fullName)?.toString();
    final email = user?.email?.toString();
    final phone = user?.phoneNumber?.toString();

    return _buildSectionCard(
      title: 'Personal Information',
      icon: Icons.badge_outlined,
      children: [
        _buildInfoTile('Full Name', (name != null && name.isNotEmpty) ? name : 'Not specified', Icons.person_outline),
        const Divider(height: 16, color: AppTheme.sbLine),
        _buildInfoTile('Email Address', (email != null && email.isNotEmpty) ? email : 'Not set', Icons.email_outlined),
        const Divider(height: 16, color: AppTheme.sbLine),
        _buildInfoTile('Phone Number', (phone != null && phone.isNotEmpty) ? phone : 'Not specified', Icons.phone_outlined),
      ],
    );
  }

  Widget _buildLocationCard(dynamic user) {
    final city = user?.city?.toString();
    final brgy = user?.barangay?.toString();

    return _buildSectionCard(
      title: 'Location & Coverage',
      icon: Icons.place_outlined,
      children: [
        _buildInfoTile('City / Province', (city != null && city.isNotEmpty) ? city : 'Not specified', Icons.location_city_outlined),
        const Divider(height: 16, color: AppTheme.sbLine),
        _buildInfoTile('Barangay', (brgy != null && brgy.isNotEmpty) ? brgy : 'Not specified', Icons.signpost_outlined),
        const Divider(height: 16, color: AppTheme.sbLine),
        _buildInfoTile('Service Radius', '15 km from current location', Icons.radar_outlined),
      ],
    );
  }

  Widget _buildWorkerTradeCard(dynamic user) {
    final skill = user?.skill?.toString();

    return _buildSectionCard(
      title: 'Professional Trade Details',
      icon: Icons.engineering_outlined,
      children: [
        _buildInfoTile('Primary Skill', (skill != null && skill.isNotEmpty) ? skill : 'General Services', Icons.build_outlined),
        const Divider(height: 16, color: AppTheme.sbLine),
        _buildInfoTile('Base Rate', 'Standard Rate', Icons.payments_outlined),
        const Divider(height: 16, color: AppTheme.sbLine),
        _buildInfoTile('Experience', 'Verified Tradesman', Icons.history_edu_outlined),
      ],
    );
  }

  Widget _buildDatabaseToolsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.sbLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storage_rounded, color: Color(0xFF2563EB), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Database & CRUD Controls',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sbInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Control Firestore test collections directly. Purge anytime for a pristine clean slate, or seed on demand.',
            style: TextStyle(fontSize: 12, color: AppTheme.sbInkSoft, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDbPurging || _isDbSeeding ? null : () => _confirmPurgeDatabase(context),
                  icon: _isDbPurging
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text(
                    'Wipe Clean Slate',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDbPurging || _isDbSeeding ? null : () => _runSeedDatabase(context),
                  icon: _isDbSeeding
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sbGreen))
                      : const Icon(Icons.cloud_upload_rounded, size: 16, color: AppTheme.sbGreen),
                  label: const Text(
                    'Seed Sample Data',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.sbGreen),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.sbGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(dynamic user) {
    final isVerified = user?.isVerified == true;
    final progress = user != null ? (user is UserModel ? user.profileCompletionPercentage : (isVerified ? 100 : 30)) : 30;
    final hasPhoto = user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty;
    final hasPhone = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty;
    final hasLocation = (user?.city != null && user!.city!.isNotEmpty) || (user?.barangay != null && user!.barangay!.isNotEmpty);
    final hasId = isVerified || (user?.idNumber != null && user!.idNumber!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVerified ? AppTheme.sbGreen.withValues(alpha: 0.35) : const Color(0xFFFDE68A),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isVerified ? AppTheme.sbGreen.withValues(alpha: 0.12) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                  color: isVerified ? AppTheme.sbGreen : const Color(0xFFD97706),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isVerified ? 'Profile 100% Verified' : 'Verification Status: $progress%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.sbInk,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  isVerified ? 'VERIFIED' : 'UNVERIFIED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isVerified ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isVerified) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress / 100.0,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '⚠️ You cannot book services or create job offers until your profile is verified with valid government ID.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildCheckRow('Valid Government ID Document', hasId),
          const SizedBox(height: 8),
          _buildCheckRow('Verified Contact Number', hasPhone),
          const SizedBox(height: 8),
          _buildCheckRow('Location & Service Address', hasLocation),
          const SizedBox(height: 8),
          _buildCheckRow('Profile Portrait Photo', hasPhoto),
          if (!isVerified) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => showProfileCompletionModal(context),
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text(
                  'Complete & Verify Profile',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckRow(String title, bool isOk) {
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle_rounded : Icons.pending_outlined,
          color: isOk ? AppTheme.sbGreen : AppTheme.sbInkFaint,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOk ? AppTheme.sbInk : AppTheme.sbInkSoft,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.sbLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.sbField,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.sbInk, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sbInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.sbInkFaint),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.sbInkFaint,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.sbInk,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
