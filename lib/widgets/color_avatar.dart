import 'package:flutter/material.dart';

/// Pareja fondo/texto para un avatar de iniciales, ya pensada para buen
/// contraste entre ambos.
class ColorAvatar {
  final Color fondo;
  final Color texto;
  const ColorAvatar(this.fondo, this.texto);
}

const _paletaAvatares = [
  // Menta/verde — ya no es "el color de marca" (que pasó a azul celeste,
  // ver lib/theme/app_colors.dart), pero se deja en la rotación de avatares
  // porque sigue siendo un tono distinguible y no se usa en botones/enlaces.
  ColorAvatar(Color(0xFFE3F2EC), Color(0xFF0F6E56)),
  ColorAvatar(Color(0xFFE0EAFB), Color(0xFF2451A3)), // azul
  ColorAvatar(Color(0xFFECE0FB), Color(0xFF6B3FA0)), // violeta
  ColorAvatar(Color(0xFFFBE0E6), Color(0xFFB23A55)), // rosa/coral
  ColorAvatar(Color(0xFFDFF5F2), Color(0xFF1A7A6E)), // verde azulado
  ColorAvatar(Color(0xFFFCEBDD), Color(0xFFB85C1F)), // naranja suave
  ColorAvatar(Color(0xFFE6E9ED), Color(0xFF45536B)), // gris azulado
  ColorAvatar(Color(0xFFF5E6BE), Color(0xFFAD7A16)), // dorado
];

/// Color determinístico para el avatar de iniciales de un usuario — la misma
/// [semilla] (usar el id del usuario, no el nombre, para que no cambie si dos
/// personas comparten nombre) siempre cae en el mismo color de la paleta, así
/// cada persona se distingue visualmente en el feed sin necesitar foto real.
ColorAvatar colorAvatarPara(String semilla) {
  final indice = semilla.hashCode.abs() % _paletaAvatares.length;
  return _paletaAvatares[indice];
}
