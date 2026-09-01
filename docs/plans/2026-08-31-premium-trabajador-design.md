# Diseño: Visibilidad Premium para trabajadores + Podio de Recomendados

_Fecha: 2026-08-31._ Diseño validado en conversación antes de implementar.

## Por qué esto es urgente (no es solo una idea pendiente)

El documento oficial de la Propuesta de Trabajo de Grado (página 19, sección "Gestión de
Recaudo") ya afirma por escrito: *"La aplicación integra un módulo para gestionar el
recaudo de los servicios de Visibilidad Premium... Desde la misma interfaz, **los
trabajadores** pueden solicitar estos beneficios y reportar su comprobante de pago."*
También nombra explícitamente un beneficio llamado **"Podio de Recomendados"** (página 19,
Principio de Justicia y Sostenibilidad). Hoy, en el código, **solo el empleador** puede
solicitar Premium (`premium_screen.dart` recibe una `Peticion`, que solo crea el
empleador) — nada de esto existe todavía para trabajadores. Como el documento ya lo
declara como si existiera, hay que construirlo antes de la sustentación.

Esta funcionalidad además es la **primera superficie real de descubrimiento de
trabajadores** en la app — hoy un trabajador solo se encuentra por búsqueda de nombre
(`feed_screen.dart`, franja "Personas") o dentro de la lista de interesados de una
publicación puntual (`interesados_screen.dart`). El Podio agrega una tercera vía, ligada
a categoría/oficio.

## Decisiones ya tomadas

1. **Alcance del Podio: por categoría/oficio, no global.** Cada uno de los 10 oficios
   tiene su propio podio de 3 cupos (hasta 30 cupos pagos posibles en total). Le da
   sentido comercial sin importar qué oficio busque el empleador, y evita que un solo
   trabajador (el mejor calificado en general) monopolice un único podio.
2. **Ubicación: arriba del feed al filtrar por categoría.** Reusa el filtro de categoría
   que ya existe en `feed_screen.dart` (`_categoriaFiltro`) — no se construye una pestaña
   nueva.
3. **Cupos llenos → se bloquea la solicitud.** Sin cola de espera ni promoción
   automática. Más simple, coherente con que hoy no hay pasarela de pagos real (todo es
   manual + "Simular aprobación (demo)").

## Precio, vigencia y a qué aplica

- **Precio:** $10.000, pago único con referencia de comprobante — mismo modelo que el
  empleador (`premium_screen.dart`), nada de suscripción recurrente (evita repetir la
  contradicción ya señalada en el Canvas: el documento dice "suscripciones" pero el
  producto real es pago único).
- **A qué aplica:** al perfil del trabajador **en un oficio específico**, no a una
  publicación (el trabajador no publica nada). Un trabajador con varios oficios puede
  pagar por separado en cada uno — cupos independientes, cada uno con su propio podio.
- **Vigencia:** 30 días desde la aprobación. Sin renovación automática.

## Impacto en el modelo financiero

Abre un segundo canal de ingresos con techo claro: hasta $300.000/mes adicionales (30
cupos × $10.000, asumiendo rotación completa cada 30 días), aparte de las publicaciones
destacadas del empleador. Debe reflejarse como línea aparte en la Proyección Financiera
(próximo entregable de negocio).

## Modelo de datos

**Nueva colección de Firestore: `premiumTrabajador`** (aparte de `usuarios` — no se
mezcla con el perfil, porque un trabajador puede tener Premium activo en varios oficios a
la vez, cada uno con su propia fecha de vencimiento):

```dart
class PremiumTrabajador {
  final String id;
  final String usuarioId;
  final String oficio;
  final bool solicitada;
  final bool aprobada;
  final String? comprobantePago;
  final DateTime solicitadaEn;
  final DateTime? expiraEn;   // aprobación + 30 días
}
```

**En `AppProvider`** (mismo patrón que `peticiones`/`calificaciones`/`notificaciones`/
`todosLosUsuarios`):

- `List<PremiumTrabajador> premiumTrabajadores` + `StreamSubscription`, escuchando
  `premiumTrabajador.snapshots()` **sin gateo de sesión** — a diferencia de
  `todosLosUsuarios`, no contiene celular ni cédula, así que puede verse sin cuenta
  (igual que el feed de publicaciones).
- `List<PremiumTrabajador> podioPara(String oficio)` → filtra `aprobada` +
  `expiraEn` en el futuro + `oficio` coincide, máximo 3, ordenados por quién se aprobó
  primero.
- `bool podioLleno(String oficio)` → `true` si ya hay 3 activos para ese oficio.
- `solicitarPremiumTrabajador(usuarioId, oficio, comprobante)` — crea el documento con
  `solicitada: true`.
- `aprobarPremiumTrabajadorDemo(id)` — **vuelve a chequear el cupo al momento de
  aprobar**, no solo al solicitar (evita que el botón de demo apruebe un 4to cupo si se
  usa fuera de orden).

Cero cambios a `Usuario`, `Peticion` ni al resto de `AppProvider` — aditivo puro.

## Pantalla del trabajador: `PremiumTrabajadorScreen`

**Entrada:** `ListTile` nuevo "Visibilidad Premium" en `PerfilScreen`, visible solo si
`rolActual == trabajador` y el usuario tiene al menos un oficio. Se ubica entre "Editar
perfil" y "Cambiar de modo".

**Una tarjeta por cada oficio del trabajador**, con su propio estado:

- **Activo:** ✓ verde + "Activa hasta [fecha]".
- **En revisión:** ⏳ + comprobante ingresado + botón "Simular aprobación (demo)" (mismo
  botón que ya existe en `premium_screen.dart`).
- **Sin nada activo ni pendiente, cupo lleno:** tarjeta gris deshabilitada: "Los 3 cupos
  de [oficio] están ocupados. Vuelve a intentar cuando se libere uno."
- **Sin nada activo ni pendiente, con cupo:** botón "Solicitar Visibilidad Premium
  ($10.000)".

Al tocar "Solicitar" se abre un **bottom sheet** pidiendo la referencia del comprobante
— mismo patrón visual que los filtros del feed (`_mostrarFiltro`, `_mostrarOrden` en
`feed_screen.dart`), no una pantalla nueva.

No se ofrece el botón de "Solicitar" si ya hay un registro activo o pendiente para ese
oficio — evita pagos duplicados por el mismo cupo.

## El Podio en el feed

**Dónde:** en `feed_screen.dart`, aparece cuando `_categoriaFiltro != null`. Se ubica
igual que la franja "Personas" ya construida (`_FranjaPersonas`) — antes del `Expanded`
con la lista de publicaciones. Si además hay una búsqueda de nombre activa, las dos
franjas conviven, cada una independiente.

**Cómo se ve:** encabezado "Podio de Recomendados — [Categoría]" + hasta 3 tarjetas en
fila horizontal deslizable, mismo estilo que las tarjetas de "Personas" (avatar, nombre,
calificación) con una insignia de estrella. Tocar una tarjeta abre su
`PerfilPublicoScreen` (ya construida).

**Decisión de diseño importante — nada de oro/plata/bronce:** las 3 tarjetas se ven
**exactamente iguales** entre sí, sin jerarquía visual. El orden es simplemente quién se
aprobó primero, no un ranking por calidad — todos pagan lo mismo por el mismo beneficio.
Un tratamiento visual de 1°/2°/3° insinuaría una recomendación de calidad que no
corresponde a lo que se está vendiendo, y abriría una pregunta incómoda en la
sustentación ("¿por qué este va primero, es el mejor calificado?").

**Si no hay nadie con Premium activo en esa categoría:** la franja no aparece — sin
estado vacío ni espacio en blanco, igual que la franja de "Personas" sin coincidencias.

## Casos borde

- **Sin tarea de fondo para vencidos:** `expiraEn` se compara contra `DateTime.now()`
  cada vez que se calcula el podio o el estado en pantalla. No hay job programado que
  limpie documentos vencidos — quedan en Firestore con `aprobada: true` para siempre,
  simplemente dejan de contar. Mismo estilo que el resto de la app.
- **Doble chequeo de cupo:** al solicitar (bloquea si ya está lleno) y al aprobar (por si
  se aprueban solicitudes fuera de orden).
- **Si el trabajador quita ese oficio en "Editar perfil" mientras tiene Premium activo
  ahí:** el registro sigue existiendo y sigue contando en el podio de ese oficio hasta
  vencer — ya no aparece en su propia pantalla de Premium (porque el oficio salió de su
  lista), pero tampoco se le quita el cupo pagado. Caso raro, aceptado — mismo tipo de
  trade-off que el snapshot desactualizado de interesados en una petición
  (`peticion.dart:45-51`).

## Validado en dispositivo real (2026-09-01)

Probado en un Moto G72 (Android 13) con `flutter run`. Al principio las escrituras a
`premiumTrabajador` fallaban con `PERMISSION_DENIED` porque la colección no tenía reglas
en la consola de Firebase. Se agregó:

```
match /premiumTrabajador/{id} {
  allow read: if true;
  allow create, update: if request.auth != null;
  allow delete: if false;
}
```

Mismo patrón que ya usan `peticiones` y `calificaciones` (lectura pública, escritura solo
autenticada, sin borrado). Tras publicar la regla, el flujo completo (solicitar → "Simular
aprobación (demo)" → aparecer en el Podio al filtrar por categoría) funcionó de punta a
punta en el dispositivo.
