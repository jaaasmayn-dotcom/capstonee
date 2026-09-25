import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signup.dart';
import 'dashboard.dart';
import 'transitions.dart';
import 'forgot_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  String? emailError;
  String? passwordError;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

  void validatePassword(String value) {
    if (value.trim().isEmpty) {
      passwordError = 'Password is required';
    } else if (value.length < 8) {
      passwordError = 'Password must be at least 8 characters';
    } else {
      passwordError = null;
    }
  }

  bool get canLogin {
    return emailError == null &&
        passwordError == null &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  void _showAccountNotFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Not Found'),
          content: const Text(
            'No account associated with this email exists. Would you like to create an account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185F20),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  FadeSlidePageRoute(
                    page: const Signup(),
                  ),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showIncorrectPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Incorrect Password'),
          content: const Text(
            'The password you entered is incorrect. Please check your password and try again.',
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
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
    });

    final String inputEmail = emailController.text.trim();
    final String inputPassword = passwordController.text;

    try {
      // 1. Authenticate user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: inputEmail,
        password: inputPassword,
      );

      final String firebaseUid = userCredential.user!.uid;

      // 2. Fetch user's customId from user_mappings node
      final DataSnapshot mappingSnapshot =
          await _dbRef.child('user_mappings').child(firebaseUid).get();

      String aquariumName = 'My Aquarium';

      if (mappingSnapshot.exists && mappingSnapshot.value != null) {
        final Map<dynamic, dynamic> mappingData =
            mappingSnapshot.value as Map<dynamic, dynamic>;
        final String customId = mappingData['customId'] ?? '';

        if (customId.isNotEmpty) {
          final DataSnapshot settingsSnapshot = await _dbRef
              .child('users')
              .child(customId)
              .child('settings')
              .get();

          if (settingsSnapshot.exists && settingsSnapshot.value != null) {
            final Map<dynamic, dynamic> settingsData =
                settingsSnapshot.value as Map<dynamic, dynamic>;
            aquariumName = settingsData['aquariumName'] ?? 'My Aquarium';
          }
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        FadeSlidePageRoute(
          page: Dashboard(
            aquariumName: aquariumName,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        _showAccountNotFoundDialog();
      } else if (e.code == 'wrong-password') {
        _showIncorrectPasswordDialog();
      } else if (e.code == 'invalid-credential') {
        // Query database directly to decide between Wrong Password and Account Not Found
        try {
          final DataSnapshot snapshot = await _dbRef.child('users').get();
          bool accountExists = false;

          if (snapshot.exists && snapshot.value != null) {
            final Map<dynamic, dynamic> users =
                snapshot.value as Map<dynamic, dynamic>;
            accountExists = users.values.any((user) =>
                user is Map &&
                user['email']?.toString().toLowerCase() ==
                    inputEmail.toLowerCase());
          }

          if (accountExists) {
            _showIncorrectPasswordDialog();
          } else {
            _showAccountNotFoundDialog();
          }
        } catch (_) {
          _showIncorrectPasswordDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Invalid credentials. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
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
                    const SizedBox(height: 20),
                    const Text(
                      'PASSWORD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onChanged: (value) {
                        setState(() {
                          validatePassword(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        errorText: passwordError,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(
                              page: const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF185F20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canLogin && !isLoading ? _handleLogin : null,
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
                                    'Signing In...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              FadeSlidePageRoute(
                                page: const Signup(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
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