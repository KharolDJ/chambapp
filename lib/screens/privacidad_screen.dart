import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _acento = AppColors.azulCeleste;

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F5EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  size: 26,
                  color: _acento,
                ),
              ),
              const SizedBox(height: 20),
              _seccion(
                context,
                Icons.folder_shared_outlined,
                'Qué datos recogemos',
                'Tu nombre, correo electrónico, número de celular, tu oficio (si eres trabajador), '
                    'y tu ubicación aproximada — nunca exacta — para poder ordenar el feed por cercanía.',
              ),
              _seccion(
                context,
                Icons.fact_check_outlined,
                'Para qué los usamos',
                'Para verificar tu identidad, mostrar tu perfil a otros usuarios de la app, y permitir '
                    'que un empleador te contacte por WhatsApp si te selecciona para un trabajo.',
              ),
              _seccion(
                context,
                Icons.visibility_off_outlined,
                'Lo que nunca se muestra públicamente',
                'Tu número de celular nunca aparece visible para otras personas dentro de la app. Solo '
                    'se usa para abrir WhatsApp cuando un empleador te selecciona.',
              ),
              _seccion(
                context,
                Icons.gavel_outlined,
                'Marco legal',
                'El manejo de tus datos personales sigue los lineamientos de la Ley 1581 de 2012 '
                    '(Habeas Data) de Colombia.',
              ),
              _seccion(
                context,
                Icons.cloud_outlined,
                'Sobre esta versión (prototipo)',
                'Tus datos (perfil, publicaciones, calificaciones y notificaciones) se guardan en '
                    'Firebase, la plataforma en la nube de Google, y se sincronizan entre tus '
                    'dispositivos. Tu celular y tu cédula solo son visibles para ti y no se muestran '
                    'públicamente a otros usuarios.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(
    BuildContext context,
    IconData icono,
    String titulo,
    String texto,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: _acento),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _acento,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
