import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/cabecera_oscura.dart';
import '../widgets/peticion_card.dart';
import 'interesados_screen.dart';
import 'premium_screen.dart';
import 'calificar_screen.dart';

class ActividadScreen extends StatelessWidget {
  const ActividadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final esEmpleador = provider.rolActual == RolUsuario.empleador;
    final lista = esEmpleador
        ? provider.misPublicaciones
        : provider.misIntereses;

    final tema = Theme.of(context);

    return Scaffold(
      appBar: cabeceraOscura(
        esEmpleador ? 'Mis publicaciones' : 'Mis intereses',
      ),
      body: lista.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esEmpleador
                          ? Icons.post_add_outlined
                          : Icons.search_outlined,
                      size: 56,
                      color: tema.dividerColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      esEmpleador
                          ? 'Aún no has publicado nada'
                          : 'Aún no marcaste interés en ninguna',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tema.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      esEmpleador
                          ? 'Toca el botón "+" para publicar tu primera petición'
                          : 'Explora el feed y toca "Aplicar" en lo que te interese',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: tema.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (context, i) => esEmpleador
                  ? _ItemEmpleador(peticion: lista[i])
                  : _ItemTrabajador(peticion: lista[i]),
            ),
    );
  }
}

// Insignia de esquina para una petición ya calificada — reemplaza el
// AccionPeticion/Chip que antes vivía entre los botones o junto al anillo
// de progreso, para que no compita visualmente con el contenido central.
class _InsigniaYaCalificaste extends StatelessWidget {
  // Dorado solo para el caso especial: oferta urgente/premium ya
  // finalizada; cualquier otro caso (oferta normal) va en celeste. En
  // ambos el texto es blanco, así que se usan los tonos saturados
  // (dorado de marca #AD7A16, celeste #0284C7) y no sus versiones claras
  // (#D4AF37, #7DD3FC), sobre las que el blanco casi no se leía.
  final bool esPremiumFinalizada;
  const _InsigniaYaCalificaste({this.esPremiumFinalizada = false});

  @override
  Widget build(BuildContext context) {
    final color = esPremiumFinalizada
        ? AppColors.dorado
        : AppColors.celesteCategoria;
    const colorTexto = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: colorTexto),
          const SizedBox(width: 5),
          Text(
            'Ya calificaste',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemEmpleador extends StatelessWidget {
  final Peticion peticion;
  const _ItemEmpleador({required this.peticion});

  void _abrirCalificar(BuildContext context) {
    final provider = context.read<AppProvider>();
    Usuario? trabajador;
    try {
      trabajador = peticion.interesados.firstWhere(
        (u) => u.id == peticion.trabajadorSeleccionadoId,
      );
    } catch (_) {
      try {
        trabajador = provider.todosLosUsuarios.firstWhere(
          (u) => u.id == peticion.trabajadorSeleccionadoId,
        );
      } catch (_) {
        trabajador = null;
      }
    }
    if (trabajador == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese trabajador ya no está disponible')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalificarScreen(
          paraUsuarioId: trabajador!.id,
          paraNombre: trabajador.nombre,
          peticionId: peticion.id,
        ),
      ),
    );
  }

  Future<void> _confirmarArchivar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Archivar esta publicación?'),
        content: Text(
          peticion.premiumAprobada
              ? 'Ya no aparecerá en el feed ni en tus publicaciones. Los interesados y calificaciones asociados se conservan, pero perderás la Visibilidad Premium activa — no se reembolsa.'
              : 'Ya no aparecerá en el feed ni en tus publicaciones. Los interesados y calificaciones asociados se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (!context.mounted) return;
    context.read<AppProvider>().archivarPeticion(peticion.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final miId = provider.usuarioActual?.id;
    final yaCalifique =
        miId != null &&
        provider.yaCalifique(deUsuarioId: miId, peticionId: peticion.id);

    return PeticionCard(
      peticion: peticion,
      insigniaEsquina: yaCalifique
          ? _InsigniaYaCalificaste(
              esPremiumFinalizada: peticion.premiumAprobada,
            )
          : null,
      acciones: [
        // Interesados, Premium y Archivar: solo texto (sin ícono), en botón
        // negro sólido; Premium con texto/borde dorado para distinguirse.
        AccionPeticion(
          texto: 'Interesados (${peticion.interesados.length})',
          estilo: EstiloAccion.solido,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteresadosScreen(peticion: peticion),
            ),
          ),
        ),
        AccionPeticion(
          texto: 'Premium',
          estilo: EstiloAccion.solidoPremium,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PremiumScreen(peticion: peticion),
            ),
          ),
        ),
        if (peticion.trabajadorSeleccionadoId != null && !peticion.cerrada)
          AccionPeticion(
            icono: Icons.check_circle_outline,
            texto: 'Finalizar',
            onTap: () =>
                context.read<AppProvider>().cerrarPeticion(peticion.id),
          ),
        if (peticion.cerrada &&
            peticion.trabajadorSeleccionadoId != null &&
            !yaCalifique)
          AccionPeticion(
            icono: Icons.star_outline,
            texto: 'Calificar',
            onTap: () => _abrirCalificar(context),
          ),
        AccionPeticion(
          texto: 'Archivar',
          estilo: EstiloAccion.solido,
          onTap: () => _confirmarArchivar(context),
        ),
      ],
    );
  }
}

