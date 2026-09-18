import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/premium_trabajador.dart';
import '../providers/app_provider.dart';
import '../widgets/brillo_dorado.dart';
import 'pago_paypal_screen.dart';

class PremiumTrabajadorScreen extends StatelessWidget {
  const PremiumTrabajadorScreen({super.key});

  Future<void> _pagarYActivar(BuildContext context, String oficio) async {
    final resultado = await Navigator.push<ResultadoPagoPaypal>(
      context,
      MaterialPageRoute(
        builder: (_) => const PagoPaypalScreen(
          montoUsd: '2.50',
          descripcion: 'Visibilidad Premium Chambapp (sandbox)',
        ),
      ),
    );
    if (resultado == null) return; // cancelado
    if (!context.mounted) return;
    if (resultado.estado != 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El pago no se completó (estado: ${resultado.estado})'),
        ),
      );
      return;
    }
    final error = await context.read<AppProvider>().activarPremiumTrabajador(
      oficio: oficio,
      ordenPaypalId: resultado.ordenId,
    );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _mostrarExito(
      context,
      icono: Icons.emoji_events,
      titulo: '¡Ya estás en el Podio!',
      mensaje:
          'Tu perfil ya aparece entre los destacados de "$oficio" por los próximos 30 días.',
      textoBoton: 'Ver mi puesto en $oficio',
      onVerPodio: () {
        context.read<AppProvider>().irAlPodioDe(oficio);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final colorTituloPremium = esOscuro
        ? const Color(0xFFF5E6BE)
        : const Color(0xFF3A2A12);

    return Scaffold(
      appBar: AppBar(title: const Text('Visibilidad Premium')),
      body: (usuario == null || usuario.oficios.isEmpty)
          ? Center(
              child: Text(
                'Agrega al menos un oficio en tu perfil para poder destacarte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tema.textTheme.bodySmall?.color),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Encabezado(),
                const SizedBox(height: 20),
                const _FilaBeneficios(
                  beneficios: [
                    _Beneficio(
                      iconoAsset: 'assets/icon/podio.png',
                      texto: 'Podio de\ntu oficio',
                    ),
                    _Beneficio(
                      iconoAsset: 'assets/icon/calendario.png',
                      texto: 'Visible\n30 días',
                    ),
                    _Beneficio(
                      iconoAsset: 'assets/icon/insignia.png',
                      texto: 'Insignia dorada\nexclusiva',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Tus oficios',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: tema.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...usuario.oficios.map((oficio) {
                  PremiumTrabajador? vigente;
                  for (final p in provider.premiumTrabajadores) {
                    if (p.usuarioId == usuario.id &&
                        p.oficio == oficio &&
                        (p.activo || (p.solicitada && !p.aprobada))) {
                      vigente = p;
                      break;
                    }
                  }

                  final activo = vigente != null && vigente.activo;

                  Widget construirTarjeta(double? t) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: activo ? null : tema.cardColor,
                      gradient: activo
                          ? fondoDoradoDeslizante(t, esOscuro: esOscuro)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: activo
                          ? null
                          : Border.all(color: tema.dividerColor),
                      boxShadow: activo
                          ? sombraDorada(esOscuro: esOscuro)
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: esOscuro ? 0.2 : 0.03,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oficio,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: activo
                                ? colorTituloPremium
                                : tema.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (activo) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: esOscuro
                                    ? const Color(0xFFE0B84A)
                                    : const Color(0xFFAD7A16),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Activa hasta ${_formatearFecha(vigente!.expiraEn!)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: esOscuro
                                        ? const Color(0xFFE0B84A)
                                        : const Color(0xFFAD7A16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<AppProvider>().irAlPodioDe(oficio);
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFAD7A16),
                                side: const BorderSide(
                                  color: Color(0xFFAD7A16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: Text('Ver mi puesto en $oficio'),
                            ),
                          ),
                        ] else if (provider.podioLleno(oficio)) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.block,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Los ${provider.cupoMaximoVipPorOficio} cupos VIP de "$oficio" están ocupados. Vuelve a intentar cuando se libere uno.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tema.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _pagarYActivar(context, oficio),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFAD7A16),
                                side: const BorderSide(
                                  color: Color(0xFFAD7A16),
                                ),
                              ),
                              icon: const Icon(Icons.lock_outline, size: 16),
                              label: const Text(
                                'Pagar con PayPal (sandbox)',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: activo
                        ? BrilloDoradoAnimado(
                            borderRadius: BorderRadius.circular(14),
                            builder: (context, t) => construirTarjeta(t),
                          )
                        : construirTarjeta(null),
                  );
                }),
              ],
            ),
    );
  }

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  void _mostrarExito(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String mensaje,
    required String textoBoton,
    required VoidCallback onVerPodio,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF6D8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: const Color(0xFFAD7A16), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onVerPodio();
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(textoBoton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD7A16),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icon/podio.png',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'PODIO DE RECOMENDADOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Destaca tu perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rota entre los 3 destacados de tu oficio cuando alguien busque tu categoría',
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
                      'por 30 días, por oficio',
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
  final IconData? icono;
  final String? iconoAsset;
  final String texto;
  const _Beneficio({this.icono, this.iconoAsset, required this.texto})
    : assert(
        icono != null || iconoAsset != null,
        'Debe proveer icono o iconoAsset',
      );
}

class _FilaBeneficios extends StatelessWidget {
  final List<_Beneficio> beneficios;
  const _FilaBeneficios({required this.beneficios});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
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
                        alpha: esOscuro ? 0.2 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    b.iconoAsset != null
                        ? Image.asset(
                            b.iconoAsset!,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            b.icono,
                            color: esOscuro
                                ? const Color(0xFFE0B84A)
                                : const Color(0xFFAD7A16),
                            size: 22,
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
