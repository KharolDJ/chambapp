import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/premium_trabajador.dart';
import '../providers/app_provider.dart';

class PremiumTrabajadorScreen extends StatelessWidget {
  const PremiumTrabajadorScreen({super.key});

  void _abrirSolicitud(BuildContext contextPantalla, String oficio) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: contextPantalla,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Visibilidad Premium — $oficio',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Destaca tu perfil en el Podio de Recomendados de $oficio por 30 días — \$10.000',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              const _Paso(numero: '1', texto: 'Transfiere \$10.000 a la cuenta indicada por el equipo Chambapp.'),
              const _Paso(numero: '2', texto: 'Ingresa abajo la referencia de tu comprobante de pago.'),
              const _Paso(numero: '3', texto: 'El equipo revisa y aprueba — apareces en el Podio de tu oficio.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Referencia del comprobante de pago',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa la referencia del comprobante')),
                    );
                    return;
                  }
                  final navigator = Navigator.of(context);
                  final mensajero = ScaffoldMessenger.of(context);
                  final error = await context.read<AppProvider>().solicitarPremiumTrabajador(
                        oficio: oficio,
                        comprobante: controller.text.trim(),
                      );
                  navigator.pop();
                  if (error != null) {
                    mensajero.showSnackBar(SnackBar(content: Text(error)));
                    return;
                  }
                  if (!contextPantalla.mounted) return;
                  _mostrarExito(
                    contextPantalla,
                    icono: Icons.hourglass_top,
                    titulo: 'Solicitud enviada',
                    mensaje:
                        'La revisaremos y en cuanto se apruebe, ocuparás un cupo en el Podio de "$oficio" por 30 días.',
                    textoBoton: 'Ver el Podio de $oficio',
                    onVerPodio: () {
                      contextPantalla.read<AppProvider>().irAlPodioDe(oficio);
                      Navigator.of(contextPantalla).popUntil((route) => route.isFirst);
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6E56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Solicitar Visibilidad Premium', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Visibilidad Premium'),
        backgroundColor: const Color(0xFFF9F9FB),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: (usuario == null || usuario.oficios.isEmpty)
          ? Center(
              child: Text(
                'Agrega al menos un oficio en tu perfil para poder destacarte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF666666)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Encabezado(),
                const SizedBox(height: 20),
                const _FilaBeneficios(
                  beneficios: [
                    _Beneficio(icono: Icons.emoji_events, texto: 'Podio de\ntu oficio'),
                    _Beneficio(icono: Icons.calendar_month, texto: 'Visible\n30 días'),
                    _Beneficio(icono: Icons.workspace_premium, texto: 'Insignia dorada\nexclusiva'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Tus oficios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800)),
                const SizedBox(height: 12),
                ...usuario.oficios.map((oficio) {
                  PremiumTrabajador? vigente;
                  for (final p in provider.premiumTrabajadores) {
                    if (p.usuarioId == usuario.id && p.oficio == oficio && (p.activo || (p.solicitada && !p.aprobada))) {
                      vigente = p;
                      break;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (vigente != null && vigente.activo) ? const Color(0xFF0F6E56) : Colors.grey.shade200,
                        width: (vigente != null && vigente.activo) ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (vigente != null && vigente.activo)
                              ? const Color(0xFF0F6E56).withValues(alpha: 0.16)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: (vigente != null && vigente.activo) ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(oficio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 10),
                        if (vigente != null && vigente.activo) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF0F6E56), size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Activa hasta ${_formatearFecha(vigente.expiraEn!)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F6E56)),
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
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: Text('Ver mi puesto en $oficio'),
                            ),
                          ),
                        ] else if (vigente != null && vigente.solicitada && !vigente.aprobada) ...[
                          Row(
                            children: [
                              const Icon(Icons.hourglass_top, color: Color(0xFFAD7A16), size: 18),
                              const SizedBox(width: 6),
                              const Expanded(child: Text('Tu solicitud está en revisión', style: TextStyle(fontSize: 13))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () async {
                              await context.read<AppProvider>().aprobarPremiumTrabajadorDemo(vigente!.id);
                              if (!context.mounted) return;
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
                            },
                            child: const Text('Simular aprobación (demo)'),
                          ),
                        ] else if (provider.podioLleno(oficio)) ...[
                          Row(
                            children: [
                              Icon(Icons.block, size: 18, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Los 3 cupos de "$oficio" están ocupados. Vuelve a intentar cuando se libere uno.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _abrirSolicitud(context, oficio),
                              icon: const Icon(Icons.star_outline, size: 16),
                              label: const Text('Solicitar Visibilidad Premium (\$10.000)'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _formatearFecha(DateTime fecha) => '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

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
                decoration: const BoxDecoration(color: Color(0xFFE3F2EC), shape: BoxShape.circle),
                child: Icon(icono, color: const Color(0xFF0F6E56), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.4),
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
                    backgroundColor: const Color(0xFF0F6E56),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F6E56), Color(0xFF0B5344)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text('PODIO DE RECOMENDADOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Destaca tu perfil',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Aparece entre los 3 destacados de tu oficio cuando alguien busque tu categoría',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('\$10.000', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('por 30 días, por oficio', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
            ],
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
    return Row(
      children: beneficios
          .map(
            (b) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(b.icono, color: const Color(0xFF0F6E56), size: 22),
                    const SizedBox(height: 8),
                    Text(
                      b.texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A), height: 1.25),
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
            decoration: const BoxDecoration(color: Color(0xFF0F6E56), shape: BoxShape.circle),
            child: Text(numero, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
