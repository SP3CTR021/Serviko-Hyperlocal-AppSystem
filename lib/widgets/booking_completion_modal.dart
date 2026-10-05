import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/mysql_service.dart';
import '../theme/app_theme.dart';

/// Shows the interactive job completion & payment fill-up modal.
Future<void> showBookingCompletionModal({
  required BuildContext context,
  required BookingModel booking,
  bool? isCustomer,
  VoidCallback? onCompleted,
}) async {
  final customerMode = isCustomer ?? (AuthService().currentUser?.isCustomer ?? true);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BookingCompletionSheet(
      booking: booking,
      isCustomer: customerMode,
      onCompleted: onCompleted,
    ),
  );
}

/// Shows the digital settlement receipt dialog for completed bookings.
void showBookingReceiptDialog({
  required BuildContext context,
  required BookingModel booking,
  bool isCustomer = true,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _BookingReceiptDialog(
      booking: booking,
      isCustomer: isCustomer,
    ),
  );
}

class _BookingCompletionSheet extends StatefulWidget {
  final BookingModel booking;
  final bool isCustomer;
  final VoidCallback? onCompleted;

  const _BookingCompletionSheet({
    required this.booking,
    required this.isCustomer,
    this.onCompleted,
  });

  @override
  State<_BookingCompletionSheet> createState() => _BookingCompletionSheetState();
}

class _BookingCompletionSheetState extends State<_BookingCompletionSheet> {
  late TextEditingController _amountCtrl;
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _reviewCtrl = TextEditingController();

  // Cash / COD removed as requested. Digital payment methods only.
  String _selectedPaymentMethod = 'GCash';
  bool _isPaidInFull = true;
  int _rating = 5;
  bool _isSubmitting = false;

