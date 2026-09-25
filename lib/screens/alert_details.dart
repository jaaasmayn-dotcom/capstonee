import 'package:flutter/material.dart';

class AlertDetailsScreen extends StatelessWidget {
  final String title;
  final String currentValue;
  final String targetRange;
  final String severity;
  final String detectedTime;
  final String status;
  final Color severityColor;

  const AlertDetailsScreen({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetRange,
    required this.severity,
    required this.detectedTime,
    required this.status,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        title: const Text(
          'Alert Details',
          style: TextStyle(
            color: Color(0xFF1D2E47),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF1D2E47),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: severityColor,
                        size: 30,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF1D2E47),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _detailRow(
                    'Current Reading',
                    currentValue,
                  ),

                  _detailRow(
                    'Target Range',
                    targetRange,
                  ),

                  _detailRow(
                    'Severity',
                    severity,
                  ),

                  _detailRow(
                    'Detected',
                    detectedTime,
                  ),

                  _detailRow(
                    'Status',
                    status,
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Alert marked as resolved.',
                      ),
                    ),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF1D2E47,
                  ),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Text(
                  'MARK AS RESOLVED',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
                color: Color(0xFF1D2E47),
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}