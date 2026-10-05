import 'package:flutter/material.dart';
import '../../models/worker_profile_model.dart';
import '../../models/worker_service_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/verification_guard.dart';
import 'create_booking_screen.dart';
import '../chat/conversation_screen.dart';

class WorkerProfileDetailScreen extends StatelessWidget {
  final WorkerProfileModel worker;

  const WorkerProfileDetailScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(worker.user?.fullName ?? 'Worker Profile'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Standard Rate', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      worker.formattedPrice,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        otherUserId: worker.userId,
                        otherUserName: worker.user?.fullName ?? 'Worker',
                        serviceTitle: worker.primarySkill,
                        otherUserPhoto: worker.photoUrl,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.sbInk2,
                  side: const BorderSide(color: AppTheme.sbLine, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  if (!VerificationGuard.check(context, actionName: 'book a service')) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateBookingScreen(worker: worker),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text('Book Service'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryLight,
                    backgroundImage: (worker.photoUrl != null && worker.photoUrl!.isNotEmpty)
                        ? NetworkImage(worker.photoUrl!)
                        : null,
                    child: (worker.photoUrl == null || worker.photoUrl!.isEmpty)
                        ? Text(
                            worker.initials ?? (worker.user?.fullName.isNotEmpty == true ? worker.user!.fullName.substring(0, 1).toUpperCase() : 'W'),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        worker.user?.fullName ?? 'Service Pro',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (worker.isIdVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.primarySkill ?? 'Specialist',
                    style: const TextStyle(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.user?.locationString ?? 'Metro Manila',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Highlights row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Rating', '${worker.avgRating}', isRating: true),
                      _buildStatColumn('Jobs Done', '${worker.totalJobsCompleted}'),
                      _buildStatColumn('Experience', '${worker.yearsOfExperience} yrs'),
                      _buildStatColumn('Status', worker.availabilityStatus.toUpperCase()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bio Card
          if (worker.bio != null && worker.bio!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About Worker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      worker.bio!,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Services Offered Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Services & Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (worker.services.isEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor),
                      title: Text(worker.primarySkill ?? 'General Service'),
                      subtitle: const Text('Custom estimates provided based on requirement.'),
                      trailing: Text(worker.formattedPrice, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    ...worker.services.map((service) => _buildServiceTile(context, service)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {bool isRating = false}) {
    return Column(
      children: [
        if (isRating)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(width: 3),
              const Icon(Icons.star_rounded, size: 16, color: AppTheme.sbYellowGreen),
            ],
          )
        else
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, WorkerServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.displayName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (service.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    service.description!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                service.formattedPrice,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  if (!VerificationGuard.check(context, actionName: 'book a service')) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateBookingScreen(worker: worker, preselectedService: service),
                    ),
                  );
                },
                child: const Text(
                  'Book this',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
