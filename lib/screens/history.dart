import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'alerts.dart';
import 'settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class HistoryItem {
  final DateTime date;
  final String title;
  final String subtitle;
  final String type;

  HistoryItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  late DateTime selectedDate;

  bool isLoading = true;

  List<HistoryItem> historyItems = [];

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

    @override
    void initState() {
      super.initState();

      selectedDate = DateTime.now();

      _listenToHistory();
    }
    Future<String> _getTargetUserId() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User is not logged in.');
  }

  final mappingSnapshot =
      await _dbRef.child('user_mappings').child(user.uid).get();

  if (mappingSnapshot.exists &&
      mappingSnapshot.value != null) {
    final mappingData =
        Map<String, dynamic>.from(
      mappingSnapshot.value as Map,
    );

    final customId =
        mappingData['customId']?.toString();

    if (customId != null &&
        customId.isNotEmpty) {
      return customId;
    }
  }

  throw Exception('User mapping not found.');
}
void _listenToHistory() async {
  try {
    final customId = await _getTargetUserId();

    final historyRef =
        _dbRef.child('users/$customId/history');

    historyRef.onValue.listen((event) {
      final List<HistoryItem> loadedItems = [];

      if (event.snapshot.exists &&
          event.snapshot.value != null) {
        final data =
            Map<dynamic, dynamic>.from(
          event.snapshot.value as Map,
        );

        data.forEach((key, value) {
          final item =
              Map<dynamic, dynamic>.from(value);

          loadedItems.add(
            HistoryItem(
              date:
                  DateTime.fromMillisecondsSinceEpoch(
                item['timestamp'] ?? 0,
              ),
              title:
                  item['title']?.toString() ?? '',
              subtitle:
                  item['subtitle']?.toString() ??
                      '',
              type:
                  item['type']?.toString() ??
                      'history',
            ),
          );
        });

        loadedItems.sort(
          (a, b) =>
              b.date.compareTo(a.date),
        );
      }

      if (mounted) {
        setState(() {
          historyItems = loadedItems;
          isLoading = false;
        });
      }
    });
  } catch (e) {
    debugPrint('History error: $e');

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
IconData _getIcon(String type) {
  switch (type) {
    case 'water_change':
      return Icons.water_drop;

    case 'temperature':
      return Icons.thermostat;

    case 'ph':
      return Icons.science;

    case 'recommendation':
      return Icons.tips_and_updates;

    default:
      return Icons.history;
  }
}
Color _getIconColor(String type) {
  switch (type) {
    case 'water_change':
      return Colors.green;

    case 'temperature':
      return Colors.orange;

    case 'ph':
      return Colors.blue;

    case 'recommendation':
      return Colors.deepPurple;

    default:
      return Colors.grey;
  }
}

  bool _isSameDate(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  List<HistoryItem> get filteredHistory {
    return historyItems.where((item) {
      return _isSameDate(
        item.date,
        selectedDate,
      );
    }).toList();
  }

  bool get isToday =>
      _isSameDate(
        selectedDate,
        DateTime.now(),
      );

  String _formatDate(DateTime date) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  Future<void> _showDateFilter() async {

  final DateTime? picked =
      await showDatePicker(
    context: context,
    initialDate: selectedDate,

    // Today is the earliest selectable date
      firstDate: DateTime(
        2024,
        1,
        1,
      ),

    // Last day of current year
    lastDate: DateTime.now(),
  );

  if (picked != null) {
    setState(() {
      selectedDate = picked;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F0DB),

      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor:
            const Color(0xFFF5F1E8),
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.history,
              color:
                  Color(0xFF1D2E47),
            ),
            SizedBox(width: 8),
            Text(
              'HISTORY',
              style: TextStyle(
                color:
                    Color(0xFF1D2E47),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month,
              color:
                  Color(0xFF1D2E47),
            ),
            onPressed:
                _showDateFilter,
            tooltip:
                'Filter by Date',
          ),
        ],
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isToday
                  ? 'Today'
                  : _formatDate(
                      selectedDate,
                    ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF1D2E47),
              ),
            ),

            const SizedBox(height: 8),

            if (!isToday)
              Text(
                'Viewing history for ${_formatDate(selectedDate)}',
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                  fontSize: 13,
                ),
              ),

            const SizedBox(height: 12),

            Expanded(
              child: filteredHistory
                      .isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 64,
                            color:
                                Colors.grey,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'No history records found for\n${_formatDate(selectedDate)}',
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          filteredHistory
                              .length,
                      itemBuilder:
                          (context,
                              index) {
                        final item =
                            filteredHistory[
                                index];
                      return _historyCard(
                        icon: _getIcon(item.type),
                        iconColor: _getIconColor(item.type),
                        title: item.title,
                        subtitle: item.subtitle,
                        time:
                            '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
                      );
                      },
                    ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor:
            const Color(0xFF1D2E47),
        unselectedItemColor:
            Colors.grey,
        type:
            BottomNavigationBarType
                .fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator
                  .pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const Dashboard(
                    aquariumName:
                        'My Aquarium',
                  ),
                ),
              );
              break;

            case 1:
              Navigator
                  .pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AlertsScreen(),
                ),
              );
              break;

            case 2:
              break;

            case 3:
              Navigator
                  .pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SettingsScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon:
                Icon(Icons.home),
            label:
                'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications,
            ),
            label:
                'Alerts',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.history),
            label:
                'History',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.settings),
            label:
                'Settings',
          ),
        ],
      ),
    );
  }

  static Widget _historyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              10,
            ),
            decoration:
                BoxDecoration(
              color:
                  iconColor.withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                    color: Color(
                      0xFF1D2E47,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            time,
            style:
                const TextStyle(
              color:
                  Colors.grey,
              fontSize:
                  12,
            ),
          ),
        ],
      ),
    );
  }
}