import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/peticion_card.dart';

/// Perfil de solo lectura de otro usuario (empleador o trabajador),
/// alcanzable desde la búsqueda de personas en el feed. A diferencia de
/// PerfilScreen (que siempre muestra al usuario logueado), esta pantalla no
/// tiene acciones de dueño: sin editar, sin cambiar de rol, y
/// deliberadamente sin botón de contacto — el contacto sigue reservado al
/// flujo de aplicar/seleccionar de una publicación concreta.
class PerfilPublicoScreen extends StatefulWidget {
  final String usuarioId;
  const PerfilPublicoScreen({super.key, required this.usuarioId});

  @override
  State<PerfilPublicoScreen> createState() => _PerfilPublicoScreenState();
}

class _PerfilPublicoScreenState extends State<PerfilPublicoScreen> {
  Usuario? _usuarioRemoto;
  bool _buscandoEnFirestore = false;
  bool _noEncontrado = false;

  Usuario? _buscarLocal(AppProvider provider) {
    for (final u in provider.todosLosUsuarios) {
      if (u.id == widget.usuarioId) return u;
    }
    return null;
  }

  Future<void> _buscarEnFirestore() async {
    if (_buscandoEnFirestore) return;
    _buscandoEnFirestore = true;
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.usuarioId).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() => _usuarioRemoto = Usuario.fromJson(doc.data()!));
      } else {
        setState(() => _noEncontrado = true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _noEncontrado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = _buscarLocal(provider) ?? _usuarioRemoto;

    if (usuario == null && !_noEncontrado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarEnFirestore());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: Text(usuario?.nombre ?? 'Perfil'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: usuario == null
          ? Center(
              child: _noEncontrado
                  ? Text(
                      'Este usuario ya no está disponible',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  : const CircularProgressIndicator(color: Color(0xFF0F6E56)),
            )
          : _CuerpoPerfil(usuario: usuario, provider: provider),
    );
  }
}

class _CuerpoPerfil extends StatelessWidget {
  final Usuario usuario;
  final AppProvider provider;
  const _CuerpoPerfil({required this.usuario, required this.provider});

  ImageProvider? _fotoSiExiste() {
    final ruta = usuario.fotoPath;
    if (ruta == null) return null;
    final archivo = File(ruta);
    if (!archivo.existsSync()) return null;
    return FileImage(archivo);
  }

  @override
  Widget build(BuildContext context) {
    final foto = _fotoSiExiste();
    final calificaciones =
        provider.calificaciones.where((c) => c.paraUsuarioId == usuario.id).toList().reversed.toList();
    final publicaciones = provider.peticiones.where((p) => p.autorId == usuario.id).toList()
      ..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
    final publicacionesActivas = publicaciones.where((p) => !p.cerrada).toList();
    final publicacionesFinalizadas = publicaciones.where((p) => p.cerrada).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFE1F5EE),
              backgroundImage: foto,
              child: foto == null ? const Icon(Icons.person, size: 50, color: Color(0xFF0F6E56)) : null,
            ),
            const SizedBox(height: 14),
            Text(usuario.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (usuario.numeroCalificaciones > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFFAD7A16)),
                  const SizedBox(width: 4),
                  Text(
                    '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones} calificaciones)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFFAD7A16)),
                    SizedBox(width: 4),
                    Text(
                      'Nuevo en la plataforma',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAD7A16)),
                    ),
                  ],
                ),
              ),
            if (usuario.oficios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Oficios: ${usuario.oficios.join(', ')}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
        if (publicaciones.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Publicaciones',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 12),
          if (publicacionesActivas.isNotEmpty) ...[
            Text(
              'ACTIVAS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            ...publicacionesActivas.map((p) => PeticionCard(peticion: p)),
          ],
          if (publicacionesFinalizadas.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(top: publicacionesActivas.isNotEmpty ? 8 : 0),
              child: Text(
                'FINALIZADAS',
                style:
                    TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 8),
            ...publicacionesFinalizadas.map((p) => PeticionCard(peticion: p)),
          ],
        ],
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'Calificaciones recibidas',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 12),
        if (calificaciones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Todavía nadie ha calificado a esta persona', style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          ...calificaciones.map((c) {
            String nombreAutor;
            try {
              nombreAutor = provider.todosLosUsuarios.firstWhere((u) => u.id == c.deUsuarioId).nombre;
            } catch (_) {
              nombreAutor = 'Usuario eliminado';
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < c.estrellas ? Icons.star : Icons.star_border,
                        size: 18,
                        color: const Color(0xFFAD7A16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— $nombreAutor',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F6E56)),
                  ),
                  if (c.comentario != null && c.comentario!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.comentario!, style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
