import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'profile_completion_modal.dart';

class ProfileCompletionBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const ProfileCompletionBanner({
    super.key,
    this.margin = const EdgeInsets.only(top: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final user = AuthService().currentUser;
        if (user == null || user.isVerified) {
          return const SizedBox.shrink();
        }

        final progress = user.profileCompletionPercentage;

        // Step 1: Basic account (30%)
        // Step 2: Details & Photo (60%)
        // Step 3: Government ID verified (100%)
        int step = 1;
        if ((user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ||
            (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty)) {
          step = 2;
        }

        return Container(
          margin: margin,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showProfileCompletionModal(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Complete your Profile',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Step $step of 3 · $progress%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: [
                          Container(
                            height: 4,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          FractionallySizedBox(
                            widthFactor: (progress / 100.0).clamp(0.08, 1.0),
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
