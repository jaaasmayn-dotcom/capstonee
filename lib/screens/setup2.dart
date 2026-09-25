import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'setup1.dart';
import 'setup_complete.dart';

class Setup2 extends StatefulWidget {
  final String minPh;
  final String maxPh;
  final String minTemp;
  final String maxTemp;

  const Setup2({
    super.key,
    required this.minPh,
    required this.maxPh,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  State<Setup2> createState() => _Setup2State();
}

class _Setup2State extends State<Setup2> {
  // Recommended ranges for small-to-medium aquariums
  static const double minDimensionCm = 15.0;
  static const double maxDimensionCm = 120.0;
  static const double minVolumeLiters = 9.5;
  static const double maxVolumeLiters = 208.0;

  // Preset dimension choices matching tankconfig
  static const List<String> lengthOptions = [
    '30', '40', '41', '50', '51', '60', '61', '75', '76', '80', '90', '91', '122', 'Enter Custom'
  ];

  static const List<String> widthOptions = [
    '15', '18', '20', '25', '27', '30', '35', '45', '46', 'Enter Custom'
  ];

  static const List<String> heightOptions = [
    '18', '20', '24', '25', '27', '30', '35', '36', '40', '45', '46', '48', '53', '56', 'Enter Custom'
  ];

  // GlobalKeys for dimension dropdown alignment
  final GlobalKey _lengthKey = GlobalKey();
  final GlobalKey _widthKey = GlobalKey();
  final GlobalKey _heightKey = GlobalKey();

  // Track if custom editable mode is active for each dimension
  bool isLengthCustom = false;
  bool isWidthCustom = false;
  bool isHeightCustom = false;

  final aquariumNameController = TextEditingController();
  final lengthController = TextEditingController();
  final heightController = TextEditingController();
  final widthController = TextEditingController();

  final FocusNode lengthFocusNode = FocusNode();
  final FocusNode heightFocusNode = FocusNode();
  final FocusNode widthFocusNode = FocusNode();

  bool automaticWaterChange = false;
  bool notifications = false; // Off by default
  bool isLoading = false;

  String? aquariumNameError;
  String? lengthError;
  String? heightError;
  String? widthError;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void dispose() {
    aquariumNameController.dispose();
    lengthController.dispose();
    heightController.dispose();
    widthController.dispose();
    lengthFocusNode.dispose();
    heightFocusNode.dispose();
    widthFocusNode.dispose();
    super.dispose();
  }

  double? get currentVolumeLiters {
    final l = double.tryParse(lengthController.text.trim());
    final h = double.tryParse(heightController.text.trim());
    final w = double.tryParse(widthController.text.trim());

    if (l != null && h != null && w != null && l > 0 && h > 0 && w > 0) {
      return (l * h * w) / 1000.0;
    }
    return null;
  }

  bool get isWithinSmallMediumRange {
    final l = double.tryParse(lengthController.text.trim());
    final h = double.tryParse(heightController.text.trim());
    final w = double.tryParse(widthController.text.trim());
    final vol = currentVolumeLiters;

    if (l == null || h == null || w == null || vol == null) return false;

    final sidesValid = l >= minDimensionCm &&
        l <= maxDimensionCm &&
        w >= minDimensionCm &&
        w <= maxDimensionCm &&
        h >= minDimensionCm &&
        h <= maxDimensionCm;

    final volumeValid = vol >= minVolumeLiters && vol <= maxVolumeLiters;

    return sidesValid && volumeValid;
  }

  bool get isOutsideRecommendedRange {
    final l = double.tryParse(lengthController.text.trim());
    final h = double.tryParse(heightController.text.trim());
    final w = double.tryParse(widthController.text.trim());

    if (l == null || h == null || w == null) return false;
    return !isWithinSmallMediumRange;
  }

  bool get canFinish {
    final l = double.tryParse(lengthController.text.trim());
    final h = double.tryParse(heightController.text.trim());
    final w = double.tryParse(widthController.text.trim());

    return aquariumNameController.text.trim().isNotEmpty &&
        l != null &&
        l > 0 &&
        h != null &&
        h > 0 &&
        w != null &&
        w > 0 &&
        aquariumNameError == null &&
        lengthError == null &&
        widthError == null &&
        heightError == null;
  }

  void validateAquariumName(String value) {
    aquariumNameError =
        value.trim().isEmpty ? 'Aquarium name is required' : null;
  }

  void _validateDimension(
      String value, String fieldName, Function(String?) setError) {
    final val = double.tryParse(value.trim());
    if (val == null || val <= 0) {
      setError('Enter a valid $fieldName');
    } else {
      setError(null);
    }
  }

  void validateLength(String value) =>
      _validateDimension(value, 'Length', (err) => lengthError = err);

  void validateHeight(String value) =>
      _validateDimension(value, 'Height', (err) => heightError = err);

  void validateWidth(String value) =>
      _validateDimension(value, 'Width', (err) => widthError = err);

  void _navigateBackToSetup1() {
    if (isLoading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Setup1(),
      ),
    );
  }

  void _handleFinishSetupClick() {
    if (isOutsideRecommendedRange) {
      _showWarningDialog();
    } else {
      _saveSettingsToFirebase();
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
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
                    Navigator.of(ctx).pop();
                    _saveSettingsToFirebase();
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
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
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

  void _openNarrowDropdownMenu({
    required BuildContext context,
    required List<String> options,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<bool> onCustomChanged,
    required Function(String) onValueChanged,
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
                top: 240,
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
                                onValueChanged('');
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  focusNode.requestFocus();
                                });
                              } else {
                                onCustomChanged(false);
                                controller.text = val;
                                onValueChanged(val);
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
                top: 240,
                bottom: 40,
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
                                onValueChanged('');
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  focusNode.requestFocus();
                                });
                              } else {
                                onCustomChanged(false);
                                controller.text = val;
                                onValueChanged(val);
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
    required String? errorText,
    required ValueChanged<bool> onCustomChanged,
    required Function(String) onValueChanged,
    bool isWidth = false,
  }) {
    if (isCustom) {
      return TextField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: (val) {
          onValueChanged(val);
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter custom dimension',
          errorText: errorText,
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
                onValueChanged: onValueChanged,
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
      onTap: () {
        _openNarrowDropdownMenu(
          context: context,
          options: options,
          controller: controller,
          focusNode: focusNode,
          onCustomChanged: onCustomChanged,
          onValueChanged: onValueChanged,
          isWidth: isWidth,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon:
              const Icon(Icons.arrow_drop_down, color: Color(0xFF1D2E47)),
        ),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  Future<void> _saveSettingsToFirebase() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final querySnapshot = await _dbRef
          .child('users')
          .orderByChild('firebaseUid')
          .equalTo(user.uid)
          .get();

      String targetCustomId = '';

      if (querySnapshot.exists && querySnapshot.value != null) {
        final data = Map<String, dynamic>.from(querySnapshot.value as Map);
        targetCustomId = data.keys.first;
      } else {
        targetCustomId = 'user_02';
      }

      final parsedLength = double.tryParse(lengthController.text.trim()) ?? 0.0;
      final parsedHeight = double.tryParse(heightController.text.trim()) ?? 0.0;
      final parsedWidth = double.tryParse(widthController.text.trim()) ?? 0.0;
      final volumeLiters = (parsedLength * parsedHeight * parsedWidth) / 1000.0;
      final nowIso = DateTime.now().toIso8601String();

      final Map<String, dynamic> updates = {
        'users/$targetCustomId/dimensions': {
          'lengthCm': parsedLength,
          'heightCm': parsedHeight,
          'widthCm': parsedWidth,
          'volumeLiters': double.parse(volumeLiters.toStringAsFixed(2)),
          'dimensionsHasBeenModified': false,
          'lastDimensionsModifiedDate': nowIso,
          'updatedAt': ServerValue.timestamp,
        },
        'users/$targetCustomId/thresholdSettings': {
          'minPh': widget.minPh,
          'maxPh': widget.maxPh,
          'minTemp': widget.minTemp,
          'maxTemp': widget.maxTemp,
          'lastPhModifiedDate': nowIso,
          'lastTempModifiedDate': nowIso,
          'updatedAt': ServerValue.timestamp,
        },
        'users/$targetCustomId/settings': {
          'aquariumName': aquariumNameController.text.trim(),
          'lastAquariumNameModifiedDate': nowIso,
          'automaticWaterChange': automaticWaterChange,
          'lastAutomaticWaterChangeModifiedDate': nowIso,
          'notifications': notifications,
          'lastNotificationsModifiedDate': nowIso,
          'updatedAt': ServerValue.timestamp,
        },
      };

      await _dbRef.update(updates);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SetupComplete(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving setup data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBackToSetup1();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0DB),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEEBA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The details entered here can only be modified later in Settings, so please review them carefully before proceeding.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aquarium Setup',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF185F20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Step 2 of 2',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const LinearProgressIndicator(
                              value: 1.0,
                              minHeight: 8,
                              backgroundColor: Color(0xFFE0E0E0),
                              color: Color(0xFF185F20),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Aquarium Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF185F20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: aquariumNameController,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                RegExp(
                                  r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                validateAquariumName(value);
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Aquarium Name',
                              errorText: aquariumNameError,
                              suffixIcon:
                                  aquariumNameController.text.trim().isNotEmpty
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Aquarium Dimensions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF185F20),
                            ),
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
                            errorText: lengthError,
                            onCustomChanged: (val) {
                              setState(() => isLengthCustom = val);
                            },
                            onValueChanged: validateLength,
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
                            errorText: widthError,
                            onCustomChanged: (val) {
                              setState(() => isWidthCustom = val);
                            },
                            onValueChanged: validateWidth,
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
                            errorText: heightError,
                            onCustomChanged: (val) {
                              setState(() => isHeightCustom = val);
                            },
                            onValueChanged: validateHeight,
                            isWidth: false,
                          ),
                          if (currentVolumeLiters != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isWithinSmallMediumRange
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isWithinSmallMediumRange
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isWithinSmallMediumRange
                                        ? Icons.check_circle_outline
                                        : Icons.warning_amber_rounded,
                                    size: 18,
                                    color: isWithinSmallMediumRange
                                        ? const Color(0xFF185F20)
                                        : Colors.red.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isWithinSmallMediumRange
                                          ? 'Estimated Volume: ${currentVolumeLiters!.toStringAsFixed(1)} Liters (Small–Medium tank)'
                                          : 'Estimated Volume: ${currentVolumeLiters!.toStringAsFixed(1)} Liters (Outside small–medium range)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isWithinSmallMediumRange
                                            ? const Color(0xFF185F20)
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          const Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF185F20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1E8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Automatic Water Change',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF13263C),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Automatically cycles water on threshold breach',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: automaticWaterChange,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF1D2E47),
                                  onChanged: (value) {
                                    setState(() {
                                      automaticWaterChange = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1E8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Notification',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF13263C),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Sends notification for abnormalities',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: notifications,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF1D2E47),
                                  onChanged: (value) {
                                    setState(() {
                                      notifications = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: canFinish && !isLoading
                                  ? _handleFinishSetupClick
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D2E47),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Saving...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Finish Setup',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
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
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFF1D2E47),
                  onPressed: isLoading ? null : _navigateBackToSetup1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}