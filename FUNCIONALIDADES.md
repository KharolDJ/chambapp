# Chambapp — Funcionalidades actuales del prototipo

_Última actualización: 2026-08-26._ Este documento resume todo lo que la app hace hoy,
organizado por área. Sirve como referencia rápida y como insumo para la documentación
del trabajo de grado.

## 1. Roles y cuentas

- Al abrir la app por primera vez, se elige un rol: **Empleador** (busca un servicio) o
  **Trabajador** (ofrece un servicio).
- **No es obligatorio registrarse para explorar** — cualquiera puede ver el feed sin cuenta.
  El registro solo se pide la primera vez que se toca "Aplicar" (trabajador) o "+" para
  publicar (empleador), o desde el botón de acceso directo en el feed/perfil.
- **Iniciar sesión** es solo por correo electrónico (sin contraseña por ahora — se
  reemplaza por Firebase Auth más adelante). Si el correo ya existe, entra directo; si no,
  ofrece registrarse con ese mismo correo ya escrito.
- El registro pide: nombre, correo, celular, foto de perfil (opcional, cámara o galería), y
  — si el rol es trabajador — uno o **varios oficios** (selección múltiple con chips: una
  persona puede saber, por ejemplo, plomería y electricidad a la vez).
- El celular **nunca se muestra públicamente** — solo se usa para abrir WhatsApp cuando un
  empleador selecciona a ese trabajador.
- La sesión y el rol elegido se recuerdan entre aperturas de la app (guardado local en el
  teléfono), así que no hay que volver a elegir rol ni iniciar sesión cada vez.

## 2. Feed principal ("Cerca de ti")

- Muestra publicaciones de empleadores buscando un servicio, en tarjetas resumidas (autor,
  barrio, distancia aproximada, hace cuánto, categoría, foto si tiene).
- **Geolocalización aproximada:** ordena el feed por cercanía real usando la ubicación del
  teléfono, sin mostrar nunca coordenadas exactas (solo "cerca de ti" o "a ~X km").
- **Filtro por categoría** (ícono de embudo) y **búsqueda por barrio/zona/descripción**
  (ícono de lupa, estilo Computrabajo) — se pueden combinar los dos a la vez.
- **Radio de búsqueda configurable** (1 a 50 km, o "Sin límite") desde Configuración —
  filtra qué tan lejos se muestran publicaciones.
- Al tocar una tarjeta se abre el **detalle completo** de la publicación (descripción sin
  cortar, foto grande, etiquetas de "Urgente"/categoría), y ahí — solo si el rol es
  trabajador — aparece el botón **"Aplicar"**.
- Las publicaciones con Visibilidad Premium aprobada se destacan visualmente (fondo y borde
  distintos, ícono de estrella).

## 3. Publicar una petición (empleador)

- Botón "+" central (solo visible para empleadores).
- Formulario: descripción, barrio, categoría, marcar como "Urgente", y **foto real**
  (tomar con la cámara o elegir de galería) de la situación.

## 4. Aplicar y seguimiento de la aplicación (trabajador)

- Botón "Aplicar" en el detalle de la publicación (antes "Me interesa") — se puede quitar
  el interés volviendo a tocar, salvo que ya hayas sido seleccionado para ese trabajo.
- En la pestaña **Actividad → Mis intereses**, cada aplicación muestra en qué etapa va:
  **Aplicaste → El empleador vio tu perfil → Te contactará por WhatsApp** — o, si el
  empleador ya eligió a otra persona, un aviso claro de que ya no sigues en carrera.
- Aviso en la pestaña **Notificaciones** cuando cambia tu etapa (con un punto rojo en el
  ícono de la barra inferior).

## 5. Gestionar interesados y contactar (empleador)

- En **Actividad → Mis publicaciones**, cada publicación tiene un botón "Ver interesados
  (N)" que muestra la lista de personas interesadas, con su calificación.
