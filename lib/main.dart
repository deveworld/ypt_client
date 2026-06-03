import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'ca_setup.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// YPT 브랜드 컬러
const kBrand = Color(0xFFE8552D); // 주황빨강
const kBg = Color(0xFF0D0D0F);
const kCard = Color(0xFF18181B);
const kCard2 = Color(0xFF222227);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupCaCerts(); // Windows TLS 루트 보완 (웹/기타 플랫폼은 no-op)
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..tryAutoLogin(),
      child: const YptApp(),
    ),
  );
}

class YptApp extends StatelessWidget {
  const YptApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrand,
      brightness: Brightness.dark,
    ).copyWith(surface: kBg);

    return MaterialApp(
      title: 'YPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: kCard,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kCard,
          indicatorColor: kBrand.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCard2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBrand, width: 1.5),
          ),
        ),
      ),
      home: Consumer<AppState>(
        builder: (_, st, __) =>
            st.loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
