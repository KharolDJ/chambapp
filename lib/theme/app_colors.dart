import 'package:flutter/material.dart';

/// Paleta de marca centralizada. Antes cada pantalla definía su propia
/// constante privada (`_petroleo`, `_verdeCorporativo`, etc.) repitiendo el
/// mismo valor hexadecimal decenas de veces en todo el proyecto. Ahora todas
/// las pantallas importan estas constantes en vez de duplicar el hex, así
/// que un cambio de color de marca (como este, de verde petróleo a azul
/// celeste) se hace en un solo lugar.
class AppColors {
  AppColors._();

  /// Acento principal de marca en tema claro — antes petróleo `#0F6E56`.
  /// Usado en botones de acción, bordes de campo enfocados, pestañas/chips
  /// activos, enlaces y elementos destacados (ej. "Aplicaste").
  static const azulCeleste = Color(0xFF0284C7);

  /// Acento principal de marca en tema oscuro — más claro que [azulCeleste]
  /// para mantener buen contraste sobre los fondos oscuros de la app (antes
  /// `#2BB893`).
  static const azulCelesteOscuro = Color(0xFF38BDF8);

  /// Dorado de las estrellas de calificación (ícono y número), en claro y
  /// oscuro — antes `#AD7A16` (mostaza oscura, se veía "dorado sucio"),
  /// reemplazado por un ámbar más vivo. No se usa para el sistema de
  /// Visibilidad Premium/Destacada (ese dorado sigue siendo `#AD7A16`,
  /// definido localmente en cada pantalla — son sistemas visuales
  /// distintos aunque compartan familia de color).
  static const doradoCalificacion = Color(0xFFFFC107);
}
