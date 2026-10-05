import 'package:flutter/material.dart';
import '../../models/bid_model.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/verification_guard.dart';

class JobMarketplaceScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const JobMarketplaceScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<JobMarketplaceScreen> createState() => _JobMarketplaceScreenState();
}

class _JobMarketplaceScreenState extends State<JobMarketplaceScreen> {
  String _selectedPill = 'All';

  // ---------------------------------------------------------------------------
  // SAMPLE JOB POSTINGS (COMMENTED OUT FOR CLEAN SLATE TESTING)
  // ---------------------------------------------------------------------------
  // static final List<Map<String, dynamic>> _sampleJobs = [
  //   {
  //     'cat': 'Electrical',
  //     'tag': 'Urgent',
  //     'tagColor': AppTheme.sbRedSoft,
  //     'tagTextColor': AppTheme.sbRed,
  //     'title': 'Need electrician ASAP — circuit breaker tripped',
  //     'meta': 'Agdao, Davao City · 30 minutes ago',
  //     'desc': 'Our circuit breaker stopped working last night. It tripped and won\'t reset. We need help this morning.',
  //     'budget': '₱500 – ₱800',
  //     'timing': 'Needed today',
  //   },
  //   {
  //     'cat': 'Electrical',
  //     'tag': 'Flexible',
  //     'tagColor': AppTheme.sbAmberSoft,
  //     'tagTextColor': const Color(0xFFA55F00),
  //     'title': 'Need electrician for new house — complete wiring',
  //     'meta': 'Mintal, Davao City · 2 hours ago',
  //     'desc': 'New house construction requiring complete wiring from the main electrical panel to outlets and switches across all rooms. 3-bedroom house.',
  //     'budget': '₱2,000 – ₱3,500',
  //     'timing': 'Needed Saturday',
  //   },
  //   {
  //     'cat': 'Electrical / Tech',
  //     'tag': 'This week',
  //     'tagColor': AppTheme.sbAmberSoft,
  //     'tagTextColor': const Color(0xFFA55F00),
  //     'title': 'CCTV installation — 4 cameras, indoor and outdoor',
  //     'meta': 'Lanang, Davao City · Posted yesterday',
  //     'desc': 'Looking to install 4 CCTV cameras around our home — 2 outdoor and 2 indoor. DVR unit is on hand, need installation and wiring setup.',
  //     'budget': '₱1,200 – ₱1,800',
  //     'timing': 'Flexible',
  //   },
  //   {
  //     'cat': 'Plumber',
  //     'tag': 'Urgent',
  //     'tagColor': AppTheme.sbRedSoft,
  //     'tagTextColor': AppTheme.sbRed,
  //     'title': 'Leaking pipe under kitchen sink and bathroom',
  //     'meta': 'Buhangin, Davao City · 3 hours ago',
  //     'desc': 'Heavy water leak under kitchen sink. Needs immediate replacement valve and pipe sealing.',
  //     'budget': '₱400 – ₱700',
  //     'timing': 'Needed today',
  //   },
  final List<Map<String, dynamic>> _protoJobs = [];

  @override
  void initState() {
    super.initState();
    MySqlService().refreshData();
  }

  void _openBidModal(Map<String, dynamic> job) {
    if (!VerificationGuard.check(context, actionName: 'submit a bid on this job')) return;

    final priceCtrl = TextEditingController(text: '650');
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
                  job['title'] as String,
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
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 500.0;
                  final msg = msgCtrl.text.trim();
                  final currentUser = AuthService().currentUser;

                  final newBid = BidModel(
                    bidId: DateTime.now().millisecondsSinceEpoch % 100000,
                    jobPostId: (job['job_post_id'] is int) ? job['job_post_id'] : 1,
                    workerId: currentUser?.id ?? 2,
                    proposedPrice: price,
                    message: msg.isNotEmpty ? msg : 'I can help with this job.',
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
      listenable: MySqlService(),
      builder: (context, _) {
        // Map dynamic database job posts from MySqlService / Firestore
        final dbJobs = MySqlService().jobPosts.map((jp) {
          final customer = jp.customer;
          final customerName = customer?.fullName ?? customer?.name ?? 'Client';
          final customerPhoto = customer?.profilePhotoUrl;
          final customerInitials = (customerName.isNotEmpty) ? customerName[0].toUpperCase() : 'C';

          return {
            'job_post_id': jp.jobPostId,
            'cat': jp.categoryName ?? 'General',
            'tag': jp.urgency == 'urgent' ? 'Urgent' : 'Flexible',
            'tagColor': jp.urgency == 'urgent' ? AppTheme.sbRedSoft : AppTheme.sbAmberSoft,
            'tagTextColor': jp.urgency == 'urgent' ? AppTheme.sbRed : const Color(0xFFA55F00),
            'title': jp.title ?? 'Job Request',
            'meta': '${jp.locationAddress ?? (jp.city ?? 'Local Area')} · ${jp.status}',
            'desc': jp.description ?? '',
            'budget': jp.budgetDisplay,
            'timing': jp.preferredDate != null ? 'Date: ${jp.preferredDate!.month}/${jp.preferredDate!.day}' : 'Flexible',
            'customer_name': customerName,
            'customer_photo': customerPhoto,
            'customer_initials': customerInitials,
          };
        });

        final allJobs = [..._protoJobs, ...dbJobs];

        final jobs = allJobs.where((j) {
          if (_selectedPill == 'All') return true;
          if (_selectedPill == 'Urgent') return j['tag'] == 'Urgent';
          return (j['cat'] as String).toLowerCase().contains(_selectedPill.toLowerCase());
        }).toList();

        return Scaffold(
          backgroundColor: AppTheme.sbSurface,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.90),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Jobs Near You',
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
                    const SnackBar(content: Text('Job notifications')),
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

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Electrical', 'Plumber', 'Carpenter', 'Urgent'].map((pill) {
                  final isSelected = _selectedPill == pill;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPill = pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.sbInk : AppTheme.sbCard,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isSelected ? AppTheme.sbInk : AppTheme.sbLine,
                          ),
                        ),
                        child: Text(
                          pill,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppTheme.sbInk3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Job List
            if (jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: const [
                    Icon(Icons.work_off_outlined, size: 48, color: AppTheme.sbInk4),
                    SizedBox(height: 8),
                    Text('No job postings yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('No active job requests right now. Create a new job post to see it here!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.sbInk4, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, idx) {
                final job = jobs[idx];
                return Container(
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
                      // Customer & Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1B33),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: (job['customer_photo'] != null && (job['customer_photo'] as String).isNotEmpty)
                                  ? Image.network(
                                      job['customer_photo'] as String,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          job['customer_initials'] as String? ?? 'C',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        job['customer_initials'] as String? ?? 'C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
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
                                Text(
                                  job['customer_name'] as String? ?? 'Client',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.sbInk,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sbBlueSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        job['cat'] as String,
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.sbBlue),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: job['tagColor'] as Color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        job['tag'] as String,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: job['tagTextColor'] as Color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        job['title'] as String,
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
                        job['meta'] as String,
                        style: const TextStyle(fontSize: 12, color: AppTheme.sbInk4, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      // Description Box
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppTheme.sbSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          job['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.sbInk3,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Footer: Budget & Mag-bid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['budget'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.sbBlue,
                                ),
                              ),
                              Text(
                                job['timing'] as String,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppTheme.sbInk4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => _openBidModal(job),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sbBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                            ),
                            child: const Text('Submit Bid', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
},
);
}
}
