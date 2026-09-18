# Chambapp

Plataforma móvil de intermediación laboral para servicios técnicos y del hogar en Bucaramanga, Colombia. Conecta trabajadores informales (plomería, electricidad, cocina, limpieza, carpintería, albañilería, cerrajería, pintura, jardinería, acarreos) con hogares y vecinos de su misma comunidad que necesitan contratarlos.

## Funcionalidades principales

- **Perfiles verificados** — registro con cédula y foto, revisado por un administrador.
- **Geolocalización por proximidad** — el feed prioriza a los trabajadores más cercanos.
- **Calificaciones bidireccionales** — empleador y trabajador se califican mutuamente tras cada servicio.
- **Visibilidad Premium** — pago único para destacar una publicación o perfil durante 30 días.
- **Contacto directo** — sin chat interno; el contacto final ocurre por WhatsApp.

## Stack técnico

- **Flutter / Dart** — aplicación móvil multiplataforma (Android / iOS).
- **Firebase** — autenticación, base de datos en tiempo real (Firestore).
- **Geolocator** — cálculo de proximidad y ordenamiento del feed.
- **Provider** — gestión de estado.

## Cómo ejecutar el proyecto

```bash
flutter pub get
flutter run
```

Requiere un archivo de configuración de Firebase (`google-services.json` para Android, `GoogleService-Info.plist` para iOS) generado desde la consola de Firebase del proyecto.

## Estructura del proyecto

```
lib/
  models/       # Modelos de datos (Usuario, Peticion, Calificacion, etc.)
  providers/    # Gestión de estado y lógica de negocio
  screens/      # Pantallas de la aplicación
  services/     # Integraciones externas (pasarela de pago)
  theme/        # Paleta de colores y estilos
  widgets/      # Componentes reutilizables
```
