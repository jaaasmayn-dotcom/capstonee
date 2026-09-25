import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'history.dart';
import 'settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notification_service.dart';

class AlertItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String id;

  final String currentValue;
  final String targetRange;
  final String severity;
  final String detectedTime;
  final String status;

  bool isRead;

  AlertItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.targetRange,
    required this.severity,
    required this.detectedTime,
    required this.status,
    
    this.isRead = false,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DatabaseReference _dbRef =
    FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL:
          'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();

    Future<String> _getTargetUserId() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('No logged-in user.');
  }

  final mappingSnapshot =
      await _dbRef
          .child('user_mappings')
          .child(user.uid)
          .get();

  if (mappingSnapshot.exists &&
      mappingSnapshot.value != null) {
    final mapping =
        Map<dynamic, dynamic>.from(
      mappingSnapshot.value as Map,
    );

    return mapping['customId'];
  }

  throw Exception('Custom ID not found.');
}
    Future<void> _markAlertAsRead(
    AlertItem alert,
    ) async {
    try {
        final customId =
        await _getTargetUserId();

      await _dbRef
      .child('users')
      .child(customId)
      .child('alerts')
      .child(alert.id)
      .update({
      'isRead': true,
    });

      if (mounted) {
      setState(() {
      alert.isRead = true;
    });
    }
    } catch (e) {
      debugPrint(
      'MARK READ ERROR: $e',
    );
    }
    }
IconData _getIcon(String type) {
  switch (type) {
    case 'temperature':
      return Icons.thermostat;

    case 'ph':
      return Icons.water_drop;

    case 'success':
      return Icons.check_circle;

    default:
      return Icons.warning;
  }
}
Color _getColor(String severity) {
  switch (severity) {
    case 'Critical':
      return Colors.red;

    case 'Warning':
      return Colors.orange;

    case 'Resolved':
      return Colors.green;

    default:
      return Colors.blue;
  }
}
  Future<void> loadAlerts() async {
  try {
    final customId =
        await _getTargetUserId();

    final snapshot = await _dbRef
        .child('users')
        .child(customId)
        .child('alerts')
        .get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      if (mounted) {
        setState(() {
          alerts = [];
          isLoading = false;
        });
      }
      return;
    }

    final data =
        Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final List<AlertItem> loaded =
        [];

    data.forEach((key, value) {
      final alert =
          Map<dynamic, dynamic>.from(
        value,
      );

      loaded.add(
      AlertItem(
        id: key.toString(),
        icon: _getIcon(
          alert['type'] ?? '',
        ),
          iconColor: _getColor(
            alert['severity'] ?? '',
          ),
          title:
              alert['title'] ?? 'Alert',
          subtitle:
              alert['subtitle'] ?? '',
          currentValue:
              alert['currentValue'] ?? '',
          targetRange:
              alert['targetRange'] ?? '',
          severity:
              alert['severity'] ?? '',
          detectedTime:
              alert['detectedTime'] ?? '',
          status:
              alert['status'] ?? '',
          isRead:
              alert['isRead'] == true,
        ),
      );
    });

    if (mounted) {
      setState(() {
        alerts = loaded.reversed.toList();
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint(
      'ALERT ERROR: $e',
    );

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
      List<AlertItem> alerts = [];
      bool isLoading = true;

      @override
      void initState() {
        super.initState();
        loadAlerts();
      }
  List<AlertItem> get unreadAlerts =>
      alerts.where((alert) => !alert.isRead).toList();

  List<AlertItem> get readAlerts =>
      alerts.where((alert) => alert.isRead).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: Color(0xFF1D2E47)),
            SizedBox(width: 8),
            Text(
              'ALERTS',
              style: TextStyle(
                color: Color(0xFF1D2E47),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

    body: isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Unread Alerts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2E47),
            ),
          ),

          const SizedBox(height: 12),

          if (unreadAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text('No unread alerts.'),
            ),

          ...unreadAlerts.map((alert) => _buildAlertCard(alert)),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 20),

          const Text(
            'Read Alerts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2E47),
            ),
          ),

          const SizedBox(height: 12),

          if (readAlerts.isEmpty) const Text('No read alerts.'),

          ...readAlerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
      floatingActionButton:
    FloatingActionButton.extended(
  backgroundColor: const Color(0xFF1D2E47),
  foregroundColor: Colors.white,
  icon: const Icon(
    Icons.notifications_active,
  ),
  label: const Text(
    'Test Alert',
  ),
    onPressed: () async {
      final messenger =
          ScaffoldMessenger.of(context);

      final granted =
          await NotificationService
              .requestPermission();

      if (!mounted) return;

      if (!granted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied.',
            ),
          ),
        );
        return;
      }

      await NotificationService.showNotification(
        title: 'SENSORIYA ALERT',
        body: 'Notification system is working correctly.',
      );
    },
),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF1D2E47),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const Dashboard(aquariumName: 'My Aquarium'),
                ),
              );
              break;

            case 1:
              break;

            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    return InkWell(
      onTap: () {
        _showAlertDetails(alert);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (!alert.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alert.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert.icon, color: alert.iconColor),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontWeight: alert.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      color: const Color(0xFF1D2E47),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    alert.subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            if (alert.isRead)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Read',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
              ),

            const SizedBox(width: 8),

            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(AlertItem alert) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(alert.title),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Current Reading', alert.currentValue),
              _detailRow('Target Range', alert.targetRange),
              _detailRow('Severity', alert.severity),
              _detailRow('Detected', alert.detectedTime),
              _detailRow('Status', alert.status),
            ],
          ),

          actions: [
            if (!alert.isRead)
              TextButton(
                onPressed: () async {
                  await _markAlertAsRead(alert);

                  if (!mounted) return;

                  Navigator.pop(context);
                },
                child: const Text('Mark as Read'),
              ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
