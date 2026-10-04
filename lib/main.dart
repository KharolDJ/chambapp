import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/main_nav_screen.dart';
import 'screens/role_selector_screen.dart';
import 'screens/splash_screen.dart';
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

// Paleta corporativa global — negro y dorado de marca fijos (no derivados
// del tono de semilla de Material 3, que puede desviar levemente el hex;
// valores reales en lib/theme/app_colors.dart, un solo lugar para todo el
// proyecto). El claro usa fondo blanco hueso y superficies blancas; el
// oscuro usa negro profundo y superficies casi negras, con dorado (aclarado
// en oscuro para buen contraste) como acento.
const _acentoClaro = AppColors.dorado;
const _acentoOscuro = AppColors.doradoOscuro;

const _fondoClaro = Color(0xFFF9F9FB);
const _tituloSobreClaro = Color(0xFF1A1A1A);
const _subtituloSobreClaro = Color(0xFF666666);
// Gris neutro sin matiz azulado (antes #E5E7EB, con un canal azul levemente
// más alto que rojo/verde — imperceptible aislado, pero contrario a
// "erradicar el azul" en un rediseño que se apoya solo en negro y dorado).
const _bordeSutilClaro = Color(0xFFE5E5E5);

// GoogleFonts.interTextTheme() devuelve estilos con inherit: false (para
// garantizar que la fuente cargue sin heredar nada del DefaultTextStyle
// ambiente) — pero los estilos internos por defecto de Flutter usan
// inherit: true. Cuando algo anima entre uno de nuestros estilos y uno de
// los internos (ej. el texto de ayuda/error de un TextField cambiando),
// TextStyle.lerp truena con "Failed to interpolate TextStyles with
// different inherit values". Forzar inherit: true en todo el TextTheme
// evita ese choque en cualquier parte de la app.
TextTheme _forzarInherit(TextTheme tema) {
  TextStyle? f(TextStyle? estilo) => estilo?.copyWith(inherit: true);
  return tema.copyWith(
    displayLarge: f(tema.displayLarge),
    displayMedium: f(tema.displayMedium),
    displaySmall: f(tema.displaySmall),
    headlineLarge: f(tema.headlineLarge),
    headlineMedium: f(tema.headlineMedium),
    headlineSmall: f(tema.headlineSmall),
    titleLarge: f(tema.titleLarge),
    titleMedium: f(tema.titleMedium),
    titleSmall: f(tema.titleSmall),
    bodyLarge: f(tema.bodyLarge),
    bodyMedium: f(tema.bodyMedium),
    bodySmall: f(tema.bodySmall),
    labelLarge: f(tema.labelLarge),
    labelMedium: f(tema.labelMedium),
    labelSmall: f(tema.labelSmall),
  );
}

// Negro profundo de verdad (antes un grafito con matiz azulado, #121417) —
// la superficie de tarjetas se separa del fondo con un negro apenas más
// claro (#141414) para que las tarjetas sigan siendo distinguibles.
const _fondoOscuro = AppColors.negroProfundo;
const _superficieOscura = Color(0xFF141414);
const _tituloSobreOscuro = Color(0xFFF2F2F2);
const _subtituloSobreOscuro = Color(0xFFA3A3A3);
const _bordeSutilOscuro = Color(0xFF2A2A2A);

class ChambappApp extends StatefulWidget {
  const ChambappApp({super.key});

  @override
  State<ChambappApp> createState() => _ChambappAppState();
}

class _ChambappAppState extends State<ChambappApp> {
  // El splash se muestra una sola vez, en el arranque en frío — una vez
  // termina, `home:` vuelve a depender solo de rolActual, exactamente igual
  // que antes de que existiera el splash (logout incluido).
  bool _mostrarSplash = true;

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
    final textTheme = _forzarInherit(
      cuerpoTheme
          .apply(bodyColor: titulo, displayColor: titulo)
          .copyWith(
            bodyMedium: cuerpoTheme.bodyMedium?.copyWith(color: subtitulo),
            bodySmall: cuerpoTheme.bodySmall?.copyWith(color: subtitulo),
            labelMedium: cuerpoTheme.labelMedium?.copyWith(color: subtitulo),
            labelSmall: cuerpoTheme.labelSmall?.copyWith(color: subtitulo),
          ),
    );

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _acentoClaro,
          brightness: brightness,
        ).copyWith(
          // primary/secondary siguen en dorado — controlan el acento de
          // detalle (chips de selección, campos enfocados, etc.), separado
          // a propósito del color de los botones de acción principal, que
          // ahora es negro/blanco (ver elevatedButtonTheme más abajo).
          primary: acento,
          onPrimary: AppColors.negroProfundo,
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
          // Botones de acción principal en negro/blanco (no en el acento
          // dorado, que queda para detalles). En oscuro se invierte —
          // negro sobre negro sería invisible.
          backgroundColor: esOscuro ? Colors.white : AppColors.negroProfundo,
          foregroundColor: esOscuro ? AppColors.negroProfundo : Colors.white,
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
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _mostrarSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onFinished: () => setState(() => _mostrarSplash = false),
              )
            : Consumer<AppProvider>(
                key: const ValueKey('principal'),
                builder: (context, provider, _) => provider.rolActual == null
                    ? const RoleSelectorScreen()
                    : const MainNavScreen(),
              ),
      ),
    );
  }
}
