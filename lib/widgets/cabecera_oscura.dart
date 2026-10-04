import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cabecera negra fija con esquinas inferiores redondeadas: la misma
/// identidad visual del bloque superior de "Cerca de ti" en el feed (mismo
/// `AppColors.negroProfundo`, mismo radio de 24, mismo tamaño de título),
/// reutilizada tal cual en Notificaciones, Actividad y Perfil para que las
/// 4 pantallas principales compartan exactamente el mismo tono y acabado.
///
/// En el feed el redondeo vive en el contenedor de búsqueda/filtros (un
/// bloque aparte debajo del AppBar), no en el AppBar mismo — acá, al no
/// haber ese segundo bloque, el redondeo se aplica directo al `shape` del
/// AppBar para lograr el mismo remate visual.
AppBar cabeceraOscura(String titulo, {List<Widget>? actions}) {
  return AppBar(
    title: Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    backgroundColor: AppColors.negroProfundo,
    foregroundColor: Colors.white,
    elevation: 0,
    // Separación del título respecto al borde izquierdo — el valor por
    // defecto de Flutter (16) se sentía pegado contra el margen general
    // del contenido debajo (20/24 en la mayoría de las pantallas).
    titleSpacing: 20,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    actions: actions,
  );
}
