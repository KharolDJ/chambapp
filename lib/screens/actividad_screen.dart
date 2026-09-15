import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
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
      appBar: AppBar(
        title: Text(esEmpleador ? 'Mis publicaciones' : 'Mis intereses'),
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
      acciones: [
        AccionPeticion(
          iconoAsset: 'assets/icon/interesados.png',
          texto: 'Interesados (${peticion.interesados.length})',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InteresadosScreen(peticion: peticion),
            ),
          ),
        ),
        AccionPeticion(
          iconoAsset: 'assets/icon/estrella.png',
          texto: 'Premium',
          color: const Color(0xFFAD7A16),
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
        if (peticion.cerrada && peticion.trabajadorSeleccionadoId != null)
          if (yaCalifique)
            const AccionPeticion(
              icono: Icons.check_circle,
              texto: 'Ya calificaste',
              color: AppColors.azulCeleste,
            )
          else
            AccionPeticion(
              icono: Icons.star_outline,
              texto: 'Calificar',
              onTap: () => _abrirCalificar(context),
            ),
        AccionPeticion(
          iconoAsset: 'assets/icon/archivar.png',
          texto: 'Archivar',
          color: const Color(0xFF666666),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeticionCard(peticion: peticion),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: otroSeleccionado
              ? Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'El empleador seleccionó a otro trabajador',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                )
              : _EtapasAplicacion(
                  vistoPorEmpleador:
                      miId != null &&
                      peticion.vistosPorEmpleador.contains(miId),
                  seleccionado: esSeleccionado,
                  premium: peticion.premiumAprobada,
                ),
        ),
        if (esSeleccionado && peticion.cerrada)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child:
                (miId != null &&
                    provider.yaCalifique(
                      deUsuarioId: miId,
                      peticionId: peticion.id,
                    ))
                ? const Chip(
                    avatar: Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.azulCeleste,
                    ),
                    label: Text('Ya calificaste'),
                  )
                : OutlinedButton.icon(
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
                    label: const Text('Calificar al empleador'),
                  ),
          ),
      ],
    );
  }
}

class _EtapasAplicacion extends StatelessWidget {
  final bool vistoPorEmpleador;
  final bool seleccionado;
  final bool premium;
  const _EtapasAplicacion({
    required this.vistoPorEmpleador,
    required this.seleccionado,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _paso(context, 'Aplicaste', true),
        _linea(context, vistoPorEmpleador),
        _paso(context, 'Visto', vistoPorEmpleador),
        _linea(context, seleccionado),
        _paso(context, 'Te contactan', seleccionado),
      ],
    );
  }

  Widget _paso(BuildContext context, String texto, bool completado) {
    final color = !completado
        ? Theme.of(context).dividerColor
        : (premium ? const Color(0xFFAD7A16) : AppColors.azulCeleste);
    return Expanded(
      child: Column(
        children: [
          Icon(
            completado ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 2),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  Widget _linea(BuildContext context, bool completado) {
    final color = !completado
        ? Theme.of(context).dividerColor
        : (premium ? const Color(0xFFAD7A16) : AppColors.azulCeleste);
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: color,
    );
  }
}
