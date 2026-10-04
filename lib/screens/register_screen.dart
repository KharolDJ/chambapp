import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/cloudinary_service.dart';
import '../widgets/color_avatar.dart';
import '../widgets/foto_image.dart';
import 'login_screen.dart';

// Celeste en vez de dorado — pedido explícito para limpiar los acentos
// dorados del formulario de registro (barra de progreso, bordes de campo
// enfocados, chips de oficio y el enlace "¿Ya tienes cuenta?"). Un solo
// valor fijo porque este celeste ya tiene buen contraste sobre blanco y
// sobre negro profundo.
const _acento = AppColors.celesteCategoria;

enum _TipoPaso { nombre, correo, oficios, datosFinales }

class RegisterScreen extends StatefulWidget {
  final String? correoInicial;

  const RegisterScreen({super.key, this.correoInicial});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  late final TextEditingController _correoController;
  final _passwordController = TextEditingController();
  final _celularController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _barrioController = TextEditingController();

  final List<String> _oficiosSeleccionados = [];
  String? _fotoPath;
  bool _subiendoFoto = false;

  int _paso = 0;
  late final bool _esTrabajador;
  bool _enviando = false;

  String? _errorNombre;
  String? _errorCorreo;
  String? _errorPassword;
  bool _mostrarErrorOficios = false;
  String? _errorCelular;

  final List<String> _servicios = [
    'Plomería',
    'Electricidad',
    'Cocina',
    'Carpintería',
    'Jardinería',
    'Limpieza del hogar',
    'Pintura',
    'Albañilería',
    'Cerrajería',
    'Acarreos',
  ];

  static const Map<String, String> _iconosCategoria = {
    'Plomería': 'assets/icon/plomeria.png',
    'Electricidad': 'assets/icon/electricidad.png',
    'Cocina': 'assets/icon/cocina.png',
    'Carpintería': 'assets/icon/carpinteria.png',
    'Jardinería': 'assets/icon/jardineria.png',
    'Limpieza del hogar': 'assets/icon/limpieza.png',
    'Pintura': 'assets/icon/pintura.png',
    'Albañilería': 'assets/icon/albanileria.png',
    'Cerrajería': 'assets/icon/cerrajeria.png',
    'Acarreos': 'assets/icon/acarreos.png',
  };

  List<_TipoPaso> get _pasos => _esTrabajador
      ? [
          _TipoPaso.nombre,
          _TipoPaso.correo,
          _TipoPaso.oficios,
          _TipoPaso.datosFinales,
        ]
      : [_TipoPaso.nombre, _TipoPaso.correo, _TipoPaso.datosFinales];

  @override
  void initState() {
    super.initState();
    _esTrabajador =
        context.read<AppProvider>().rolActual == RolUsuario.trabajador;
    _correoController = TextEditingController(text: widget.correoInicial ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _celularController.dispose();
    _cedulaController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
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
      maxWidth: 800,
      imageQuality: 80,
    );
    if (archivo == null) return;
    setState(() => _subiendoFoto = true);
    try {
      final url = await CloudinaryService.subirFoto(File(archivo.path));
      if (!mounted) return;
      setState(() {
        _fotoPath = url;
        _subiendoFoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _subiendoFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir la foto. Intenta de nuevo.'),
        ),
      );
    }
  }

