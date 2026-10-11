import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _acento = AppColors.dorado;

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
              // Mismo contenido que la política del informe final
              // (Apéndice B): si cambia una, hay que cambiar la otra.
              _seccion(
                context,
                Icons.storefront_outlined,
                'Responsable',
                'CHAMBAPP, establecimiento de comercio con matrícula n.º 738403 de la Cámara de '
                    'Comercio de Bucaramanga, de propiedad de Kharol Juliana Calderón Barrera. '
                    'Correo de contacto: kharolcalderon@gmail.com.',
              ),
              _seccion(
                context,
                Icons.folder_shared_outlined,
                'Qué datos recogemos',
                'Tu nombre, correo electrónico, número de celular, barrio, tus oficios (si eres '
                    'trabajador), una foto de perfil opcional, el número y la foto de tu cédula (solo '
                    'si pides la verificación de identidad) y la ubicación de tu celular, solo si das '
                    'el permiso.',
              ),
              _seccion(
                context,
                Icons.fact_check_outlined,
                'Para qué los usamos',
                'Para crear tu cuenta, verificar tu identidad, mostrar tu perfil y tus calificaciones a '
                    'otros usuarios, ordenar las publicaciones por cercanía, permitir que un empleador '
                    'te contacte por WhatsApp si te selecciona y procesar los pagos de Visibilidad '
                    'Premium con Wompi, que maneja los datos de pago bajo su propia política.',
              ),
              _seccion(
                context,
                Icons.visibility_off_outlined,
                'Datos de acceso restringido',
                'La foto de tu cédula solo la revisa un administrador para darte la insignia de perfil '
                    'verificado. Tu celular no aparece en la app: solo se usa para abrir WhatsApp cuando '
                    'un empleador te selecciona. Tu ubicación solo se usa en tu celular para calcular '
                    'distancias y nunca se muestra; la de tus publicaciones se guarda aproximada '
                    '(unos 100 metros), sin tu dirección exacta.',
              ),
              _seccion(
                context,
                Icons.verified_user_outlined,
                'Tu autorización y tus derechos',
                'Al registrarte autorizas el uso de tus datos para estas finalidades, y puedes '
                    'retirar esa autorización cuando quieras. Puedes conocer, actualizar y corregir tus '
                    'datos, pedir que se borren y presentar quejas ante la Superintendencia de Industria '
                    'y Comercio. Desde Configuración puedes editar tu perfil o eliminar tu cuenta.',
              ),
              _seccion(
                context,
                Icons.mail_outline,
                'Consultas y reclamos',
                'Escríbenos al correo de contacto. Las consultas se responden en máximo diez días '
                    'hábiles y los reclamos en máximo quince, como dice la Ley 1581 de 2012.',
              ),
              _seccion(
                context,
                Icons.cloud_outlined,
                'Dónde se guardan',
                'Tus datos se guardan en Firebase (Google Cloud), con reglas que controlan qué puede '
                    'ver y modificar cada usuario, y las fotos se guardan en Cloudinary.',
              ),
              _seccion(
                context,
                Icons.gavel_outlined,
                'Marco legal',
                'Ley 1581 de 2012 (Habeas Data) y Decreto 1377 de 2013 de Colombia.',
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
