import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

const _acento = AppColors.azulCeleste;

class VerificacionIdentidadScreen extends StatefulWidget {
  const VerificacionIdentidadScreen({super.key});

  @override
  State<VerificacionIdentidadScreen> createState() =>
      _VerificacionIdentidadScreenState();
}

class _VerificacionIdentidadScreenState
    extends State<VerificacionIdentidadScreen> {
  final _cedulaController = TextEditingController();
  String? _fotoCedulaPath;
  bool _cargando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AppProvider>().usuarioActual;
    _cedulaController.text = usuario?.cedula ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppProvider>().cargarMiVerificacionIdentidad();
      if (!mounted) return;
      setState(() => _cargando = false);
    });
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _elegirFotoCedula() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final archivo = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (archivo == null) return;
    setState(() => _fotoCedulaPath = archivo.path);
  }

  Future<void> _enviarSolicitud() async {
    final numero = _cedulaController.text.trim();
    if (numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu número de cédula')),
      );
      return;
    }
    if (_fotoCedulaPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toma o elige una foto de tu cédula')),
      );
      return;
    }

    setState(() => _enviando = true);
    final error = await context
        .read<AppProvider>()
        .solicitarVerificacionIdentidad(
          numeroCedula: numero,
          fotoCedulaPath: _fotoCedulaPath!,
        );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud enviada — la revisaremos pronto'),
        backgroundColor: _acento,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;
    final verificacion = provider.miVerificacionIdentidad;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil verificado')),
      body: _cargando || usuario == null
          ? const Center(child: CircularProgressIndicator(color: _acento))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (usuario.perfilVerificado)
                  _EstadoVerificado()
                else if (verificacion != null &&
                    verificacion.solicitada &&
                    !verificacion.aprobada)
                  const _EstadoEnRevision()
                else
                  _FormularioSolicitud(
                    cedulaController: _cedulaController,
                    fotoCedulaPath: _fotoCedulaPath,
                    enviando: _enviando,
                    onElegirFoto: _elegirFotoCedula,
                    onEnviar: _enviarSolicitud,
                  ),
              ],
            ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final IconData? icono;
  final String? iconoAsset;
  final Color color;
  final String titulo;
  final String mensaje;
  const _Encabezado({
    this.icono,
    this.iconoAsset,
    required this.color,
    required this.titulo,
    required this.mensaje,
  }) : assert(
         icono != null || iconoAsset != null,
         'Debe proveer icono o iconoAsset',
       );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: iconoAsset != null
              ? Image.asset(
                  iconoAsset!,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                )
              : Icon(icono, color: color, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _EstadoVerificado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _Encabezado(
        icono: Icons.verified,
        color: _acento,
        titulo: '¡Tu perfil está verificado!',
        mensaje: 'Los empleadores ven la insignia de verificado en tu perfil público.',
      ),
    );
  }
}

class _EstadoEnRevision extends StatelessWidget {
  const _EstadoEnRevision();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _Encabezado(
        iconoAsset: 'assets/icon/reloj_arena.png',
        color: const Color(0xFFAD7A16),
        titulo: 'Tu solicitud está en revisión',
        mensaje: 'Un administrador revisará la foto de tu cédula y activará la insignia de verificado en tu perfil.',
      ),
    );
  }
}

class _FormularioSolicitud extends StatelessWidget {
  final TextEditingController cedulaController;
  final String? fotoCedulaPath;
  final bool enviando;
  final VoidCallback onElegirFoto;
  final VoidCallback onEnviar;

  const _FormularioSolicitud({
    required this.cedulaController,
    required this.fotoCedulaPath,
    required this.enviando,
    required this.onElegirFoto,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Encabezado(
          icono: Icons.verified_outlined,
          color: _acento,
          titulo: 'Verifica tu identidad',
          mensaje: 'Sube una foto de tu cédula para que tu perfil muestre la insignia de "Perfil verificado" ante los empleadores.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: cedulaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Número de cédula',
            filled: true,
            fillColor: tema.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onElegirFoto,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: tema.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tema.dividerColor),
            ),
            child: fotoCedulaPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 32,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para agregar foto de tu cédula',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(fotoCedulaPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: enviando ? null : onEnviar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _acento,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            enviando ? 'Enviando...' : 'Enviar para verificación',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
