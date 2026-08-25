import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/main_nav_screen.dart';
import 'screens/role_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.cargarEstadoGuardado();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const ChambappApp(),
    ),
  );
}

class ChambappApp extends StatelessWidget {
  const ChambappApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    final workSansTheme = GoogleFonts.workSansTextTheme(baseTextTheme);
    final textTheme = workSansTheme.copyWith(
      headlineLarge: GoogleFonts.sora(textStyle: workSansTheme.headlineLarge),
      headlineMedium: GoogleFonts.sora(textStyle: workSansTheme.headlineMedium),
      headlineSmall: GoogleFonts.sora(textStyle: workSansTheme.headlineSmall),
      titleLarge: GoogleFonts.sora(textStyle: workSansTheme.titleLarge),
      titleMedium: GoogleFonts.sora(textStyle: workSansTheme.titleMedium),
    );

    return MaterialApp(
      title: 'Chambapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F6E56),
        useMaterial3: true,
        textTheme: textTheme,
      ),
      home: Consumer<AppProvider>(
        builder: (context, provider, _) =>
            provider.rolActual == null ? const RoleSelectorScreen() : const MainNavScreen(),
      ),
    );
  }
}
