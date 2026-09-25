import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'splash2.dart';
import 'dashboard.dart';

class Splash1 extends StatefulWidget {
  const Splash1({super.key});

  @override
  State<Splash1> createState() => _Splash1State();
}

class _Splash1State extends State<Splash1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://capstone-6c8f5-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 40,
      ),
    ]).animate(_controller);

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // Wait for splash animation to finish before navigating
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Look up customId mapping for logged in firebase UID
        final DataSnapshot mappingSnapshot =
            await _dbRef.child('user_mappings').child(currentUser.uid).get();

        if (mappingSnapshot.exists && mappingSnapshot.value != null) {
          final Map<dynamic, dynamic> mappingData =
              mappingSnapshot.value as Map<dynamic, dynamic>;
          final String customId = mappingData['customId'] ?? '';
          // Verify the actual user node exists
            final DataSnapshot userSnapshot = await _dbRef
                .child('users')
                .child(customId)
                .get();

            if (!userSnapshot.exists) {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const Splash2(),
                ),
              );
              return;
            }
          // Fetch user's dynamic settings from Realtime Database
          final DataSnapshot settingsSnapshot = await _dbRef
              .child('users')
              .child('customId')
              .child('settings')
              .get();

          String aquariumName = 'My Aquarium';
          if (settingsSnapshot.exists && settingsSnapshot.value != null) {
            final Map<dynamic, dynamic> settingsData =
                settingsSnapshot.value as Map<dynamic, dynamic>;
            aquariumName = settingsData['aquariumName'] ?? 'My Aquarium';
          }

          if (!mounted) return;

          // Direct logged-in user straight to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Dashboard(aquariumName: aquariumName),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error fetching user context: $e');
      }
    }

    // First run or unauthenticated user goes to Splash2
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Splash2(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0DB),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/logos/sensoriya.png',
            width: 280,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}