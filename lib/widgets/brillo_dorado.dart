import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Traduce (desliza) el gradiente horizontalmente en vez de rotarlo — a
/// diferencia de GradientRotation, esto no deja ningún punto de pivote
/// visible: el degradado completo se mueve de lado a lado como una franja
/// de luz, no como una hélice girando sobre un centro.
class DesplazamientoDeslizante extends GradientTransform {
  final double porcentaje;
  const DesplazamientoDeslizante({required this.porcentaje});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * porcentaje, 0, 0);
  }
}

/// Fondo dorado deslizante para tarjetas Premium (peticiones y oficios) —
/// usa [DesplazamientoDeslizante] con [t] (0.0-1.0, provisto por
/// [BrilloDoradoAnimado]) para que la franja de brillo recorra el fondo.
/// [esOscuro] cambia la base de crema/pergamino pálido (tema claro) a un
/// bronce casi negro (tema oscuro) — en modo oscuro, un fondo crema clarito
/// se vería como un parche blanco fuera de lugar sobre el resto de la app en
/// negro, así que la base tiene que ser oscura también, solo con el mismo
/// reflejo dorado recorriéndola.
LinearGradient fondoDoradoDeslizante(double? t, {bool esOscuro = false}) {
  return LinearGradient(
    begin: const Alignment(-1, -0.3),
    end: const Alignment(1, 0.3),
    colors: esOscuro
        ? const [
            Color(0xFF1B1509),
            Color(0xFF1B1509),
            Color(0xFF4A3712),
            Color(0xFF1B1509),
            Color(0xFF1B1509),
          ]
        : const [
            Color(0xFFFFFDF6),
            Color(0xFFFFFDF6),
            Color(0xFFFFF0C4),
            Color(0xFFFFFDF6),
            Color(0xFFFFFDF6),
          ],
    stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    transform: DesplazamientoDeslizante(porcentaje: -1.5 + 3.0 * (t ?? 0)),
  );
}

/// Sombra dorada acompañante de [fondoDoradoDeslizante]. En oscuro se reduce
/// la opacidad — una sombra pensada para resaltar sobre fondo blanco satura
/// demasiado sobre un fondo ya oscuro.
List<BoxShadow> sombraDorada({bool esOscuro = false}) => [
  BoxShadow(
    color: const Color(0xFFAD7A16).withValues(alpha: esOscuro ? 0.35 : 0.22),
    blurRadius: 18,
    offset: const Offset(0, 4),
  ),
];

/// Anillo de degradado dorado que rota lentamente alrededor de [child] — el
/// "brillo metálico en movimiento" de las tarjetas Premium aprobadas (tanto
/// peticiones como oficios de trabajadores). Se implementa envolviendo el
/// contenido en un Container cuyo fondo es un SweepGradient (los "bordes" de
/// BoxDecoration solo admiten color plano, no degradados), dejando un margen
/// de 1.8px visible como anillo alrededor de la tarjeta interior. Como el
/// centro de la rotación queda tapado por la tarjeta blanca/interior, no se
/// ve ningún "punto de pivote" — solo la luz recorriendo el anillo. (El
/// fondo interior, en cambio, usa [fondoDoradoDeslizante], porque ahí el
/// centro del giro sí quedaría expuesto sobre el contenido.)
class BrilloDoradoAnimado extends StatefulWidget {
  final Widget Function(BuildContext context, double t) builder;
  final BorderRadius borderRadius;
  const BrilloDoradoAnimado({
    super.key,
    required this.builder,
    required this.borderRadius,
  });

  @override
  State<BrilloDoradoAnimado> createState() => _BrilloDoradoAnimadoState();
}

class _BrilloDoradoAnimadoState extends State<BrilloDoradoAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _colores = [
    Color(0xFFFFF6D8),
    Color(0xFFE0A93B),
    Color(0xFFFFF6D8),
    Color(0xFFAD7A16),
    Color(0xFFFFF6D8),
  ];
  static const _paradas = [0.0, 0.25, 0.5, 0.75, 1.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          padding: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: SweepGradient(
              transform: GradientRotation(t * 2 * math.pi),
              colors: _colores,
              stops: _paradas,
            ),
          ),
          child: widget.builder(context, t),
        );
      },
    );
  }
}
