import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/calificacion.dart';
import '../providers/app_provider.dart';

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

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  void _enviar(BuildContext context) {
    final usuarioActual = context.read<AppProvider>().usuarioActual;
    if (usuarioActual == null) return;

    context.read<AppProvider>().calificarUsuario(
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F5EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.azulCeleste,
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
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                filled: true,
                fillColor: tema.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _enviar(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulCeleste,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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
