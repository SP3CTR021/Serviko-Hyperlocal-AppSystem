import 'package:flutter/material.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../chat/conversation_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const CustomerBookingsScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  int _selectedSeg = 0; // 0: Active, 1: Pending, 2: Completed, 3: Cancelled

  @override
  Widget build(BuildContext context) {
    final allBookings = MySqlService().bookings;
    final activeBookings = allBookings.where((b) => b.status == 'accepted' || b.status == 'in_progress').toList();
    final pendingBookings = allBookings.where((b) => b.status == 'pending').toList();
    final completedBookings = allBookings.where((b) => b.status == 'completed').toList();
    final cancelledBookings = allBookings.where((b) => b.status == 'cancelled').toList();

    return Scaffold(
      backgroundColor: AppTheme.sbSurface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.90),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Bookings',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          children: [
            // Segmented Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSegButton(0, 'Active', badge: activeBookings.isNotEmpty ? '${activeBookings.length}' : null),
                  const SizedBox(width: 8),
                  _buildSegButton(1, 'Pending', badge: pendingBookings.isNotEmpty ? '${pendingBookings.length}' : null),
                  const SizedBox(width: 8),
                  _buildSegButton(2, 'Completed', badge: completedBookings.isNotEmpty ? '${completedBookings.length}' : null),
                  const SizedBox(width: 8),
                  _buildSegButton(3, 'Cancelled', badge: cancelledBookings.isNotEmpty ? '${cancelledBookings.length}' : null),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tab Panels
            if (_selectedSeg == 0) _buildActivePanel(activeBookings),
            if (_selectedSeg == 1) _buildPendingPanel(pendingBookings),
            if (_selectedSeg == 2) _buildDonePanel(completedBookings),
            if (_selectedSeg == 3) _buildCancelledPanel(cancelledBookings),
          ],
        ),
      ),
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

  Widget _buildActivePanel(List<dynamic> activeBookings) {
    if (activeBookings.isEmpty) {
      return _buildEmptyState('No active bookings', 'When you hire a service and it is accepted, it will appear here.', Icons.event_available_outlined);
    }
    return Column(
      children: activeBookings.map((b) {
        final workerName = b.worker?.fullName ?? b.worker?.name ?? 'Assigned Worker';
        final workerSkill = b.serviceName ?? b.categoryName ?? 'Service';
        final initials = (workerName.isNotEmpty) ? workerName[0] : 'W';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildBookingCard(
            statusBarText: 'Accepted · In Progress',
            statusBarGradient: const LinearGradient(colors: [Color(0xFF10794A), Color(0xFF1CA268)]),
            workerName: workerName,
            workerSkill: workerSkill,
            workerInitials: initials,
            avatarColor: const Color(0xFF10794A),
            amount: '₱${(b.totalAmount ?? 0).toInt()}',
            kv: {
              'Date': b.scheduledDate != null ? '${b.scheduledDate!.month}/${b.scheduledDate!.day}/${b.scheduledDate!.year}' : 'Flexible',
              'Time': b.scheduledTime ?? '9:00 AM',
              'Service': workerSkill,
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
                          otherUserName: workerName,
                          serviceTitle: workerSkill,
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
                child: ElevatedButton(
                  onPressed: () async {
                    await MySqlService().updateBookingStatus(b.bookingId, 'completed');
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sbBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Mark Done', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingPanel(List<dynamic> pendingBookings) {
    if (pendingBookings.isEmpty) {
      return _buildEmptyState('No pending bookings', 'Bookings waiting for worker response will appear here.', Icons.hourglass_empty_rounded);
    }
    return Column(
      children: pendingBookings.map((b) {
        final workerName = b.worker?.fullName ?? b.worker?.name ?? 'Worker';
        final workerSkill = b.serviceName ?? b.categoryName ?? 'Service';
        final initials = (workerName.isNotEmpty) ? workerName[0] : 'W';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildBookingCard(
            statusBarText: 'Waiting for response from $workerName',
            statusBarGradient: AppTheme.gWarm,
            statusBarTextColor: const Color(0xFF4A2A00),
            workerName: workerName,
            workerSkill: workerSkill,
            workerInitials: initials,
            avatarColor: const Color(0xFF6B4BD8),
            amount: '₱${(b.totalAmount ?? 0).toInt()}',
            kv: {
              'Date': b.scheduledDate != null ? '${b.scheduledDate!.month}/${b.scheduledDate!.day}/${b.scheduledDate!.year}' : 'Flexible',
              'Time': b.scheduledTime ?? '9:00 AM',
              'Service': workerSkill,
              'Location': b.serviceAddress ?? 'Local Area',
            },
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
                  child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDonePanel(List<dynamic> completedBookings) {
    if (completedBookings.isEmpty) {
      return _buildEmptyState('No completed bookings', 'Completed service jobs and reviews will appear here.', Icons.task_alt_rounded);
    }
    return Column(
      children: completedBookings.map((b) {
        final workerName = b.worker?.fullName ?? b.worker?.name ?? 'Worker';
        final workerSkill = b.serviceName ?? b.categoryName ?? 'Service';
        final initials = (workerName.isNotEmpty) ? workerName[0] : 'W';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildBookingCard(
            statusBarText: 'Completed',
            statusBarGradient: const LinearGradient(colors: [Color(0xFF1A2A20), Color(0xFF39543F)]),
            workerName: workerName,
            workerSkill: workerSkill,
            workerInitials: initials,
            avatarColor: const Color(0xFF1B9457),
            amount: '₱${(b.totalAmount ?? 0).toInt()}',
            kv: {
              'Service': workerSkill,
              'Time': b.scheduledTime ?? 'Morning',
              'Location': b.serviceAddress ?? 'Local Area',
            },
            actions: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Re-booking service with $workerName')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sbBlueSoft,
                    foregroundColor: AppTheme.sbBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCancelledPanel(List<dynamic> cancelledBookings) {
    if (cancelledBookings.isEmpty) {
      return _buildEmptyState('No cancellations', 'Bookings cancelled by you or the service provider will appear here.', Icons.cancel_outlined);
    }
    return Column(
      children: cancelledBookings.map((b) {
        final workerName = b.worker?.fullName ?? b.worker?.name ?? 'Worker';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildBookingCard(
            statusBarText: 'Cancelled',
            statusBarGradient: const LinearGradient(colors: [Color(0xFF4A1010), Color(0xFF7A2020)]),
            workerName: workerName,
            workerSkill: b.serviceName ?? 'Service',
            workerInitials: (workerName.isNotEmpty) ? workerName[0] : 'W',
            avatarColor: Colors.grey,
            amount: '₱${(b.totalAmount ?? 0).toInt()}',
            kv: {
              'Reason': b.cancellationReason ?? 'Cancelled by user',
              'Location': b.serviceAddress ?? 'Local Area',
            },
            actions: const [],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard({
    required String statusBarText,
    required LinearGradient statusBarGradient,
    Color statusBarTextColor = Colors.white,
    required String workerName,
    required String workerSkill,
    required String workerInitials,
    required Color avatarColor,
    required String amount,
    required Map<String, String> kv,
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
                // Worker header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          workerInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
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
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.sbBlueSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            workerSkill,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.sbBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.sbInk4)),
                          const SizedBox(height: 2),
                          Text(e.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                if (reviewCard != null) reviewCard,
                const SizedBox(height: 14),

                // Action buttons
                Row(children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
