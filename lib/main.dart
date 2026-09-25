import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/splash1.dart';
import 'screens/notification_service.dart';

    ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.initialize();

  FirebaseDatabase.instance.setPersistenceEnabled(true);

  runApp(const CapstoneApp());
}

class CapstoneApp extends StatelessWidget {
  const CapstoneApp({super.key});

 @override
Widget build(BuildContext context) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: themeNotifier,
    builder: (context, mode, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,

        themeMode: mode,

        theme: ThemeData(
          brightness: Brightness.light,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF185F20),
                width: 2,
              ),
            ),
          ),
        ),

        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor:
              const Color(0xFF121212),

          appBarTheme: const AppBarTheme(
            backgroundColor:
                Color(0xFF1A1A1A),
          ),

          cardColor: const Color(0xFF1E1E1E),
        ),

        home: const Splash1(),
      );
    },
  );
}
}