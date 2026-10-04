import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_completion_modal.dart';

class VerificationGuard {
  /// Checks if the current user is verified.
  /// If verified, returns true.
  /// If not verified, shows a warning modal prompting ID & profile verification, and returns false.
  static bool check(BuildContext context, {required String actionName}) {
    final user = AuthService().currentUser;

    // If verified, proceed immediately
    if (user != null && user.isVerified) {
      return true;
    }

    // Otherwise, show restriction reminder dialog (Green & Black UI)
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.sbGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.sbGreen.withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppTheme.sbGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verification Required',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.sbInk,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sbGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.sbGreen.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.sbGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Action Restricted: $actionName',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.sbInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'To protect our community and ensure safe transactions, you cannot $actionName until your profile is verified with a valid government ID and complete information.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.sbInkSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.sbLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.sbInkSoft),
                  const SizedBox(width: 6),
                  Text(
                    'Profile setup is currently ${user?.profileCompletionPercentage ?? 30}% complete',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.sbInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      color: AppTheme.sbInkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sbGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    showProfileCompletionModal(context);
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 16),
                  label: const Text(
                    'Verify ID Now',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return false;
  }
}
