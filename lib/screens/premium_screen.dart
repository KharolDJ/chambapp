import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../providers/app_provider.dart';
import 'pago_paypal_screen.dart';

class PremiumScreen extends StatefulWidget {
  final Peticion peticion;
  const PremiumScreen({super.key, required this.peticion});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _pagando = false;

  Future<void> _pagar(String peticionId) async {
    setState(() => _pagando = true);
    final resultado = await Navigator.push<ResultadoPagoPaypal>(
      context,
      MaterialPageRoute(
        builder: (_) => const PagoPaypalScreen(
          montoUsd: '2.50',
          descripcion: 'Visibilidad Premium Chambapp (sandbox)',
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _pagando = false);
    if (resultado == null) return; // cancelado
    if (resultado.estado != 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El pago no se completó (estado: ${resultado.estado})'),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    await context.read<AppProvider>().activarPremiumPeticion(
      peticionId,
      resultado.ordenId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final actualizada = provider.peticiones.firstWhere(
      (p) => p.id == widget.peticion.id,
      orElse: () => widget.peticion,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Visibilidad Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Encabezado(descripcion: actualizada.descripcion),
          const SizedBox(height: 20),
          const _FilaBeneficios(
            beneficios: [
              _Beneficio(
                icono: Icons.trending_up,
                texto: 'Hasta 5x más\npostulaciones',
              ),
              _Beneficio(
                icono: Icons.vertical_align_top,
                texto: 'Primero en el\nfeed de tu zona',
              ),
              _Beneficio(
                icono: Icons.workspace_premium,
                texto: 'Insignia dorada\n"Destacado"',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _VistaPrevia(),
          const SizedBox(height: 28),
          if (actualizada.premiumAprobada)
            const _EstadoSimple(
              icono: Icons.check_circle,
              color: Color(0xFFAD7A16),
              texto: '¡Tu publicación ya tiene Visibilidad Premium activa!',
            )
          else if (actualizada.cerrada)
            _EstadoSimple(
              icono: Icons.info_outline,
              color: Colors.grey.shade500,
              texto: 'Esta publicación ya está finalizada, no se puede solicitar Visibilidad Premium',
            )
          else ...[
            const Text(
              'Cómo funciona',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            const _Paso(
              numero: '1',
              texto: 'Paga \$2.50 USD (equivalente sandbox a los \$10.000 COP) con PayPal.',
            ),
            const _Paso(
              numero: '2',
              texto: 'PayPal confirma el pago automáticamente — no hace falta revisión manual.',
            ),
            const _Paso(
              numero: '3',
              texto: 'Tu publicación queda destacada al instante.',
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pagando ? null : () => _pagar(actualizada.id),
              icon: _pagando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline, size: 18),
              label: Text(
                _pagando ? 'Procesando...' : 'Pagar con PayPal (sandbox)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAD7A16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String descripcion;
  const _Encabezado({required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/premium_banner.jpg',
              fit: BoxFit.cover,
              cacheWidth: 800,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xB8402B06), Color(0x73AD7A16)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Destaca tu publicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aparece primero cuando alguien busque servicios en tu zona',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '\$10.000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'pago único',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Beneficio {
  final IconData icono;
  final String texto;
  const _Beneficio({required this.icono, required this.texto});
}

class _FilaBeneficios extends StatelessWidget {
  final List<_Beneficio> beneficios;
  const _FilaBeneficios({required this.beneficios});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: beneficios
          .map(
            (b) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: tema.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tema.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: tema.brightness == Brightness.dark ? 0.2 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(b.icono, color: const Color(0xFFAD7A16), size: 22),
                    const SizedBox(height: 8),
                    Text(
                      b.texto,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tema.colorScheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Así se ve en el feed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _tarjetaEjemplo(context, destacada: false)),
            const SizedBox(width: 10),
            Expanded(child: _tarjetaEjemplo(context, destacada: true)),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaEjemplo(BuildContext context, {required bool destacada}) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: destacada ? const Color(0xFFFFFDF6) : tema.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: destacada ? null : Border.all(color: tema.dividerColor),
            boxShadow: [
              BoxShadow(
                color: destacada
                    ? const Color(0xFFAD7A16).withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: destacada ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (destacada)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 9, color: const Color(0xFFAD7A16)),
                      const SizedBox(width: 3),
                      const Text(
                        'DESTACADO',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAD7A16),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFE3F2EC),
                    child: Text(
                      'T',
                      style: TextStyle(fontSize: 9, color: Color(0xFF666666)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          destacada ? 'Con Premium' : 'Sin Premium',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: destacada ? const Color(0xFFAD7A16) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final String numero;
  final String texto;
  const _Paso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.azulCeleste,
              shape: BoxShape.circle,
            ),
            child: Text(
              numero,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoSimple extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;
  const _EstadoSimple({
    required this.icono,
    required this.color,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 48),
        const SizedBox(height: 12),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: color == Colors.grey.shade500 ? color : null),
        ),
      ],
    );
  }
}
