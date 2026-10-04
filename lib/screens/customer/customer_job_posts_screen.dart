import 'package:flutter/material.dart';
import '../../models/job_post_model.dart';
import '../../models/bid_model.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/verification_guard.dart';
import '../chat/conversation_screen.dart';

class CustomerJobPostsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const CustomerJobPostsScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<CustomerJobPostsScreen> createState() => _CustomerJobPostsScreenState();
}

class _CustomerJobPostsScreenState extends State<CustomerJobPostsScreen> {
  int _selectedSeg = 0; // 0: Open, 1: Hired, 2: Closed

  @override
  void initState() {
    super.initState();
    MySqlService().refreshData();
  }

  void _openCreateJobModal() {
    if (!VerificationGuard.check(context, actionName: 'create a job post')) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String urgency = 'Urgent';
    String skill = 'Plumber';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
              const Text(
                'Post a New Job',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
              ),
              const SizedBox(height: 14),

              const Text('Job Title', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Need a plumber for a leaking kitchen sink',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Skill Required', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
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
                              value: skill,
                              isExpanded: true,
                              items: ['Plumber', 'Electrician', 'Carpenter', 'House Cleaner', 'Aircon Tech', 'Painter']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => skill = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Timeline', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
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
                              value: urgency,
                              isExpanded: true,
                              items: ['Urgent', 'Flexible', 'This week']
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => urgency = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Budget (₱)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. 500 – 1000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Description', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Describe full job details and requirements',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final desc = descCtrl.text.trim();
                  final budgetText = budgetCtrl.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a job title')),
                    );
                    return;
                  }

                  final budget = double.tryParse(budgetText) ?? 500.0;
                  final currentUser = AuthService().currentUser;
                  final newPost = JobPostModel(
                    jobPostId: DateTime.now().millisecondsSinceEpoch % 100000,
                    customerId: currentUser?.id ?? 1,
                    title: title,
                    description: desc,
                    locationAddress: currentUser?.locationString ?? 'Local Area',
                    city: currentUser?.city ?? 'Local City',
                    barangay: currentUser?.barangay ?? 'Barangay',
                    budgetMin: budget,
                    budgetMax: budget * 1.5,
                    urgency: urgency.toLowerCase(),
                    status: 'open',
                    createdAt: DateTime.now(),
                    customer: currentUser,
                    categoryName: skill,
                  );

