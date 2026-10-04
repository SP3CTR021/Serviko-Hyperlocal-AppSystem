import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_completion_banner.dart';
import '../../utils/verification_guard.dart';
import '../chat/conversation_screen.dart';

class ExploreServicesScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onNavigateTab;

  const ExploreServicesScreen({
    super.key,
    this.onOpenDrawer,
    this.onNavigateTab,
  });

  @override
  State<ExploreServicesScreen> createState() => _ExploreServicesScreenState();
}

class _ExploreServicesScreenState extends State<ExploreServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _locationFilter = '';
  String _priceFilter = '';
  bool _filterAvailableOnly = false;
  bool _filterVerifiedOnly = false;
  bool _filterTopRatedOnly = false;
  String _sortBy = 'Most Relevant';

  // ---------------------------------------------------------------------------
  // SAMPLE PEOPLE / WORKERS (COMMENTED OUT FOR CLEAN SLATE TESTING)
  // ---------------------------------------------------------------------------
  // static final List<Map<String, dynamic>> _sampleProtoWorkers = [
  //   {'n': 'Romy dela Cruz', 'i': 'RD', 'c': const Color(0xFF1B9457), 's': 'Electrician', 'l': 'Toril, Davao City', 'r': 4.9, 'j': 87, 'p': 350, 'u': 'hr', 'v': true, 'a': true, 't': true},
  //   {'n': 'Nena Santos', 'i': 'NS', 'c': const Color(0xFF10794A), 's': 'House Cleaner', 'l': 'Matina, Davao City', 'r': 4.8, 'j': 134, 'p': 250, 'u': 'hr', 'v': true, 'a': true, 't': true},
  //   {'n': 'Eddie Morales', 'i': 'EM', 'c': const Color(0xFF6B4BD8), 's': 'Plumber', 'l': 'Agdao, Davao City', 'r': 4.7, 'j': 62, 'p': 400, 'u': 'hr', 'v': true, 'a': false, 't': false},
  //   {'n': 'Ben Villarreal', 'i': 'BV', 'c': const Color(0xFFC47D0E), 's': 'Carpenter', 'l': 'Buhangin, Davao City', 'r': 4.6, 'j': 45, 'p': 550, 'u': 'day', 'v': false, 'a': true, 't': false},
  //   {'n': 'Toto Recio', 'i': 'TR', 'c': const Color(0xFFB85C00), 's': 'Aircon Tech', 'l': 'Lanang, Davao City', 'r': 4.9, 'j': 203, 'p': 300, 'u': 'unit', 'v': true, 'a': true, 't': true},
  //   {'n': 'Linda Go', 'i': 'LG', 'c': const Color(0xFFA32D2D), 's': 'Painter', 'l': 'Talomo, Davao City', 'r': 4.5, 'j': 38, 'p': 600, 'u': 'day', 'v': false, 'a': true, 't': false},
  //   {'n': 'Dodong Espinosa', 'i': 'DE', 'c': const Color(0xFF0F6E56), 's': 'Welder', 'l': 'Mintal, Davao City', 'r': 4.8, 'j': 71, 'p': 500, 'u': 'hr', 'v': true, 'a': false, 't': true},
  //   {'n': 'Clara Santos', 'i': 'CS', 'c': const Color(0xFF533AB7), 's': 'Massage Therapist', 'l': 'Ma-a, Davao City', 'r': 4.7, 'j': 156, 'p': 200, 'u': 'session', 'v': true, 'a': true, 't': false},
  //   {'n': 'Kuya Boy', 'i': 'KB', 'c': const Color(0xFF854F0B), 's': 'Handyman', 'l': 'Sasa, Davao City', 'r': 4.7, 'j': 93, 'p': 300, 'u': 'hr', 'v': true, 'a': true, 't': false},
  //   {'n': 'Bert Reyes', 'i': 'BR', 'c': const Color(0xFF0C447C), 's': 'Electrician', 'l': 'Sta. Ana, Davao City', 'r': 4.8, 'j': 118, 'p': 380, 'u': 'hr', 'v': true, 'a': true, 't': true},
  // ];
  final List<Map<String, dynamic>> _protoWorkers = [];

  @override
  void initState() {
    super.initState();
    MySqlService().refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredWorkers() {
    final query = _searchController.text.trim().toLowerCase();

    // Map dynamic database worker profiles from MySqlService / Firestore
    final dbWorkers = MySqlService().workerProfiles.map((wp) {
      final name = wp.user?.fullName ?? (wp.user?.name ?? 'Worker');
      final colorHex = wp.avatarColor?.replaceFirst('#', '0xFF') ?? '0xFF1B9457';
      final parsedColor = Color(int.tryParse(colorHex) ?? 0xFF1B9457);
      return {
        'id': wp.userId,
        'n': name,
        'i': wp.initials ?? (name.isNotEmpty ? name[0] : 'W'),
        'c': parsedColor,
        's': wp.primarySkill ?? 'Services',
        'l': wp.user?.locationString ?? 'Local Area',
        'r': wp.avgRating,
        'j': wp.totalJobsCompleted,
        'p': wp.basePrice?.toInt() ?? 300,
        'u': wp.priceType ?? 'hr',
        'v': wp.isIdVerified,
        'a': wp.availabilityStatus == 'available',
        't': wp.avgRating >= 4.8,
      };
    });

    final allWorkers = [..._protoWorkers, ...dbWorkers];

    var list = allWorkers.where((w) {
      final name = (w['n'] as String).toLowerCase();
      final skill = (w['s'] as String).toLowerCase();
      final loc = (w['l'] as String).toLowerCase();

      if (query.isNotEmpty && !name.contains(query) && !skill.contains(query) && !loc.contains(query)) {
        return false;
      }

      if (_selectedCategory != 'All') {
        if (_selectedCategory == 'Aircon' && !skill.contains('aircon')) return false;
        if (_selectedCategory != 'Aircon' && !skill.contains(_selectedCategory.toLowerCase())) return false;
      }

      if (_locationFilter.isNotEmpty && !loc.contains(_locationFilter.toLowerCase())) {
        return false;
      }

      final price = w['p'] as int;
      if (_priceFilter == 'low' && price > 300) return false;
      if (_priceFilter == 'mid' && (price < 301 || price > 600)) return false;
      if (_priceFilter == 'high' && price < 601) return false;

      if (_filterAvailableOnly && w['a'] != true) return false;
      if (_filterVerifiedOnly && w['v'] != true) return false;
      if (_filterTopRatedOnly && w['t'] != true) return false;

      return true;
    }).toList();

    if (_sortBy == 'Highest Rated') {
      list.sort((a, b) => (b['r'] as double).compareTo(a['r'] as double));
    } else if (_sortBy == 'Lowest Price') {
      list.sort((a, b) => (a['p'] as int).compareTo(b['p'] as int));
    }

    return list;
  }

  void _openBookingSheet(Map<String, dynamic> worker) {
    if (!VerificationGuard.check(context, actionName: 'book a service')) return;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    String selectedTime = '9:00 AM';
    final addressCtrl = TextEditingController(text: 'Matina, Davao City');
    final detailsCtrl = TextEditingController();

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
                  decoration: BoxDecoration(
                    color: AppTheme.sbLine,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Book with ${worker['n']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sbInk,
                ),
              ),
              const SizedBox(height: 12),

              // Worker brief banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.sbBlueSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker['n'],
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.sbInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${worker['s']} · ₱${worker['p']} per ${worker['u']}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.sbBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Date
              const Text('Service Date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.sbCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.sbLine, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.sbInk)),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.sbInk4),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Time Dropdown
              const Text('Service Time', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
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
                    value: selectedTime,
                    isExpanded: true,
                    items: ['8:00 AM', '9:00 AM', '10:00 AM', '1:00 PM', '2:00 PM', '3:00 PM']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedTime = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Address
              const Text('Service Address', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: addressCtrl,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Street, barangay, city',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Job Details
              const Text('Job Details & Instructions', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 6),
              TextFormField(
                controller: detailsCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Describe the issue or requirements (e.g. leaking sink pipe)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.sbLine, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.sbSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Payment is made directly via GCash, Maya, or cash upon job completion.',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.sbInk3),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  final address = addressCtrl.text.trim();
                  final details = detailsCtrl.text.trim();
                  final currentUser = AuthService().currentUser;
                  final price = (worker['p'] as num?)?.toDouble() ?? 500.0;

                  final newBooking = BookingModel(
                    bookingId: DateTime.now().millisecondsSinceEpoch % 100000,
                    customerId: currentUser?.id ?? 1,
                    workerId: (worker['user_id'] is int) ? worker['user_id'] : 2,
                    scheduledDate: DateTime.now().add(const Duration(days: 1)),
                    scheduledTime: selectedTime,
                    serviceAddress: address.isNotEmpty ? address : 'Local Address',
                    jobDescription: details.isNotEmpty ? details : 'Service Request',
                    status: 'pending',
                    totalAmount: price,
                    createdAt: DateTime.now(),
                    customer: currentUser,
                    serviceName: worker['s']?.toString() ?? 'Service',
                  );

                  await MySqlService().createBooking(newBooking);

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking request sent to ${worker['n'].split(' ')[0]} and saved to Firebase!'),
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
                child: const Text('Confirm Booking', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
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

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
              const Text('Filter Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
              const SizedBox(height: 16),

              // Location Dropdown
              const Text('Location', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
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
                    value: _locationFilter.isEmpty ? '' : _locationFilter,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All locations')),
                      DropdownMenuItem(value: 'Davao City', child: Text('Davao City')),
                      DropdownMenuItem(value: 'Cebu City', child: Text('Cebu City')),
                      DropdownMenuItem(value: 'Cagayan de Oro', child: Text('Cagayan de Oro')),
                    ],
                    onChanged: (val) {
                      setSheetState(() => _locationFilter = val ?? '');
                      setState(() => _locationFilter = val ?? '');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Price Dropdown
              const Text('Price Range', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
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
                    value: _priceFilter,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All prices')),
                      DropdownMenuItem(value: 'low', child: Text('Up to ₱300')),
                      DropdownMenuItem(value: 'mid', child: Text('₱301 – ₱600')),
                      DropdownMenuItem(value: 'high', child: Text('₱601 and above')),
                    ],
                    onChanged: (val) {
                      setSheetState(() => _priceFilter = val ?? '');
                      setState(() => _priceFilter = val ?? '');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Attributes & Badges', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.sbInk2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterPill(
                    label: 'Available Now',
                    isSelected: _filterAvailableOnly,
                    onTap: () {
                      setSheetState(() => _filterAvailableOnly = !_filterAvailableOnly);
                      setState(() => _filterAvailableOnly = !_filterAvailableOnly);
                    },
                  ),
                  _buildFilterPill(
                    label: 'Verified Only',
                    isSelected: _filterVerifiedOnly,
                    onTap: () {
                      setSheetState(() => _filterVerifiedOnly = !_filterVerifiedOnly);
                      setState(() => _filterVerifiedOnly = !_filterVerifiedOnly);
                    },
                  ),
                  _buildFilterPill(
                    label: 'Top Rated',
                    isSelected: _filterTopRatedOnly,
                    onTap: () {
                      setSheetState(() => _filterTopRatedOnly = !_filterTopRatedOnly);
                      setState(() => _filterTopRatedOnly = !_filterTopRatedOnly);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sbBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Apply Filters', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
            const Text('Sort Results By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
            const SizedBox(height: 14),
            ...['Most Relevant', 'Highest Rated', 'Lowest Price', 'Closest Distance'].map(
              (opt) => ListTile(
                title: Text(
                  opt,
                  style: TextStyle(
                    fontWeight: _sortBy == opt ? FontWeight.w800 : FontWeight.w600,
                    color: _sortBy == opt ? AppTheme.sbBlue : AppTheme.sbInk,
                  ),
                ),
                trailing: _sortBy == opt ? const Icon(Icons.check_rounded, color: AppTheme.sbBlue) : const Icon(Icons.chevron_right_rounded, color: AppTheme.sbInk4),
                onTap: () {
                  setState(() => _sortBy = opt);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sbBlueSoft : AppTheme.sbCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? AppTheme.sbBlue2 : AppTheme.sbLine,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTheme.sbBlue : AppTheme.sbInk3,
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
        final workers = _getFilteredWorkers();
        final currentUser = AuthService().currentUser;
        final userName = currentUser?.fullName ?? currentUser?.name ?? 'User';
        final userPhotoUrl = currentUser?.profilePhotoUrl;
        final userInitials = (userName.isNotEmpty && userName != 'User')
            ? userName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
            : 'U';

        final bookings = MySqlService().bookings;
        final activeBookingsCount = bookings.where((b) => b.status == 'accepted' || b.status == 'in_progress' || b.status == 'pending').length;
        final totalBookingsCount = bookings.length;
        final totalSpent = bookings.fold<double>(0.0, (acc, b) => acc + (b.totalAmount ?? 0.0));

        return Scaffold(
          backgroundColor: AppTheme.sbSurface,
          body: RefreshIndicator(
            onRefresh: () => MySqlService().refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: homehead
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.gHero,
              ),
              child: Stack(
                clipBehavior: Clip.none,
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
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 76),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                            errorBuilder: (_, __, ___) => const Center(
                                              child: Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.person_rounded,
                                              color: Colors.white,
                                              size: 24,
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
                                      'Good day,',
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
                                    const SnackBar(content: Text('No new notifications')),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pull Section: Search Bar & Mini Cards
            Transform.translate(
              offset: const Offset(0, -56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330B1B33),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppTheme.sbInk4, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Plumber, electrician, aircon, cleaner...',
                                hintStyle: TextStyle(color: AppTheme.sbInk4, fontWeight: FontWeight.w500),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openFiltersSheet,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: AppTheme.gBlue,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mini cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$activeBookingsCount', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                                const SizedBox(height: 2),
                                const Text('Active bookings', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.sbCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.sbLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$totalBookingsCount', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                                const SizedBox(height: 2),
                                const Text('Total bookings', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.sbInk4)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.sbCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.sbLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₱${totalSpent.toInt()}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                                const SizedBox(height: 2),
                                const Text('Total spent', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.sbInk4)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Promo Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.gHero,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cannot find what you need?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Post a custom job request and let verified workers send their best bids.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => widget.onNavigateTab?.call(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.sbBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Post a Job', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  'All',
                  'Electrician',
                  'Plumber',
                  'House Cleaner',
                  'Aircon',
                  'Carpenter',
                ].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.sbBlueSoft : AppTheme.sbCard,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFC8DBFF) : AppTheme.sbLine,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppTheme.sbBlue : AppTheme.sbInk3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${workers.length} workers near you',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.sbInk,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openSortSheet,
                    child: const Text(
                      'Sort',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sbBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Worker List
            if (workers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: const [
                    Icon(Icons.search_off_rounded, size: 48, color: AppTheme.sbInk4),
                    SizedBox(height: 8),
                    Text('No workers found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Try searching with another keyword or adjust your filters.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.sbInk4, fontSize: 13)),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final w = workers[idx];
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppTheme.sbCard,
                        borderRadius: BorderRadius.circular(20),
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
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar with verification badge
                              Stack(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: w['c'] as Color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        w['i'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (w['v'] == true)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: AppTheme.sbBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w['n'] as String,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.sbInk,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${w['s']} · ${(w['l'] as String).split(',')[0]}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.sbInk4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppTheme.sbAmber, size: 16),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${w['r']}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.sbInk,
                                          ),
                                        ),
                                        Text(
                                          ' · ${w['j']} jobs',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.sbInk4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: w['a'] == true ? AppTheme.sbGreenSoft : AppTheme.sbLine2,
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            w['a'] == true ? 'Available' : 'Busy',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: w['a'] == true ? AppTheme.sbGreen : AppTheme.sbInk3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₱${w['p']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.sbBlue,
                                    ),
                                  ),
                                  Text(
                                    'per ${w['u']}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.sbInk4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppTheme.sbLine2),
                          const SizedBox(height: 10),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ConversationScreen(
                                          otherUserId: w['id'] as int?,
                                          otherUserName: w['n'] as String,
                                          serviceTitle: w['s'] as String,
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
                                  child: const Text('Message', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _openBookingSheet(w),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.sbBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800)),
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
    },
  );
}
}
