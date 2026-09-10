import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:kimpul/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFE93A56);   // Merah Kimpul
    const Color secondaryColor = Color(0xFF515F74); // Abu-abu Slate
    const Color darkColor = Color(0xFF0F172A);      // Hitam/Dark Slate
    const Color backgroundColor = Colors.white;      // Background Layar Putih

    return MaterialApp(
      title: 'Kimpul',
      debugShowCheckedModeBanner: false,

      // 🌟 KONFIGURASI TEMA GLOBAL
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,

        // 1. ColorScheme Utama
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: darkColor,
          surface: backgroundColor,
        ),

        // 2. Tema AppBar / Header
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: darkColor,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),

        // 3. Tema Bottom Navigation Bar (Menu Bawah - Fixed Error LabelStyle)
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: backgroundColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: secondaryColor,
          selectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // 4. Tema Tombol (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 5. Tema FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),

      // SplashScreen sebagai halaman pertama
      home: const SplashScreen(),
    );
  }
}