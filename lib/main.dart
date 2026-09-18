import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/main_nav_screen.dart';
import 'screens/role_selector_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final provider = AppProvider();
  await provider.cargarEstadoGuardado();
  runApp(
    ChangeNotifierProvider.value(value: provider, child: const ChambappApp()),
  );
}

// Paleta corporativa global — azul celeste de marca fijo (no derivado del
// tono de semilla de Material 3, que puede desviar levemente el hex; valores
// reales en lib/theme/app_colors.dart, un solo lugar para todo el proyecto).
// El claro usa fondo blanco hueso y superficies blancas; el oscuro usa
// grafito profundo y superficies gris carbón, con el mismo azul de marca
// (aclarado para buen contraste) como acento.
const _acentoClaro = AppColors.azulCeleste;
const _acentoOscuro = AppColors.azulCelesteOscuro;

const _fondoClaro = Color(0xFFF9F9FB);
const _tituloSobreClaro = Color(0xFF1A1A1A);
const _subtituloSobreClaro = Color(0xFF666666);
const _bordeSutilClaro = Color(0xFFE5E7EB);

const _fondoOscuro = Color(0xFF121417);
const _superficieOscura = Color(0xFF1B1F22);
const _tituloSobreOscuro = Color(0xFFF2F3F5);
const _subtituloSobreOscuro = Color(0xFF9AA3AB);
const _bordeSutilOscuro = Color(0xFF2A2E33);

class ChambappApp extends StatelessWidget {
  const ChambappApp({super.key});

  ThemeData _construirTema(BuildContext context, Brightness brightness) {
    final esOscuro = brightness == Brightness.dark;
    final fondo = esOscuro ? _fondoOscuro : _fondoClaro;
    final superficie = esOscuro ? _superficieOscura : Colors.white;
    final titulo = esOscuro ? _tituloSobreOscuro : _tituloSobreClaro;
    final subtitulo = esOscuro ? _subtituloSobreOscuro : _subtituloSobreClaro;
    final borde = esOscuro ? _bordeSutilOscuro : _bordeSutilClaro;
    final acento = esOscuro ? _acentoOscuro : _acentoClaro;

    final baseTextTheme = Theme.of(context).textTheme;
    // Una sola familia (Inter) para toda la app — reemplaza el par
    // Manrope/Inter anterior; ya no hace falta distinguir títulos de cuerpo.
    final cuerpoTheme = GoogleFonts.interTextTheme(baseTextTheme);
    final textTheme = cuerpoTheme
        .apply(bodyColor: titulo, displayColor: titulo)
        .copyWith(
          bodyMedium: cuerpoTheme.bodyMedium?.copyWith(color: subtitulo),
          bodySmall: cuerpoTheme.bodySmall?.copyWith(color: subtitulo),
          labelMedium: cuerpoTheme.labelMedium?.copyWith(color: subtitulo),
          labelSmall: cuerpoTheme.labelSmall?.copyWith(color: subtitulo),
        );

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _acentoClaro,
          brightness: brightness,
        ).copyWith(
          primary: acento,
          onPrimary: esOscuro ? _fondoOscuro : Colors.white,
          secondary: acento,
          surface: superficie,
          onSurface: titulo,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: fondo,
      textTheme: textTheme,
      cardColor: superficie,
      dividerColor: borde,
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: titulo,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: acento,
          foregroundColor: esOscuro ? _fondoOscuro : Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temaPreferido = context.watch<AppProvider>().temaPreferido;
    return MaterialApp(
      title: 'Chambapp',
      debugShowCheckedModeBanner: false,
      theme: _construirTema(context, Brightness.light),
      darkTheme: _construirTema(context, Brightness.dark),
      themeMode: temaPreferido,
      home: Consumer<AppProvider>(
        builder: (context, provider, _) => provider.rolActual == null
            ? const RoleSelectorScreen()
            : const MainNavScreen(),
      ),
    );
  }
}
