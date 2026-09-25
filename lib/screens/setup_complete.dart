import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard.dart';

class SetupComplete extends StatefulWidget {
  const SetupComplete({super.key});

  @override
  State<SetupComplete> createState() => _SetupCompleteState();
}

class _SetupCompleteState extends State<SetupComplete>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;

  bool isLoading = false;
  late Future<Map<String, dynamic>?> _userSettingsFuture;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();
    _userSettingsFuture = _fetchUserSettings();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
    );

    fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final querySnapshot = await _dbRef
        .child('users')
        .orderByChild('firebaseUid')
        .equalTo(user.uid)
        .get();

    if (querySnapshot.exists && querySnapshot.value != null) {
      final data = Map<String, dynamic>.from(querySnapshot.value as Map);
      final customIdNode =
          Map<String, dynamic>.from(data.values.first as Map);

      final settings = customIdNode['settings'] != null
          ? Map<String, dynamic>.from(customIdNode['settings'] as Map)
          : <String, dynamic>{};

      final dimensions = customIdNode['dimensions'] != null
          ? Map<String, dynamic>.from(customIdNode['dimensions'] as Map)
          : <String, dynamic>{};

      final thresholdSettings = customIdNode['thresholdSettings'] != null
          ? Map<String, dynamic>.from(customIdNode['thresholdSettings'] as Map)
          : <String, dynamic>{};

      return {
        'aquariumName': settings['aquariumName'] ?? 'N/A',
        'automaticWaterChange': settings['automaticWaterChange'] == true,
        'notifications': settings['notifications'] == true,
        'minPh': thresholdSettings['minPh'] ?? settings['minPh'] ?? '0',
        'maxPh': thresholdSettings['maxPh'] ?? settings['maxPh'] ?? '0',
        'minTemp': thresholdSettings['minTemp'] ?? settings['minTemp'] ?? '0',
        'maxTemp': thresholdSettings['maxTemp'] ?? settings['maxTemp'] ?? '0',
        'length': dimensions['lengthCm'] ?? settings['length'] ?? '0',
        'height': dimensions['heightCm'] ?? settings['height'] ?? '0',
        'width': dimensions['widthCm'] ?? settings['width'] ?? '0',
      };
    }
    return null;
  }

  Widget buildInfoTile(
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2E47),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF185F20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0DB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Column(
                children: [
                  Image.asset(
                    'assets/logos/sensoriya.png',
                    height: 120,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SENSORIYA',
                    style: TextStyle(
                      fontSize: 39,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2E47),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: 1,
                    ),
                    duration: const Duration(
                      milliseconds: 1500,
                    ),
                    builder: (
                      context,
                      value,
                      child,
                    ) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: const Color(
                          0xFFE0E0E0,
                        ),
                        color: const Color(
                          0xFF185F20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: _userSettingsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF185F20),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                            child: Text(
                              'Failed to load setup configurations.',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final aquariumName = data['aquariumName'] ?? 'N/A';
                        final minPh = data['minPh'] ?? '0';
                        final maxPh = data['maxPh'] ?? '0';
                        final minTemp = data['minTemp'] ?? '0';
                        final maxTemp = data['maxTemp'] ?? '0';
                        final length = data['length'] ?? '0';
                        final height = data['height'] ?? '0';
                        final width = data['width'] ?? '0';
                        final autoWaterChange =
                            data['automaticWaterChange'] == true;
                        final notifications = data['notifications'] == true;

                        return Column(
                          children: [
                            ScaleTransition(
                              scale: scaleAnimation,
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(
                                  0xFF185F20,
                                ),
                                size: 100,
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              'Setup Complete!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFF185F20,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: 1,
                              ),
                              duration: const Duration(
                                milliseconds: 1800,
                              ),
                              builder: (
                                context,
                                value,
                                child,
                              ) {
                                return Opacity(
                                  opacity: value,
                                  child: child,
                                );
                              },
                              child: const Text(
                                'Your aquarium has been configured successfully.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            buildInfoTile(
                              'Aquarium Name',
                              aquariumName,
                            ),
                            buildInfoTile(
                              'pH Range',
                              '$minPh - $maxPh',
                            ),
                            buildInfoTile(
                              'Temperature Range',
                              '$minTemp°C - $maxTemp°C',
                            ),
                            buildInfoTile(
                              'Length',
                              '$length cm',
                            ),
                            buildInfoTile(
                              'Height',
                              '$height cm',
                            ),
                            buildInfoTile(
                              'Width',
                              '$width cm',
                            ),
                            buildInfoTile(
                              'Automatic Water Change',
                              autoWaterChange ? 'Enabled' : 'Disabled',
                            ),
                            buildInfoTile(
                              'Notifications',
                              notifications ? 'Enabled' : 'Disabled',
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: !isLoading
                                    ? () async {
                                        setState(() {
                                          isLoading = true;
                                        });

                                        await Future.delayed(
                                          const Duration(seconds: 1),
                                        );

                                        if (!context.mounted) return;

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Dashboard(
                                              aquariumName: aquariumName,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D2E47),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFF1D2E47)
                                          .withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Loading...',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Start Monitoring!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}