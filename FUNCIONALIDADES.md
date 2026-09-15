# Chambapp — Funcionalidades actuales del prototipo

_Última actualización: 2026-09-12._ Este documento resume todo lo que la app hace hoy,
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
  galería), **barrio/zona de residencia** (opcional, texto libre — agregado 2026-09-14 para dar
  contexto de proximidad; se dejó como texto libre a propósito, igual que el campo barrio de una
  publicación, para no tener dos formatos distintos de "barrio" en la misma app), y — si el rol
  es trabajador — uno o **varios oficios** (selección múltiple con chips: una persona puede
  saber, por ejemplo, plomería y electricidad a la vez).
- **Verificación de correo:** al registrarse, Firebase envía un correo de verificación. Si no
  se confirma, la app muestra un aviso en el Perfil ("Reenviar correo" / "Ya verifiqué mi
  correo") y **bloquea "Aplicar" y "Publicar"** hasta que el correo quede verificado.
- El celular **nunca se muestra públicamente** — solo se usa para abrir WhatsApp cuando un
  empleador selecciona a ese trabajador.
- La sesión y el rol elegido se recuerdan entre aperturas de la app, así que no hay que
  volver a elegir rol ni iniciar sesión cada vez. "Cambiar de rol" (desde Perfil) alterna
  entre Empleador/Trabajador con la misma cuenta, **sin cerrar sesión**.

## 2. Feed principal ("Cerca de ti")

- Cada publicación es una tarjeta blanca con sombra suave (esquinas redondeadas), separadas por
  margen entre sí — **no** un timeline continuo (se probó ese estilo el 2026-09-13 y se revirtió
  a pedido explícito). Actualizado 2026-09-14: se eliminaron los badges flotantes en las esquinas
  (chocaban con el borde dorado animado de Premium); ahora "Oferta destacada" (si tiene
  Visibilidad Premium aprobada) y/o "Se precisa urgentemente" (si es urgente) aparecen como texto
  simple en flujo normal, arriba del encabezado — sin recuadros ni superposición con los bordes.
  Encabezado: avatar + nombre, con la calificación en estrellas y la insignia de "Perfil
  verificado" (si aplica) en la misma línea junto al nombre, y barrio/distancia/tiempo
  transcurrido como subtítulo debajo. Foto (si tiene) con esquinas redondeadas. Categoría como
  etiqueta en la parte inferior.
- **Geolocalización aproximada:** ordena el feed por cercanía real usando la ubicación del
  teléfono, sin mostrar nunca coordenadas exactas (solo "cerca de ti" o "a ~X km").
- **Filtro por categoría** (ícono de embudo) y **búsqueda por barrio/zona/descripción o por
  nombre de una persona** (ícono de lupa) — se pueden combinar entre sí.
- Al escribir un nombre que coincide con algún usuario registrado, aparece una franja
  **"PERSONAS"** arriba de las publicaciones (ver sección 3).
- Al filtrar por una categoría con trabajadores destacados, aparece una franja **"Podio de
  Recomendados"** arriba de las publicaciones (ver sección 10).
- **Radio de búsqueda configurable** (1 a 50 km, o "Sin límite") desde Configuración.
- Al tocar una publicación se abre el **detalle completo** (descripción sin cortar, foto
  grande, etiquetas de "Urgente"/categoría, nombre del empleador tocable — ver sección 7), y
  ahí — solo si el rol es trabajador — aparece el botón **"Aplicar"**.
- Las publicaciones con Visibilidad Premium aprobada conservan su bloque distintivo (fondo y
  borde dorado animado, ícono de estrella, con un margen pequeño para no romper la sensación de
  timeline continuo) y aparecen primero en el orden del feed. Las tarjetas también se
  escalan suavemente según su posición en el scroll (más grandes cerca del centro del
  viewport).
- **Tema oscuro:** la app sigue el modo del sistema operativo (`ThemeMode.system`); todos los
  colores del feed (fondo, texto, divisores, chips de filtro) se adaptan automáticamente.

## 3. Búsqueda de personas y perfil público

- La barra de búsqueda del feed también encuentra usuarios (empleadores o trabajadores) por
  nombre — requiere sesión iniciada (los datos completos de usuarios solo se sincronizan
  con cuenta activa, por privacidad).
- Al tocar un resultado, se abre su **perfil público de solo lectura**: foto, oficios (si
  aplica), calificación promedio, y el historial de calificaciones recibidas (reseñas).
- **No tiene botón de contacto directo** (nunca expone el celular) — a propósito, para no
  saltarse el flujo de aplicar/seleccionar de una publicación concreta.
- **"Invitar a mi publicación"** (agregado 2026-09-14): si quien mira el perfil es empleador y
  tiene al menos una publicación propia abierta, puede invitar a ese trabajador — le llega una
  notificación con enlace directo a la publicación. No lo agrega a "interesados" ni abre
  WhatsApp: el trabajador debe entrar y tocar "Aplicar" como siempre. Pensado principalmente
  para invitar a alguien visto en el Podio de Recomendados (sección 10), que hoy no tenía
  ninguna forma de ser contactado desde ahí.

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
- **Rotación estilo Airbnb/Mercado Pago** (cambiado 2026-09-14 — antes eran 3 cupos fijos por
  30 días para las mismas 3 personas, lo cual dejaba al 4º+ trabajador sin ninguna posibilidad
  real de aparecer). Ahora cada oficio admite hasta **10 "VIP" activos** a la vez (con vigencia
  de 30 días desde la aprobación, sin renovación automática), y el Podio muestra **3 al azar**
  entre todos los VIP activos de ese oficio en cada carga — la terna se recalcula cada 15
  minutos (no en cada refresco de pantalla, para no "parpadear"), así que a lo largo del día
  todos los que pagaron reciben exposición real, no solo los 3 primeros que se aprobaron. Si
  los 10 cupos VIP de un oficio están ocupados, la solicitud se bloquea con un aviso claro.
- El Podio se ve en el feed, arriba de las publicaciones, al filtrar por esa categoría — las 3
  tarjetas mostradas se ven iguales entre sí, sin jerarquía visual (el orden dentro de la terna
  es aleatorio, no un ranking por calidad).

## 11. Perfil Verificado (identidad)

- Desde Perfil (solo trabajadores), se puede solicitar la verificación de identidad: número de
  cédula + **foto real de la cédula** (cámara o galería).
- Queda "en revisión" hasta aprobarse (botón "Simular aprobación (demo)", mismo patrón que
  Visibilidad Premium — todavía no hay revisión manual real de un administrador).
- Una vez aprobada, el perfil muestra la insignia **"Perfil verificado"** (ícono de check) tanto
  en el perfil propio como en el perfil público que ven los empleadores — es la señal de
  confianza que responde al objetivo específico 3 de la tesis ("perfiles verificados"), más allá
  de la sola verificación de correo.
- **Alcance actual: solo cédula.** La verificación del oficio declarado (ej. comprobante de que
  de verdad sabe plomería) queda pendiente para una fase posterior.
- La foto de la cédula se guarda en una colección aparte (`verificacionesIdentidad`), no en el
  documento del usuario, para no exponerla en el directorio de usuarios que alimenta la búsqueda
  de personas.

## 12. Notificaciones

- Pestaña dedicada ("Avisos") con historial cronológico de eventos puntuales: alguien se
  interesó en tu publicación, el empleador vio tu perfil, te seleccionaron, te calificaron,
  se aprobó tu Visibilidad Premium.
- Contador de no leídas visible en el ícono de la barra inferior (para ambos roles).
- Se pueden eliminar notificaciones individuales.

## 13. Perfil

- Foto, nombre, rol, calificación promedio, barrio/zona (si lo llenó — también visible en el
  perfil público que ven otros usuarios, sección 3), oficios (si aplica).
- Si el correo no está verificado, aviso con "Reenviar correo" / "Ya verifiqué mi correo"
  (ver sección 1).
- Acceso a "Mis calificaciones", "Editar perfil" (incluye cambiar foto, barrio y oficios),
  "Visibilidad Premium" (solo trabajadores con oficio — sección 10), "Cambiar de rol"
  (vuelve al selector de rol sin cerrar sesión), y "Configuración".
- Administradores ven además una sección "Herramientas del equipo" con acceso al panel de
  Administración (reportes).

## 14. Configuración

- **Apariencia:** selector de tema Claro/Oscuro/Automático (agregado 2026-09-14), guardado en
  el dispositivo — "Automático" sigue el modo del sistema operativo, igual que el
  comportamiento por defecto antes de que existiera este selector.
- **Preferencias:** activar/desactivar notificaciones de actividad, radio de búsqueda del
  feed.
- **Cuenta:** Política de privacidad (resume qué datos se recogen y para qué, alineado con
  la Ley 1581 de 2012 — ya refleja que los datos se guardan en Firebase, no localmente),
  Cerrar sesión, Eliminar cuenta (con confirmación).

## 15. Identidad visual

- Paleta: **azul celeste `#0284C7`** (claro) / `#38BDF8` (oscuro) — color de marca, antes
  petróleo `#0F6E56` (cambiado 2026-09-14, ver `lib/theme/app_colors.dart` — único lugar donde
  se define, todas las pantallas lo importan de ahí en vez de repetir el hex), mostaza
  `#D9A441`/`#AD7A16`/`#FAEEDA`, ladrillo `#B54834` (etiqueta "Urgente"), papel `#FAF7F0`
  (fondo), grafito `#26312D` (texto). La primera entrada de la paleta de avatares (menta/verde
  `#0F6E56`) se dejó igual a propósito — es solo una de 8 variantes de color para distinguir
  avatares, no el acento interactivo de marca.
- Tipografía: Sora (títulos) + Work Sans (cuerpo).
- **Tema oscuro** (reimplementado 2026-09-14; hubo un primer intento el 2026-09-13 que se
  revirtió junto con el rediseño de timeline de esa sesión). Selector manual Claro/Oscuro/
  Automático en Configuración (sección 14) — "Automático" usa `ThemeMode.system`. Fondo
  `#121417`, superficies `#1B1F22`, texto `#F2F3F5`/`#9AA3AB` (secundario), divisores `#2A2E33`,
  acento verde aclarado `#2BB893`
  (en vez del petróleo `#0F6E56` del claro, para mantener buen contraste).
- **El fondo dorado deslizante de Visibilidad Premium (`fondoDoradoDeslizante`) también se
  adapta**: en claro sigue siendo crema/pergamino pálido; en oscuro pasa a un bronce casi negro
  (`#1B1509`→`#4A3712`) para no verse como un parche blanco fuera de lugar sobre el resto de la
  app en negro. El texto sobre las tarjetas Premium (nombre, descripción, "Activa hasta...", "Ver
  interesados") también cambia de par de colores según el tema — antes era un café fijo pensado
  solo para fondo claro. Aplica tanto a las publicaciones destacadas del feed
  (`peticion_card.dart`) como a las tarjetas de oficio en Visibilidad Premium
  (`premium_trabajador_screen.dart`).
- **Alcance del tema oscuro:** cubre toda la app (agregado 2026-09-14) — feed, tarjetas de
  publicación, Visibilidad Premium (trabajador y empleador), Configuración, Actividad, Avisos,
  Perfil, registro, login, editar perfil, perfil público, detalle de publicación, interesados,
  calificar, mis calificaciones, verificación de identidad, publicar, reportar, selector de rol,
  administración y política de privacidad.

## 16. Estado técnico

- **Persistencia:** perfil, peticiones, calificaciones, notificaciones, solicitudes de
  Visibilidad Premium (empleador y trabajador) y solicitudes de Perfil Verificado viven en
  **Firebase (Auth + Firestore)**, sincronizados en tiempo real. Ya no es almacenamiento solo
  local.
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

## 17. Pendiente / próximos pasos conocidos

- **Verificación del oficio del trabajador** (objetivo específico 3 del documento de tesis,
  parte de "perfiles verificados"): la verificación de identidad por cédula ya está
  implementada (sección 11), pero falta comprobar que el trabajador de verdad sabe el oficio que
  declaró (ej. certificado, evaluación práctica) — queda para una fase posterior.
- Ícono de app y pantalla de bienvenida propios (branding).
- Generar el APK final de entrega (`flutter build apk`) — solo Android es realista sin Mac
  para compilar iOS.
- Pruebas automatizadas para el informe de pruebas del trabajo de grado.
- Rol de administrador por lista de correos hardcodeada (reforzada también en las reglas de
  Firestore) — no escala, es una decisión de alcance para prototipo.
- Reglas de Firestore no versionadas en el repositorio (solo viven en la consola de
  Firebase).
- Rediseño visual más adelante (incluye la idea pendiente de una animación/mascota).

## 18. Entregables de negocio (objetivos específicos 1, 2 y 4)

- **Modelo Canvas** — publicado como Artifact, con los 9 bloques y notas de consistencia
  con el código actual.
- **Proyección Financiera** a 12 meses (3 escenarios, gráfico interactivo) — publicada como
  Artifact.
- **Encuesta de validación de mercado** — cuestionario listo en
  `docs/encuesta-validacion-mercado.txt` para armar en Google Forms.
- Pendientes: aplicar la encuesta y redactar el Informe de Validación de Mercado y
  Tracción, y el Pitch Deck de Emprendimiento (se arma al final, resumiendo los anteriores).
