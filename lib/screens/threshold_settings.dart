import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ThresholdSettingsScreen extends StatefulWidget {
  const ThresholdSettingsScreen({super.key});

  @override
  State<ThresholdSettingsScreen> createState() =>
      _ThresholdSettingsScreenState();
}

class _ThresholdSettingsScreenState extends State<ThresholdSettingsScreen> {
  // Constraints for small-to-medium aquariums
  static const double minDimensionCm = 15.0;
  static const double maxDimensionCm = 120.0;
  static const double minVolumeLiters = 9.5;
  static const double maxVolumeLiters = 208.0;
  

  // Preset dimension choices
  static const List<String> lengthOptions = [
    '30', '40', '41', '50', '51', '60', '61', '75', '76', '80', '90', '91', '122', 'Enter Custom'
  ];
  static const List<String> widthOptions = [
    '15', '18', '20', '25', '27', '30', '35', '45', '46', 'Enter Custom'
  ];
  static const List<String> heightOptions = [
    '18', '20', '24', '25', '27', '30', '35', '36', '40', '45', '46', '48', '53', '56', 'Enter Custom'
  ];

  RangeValues phRange = const RangeValues(6.5, 7.5);
  RangeValues tempRange = const RangeValues(23.0, 26.0);

  late TextEditingController aquariumNameController;
  late TextEditingController minPhController;
  late TextEditingController maxPhController;
  late TextEditingController minTempController;
  late TextEditingController maxTempController;
  late TextEditingController lengthController;
  late TextEditingController widthController;
  late TextEditingController heightController;

  late FocusNode lengthFocusNode;
  late FocusNode widthFocusNode;
  late FocusNode heightFocusNode;

  final GlobalKey _lengthKey = GlobalKey();
  final GlobalKey _widthKey = GlobalKey();
  final GlobalKey _heightKey = GlobalKey();

  bool isLengthCustom = false;
  bool isWidthCustom = false;
  bool isHeightCustom = false;
  

  RangeValues? stagedPhRange;
  RangeValues? stagedTempRange;
  String? stagedAquariumName;
  String? stagedLength;
  String? stagedWidth;
  String? stagedHeight;

  bool isEditingAquariumName = false;
  bool isEditingPh = false;
  bool isEditingTemp = false;
  bool isEditingDimensions = false;
  bool isLoading = true;

  DateTime? lastAquariumNameModifiedDate;
  DateTime? lastPhModifiedDate;
  bool phHasBeenModified = false;

  DateTime? lastTempModifiedDate;
  bool tempHasBeenModified = false;

  DateTime? lastDimensionsModifiedDate;
  bool dimensionsHasBeenModified = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  
  @override
  void initState() {
    super.initState();
    aquariumNameController = TextEditingController(text: '');
    minPhController = TextEditingController(text: '6.5');
    maxPhController = TextEditingController(text: '7.5');
    minTempController = TextEditingController(text: '23.0');
    maxTempController = TextEditingController(text: '26.0');
    lengthController = TextEditingController(text: '50');
    widthController = TextEditingController(text: '30');
    heightController = TextEditingController(text: '50');

    lengthFocusNode = FocusNode();
    widthFocusNode = FocusNode();
    heightFocusNode = FocusNode();

    aquariumNameController.addListener(() {
      if (isEditingAquariumName) setState(() {});
    });
    lengthController.addListener(() {
      if (isEditingDimensions) setState(() {});
    });
    widthController.addListener(() {
      if (isEditingDimensions) setState(() {});
    });
    heightController.addListener(() {
      if (isEditingDimensions) setState(() {});
    });
    
    _listenToDataFromFirebase();
  }
  
  @override
  void dispose() {
    aquariumNameController.dispose();
    minPhController.dispose();
    maxPhController.dispose();
    minTempController.dispose();
    maxTempController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();

    lengthFocusNode.dispose();
    widthFocusNode.dispose();
    heightFocusNode.dispose();
    super.dispose();
  }

