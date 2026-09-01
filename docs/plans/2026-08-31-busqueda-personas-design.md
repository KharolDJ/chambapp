# Diseño: Búsqueda de personas por nombre + perfil público

_Fecha: 2026-08-31. Implementado el mismo día — ver "Nota de implementación" al final._
Diseño validado en conversación antes de implementar. Objetivo: que la barra de
búsqueda del feed también encuentre trabajadores/empleadores por nombre, y que al
tocar un resultado se abra su perfil público de solo lectura.

## Contexto

Hoy la búsqueda del feed (`feed_screen.dart:213-220`) solo filtra `Peticion`s por
barrio, descripción y categoría. No existe ninguna forma de buscar a una persona
por su nombre, ni una pantalla que muestre el perfil de alguien más allá del propio
usuario logueado (`PerfilScreen` está codificada para `provider.usuarioActual`,
`perfil_screen.dart:19`).

## Decisión funcional: sin contacto directo

El perfil público es **solo lectura** (foto, oficios, calificación promedio,
historial de calificaciones recibidas). No incluye botón de WhatsApp ni celular.

**Por qué:** el contacto hoy solo se habilita cuando el empleador *selecciona* a un
trabajador desde una publicación concreta (`interesados_screen.dart:27-41`), lo cual
alimenta notificaciones, `trabajadorSeleccionadoId` y la calificación bidireccional.
Un botón de contacto en el perfil de búsqueda saltaría ese flujo y perdería ese
registro. El valor del perfil público es **verificar reputación antes de
comprometerse** (ej. un empleador que ya conoce a alguien por referencia, o un
trabajador que quiere ver el historial de un empleador antes de aplicar) — no
reemplazar el flujo de contacto existente.

## Arquitectura

Tres piezas aditivas, sin tocar lógica existente:

### 1. `AppProvider`: lista viva de todos los usuarios

Hoy `usuarios` en `AppProvider` (`app_provider.dart:55`) son solo los 7 usuarios de
demo/siembra — no todos los usuarios reales. Se agrega un listener nuevo, mismo
patrón que `peticiones`/`calificaciones`/`notificaciones` (`app_provider.dart:328-342`):

```dart
final List<Usuario> todosLosUsuarios = [];
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionUsuarios;

// dentro de iniciarEscuchaFirestore():
await _suscripcionUsuarios?.cancel();
_suscripcionUsuarios = _db.collection('usuarios').snapshots().listen((snapshot) {
  todosLosUsuarios
    ..clear()
    ..addAll(snapshot.docs.map((doc) => Usuario.fromJson(doc.data())));
  notifyListeners();
});

// en dispose():
_suscripcionUsuarios?.cancel();
```

Getter de búsqueda (excluye al usuario actual de sus propios resultados):

```dart
List<Usuario> buscarUsuariosPorNombre(String termino) {
  final t = termino.trim().toLowerCase();
  if (t.isEmpty) return const [];
  return todosLosUsuarios
      .where((u) => u.id != usuarioActual?.id && u.nombre.toLowerCase().contains(t))
      .toList();
}
```

**Efecto secundario positivo (no es el objetivo, opcional arreglar de paso):**
`mis_calificaciones_screen.dart:72` resuelve el nombre de quien calificó buscando en
`provider.usuarios` (los 7 de demo), así que calificaciones de usuarios reales no-demo
se muestran como "Usuario eliminado". Con `todosLosUsuarios` disponible, ese lookup
se puede apuntar a la lista correcta.

### 2. `PerfilPublicoScreen(usuarioId)` — pantalla nueva

Reusa el layout visual de `PerfilScreen`, sin las acciones de dueño (editar, cambiar
rol, contacto):

```
PerfilPublicoScreen(usuarioId)
├── Busca en provider.todosLosUsuarios (fallback a .get() si aún no sincronizó)
├── CircleAvatar — con guard File(fotoPath).existsSync() antes de usar FileImage
├── Nombre + rol
├── Calificación promedio / "Nuevo en la plataforma"
├── Oficios (si aplica)
└── Lista de calificaciones recibidas (mismo estilo que mis_calificaciones_screen.dart,
    filtrando provider.calificaciones por paraUsuarioId == usuarioId)
```

**Hallazgo técnico:** las fotos de perfil se guardan como ruta de archivo local
(`editar_perfil_screen.dart:76-78`, `ImagePicker` sin subir a Storage) — nunca subidas
a la nube. Al ver el perfil de otra persona desde tu dispositivo, su `fotoPath` no
existe localmente. Sin el guard de `existsSync()`, `FileImage` fallaría en silencio y
se vería roto. Con el guard, cae limpio al ícono por defecto.

**Caso borde:** si el usuario no aparece en `todosLosUsuarios` ni en Firestore
(cuenta eliminada), se muestra un estado vacío: "Este usuario ya no está disponible".

### 3. Franja "Personas" en el feed

En `feed_screen.dart`, lista paralela a la de peticiones:

```dart
final personasEncontradas = _busqueda.trim().isEmpty
    ? const <Usuario>[]
    : provider.buscarUsuariosPorNombre(_busqueda);
```

