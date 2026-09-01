import 'dart:async';
import 'dart:convert';

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

enum RolUsuario { empleador, trabajador }

// Identidad/perfil (usuarios), peticiones, calificaciones, notificaciones y
// reportes viven todos en Firebase Auth + Firestore. Notificaciones se
// escuchan en tiempo real (filtradas por usuario); reportes se cargan bajo
// demanda solo cuando un administrador abre el panel de Administración.
class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionPeticiones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionCalificaciones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionNotificaciones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionUsuarios;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionPremiumTrabajadores;

  static const _claveUsuarios = 'chambapp_usuarios';
  static const _claveRol = 'chambapp_rol_actual';
  static const _claveNotificaciones = 'chambapp_notificaciones_activas';
  static const _claveRadio = 'chambapp_radio_busqueda_km';

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

  RolUsuario? rolActual;
  Usuario? usuarioActual;
  bool notificacionesActivas = true;
  double radioBusquedaKm = 50;

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

  List<PremiumTrabajador> podioPara(String oficio) {
    final activos = premiumTrabajadores.where((p) => p.oficio == oficio && p.activo).toList()
      ..sort((a, b) => (a.expiraEn ?? a.solicitadaEn).compareTo(b.expiraEn ?? b.solicitadaEn));
    return activos.take(3).toList();
  }

  bool podioLleno(String oficio) => podioPara(oficio).length >= 3;

  List<Usuario> buscarUsuariosPorNombre(String termino) {
    final t = termino.trim().toLowerCase();
    if (t.isEmpty) return const [];
    return todosLosUsuarios
        .where((u) => u.id != usuarioActual?.id && u.nombre.toLowerCase().contains(t))
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
          descripcion: 'Se dañó la tubería de la cocina, necesito un plomero urgente',
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
          descripcion: 'Necesito limpieza profunda de apartamento antes de una mudanza',
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
    _suscripcionNotificaciones =
        _db.collection('notificaciones').where('paraUsuarioId', isEqualTo: uid).snapshots().listen((snapshot) {
      notificaciones
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Notificacion.fromFirestore(doc.data(), doc.id)));
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
    _suscripcionUsuarios = _db.collection('usuarios').snapshots().listen((snapshot) {
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
          await _db.collection('usuarios').doc(u.id).set(u.toJson(), SetOptions(merge: true));
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
    _suscripcionPeticiones = _db.collection('peticiones').snapshots().listen((snapshot) {
      peticiones
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Peticion.fromFirestore(doc.data(), doc.id)));
      notifyListeners();
    });

    await _suscripcionCalificaciones?.cancel();
    _suscripcionCalificaciones = _db.collection('calificaciones').snapshots().listen((snapshot) {
      calificaciones
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Calificacion.fromJson(doc.data())));
      notifyListeners();
    });

    await _suscripcionPremiumTrabajadores?.cancel();
    _suscripcionPremiumTrabajadores = _db.collection('premiumTrabajador').snapshots().listen((snapshot) {
      premiumTrabajadores
        ..clear()
        ..addAll(snapshot.docs.map((doc) => PremiumTrabajador.fromFirestore(doc.data(), doc.id)));
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
  }

  Future<void> _crearNotificacion({required String paraUsuarioId, required String mensaje, String? peticionId}) async {
    final notif = Notificacion(
      id: _db.collection('notificaciones').doc().id,
      paraUsuarioId: paraUsuarioId,
      mensaje: mensaje,
      fecha: DateTime.now(),
      peticionId: peticionId,
    );
    try {
      await _db.collection('notificaciones').doc(notif.id).set(notif.toFirestore());
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
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );
      final uid = credencial.user!.uid;
      final nuevoUsuario = Usuario(
        id: uid,
        nombre: nombre,
        correo: correo.trim(),
        celular: celular,
        oficios: oficios,
        fotoPath: fotoPath,
        cedula: cedula,
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

  Future<String?> iniciarSesionConFirebase({required String correo, required String password}) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(email: correo.trim(), password: password);
      final doc = await _db.collection('usuarios').doc(credencial.user!.uid).get();
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
  }) async {
    final actual = usuarioActual;
    if (actual == null) return;
    actual.nombre = nombre;
    actual.celular = celular;
    actual.oficios = oficios ?? [];
    if (fotoPath != null) actual.fotoPath = fotoPath;
    if (cedula != null) actual.cedula = cedula;
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

  Future<void> eliminarCuentaActual() async {
    final actual = usuarioActual;
    if (actual == null) return;
    try {
      await _db.collection('usuarios').doc(actual.id).delete();
    } catch (_) {
      // Continúa con la limpieza local aunque Firestore falle.
    }
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      // Firebase exige haber iniciado sesión recientemente para borrar la
      // cuenta de Auth. Por ahora dejamos esa cuenta huérfana (sin perfil
      // en Firestore) — es una limitación aceptable del prototipo.
    }
    usuarioActual = null;
    rolActual = null;
    unawaited(_escucharNotificaciones(null));
    unawaited(_escucharUsuarios(null));
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void actualizarNotificaciones(bool activas) {
    notificacionesActivas = activas;
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
      await _db.collection('peticiones').doc(peticion.id).set(peticion.toFirestore());
    } catch (_) {
      // El listener de Firestore es la única fuente de verdad de la lista;
      // si la escritura falla, la petición simplemente no aparece.
    }
  }

  Future<void> marcarInteres(String peticionId) async {
    final usuario = usuarioActual;
    assert(usuario != null, 'No se puede marcar interés sin un usuario registrado');
    if (usuario == null) return;

    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
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
      unawaited(_crearNotificacion(
        paraUsuarioId: peticion.autorId,
        mensaje: '${usuario.nombre} se interesó en tu publicación "${_truncar(peticion.descripcion)}"',
        peticionId: peticion.id,
      ));
      unawaited(_guardarEstado());
    }
  }

  Future<void> marcarVistoPorEmpleador(String peticionId) async {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    final nuevos =
        peticion.interesados.map((u) => u.id).where((id) => !peticion.vistosPorEmpleador.contains(id)).toList();
    if (nuevos.isEmpty) return;

    for (final id in nuevos) {
      unawaited(_crearNotificacion(
        paraUsuarioId: id,
        mensaje: 'El empleador vio tu perfil en "${_truncar(peticion.descripcion)}"',
        peticionId: peticion.id,
      ));
    }

    final actualizados = {...peticion.vistosPorEmpleador, ...nuevos}.toList();
    try {
      await _db.collection('peticiones').doc(peticionId).update({'vistosPorEmpleador': actualizados});
    } catch (_) {
      // Las notificaciones ya se generaron en Firestore; si esta escritura
      // falla, se puede volver a marcar como visto en un próximo intento.
    }
    unawaited(_guardarEstado());
  }

  Future<void> seleccionarTrabajador(String peticionId, String usuarioId) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({'trabajadorSeleccionadoId': usuarioId});
    } catch (_) {
      return;
    }
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    unawaited(_crearNotificacion(
      paraUsuarioId: usuarioId,
      mensaje:
          '¡Fuiste seleccionado para "${_truncar(peticion.descripcion)}"! El empleador te contactará por WhatsApp',
      peticionId: peticionId,
    ));
    unawaited(_guardarEstado());
  }

  Future<void> cerrarPeticion(String peticionId) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({'cerrada': true});
    } catch (_) {
      // Silencioso: el listener reflejará el estado real en cuanto se
      // reconecte, si la escritura llegó a aplicarse.
    }
  }

  Future<void> calificarUsuario(Calificacion calificacion) async {
    try {
      await _db.collection('calificaciones').doc(calificacion.id).set(calificacion.toJson());
    } catch (_) {
      return;
    }

    unawaited(_crearNotificacion(
      paraUsuarioId: calificacion.paraUsuarioId,
      mensaje: 'Recibiste una calificación de ${calificacion.estrellas} estrellas',
    ));
    unawaited(_guardarEstado());

    // El promedio se calcula incluyendo esta calificación aunque el
    // listener de Firestore todavía no haya reflejado el nuevo documento
    // en la lista local (evita depender del orden de llegada del snapshot).
    final calificacionesDelUsuario = [
      ...calificaciones.where((c) => c.paraUsuarioId == calificacion.paraUsuarioId && c.id != calificacion.id),
      calificacion,
    ];
    final promedio = calificacionesDelUsuario.map((c) => c.estrellas).reduce((a, b) => a + b) /
        calificacionesDelUsuario.length;

    for (final u in usuarios) {
      if (u.id == calificacion.paraUsuarioId) {
        u.calificacionPromedio = promedio;
        u.numeroCalificaciones = calificacionesDelUsuario.length;
      }
    }
    for (final u in todosLosUsuarios) {
      if (u.id == calificacion.paraUsuarioId) {
        u.calificacionPromedio = promedio;
        u.numeroCalificaciones = calificacionesDelUsuario.length;
      }
    }
    if (usuarioActual?.id == calificacion.paraUsuarioId) {
      usuarioActual!.calificacionPromedio = promedio;
      usuarioActual!.numeroCalificaciones = calificacionesDelUsuario.length;
    }
    notifyListeners();

    try {
      await _db.collection('usuarios').doc(calificacion.paraUsuarioId).update({
        'calificacionPromedio': promedio,
        'numeroCalificaciones': calificacionesDelUsuario.length,
      });
    } catch (_) {
      // El promedio local ya se actualizó para la UI de este dispositivo.
    }
  }

  Future<void> solicitarPremium(String peticionId, String comprobante) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({
        'premiumSolicitada': true,
        'comprobantePago': comprobante,
      });
    } catch (_) {
      // Silencioso, igual que el resto de escrituras de estado de petición.
    }
  }

  Future<void> aprobarPremiumDemo(String peticionId) async {
    try {
      await _db.collection('peticiones').doc(peticionId).update({'premiumAprobada': true});
    } catch (_) {
      return;
    }
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    unawaited(_crearNotificacion(
      paraUsuarioId: peticion.autorId,
      mensaje: 'Tu Visibilidad Premium fue aprobada para "${_truncar(peticion.descripcion)}"',
      peticionId: peticionId,
    ));
    unawaited(_guardarEstado());
  }

  Future<String?> solicitarPremiumTrabajador({
    required String oficio,
    required String comprobante,
  }) async {
    final actual = usuarioActual;
    if (actual == null) return 'Debes iniciar sesión para solicitar Visibilidad Premium.';
    if (podioLleno(oficio)) {
      return 'Los 3 cupos de "$oficio" ya están ocupados. Vuelve a intentar cuando se libere uno.';
    }
    final yaTiene = premiumTrabajadores.any(
      (p) => p.usuarioId == actual.id && p.oficio == oficio && (p.activo || (p.solicitada && !p.aprobada)),
    );
    if (yaTiene) return 'Ya tienes una solicitud activa o en revisión para "$oficio".';

    final doc = PremiumTrabajador(
      id: _db.collection('premiumTrabajador').doc().id,
      usuarioId: actual.id,
      oficio: oficio,
      solicitada: true,
      comprobantePago: comprobante,
      solicitadaEn: DateTime.now(),
      usuarioNombre: actual.nombre,
      usuarioFotoPath: actual.fotoPath,
      calificacionPromedio: actual.calificacionPromedio,
      numeroCalificaciones: actual.numeroCalificaciones,
    );
    try {
      await _db.collection('premiumTrabajador').doc(doc.id).set(doc.toFirestore());
    } catch (_) {
      return 'No se pudo enviar la solicitud. Intenta de nuevo.';
    }
    return null;
  }

  Future<void> aprobarPremiumTrabajadorDemo(String id) async {
    PremiumTrabajador? solicitud;
    try {
      solicitud = premiumTrabajadores.firstWhere((p) => p.id == id);
    } catch (_) {
      return;
    }
    // Chequeo de cupo repetido al momento de aprobar, no solo al solicitar
    // — evita que un 4to cupo del mismo oficio quede activo si se aprueban
    // solicitudes fuera de orden.
    if (podioLleno(solicitud.oficio)) return;

    final expiraEn = DateTime.now().add(const Duration(days: 30));
    try {
      await _db.collection('premiumTrabajador').doc(id).update({
        'aprobada': true,
        'expiraEn': expiraEn.toIso8601String(),
      });
    } catch (_) {
      return;
    }
    unawaited(_crearNotificacion(
      paraUsuarioId: solicitud.usuarioId,
      mensaje: 'Tu Visibilidad Premium fue aprobada para "${solicitud.oficio}"',
    ));
  }

  bool yaCalifique({required String deUsuarioId, required String peticionId}) =>
      calificaciones.any((c) => c.deUsuarioId == deUsuarioId && c.peticionId == peticionId);

  List<Peticion> get misPublicaciones =>
      peticiones.where((p) => p.autorId == usuarioActual?.id).toList();

  List<Peticion> get misIntereses =>
      peticiones.where((p) => p.interesados.any((u) => u.id == usuarioActual?.id)).toList();

  List<Notificacion> get misNotificaciones {
    final propias = notificaciones.where((n) => n.paraUsuarioId == usuarioActual?.id).toList();
    propias.sort((a, b) => b.fecha.compareTo(a.fecha));
    return propias;
  }

  int get notificacionesSinLeerCount => misNotificaciones.where((n) => !n.leida).length;

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

  Future<void> crearReporte({required String tipo, required String contraId, required String motivo, String? comentario}) async {
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
      await _db.collection('reportes').doc(reporte.id).set(reporte.toFirestore());
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
        ..addAll(snapshot.docs.map((doc) => Reporte.fromFirestore(doc.data(), doc.id)));
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
      if (doc.exists) return (doc.data()?['nombre'] as String?) ?? 'Usuario eliminado';
    } catch (_) {
      // Sin conexión: se informa como no disponible más abajo.
    }
    return 'Usuario eliminado';
  }
}
