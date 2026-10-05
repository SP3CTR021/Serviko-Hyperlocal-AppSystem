import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../chat/conversation_screen.dart';
import '../../widgets/booking_completion_modal.dart';

class WorkerBookingsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const WorkerBookingsScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen> {
  int _selectedSeg = 0; // 0: Pending, 1: Active, 2: Completed

  @override
  void initState() {
    super.initState();
    MySqlService().refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([MySqlService(), AuthService()]),
      builder: (context, _) {
        final currentUser = AuthService().currentUser;
        final currentUserId = currentUser?.id;
        final currentUserUid = currentUser?.uid;
        final currentUserEmail = currentUser?.email.toLowerCase().trim();

        final myWorkerProfiles = MySqlService().workerProfiles.where((wp) =>
            (currentUserId != null && currentUserId != 0 && wp.userId == currentUserId) ||
            (currentUserUid != null && currentUserUid.isNotEmpty && wp.user?.uid == currentUserUid) ||
            (currentUserEmail != null && currentUserEmail.isNotEmpty && wp.user?.email.toLowerCase().trim() == currentUserEmail)
        ).toList();
        final myWorkerProfileIds = myWorkerProfiles.map((wp) => wp.workerProfileId).toSet();
        final myWorkerUserIds = myWorkerProfiles.map((wp) => wp.userId).toSet();

        final myWorkerBookings = MySqlService().bookings.where((b) {
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

        final pendingBookings = myWorkerBookings.where((b) => b.status == 'pending').toList();
        final activeBookings = myWorkerBookings.where((b) =>
            b.status == 'accepted' || b.status == 'in_progress' || b.status == 'active' || b.status == 'confirmed'
        ).toList();
        final completedBookings = myWorkerBookings.where((b) => b.status == 'completed').toList();

        return Scaffold(
          backgroundColor: AppTheme.sbSurface,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.90),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Bookings',
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
                    const SnackBar(content: Text('Booking notifications')),
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
                  // Segmented Pills
                  Row(
                    children: [
                      _buildSegButton(0, 'Pending', badge: pendingBookings.isNotEmpty ? '${pendingBookings.length}' : null),
                      const SizedBox(width: 8),
                      _buildSegButton(1, 'Active', badge: activeBookings.isNotEmpty ? '${activeBookings.length}' : null),
                      const SizedBox(width: 8),
                      _buildSegButton(2, 'Completed', badge: completedBookings.isNotEmpty ? '${completedBookings.length}' : null),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tab Panels
                  if (_selectedSeg == 0) _buildPendingPanel(pendingBookings),
                  if (_selectedSeg == 1) _buildActivePanel(activeBookings, pendingBookings),
                  if (_selectedSeg == 2) _buildDonePanel(completedBookings),
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

  Widget _buildPendingCard(dynamic b) {
    final customerName = b.customer?.fullName ?? b.customer?.name ?? 'Customer';
    final customerPhoto = b.customer?.profilePhotoUrl;
    final initials = (customerName.isNotEmpty) ? customerName[0].toUpperCase() : 'C';
    final serviceTitle = b.serviceName ?? b.categoryName ?? 'Service Request';
    return _buildBookingCard(
      statusBarText: 'New request · Response needed',
      statusBarGradient: AppTheme.gWarm,
      statusBarTextColor: const Color(0xFF4A2A00),
      customerName: customerName,
      customerPhoto: customerPhoto,
      customerTag: b.isUrgent ? 'Urgent' : 'Standard',
      customerTagColor: b.isUrgent ? AppTheme.sbRedSoft : AppTheme.sbBlueSoft,
      customerTagTextColor: b.isUrgent ? AppTheme.sbRed : AppTheme.sbBlue,
      customerInitials: initials,
      avatarColor: const Color(0xFF0B1B33),
      amount: '₱${(b.totalAmount ?? 0).toInt()}',
      kv: {
        'Service': serviceTitle,
        'Date': b.scheduledDate != null ? '${b.scheduledDate!.month}/${b.scheduledDate!.day}/${b.scheduledDate!.year}' : 'Flexible',
        'Time': b.scheduledTime ?? '9:00 AM',
        'Location': b.serviceAddress ?? 'Local Area',
      },
      quote: b.jobDescription ?? 'Client requested this service.',
      actions: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await MySqlService().updateBookingStatus(b.bookingId, 'cancelled');
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sbRedSoft,
              foregroundColor: AppTheme.sbRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    otherUserId: b.customerId,
                    otherUserName: customerName,
                    serviceTitle: serviceTitle,
                    booking: b,
                    otherUserPhoto: customerPhoto,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.sbInk2,
              side: const BorderSide(color: AppTheme.sbLine, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await MySqlService().updateBookingStatus(b.bookingId, 'accepted');
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sbBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingPanel(List<dynamic> pendingBookings) {
    if (pendingBookings.isEmpty) {
      return _buildEmptyState('No pending requests', 'Incoming requests from clients will appear here.', Icons.hourglass_empty_rounded);
    }
    return Column(
      children: pendingBookings.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildPendingCard(b),
        );
      }).toList(),
    );
  }

  Widget _buildActivePanel(List<dynamic> activeBookings, List<dynamic> pendingBookings) {
    if (activeBookings.isEmpty && pendingBookings.isEmpty) {
      return _buildEmptyState('No active bookings', 'Accepted bookings in progress will appear here.', Icons.event_available_outlined);
    }
    return Column(
      children: [
        if (pendingBookings.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF92400E), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pendingBookings.length} Incoming Booking Request${pendingBookings.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Clients requested to book you! Accept below to start the job.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...pendingBookings.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildPendingCard(b),
          )),
          if (activeBookings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Jobs In Progress',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.sbGreenSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${activeBookings.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.sbGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
        ...activeBookings.map((b) {
          final customerName = b.customer?.fullName ?? b.customer?.name ?? 'Customer';
          final customerPhoto = b.customer?.profilePhotoUrl;
          final initials = (customerName.isNotEmpty) ? customerName[0].toUpperCase() : 'C';
          final serviceTitle = b.serviceName ?? b.categoryName ?? 'Service Request';
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildBookingCard(
              statusBarText: 'In progress now',
              statusBarGradient: const LinearGradient(colors: [Color(0xFF10794A), Color(0xFF1CA268)]),
              customerName: customerName,
              customerPhoto: customerPhoto,
              customerTag: 'Accepted',
              customerTagColor: AppTheme.sbGreenSoft,
              customerTagTextColor: AppTheme.sbGreen,
              customerInitials: initials,
              avatarColor: const Color(0xFF10794A),
              amount: '₱${(b.totalAmount ?? 0).toInt()}',
              kv: {
                'Service': serviceTitle,
                'Date': b.scheduledDate != null ? '${b.scheduledDate!.month}/${b.scheduledDate!.day}/${b.scheduledDate!.year}' : 'Flexible',
                'Time': b.scheduledTime ?? '9:00 AM',
                'Location': b.serviceAddress ?? 'Local Area',
              },
              actions: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            otherUserId: b.customerId,
                            otherUserName: customerName,
                            serviceTitle: serviceTitle,
                            booking: b,
                            otherUserPhoto: customerPhoto,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sbInk2,
                      side: const BorderSide(color: AppTheme.sbLine, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Mark as Done', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () {
                      showBookingCompletionModal(
                        context: context,
                        booking: b,
                        isCustomer: false,
                        onCompleted: () {
                          if (mounted) setState(() {});
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sbGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDonePanel(List<dynamic> completedBookings) {
    if (completedBookings.isEmpty) {
      return _buildEmptyState('No completed jobs', 'Completed jobs will appear here.', Icons.task_alt_rounded);
    }
    return Column(
      children: completedBookings.map((b) {
        final customerName = b.customer?.fullName ?? b.customer?.name ?? 'Customer';
        final customerPhoto = b.customer?.profilePhotoUrl;
        final initials = (customerName.isNotEmpty) ? customerName[0].toUpperCase() : 'C';
        final serviceTitle = b.serviceName ?? b.categoryName ?? 'Service Job';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildBookingCard(
            statusBarText: 'Completed',
            statusBarGradient: const LinearGradient(colors: [Color(0xFF1A2A20), Color(0xFF39543F)]),
            customerName: customerName,
            customerPhoto: customerPhoto,
            customerTag: 'Completed',
            customerTagColor: AppTheme.sbLine2,
            customerTagTextColor: AppTheme.sbInk3,
            customerInitials: initials,
            avatarColor: const Color(0xFF6B4BD8),
            amount: '₱${(b.totalAmount ?? 0).toInt()}',
            kv: {
              'Service': serviceTitle,
              'Settlement': '${b.paymentMethod ?? 'Cash'} • ${(b.paymentStatus?.toUpperCase() ?? 'PAID')}',
              if (b.rating != null && b.rating! > 0)
                'Rating Received': '${'★' * b.rating!} (${b.rating}/5)'
              else
                'Date': b.scheduledDate != null ? '${b.scheduledDate!.month}/${b.scheduledDate!.day}/${b.scheduledDate!.year}' : 'Recent',
              'Location': b.serviceAddress ?? 'Local Area',
            },
            actions: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    showBookingReceiptDialog(
                      context: context,
                      booking: b,
                      isCustomer: false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sbInk2,
                    side: const BorderSide(color: AppTheme.sbLine, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard({
    required String statusBarText,
    required LinearGradient statusBarGradient,
    Color statusBarTextColor = Colors.white,
    required String customerName,
    String? customerPhoto,
    required String customerTag,
    required Color customerTagColor,
    required Color customerTagTextColor,
    required String customerInitials,
    required Color avatarColor,
    String? amount,
    required Map<String, String> kv,
    String? quote,
    Widget? reviewCard,
    required List<Widget> actions,
  }) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: statusBarGradient,
            ),
            child: Text(
              statusBarText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: statusBarTextColor,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: (customerPhoto != null && customerPhoto.isNotEmpty)
                            ? Image.network(
                                customerPhoto,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    customerInitials,
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
                                  customerInitials,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sbInk,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: customerTagColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            customerTag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: customerTagTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (amount != null) ...[
                      const Spacer(),
                      Text(
                        amount,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.sbBlue,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Key-Value Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.sbSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: kv.entries.map((e) {
                      final isGreen = e.key == 'Net Earnings' || e.key == 'Kita';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.sbInk4)),
                          const SizedBox(height: 2),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isGreen ? AppTheme.sbBlue : AppTheme.sbInk2,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                if (quote != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppTheme.sbBlueSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      quote,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F5C36),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                if (reviewCard != null) reviewCard,

                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(children: actions),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
