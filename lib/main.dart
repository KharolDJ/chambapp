import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/main_nav_screen.dart';
import 'screens/role_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final provider = AppProvider();
  await provider.cargarEstadoGuardado();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const ChambappApp(),
    ),
  );
}

// Paleta corporativa global — verde de marca fijo (no derivado del tono de
// semilla de Material 3, que puede desviar levemente el hex), fondo blanco
// hueso, superficies blancas y textos con el contraste "limpio" pedido.
const _verdeCorporativo = Color(0xFF0F6E56);
const _fondo = Color(0xFFF9F9FB);
const _tituloOscuro = Color(0xFF1A1A1A);
const _subtituloGris = Color(0xFF666666);
const _bordeSutil = Color(0xFFE5E7EB);

class ChambappApp extends StatelessWidget {
  const ChambappApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    // Plus Jakarta Sans para cuerpo/botones/tarjetas, Outfit (geométrica) para
    // títulos destacados — reemplaza el par Work Sans/Sora anterior por una
    // pareja más sobria y corporativa.
    final cuerpoTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
    final textTheme = cuerpoTheme
        .copyWith(
          headlineLarge: GoogleFonts.outfit(textStyle: cuerpoTheme.headlineLarge),
          headlineMedium: GoogleFonts.outfit(textStyle: cuerpoTheme.headlineMedium),
          headlineSmall: GoogleFonts.outfit(textStyle: cuerpoTheme.headlineSmall),
          titleLarge: GoogleFonts.outfit(textStyle: cuerpoTheme.titleLarge),
          titleMedium: GoogleFonts.outfit(textStyle: cuerpoTheme.titleMedium),
        )
        .apply(bodyColor: _tituloOscuro, displayColor: _tituloOscuro)
        .copyWith(
          bodyMedium: cuerpoTheme.bodyMedium?.copyWith(color: _subtituloGris),
          bodySmall: cuerpoTheme.bodySmall?.copyWith(color: _subtituloGris),
          labelMedium: cuerpoTheme.labelMedium?.copyWith(color: _subtituloGris),
          labelSmall: cuerpoTheme.labelSmall?.copyWith(color: _subtituloGris),
        );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _verdeCorporativo,
      brightness: Brightness.light,
    ).copyWith(
      primary: _verdeCorporativo,
      onPrimary: Colors.white,
      secondary: _verdeCorporativo,
      surface: Colors.white,
      onSurface: _tituloOscuro,
    );

    return MaterialApp(
      title: 'Chambapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _fondo,
        textTheme: textTheme,
        cardColor: Colors.white,
        dividerColor: _bordeSutil,
        appBarTheme: const AppBarTheme(
          backgroundColor: _fondo,
          foregroundColor: _tituloOscuro,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _verdeCorporativo,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: Consumer<AppProvider>(
        builder: (context, provider, _) =>
            provider.rolActual == null ? const RoleSelectorScreen() : const MainNavScreen(),
      ),
    );
  }
}
