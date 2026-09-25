import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'alerts.dart';
import 'history.dart';
import 'settings.dart';

class Dashboard extends StatefulWidget {
  final String aquariumName;

  const Dashboard({
    super.key,
    required this.aquariumName,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  late String currentAquariumName;

  String minPh = '6.5';
  String maxPh = '7.5';
  String minTemp = '23.0';
  String maxTemp = '26.0';

  String currentPh = '--';
  String currentTemperature = '--';

  bool isLoading = true;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();

    currentAquariumName = widget.aquariumName;

    _listenToUserData();
    _listenToSensorData();
    _finishLoading();
  }

  Future<void> _finishLoading() async {
    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _getTargetUserId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No authenticated user.');
    }

    final querySnapshot = await _dbRef
        .child('users')
        .orderByChild('firebaseUid')
        .equalTo(user.uid)
        .get();

    if (querySnapshot.exists && querySnapshot.value != null) {
      final data =
          Map<String, dynamic>.from(querySnapshot.value as Map);

      return data.keys.first;
    }

    throw Exception('User record not found.');
  }

  void _listenToUserData() async {
    try {
      final customId = await _getTargetUserId();

      final userRef = _dbRef.child('users/$customId');

      await userRef.keepSynced(true);

      userRef.onValue.listen((event) {
        if (!event.snapshot.exists ||
            event.snapshot.value == null) {
          return;
        }

        final userData =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        final settingsData = userData['settings'] != null
            ? Map<String, dynamic>.from(
                userData['settings'] as Map,
              )
            : <String, dynamic>{};

        final thresholdData =
            userData['thresholdSettings'] != null
                ? Map<String, dynamic>.from(
                    userData['thresholdSettings'] as Map,
                  )
                : <String, dynamic>{};

        if (mounted) {
          setState(() {
            currentAquariumName =
                settingsData['aquariumName']?.toString() ??
                    currentAquariumName;

            minPh =
                thresholdData['safeMinPh']?.toString() ??
                    '6.5';

            maxPh =
                thresholdData['safeMaxPh']?.toString() ??
                    '7.5';

            minTemp =
                thresholdData['safeMinTemp']?.toString() ??
                    '23';

            maxTemp =
                thresholdData['safeMaxTemp']?.toString() ??
                    '26';
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _listenToSensorData() async {
    try {
      final customId = await _getTargetUserId();

      _dbRef
          .child('users')
          .child(customId)
          .child('liveMonitoring')
          .onValue
          .listen((event) {
        if (!event.snapshot.exists ||
            event.snapshot.value == null) {
          return;
        }

        final data =
            Map<dynamic, dynamic>.from(
                event.snapshot.value as Map);

        if (mounted) {
          setState(() {
            currentPh =
                data['ph']?.toString() ?? '--';

            currentTemperature =
                data['temperature'] != null
                    ? '${data['temperature']}°C'
                    : '--';
          });
        }
      });
    } catch (e) {
      debugPrint(
        'Error loading sensor data: $e',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.water_drop_outlined, color: Color(0xFF1D2E47)),
            SizedBox(width: 8),
            Text(
              'SENSORIYA',
              style: TextStyle(
                color: Color(0xFF1D2E47),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAquariumName,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2E47),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Real-Time Monitoring',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sensorCard(
                      title: 'PH LEVEL',
                      value: currentPh,
                      target: 'Target: $minPh - $maxPh',
                      icon: Icons.science_outlined,
                    ),
                    const SizedBox(height: 10),
                    _sensorCard(
                      title: 'TEMPERATURE',
                      value: currentTemperature,
                      target: 'Target: $minTemp - $maxTemp°C',
                      icon: Icons.thermostat,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                color: Color(0xFF1D2E47),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: const Text( 'Recommendations',
                                  style:TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1D2E47),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                            const Text(
                              'No recommendations available at this time.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: null, // Disable the button for now
                              // onPressed: () {
                               // Navigator.push(
                               //   context,
                                //  MaterialPageRoute(
                                 //   builder: (context) =>
                                  //      const RecommendationsScreen(),
                                 // ),
                               // ); 
                              child: const Text(''),
                            ),    
                            ),
                      ],
                    ),    
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history, color: Color(0xFF1D2E47)),
                              SizedBox(width: 8),
                              Text(
                                'Water Change History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2E47),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No water change records available.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Confirm Water Change'),
                          content: const Text(
                            'Are you sure you want to initiate a water change?',
                          ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),

                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ Partial water change completed.',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    
                                    await Future.delayed(
                                      const Duration(seconds: 2),
                                    );

                                    if (!mounted) return;
                                    
                                    if (!context.mounted) return; 
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ Water change completed.',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D2E47),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Start'),
                                ),
                              ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.water_drop),
                  label: const Text('INITIATE WATER CHANGE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D2E47),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1D2E47),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    ),
    if (isLoading)
      Container(
        color: const Color(0xFFF0F0DB),
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1D2E47),
          ),
        ),
      ),
      ],
);
  }

  static Widget _sensorCard({
    required String title,
    required String value,
    required String target,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFF1D2E47),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 34,
                    color: Color(0xFF1D2E47),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(target),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1D2E47)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE7D0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('OPTIMAL'),
              ),
            ],
          ),
        ],
      ),
    );
  }

}