                  await MySqlService().createJobPost(newPost);
                  setState(() {});

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New job posted successfully and saved to Firebase!'),
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
                child: const Text('Post Job', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
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
      listenable: MySqlService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.sbSurface,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.90),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'My Job Posts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.sbInk,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.sbInk),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job post notifications')),
                  );
                },
              ),
              if (widget.onOpenDrawer != null)
                GestureDetector(
                  onTap: widget.onOpenDrawer,
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.sbInk,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppTheme.sbLine2, height: 1),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => MySqlService().refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
          children: [

            // Post new job button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openCreateJobModal,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33148E4F),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Post a New Job',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Segmented Pills
            Builder(
              builder: (context) {
                final allPosts = MySqlService().jobPosts;
                final openCount = allPosts.where((p) => p.status == 'open' || p.status == 'in_review').length;
                final hiredCount = allPosts.where((p) => p.status == 'hired').length;
                final closedCount = allPosts.where((p) => p.status == 'closed' || p.status == 'completed').length;

                return Row(
                  children: [
                    _buildSegButton(0, 'Open', badge: openCount > 0 ? '$openCount' : null),
                    const SizedBox(width: 8),
                    _buildSegButton(1, 'Hired', badge: hiredCount > 0 ? '$hiredCount' : null),
                    const SizedBox(width: 8),
                    _buildSegButton(2, 'Closed', badge: closedCount > 0 ? '$closedCount' : null),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Tab Panels
            if (_selectedSeg == 0) _buildOpenPanel(),
            if (_selectedSeg == 1) _buildHiredPanel(),
            if (_selectedSeg == 2) _buildClosedPanel(),
          ],
        ),
      ),
    ),
  );
},
);
}

  Widget _buildSegButton(int index, String label, {String? badge}) {
    final isSelected = _selectedSeg == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedSeg = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sbInk : AppTheme.sbCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? AppTheme.sbInk : AppTheme.sbLine,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.sbInk3,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white70 : AppTheme.sbInk4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 50, color: AppTheme.sbInk4),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.sbInk4, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPostModelCard(JobPostModel p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildJobCard(
        post: p,
        category: p.categoryName ?? 'General',
        urgencyChip: p.urgency == 'urgent' ? 'Urgent' : (p.urgency == 'this_week' ? 'This Week' : null),
        urgencyColor: p.urgency == 'urgent' ? AppTheme.sbRedSoft : AppTheme.sbAmberSoft,
        urgencyTextColor: p.urgency == 'urgent' ? AppTheme.sbRed : const Color(0xFFA55F00),
        statusChip: p.status.isNotEmpty ? (p.status[0].toUpperCase() + p.status.substring(1)) : 'Open',
        title: p.title ?? 'Job Request',
        meta: '${p.locationAddress ?? (p.city ?? 'Local Area')} · Posted ${p.createdAt != null ? '${p.createdAt!.month}/${p.createdAt!.day}/${p.createdAt!.year}' : 'Recently'}',
        budget: p.budgetDisplay,
        bidsCount: p.bids.isNotEmpty ? '${p.bids.length} bid${p.bids.length == 1 ? '' : 's'}' : null,
        bids: p.bids.map((b) => {
          'i': (b.worker?.name.isNotEmpty == true ? b.worker!.name[0].toUpperCase() : 'W'),
          'c': const Color(0xFF1B9457),
          'n': b.worker?.fullName ?? (b.worker?.name ?? 'Worker'),
          'q': b.message ?? 'Available for this job',
          'p': b.proposedPrice != null ? '₱${b.proposedPrice!.toInt()}' : 'Negotiable',
        }).toList(),
      ),
    );
  }

  Widget _buildOpenPanel() {
    final posts = MySqlService().jobPosts.where((p) => p.status == 'open' || p.status == 'in_review').toList();
    if (posts.isEmpty) {
      return _buildEmptyState('No open job posts', 'Post a job to get competitive bids from verified workers near you.', Icons.work_outline_rounded);
    }
    return Column(
      children: posts.map((p) => _buildPostModelCard(p)).toList(),
    );
  }

  Widget _buildHiredPanel() {
    final posts = MySqlService().jobPosts.where((p) => p.status == 'hired').toList();
    if (posts.isEmpty) {
      return _buildEmptyState('No hired workers yet', 'Jobs with assigned contractors will appear here.', Icons.assignment_turned_in_outlined);
    }
    return Column(
      children: posts.map((p) => _buildPostModelCard(p)).toList(),
    );
  }

  Widget _buildClosedPanel() {
    final posts = MySqlService().jobPosts.where((p) => p.status == 'closed' || p.status == 'completed').toList();
    if (posts.isEmpty) {
      return _buildEmptyState('No closed posts', 'Job posts that have been completed or closed will appear here.', Icons.inventory_2_outlined);
    }
    return Column(
      children: posts.map((p) => _buildPostModelCard(p)).toList(),
    );
  }

  Widget _buildJobCard({
    JobPostModel? post,
    required String category,
    String? urgencyChip,
    Color urgencyColor = AppTheme.sbAmberSoft,
    Color urgencyTextColor = Colors.black,
    required String statusChip,
    required String title,
    required String meta,
    required String budget,
    String? bidsCount,
    required List<Map<String, dynamic>> bids,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: post != null ? () => _showBidsModal(context, post) : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.sbCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.sbLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0B1B33),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header chips
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.sbBlueSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.sbBlue),
                    ),
                  ),
                  if (urgencyChip != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        urgencyChip,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: urgencyTextColor),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusChip == 'Open' ? AppTheme.sbGreenSoft : AppTheme.sbLine2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      statusChip,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusChip == 'Open' ? AppTheme.sbGreen : AppTheme.sbInk3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sbInk,
                  height: 1.35,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: const TextStyle(fontSize: 12, color: AppTheme.sbInk4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),

              // Footer: budget & bids count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.sbBlue,
                        ),
                      ),
                      const Text('Budget', style: TextStyle(fontSize: 10.5, color: AppTheme.sbInk4, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (bidsCount != null)
                    GestureDetector(
                      onTap: post != null ? () => _showBidsModal(context, post) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.sbBlueSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.sbBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.sbBlue),
                            const SizedBox(width: 5),
                            Text(
                              bidsCount,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.sbBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Bid items preview
              if (bids.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...bids.map((b) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppTheme.sbSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: b['c'] as Color,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(
                            b['i'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['n'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              b['q'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.sbInk4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b['p'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.sbBlue),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
                  label: Text(
                    'View All Proposals (${bids.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: post != null ? () => _showBidsModal(context, post) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sbBlue,
                    side: BorderSide(color: AppTheme.sbBlue.withOpacity(0.4), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(double.infinity, 42),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.sbSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 15, color: AppTheme.sbInk4),
                      SizedBox(width: 8),
                      Text(
                        'Waiting for worker proposals...',
                        style: TextStyle(fontSize: 12, color: AppTheme.sbInk4, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBidsModal(BuildContext context, JobPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.sbCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.sbLine,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title ?? 'Job Proposals',
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.sbInk,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${post.bids.length} proposal${post.bids.length == 1 ? '' : 's'} received • Budget: ${post.budgetDisplay}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.sbInk4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.sbInkSoft),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.sbLine2),

              // Bids list or empty state
              Expanded(
                child: post.bids.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.hourglass_empty_rounded, size: 48, color: AppTheme.sbInk4),
                              SizedBox(height: 14),
                              Text(
                                'No proposals yet',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Workers in your area are reviewing your job post. Proposals will appear here as soon as workers submit their bids.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppTheme.sbInk4, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                        itemCount: post.bids.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, idx) {
                          final bid = post.bids[idx];
                          final worker = bid.worker;
                          final workerName = worker?.fullName ?? worker?.name ?? 'Worker';
                          final workerSkill = worker?.skill ?? 'Specialist';
                          final initials = workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W';
                          final isAccepted = bid.status.toLowerCase() == 'accepted';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isAccepted ? const Color(0xFFF0FDF4) : AppTheme.sbSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAccepted ? AppTheme.sbGreen : AppTheme.sbLine,
                                width: isAccepted ? 1.5 : 1,
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
                                // Worker row
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.gBlue,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workerName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.sbInk,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            workerSkill,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.sbInk4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          bid.formattedPrice,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.sbBlue,
                                          ),
                                        ),
                                        Text(
                                          bid.estimatedDuration != null ? '⏱️ ${bid.estimatedDuration}' : 'Flexible',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.sbInk4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Bid message box
                                if (bid.message != null && bid.message!.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.sbLine),
                                    ),
                                    child: Text(
                                      '"${bid.message}"',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.sbInk2,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 14),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                        label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ConversationScreen(
                                                otherUserId: bid.workerId,
                                                otherUserName: workerName,
                                                serviceTitle: post.title,
                                              ),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.sbInk2,
                                          side: const BorderSide(color: AppTheme.sbLine, width: 1.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: isAccepted
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              decoration: BoxDecoration(
                                                color: AppTheme.sbGreenSoft,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.sbGreen),
                                                  SizedBox(width: 6),
                                                  Text('Hired', style: TextStyle(color: AppTheme.sbGreen, fontWeight: FontWeight.w800)),
                                                ],
                                              ),
                                            )
                                          : ElevatedButton.icon(
                                              icon: const Icon(Icons.check_rounded, size: 17),
                                              label: const Text('Accept Bid', style: TextStyle(fontWeight: FontWeight.w800)),
                                              onPressed: () => _confirmAcceptBid(context, post, bid),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.sbGreen,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAcceptBid(BuildContext context, JobPostModel post, BidModel bid) {
    final workerName = bid.worker?.fullName ?? bid.worker?.name ?? 'this worker';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accept Proposal?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Do you want to accept $workerName\'s bid for ${bid.formattedPrice}?\n\nThis will assign this job to $workerName and create a confirmed booking.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.sbInk4, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sbGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx); // close dialog
              Navigator.pop(context); // close sheet

              // Create confirmed booking
              final newBooking = BookingModel(
                bookingId: DateTime.now().millisecondsSinceEpoch % 100000,
                customerId: post.customerId,
                workerId: bid.workerId,
                categoryId: post.categoryId,
                serviceAddress: post.locationAddress ?? post.city ?? 'Local Area',
                jobDescription: post.description,
                status: 'accepted',
                isUrgent: post.urgency == 'urgent',
                totalAmount: bid.proposedPrice,
                createdAt: DateTime.now(),
                serviceName: post.title,
                categoryName: post.categoryName,
                customer: post.customer ?? AuthService().currentUser,
                worker: bid.worker,
              );

              await MySqlService().createBooking(newBooking);
              await FirestoreService().updateJobPostStatus(post.jobPostId, 'hired');
              await FirestoreService().updateBidStatus(bid.bidId, 'accepted');
              await MySqlService().refreshData();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bid accepted! Booking created with $workerName.'),
                    backgroundColor: AppTheme.sbGreen,
                  ),
                );
              }
            },
            child: const Text('Confirm & Hire', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
