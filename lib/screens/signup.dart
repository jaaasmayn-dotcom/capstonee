import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';
import 'transitions.dart';
import 'emailverification.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final confirmPasswordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  bool showPasswordRequirements = false;
  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? confirmPasswordError;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();
    confirmPasswordFocusNode.addListener(() {
      if (confirmPasswordFocusNode.hasFocus) {
        setState(() {
          showPasswordRequirements = false;
        });
      }
    });
  }

  @override
  void dispose() {
    confirmPasswordFocusNode.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isPasswordValid(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[^A-Za-z0-9]'));
    final hasLength = password.length >= 8;

    return hasUppercase && hasNumber && hasSpecial && hasLength;
  }

  void validateFirstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      firstNameError = 'First name is required';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      firstNameError = 'Must contain only letters and spaces';
    } else if (!RegExp(r'^[A-Z]').hasMatch(trimmed)) {
      firstNameError = 'First letter must be capitalized';
    } else if (trimmed.length < 2) {
      firstNameError = 'Must be at least 2 characters';
    } else {
      firstNameError = null;
    }
  }

  void validateLastName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      lastNameError = 'Last name is required';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      lastNameError = 'Must contain only letters and spaces';
    } else if (!RegExp(r'^[A-Z]').hasMatch(trimmed)) {
      lastNameError = 'First letter must be capitalized';
    } else if (trimmed.length < 2) {
      lastNameError = 'Must be at least 2 characters';
    } else {
      lastNameError = null;
    }
  }

  void validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(trimmed)) {
      emailError = 'Must be a valid @gmail.com address';
    } else {
      emailError = null;
    }
  }

  void validateConfirmPassword() {
    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError = null;
    } else if (passwordController.text != confirmPasswordController.text) {
      confirmPasswordError = 'Passwords do not match';
    } else {
      confirmPasswordError = null;
    }
  }

  bool get canCreateAccount {
    return firstNameError == null &&
        lastNameError == null &&
        emailError == null &&
        confirmPasswordError == null &&
        firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        isPasswordValid(passwordController.text) &&
        passwordController.text == confirmPasswordController.text;
  }

  Future<void> _showAccountExistsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Account Exists',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2E47),
            ),
          ),
          content: const Text(
            'This email address already exists. Please proceed to the Log In screen instead.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185F20),
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Log In'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacement(
                  context,
                  FadeSlidePageRoute(
                    page: const Login(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignUp() async {
    setState(() {
      isLoading = true;
    });

    final String inputEmail = emailController.text.trim();
    final String firstName = firstNameController.text.trim();
    final String lastName = lastNameController.text.trim();

    try {
      final DatabaseEvent event = await _dbRef
          .child('users')
          .orderByChild('email')
          .equalTo(inputEmail)
          .once();

      if (event.snapshot.exists) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        await _showAccountExistsDialog();
        return;
      }

      // 1. Register with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: inputEmail,
        password: passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 2. Dispatch verification link
        await user.sendEmailVerification();

        if (!mounted) return;

        // 3. Forward info to verification screen without writing to database
        Navigator.pushReplacement(
          context,
          FadeSlidePageRoute(
            page: EmailVerificationScreen(
              email: inputEmail,
              userData: {
                'firstName': firstName,
                'lastName': lastName,
                'customId': lastName,
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
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
    final bool passwordValid = isPasswordValid(passwordController.text);

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
                height: 120,
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
                      'Get Started!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'FIRST NAME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: firstNameController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          validateFirstName(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter first name',
                        errorText: firstNameError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'LAST NAME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lastNameController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          validateLastName(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter last name',
                        errorText: lastNameError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                        hintText: 'Enter email address',
                        errorText: emailError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                          if (!confirmPasswordFocusNode.hasFocus) {
                            showPasswordRequirements = true;
                          }
                          validateConfirmPassword();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Create password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                    if (showPasswordRequirements)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8D8C8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• Password Requirements',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF185F20),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• At least 8 characters',
                              style: TextStyle(
                                color: passwordController.text.length >= 8
                                    ? Colors.green
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '• One uppercase letter',
                              style: TextStyle(
                                color: passwordController.text.contains(
                                  RegExp(r'[A-Z]'),
                                )
                                    ? Colors.green
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '• At least one number',
                              style: TextStyle(
                                color: passwordController.text.contains(
                                  RegExp(r'[0-9]'),
                                )
                                    ? Colors.green
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '• At least one special character',
                              style: TextStyle(
                                color: passwordController.text.contains(
                                  RegExp(r'[^A-Za-z0-9]'),
                                )
                                    ? Colors.green
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'CONFIRM PASSWORD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185F20),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      focusNode: confirmPasswordFocusNode,
                      obscureText: obscureConfirmPassword,
                      enabled: passwordValid,
                      onChanged: (value) {
                        setState(() {
                          validateConfirmPassword();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: passwordValid
                            ? 'Confirm password'
                            : 'Create a password first',
                        errorText: confirmPasswordError,
                        filled: !passwordValid,
                        fillColor:
                            passwordValid ? null : Colors.grey.shade200,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: passwordValid
                              ? () {
                                  setState(() {
                                    obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                  });
                                }
                              : null,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            canCreateAccount && !isLoading ? _handleSignUp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D2E47),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                                    'Creating Account...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Create Account',
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
                        const Text(
                          'Already have an account? ',
                        ),
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
                            'Login',
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