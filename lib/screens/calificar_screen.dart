import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
            comentario: _comentarioController.text.trim().isEmpty ? null : _comentarioController.text.trim(),
            fecha: DateTime.now(),
            peticionId: widget.peticionId,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Calificar'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Calificando a: ${widget.paraNombre}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final valor = i + 1;
                return IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => _estrellas = valor),
                  icon: Icon(
                    valor <= _estrellas ? Icons.star : Icons.star_border,
                    color: const Color(0xFFAD7A16),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _enviar(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enviar calificación', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
