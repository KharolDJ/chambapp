import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  State<PublicarScreen> createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  final _descripcionController = TextEditingController();
  final _barrioController = TextEditingController();
  String _categoria = 'Plomería';
  bool _urgente = false;

  final List<String> _categorias = [
    'Plomería', 'Electricidad', 'Cocina', 'Carpintería', 'Jardinería', 'Limpieza del hogar', 'Pintura',
  ];

  void _publicar() {
    if (_descripcionController.text.trim().isEmpty || _barrioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa la descripción y el barrio')),
      );
      return;
    }

    final usuarioActual = context.read<AppProvider>().usuarioActual;
    if (usuarioActual == null) return;

    context.read<AppProvider>().publicarPeticion(
          Peticion(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            autorId: usuarioActual.id,
            autorNombre: usuarioActual.nombre,
            barrio: _barrioController.text.trim(),
            descripcion: _descripcionController.text.trim(),
            categoria: _categoria,
            urgente: _urgente,
            creadaEn: DateTime.now(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Publicar petición'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500),
                  const SizedBox(height: 6),
                  Text('Agregar foto (opcional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '¿Qué necesitas?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _barrioController,
              decoration: InputDecoration(
                labelText: 'Barrio',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: InputDecoration(
                labelText: 'Categoría',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _urgente,
              onChanged: (v) => setState(() => _urgente = v),
              title: const Text('Marcar como urgente'),
              activeThumbColor: const Color(0xFFB54834),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _publicar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
