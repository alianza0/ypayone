import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_colors.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const YpayoneApp());
}

class YpayoneApp extends StatelessWidget {
  const YpayoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ypayone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
        // En web usa Inter; instalada en iPhone usa la letra de Apple.
        fontFamily: kIsWeb ? GoogleFonts.inter().fontFamily : null,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.accent,
          selectionColor: AppColors.chip,
          selectionHandleColor: AppColors.accent,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
