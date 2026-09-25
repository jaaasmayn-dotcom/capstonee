import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';
import 'transitions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? emailError;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void validateEmail(String value) {
    if (value.trim().isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(
      r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$',
    ).hasMatch(value)) {
      emailError = 'Enter a valid email address';
    } else {
      emailError = null;
    }
  }

  bool get canSubmit {
    return emailError == null && emailController.text.trim().isNotEmpty;
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      isLoading = true;
    });

    final String inputEmail = emailController.text.trim();

    try {
      // Optional check against Realtime Database to confirm account existence first
      final DataSnapshot snapshot = await _dbRef.child('users').get();
      bool accountExists = false;

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> users =
            snapshot.value as Map<dynamic, dynamic>;
        accountExists = users.values.any((user) =>
            user is Map &&
            user['email']?.toString().toLowerCase() == inputEmail.toLowerCase());
      }

      if (!accountExists) {
        if (!mounted) return;
        _showAccountNotFoundDialog();
        return;
      }

      // Send Firebase Auth password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: inputEmail);

      if (!mounted) return;

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send reset email.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
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

  void _showAccountNotFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Not Found'),
          content: const Text(
            "We couldn't find an account registered with this email.",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D2E47),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Sent'),
          content: const Text(
            'A password reset link has been sent to your email address. Please check your inbox.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185F20),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  FadeSlidePageRoute(
                    page: const Login(),
                  ),
                );
              },
              child: const Text(
                'Back to Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/logos/sensoriya.png',
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                'SENSORIYA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 39,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2E47),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter the email address associated with your account, and we will send you instructions to reset your password.',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'EMAIL ADDRESS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          validateEmail(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        errorText: emailError,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            canSubmit && !isLoading ? _handleResetPassword : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1D2E47,
                          ),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                        child: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
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
                                    'Sending Link...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Remembered your password? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              FadeSlidePageRoute(
                                page: const Login(),
                              ),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Color(0xFF185F20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}