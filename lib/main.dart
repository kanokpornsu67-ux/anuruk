import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'widgets/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ถ้ารันบน Windows / Linux / macOS ให้เปิดบรรทัดนี้ (และเพิ่ม sqflite_common_ffi ใน pubspec)
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;

  final appState = AppState();
  await appState.init(); // โหลดข้อมูลจากดาต้าเบสก่อนแสดงหน้าแรก

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const GreenClubApp(),
    ),
  );
}

class GreenClubApp extends StatelessWidget {
  const GreenClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anuruk App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
        scaffoldBackgroundColor: kBg,
        textTheme: GoogleFonts.sarabunTextTheme(), // ใส่ฟอนต์ไทยใน assets ได้ หรือลบบรรทัดนี้
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kDarkGreen,
          elevation: 0.5,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}