import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

const _acento = AppColors.azulCeleste;
const _ladrillo = Color(0xFFB54834);

class ReportarScreen extends StatefulWidget {
  final String tipo; // 'peticion' o 'usuario'
  final String contraId;

  const ReportarScreen({super.key, required this.tipo, required this.contraId});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  String? _motivo;
  final _comentarioController = TextEditingController();

  List<String> get _motivos => widget.tipo == 'peticion'
      ? const [
          'Contenido inapropiado',
          'Es spam o publicidad',
          'Parece un fraude o estafa',
          'Otro',
        ]
      : const [
          'Comportamiento inapropiado',
          'No se presentó al trabajo acordado',
          'Sospecha de fraude',
          'Otro',
        ];

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  bool _enviando = false;

  Future<void> _enviar() async {
    if (_motivo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un motivo')));
      return;
    }
    setState(() => _enviando = true);
    await context.read<AppProvider>().crearReporte(
      tipo: widget.tipo,
      contraId: widget.contraId,
      motivo: _motivo!,
      comentario: _comentarioController.text.trim().isEmpty
          ? null
          : _comentarioController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gracias, revisaremos tu reporte'),
        backgroundColor: _acento,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.tipo == 'peticion'
        ? 'Reportar publicación'
        : 'Reportar usuario';

    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF7E3DD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                size: 26,
                color: _ladrillo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cuál es el motivo?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tema.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
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
              child: RadioGroup<String>(
                groupValue: _motivo,
                onChanged: (v) => setState(() => _motivo = v),
                child: Column(
                  children: _motivos
                      .map(
                        (m) => RadioListTile<String>(
                          value: m,
                          title: Text(m),
                          activeColor: _acento,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ladrillo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar reporte',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
