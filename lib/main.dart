import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/recognize_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/monthly_report_screen.dart';
import 'screens/food_quality_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MidDayMealApp());
}

class MidDayMealApp extends StatelessWidget {
  const MidDayMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mid Day Meal System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash':       (ctx) => const SplashScreen(),
        '/home':         (ctx) => const HomeScreen(),
        '/register':     (ctx) => const RegisterScreen(),
        '/recognize':    (ctx) => const RecognizeScreen(),
        '/logs':         (ctx) => const LogsScreen(),
        '/settings':     (ctx) => const SettingsScreen(),
        '/monthly':      (ctx) => const MonthlyReportScreen(),
        '/food-quality': (ctx) => const FoodQualityScreen(),
      },
    );
  }
}
