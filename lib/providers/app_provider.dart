import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/peticion.dart';
import '../models/usuario.dart';
import '../models/calificacion.dart';
import '../models/notificacion.dart';
import '../models/premium_trabajador.dart';
import '../models/reporte.dart';
import '../models/verificacion_identidad.dart';

enum RolUsuario { empleador, trabajador }

// Identidad/perfil (usuarios), peticiones, calificaciones, notificaciones y
// reportes viven todos en Firebase Auth + Firestore. Notificaciones se
// escuchan en tiempo real (filtradas por usuario); reportes se cargan bajo
// demanda solo cuando un administrador abre el panel de Administración.
class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _suscripcionPeticiones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _suscripcionCalificaciones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _suscripcionNotificaciones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionUsuarios;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _suscripcionPremiumTrabajadores;

  static const _claveUsuarios = 'chambapp_usuarios';
  static const _claveRol = 'chambapp_rol_actual';
  static const _claveNotificaciones = 'chambapp_notificaciones_activas';
  static const _claveRadio = 'chambapp_radio_busqueda_km';
  static const _claveTema = 'chambapp_tema_preferido';

  // Cuentas de los autores del proyecto — únicas con acceso al panel de
  // Administración (reportes). Lista fija por ahora; se reemplaza por un
  // campo real de rol de administrador cuando exista un backend (Fase B).
  static const _correosAdmin = {
    'kharoljcalderon@uts.edu.co',
    'carojasperales@uts.edu.co',
  };

  bool get esAdmin {
    final correo = usuarioActual?.correo.trim().toLowerCase();
    return correo != null && _correosAdmin.contains(correo);
  }

  // El estado de verificación vive en el objeto de Firebase Auth
  // (`currentUser.emailVerified`), no en el documento de Firestore — y no
  // se actualiza solo, así que hay que refrescarlo explícitamente
  // (`recargarVerificacionCorreo`) después de que la persona confirme el
  // correo desde su bandeja de entrada.
  bool get correoVerificado =>
      usuarioActual == null || (_auth.currentUser?.emailVerified ?? false);

  Future<void> recargarVerificacionCorreo() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {
      // Sin conexión u otro error transitorio: se reintenta la próxima vez.
    }
    notifyListeners();
  }

  Future<void> reenviarCorreoVerificacion() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (_) {
      // Silencioso — el botón de reenviar puede tocarse varias veces sin
      // que un error transitorio rompa la pantalla.
    }
  }

  RolUsuario? rolActual;
  Usuario? usuarioActual;
  bool notificacionesActivas = true;
  double radioBusquedaKm = 50;
  ThemeMode temaPreferido = ThemeMode.system;

  // Todos los usuarios reales registrados, sincronizados en tiempo real desde
  // Firestore (a diferencia de [usuarios] abajo, que es solo la lista fija de
  // siembra/demo). Alimenta la búsqueda de personas por nombre en el feed.
  final List<Usuario> todosLosUsuarios = [];

  // Solicitudes de Visibilidad Premium de trabajadores, sincronizadas en
  // tiempo real desde Firestore. A diferencia de [todosLosUsuarios], no
  // requiere sesión activa: no contiene datos sensibles (solo usuarioId,
  // oficio y fechas), y el Podio de Recomendados debe verse igual que el
  // feed, sin necesidad de cuenta.
  final List<PremiumTrabajador> premiumTrabajadores = [];

  // Verificación de identidad (cédula) del usuario con sesión activa. A
  // diferencia de [premiumTrabajadores], no se escucha en tiempo real para
  // todo el mundo: contiene la ruta local de la foto de la cédula, un dato
  // más sensible que el resto del perfil, así que solo se consulta bajo
  // demanda para el propio usuario (ver [cargarMiVerificacionIdentidad]).
  VerificacionIdentidad? miVerificacionIdentidad;

  Future<void> cargarMiVerificacionIdentidad() async {
    final actual = usuarioActual;
    if (actual == null) return;
    try {
      final doc = await _db
          .collection('verificacionesIdentidad')
          .doc(actual.id)
          .get();
      miVerificacionIdentidad = doc.exists
          ? VerificacionIdentidad.fromFirestore(doc.data()!, doc.id)
          : null;
    } catch (_) {
      // Sin conexión u otro error transitorio: la pantalla se queda en su
      // estado anterior y se puede reintentar volviendo a abrirla.
    }
    notifyListeners();
  }

  Future<String?> solicitarVerificacionIdentidad({
    required String numeroCedula,
    required String fotoCedulaPath,
  }) async {
    final actual = usuarioActual;
    if (actual == null) {
      return 'Debes iniciar sesión para solicitar la verificación.';
    }
    if (actual.perfilVerificado) return 'Tu perfil ya está verificado.';
    if (miVerificacionIdentidad != null &&
        miVerificacionIdentidad!.solicitada &&
        !miVerificacionIdentidad!.aprobada) {
      return 'Ya tienes una solicitud de verificación en revisión.';
    }

    final doc = VerificacionIdentidad(
      id: actual.id,
      usuarioId: actual.id,
      numeroCedula: numeroCedula,
      fotoCedulaPath: fotoCedulaPath,
      solicitada: true,
      solicitadaEn: DateTime.now(),
    );
    try {
      await _db
          .collection('verificacionesIdentidad')
          .doc(doc.id)
          .set(doc.toFirestore());
    } catch (_) {
      return 'No se pudo enviar la solicitud. Intenta de nuevo.';
    }
    miVerificacionIdentidad = doc;
    // El número de cédula queda también autodeclarado en el perfil, igual
    // que si se hubiera guardado desde Editar perfil.
    actual.cedula = numeroCedula;
    notifyListeners();
    unawaited(_guardarEstado());
    try {
      await _db.collection('usuarios').doc(actual.id).update({
        'cedula': numeroCedula,
      });
    } catch (_) {
      // Igual que en actualizarPerfil: la copia local ya quedó actualizada.
    }
    return null;
  }

  // Solicitudes de verificación de identidad pendientes de revisión —
  // cargadas bajo demanda solo cuando un administrador abre el panel de
  // Administración, igual que [reportes].
  final List<VerificacionIdentidad> verificacionesPendientes = [];

  Future<void> cargarVerificacionesPendientes() async {
    try {
      final snapshot = await _db
          .collection('verificacionesIdentidad')
          .where('solicitada', isEqualTo: true)
          .where('aprobada', isEqualTo: false)
          .get();
      verificacionesPendientes
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (doc) => VerificacionIdentidad.fromFirestore(doc.data(), doc.id),
          ),
        );
      notifyListeners();
    } catch (_) {
      // Sin conexión o sin permiso: se deja la lista como estaba.
    }
  }

  /// Aprueba la solicitud de un tercero — a diferencia de la vieja
  /// autoaprobación de demo, esta la ejecuta un administrador desde el
  /// panel de Administración sobre la solicitud de otro usuario.
  Future<void> aprobarVerificacionIdentidad(
    VerificacionIdentidad solicitud,
  ) async {
    try {
      await _db.collection('verificacionesIdentidad').doc(solicitud.id).update({
        'aprobada': true,
      });
      await _db.collection('usuarios').doc(solicitud.usuarioId).update({
        'perfilVerificado': true,
      });
    } catch (_) {
      return;
    }
    verificacionesPendientes.removeWhere((v) => v.id == solicitud.id);
    notifyListeners();
    unawaited(
      _crearNotificacion(
        paraUsuarioId: solicitud.usuarioId,
        mensaje: 'Tu perfil fue verificado con tu cédula.',
      ),
    );
  }

  /// Rechaza la solicitud borrando el documento (en vez de marcar un campo
  /// `rechazada`) para que el usuario pueda volver a solicitar la
  /// verificación desde cero sin quedar bloqueado por el chequeo de
  /// "solicitud en revisión" en [solicitarVerificacionIdentidad].
  Future<void> rechazarVerificacionIdentidad(
    VerificacionIdentidad solicitud,
  ) async {
    try {
      await _db
          .collection('verificacionesIdentidad')
          .doc(solicitud.id)
          .delete();
    } catch (_) {
      return;
    }
    verificacionesPendientes.removeWhere((v) => v.id == solicitud.id);
    notifyListeners();
    unawaited(
      _crearNotificacion(
        paraUsuarioId: solicitud.usuarioId,
        mensaje:
            'Tu verificación de identidad fue rechazada. Revisa que la foto de tu cédula sea legible y vuelve a intentarlo.',
      ),
    );
  }

  // Rotación estilo Airbnb/Mercado Pago (2026-09-14): "Visibilidad Premium"
  // ya no reserva uno de solo 3 cupos fijos por 30 días — ahora vende hasta
  // [_cupoMaximoVipPorOficio] "pases VIP" por oficio, y el Podio muestra 3 al
  // azar entre todos los VIP activos en cada carga. Así todo el que paga
  // recibe exposición real a lo largo del mes, en vez de quedar bloqueado si
  // alguien más llegó primero.
  static const _cupoMaximoVipPorOficio = 10;

  List<PremiumTrabajador> vipActivosPara(String oficio) =>
      premiumTrabajadores.where((p) => p.oficio == oficio && p.activo).toList();

  bool podioLleno(String oficio) =>
      vipActivosPara(oficio).length >= _cupoMaximoVipPorOficio;

  int get cupoMaximoVipPorOficio => _cupoMaximoVipPorOficio;

  /// Los 3 que se muestran ahora mismo en el Podio de [oficio]. Si hay 3 o
  /// menos VIP activos, se muestran todos. Si hay más, se eligen 3 al azar
  /// con una semilla que cambia cada 15 minutos — estable dentro de esa
  /// ventana (no "parpadea" en cada rebuild de la pantalla), pero rota a lo
  /// largo del día para repartir la exposición entre todos los VIP.
  List<PremiumTrabajador> podioPara(String oficio) {
    final activos = vipActivosPara(oficio);
    if (activos.length <= 3) return activos;
    final ventana = DateTime.now().millisecondsSinceEpoch ~/ (15 * 60 * 1000);
    final aleatorio = Random(Object.hash(oficio, ventana));
    return ([...activos]..shuffle(aleatorio)).take(3).toList();
  }

  // Señal de navegación efímera: "ve al feed y filtra por esta categoría".
  // No es un dato de negocio, solo un puente entre PremiumTrabajadorScreen
  // (que vive en otra rama de navegación) y FeedScreen, que persiste su
  // estado dentro del IndexedStack de MainNavScreen.
  String? categoriaParaVerEnFeed;

  void irAlPodioDe(String categoria) {
    categoriaParaVerEnFeed = categoria;
    notifyListeners();
  }

  void categoriaParaVerEnFeedConsumida() {
    categoriaParaVerEnFeed = null;
  }

  List<Usuario> buscarUsuariosPorNombre(String termino) {
    final t = termino.trim().toLowerCase();
    if (t.isEmpty) return const [];
    return todosLosUsuarios
        .where(
          (u) =>
              u.id != usuarioActual?.id && u.nombre.toLowerCase().contains(t),
        )
        .toList();
  }

  // Usuarios de referencia (Carlos, Rosa, etc.) — no son cuentas reales de
  // Firebase Auth, solo se usan para sembrar Firestore la primera vez y
  // como respaldo local (ej. panel de Administración) mientras esa parte
  // no se migra todavía.
  final List<Usuario> usuarios = [
    Usuario(
      id: 'u-carlos',
      nombre: 'Carlos R.',
      correo: 'carlos.r@example.com',
      celular: '3001234567',
      oficios: ['Pintura'],
      calificacionPromedio: 4.5,
      numeroCalificaciones: 12,
    ),
    Usuario(
      id: 'u-rosa',
      nombre: 'Rosa T.',
      correo: 'rosa.t@example.com',
      celular: '3007654321',
      oficios: ['Electricidad'],
      calificacionPromedio: 4.8,
      numeroCalificaciones: 27,
    ),
    Usuario(
      id: 'u-maria',
      nombre: 'María J.',
      correo: 'maria.j@example.com',
      celular: '3009876543',
      oficios: ['Plomería'],
      calificacionPromedio: 4.2,
      numeroCalificaciones: 8,
    ),
    Usuario(
      id: 'u-diego',
      nombre: 'Diego Fernández',
      correo: 'diego.f@example.com',
      celular: '3012345678',
      oficios: ['Carpintería', 'Pintura'],
      calificacionPromedio: 4.6,
      numeroCalificaciones: 15,
    ),
    Usuario(
      id: 'u-laura',
      nombre: 'Laura Pinzón',
      correo: 'laura.p@example.com',
      celular: '3023456789',
      oficios: ['Limpieza del hogar'],
      calificacionPromedio: 4.9,
      numeroCalificaciones: 30,
    ),
    Usuario(
      id: 'u-andres',
      nombre: 'Andrés Mantilla',
      correo: 'andres.m@example.com',
      celular: '3034567890',
      oficios: ['Jardinería'],
      calificacionPromedio: 4.0,
      numeroCalificaciones: 5,
    ),
    Usuario(
      id: 'u-sofia',
      nombre: 'Sofía Ortiz',
      correo: 'sofia.o@example.com',
      celular: '3045678901',
    ),
  ];

  final List<Calificacion> calificaciones = [];
  final List<Notificacion> notificaciones = [];
  final List<Reporte> reportes = [];
  final List<Peticion> peticiones = [];

  List<Calificacion> _calificacionesDemo() => [
    Calificacion(
      id: 'demo-cal-1',
      deUsuarioId: 'u-rosa',
      paraUsuarioId: 'u-diego',
      estrellas: 5,
      comentario: 'Excelente trabajo, muy puntual y ordenado.',
      fecha: DateTime.now().subtract(const Duration(days: 3)),
      peticionId: '5',
    ),
  ];

  List<Peticion> _peticionesDemo() => [
    Peticion(
      id: '1',
      autorId: 'u-maria',
      autorNombre: 'María J.',
      barrio: 'Provenza',
      descripcion:
          'Se dañó la tubería de la cocina, necesito un plomero urgente',
      categoria: 'Plomería',
      urgente: true,
      creadaEn: DateTime.now().subtract(const Duration(minutes: 20)),
      lat: 7.1198,
      lng: -73.1210,
      interesados: [...usuarios.where((u) => u.id == 'u-rosa')],
    ),
    Peticion(
      id: '2',
      autorId: 'u-carlos',
      autorNombre: 'Carlos R.',
      barrio: 'La Concordia',
      descripcion: 'Busco quien pinte una fachada pequeña este fin de semana',
      categoria: 'Pintura',
      creadaEn: DateTime.now().subtract(const Duration(hours: 2)),
      lat: 7.1245,
      lng: -73.1189,
    ),
    Peticion(
      id: '3',
      autorId: 'u-rosa',
      autorNombre: 'Rosa T.',
      barrio: 'Kennedy',
      descripcion: 'Necesito instalar un tomacorriente nuevo en la sala',
      categoria: 'Electricidad',
      creadaEn: DateTime.now().subtract(const Duration(hours: 5)),
      lat: 7.1156,
      lng: -73.1257,
      interesados: [...usuarios.where((u) => u.id == 'u-maria')],
    ),
    Peticion(
      id: '4',
      autorId: 'u-sofia',
      autorNombre: 'Sofía Ortiz',
      barrio: 'Cabecera',
      descripcion: 'Corto circuito en el tablero eléctrico, necesito ayuda urgente hoy mismo',
      categoria: 'Electricidad',
      urgente: true,
      creadaEn: DateTime.now().subtract(const Duration(minutes: 5)),
      lat: 7.1220,
      lng: -73.1230,
      premiumSolicitada: true,
      premiumAprobada: true,
      comprobantePago: 'demo-001',
    ),
    Peticion(
      id: '5',
      autorId: 'u-rosa',
      autorNombre: 'Rosa T.',
      barrio: 'Kennedy',
      descripcion: 'Arreglo de una puerta de closet y un mueble de cocina',
      categoria: 'Carpintería',
      creadaEn: DateTime.now().subtract(const Duration(days: 4)),
      lat: 7.1180,
      lng: -73.1200,
      interesados: [...usuarios.where((u) => u.id == 'u-diego')],
      trabajadorSeleccionadoId: 'u-diego',
      cerrada: true,
    ),
    Peticion(
      id: '6',
      autorId: 'u-maria',
      autorNombre: 'María J.',
      barrio: 'Cabecera',
      descripcion:
          'Necesito limpieza profunda de apartamento antes de una mudanza',
      categoria: 'Limpieza del hogar',
      creadaEn: DateTime.now().subtract(const Duration(hours: 8)),
      lat: 7.1265,
      lng: -73.1175,
      interesados: [
        ...usuarios.where((u) => u.id == 'u-laura'),
        ...usuarios.where((u) => u.id == 'u-rosa'),
      ],
    ),
    Peticion(
      id: '7',
      autorId: 'u-carlos',
      autorNombre: 'Carlos R.',
      barrio: 'Provenza',
      descripcion: 'Busco quien me ayude a preparar comida para una reunión familiar el sábado',
      categoria: 'Cocina',
      creadaEn: DateTime.now().subtract(const Duration(minutes: 45)),
      lat: 7.1140,
      lng: -73.1245,
    ),
  ];

  Future<void> cargarEstadoGuardado() async {
    final prefs = await SharedPreferences.getInstance();

    final usuariosJson = prefs.getString(_claveUsuarios);
    if (usuariosJson != null) {
      final lista = (jsonDecode(usuariosJson) as List)
          .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
          .toList();
      usuarios
        ..clear()
        ..addAll(lista);
    }

    final rolGuardado = prefs.getString(_claveRol);
    if (rolGuardado != null) {
      rolActual = RolUsuario.values.byName(rolGuardado);
    }

    notificacionesActivas = prefs.getBool(_claveNotificaciones) ?? true;
    radioBusquedaKm = prefs.getDouble(_claveRadio) ?? 50;
    final temaGuardado = prefs.getString(_claveTema);
    if (temaGuardado != null) {
      temaPreferido = ThemeMode.values.byName(temaGuardado);
    }

    // La sesión real de identidad viene de Firebase Auth, no de lo guardado
    // localmente — si hay una sesión activa, tiene prioridad.
    await restaurarSesionFirebase();

    // Peticiones y calificaciones ahora viven en Firestore, con escucha en
    // tiempo real (incluye la siembra única de datos de ejemplo la primera
    // vez que la colección está vacía).
    await iniciarEscuchaFirestore();

    notifyListeners();
  }

  Future<void> restaurarSesionFirebase() async {
    final actual = _auth.currentUser;
    if (actual == null) {
      unawaited(_escucharNotificaciones(null));
      unawaited(_escucharUsuarios(null));
      return;
    }
    try {
      final doc = await _db.collection('usuarios').doc(actual.uid).get();
      if (doc.exists) {
        usuarioActual = Usuario.fromJson(doc.data()!);
      }
      // Refresca el estado de verificación al abrir la app, por si se
      // confirmó el correo desde el buzón en una sesión anterior.
      await actual.reload();
    } catch (_) {
      // Sin conexión u otro error transitorio: se reintenta en el próximo
      // arranque de la app, no es un fallo crítico dejarlo así por ahora.
    }
    unawaited(_escucharNotificaciones(usuarioActual?.id));
    unawaited(_escucharUsuarios(usuarioActual?.id));
  }

  /// Escucha en tiempo real las notificaciones del usuario [uid]. Se
  /// re-arma cada vez que cambia la identidad activa (login, registro,
  /// logout, borrado de cuenta) para no arrastrar notificaciones de una
  /// cuenta hacia otra en el mismo dispositivo.
  Future<void> _escucharNotificaciones(String? uid) async {
    await _suscripcionNotificaciones?.cancel();
    if (uid == null) {
      notificaciones.clear();
      notifyListeners();
      return;
    }
    _suscripcionNotificaciones = _db
        .collection('notificaciones')
        .where('paraUsuarioId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          notificaciones
            ..clear()
            ..addAll(
              snapshot.docs.map(
                (doc) => Notificacion.fromFirestore(doc.data(), doc.id),
              ),
            );
          notifyListeners();
        });
  }

  /// Escucha en tiempo real el directorio completo de usuarios (para la
  /// búsqueda de personas por nombre en el feed). Se arma/rearma junto con
  /// [_escucharNotificaciones] en cada cambio de sesión, y **solo cuando hay
  /// sesión activa** — a diferencia de peticiones/calificaciones, este es un
  /// listado con datos sensibles por usuario (celular, cédula), así que no
  /// se sincroniza para quien navega sin haber iniciado sesión.
  Future<void> _escucharUsuarios(String? uid) async {
    await _suscripcionUsuarios?.cancel();
    if (uid == null) {
      todosLosUsuarios.clear();
      notifyListeners();
      return;
    }
    _suscripcionUsuarios = _db.collection('usuarios').snapshots().listen((
      snapshot,
    ) {
      todosLosUsuarios
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Usuario.fromJson(doc.data())));
      notifyListeners();
    });
  }

  Future<void> iniciarEscuchaFirestore() async {
    try {
      // Se revisa un id fijo de ejemplo en vez de "¿está vacía la colección?"
      // -- si no, en cuanto exista UNA petición real (de cualquier usuario),
      // la siembra de ejemplo nunca se reintentaría, aunque nunca haya
      // llegado a completarse (ej. por un rechazo de las reglas de
      // seguridad).
      final yaSembrado = await _db.collection('peticiones').doc('1').get();
      if (!yaSembrado.exists) {
        // Siembra única: usuarios de referencia + peticiones + calificación
        // de ejemplo, para que el feed no se vea vacío mientras hay pocos
        // usuarios reales. `merge: true` evita pisar una cuenta real si
        // algún día coincidiera un id (no debería pasar, usan ids fijos).
        for (final u in usuarios) {
          await _db
              .collection('usuarios')
              .doc(u.id)
              .set(u.toJson(), SetOptions(merge: true));
        }
        for (final p in _peticionesDemo()) {
          await _db.collection('peticiones').doc(p.id).set(p.toFirestore());
        }
        for (final c in _calificacionesDemo()) {
          await _db.collection('calificaciones').doc(c.id).set(c.toJson());
        }
      }
    } catch (_) {
      // Sin conexión al primer abrir la app u otro error transitorio: no
      // tumba el arranque, se reintenta sembrando en un futuro inicio.
    }

    await _suscripcionPeticiones?.cancel();
    _suscripcionPeticiones = _db.collection('peticiones').snapshots().listen((
      snapshot,
    ) {
      peticiones
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (doc) => Peticion.fromFirestore(doc.data(), doc.id),
          ),
        );
      notifyListeners();
    });

    await _suscripcionCalificaciones?.cancel();
    _suscripcionCalificaciones = _db
        .collection('calificaciones')
        .snapshots()
        .listen((snapshot) {
          calificaciones
            ..clear()
            ..addAll(
              snapshot.docs.map((doc) => Calificacion.fromJson(doc.data())),
            );
          notifyListeners();
        });

    await _suscripcionPremiumTrabajadores?.cancel();
    _suscripcionPremiumTrabajadores = _db
        .collection('premiumTrabajador')
        .snapshots()
        .listen((snapshot) {
          premiumTrabajadores
            ..clear()
            ..addAll(
              snapshot.docs.map(
                (doc) => PremiumTrabajador.fromFirestore(doc.data(), doc.id),
              ),
            );
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _suscripcionPeticiones?.cancel();
    _suscripcionCalificaciones?.cancel();
    _suscripcionNotificaciones?.cancel();
    _suscripcionUsuarios?.cancel();
    _suscripcionPremiumTrabajadores?.cancel();
    super.dispose();
  }

  Future<void> _guardarEstado() async {
    final prefs = await SharedPreferences.getInstance();

    final usuariosJson = jsonEncode(usuarios.map((u) => u.toJson()).toList());
    await prefs.setString(_claveUsuarios, usuariosJson);

    if (rolActual != null) {
      await prefs.setString(_claveRol, rolActual!.name);
    } else {
      await prefs.remove(_claveRol);
    }

    await prefs.setBool(_claveNotificaciones, notificacionesActivas);
    await prefs.setDouble(_claveRadio, radioBusquedaKm);
    await prefs.setString(_claveTema, temaPreferido.name);
  }

  Future<void> _crearNotificacion({
    required String paraUsuarioId,
    required String mensaje,
    String? peticionId,
  }) async {
    final notif = Notificacion(
      id: _db.collection('notificaciones').doc().id,
      paraUsuarioId: paraUsuarioId,
      mensaje: mensaje,
      fecha: DateTime.now(),
      peticionId: peticionId,
    );
    try {
      await _db
          .collection('notificaciones')
          .doc(notif.id)
          .set(notif.toFirestore());
    } catch (_) {
      // Si falla, simplemente no se genera el aviso; no debe tumbar la
      // operación principal que la disparó (marcar interés, calificar, etc.).
    }
  }

  String _truncar(String texto, [int limite = 40]) =>
      texto.length <= limite ? texto : '${texto.substring(0, limite)}...';

  void seleccionarRol(RolUsuario rol) {
    rolActual = rol;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  String _mensajeErrorAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo, intenta iniciar sesión.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'Ese correo no es válido.';
      case 'user-not-found':
        return 'No encontramos una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      default:
        return 'Ocurrió un problema (${e.code}). Intenta de nuevo.';
    }
  }

  Future<String?> registrarConFirebase({
    required String nombre,
    required String correo,
    required String password,
    required String celular,
    List<String>? oficios,
    String? fotoPath,
    String? cedula,
    String? barrio,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );
      final uid = credencial.user!.uid;
      unawaited(credencial.user!.sendEmailVerification());
      final nuevoUsuario = Usuario(
        id: uid,
        nombre: nombre,
        correo: correo.trim(),
        celular: celular,
        oficios: oficios,
        fotoPath: fotoPath,
        cedula: cedula,
        barrio: barrio,
      );
      await _db.collection('usuarios').doc(uid).set(nuevoUsuario.toJson());
      usuarioActual = nuevoUsuario;
      unawaited(_escucharNotificaciones(uid));
      unawaited(_escucharUsuarios(uid));
      notifyListeners();
      unawaited(_guardarEstado());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeErrorAuth(e);
    } catch (_) {
      return 'No se pudo completar el registro. Intenta de nuevo.';
    }
  }

  Future<String?> iniciarSesionConFirebase({
    required String correo,
    required String password,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );
      final doc = await _db
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .get();
      if (!doc.exists) {
        return 'No encontramos tu perfil. Contacta soporte.';
      }
      usuarioActual = Usuario.fromJson(doc.data()!);
      unawaited(_escucharNotificaciones(credencial.user!.uid));
      unawaited(_escucharUsuarios(credencial.user!.uid));
      notifyListeners();
      unawaited(_guardarEstado());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeErrorAuth(e);
    } catch (_) {
      return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
  }

  Future<void> actualizarPerfil({
    required String nombre,
    required String celular,
    List<String>? oficios,
    String? fotoPath,
    String? cedula,
    String? barrio,
  }) async {
    final actual = usuarioActual;
    if (actual == null) return;
    actual.nombre = nombre;
    actual.celular = celular;
    actual.oficios = oficios ?? [];
    if (fotoPath != null) actual.fotoPath = fotoPath;
    if (cedula != null) actual.cedula = cedula;
    if (barrio != null) actual.barrio = barrio;
    notifyListeners();
    unawaited(_guardarEstado());
    try {
      await _db.collection('usuarios').doc(actual.id).update(actual.toJson());
    } catch (_) {
      // La copia local (memoria + shared_preferences) ya quedó actualizada
      // para la UI; si Firestore falla por conexión, no tumbamos la app.
    }
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
    rolActual = null;
    usuarioActual = null;
    unawaited(_escucharNotificaciones(null));
    unawaited(_escucharUsuarios(null));
    notifyListeners();
    unawaited(_guardarEstado());
  }

  /// Elimina la cuenta actual. Devuelve `null` si tuvo éxito, o un mensaje
  /// de error para mostrar al usuario si no se pudo completar.
  Future<String?> eliminarCuentaActual() async {
    final actual = usuarioActual;
    if (actual == null) return null;

    // Se borra la cuenta de Auth PRIMERO: si esto falla (ej. Firebase exige
    // sesión reciente), se aborta sin tocar Firestore ni el estado local —
    // antes se borraba el perfil de Firestore antes que la cuenta de Auth,
    // así que un fallo aquí dejaba una cuenta de Auth "viva" pero sin perfil
    // (huérfana, sin forma de recuperarla ni de volver a iniciar sesión).
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Por seguridad, cierra sesión y vuelve a iniciarla antes de eliminar tu cuenta.';
      }
      return 'No se pudo eliminar tu cuenta. Intenta de nuevo.';
    } catch (_) {
      return 'No se pudo eliminar tu cuenta. Intenta de nuevo.';
    }

    try {
      // Archiva sus peticiones y libera cualquier cupo del Podio antes de
      // borrar el perfil — de lo contrario quedan "vivas" indefinidamente:
      // publicaciones sin dueño real aceptando "Aplicar", y un cupo de
      // Visibilidad Premium ocupado hasta por 30 días aunque la cuenta ya
      // no exista.
      final batch = _db.batch();
      final peticionesActivas = await _db
          .collection('peticiones')
          .where('autorId', isEqualTo: actual.id)
          .where('archivada', isEqualTo: false)
          .get();
      for (final doc in peticionesActivas.docs) {
        batch.update(doc.reference, {'archivada': true});
      }
      final premiumActivo = await _db
          .collection('premiumTrabajador')
          .where('usuarioId', isEqualTo: actual.id)
          .where('aprobada', isEqualTo: true)
          .get();
      for (final doc in premiumActivo.docs) {
        batch.update(doc.reference, {
          'expiraEn': DateTime.now()
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
        });
      }
      await batch.commit();
    } catch (_) {
      // Sin conexión u otro error transitorio: la cuenta de Auth ya se
      // borró; sus peticiones/cupos quedan pendientes de limpiar en un
      // futuro intento, no es un fallo crítico para el borrado en sí.
    }
    try {
      await _db.collection('usuarios').doc(actual.id).delete();
    } catch (_) {
      // Continúa con la limpieza local aunque Firestore falle.
    }
    usuarioActual = null;
    rolActual = null;
    unawaited(_escucharNotificaciones(null));
    unawaited(_escucharUsuarios(null));
    notifyListeners();
    unawaited(_guardarEstado());
    return null;
  }

  void actualizarNotificaciones(bool activas) {
    notificacionesActivas = activas;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void actualizarTema(ThemeMode modo) {
    temaPreferido = modo;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void actualizarRadioBusqueda(double km) {
    radioBusquedaKm = km;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  Future<void> publicarPeticion(Peticion peticion) async {
    try {
      await _db
          .collection('peticiones')
          .doc(peticion.id)
          .set(peticion.toFirestore());
    } catch (_) {
      // El listener de Firestore es la única fuente de verdad de la lista;
      // si la escritura falla, la petición simplemente no aparece.
    }
  }

  Future<void> marcarInteres(String peticionId) async {
    final usuario = usuarioActual;
    assert(
      usuario != null,
      'No se puede marcar interés sin un usuario registrado',
    );
    if (usuario == null) return;

    // La petición pudo archivarse/eliminarse entre que la pantalla la mostró
    // y el tap llegó aquí (listener en tiempo real) — sin esto, firstWhere
    // lanzaría una excepción no capturada dentro de esta llamada.
    Peticion? peticion;
    try {
      peticion = peticiones.firstWhere((p) => p.id == peticionId);
    } catch (_) {
      return;
    }
    final yaInteresado = peticion.interesados.any((u) => u.id == usuario.id);
    if (yaInteresado && peticion.trabajadorSeleccionadoId == usuario.id) {
      // Ya fue seleccionado por el empleador para este trabajo: no puede
      // retirar su interés (dejaría a trabajadorSeleccionadoId apuntando a
      // alguien fuera de la lista de interesados).
      return;
    }

    final nuevaLista = List<Usuario>.from(peticion.interesados);
    if (yaInteresado) {
      nuevaLista.removeWhere((u) => u.id == usuario.id);
    } else {
      nuevaLista.add(usuario);
    }

    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'interesados': nuevaLista.map(Peticion.interesadoAMapa).toList(),
      });
    } catch (_) {
      return;
    }

    if (!yaInteresado) {
      unawaited(
        _crearNotificacion(
          paraUsuarioId: peticion.autorId,
          mensaje:
              '${usuario.nombre} se interesó en tu publicación "${_truncar(peticion.descripcion)}"',
          peticionId: peticion.id,
        ),
      );
      unawaited(_guardarEstado());
    }
  }

  Future<void> marcarVistoPorEmpleador(String peticionId) async {
    Peticion? peticion;
    try {
      peticion = peticiones.firstWhere((p) => p.id == peticionId);
    } catch (_) {
      return;
    }
    final vistosActuales = peticion.vistosPorEmpleador;
    final nuevos = peticion.interesados
        .map((u) => u.id)
        .where((id) => !vistosActuales.contains(id))
        .toList();
    if (nuevos.isEmpty) return;

    for (final id in nuevos) {
      unawaited(
        _crearNotificacion(
          paraUsuarioId: id,
          mensaje:
              'El empleador vio tu perfil en "${_truncar(peticion.descripcion)}"',
          peticionId: peticion.id,
        ),
      );
    }

    final actualizados = {...peticion.vistosPorEmpleador, ...nuevos}.toList();
    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'vistosPorEmpleador': actualizados,
      });
    } catch (_) {
      // Las notificaciones ya se generaron en Firestore; si esta escritura
      // falla, se puede volver a marcar como visto en un próximo intento.
    }
    unawaited(_guardarEstado());
  }

  Future<void> seleccionarTrabajador(
    String peticionId,
    String usuarioId,
  ) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'trabajadorSeleccionadoId': usuarioId,
      });
    } catch (_) {
      return;
    }
    // La escritura ya se aplicó; si la petición desapareció del snapshot
    // local justo después, solo se omite la notificación (no crítico).
    Peticion? peticion;
    try {
      peticion = peticiones.firstWhere((p) => p.id == peticionId);
    } catch (_) {
      peticion = null;
    }
    if (peticion != null) {
      unawaited(
        _crearNotificacion(
          paraUsuarioId: usuarioId,
          mensaje:
              '¡Fuiste seleccionado para "${_truncar(peticion.descripcion)}"! El empleador te contactará por WhatsApp',
          peticionId: peticionId,
        ),
      );
    }
    unawaited(_guardarEstado());
  }

  Future<void> cerrarPeticion(String peticionId) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'cerrada': true,
      });
    } catch (_) {
      // Silencioso: el listener reflejará el estado real en cuanto se
      // reconecte, si la escritura llegó a aplicarse.
    }
  }

  // Las reglas de Firestore no permiten borrar peticiones (para no dejar
  // huérfanas las calificaciones/interesados que las referencian) — en vez
  // de eso se archivan: dejan de verse en el feed y en "Mis publicaciones",
  // pero el documento sigue existiendo.
  Future<void> archivarPeticion(String peticionId) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'archivada': true,
      });
    } catch (_) {
      // Silencioso, igual que el resto de escrituras de estado de petición.
    }
  }

  Future<void> calificarUsuario(Calificacion calificacion) async {
    final calificacionRef = _db
        .collection('calificaciones')
        .doc(calificacion.id);
    final usuarioRef = _db
        .collection('usuarios')
        .doc(calificacion.paraUsuarioId);

    // El promedio se recalcula DENTRO de una transacción (lee el estado más
    // reciente de `usuarios/{id}` y escribe el nuevo promedio en la misma
    // operación atómica) — a diferencia de leer la lista local y hacer un
    // `.update()` suelto, esto evita que dos calificaciones casi simultáneas
    // al mismo usuario se pisen entre sí (Firestore reintenta la transacción
    // automáticamente si detecta que el documento cambió mientras corría).
    double promedio = 0;
    int totalCalificaciones = 0;
    try {
      await _db.runTransaction((tx) async {
        final usuarioSnap = await tx.get(usuarioRef);
        final promedioActual =
            (usuarioSnap.data()?['calificacionPromedio'] as num?)?.toDouble() ??
            0.0;
        final totalActual =
            (usuarioSnap.data()?['numeroCalificaciones'] as num?)?.toInt() ?? 0;
        totalCalificaciones = totalActual + 1;
        promedio =
            (promedioActual * totalActual + calificacion.estrellas) /
            totalCalificaciones;

        tx.set(calificacionRef, calificacion.toJson());
        tx.update(usuarioRef, {
          'calificacionPromedio': promedio,
          'numeroCalificaciones': totalCalificaciones,
        });
      });
    } catch (_) {
      return;
    }

    unawaited(
      _crearNotificacion(
        paraUsuarioId: calificacion.paraUsuarioId,
        mensaje:
            'Recibiste una calificación de ${calificacion.estrellas} estrellas',
      ),
    );
    unawaited(_guardarEstado());

    for (final u in usuarios) {
      if (u.id == calificacion.paraUsuarioId) {
        u.calificacionPromedio = promedio;
        u.numeroCalificaciones = totalCalificaciones;
      }
    }
    for (final u in todosLosUsuarios) {
      if (u.id == calificacion.paraUsuarioId) {
        u.calificacionPromedio = promedio;
        u.numeroCalificaciones = totalCalificaciones;
      }
    }
    if (usuarioActual?.id == calificacion.paraUsuarioId) {
      usuarioActual!.calificacionPromedio = promedio;
      usuarioActual!.numeroCalificaciones = totalCalificaciones;
    }
    notifyListeners();
  }

  /// Activa Visibilidad Premium sobre una petición apenas PayPal confirma
  /// el pago (ver `PagoPaypalScreen`) — reemplaza el viejo par
  /// `solicitarPremium` + `aprobarPremiumDemo` (comprobante de texto libre
  /// + botón de autoaprobación) porque la pasarela ya es la verificación
  /// real: no hace falta una revisión manual aparte.
  Future<void> activarPremiumPeticion(
    String peticionId,
    String ordenPaypalId,
  ) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'premiumSolicitada': true,
        'premiumAprobada': true,
        'comprobantePago': 'paypal:$ordenPaypalId',
      });
    } catch (_) {
      return;
    }
    // La escritura ya se aplicó; si la petición desapareció del snapshot
    // local justo después, solo se omite la notificación (no crítico).
    Peticion? peticion;
    try {
      peticion = peticiones.firstWhere((p) => p.id == peticionId);
    } catch (_) {
      peticion = null;
    }
    if (peticion != null) {
      unawaited(
        _crearNotificacion(
          paraUsuarioId: peticion.autorId,
          mensaje:
              'Tu Visibilidad Premium fue aprobada para "${_truncar(peticion.descripcion)}"',
          peticionId: peticionId,
        ),
      );
    }
    unawaited(_guardarEstado());
  }

  /// Activa el VIP de un oficio apenas PayPal confirma el pago — reemplaza
  /// el viejo par `solicitarPremiumTrabajador` + `aprobarPremiumTrabajadorDemo`
  /// por la misma razón que [activarPremiumPeticion]: la pasarela ya
  /// verificó el pago, así que solicitud y aprobación quedan en una sola
  /// escritura.
  ///
  /// Nota: el cupo se revisa antes de iniciar el pago Y otra vez aquí (por
  /// si se llenó mientras la persona pagaba) — en ese caso de carrera el
  /// dinero de sandbox ya se "cobró" pero el cupo no se activa. Para un
  /// prototipo de tesis no se implementa reembolso automático; en
  /// producción esto necesitaría un flujo de devolución.
  Future<String?> activarPremiumTrabajador({
    required String oficio,
    required String ordenPaypalId,
  }) async {
    final actual = usuarioActual;
    if (actual == null) {
      return 'Debes iniciar sesión para solicitar Visibilidad Premium.';
    }
    if (podioLleno(oficio)) {
      return 'Los $_cupoMaximoVipPorOficio cupos VIP de "$oficio" ya están ocupados. Contacta soporte para tu reembolso.';
    }
    final yaTiene = premiumTrabajadores.any(
      (p) =>
          p.usuarioId == actual.id &&
          p.oficio == oficio &&
          (p.activo || (p.solicitada && !p.aprobada)),
    );
    if (yaTiene) {
      return 'Ya tienes una solicitud activa o en revisión para "$oficio".';
    }

    final doc = PremiumTrabajador(
      id: _db.collection('premiumTrabajador').doc().id,
      usuarioId: actual.id,
      oficio: oficio,
      solicitada: true,
      aprobada: true,
      comprobantePago: 'paypal:$ordenPaypalId',
      solicitadaEn: DateTime.now(),
      expiraEn: DateTime.now().add(const Duration(days: 30)),
      usuarioNombre: actual.nombre,
      usuarioFotoPath: actual.fotoPath,
      calificacionPromedio: actual.calificacionPromedio,
      numeroCalificaciones: actual.numeroCalificaciones,
    );
    try {
      await _db
          .collection('premiumTrabajador')
          .doc(doc.id)
          .set(doc.toFirestore());
    } catch (_) {
      return 'El pago se confirmó pero no se pudo activar tu Visibilidad Premium. Contacta soporte.';
    }
    unawaited(
      _crearNotificacion(
        paraUsuarioId: actual.id,
        mensaje: 'Tu Visibilidad Premium fue activada para "$oficio"',
      ),
    );
    return null;
  }

  bool yaCalifique({required String deUsuarioId, required String peticionId}) =>
      calificaciones.any(
        (c) => c.deUsuarioId == deUsuarioId && c.peticionId == peticionId,
      );

  List<Peticion> get misPublicaciones => peticiones
      .where((p) => p.autorId == usuarioActual?.id && !p.archivada)
      .toList();

  /// Mis publicaciones que todavía admiten invitar a alguien (no archivadas,
  /// no finalizadas) — la lista que se ofrece al invitar desde el perfil de
  /// un trabajador (ej. desde el Podio de Recomendados).
  List<Peticion> get misPublicacionesInvitables =>
      misPublicaciones.where((p) => !p.cerrada).toList();

  /// Invita a [trabajador] a aplicar a la publicación [peticionId] — usado
  /// desde el perfil público de un trabajador (típicamente al llegar desde
  /// el Podio de Recomendados). No lo agrega directo a `interesados`: solo
  /// le manda una notificación con el enlace a la publicación, y es el
  /// propio trabajador quien decide aplicar desde ahí — mismo flujo de
  /// siempre (aplicar → aparece en Interesados → el empleador selecciona y
  /// recién ahí se abre WhatsApp), sin saltarse ese filtro.
  Future<String?> invitarTrabajador({
    required String peticionId,
    required Usuario trabajador,
  }) async {
    final actual = usuarioActual;
    if (actual == null) return 'Debes iniciar sesión para invitar.';

    Peticion? peticion;
    try {
      peticion = peticiones.firstWhere((p) => p.id == peticionId);
    } catch (_) {
      return 'Esa publicación ya no está disponible.';
    }
    if (peticion.autorId != actual.id) {
      return 'Solo puedes invitar desde tus propias publicaciones.';
    }
    if (peticion.cerrada) {
      return 'Esa publicación ya está finalizada.';
    }
    if (peticion.interesados.any((u) => u.id == trabajador.id)) {
      return '${trabajador.nombre} ya está entre los interesados de esa publicación.';
    }

    unawaited(
      _crearNotificacion(
        paraUsuarioId: trabajador.id,
        mensaje:
            '${actual.nombre} te invitó a aplicar a "${_truncar(peticion.descripcion)}"',
        peticionId: peticionId,
      ),
    );
    return null;
  }

  List<Peticion> get misIntereses => peticiones
      .where((p) => p.interesados.any((u) => u.id == usuarioActual?.id))
      .toList();

  List<Notificacion> get misNotificaciones {
    final propias = notificaciones
        .where((n) => n.paraUsuarioId == usuarioActual?.id)
        .toList();
    propias.sort((a, b) => b.fecha.compareTo(a.fecha));
    return propias;
  }

  int get notificacionesSinLeerCount =>
      misNotificaciones.where((n) => !n.leida).length;

  Future<void> marcarTodasNotificacionesLeidas() async {
    final noLeidas = misNotificaciones.where((n) => !n.leida).toList();
    if (noLeidas.isEmpty) return;
    final batch = _db.batch();
    for (final n in noLeidas) {
      batch.update(_db.collection('notificaciones').doc(n.id), {'leida': true});
    }
    try {
      await batch.commit();
    } catch (_) {
      // El listener reflejará el estado real cuando se reconecte.
    }
  }

  Future<void> eliminarNotificacion(String id) async {
    try {
      await _db.collection('notificaciones').doc(id).delete();
    } catch (_) {
      // El listener reflejará el estado real cuando se reconecte.
    }
  }

  Future<void> crearReporte({
    required String tipo,
    required String contraId,
    required String motivo,
    String? comentario,
  }) async {
    final usuario = usuarioActual;
    if (usuario == null) return;
    final reporte = Reporte(
      id: _db.collection('reportes').doc().id,
      deUsuarioId: usuario.id,
      tipo: tipo,
      contraId: contraId,
      motivo: motivo,
      comentario: comentario,
      fecha: DateTime.now(),
    );
    try {
      await _db
          .collection('reportes')
          .doc(reporte.id)
          .set(reporte.toFirestore());
    } catch (_) {
      // Silencioso: el usuario ya recibió confirmación visual del envío.
    }
  }

  /// Carga los reportes bajo demanda (no hay escucha en tiempo real: solo
  /// los administradores abren esta pantalla, y no necesitan verla
  /// actualizarse sola mientras la tienen abierta).
  Future<void> cargarReportes() async {
    try {
      final snapshot = await _db.collection('reportes').get();
      reportes
        ..clear()
        ..addAll(
          snapshot.docs.map((doc) => Reporte.fromFirestore(doc.data(), doc.id)),
        );
      notifyListeners();
    } catch (_) {
      // Sin conexión o sin permiso: se deja la lista como estaba.
    }
  }

  /// Resuelve el nombre de un usuario para mostrar en el panel de
  /// Administración: primero busca en la lista local de demo (rápido, sin
  /// red), y si no está ahí, lo busca en Firestore (cuenta real).
  Future<String> nombreDeUsuario(String usuarioId) async {
    final local = usuarios.where((u) => u.id == usuarioId);
    if (local.isNotEmpty) return local.first.nombre;
    try {
      final doc = await _db.collection('usuarios').doc(usuarioId).get();
      if (doc.exists) {
        return (doc.data()?['nombre'] as String?) ?? 'Usuario eliminado';
      }
    } catch (_) {
      // Sin conexión: se informa como no disponible más abajo.
    }
    return 'Usuario eliminado';
  }
}
