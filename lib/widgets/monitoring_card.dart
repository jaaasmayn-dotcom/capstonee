import 'package:flutter/material.dart';
import '../theme/theme_constants.dart';

class MonitoringCard extends StatelessWidget {
  final String title;
  final String value;
  final String safeRange;
  final String? status;

  const MonitoringCard({
    super.key,
    required this.title,
    required this.value,
    required this.safeRange,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeConstants.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (status != null) ...[
            const SizedBox(height: 8),

            Text(
              status!,
              style: TextStyle(
                color: status == "OPTIMAL"
                    ? ThemeConstants.optimalGreen
                    : ThemeConstants.criticalRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          const SizedBox(height: 10),

          Text(
            'Safe Range: $safeRange',
            style: TextStyle(
              color:
                  ThemeConstants.textLight,
            ),
          ),
        ],
      ),
    );
  }
}