class _ItemTrabajador extends StatelessWidget {
  final Peticion peticion;
  const _ItemTrabajador({required this.peticion});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final miId = provider.usuarioActual?.id;
    final esSeleccionado = peticion.trabajadorSeleccionadoId == miId;
    final otroSeleccionado =
        peticion.trabajadorSeleccionadoId != null && !esSeleccionado;
    final yaCalifique =
        miId != null &&
        provider.yaCalifique(deUsuarioId: miId, peticionId: peticion.id);

    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    Widget? accionCompletada;
    if (esSeleccionado && peticion.cerrada && !yaCalifique) {
      accionCompletada = ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CalificarScreen(
              paraUsuarioId: peticion.autorId,
              paraNombre: peticion.autorNombre,
              peticionId: peticion.id,
            ),
          ),
        ),
        icon: const Icon(Icons.star_outline, size: 16),
        label: const Text(
          'Calificar',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        // Botón de acción principal en negro/blanco (invertido en oscuro) —
        // ya no en el dorado de acento.
        style: ElevatedButton.styleFrom(
          backgroundColor: esOscuro ? Colors.white : AppColors.negroProfundo,
          foregroundColor: esOscuro ? AppColors.negroProfundo : Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (esSeleccionado && !peticion.cerrada) {
      // Cierre simétrico: antes solo el empleador podía marcar el trabajo
      // como terminado con "Finalizar" — ahora el trabajador también puede
      // iniciarlo desde su lado, sin depender de que el empleador lo haga.
      accionCompletada = OutlinedButton.icon(
        onPressed: () =>
            context.read<AppProvider>().cerrarPeticion(peticion.id),
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Marcar como terminado'),
      );
    }

    return PeticionCard(
      peticion: peticion,
      insigniaEsquina: esSeleccionado && peticion.cerrada && yaCalifique
          ? _InsigniaYaCalificaste(
              esPremiumFinalizada: peticion.premiumAprobada,
            )
          : null,
      piePersonalizado: otroSeleccionado
          ? Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'El empleador seleccionó a otro trabajador',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            )
          : _EtapasAplicacion(
              vistoPorEmpleador:
                  miId != null && peticion.vistosPorEmpleador.contains(miId),
              seleccionado: esSeleccionado,
              finalizado: peticion.cerrada,
              premium: peticion.premiumAprobada,
              accionCompletada: accionCompletada,
            ),
    );
  }
}

class _EtapasAplicacion extends StatelessWidget {
  final bool vistoPorEmpleador;
  final bool seleccionado;
  final bool finalizado;
  final bool premium;
  // Cuando hay una acción pendiente de esta persona (marcar como
  // terminado en el paso 3, o calificar en el paso 4), este widget
  // reemplaza el texto de estado/paso junto al anillo — no tiene sentido
  // seguir mostrando "Te contactan · Paso 3 de 4" cuando lo que importa
  // ahora es la acción siguiente.
  final Widget? accionCompletada;
  const _EtapasAplicacion({
    required this.vistoPorEmpleador,
    required this.seleccionado,
    required this.finalizado,
    required this.premium,
    this.accionCompletada,
  });

  // Antes ambas ramas caían en el mismo dorado "cobrizo" (#AD7A16) sin
  // distinción real. Ahora: premium/destacado en un dorado más fino
  // (doradoOscuro, #D4AF37) y ofertas normales en celeste claro.
  Color _colorActivo() =>
      premium ? AppColors.doradoOscuro : AppColors.celesteCategoriaOscuro;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pasos = [
      ('Aplicaste', true),
      ('Visto', vistoPorEmpleador),
      ('Te contactan', seleccionado),
      ('Finalizado', finalizado),
    ];
    // Como los pasos son secuenciales (uno no se completa sin el anterior),
    // contar los `true` equivale al índice del último paso alcanzado — no
    // hace falta buscar dónde está el corte.
    final completados = pasos.where((p) => p.$2).length;
    final progreso = completados / pasos.length;
    final estadoActual = pasos[completados - 1].$1;
    final colorActivo = _colorActivo();

    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: progreso,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: tema.dividerColor,
                  valueColor: AlwaysStoppedAnimation(colorActivo),
                ),
              ),
              if (finalizado) Icon(Icons.check, size: 18, color: colorActivo),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: accionCompletada != null
              ? Align(alignment: Alignment.centerLeft, child: accionCompletada)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      estadoActual,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paso $completados de ${pasos.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: tema.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