Se muestra como franja horizontal deslizable, entre los chips de filtro y la lista de
publicaciones (antes del `Expanded` en `feed_screen.dart:354`), visible solo si
`personasEncontradas.isNotEmpty`. Tarjeta compacta (avatar + nombre + calificación) →
tap → `PerfilPublicoScreen(usuarioId: u.id)`.

**Por qué franja aparte y no mezclado en el mismo `ListView`:** el `ListView.builder`
actual (`feed_screen.dart:385-392`) itera solo `Peticion` y alimenta el `sort()` por
premium/urgente/cercanía (líneas 234-250). Mezclar tipos ahí obligaría a un
`itemBuilder` condicional más complejo, con riesgo de romper ese ordenamiento. Una
franja aparte es puramente aditiva.

## Riesgo de privacidad (el hallazgo más importante)

`usuarios.snapshots()` trae el documento **completo** de cada usuario, incluyendo
`celular` y `cedula` (`usuario.dart:24-34`), no solo el nombre. Hoy esos campos ya son
legibles individualmente por id (`app_provider.dart:269`), pero sincronizar la
colección completa los deja disponibles en bloque, para cualquiera que abra la app —
aunque la UI no los muestre en pantalla. Dado que `FUNCIONALIDADES.md` §10 ya declara
cumplimiento de la Ley 1581 de 2012, esto merece atención real, no es cosmético.

**Recomendación:** exigir sesión iniciada para usar el buscador de personas, mismo
patrón de muro suave que ya existe para "Aplicar" o publicar (`FUNCIONALIDADES.md`
§1). Además, revisar en la consola de Firebase si las reglas de `usuarios` deberían
restringir lectura de colección completa vs. documento individual — eso es
configuración de Firebase, no código Flutter, y hay que validarlo contra el proyecto
real antes de dar por cerrada la funcionalidad.

## Otros casos borde

- Sin conexión / reglas bloquean la consulta → `todosLosUsuarios` queda vacío, la
  búsqueda de personas no devuelve nada (degradación silenciosa, igual que el feed).
- Nombres duplicados → sin ambigüedad real, la navegación usa `usuarioId`.
- Buscarse a sí mismo → excluido por el getter.

## Plan de pruebas (manual — no hay suite automatizada todavía)

1. `flutter analyze` limpio tras los cambios (hoy: 0 issues).
2. Buscar nombre existente → aparece franja "Personas" → tap → abre el perfil correcto.
3. Buscar nombre inexistente → sin franja, sin error en consola.
4. Borrar búsqueda → franja desaparece.
5. Perfil sin calificaciones → "Nuevo en la plataforma".
6. Perfil con foto tomada en otro dispositivo → cae a ícono por defecto, sin romper.
7. Buscarse a uno mismo → no aparece en resultados.
8. Perfil de cuenta eliminada tras aparecer en resultados → estado vacío, sin crash.
9. Buscar personas sin sesión iniciada (si se agrega el muro) → pide login.
10. Confirmar en consola de Firebase que las reglas permiten `usuarios.snapshots()`.

## Estimado de esfuerzo

| Pieza | Esfuerzo |
|---|---|
| Listener `todosLosUsuarios` + getter de búsqueda | ~30 min |
| `PerfilPublicoScreen` | ~1-1.5 h |
| Franja "Personas" en el feed | ~45 min |
| Verificar/ajustar reglas de Firestore | Variable (10 min+) |
| Pruebas manuales | ~45 min |
| **Total** | **~3-4 horas** |

Mejora contenida: tres piezas aditivas, cero cambios a lógica existente. El mayor
riesgo es de configuración de Firestore, no de código.

## Nota de implementación (cambio respecto al plan original)

El plan original sincronizaba `usuarios.snapshots()` sin condición, dentro de
`iniciarEscuchaFirestore()` (que corre en cada apertura de la app, con o sin sesión).
Al implementar se detectó que eso exponía el directorio completo (celular, cédula
incluidos) también a quien navega sin cuenta — el muro de sesión a nivel de UI no
alcanzaba a evitarlo, porque los datos ya estarían en memoria desde el arranque.

Se cambió a un método `_escucharUsuarios(String? uid)`, que se arma y rearma en los
mismos puntos donde ya se arma `_escucharNotificaciones` (login, registro, logout,
borrado de cuenta, restauración de sesión al abrir la app) — si `uid` es `null`
(sin sesión), `todosLosUsuarios` se mantiene vacío y la suscripción se cancela. Esto
resuelve el riesgo de privacidad en el origen: la colección completa de usuarios
nunca llega a la memoria de quien no ha iniciado sesión, en vez de solo ocultarse en
la interfaz.

**Pendiente de validar contra el proyecto real (no verificable desde el código):**
que las reglas de Firestore permitan `usuarios.snapshots()` para un usuario
autenticado — confirmar en la consola de Firebase.

## Pendiente relacionado (fuera de alcance, no resuelto aquí)

Visibilidad Premium para trabajadores quedó en pausa (ver conversación de diseño
previa) — el empleador ya tiene Premium por publicación individual ($10.000, flujo
manual con comprobante); para trabajadores se evaluó una versión de perfil con
vigencia de 30 días al mismo precio, pero no se decidió. No forma parte de este
diseño.
