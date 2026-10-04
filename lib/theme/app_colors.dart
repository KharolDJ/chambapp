import 'package:flutter/material.dart';

/// Paleta de marca centralizada. Antes cada pantalla definía su propia
/// constante privada (`_petroleo`, `_verdeCorporativo`, etc.) repitiendo el
/// mismo valor hexadecimal decenas de veces en todo el proyecto. Ahora todas
/// las pantallas importan estas constantes en vez de duplicar el hex, así
/// que un cambio de color de marca (verde petróleo → azul celeste → negro y
/// dorado, este último junto con el nuevo ícono minimalista en blanco y
/// negro) se hace en un solo lugar.
class AppColors {
  AppColors._();

  /// Acento de marca en tema claro — ya NO es el color de los botones
  /// principales (esos son negro/blanco, ver [negroProfundo] y
  /// `ElevatedButtonThemeData` en main.dart); [dorado] queda para detalles:
  /// bordes de campo enfocados, pestañas/chips activos (los de selección,
  /// no los botones de acción), insignias y elementos destacados. Mismo hex
  /// que el dorado ya usado para Visibilidad Premium/Destacada (`#AD7A16`).
  static const dorado = Color(0xFFAD7A16);

  /// Acento de marca en tema oscuro — más claro que [dorado] para mantener
  /// buen contraste sobre negro profundo (antes `#38BDF8`).
  static const doradoOscuro = Color(0xFFD4AF37);

  /// Negro profundo de marca: fondo de los botones de acción principal en
  /// tema claro (con texto/ícono blanco), texto/ícono sobre superficies
  /// doradas, y base del tema oscuro. En tema oscuro los botones invierten
  /// a blanco con texto/ícono en este negro — un botón negro sobre un
  /// fondo ya casi negro sería invisible.
  static const negroProfundo = Color(0xFF0A0A0A);

  /// Dorado de las estrellas de calificación (ícono y número). Se mantiene
  /// como una segunda tonalidad de dorado, ligeramente más cálida que
  /// [dorado] — antes se justificaba como "distinto del azul de marca";
  /// ahora que el acento principal también es dorado, la diferencia es
  /// sutil a propósito (misma familia, no un color en competencia).
  static const doradoCalificacion = Color(0xFFD9A441);

  /// Etiqueta de categoría en las tarjetas del feed ("Plomería",
  /// "Acarreos"...) — antes usaba [dorado]/[doradoOscuro], ahora un celeste
  /// propio pedido explícitamente para esa sola pieza (el resto de la app
  /// se queda en negro/dorado). Mismo hex que el azul de "Nuevo en la
  /// plataforma" en el perfil — reutilizado en vez de inventar un tercer
  /// azul. Contraste ~4.1:1 sobre blanco: se prioriza que siga leyéndose
  /// "celeste" y no un azul marino oscuro, aceptando un contraste algo más
  /// ajustado que el resto de los textos de la app para una etiqueta corta.
  static const celesteCategoria = Color(0xFF0284C7);

  /// Versión clara para tema oscuro — un celeste saturado como
  /// [celesteCategoria] casi no se ve sobre una tarjeta oscura, así que
  /// aquí sí se aclara de verdad ("celeste muy claro" real, no un
  /// compromiso de contraste).
  static const celesteCategoriaOscuro = Color(0xFF7DD3FC);
}
