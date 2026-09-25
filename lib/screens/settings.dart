import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'alerts.dart';
import 'dashboard.dart';
import 'history.dart';
import 'splash2.dart';
import 'threshold_settings.dart';
import 'notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final String? ownerFirstName;

  const SettingsScreen({super.key, this.ownerFirstName});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool automaticWaterChange = false;
  bool enableNotifications = true;
  bool isLoading = true;
  DateTime? loadingStartTime;
  String aquariumName = 'My Aquarium';
  String ownerFirstName = '';
  String ownerLastName = '';

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();
    if (widget.ownerFirstName != null && widget.ownerFirstName!.isNotEmpty) {
      ownerFirstName = widget.ownerFirstName!;
    }
    loadingStartTime = DateTime.now();
    _claimActiveDeviceSession();
    _listenToUserDataAndSettingsFromFirebase();
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  Future<String> _getTargetUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final mappingSnapshot = await _dbRef
        .child('user_mappings')
        .child(user.uid)
        .get();

    if (mappingSnapshot.exists && mappingSnapshot.value != null) {
      final mappingData = Map<String, dynamic>.from(
        mappingSnapshot.value as Map,
      );
      final customId = mappingData['customId']?.toString();
      if (customId != null && customId.isNotEmpty) {
        return customId;
      }
    }

    final querySnapshot = await _dbRef
        .child('users')
        .orderByChild('firebaseUid')
        .equalTo(user.uid)
        .get();

    if (querySnapshot.exists && querySnapshot.value != null) {
      final data = Map<String, dynamic>.from(querySnapshot.value as Map);
      return data.keys.first;
    }

    throw Exception('User record not found in database.');
  }

  Future<void> _claimActiveDeviceSession() async {
    try {
      final customId = await _getTargetUserId();
      final user = FirebaseAuth.instance.currentUser;
      final currentFormattedTime = _formatDateTime(DateTime.now());

      await _dbRef.child('users/$customId').update({
        'isActive': true,
        'status': 'active',
        'lastLogin': currentFormattedTime,
      });

      await _dbRef.child('active_device/esp32_01').set({
        'assignedUserId': customId,
        'firebaseUid': user?.uid,
        'lastAssignedAt': currentFormattedTime,
      });
    } catch (e) {
      debugPrint('Error claiming active device session: $e');
    }
  }

  Future<void> _finishLoading() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _listenToUserDataAndSettingsFromFirebase() async {
    try {
      final customId = await _getTargetUserId();
      final userRef = _dbRef.child('users/$customId');

      await userRef.keepSynced(true);

      userRef.onValue.listen(
        (event) {
          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);

            final settingsData = data['settings'] != null
                ? Map<String, dynamic>.from(data['settings'] as Map)
                : <String, dynamic>{};

            if (mounted) {
              setState(() {
                ownerFirstName =
                    data['firstName']?.toString() ?? ownerFirstName;
                ownerLastName = data['lastName']?.toString() ?? '';

                automaticWaterChange =
                    settingsData['automaticWaterChange'] == true;

                enableNotifications = settingsData['notifications'] == true;

                aquariumName =
                    settingsData['aquariumName']?.toString() ?? 'My Aquarium';
              });

              _finishLoading();
            }
          } else if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Settings listener error: $error');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateFirebaseSetting(
    String key,
    dynamic value, {
    String? dateKey,
  }) async {
    try {
      final customId = await _getTargetUserId();
      final Map<String, dynamic> updates = {
        key: value,
        'updatedAt': _formatDateTime(DateTime.now()),
      };

      if (dateKey != null) {
        updates[dateKey] = _formatDateTime(DateTime.now());
      }

      await _dbRef.child('users/$customId/settings').update(updates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmToggle({
    required String title,
    required String message,
    required bool pendingValue,
    required String fieldKey,
    required String dateKey,
    required ValueChanged<bool> onConfirmed,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D2E47),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                onConfirmed(pendingValue);
                await _updateFirebaseSetting(
                  fieldKey,
                  pendingValue,
                  dateKey: dateKey,
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      setState(() {
        isLoading = true;
      });

      final customId = await _getTargetUserId();
      final currentFormattedTime = _formatDateTime(DateTime.now());

      // Deactivate user session and log formatted date/time
      await _dbRef.child('users/$customId').update({
        'isActive': false,
        'status': 'disabled',
        'lastLogout': currentFormattedTime,
      });

      final activeSnapshot =
          await _dbRef.child('active_device/esp32_01').get();
      if (activeSnapshot.exists && activeSnapshot.value != null) {
        final activeData =
            Map<String, dynamic>.from(activeSnapshot.value as Map);
        if (activeData['assignedUserId'] == customId) {
          await _dbRef.child('active_device/esp32_01').update({
            'assignedUserId': null,
            'firebaseUid': null,
            'unassignedAt': currentFormattedTime,
          });
        }
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Splash2()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Splash2()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout? Your account session will be disabled until you log in again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _performLogout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF1D2E47)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = '$ownerFirstName $ownerLastName'.trim();

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
                Icon(Icons.settings, color: Color(0xFF1D2E47)),
                SizedBox(width: 8),
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Color(0xFF1D2E47),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF1D2E47),
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        fullName.isNotEmpty ? fullName : 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2E47),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Automation & Maintenance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _settingsTile(
                        icon: Icons.tune_outlined,
                        title: 'Tank Configuration',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ThresholdSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      _settingsTile(
                        icon: Icons.water_drop_outlined,
                        title: 'Enable Automatic Water Change',
                        trailing: Switch(
                          value: automaticWaterChange,
                          activeThumbColor: const Color(0xFF1D2E47),
                          onChanged: (newValue) {
                            _confirmToggle(
                              title: newValue
                                  ? 'Enable Water Change?'
                                  : 'Disable Water Change?',
                              message: newValue
                                  ? 'Are you sure you want to enable automatic water change?'
                                  : 'Are you sure you want to disable automatic water change?',
                              pendingValue: newValue,
                              fieldKey: 'automaticWaterChange',
                              dateKey: 'lastAutomaticWaterChangeModifiedDate',
                              onConfirmed: (val) {
                                setState(() {
                                  automaticWaterChange = val;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      _settingsTile(
                        icon: Icons.notifications_none,
                        title: 'Enable Notifications',
                        trailing: Switch(
                          value: enableNotifications,
                          activeThumbColor: const Color(0xFF1D2E47),
                          onChanged: (newValue) async {
                            if (newValue) {
                              final granted =
                                  await NotificationService.requestPermission();

                              if (!granted) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notification permission was denied.',
                                    ),
                                  ),
                                );

                                return;
                              }
                            }

                            _confirmToggle(
                              title: newValue
                                  ? 'Enable Notifications?'
                                  : 'Disable Notifications?',
                              message: newValue
                                  ? 'Are you sure you want to enable notifications?'
                                  : 'Are you sure you want to disable notifications?',
                              pendingValue: newValue,
                              fieldKey: 'notifications',
                              dateKey: 'lastNotificationsModifiedDate',
                              onConfirmed: (val) {
                                setState(() {
                                  enableNotifications = val;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8D7DA),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 3,
            selectedItemColor: const Color(0xFF1D2E47),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Dashboard(aquariumName: aquariumName),
                    ),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                  break;
                case 3:
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
        if (isLoading)
          Container(
            color: const Color(0xFFF0F0DB),
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D2E47)),
            ),
          ),
      ],
    );
  }
}