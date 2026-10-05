import 'package:flutter/material.dart';
import '../../models/bid_model.dart';
import '../../models/job_post_model.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_completion_banner.dart';
import '../../utils/verification_guard.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onNavigateTab;

  const WorkerDashboardScreen({
    super.key,
    this.onOpenDrawer,
    this.onNavigateTab,
  });

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    MySqlService().refreshData();
  }

  void _openBidModal(JobPostModel job) {
    if (!VerificationGuard.check(context, actionName: 'submit a bid on this job')) return;

    final priceCtrl = TextEditingController(text: '${job.budgetMin?.toInt() ?? 500}');
    final msgCtrl = TextEditingController();
    String duration = '1–2 hours';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.sbCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.sbLine, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Submit Job Bid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sbSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  job.title ?? 'Job Request',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Your Proposed Price (₱)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Estimated Duration', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.sbCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.sbLine, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: duration,
                    isExpanded: true,
                    items: ['1–2 hours', '2–3 hours', '1 day', '2–3 days']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => duration = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Message to Customer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: msgCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Why are you the best fit for this job?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: () async {
                  final price = double.tryParse(priceCtrl.text.trim()) ?? (job.budgetMin ?? 500.0);
                  final msg = msgCtrl.text.trim();
                  final currentUser = AuthService().currentUser;

                  final newBid = BidModel(
                    bidId: DateTime.now().millisecondsSinceEpoch % 100000,
                    jobPostId: job.jobPostId,
                    workerId: currentUser?.id ?? 0,
                    proposedPrice: price,
                    message: msg.isNotEmpty ? msg : 'Available to work on this job.',
                    estimatedDuration: duration,
                    status: 'pending',
                    createdAt: DateTime.now(),
                    worker: currentUser,
                  );

                  await MySqlService().placeBid(newBid);

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your bid has been submitted and saved to Firebase!'),
                        backgroundColor: AppTheme.sbBlue,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sbBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Submit Bid', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.sbInk3, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([MySqlService(), AuthService()]),
      builder: (context, _) {
        final currentUser = AuthService().currentUser;
        final userName = currentUser?.fullName ?? currentUser?.name ?? 'Worker';
        final currentUserId = currentUser?.id;
        final currentUserUid = currentUser?.uid;
        final currentUserEmail = currentUser?.email.toLowerCase().trim();
        final matchingProfiles = MySqlService().workerProfiles.where(
          (wp) => (currentUserId != null && currentUserId != 0 && wp.userId == currentUserId) ||
                  (currentUserUid != null && wp.user?.uid == currentUserUid),
        );
        final workerProfilePhoto = matchingProfiles.isNotEmpty ? matchingProfiles.first.photoUrl : null;
        final userPhotoUrl = (currentUser?.profilePhotoUrl != null && currentUser!.profilePhotoUrl!.isNotEmpty)
            ? currentUser.profilePhotoUrl
            : workerProfilePhoto;
        final userInitials = (userName.isNotEmpty && userName != 'Worker')
            ? userName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
            : 'W';

        final allBookings = MySqlService().bookings;

        final myWorkerProfiles = MySqlService().workerProfiles.where((wp) =>
            (currentUserId != null && currentUserId != 0 && wp.userId == currentUserId) ||
            (currentUserUid != null && currentUserUid.isNotEmpty && wp.user?.uid == currentUserUid) ||
            (currentUserEmail != null && currentUserEmail.isNotEmpty && wp.user?.email.toLowerCase().trim() == currentUserEmail)
        ).toList();
        final myWorkerProfileIds = myWorkerProfiles.map((wp) => wp.workerProfileId).toSet();
        final myWorkerUserIds = myWorkerProfiles.map((wp) => wp.userId).toSet();

        // Filter bookings belonging exclusively to this worker
        final myWorkerBookings = allBookings.where((b) {
          if (currentUser == null) return false;
          // 1. Direct match on workerId
          if (currentUserId != null && currentUserId != 0 && b.workerId == currentUserId) return true;
          if (myWorkerProfileIds.contains(b.workerId)) return true;
          if (myWorkerUserIds.contains(b.workerId)) return true;

          // 2. Direct match on workerUid
          if (currentUserUid != null && currentUserUid.isNotEmpty) {
            if (b.workerUid != null && b.workerUid == currentUserUid) return true;
            if (b.worker?.uid != null && b.worker!.uid == currentUserUid) return true;
          }

          // 3. Worker user model ID or email
          if (b.worker != null) {
            if (currentUserId != null && currentUserId != 0 && b.worker!.id == currentUserId) return true;
            if (currentUserEmail != null && currentUserEmail.isNotEmpty && b.worker!.email.toLowerCase().trim() == currentUserEmail) return true;
          }
          return false;
        }).toList();

        final pendingRequests = myWorkerBookings.where((b) => b.status == 'pending').toList();
        final completedJobs = myWorkerBookings.where((b) => b.status == 'completed').toList();
        final completedCount = completedJobs.length;
        final totalEarnings = completedJobs.fold<double>(0.0, (acc, b) => acc + (b.totalAmount ?? 0.0));
        final jobPosts = MySqlService().jobPosts.where((jp) => jp.status == 'open' || jp.status == 'in_review').toList();

        return Scaffold(
          backgroundColor: AppTheme.sbSurface,
          body: RefreshIndicator(
            onRefresh: () => MySqlService().refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
            // Header: homehead with availability switch
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.gHero,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -70,
                    top: -100,
                    child: Container(
                      width: 240,
                      height: 240,
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
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: widget.onOpenDrawer,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                                        ? Image.network(
                                            userPhotoUrl,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                userInitials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              userInitials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hello,',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('3 new requests')),
                                  );
                                },
                              ),
                              GestureDetector(
                                onTap: widget.onOpenDrawer,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                  ),
                                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const ProfileCompletionBanner(margin: EdgeInsets.only(top: 10)),
                          const SizedBox(height: 14),

                          // Availability Banner Switch
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isAvailable ? const Color(0xFF3BD07F) : Colors.grey,
                                    boxShadow: _isAvailable
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x663BD07F),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isAvailable ? 'Available for Bookings' : 'Offline / Unavailable',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _isAvailable ? 'Customers can discover and book your services' : 'Hidden from client searches and marketplace',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isAvailable,
                                  activeColor: AppTheme.sbSky,
                                  activeTrackColor: AppTheme.sbBlue,
                                  onChanged: (val) {
                                    setState(() => _isAvailable = val);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(val ? 'You are now available for bookings' : 'You are now offline'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Monthly Earnings Card with Bar Chart
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.sbCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.sbLine),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D0B1B33),
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Earnings This Month',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.sbInk,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Full earnings report')),
                                );
                              },
                              child: const Text(
                                'Full report',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.sbBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Weekly Bar Chart
                        SizedBox(
                          height: 110,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBarColumn('Wk 1', totalEarnings > 0 ? 45 : 0, isDim: true),
                              _buildBarColumn('Wk 2', totalEarnings > 0 ? 72 : 0),
                              _buildBarColumn('Wk 3', totalEarnings > 0 ? 58 : 0),
                              _buildBarColumn('Wk 4', totalEarnings > 0 ? 80 : 0),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppTheme.sbLine2),
                        const SizedBox(height: 14),

                        // Chart Total & Chip
                        Row(
                          children: [
                            Text(
                              '₱${totalEarnings.toInt()}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.sbInk,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: completedCount > 0 ? AppTheme.sbGreenSoft : AppTheme.sbCard,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                completedCount > 0 ? '↑ 18% vs last month' : '₱0 this month',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: completedCount > 0 ? AppTheme.sbGreen : AppTheme.sbInk4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mini stats cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppTheme.sbCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.sbLine),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$completedCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                              const SizedBox(height: 2),
                              const Text('Completed jobs', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.sbInk4)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppTheme.sbCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.sbLine),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(completedCount > 0 ? '5.0' : 'New', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                                  if (completedCount > 0) ...[
                                    const SizedBox(width: 3),
                                    const Icon(Icons.star_rounded, size: 16, color: AppTheme.sbYellowGreen),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text('Average rating', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.sbInk4)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            gradient: AppTheme.gBlue,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33148E4F), blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${pendingRequests.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(height: 2),
                              const Text('Pending requests', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Section: Booking requests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Booking Requests',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                      ),
                      GestureDetector(
                        onTap: () => widget.onNavigateTab?.call(1),
                        child: const Text(
                          'View all',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.sbBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (pendingRequests.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.sbCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.sbLine),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 36, color: AppTheme.sbInk4),
                            SizedBox(height: 8),
                            Text('No booking requests yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            SizedBox(height: 4),
                            Text(
                              'When clients request your services, they will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.sbInk4, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...pendingRequests.map((b) {
                      final cName = b.customer?.fullName ?? b.customer?.name ?? 'Client';
                      final cPhoto = b.customer?.profilePhotoUrl;
                      final cInitials = (cName.isNotEmpty) ? cName[0].toUpperCase() : 'C';
                      final sTitle = b.serviceName ?? b.categoryName ?? 'Service Request';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRequestCard(
                          initials: cInitials,
                          avatarColor: const Color(0xFF0B1B33),
                          name: cName,
                          photoUrl: cPhoto,
                          desc: '$sTitle · ${b.scheduledTime ?? 'Flexible'}',
                          chipText: b.isUrgent ? 'Urgent · Pending' : 'Pending',
                          chipColor: b.isUrgent ? AppTheme.sbRedSoft : AppTheme.sbBlueSoft,
                          chipTextColor: b.isUrgent ? AppTheme.sbRed : AppTheme.sbBlue,
                          onTap: () => widget.onNavigateTab?.call(1),
                        ),
                      );
                    }),
                  const SizedBox(height: 22),

                  // Section: Jobs Near You
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jobs Near You',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                      ),
                      GestureDetector(
                        onTap: () => widget.onNavigateTab?.call(2),
                        child: const Text(
                          'View all',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.sbBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (jobPosts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.sbCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.sbLine),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.work_outline_rounded, size: 36, color: AppTheme.sbInk4),
                            SizedBox(height: 8),
                            Text('No jobs posted yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            SizedBox(height: 4),
                            Text(
                              'When clients post jobs in your area, they will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.sbInk4, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...jobPosts.take(3).map((jp) {
                      final cName = jp.customer?.fullName ?? jp.customer?.name ?? 'Client';
                      final cPhoto = jp.customer?.profilePhotoUrl;
                      final cInitials = (cName.isNotEmpty) ? cName[0].toUpperCase() : 'C';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildQuickJobCard(
                          category: jp.categoryName ?? 'General',
                          tag: jp.urgency == 'urgent' ? 'Urgent' : 'Flexible',
                          tagColor: jp.urgency == 'urgent' ? AppTheme.sbRedSoft : AppTheme.sbAmberSoft,
                          tagTextColor: jp.urgency == 'urgent' ? AppTheme.sbRed : const Color(0xFFA55F00),
                          title: jp.title ?? 'Job Request',
                          meta: '${jp.locationAddress ?? (jp.city ?? 'Local Area')} · ${jp.status}',
                          budget: '₱${jp.budgetMin?.toInt() ?? 0} – ₱${jp.budgetMax?.toInt() ?? 0}',
                          customerPhoto: cPhoto,
                          customerName: cName,
                          customerInitials: cInitials,
                          onBid: () => _openBidModal(jp),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
},
);
}

  Widget _buildBarColumn(String label, int value, {bool isDim = false}) {
    final heightRatio = value / 80.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 70 * heightRatio,
            decoration: BoxDecoration(
              gradient: isDim
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFCDEEDA), Color(0xFFE9F7EF)],
                    )
                  : AppTheme.gBlue,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.sbInk4),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required String initials,
    required Color avatarColor,
    required String name,
    required String desc,
    required String chipText,
    required Color chipColor,
    required Color chipTextColor,
    required VoidCallback onTap,
    String? photoUrl,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.sbCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.sbLine),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        photoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.sbInk4, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      chipText,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: chipTextColor),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.sbInk4),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickJobCard({
    required String category,
    required String tag,
    required Color tagColor,
    required Color tagTextColor,
    required String title,
    required String meta,
    required String budget,
    required VoidCallback onBid,
    String? customerPhoto,
    String customerName = 'Client',
    String customerInitials = 'C',
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.sbCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.sbLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1B33),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (customerPhoto != null && customerPhoto.isNotEmpty)
                      ? Image.network(
                          customerPhoto,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              customerInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            customerInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sbInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.sbBlueSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.sbBlue),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tagTextColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.sbInk, height: 1.3),
          ),
          const SizedBox(height: 3),
          Text(meta, style: const TextStyle(fontSize: 11.5, color: AppTheme.sbInk4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(budget, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.sbBlue)),
                  const Text('Budget', style: TextStyle(fontSize: 10, color: AppTheme.sbInk4, fontWeight: FontWeight.w600)),
                ],
              ),
              ElevatedButton(
                onPressed: onBid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sbBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                child: const Text('Bid', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