  double? get _currentVolumeLiters {
    final l = double.tryParse(lengthController.text.trim());
    final w = double.tryParse(widthController.text.trim());
    final h = double.tryParse(heightController.text.trim());

    if (l != null && w != null && h != null && l > 0 && w > 0 && h > 0) {
      return (l * w * h) / 1000.0;
    }
    return null;
  }

  bool get _isWithinSmallMediumRange {
    final l = double.tryParse(lengthController.text.trim());
    final w = double.tryParse(widthController.text.trim());
    final h = double.tryParse(heightController.text.trim());
    final vol = _currentVolumeLiters;

    if (l == null || w == null || h == null || vol == null) return false;

    final sidesValid = l >= minDimensionCm &&
        l <= maxDimensionCm &&
        w >= minDimensionCm &&
        w <= maxDimensionCm &&
        h >= minDimensionCm &&
        h <= maxDimensionCm;

    final volumeValid = vol >= minVolumeLiters && vol <= maxVolumeLiters;

    return sidesValid && volumeValid;
  }

  bool get _isDimensionInputNotEmptyAndPositive {
    final l = double.tryParse(lengthController.text.trim());
    final w = double.tryParse(widthController.text.trim());
    final h = double.tryParse(heightController.text.trim());

    return l != null && l > 0 && w != null && w > 0 && h != null && h > 0;
  }

  Future<String> _getTargetUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {throw Exception('No authenticated user');
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
    throw Exception('User record not found');
  }