  void _atras() {
    if (_paso > 0) {
      setState(() => _paso -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _siguiente() async {
    final tipo = _pasos[_paso];

    if (tipo == _TipoPaso.nombre) {
      if (_nombreController.text.trim().isEmpty) {
        setState(() => _errorNombre = 'Ingresa tu nombre');
        return;
      }
      setState(() {
        _errorNombre = null;
        _paso += 1;
      });
      return;
    }

    if (tipo == _TipoPaso.correo) {
      final texto = _correoController.text.trim();
      final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
      if (!valido) {
        setState(() => _errorCorreo = 'Ingresa un correo válido');
        return;
      }
      if (_passwordController.text.length < 6) {
        setState(
          () =>
              _errorPassword = 'La contraseña debe tener al menos 6 caracteres',
        );
        return;
      }
      setState(() {
        _errorCorreo = null;
        _errorPassword = null;
        _paso += 1;
      });
      return;
    }

    if (tipo == _TipoPaso.oficios) {
      if (_oficiosSeleccionados.isEmpty) {
        setState(() => _mostrarErrorOficios = true);
        return;
      }
      setState(() {
        _mostrarErrorOficios = false;
        _paso += 1;
      });
      return;
    }

    // datosFinales: paso final, envía el formulario.
    final texto = _celularController.text.trim();
    if (!RegExp(r'^\d{7,15}$').hasMatch(texto)) {
      setState(() => _errorCelular = 'Ingresa solo números (7 a 15 dígitos)');
      return;
    }

    setState(() => _enviando = true);
    final provider = context.read<AppProvider>();
    final error = await provider.registrarConFirebase(
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      password: _passwordController.text,
      celular: texto,
      oficios: _esTrabajador ? _oficiosSeleccionados : null,
      fotoPath: _fotoPath,
      cedula: _cedulaController.text.trim().isEmpty
          ? null
          : _cedulaController.text.trim(),
      barrio: _barrioController.text.trim().isEmpty
          ? null
          : _barrioController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _irALogin() async {
    final autenticado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (autenticado == true) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = _pasos;
    final tipo = pasos[_paso];
    final esUltimoPaso = _paso == pasos.length - 1;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _atras,
        ),
        title: const Text('Crear tu cuenta'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_paso + 1) / pasos.length,
                  minHeight: 6,
                  // Antes un verde-menta residual del branding viejo, que
                  // ya chocaba con el celeste del relleno.
                  backgroundColor: Theme.of(context).dividerColor,
                  color: _acento,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(tipo),
                      child: _construirPaso(tipo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _enviando ? null : _siguiente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: esOscuro
                      ? Colors.white
                      : AppColors.negroProfundo,
                  foregroundColor: esOscuro
                      ? AppColors.negroProfundo
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _enviando
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: esOscuro
                              ? AppColors.negroProfundo
                              : Colors.white,
                        ),
                      )
                    : Icon(
                        esUltimoPaso ? Icons.check : Icons.arrow_forward,
                        size: 16,
                      ),
                label: Text(
                  esUltimoPaso ? 'Registrarme' : 'Continuar',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_paso > 0) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: _enviando ? null : _atras,
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Atrás', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                ),
              ],
              if (_paso == 0) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: _irALogin,
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(color: _acento),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirPaso(_TipoPaso tipo) {
    switch (tipo) {
      case _TipoPaso.nombre:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cómo te llamas?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuéntanos tu nombre completo para tu perfil.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              autofocus: true,
              decoration: _decoracion(
                'Nombre completo',
                null,
                error: _errorNombre,
              ),
              onChanged: (_) {
                if (_errorNombre != null) setState(() => _errorNombre = null);
              },
            ),
          ],
        );

      case _TipoPaso.correo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cuál es tu correo?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lo usaremos para verificar tu cuenta.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _correoController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoracion(
                'Correo electrónico',
                'assets/icon/correo.png',
                error: _errorCorreo,
              ),
              onChanged: (_) {
                if (_errorCorreo != null) setState(() => _errorCorreo = null);
              },
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _decoracion(
                'Contraseña',
                'assets/icon/contrasena.png',
                helper: 'Mínimo 6 caracteres',
                error: _errorPassword,
              ),
              onChanged: (_) {
                if (_errorPassword != null) {
                  setState(() => _errorPassword = null);
                }
              },
            ),
          ],
        );

      case _TipoPaso.oficios:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿En qué trabajas?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige uno o varios oficios que sepas hacer.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _servicios.map((servicio) {
                final seleccionado = _oficiosSeleccionados.contains(servicio);
                return FilterChip(
                  avatar: SizedBox(
                    width: 18,
                    height: 18,
                    child: Image.asset(
                      _iconosCategoria[servicio]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  label: Text(servicio),
                  selected: seleccionado,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _oficiosSeleccionados.add(servicio);
                      } else {
                        _oficiosSeleccionados.remove(servicio);
                      }
                      _mostrarErrorOficios = false;
                    });
                  },
                  selectedColor: _acento.withValues(alpha: 0.18),
                  checkmarkColor: _acento,
                  labelStyle: TextStyle(
                    color: seleccionado
                        ? _acento
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  side: BorderSide(
                    color: seleccionado
                        ? _acento
                        : Theme.of(context).dividerColor,
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                );
              }).toList(),
            ),
            if (_mostrarErrorOficios)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Selecciona al menos un servicio',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );

      case _TipoPaso.datosFinales:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ya casi terminamos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Así podrán ubicarte y contactarte cuando aplique a algo.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _elegirFoto,
                child: Stack(
                  children: [
                    Builder(
                      builder: (context) {
                        final nombre = _nombreController.text.trim();
                        final colorAvatar = colorAvatarPara(
                          nombre.isNotEmpty ? nombre : 'chambapp',
                        );
                        return CircleAvatar(
                          radius: 55,
                          backgroundColor: colorAvatar.fondo,
                          backgroundImage: proveedorFoto(_fotoPath),
                          child: _fotoPath != null
                              ? null
                              : Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colorAvatar.texto,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                  ),
                                ),
                        );
                      },
                    ),
                    if (_subiendoFoto)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.black38,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          // Blanco en vez del dorado de antes — el borde
                          // pasa a un gris suave porque un borde blanco
                          // sobre relleno blanco ya no se vería.
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppColors.negroProfundo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _fotoPath != null
                    ? 'Se ve mucho mejor con tu cara, ¡gracias!'
                    : 'Muestra tu rostro: da más confianza que un ícono',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _celularController,
              keyboardType: TextInputType.phone,
              decoration: _decoracion(
                'Número de celular',
                'assets/icon/telefono.png',
                helper: 'Para contactarte por WhatsApp. No es público.',
                error: _errorCelular,
              ),
              onChanged: (_) {
                if (_errorCelular != null) setState(() => _errorCelular = null);
              },
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _barrioController,
              decoration: _decoracion(
                'Barrio / zona (opcional)',
                'assets/icon/marcador_posicion.png',
                helper: 'Para mostrarte trabajos cerca de ti',
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              decoration: _decoracion(
                'Documento de identidad (opcional)',
                'assets/icon/documento_identidad.png',
                helper: 'Opcional. Sube tu documento más adelante para obtener la insignia de perfil verificado y generar más confianza.',
              ),
            ),
          ],
        );
    }
  }

  InputDecoration _decoracion(
    String label,
    String? iconoAsset, {
    IconData? icono,
    String? helper,
    String? error,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: error == null ? helper : null,
      helperMaxLines: 3,
      errorText: error,
      // Sin ícono en absoluto cuando no se provee ninguno de los dos (ej.
      // "Nombre completo") — antes quedaba un hueco vacío reservado para
      // un ícono que ya no está.
      prefixIcon: (iconoAsset == null && icono == null)
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: iconoAsset != null
                    ? Image.asset(iconoAsset, fit: BoxFit.contain)
                    : Icon(icono, size: 18, color: Colors.grey.shade600),
              ),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _acento, width: 1.5),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFB54834)),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFB54834), width: 1.5),
      ),
    );
  }
}
