import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  // ==========================
  // DUMMY DATA (Firebase Later)
  // ==========================

static double currentPh = 8.0;
static double currentTemp = 27.0;

static double minPh = 6.5;
static double maxPh = 7.5;

static double minTemp = 23.0;
static double maxTemp = 26.0;

static int correctionAttempts = 2;

  // ==========================
  // RECOMMENDATION LOGIC
  // ==========================

 static Map<String, dynamic> getRecommendation() {
    bool phUnsafe =
        currentPh < minPh || currentPh > maxPh;

    bool tempUnsafe =
        currentTemp < minTemp ||
        currentTemp > maxTemp;

    // System is still attempting correction
    if (correctionAttempts < 2) {
      return {
        'priority': 'MEDIUM',
        'title': 'Automatic Correction In Progress',
        'analysis':
            'The system is currently attempting to restore safe water conditions.',
        'actions': [
          'Continue monitoring water conditions.',
        ],
      };
    }

    // Both parameters unsafe
    if (phUnsafe && tempUnsafe) {
      return {
        'priority': 'CRITICAL',
        'title': 'Multiple Water Quality Issues',
        'analysis':
            'Both pH and temperature remain outside the configured thresholds despite automated corrective actions.',
        'actions': [
          'Perform an immediate manual water change.',
          'Inspect filtration components.',
          'Inspect heater operation.',
          'Verify sensor calibration.',
          'Monitor fish behavior closely.',
        ],
      };
    }

    // High pH
    if (currentPh > maxPh) {
      return {
        'priority': 'HIGH',
        'title': 'High pH Detected',
        'analysis':
            'The pH level remains above the safe threshold despite automatic correction.',
        'actions': [
          'Perform a manual 20–30% water change.',
          'Inspect filtration components.',
          'Check water source quality.',
          'Verify pH sensor calibration.',
        ],
      };
    }

    // Low pH
    if (currentPh < minPh) {
      return {
        'priority': 'HIGH',
        'title': 'Low pH Detected',
        'analysis':
            'The pH level remains below the configured threshold.',
        'actions': [
          'Perform a partial water change.',
          'Inspect aquarium substrate.',
          'Remove accumulated waste.',
          'Verify pH sensor calibration.',
        ],
      };
    }

    // High Temperature
    if (currentTemp > maxTemp) {
      return {
        'priority': 'HIGH',
        'title': 'High Temperature Detected',
        'analysis':
            'The aquarium temperature remains above the configured threshold.',
        'actions': [
          'Inspect heater settings.',
          'Increase aeration.',
          'Reduce direct sunlight exposure.',
          'Improve water circulation.',
        ],
      };
    }

    // Low Temperature
    if (currentTemp < minTemp) {
      return {
        'priority': 'HIGH',
        'title': 'Low Temperature Detected',
        'analysis':
            'The aquarium temperature remains below the configured threshold.',
        'actions': [
          'Check heater operation.',
          'Inspect power supply.',
          'Verify temperature settings.',
        ],
      };
    }

    return {
      'priority': 'LOW',
      'title': 'No Recommendation Required',
      'analysis':
          'The aquarium parameters remain within safe operating thresholds.',
      'actions': [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final reco = RecommendationsScreen.getRecommendation();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F1E8),
        title: const Text(
          'Recommendation!',
          style: TextStyle(
            color: Color(0xFF1D2E47),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // STATUS BANNER

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    reco['priority'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    reco['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2E47),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    reco['analysis'],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SMART RECOMMENDATION

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Smart Recommendation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF185F20),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...List.generate(
                    reco['actions'].length,
                    (index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(
                                0xFF185F20,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                reco['actions'][index],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TREND SECTION
            // Replace with fl_chart later

           const SizedBox(height: 16),

// CURRENT WATER CONDITIONS

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF1D2E47),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Current Water Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2E47),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F1E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Current pH',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                RecommendationsScreen.currentPh
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2E47),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Safe Range\n${RecommendationsScreen.minPh} - ${RecommendationsScreen.maxPh}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F1E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Temperature',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                '${RecommendationsScreen.currentTemp.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2E47),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Safe Range\n${RecommendationsScreen.minTemp} - ${RecommendationsScreen.maxTemp}°C',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AUTOMATIC RECOVERY SUMMARY

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Color(0xFF1D2E47),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Automatic Recovery Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2E47),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.water,
                          color: Color(0xFF185F20),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            '${RecommendationsScreen.correctionAttempts} Automatic Partial Water Change${RecommendationsScreen.correctionAttempts > 1 ? 's' : ''} Performed',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Divider(),

                  const SizedBox(height: 14),

                  const Text(
                    'Why Recommendation Was Generated',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    reco['analysis'],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

// TREND SECTION
          ],
        ),
      ),
    );
  }
}