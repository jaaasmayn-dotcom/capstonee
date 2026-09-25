import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'setup2.dart';

class Setup1 extends StatefulWidget {
  const Setup1({super.key});

  @override
  State<Setup1> createState() => _Setup1State();
}

class _Setup1State extends State<Setup1> {
  final minPhController = TextEditingController(text: '6.5');
  final maxPhController = TextEditingController(text: '7.5');
  final minTempController = TextEditingController(text: '23.0');
  final maxTempController = TextEditingController(text: '26.0');

  RangeValues phRange = const RangeValues(6.5, 7.5);
  RangeValues tempRange = const RangeValues(23.0, 26.0);

  bool get isPhWarning {
    final start = double.parse(phRange.start.toStringAsFixed(1));
    final end = double.parse(phRange.end.toStringAsFixed(1));
    return start < 6.5 || end > 7.5;
  }

  bool get isTempWarning {
    final start = double.parse(tempRange.start.toStringAsFixed(1));
    final end = double.parse(tempRange.end.toStringAsFixed(1));
    return start < 23.0 || end > 26.0;
  }

  bool get isValid {
    final minPh = double.tryParse(minPhController.text);
    final maxPh = double.tryParse(maxPhController.text);
    final minTemp = double.tryParse(minTempController.text);
    final maxTemp = double.tryParse(maxTempController.text);

    if (minPh == null || maxPh == null || minTemp == null || maxTemp == null) {
      return false;
    }

    return minPh < maxPh && minTemp < maxTemp;
  }

  void _proceedToNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Setup2(
          minPh: minPhController.text,
          maxPh: maxPhController.text,
          minTemp: minTempController.text,
          maxTemp: maxTempController.text,
        ),
      ),
    );
  }

  void _handleNext() {
    if (isPhWarning || isTempWarning) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
                SizedBox(width: 8),
                Text(
                  'Threshold Warning',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2E47),
                  ),
                ),
              ],
            ),
            content: const Text(
              'One or more of your threshold values are set outside the recommended range. Do you wish to proceed with these settings?',
              style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _proceedToNext();
                },
                child: const Text(
                  'Proceed Anyway',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D2E47),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    } else {
      _proceedToNext();
    }
  }

  void _onPhInputChanged() {
    final minVal = double.tryParse(minPhController.text);
    final maxVal = double.tryParse(maxPhController.text);

    if (minVal != null && maxVal != null && minVal <= maxVal) {
      final clampedMin = minVal.clamp(6.0, 8.5);
      final clampedMax = maxVal.clamp(6.0, 8.5);
      if (clampedMin <= clampedMax) {
        setState(() {
          phRange = RangeValues(clampedMin, clampedMax);
        });
        return;
      }
    }
    setState(() {});
  }

  void _onTempInputChanged() {
    final minVal = double.tryParse(minTempController.text);
    final maxVal = double.tryParse(maxTempController.text);

    if (minVal != null && maxVal != null && minVal <= maxVal) {
      final clampedMin = minVal.clamp(21.0, 29.0);
      final clampedMax = maxVal.clamp(21.0, 29.0);
      if (clampedMin <= clampedMax) {
        setState(() {
          tempRange = RangeValues(clampedMin, clampedMax);
        });
        return;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    minPhController.dispose();
    maxPhController.dispose();
    minTempController.dispose();
    maxTempController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Image.asset('assets/logos/sensoriya.png', height: 120),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 14,
                      elevation: 3,
                    ),
                    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                    rangeTickMarkShape: const RoundRangeSliderTickMarkShape(
                      tickMarkRadius: 0,
                    ),
                    activeTrackColor: const Color(0xFF1D2E47),
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: const Color(0xFF1D2E47),
                    overlayColor: const Color(0xFF1D2E47).withValues(alpha: 0.15),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 26,
                    ),
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
                        'Step 1 of 2',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 8,
                          backgroundColor: Color(0xFFE0E0E0),
                          color: Color(0xFF185F20),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'pH Thresholds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF185F20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minPhController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: false,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d{0,1})?$')),
                                LengthLimitingTextInputFormatter(3),
                              ],
                              onChanged: (_) => _onPhInputChanged(),
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
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: false,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d{0,1})?$')),
                                LengthLimitingTextInputFormatter(3),
                              ],
                              onChanged: (_) => _onPhInputChanged(),
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
                      const SizedBox(height: 8),
                      Transform.scale(
                        scaleX: 1.05,
                        child: RangeSlider(
                          values: phRange,
                          min: 6.0,
                          max: 8.5,
                          onChanged: (values) {
                            setState(() {
                              phRange = values;
                              minPhController.text = values.start.toStringAsFixed(1);
                              maxPhController.text = values.end.toStringAsFixed(1);
                            });
                          },
                        ),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '6.0',
                            style: TextStyle(
                              color: Color(0xFF185F20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '8.5',
                            style: TextStyle(
                              color: Color(0xFF185F20),
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
                      if (isPhWarning) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFD32F2F), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Warning: pH is set outside the recommended range (below 6.5 or above 7.5).',
                                  style: TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const Text(
                        'Temperature Thresholds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF185F20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minTempController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: false,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?$')),
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (_) => _onTempInputChanged(),
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
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: false,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?$')),
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (_) => _onTempInputChanged(),
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
                      const SizedBox(height: 8),
                      Transform.scale(
                        scaleX: 1.05,
                        child: RangeSlider(
                          values: tempRange,
                          min: 21.0,
                          max: 29.0,
                          onChanged: (values) {
                            setState(() {
                              tempRange = values;
                              minTempController.text =
                                  values.start.toStringAsFixed(1);
                              maxTempController.text =
                                  values.end.toStringAsFixed(1);
                            });
                          },
                        ),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '21°C',
                            style: TextStyle(
                              color: Color(0xFF185F20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '29°C',
                            style: TextStyle(
                              color: Color(0xFF185F20),
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
                      if (isTempWarning) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFD32F2F), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Warning: Temperature is set outside the recommended range (below 23°C or above 26°C).',
                                  style: TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isValid ? _handleNext : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D2E47),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Next',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}