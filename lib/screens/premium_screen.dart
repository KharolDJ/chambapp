import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../providers/app_provider.dart';
import 'pago_wompi_screen.dart';

class PremiumScreen extends StatefulWidget {
  final Peticion peticion;
  const PremiumScreen({super.key, required this.peticion});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

/// Visibilidad Premium sobre una publicación = un solo producto, "Urgente"
/// ($10.000), como lo describe la propuesta F-DC-124 ("Urgentes y Podio"):
/// etiqueta, primer lugar del feed, filtro "Urgente" y diseño dorado. Antes
/// había además un "Destacar" aparte que hacía prácticamente lo mismo.
class _PremiumScreenState extends State<PremiumScreen> {
  bool _pagando = false;

  Future<void> _pagar(String peticionId) async {
    setState(() => _pagando = true);
    final resultado = await Navigator.push<ResultadoPagoWompi>(
      context,
      MaterialPageRoute(
        builder: (_) => const PagoWompiScreen(
          montoCentavos: 1000000, // $10.000 COP
          producto: 'urgente',
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _pagando = false);
    if (resultado == null) return; // cancelado
    if (resultado.estado != 'APPROVED') {
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
      resultado.transaccionId,
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
              // Mismo set de íconos PNG a color que la Visibilidad Premium
              // del trabajador (premium_trabajador_screen.dart), para que
              // ambos lados se vean como un mismo producto.
              _Beneficio(
                iconoAsset: 'assets/icon/insignia.png',
                texto: 'Más visibilidad\npara tu oferta',
              ),
              _Beneficio(
                iconoAsset: 'assets/icon/podio.png',
                texto: 'Primero en el\nfeed de tu zona',
              ),
              _Beneficio(
                iconoAsset: 'assets/icon/urgente.png',
                texto: 'Etiqueta dorada\n"Urgente"',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _VistaPrevia(),
          const SizedBox(height: 28),
          if (actualizada.cerrada && !actualizada.esUrgente)
            _EstadoSimple(
              icono: Icons.info_outline,
              color: Colors.grey.shade500,
              texto: 'Esta publicación ya está finalizada, no se puede solicitar Visibilidad Premium',
            )
          else ...[
            _OpcionBeneficio(
              iconoAsset: 'assets/icon/urgente.png',
              color: const Color(0xFFAD7A16),
              titulo: 'Urgente',
              descripcion:
                  'Etiqueta dorada "Se precisa urgentemente", primer lugar en el feed de tu zona y aparición en el filtro "Urgente".',
              activo: actualizada.esUrgente,
              textoActivo: 'Urgente activa',
              finalizada: actualizada.cerrada,
              pagando: _pagando,
              bloqueado: _pagando,
              onPagar: () => _pagar(actualizada.id),
            ),
            if (!actualizada.esUrgente) ...[
              const SizedBox(height: 24),
              const Text(
                'Cómo funciona',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              const _Paso(
                numero: '1',
                texto: 'Paga \$10.000 COP con Wompi (tarjeta, Nequi o PSE).',
              ),
              const _Paso(
                numero: '2',
                texto: 'Wompi confirma el pago automáticamente — no hace falta revisión manual.',
              ),
              const _Paso(
                numero: '3',
                texto: 'Tu publicación queda marcada como Urgente al instante.',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OpcionBeneficio extends StatelessWidget {
  final String iconoAsset;
  final Color color;
  final String titulo;
  final String descripcion;
  final bool activo;
  final String textoActivo;
  final bool finalizada;
  final bool pagando;
  final bool bloqueado;
  final VoidCallback onPagar;

  const _OpcionBeneficio({
    required this.iconoAsset,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.activo,
    required this.textoActivo,
    required this.finalizada,
    required this.pagando,
    required this.bloqueado,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    final Widget accion;
    if (activo) {
      accion = Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            textoActivo,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else if (finalizada) {
      accion = Text(
        'Publicación finalizada',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
      );
    } else {
      accion = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: bloqueado ? null : onPagar,
          icon: pagando
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: esOscuro ? AppColors.negroProfundo : Colors.white,
                  ),
                )
              : const Icon(Icons.lock_outline, size: 18),
          label: Text(
            pagando ? 'Procesando...' : 'Pagar con Wompi (pruebas)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: esOscuro ? Colors.white : AppColors.negroProfundo,
            foregroundColor: esOscuro ? AppColors.negroProfundo : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activo ? color.withValues(alpha: 0.5) : tema.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(iconoAsset, width: 22, height: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '\$10.000',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: tema.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          accion,
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
                  'Marca tu publicación como Urgente',
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
  final String iconoAsset;
  final String texto;
  const _Beneficio({required this.iconoAsset, required this.texto});
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
                    Image.asset(
                      b.iconoAsset,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
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
            color: destacada ? Colors.white : tema.cardColor,
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
                        'URGENTE',
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
              color: AppColors.dorado,
              shape: BoxShape.circle,
            ),
            // Número en blanco sobre el círculo dorado de marca (#AD7A16),
            // igual que las demás insignias doradas con texto blanco.
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