  // System platform commission fee rate (5%)
  static const double _commissionRate = 0.05;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'GCash',
      'label': 'GCash',
      'icon': Icons.account_balance_wallet_rounded,
      'desc': 'E-Wallet Transfer (Instant Settlement)',
    },
    {
      'id': 'Maya',
      'label': 'Maya',
      'icon': Icons.phone_android_rounded,
      'desc': 'PayMaya Wallet / QR Payment',
    },
    {
      'id': 'Card',
      'label': 'Card / Bank Transfer',
      'icon': Icons.credit_card_rounded,
      'desc': 'Debit/Credit Card / Online Banking',
    },
  ];

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.booking.totalAmount ?? 500.0;
    _amountCtrl = TextEditingController(text: defaultAmount.toInt().toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  String _getRatingLabel(int r) {
    switch (r) {
      case 1:
        return 'Needs Improvement';
      case 2:
        return 'Fair Service';
      case 3:
        return 'Good Work';
      case 4:
        return 'Great Service!';
      case 5:
      default:
        return 'Exceptional Service! ⭐';
    }
  }

  Future<void> _handleConfirmCompletion() async {
    final finalAmount = double.tryParse(_amountCtrl.text.trim()) ?? (widget.booking.totalAmount ?? 500.0);
    final commissionAmount = finalAmount * _commissionRate;
    final netAmount = finalAmount - commissionAmount;

    setState(() => _isSubmitting = true);

    final success = await MySqlService().completeBooking(
      bookingId: widget.booking.bookingId,
      paymentMethod: _selectedPaymentMethod,
      paymentStatus: _isPaidInFull ? 'paid' : 'pending',
      totalAmount: finalAmount,
      commissionRate: _commissionRate,
      commissionAmount: commissionAmount,
      netAmount: netAmount,
      completionNotes: widget.isCustomer ? null : _notesCtrl.text.trim(),
      rating: widget.isCustomer ? _rating : null,
      reviewComment: widget.isCustomer ? _reviewCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(); // Close sheet

      final updatedBooking = BookingModel(
        bookingId: widget.booking.bookingId,
        customerId: widget.booking.customerId,
        workerId: widget.booking.workerId,
        serviceAddress: widget.booking.serviceAddress,
        jobDescription: widget.booking.jobDescription,
        status: 'completed',
        totalAmount: finalAmount,
        commissionRate: _commissionRate,
        commissionAmount: commissionAmount,
        netAmount: netAmount,
        createdAt: widget.booking.createdAt,
        scheduledDate: widget.booking.scheduledDate,
        scheduledTime: widget.booking.scheduledTime,
        serviceName: widget.booking.serviceName,
        categoryName: widget.booking.categoryName,
        customer: widget.booking.customer,
        worker: widget.booking.worker,
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _isPaidInFull ? 'paid' : 'pending',
        completedAt: DateTime.now(),
        completionNotes: widget.isCustomer ? null : _notesCtrl.text.trim(),
        rating: widget.isCustomer ? _rating : null,
        reviewComment: widget.isCustomer ? _reviewCtrl.text.trim() : null,
      );

      // Trigger completion callback
      widget.onCompleted?.call();

      // Show digital settlement receipt dialog
      showBookingReceiptDialog(
        context: context,
        booking: updatedBooking,
        isCustomer: widget.isCustomer,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete booking. Please check connection.'),
          backgroundColor: AppTheme.sbRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.isCustomer
        ? (widget.booking.worker?.fullName ?? widget.booking.worker?.name ?? 'Worker')
        : (widget.booking.customer?.fullName ?? widget.booking.customer?.name ?? 'Customer');
    final serviceName = widget.booking.serviceName ?? widget.booking.categoryName ?? 'Service Job';

    final enteredAmount = double.tryParse(_amountCtrl.text.trim()) ?? (widget.booking.totalAmount ?? 500.0);
    final commissionAmount = enteredAmount * _commissionRate;
    final workerNetPayout = enteredAmount - commissionAmount;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                color: AppTheme.sbLine2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.sbGreenSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.task_alt_rounded, color: AppTheme.sbGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Service Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sbInk,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Review payment, commission, and confirm job',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.sbInk4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.sbInk3),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.sbLine2),

            // Form Body
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // 1. Service Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.sbSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.sbLine),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.sbBlueSoft,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Booking #${widget.booking.bookingId}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.sbBlue,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.sbGreenSoft,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Ready to Complete',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.sbGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sbInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.sbInk4),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.isCustomer ? 'Service Provider' : 'Client'}: $otherName',
                              style: const TextStyle(fontSize: 13, color: AppTheme.sbInk3, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.sbInk4),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.booking.serviceAddress ?? 'Local Area',
                                style: const TextStyle(fontSize: 12.5, color: AppTheme.sbInk4),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 2. Payment & Settlement Section
                  const Text(
                    'Payment & Settlement',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.sbInk,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Final Amount Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.sbLine),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.sbGreenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('₱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.sbGreen)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Service Price', style: TextStyle(fontSize: 11.5, color: AppTheme.sbInk4, fontWeight: FontWeight.w600)),
                              TextField(
                                controller: _amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.sbInk),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  border: InputBorder.none,
                                  hintText: '0.00',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('PHP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.sbInk4)),
                      ],
                    ),
                  ),

                  // 5% System Commission Breakdown Card
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.sbSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.sbLine),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Gross Service Price', style: TextStyle(fontSize: 12.5, color: AppTheme.sbInk3)),
                            Text('₱${enteredAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.sbInk)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text('System Platform Fee (5%)', style: TextStyle(fontSize: 12.5, color: Color(0xFFB45309), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Text('-₱${commissionAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                          ],
                        ),
                        const Divider(height: 16, color: AppTheme.sbLine2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Provider Net Payout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                            Text('₱${workerNetPayout.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.sbBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method Selectors
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.sbInk2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: _paymentMethods.map((pm) {
                      final isSelected = _selectedPaymentMethod == pm['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = pm['id'] as String),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.sbBlueSoft : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppTheme.sbBlue : AppTheme.sbLine,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.sbBlue.withValues(alpha: 0.15) : AppTheme.sbSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    pm['icon'] as IconData,
                                    color: isSelected ? AppTheme.sbBlue : AppTheme.sbInk3,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pm['label'] as String,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? AppTheme.sbBlue : AppTheme.sbInk,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        pm['desc'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? AppTheme.sbBlue.withValues(alpha: 0.8) : AppTheme.sbInk4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? AppTheme.sbBlue : AppTheme.sbLine,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Payment Status Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.sbSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.sbLine),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPaidInFull ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: _isPaidInFull ? AppTheme.sbGreen : AppTheme.sbInk4,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isPaidInFull ? 'Payment Completed & Received' : 'Payment Pending / Collect Later',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isPaidInFull ? AppTheme.sbInk : AppTheme.sbInk3,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isPaidInFull,
                          activeThumbColor: AppTheme.sbGreen,
                          onChanged: (val) => setState(() => _isPaidInFull = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 3. Customer Rating & Review or Worker Notes
                  if (widget.isCustomer) ...[
                    const Text(
                      'Rate Service Provider',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.sbInk,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.sbLine),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (idx) {
                              final starNum = idx + 1;
                              return IconButton(
                                iconSize: 34,
                                icon: Icon(
                                  starNum <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: starNum <= _rating ? AppTheme.sbYellowGreen : AppTheme.sbInk4,
                                ),
                                onPressed: () => setState(() => _rating = starNum),
                              );
                            }),
                          ),
                          Text(
                            _getRatingLabel(_rating),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.sbInk2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Feedback & Review (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sbInk2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reviewCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Share your feedback on worker punctuality, quality, and friendliness...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.sbInk4),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.sbLine),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.sbLine),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Worker Completion Notes
                    const Text(
                      'Work Completion Notes (Optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.sbInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Add notes about services completed, parts installed, or warranty info...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.sbInk4),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.sbLine),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.sbLine),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Confirm Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleConfirmCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sbGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Confirm & Complete Booking',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Not yet, keep booking active',
                      style: TextStyle(color: AppTheme.sbInk3, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingReceiptDialog extends StatelessWidget {
  final BookingModel booking;
  final bool isCustomer;

  const _BookingReceiptDialog({
    required this.booking,
    required this.isCustomer,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Today';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final workerName = booking.worker?.fullName ?? booking.worker?.name ?? 'Worker';
    final customerName = booking.customer?.fullName ?? booking.customer?.name ?? 'Customer';
    final serviceTitle = booking.serviceName ?? booking.categoryName ?? 'Service Job';
    final totalAmount = booking.totalAmount ?? 500.0;
    final commissionRate = booking.commissionRate ?? 0.05;
    final commissionAmount = booking.commissionAmount ?? (totalAmount * commissionRate);
    final netAmount = booking.netAmount ?? (totalAmount - commissionAmount);
    final paymentMethod = booking.paymentMethod ?? 'GCash';
    final isPaid = (booking.paymentStatus?.toLowerCase() == 'paid') || booking.paymentStatus == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Ensures the green top extends with zero white space on the sides
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches header across entire card width
          children: [
            // Top Green Banner (Flush to borders with NO white margins)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF10794A),
                gradient: LinearGradient(
                  colors: [Color(0xFF10794A), Color(0xFF1B9457)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Removed celebrating party emoji as requested
                  const Text(
                    'Booking Completed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Official Service Settlement Receipt',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Receipt Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount Badge
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4E7DC)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT SETTLED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sbGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.sbInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPaid ? AppTheme.sbGreenSoft : AppTheme.sbAmberSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            isPaid ? 'PAID IN FULL' : 'PAYMENT PENDING',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: isPaid ? AppTheme.sbGreen : AppTheme.sbAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Receipt Meta items
                  _buildReceiptRow('Booking ID', '#${booking.bookingId}'),
                  _buildReceiptRow('Service', serviceTitle),
                  _buildReceiptRow('Service Provider', workerName),
                  _buildReceiptRow('Customer', customerName),
                  _buildReceiptRow('Payment Method', paymentMethod),
                  _buildReceiptRow('Service Total', '₱${totalAmount.toStringAsFixed(2)}'),
                  _buildReceiptRow('Platform Commission (5%)', '-₱${commissionAmount.toStringAsFixed(2)}'),
                  _buildReceiptRow('Provider Net Payout', '₱${netAmount.toStringAsFixed(2)}'),
                  _buildReceiptRow('Completed On', _formatDateTime(booking.completedAt ?? DateTime.now())),

                  if (booking.rating != null && booking.rating! > 0) ...[
                    _buildReceiptRow('Rating Given', '${'★' * booking.rating!} (${booking.rating}/5)'),
                  ],

                  if (booking.reviewComment != null && booking.reviewComment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.sbSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.sbLine),
                      ),
                      child: Text(
                        '"${booking.reviewComment}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.sbInk2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  if (booking.completionNotes != null && booking.completionNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.sbSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.sbLine),
                      ),
                      child: Text(
                        'Notes: ${booking.completionNotes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.sbInk2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sbInk,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.sbInk4, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.sbInk, fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
