import 'package:flutter/material.dart';
import '../services/mysql_service.dart';

class DbStatusBanner extends StatelessWidget {
  const DbStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MySqlService(),
      builder: (context, _) {
        final db = MySqlService();
        final isConnected = db.isConnected;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: isConnected ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                size: 16,
                color: isConnected ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConnected ? 'Cloud Firestore Online' : 'Connecting to Cloud Firestore...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isConnected ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
