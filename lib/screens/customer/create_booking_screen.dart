import 'package:flutter/material.dart';
import '../../models/worker_profile_model.dart';
import '../../models/worker_service_model.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';

class CreateBookingScreen extends StatefulWidget {
  final WorkerProfileModel worker;
  final WorkerServiceModel? preselectedService;

  const CreateBookingScreen({super.key, required this.worker, this.preselectedService});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  WorkerServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  bool _isUrgent = false;
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '08:00 AM', '10:00 AM', '01:00 PM', '03:00 PM', '05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService ?? (widget.worker.services.isNotEmpty ? widget.worker.services.first : null);
    final user = AuthService().currentUser;
    if (user?.locationString != null && user!.locationString != 'Location not set') {
      _addressController.text = user.locationString;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = AuthService().currentUser;
    final total = _selectedService?.price ?? widget.worker.basePrice ?? 0.0;

    final newBooking = BookingModel(
      bookingId: DateTime.now().millisecondsSinceEpoch % 100000,
      customerId: currentUser?.id ?? 1,
      workerId: widget.worker.userId,
      workerServiceId: _selectedService?.workerServiceId,
      categoryId: _selectedService?.categoryId,
      scheduledDate: _selectedDate,
      scheduledTime: _selectedTime,
      serviceAddress: _addressController.text.trim(),
      jobDescription: _descController.text.trim(),
      status: 'pending',
      isUrgent: _isUrgent,
      totalAmount: total,
      createdAt: DateTime.now(),
      customer: currentUser,
      worker: widget.worker.user,
      serviceName: _selectedService?.displayName ?? widget.worker.primarySkill,
      categoryName: _selectedService?.categoryName,
    );

    final success = await MySqlService().createBooking(newBooking);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('Booking Requested!'),
            ],
          ),
          content: Text(
            'Your booking request has been sent to ${widget.worker.user?.fullName ?? 'the specialist'}. You can track status in your Bookings tab.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // pop dialog
                Navigator.pop(context); // pop booking screen
              },
              child: const Text('View Bookings'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _selectedService?.price ?? widget.worker.basePrice ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Worker info summary
              Card(
                color: AppTheme.primaryLight.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          widget.worker.initials ?? 'W',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.worker.user?.fullName ?? 'Specialist',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.worker.primarySkill ?? 'Service Pro',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Service Selection
              if (widget.worker.services.isNotEmpty) ...[
                const Text('Select Service', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<WorkerServiceModel>(
                  value: _selectedService,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: widget.worker.services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('${s.displayName} (${s.formattedPrice})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedService = val),
                ),
                const SizedBox(height: 16),
              ],

              // Schedule Date & Time
              const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTime,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _selectedTime = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              const Text('Service Location / Address', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Unit/House number, Street, District, City',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter the service address' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Describe the Issue or Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Bathroom pipe leak under the sink, low pressure...',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a short description' : null,
              ),
              const SizedBox(height: 16),

              // Urgent Switch
              Card(
                child: SwitchListTile(
                  title: const Text('Urgent Service Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Priority dispatch within 24 hours if available', style: TextStyle(fontSize: 12)),
                  value: _isUrgent,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) => setState(() => _isUrgent = val),
                ),
              ),
              const SizedBox(height: 24),

              // Total Estimate & Submit
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Cost:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      total > 0 ? '₱${total.toStringAsFixed(2)}' : 'To be estimated',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmitBooking,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirm & Send Booking Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
