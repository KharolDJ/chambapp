# Chambapp — Funcionalidades actuales del prototipo

_Última actualización: 2026-09-01._ Este documento resume todo lo que la app hace hoy,
organizado por área. Sirve como referencia rápida y como insumo para la documentación
del trabajo de grado.

## 1. Roles y cuentas

- Al abrir la app por primera vez, se elige un rol: **Empleador** (busca un servicio) o
  **Trabajador** (ofrece un servicio).
- **No es obligatorio registrarse para explorar** — cualquiera puede ver el feed sin cuenta.
  El registro solo se pide la primera vez que se toca "Aplicar" (trabajador) o "+" para
  publicar (empleador), o desde el botón de acceso directo en el feed/perfil.
- **Iniciar sesión y registro son con Firebase Auth real** (correo + contraseña) — ya no
  hay login sin contraseña.
- El registro pide: nombre, correo, contraseña, celular, foto de perfil (opcional, cámara o
  galería), y — si el rol es trabajador — uno o **varios oficios** (selección múltiple con
  chips: una persona puede saber, por ejemplo, plomería y electricidad a la vez).
- **Verificación de correo:** al registrarse, Firebase envía un correo de verificación. Si no
  se confirma, la app muestra un aviso en el Perfil ("Reenviar correo" / "Ya verifiqué mi
  correo") y **bloquea "Aplicar" y "Publicar"** hasta que el correo quede verificado.
- El celular **nunca se muestra públicamente** — solo se usa para abrir WhatsApp cuando un
  empleador selecciona a ese trabajador.
- La sesión y el rol elegido se recuerdan entre aperturas de la app, así que no hay que
  volver a elegir rol ni iniciar sesión cada vez. "Cambiar de rol" (desde Perfil) alterna
  entre Empleador/Trabajador con la misma cuenta, **sin cerrar sesión**.

## 2. Feed principal ("Cerca de ti")

- Muestra publicaciones de empleadores buscando un servicio, en tarjetas resumidas (autor,
  barrio, distancia aproximada, hace cuánto, categoría, foto si tiene).
- **Geolocalización aproximada:** ordena el feed por cercanía real usando la ubicación del
  teléfono, sin mostrar nunca coordenadas exactas (solo "cerca de ti" o "a ~X km").
- **Filtro por categoría** (ícono de embudo) y **búsqueda por barrio/zona/descripción o por
  nombre de una persona** (ícono de lupa) — se pueden combinar entre sí.
- Al escribir un nombre que coincide con algún usuario registrado, aparece una franja
  **"PERSONAS"** arriba de las publicaciones (ver sección 3).
- Al filtrar por una categoría con trabajadores destacados, aparece una franja **"Podio de
  Recomendados"** arriba de las publicaciones (ver sección 10).
- **Radio de búsqueda configurable** (1 a 50 km, o "Sin límite") desde Configuración.
- Al tocar una tarjeta se abre el **detalle completo** de la publicación (descripción sin
  cortar, foto grande, etiquetas de "Urgente"/categoría, nombre del empleador tocable —
  ver sección 7), y ahí — solo si el rol es trabajador — aparece el botón **"Aplicar"**.
- Las publicaciones con Visibilidad Premium aprobada se destacan visualmente (fondo y borde
  distintos, ícono de estrella) y aparecen primero en el orden del feed.

## 3. Búsqueda de personas y perfil público

- La barra de búsqueda del feed también encuentra usuarios (empleadores o trabajadores) por
  nombre — requiere sesión iniciada (los datos completos de usuarios solo se sincronizan
  con cuenta activa, por privacidad).
- Al tocar un resultado, se abre su **perfil público de solo lectura**: foto, oficios (si
  aplica), calificación promedio, y el historial de calificaciones recibidas (reseñas).
- **No tiene botón de contacto** — a propósito, para no saltarse el flujo de
  aplicar/seleccionar de una publicación concreta.

## 4. Publicar una petición (empleador)

- Botón "+" central (solo visible para empleadores; requiere correo verificado — ver
  sección 1).
- Formulario: descripción, barrio, categoría, marcar como "Urgente", y **foto real**
  (tomar con la cámara o elegir de galería) de la situación.

## 5. Aplicar y seguimiento de la aplicación (trabajador)

- Botón "Aplicar" en el detalle de la publicación (requiere correo verificado — ver
  sección 1) — se puede quitar el interés volviendo a tocar, salvo que ya hayas sido
  seleccionado para ese trabajo.
- En la pestaña **Actividad → Mis intereses**, cada aplicación muestra en qué etapa va:
  **Aplicaste → El empleador vio tu perfil → Te contactará por WhatsApp** — o, si el
  empleador ya eligió a otra persona, un aviso claro de que ya no sigues en carrera.
- Aviso en la pestaña **Notificaciones** cuando cambia tu etapa (con un punto rojo en el
  ícono de la barra inferior).

## 6. Gestionar interesados y contactar (empleador)

- En **Actividad → Mis publicaciones**, cada publicación tiene un botón "Ver interesados
  (N)" que muestra la lista de personas interesadas, con su calificación.
- Al seleccionar a alguien, la app **abre WhatsApp directo con esa persona** (nunca se
  expone el número en pantalla).
- Botón "Marcar como finalizado" (solo disponible una vez se seleccionó a un trabajador).

## 7. Navegación al perfil del empleador desde una petición

- En el detalle de una petición, el nombre del empleador es tocable (con una flecha `›`
  al lado) y lleva a su perfil público — si no hay sesión, primero pide iniciar
  sesión/registrarse (mismo muro suave que "Aplicar").
- El perfil del empleador incluye una sección **"Publicaciones"**, con su historial
  separado en **Activas** y **Finalizadas**, para que el trabajador pueda evaluar si es un
  usuario legítimo antes de aplicar.

## 8. Calificaciones bidireccionales

- Una vez una publicación se marca como finalizada, tanto el empleador como el trabajador
  seleccionado pueden calificarse mutuamente (1 a 5 estrellas + comentario opcional).
- No se puede calificar dos veces la misma publicación (se reemplaza el botón por un aviso
  de "Ya calificaste").
- **Mis calificaciones** (desde Perfil) muestra el historial recibido, con promedio,
  cantidad, comentario, y **quién hizo cada calificación** (ya no es anónimo). También
  sirve de "reseñas" en el perfil público de cualquier usuario (sección 3).

## 9. Visibilidad Premium — empleador

- Desde una publicación propia, se puede solicitar destacarla por $10.000 (pago único),
  dejando una referencia del comprobante de pago.
- Queda "en revisión" hasta aprobarse (botón "Simular aprobación (demo)" porque todavía no
  hay pasarela de pagos real).
- Una vez aprobada, la publicación se resalta en el feed y aparece primero en el orden.
- No se puede solicitar sobre una publicación ya finalizada.

## 10. Visibilidad Premium — trabajador y Podio de Recomendados

- Desde Perfil (solo trabajadores con al menos un oficio), se puede solicitar Visibilidad
  Premium **por oficio** — $10.000, pago único, mismo flujo de comprobante + "Simular
  aprobación (demo)" que el empleador.
- Cada oficio tiene su propio **podio de 3 cupos**, con vigencia de 30 días desde la
  aprobación (sin renovación automática). Si los 3 cupos de un oficio están ocupados, la
  solicitud se bloquea con un aviso claro.
- El Podio se ve en el feed, arriba de las publicaciones, al filtrar por esa categoría —
  las 3 tarjetas se ven iguales entre sí, sin jerarquía visual (el orden es solo quién se
  aprobó primero, no un ranking por calidad).

## 11. Notificaciones

- Pestaña dedicada ("Avisos") con historial cronológico de eventos puntuales: alguien se
  interesó en tu publicación, el empleador vio tu perfil, te seleccionaron, te calificaron,
  se aprobó tu Visibilidad Premium.
- Contador de no leídas visible en el ícono de la barra inferior (para ambos roles).
- Se pueden eliminar notificaciones individuales.

## 12. Perfil

- Foto, nombre, rol, calificación promedio, oficios (si aplica).
- Si el correo no está verificado, aviso con "Reenviar correo" / "Ya verifiqué mi correo"
  (ver sección 1).
- Acceso a "Mis calificaciones", "Editar perfil" (incluye cambiar foto y oficios),
  "Visibilidad Premium" (solo trabajadores con oficio — sección 10), "Cambiar de rol"
  (vuelve al selector de rol sin cerrar sesión), y "Configuración".
- Administradores ven además una sección "Herramientas del equipo" con acceso al panel de
  Administración (reportes).

## 13. Configuración

- **Preferencias:** activar/desactivar notificaciones de actividad, radio de búsqueda del
  feed.
- **Cuenta:** Política de privacidad (resume qué datos se recogen y para qué, alineado con
  la Ley 1581 de 2012 — ya refleja que los datos se guardan en Firebase, no localmente),
  Cerrar sesión, Eliminar cuenta (con confirmación).

## 14. Identidad visual

- Paleta: petróleo `#0F6E56`, mostaza `#D9A441`/`#AD7A16`/`#FAEEDA`, ladrillo `#B54834`
  (etiqueta "Urgente"), papel `#FAF7F0` (fondo), grafito `#26312D` (texto).
- Tipografía: Sora (títulos) + Work Sans (cuerpo).

## 15. Estado técnico

- **Persistencia:** perfil, peticiones, calificaciones, notificaciones y solicitudes de
  Visibilidad Premium (empleador y trabajador) viven en **Firebase (Auth + Firestore)**,
  sincronizados en tiempo real. Ya no es almacenamiento solo local.
- Los datos sensibles (celular, cédula) solo se sincronizan a los dispositivos con sesión
  iniciada — la búsqueda de personas y los perfiles públicos requieren cuenta activa. Las
  peticiones, calificaciones y el Podio de Recomendados sí se ven sin sesión (no tienen
  datos sensibles).
- Datos de prueba disponibles: 7 usuarios de ejemplo (correos `carlos.r@example.com`,
  `rosa.t@example.com`, `maria.j@example.com`, `diego.f@example.com`, `laura.p@example.com`,
  `andres.m@example.com`, `sofia.o@example.com`, usados como semilla/respaldo local) y 7
  publicaciones de ejemplo cubriendo distintos estados, además de las cuentas reales creadas
  por registro.
- `flutter analyze`: 0 issues.

## 16. Pendiente / próximos pasos conocidos

- **Verificación de identidad/oficio del trabajador** ("perfiles verificados" — objetivo
  específico 3 del documento de tesis): hoy la cédula es autodeclarada, sin revisión. Falta
  construir comprobante (foto de cédula) + revisión manual, mismo patrón que Visibilidad
  Premium.
- Ícono de app y pantalla de bienvenida propios (branding).
- Generar el APK final de entrega (`flutter build apk`) — solo Android es realista sin Mac
  para compilar iOS.
- Pruebas automatizadas para el informe de pruebas del trabajo de grado.
- Rol de administrador por lista de correos hardcodeada (reforzada también en las reglas de
  Firestore) — no escala, es una decisión de alcance para prototipo.
- Reglas de Firestore no versionadas en el repositorio (solo viven en la consola de
  Firebase).
- Rediseño visual más adelante (incluye la idea pendiente de una animación/mascota).

## 17. Entregables de negocio (objetivos específicos 1, 2 y 4)

- **Modelo Canvas** — publicado como Artifact, con los 9 bloques y notas de consistencia
  con el código actual.
- **Proyección Financiera** a 12 meses (3 escenarios, gráfico interactivo) — publicada como
  Artifact.
- **Encuesta de validación de mercado** — cuestionario listo en
  `docs/encuesta-validacion-mercado.txt` para armar en Google Forms.
- Pendientes: aplicar la encuesta y redactar el Informe de Validación de Mercado y
  Tracción, y el Pitch Deck de Emprendimiento (se arma al final, resumiendo los anteriores).
