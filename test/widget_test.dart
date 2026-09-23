import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kimpul/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    // Render LoginScreen di lingkungan pengujian widget
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Memastikan judul KIMPUL dan teks Selamat Datang tampil
    expect(find.text('KIMPUL'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);

    // Memastikan tombol Masuk dan opsi Daftar ada
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });
}