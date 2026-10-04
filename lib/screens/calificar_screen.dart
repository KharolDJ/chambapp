import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/calificacion.dart';
import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';
import '../widgets/foto_image.dart';

class CalificarScreen extends StatefulWidget {
  final String paraUsuarioId;
  final String paraNombre;
  final String peticionId;

  const CalificarScreen({
    super.key,
    required this.paraUsuarioId,
    required this.paraNombre,
    required this.peticionId,
  });

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  int _estrellas = 5;
  final _comentarioController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar(BuildContext context) async {
    final usuarioActual = context.read<AppProvider>().usuarioActual;
    if (usuarioActual == null) return;

    setState(() => _enviando = true);
    final exito = await context.read<AppProvider>().calificarUsuario(
      Calificacion(
        id: FirebaseFirestore.instance.collection('calificaciones').doc().id,
        deUsuarioId: usuarioActual.id,
        paraUsuarioId: widget.paraUsuarioId,
        estrellas: _estrellas,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        fecha: DateTime.now(),
        peticionId: widget.peticionId,
      ),
    );
    if (!context.mounted) return;
    if (!exito) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la calificación. Intenta de nuevo.'),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final provider = context.watch<AppProvider>();
    // Búsqueda null-safe (no firstWhere): igual que en otras pantallas, la
    // persona puede no estar todavía en el snapshot local si su cuenta es
    // muy reciente — en ese caso se cae al avatar de iniciales sin foto.
    final coincidencias = provider.todosLosUsuarios.where(
      (u) => u.id == widget.paraUsuarioId,
    );
    final fotoPath = coincidencias.isEmpty
        ? null
        : coincidencias.first.fotoPath;
    final colorAvatar = colorAvatarPara(widget.paraUsuarioId);

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorAvatar.fondo,
                    backgroundImage: proveedorFoto(fotoPath),
                    child: fotoPath != null
                        ? null
                        : Text(
                            widget.paraNombre.isNotEmpty
                                ? widget.paraNombre[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colorAvatar.texto,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Calificando a ${widget.paraNombre}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tema.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: tema.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tema.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: tema.brightness == Brightness.dark ? 0.2 : 0.04,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valor = i + 1;
                  return IconButton(
                    iconSize: 36,
                    onPressed: () => setState(() => _estrellas = valor),
                    icon: Icon(
                      valor <= _estrellas ? Icons.star : Icons.star_border,
                      color: AppColors.doradoCalificacion,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              style: TextStyle(color: tema.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                filled: true,
                fillColor: tema.cardColor,
                contentPadding: const EdgeInsets.all(14),
                // Antes sin borde en ningún estado — el campo se perdía
                // contra el fondo (blanco sobre blanco en tema claro). Un
                // borde sutil siempre visible, y el celeste de acento solo
                // al enfocar.
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tema.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tema.dividerColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: AppColors.celesteCategoria,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviando ? null : () => _enviar(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: tema.brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.negroProfundo,
                foregroundColor: tema.brightness == Brightness.dark
                    ? AppColors.negroProfundo
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _enviando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tema.brightness == Brightness.dark
                            ? AppColors.negroProfundo
                            : Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar calificación',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