- Al seleccionar a alguien, la app **abre WhatsApp directo con esa persona** (nunca se
  expone el número en pantalla).
- Botón "Marcar como finalizado" (solo disponible una vez se seleccionó a un trabajador).

## 6. Calificaciones bidireccionales

- Una vez una publicación se marca como finalizada, tanto el empleador como el trabajador
  seleccionado pueden calificarse mutuamente (1 a 5 estrellas + comentario opcional).
- No se puede calificar dos veces la misma publicación (se reemplaza el botón por un aviso
  de "Ya calificaste").
- **Mis calificaciones** (desde Perfil) muestra el historial recibido, con promedio,
  cantidad, comentario, y **quién hizo cada calificación** (ya no es anónimo).

## 7. Visibilidad Premium

- Desde una publicación propia (empleador), se puede solicitar destacarla por $10.000,
  dejando una referencia del comprobante de pago.
- Queda "en revisión" hasta aprobarse (hay un botón de "Simular aprobación (demo)" porque
  todavía no hay pasarela de pagos real — es solo para poder demostrar el efecto visual).
- Una vez aprobada, la publicación se resalta en el feed.
- No se puede solicitar sobre una publicación ya finalizada.

## 8. Notificaciones

- Pestaña dedicada ("Avisos") con historial cronológico de eventos puntuales: alguien se
  interesó en tu publicación, el empleador vio tu perfil, te seleccionaron, te calificaron,
  se aprobó tu Visibilidad Premium.
- Contador de no leídas visible en el ícono de la barra inferior (para ambos roles).
- Se pueden eliminar notificaciones individuales.

## 9. Perfil

- Foto, nombre, rol, calificación promedio, oficios (si aplica).
- Acceso a "Mis calificaciones", "Editar perfil" (incluye cambiar foto y oficios),
  "Cambiar de rol" (cierra sesión y vuelve al selector de rol), y "Configuración".

## 10. Configuración

- **Preferencias:** activar/desactivar notificaciones de actividad, radio de búsqueda del
  feed.
- **Cuenta:** Política de privacidad (resume qué datos se recogen y para qué, alineado con
  la Ley 1581 de 2012), Cerrar sesión, Eliminar cuenta (con confirmación).

## 11. Identidad visual

- Paleta: petróleo `#0F6E56`, mostaza `#D9A441`/`#AD7A16`/`#FAEEDA`, ladrillo `#B54834`
  (etiqueta "Urgente"), papel `#FAF7F0` (fondo), grafito `#26312D` (texto).
- Tipografía: Sora (títulos) + Work Sans (cuerpo).

## 12. Estado técnico

- **Persistencia:** por ahora todo se guarda localmente en el dispositivo (no en la nube)
  — sobrevive a cerrar/reabrir la app, pero es exclusivo de cada teléfono.
- **Firebase:** proyecto creado y conectado a nivel de configuración (Auth por correo y
  Firestore activados en la consola); la migración del código de `AppProvider` para usar
  Firebase de verdad en vez del almacenamiento local **todavía está pendiente** (Fase B).
- Datos de prueba disponibles: 7 usuarios de ejemplo (correos `carlos.r@example.com`,
  `rosa.t@example.com`, `maria.j@example.com`, `diego.f@example.com`, `laura.p@example.com`,
  `andres.m@example.com`, `sofia.o@example.com` — login solo con el correo, sin contraseña)
  y 7 publicaciones de ejemplo cubriendo distintos estados.

## 13. Pendiente / próximos pasos conocidos

- Migrar `AppProvider` de `shared_preferences` a Firebase Auth + Firestore (Fase B).
- Ícono de app y pantalla de bienvenida propios (branding).
- Generar el APK final de entrega (`flutter build apk`).
- Pruebas automatizadas para el informe de pruebas del trabajo de grado.
- Rediseño visual más adelante (incluye la idea pendiente de una animación/mascota).