  void _listenToDataFromFirebase() async {
    try {
      final customId = await _getTargetUserId();
      final userRef = _dbRef.child('users/$customId');

      await userRef.keepSynced(true);

      userRef.onValue.listen((event) async {
        
        await Future.delayed(
          const Duration(milliseconds: 300),
        );
        if (event.snapshot.exists && event.snapshot.value != null) {
          final userData =
              Map<String, dynamic>.from(event.snapshot.value as Map);

          final settingsData = userData['settings'] != null
              ? Map<String, dynamic>.from(userData['settings'] as Map)
              : <String, dynamic>{};

          final thresholdData = userData['thresholdSettings'] != null
              ? Map<String, dynamic>.from(userData['thresholdSettings'] as Map)
              : settingsData;

          final dimensionsData = userData['dimensions'] != null
              ? Map<String, dynamic>.from(userData['dimensions'] as Map)
              : <String, dynamic>{};

          final fetchedAquariumName =
              settingsData['aquariumName']?.toString() ?? '';

          final rawMinPh = double.tryParse(
                  thresholdData['safeMinPh']?.toString() ?? '6.5') ??
              6.5;

          final maxPhVal = double.tryParse(
                  thresholdData['safeMaxPh']?.toString() ?? '7.5') ??
              7.5;

          final rawMinTemp = double.tryParse(
                  thresholdData['safeMinTemp']?.toString() ?? '23') ??
              23.0;

          final maxTempVal = double.tryParse(
                  thresholdData['safeMaxTemp']?.toString() ?? '26') ??
              26.0;
          final minPh = rawMinPh.clamp(6.0, 8.5);
          final maxPh = maxPhVal.clamp(6.0, 8.5);
          final minTemp = rawMinTemp.clamp(21.0, 29.0);
          final maxTemp = maxTempVal.clamp(21.0, 29.0);

          final rawLastAquariumNameModified =
              settingsData['lastAquariumNameModifiedDate'];

          final rawLastPhModified = thresholdData['lastPhModifiedDate'] ??
              settingsData['lastPhModifiedDate'];
          final rawPhHasBeenModified = thresholdData['phHasBeenModified'];

          final rawLastTempModified = thresholdData['lastTempModifiedDate'] ??
              settingsData['lastTempModifiedDate'];
          final rawTempHasBeenModified = thresholdData['tempHasBeenModified'];

          final rawDimensionsModified =
              dimensionsData['dimensionsHasBeenModified'] ??
                  settingsData['dimensionsHasBeenModified'];
          final rawLastDimensionsModified =
              dimensionsData['lastDimensionsModifiedDate'];

          final fetchedLength = dimensionsData['lengthCm']?.toString() ??
              settingsData['length']?.toString() ??
              '50';
          final fetchedWidth = dimensionsData['widthCm']?.toString() ??
              settingsData['width']?.toString() ??
              '30';
          final fetchedHeight = dimensionsData['heightCm']?.toString() ??
              settingsData['height']?.toString() ??
              '50';
        if (mounted) {
          Future.delayed(
            const Duration(milliseconds: 100),
            () {
              if (!mounted) return;

              setState(() {
                phRange = RangeValues(minPh, maxPh);
                tempRange = RangeValues(minTemp, maxTemp);

                if (rawLastAquariumNameModified != null) {
                  lastAquariumNameModifiedDate =
                      DateTime.tryParse(rawLastAquariumNameModified.toString());
                }

                if (rawLastPhModified != null) {
                  lastPhModifiedDate =
                      DateTime.tryParse(rawLastPhModified.toString());
                }

                if (rawPhHasBeenModified != null) {
                  phHasBeenModified = rawPhHasBeenModified == true ||
                      rawPhHasBeenModified.toString().toLowerCase() == 'true';
                }

                if (rawLastTempModified != null) {
                  lastTempModifiedDate =
                      DateTime.tryParse(rawLastTempModified.toString());
                }

                if (rawTempHasBeenModified != null) {
                  tempHasBeenModified = rawTempHasBeenModified == true ||
                      rawTempHasBeenModified.toString().toLowerCase() == 'true';
                }
                if (rawDimensionsModified != null) {
                  dimensionsHasBeenModified = rawDimensionsModified == true ||
                      rawDimensionsModified.toString().toLowerCase() == 'true';
                }
                if (rawLastDimensionsModified != null) {
                  lastDimensionsModifiedDate =
                      DateTime.tryParse(rawLastDimensionsModified.toString());
                }

                if (!isEditingAquariumName) {
                  aquariumNameController.text = fetchedAquariumName;
                }

                if (!isEditingPh) {
                  minPhController.text = minPh.toStringAsFixed(1);
                  maxPhController.text = maxPh.toStringAsFixed(1);
                }

                if (!isEditingTemp) {
                  minTempController.text = minTemp.toStringAsFixed(1);
                  maxTempController.text = maxTemp.toStringAsFixed(1);
                }

                if (!isEditingDimensions) {
                  lengthController.text = fetchedLength;
                  widthController.text = fetchedWidth;
                  heightController.text = fetchedHeight;
                }

                isLoading = false;
              });
            },
          );
        }
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      }, onError: (_) {
        if (mounted) setState(() => isLoading = false);
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _syncAquariumNameToFirebase(
      String newName, DateTime timestamp) async {
    try {
      final customId = await _getTargetUserId();
      await _dbRef.child('users/$customId/settings').update({
        'aquariumName': newName,
        'lastAquariumNameModifiedDate': timestamp.toIso8601String(),
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating aquarium name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncThresholdsToFirebase(Map<String, dynamic> data) async {
    try {
      final customId = await _getTargetUserId();
      data['updatedAt'] = ServerValue.timestamp;
      await _dbRef.child('users/$customId/thresholdSettings').update(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving thresholds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDimensionsToFirebase({
    required double length,
    required double width,
    required double height,
  }) async {
    try {
      final customId = await _getTargetUserId();
      final volumeLiters = (length * height * width) / 1000.0;
      final parsedVolume = double.parse(volumeLiters.toStringAsFixed(2));
      final nowIso = DateTime.now().toIso8601String();

      final Map<String, dynamic> updates = {
        'users/$customId/dimensions': {
          'lengthCm': length,
          'widthCm': width,
          'heightCm': height,
          'volumeLiters': parsedVolume,
          'dimensionsHasBeenModified': true,
          'lastDimensionsModifiedDate': nowIso,
          'updatedAt': ServerValue.timestamp,
        },
      };

      await _dbRef.update(updates);

      await _dbRef.child('users/$customId/settings/length').remove();
      await _dbRef.child('users/$customId/settings/width').remove();
      await _dbRef.child('users/$customId/settings/height').remove();
      await _dbRef.child('users/$customId/settings/volumeLiters').remove();
      await _dbRef
          .child('users/$customId/settings/dimensionsHasBeenModified')
          .remove();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dimensions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _canEditAquariumName() {
    if (lastAquariumNameModifiedDate == null) return true;
    final now = DateTime.now();
    return now.difference(lastAquariumNameModifiedDate!).inDays >= 30;
  }

  bool _canEditPh() {
    if (!phHasBeenModified || lastPhModifiedDate == null) return true;
    final now = DateTime.now();
    return now.difference(lastPhModifiedDate!).inDays >= 7;
  }

  int _getRemainingPhCooldownDays() {
    if (!phHasBeenModified || lastPhModifiedDate == null) return 0;
    final diff = DateTime.now().difference(lastPhModifiedDate!).inDays;
    return (7 - diff).clamp(1, 7);
  }

  bool _canEditTemp() {
    if (!tempHasBeenModified || lastTempModifiedDate == null) return true;
    final now = DateTime.now();
    return now.difference(lastTempModifiedDate!).inDays >= 7;
  }

  int _getRemainingTempCooldownDays() {
    if (!tempHasBeenModified || lastTempModifiedDate == null) return 0;
    final diff = DateTime.now().difference(lastTempModifiedDate!).inDays;
    return (7 - diff).clamp(1, 7);
  }

  void _showLimitSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _confirmAndSave({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await onConfirm();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Changes saved successfully.')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showDimensionWarningModal({required VoidCallback onProceedAnyway}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 20, 24, 20),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC63737),
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dimension Warning',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2E47),
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'One or more of your aquarium dimensions are set outside the recommended small-to-medium range. Do you wish to proceed with these dimensions?',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onProceedAnyway();
                  },
                  child: const Text(
                    'Proceed Anyway',
                    style: TextStyle(
                      color: Color(0xFFC63737),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D2E47),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showOutOfRangeWarningModal({
    required String title,
    required String message,
    required VoidCallback onProceedAnyway,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onProceedAnyway();
                  },
                  child: const Text(
                    'Proceed anyway',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D2E47),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Review'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditButton({required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Color(0xFF1D2E47), size: 18),
            SizedBox(width: 4),
            Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFF1D2E47),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD32F2F),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openNarrowDropdownMenu({
    required BuildContext context,
    required List<String> options,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<bool> onCustomChanged,
    bool isWidth = false,
  }) {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            if (isWidth)
              Positioned(
                right: 28,
                top: 200,
                height: 10 * 48.0 + 16.0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final val = options[index];
                          final isCustom = val == 'Enter Custom';

                          return InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              if (isCustom) {
                                onCustomChanged(true);
                                controller.clear();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  focusNode.requestFocus();
                                });
                              } else {
                                onCustomChanged(false);
                                controller.text = val;
                              }
                              setState(() {});
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.only(left: 12),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isCustom ? 'Enter Custom' : '$val cm',
                                style: TextStyle(
                                  fontSize: isCustom ? 12 : 13,
                                  color: const Color(0xFF2C2C2C),
                                  fontWeight: isCustom
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                right: 28,
                top: 200,
                bottom: 24,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final val = options[index];
                          final isCustom = val == 'Enter Custom';

                          return InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              if (isCustom) {
                                onCustomChanged(true);
                                controller.clear();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  focusNode.requestFocus();
                                });
                              } else {
                                onCustomChanged(false);
                                controller.text = val;
                              }
                              setState(() {});
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.only(left: 12),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isCustom ? 'Enter Custom' : '$val cm',
                                style: TextStyle(
                                  fontSize: isCustom ? 12 : 13,
                                  color: const Color(0xFF2C2C2C),
                                  fontWeight: isCustom
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDimensionDropdownField({
    required GlobalKey key,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> options,
    required bool isCustom,
    required ValueChanged<bool> onCustomChanged,
    bool isWidth = false,
  }) {
    if (isCustom && isEditingDimensions) {
      return TextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter custom dimension',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1D2E47)),
            tooltip: 'Select preset option',
            onPressed: () {
              _openNarrowDropdownMenu(
                context: context,
                options: options,
                controller: controller,
                focusNode: focusNode,
                onCustomChanged: onCustomChanged,
                isWidth: isWidth,
              );
            },
          ),
        ),
      );
    }

    final displayText = controller.text.isNotEmpty
        ? (options.contains(controller.text)
            ? (controller.text == 'Enter Custom'
                ? 'Enter Custom'
                : '${controller.text} cm')
            : '${controller.text} cm')
        : '';

    return InkWell(
      key: key,
      onTap: isEditingDimensions
          ? () {
              _openNarrowDropdownMenu(
                context: context,
                options: options,
                controller: controller,
                focusNode: focusNode,
                onCustomChanged: onCustomChanged,
                isWidth: isWidth,
              );
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: !isEditingDimensions,
          fillColor: isEditingDimensions
              ? Colors.transparent
              : const Color(0xFFF9F9F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isEditingDimensions
              ? const Icon(Icons.arrow_drop_down, color: Color(0xFF1D2E47))
              : null,
        ),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePh = isEditingPh ? (stagedPhRange ?? phRange) : phRange;
    final isPhOutOfRange = effectivePh.start < 6.5 || effectivePh.end > 7.5;

    final effectiveTemp =
        isEditingTemp ? (stagedTempRange ?? tempRange) : tempRange;
    final isTempOutOfRange =
        effectiveTemp.start < 23.0 || effectiveTemp.end > 26.0;

    final dimensionsChanged = isEditingDimensions &&
        (lengthController.text.trim() != (stagedLength ?? '') ||
            widthController.text.trim() != (stagedWidth ?? '') ||
            heightController.text.trim() != (stagedHeight ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        title: const Text(
          'Tank Configuration',
          style: TextStyle(
            color: Color(0xFF1D2E47),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF1D2E47),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D2E47)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Aquarium Name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2E47),
                              ),
                            ),
                            if (!isEditingAquariumName)
                              _buildEditButton(
                                onPressed: () {
                                  if (!_canEditAquariumName()) {
                                    _showLimitSnackBar(
                                      'Aquarium name can only be modified once a month.',
                                    );
                                    return;
                                  }
                                  setState(() {
                                    isEditingAquariumName = true;
                                    stagedAquariumName =
                                        aquariumNameController.text;
                                  });
                                },
                              )
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check,
                                      color: (aquariumNameController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              aquariumNameController.text
                                                      .trim() !=
                                                  (stagedAquariumName ?? ''))
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: (aquariumNameController.text
                                                .trim()
                                                .isNotEmpty &&
                                            aquariumNameController.text
                                                    .trim() !=
                                                (stagedAquariumName ?? ''))
                                        ? () {
                                            _confirmAndSave(
                                              title: 'Save Aquarium Name?',
                                              message:
                                                  'Are you sure you want to change the aquarium name? It can only be changed once a month.',
                                              onConfirm: () async {
                                                final now = DateTime.now();
                                                final newName =
                                                    aquariumNameController.text
                                                        .trim();
                                                setState(() {
                                                  lastAquariumNameModifiedDate =
                                                      now;
                                                  isEditingAquariumName = false;
                                                });

                                                await _syncAquariumNameToFirebase(
                                                  newName,
                                                  now,
                                                );
                                              },
                                            );
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        aquariumNameController.text =
                                            stagedAquariumName ?? '';
                                        isEditingAquariumName = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: aquariumNameController,
                          enabled: isEditingAquariumName,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(
                              RegExp(
                                r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
                              ),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Aquarium Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: !isEditingAquariumName,
                            fillColor: isEditingAquariumName
                                ? Colors.transparent
                                : const Color(0xFFF9F9F9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '* Can only be updated once a month.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'pH Range',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2E47),
                              ),
                            ),
                            if (!isEditingPh)
                              _buildEditButton(
                                onPressed: () {
                                  if (!_canEditPh()) {
                                    final remainingDays =
                                        _getRemainingPhCooldownDays();
                                    _showLimitSnackBar(
                                      'pH range can only be modified once per week. Available again in $remainingDays day${remainingDays > 1 ? "s" : ""}.',
                                    );
                                    return;
                                  }
                                  setState(() {
                                    isEditingPh = true;
                                    stagedPhRange = phRange;
                                    minPhController.text =
                                        phRange.start.toStringAsFixed(1);
                                    maxPhController.text =
                                        phRange.end.toStringAsFixed(1);
                                  });
                                },
                              )
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check,
                                      color: (stagedPhRange != null &&
                                              stagedPhRange != phRange)
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: (stagedPhRange != null &&
                                            stagedPhRange != phRange)
                                        ? () {
                                            void executeSave() {
                                              _confirmAndSave(
                                                title: 'Save pH Thresholds?',
                                                message:
                                                    'Are you sure you want to update the pH thresholds? This setting can only be modified once per week.',
                                                onConfirm: () async {
                                                  final now = DateTime.now();
                                                  setState(() {
                                                    phRange = stagedPhRange!;
                                                    minPhController.text =
                                                        phRange.start
                                                            .toStringAsFixed(1);
                                                    maxPhController.text =
                                                        phRange.end
                                                            .toStringAsFixed(1);
                                                    lastPhModifiedDate = now;
                                                    phHasBeenModified = true;
                                                    isEditingPh = false;
                                                  });
                                                    await _syncThresholdsToFirebase({
                                                      'safeMinPh': phRange.start,
                                                      'safeMaxPh': phRange.end,
                                                    'lastPhModifiedDate':
                                                        now.toIso8601String(),
                                                    'phHasBeenModified': true,
                                                  });
                                                },
                                              );
                                            }

                                            if (stagedPhRange!.start < 6.5 ||
                                                stagedPhRange!.end > 7.5) {
                                              _showOutOfRangeWarningModal(
                                                title:
                                                    'pH Warning: Outside Recommended Range',
                                                message:
                                                    'The selected pH range (${stagedPhRange!.start.toStringAsFixed(1)} - ${stagedPhRange!.end.toStringAsFixed(1)}) falls outside the recommended parameters (6.5 - 7.5). Are you sure you want to proceed?',
                                                onProceedAnyway: executeSave,
                                              );
                                            } else {
                                              executeSave();
                                            }
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        minPhController.text =
                                            phRange.start.toStringAsFixed(1);
                                        maxPhController.text =
                                            phRange.end.toStringAsFixed(1);
                                        isEditingPh = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minPhController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'MINIMUM pH',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: maxPhController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'MAXIMUM pH',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RangeSlider(
                          values: effectivePh,
                          min: 6.0,
                          max: 8.5,
                          activeColor: const Color(0xFF1D2E47),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: isEditingPh
                              ? (values) {
                                  setState(() {
                                    stagedPhRange = values;
                                    minPhController.text =
                                        values.start.toStringAsFixed(1);
                                    maxPhController.text =
                                        values.end.toStringAsFixed(1);
                                  });
                                }
                              : null,
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '6.0',
                              style: TextStyle(
                                color: Color(0xFF1D2E47),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '8.5',
                              style: TextStyle(
                                color: Color(0xFF1D2E47),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '* Fish thrive in a pH between 6.5 and 7.5.',
                          style: TextStyle(
                            color: Color(0xFF185F20),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPhOutOfRange)
                          _buildWarningBanner(
                            'Warning: pH is set outside the recommended range (below 6.5 or above 7.5).',
                          ),
                        const SizedBox(height: 6),
                        const Text(
                          '* Can only be updated once per week.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Temperature Range',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2E47),
                              ),
                            ),
                            if (!isEditingTemp)
                              _buildEditButton(
                                onPressed: () {
                                  if (!_canEditTemp()) {
                                    final remainingDays =
                                        _getRemainingTempCooldownDays();
                                    _showLimitSnackBar(
                                      'Temperature range can only be modified once per week. Available again in $remainingDays day${remainingDays > 1 ? "s" : ""}.',
                                    );
                                    return;
                                  }
                                  setState(() {
                                    isEditingTemp = true;
                                    stagedTempRange = tempRange;
                                    minTempController.text =
                                        tempRange.start.toStringAsFixed(1);
                                    maxTempController.text =
                                        tempRange.end.toStringAsFixed(1);
                                  });
                                },
                              )
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check,
                                      color: (stagedTempRange != null &&
                                              stagedTempRange != tempRange)
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: (stagedTempRange != null &&
                                            stagedTempRange != tempRange)
                                        ? () {
                                            void executeSave() {
                                              _confirmAndSave(
                                                title:
                                                    'Save Temperature Thresholds?',
                                                message:
                                                    'Are you sure you want to update the temperature thresholds? This setting can only be modified once per week.',
                                                onConfirm: () async {
                                                  final now = DateTime.now();
                                                  setState(() {
                                                    tempRange = stagedTempRange!;
                                                    minTempController.text =
                                                        tempRange.start
                                                            .toStringAsFixed(1);
                                                    maxTempController.text =
                                                        tempRange.end
                                                            .toStringAsFixed(1);
                                                    lastTempModifiedDate = now;
                                                    tempHasBeenModified = true;
                                                    isEditingTemp = false;
                                                  });

                                                  await _syncThresholdsToFirebase({
                                                    'safeMinTemp': tempRange.start,
                                                    'safeMaxTemp': tempRange.end,
                                                    'lastTempModifiedDate':
                                                        now.toIso8601String(),
                                                    'tempHasBeenModified': true,
                                                  });
                                                },
                                              );
                                            }

                                            if (stagedTempRange!.start < 23.0 ||
                                                stagedTempRange!.end > 26.0) {
                                              _showOutOfRangeWarningModal(
                                                title:
                                                    'Temperature Warning: Outside Recommended Range',
                                                message:
                                                    'The selected temperature range (${stagedTempRange!.start.toStringAsFixed(1)}°C - ${stagedTempRange!.end.toStringAsFixed(1)}°C) falls outside the recommended parameters (23.0°C - 26.0°C). Are you sure you want to proceed?',
                                                onProceedAnyway: executeSave,
                                              );
                                            } else {
                                              executeSave();
                                            }
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        minTempController.text =
                                            tempRange.start.toStringAsFixed(1);
                                        maxTempController.text =
                                            tempRange.end.toStringAsFixed(1);
                                        isEditingTemp = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minTempController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'MIN TEMP (°C)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: maxTempController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'MAX TEMP (°C)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RangeSlider(
                          values: effectiveTemp,
                          min: 21.0,
                          max: 29.0,
                          activeColor: const Color(0xFF1D2E47),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: isEditingTemp
                              ? (values) {
                                  setState(() {
                                    stagedTempRange = values;
                                    minTempController.text =
                                        values.start.toStringAsFixed(1);
                                    maxTempController.text =
                                        values.end.toStringAsFixed(1);
                                  });
                                }
                              : null,
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '21.0°C',
                              style: TextStyle(
                                color: Color(0xFF1D2E47),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '29.0°C',
                              style: TextStyle(
                                color: Color(0xFF1D2E47),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '* A range of 23°C to 26°C is ideal for most tropical community tanks.',
                          style: TextStyle(
                            color: Color(0xFF185F20),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isTempOutOfRange)
                          _buildWarningBanner(
                            'Warning: Temperature is set outside the recommended range (below 23°C or above 26°C).',
                          ),
                        const SizedBox(height: 6),
                        const Text(
                          '* Can only be updated once per week.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Aquarium Dimensions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2E47),
                              ),
                            ),
                            if (!isEditingDimensions)
                              _buildEditButton(
                                onPressed: () {
                                  if (dimensionsHasBeenModified) {
                                    _showLimitSnackBar(
                                      'Aquarium Dimensions can only be modified once.',
                                    );
                                    return;
                                  }
                                  setState(() {
                                    isEditingDimensions = true;
                                    stagedLength = lengthController.text;
                                    stagedWidth = widthController.text;
                                    stagedHeight = heightController.text;
                                  });
                                },
                              )
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check,
                                      color: (dimensionsChanged &&
                                              _isDimensionInputNotEmptyAndPositive)
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: (dimensionsChanged &&
                                            _isDimensionInputNotEmptyAndPositive)
                                        ? () {
                                            final parsedLength = double.parse(
                                                lengthController.text.trim());
                                            final parsedWidth = double.parse(
                                                widthController.text.trim());
                                            final parsedHeight = double.parse(
                                                heightController.text.trim());

                                            void executeSaveDimensions() {
                                              _confirmAndSave(
                                                title: 'Save Aquarium Dimensions?',
                                                message:
                                                    'Are you sure you want to update the aquarium dimensions? This action can only be performed once.',
                                                onConfirm: () async {
                                                  setState(() {
                                                    dimensionsHasBeenModified =
                                                        true;
                                                    lastDimensionsModifiedDate =
                                                        DateTime.now();
                                                    isEditingDimensions = false;
                                                  });

                                                  await _saveDimensionsToFirebase(
                                                    length: parsedLength,
                                                    width: parsedWidth,
                                                    height: parsedHeight,
                                                  );
                                                },
                                              );
                                            }

                                            if (!_isWithinSmallMediumRange) {
                                              _showDimensionWarningModal(
                                                onProceedAnyway:
                                                    executeSaveDimensions,
                                              );
                                            } else {
                                              executeSaveDimensions();
                                            }
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        lengthController.text =
                                            stagedLength ?? '';
                                        widthController.text =
                                            stagedWidth ?? '';
                                        heightController.text =
                                            stagedHeight ?? '';
                                        isLengthCustom = !lengthOptions
                                            .contains(lengthController.text);
                                        isWidthCustom = !widthOptions
                                            .contains(widthController.text);
                                        isHeightCustom = !heightOptions
                                            .contains(heightController.text);
                                        isEditingDimensions = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Allowed total volume: 9.5–208 Liters Capacity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDimensionDropdownField(
                          key: _lengthKey,
                          label: 'Length (cm)',
                          controller: lengthController,
                          focusNode: lengthFocusNode,
                          options: lengthOptions,
                          isCustom: isLengthCustom,
                          onCustomChanged: (val) {
                            setState(() => isLengthCustom = val);
                          },
                          isWidth: false,
                        ),
                        const SizedBox(height: 16),
                        _buildDimensionDropdownField(
                          key: _widthKey,
                          label: 'Width (cm)',
                          controller: widthController,
                          focusNode: widthFocusNode,
                          options: widthOptions,
                          isCustom: isWidthCustom,
                          onCustomChanged: (val) {
                            setState(() => isWidthCustom = val);
                          },
                          isWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _buildDimensionDropdownField(
                          key: _heightKey,
                          label: 'Height (cm)',
                          controller: heightController,
                          focusNode: heightFocusNode,
                          options: heightOptions,
                          isCustom: isHeightCustom,
                          onCustomChanged: (val) {
                            setState(() => isHeightCustom = val);
                          },
                          isWidth: false,
                        ),
                        if (_currentVolumeLiters != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _isWithinSmallMediumRange
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isWithinSmallMediumRange
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isWithinSmallMediumRange
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  size: 18,
                                  color: _isWithinSmallMediumRange
                                      ? const Color(0xFF185F20)
                                      : Colors.red.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isWithinSmallMediumRange
                                        ? 'Estimated Volume: ${_currentVolumeLiters!.toStringAsFixed(1)} Liters (Small–Medium tank)'
                                        : 'Estimated Volume: ${_currentVolumeLiters!.toStringAsFixed(1)} Liters (Outside small–medium range)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isWithinSmallMediumRange
                                          ? const Color(0xFF185F20)
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          '* Dimensions can only be changed once.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}