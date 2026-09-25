import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'setup1.dart';
import 'splash2.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? userData;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.userData,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  bool isLoading = false;
  bool canResendEmail = false;
  bool _isSavingData = false;

  Timer? timer;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();

    canResendEmail = true;

    //timer = Timer.periodic(
      //const Duration(seconds: 5),
      //(_) => checkEmailVerified(),
    //);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _saveUserToDatabase(User user) async {
    if (_isSavingData) return;
    _isSavingData = true;

    final String firebaseUid = user.uid;
    final String customUserId =
        widget.userData?['customId'] ?? widget.userData?['lastName'] ?? firebaseUid;

    final dataToSave = {
  'customId': customUserId,
  'firebaseUid': firebaseUid,
  'email': widget.email,
  'createdAt': DateTime.now().toIso8601String(),

  ...?widget.userData,

  'settings': {
    'aquariumName': '',
    'notifications': true,
    'automaticWaterChange': false,
  },

  'thresholdSettings': {
    'acceptableMinPh': 6.0,
    'acceptableMaxPh': 8.5,

    'safeMinPh': 6.5,
    'safeMaxPh': 7.5,

    'acceptableMinTemp': 21,
    'acceptableMaxTemp': 29,

    'safeMinTemp': 23,
    'safeMaxTemp': 26,
      },
      'liveMonitoring': {
      'ph': 0,
      'temperature': 0,
      'waterLevel': 0,
      'lastUpdated': 0,
      },
      'alerts': {},

      'history': {},

      'commands': {
        'waterChange': {
          'status': 'idle',
          'requestedAt': '',
        }
      }
  
};

    await _dbRef.child('users').child(customUserId).set(dataToSave);
    await _dbRef.child('user_mappings').child(firebaseUid).set({
      'customId': customUserId,
    });
  }

  Future<void> _handleVerificationSuccess(User user) async {
    timer?.cancel();

    setState(() {
      isLoading = true;
    });

    try {
      await _saveUserToDatabase(user);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Setup1(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete account setup: $e'),
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

  Future<void> checkEmailVerified() async {
    if (_isSavingData) return;

    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      await _handleVerificationSuccess(user);
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      setState(() {
        canResendEmail = false;
      });

      await Future.delayed(const Duration(seconds: 30));

      if (!mounted) return;
      setState(() {
        canResendEmail = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> manuallyCheckVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authenticated user found.'),
          ),
        );
        return;
      }
      
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      
      if (user != null && user.emailVerified) {
        await _handleVerificationSuccess(user);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email has not been verified yet.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),),
      );
    } 
    
    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> cancelRegistration() async {
    try {
      timer?.cancel();

      final user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Splash2()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to cancel registration: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF5F1E8),
        centerTitle: true,
        title: const Text(
          'Email Verification',
          style: TextStyle(
            color: Color(0xFF1D2E47),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(
                    Icons.mark_email_read,
                    size: 110,
                    color: Color(0xFF1D2E47),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2E47),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A verification email has been sent to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1D2E47),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Open your email inbox and click the verification link from Sensoriya.\n\nAfter verifying your account, return to the app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : manuallyCheckVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D2E47),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "I've Verified My Email",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: canResendEmail ? sendVerificationEmail : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF1D2E47),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        canResendEmail
                            ? 'Resend Verification Email'
                            : 'Resend Available in 30 Seconds',
                        style: const TextStyle(
                          color: Color(0xFF1D2E47),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: cancelRegistration,
                    child: const Text('Cancel Registration'),
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