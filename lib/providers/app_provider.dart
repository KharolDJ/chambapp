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
import '../models/reporte.dart';

enum RolUsuario { empleador, trabajador }

// Identidad/perfil (usuarios), peticiones y calificaciones ahora viven en
// Firebase Auth + Firestore, con escucha en tiempo real. Notificaciones y
// reportes siguen en shared_preferences por ahora — esa migración es un
// paso aparte, todavía pendiente.
class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionPeticiones;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcionCalificaciones;

  static const _claveUsuarios = 'chambapp_usuarios';
  static const _claveRol = 'chambapp_rol_actual';
  static const _claveNotificaciones = 'chambapp_notificaciones_activas';
  static const _claveRadio = 'chambapp_radio_busqueda_km';
  static const _claveNotificacionesLista = 'chambapp_notificaciones';
  static const _claveReportes = 'chambapp_reportes';

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

    final notificacionesJson = prefs.getString(_claveNotificacionesLista);
    if (notificacionesJson != null) {
      final lista = (jsonDecode(notificacionesJson) as List)
          .map((e) => Notificacion.fromJson(e as Map<String, dynamic>))
          .toList();
      notificaciones
        ..clear()
        ..addAll(lista);
    }

    final reportesJson = prefs.getString(_claveReportes);
    if (reportesJson != null) {
      final lista =
          (jsonDecode(reportesJson) as List).map((e) => Reporte.fromJson(e as Map<String, dynamic>)).toList();
      reportes
        ..clear()
        ..addAll(lista);
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
    if (actual == null) return;
    try {
      final doc = await _db.collection('usuarios').doc(actual.uid).get();
      if (doc.exists) {
        usuarioActual = Usuario.fromJson(doc.data()!);
      }
    } catch (_) {
      // Sin conexión u otro error transitorio: se reintenta en el próximo
      // arranque de la app, no es un fallo crítico dejarlo así por ahora.
    }
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
  }

  @override
  void dispose() {
    _suscripcionPeticiones?.cancel();
    _suscripcionCalificaciones?.cancel();
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

    final notificacionesJson = jsonEncode(notificaciones.map((n) => n.toJson()).toList());
    await prefs.setString(_claveNotificacionesLista, notificacionesJson);

    final reportesJson = jsonEncode(reportes.map((r) => r.toJson()).toList());
    await prefs.setString(_claveReportes, reportesJson);
  }

  void _crearNotificacion({required String paraUsuarioId, required String mensaje, String? peticionId}) {
    notificaciones.add(Notificacion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      paraUsuarioId: paraUsuarioId,
      mensaje: mensaje,
      fecha: DateTime.now(),
      peticionId: peticionId,
    ));
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
      _crearNotificacion(
        paraUsuarioId: peticion.autorId,
        mensaje: '${usuario.nombre} se interesó en tu publicación "${_truncar(peticion.descripcion)}"',
        peticionId: peticion.id,
      );
      unawaited(_guardarEstado());
    }
  }

  Future<void> marcarVistoPorEmpleador(String peticionId) async {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    final nuevos =
        peticion.interesados.map((u) => u.id).where((id) => !peticion.vistosPorEmpleador.contains(id)).toList();
    if (nuevos.isEmpty) return;

    for (final id in nuevos) {
      _crearNotificacion(
        paraUsuarioId: id,
        mensaje: 'El empleador vio tu perfil en "${_truncar(peticion.descripcion)}"',
        peticionId: peticion.id,
      );
    }

    final actualizados = {...peticion.vistosPorEmpleador, ...nuevos}.toList();
    try {
      await _db.collection('peticiones').doc(peticionId).update({'vistosPorEmpleador': actualizados});
    } catch (_) {
      // Las notificaciones ya se generaron localmente; si Firestore falla,
      // se puede volver a marcar como visto en un próximo intento.
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
    _crearNotificacion(
      paraUsuarioId: usuarioId,
      mensaje:
          '¡Fuiste seleccionado para "${_truncar(peticion.descripcion)}"! El empleador te contactará por WhatsApp',
      peticionId: peticionId,
    );
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

    _crearNotificacion(
      paraUsuarioId: calificacion.paraUsuarioId,
      mensaje: 'Recibiste una calificación de ${calificacion.estrellas} estrellas',
    );
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
    _crearNotificacion(
      paraUsuarioId: peticion.autorId,
      mensaje: 'Tu Visibilidad Premium fue aprobada para "${_truncar(peticion.descripcion)}"',
      peticionId: peticionId,
    );
    unawaited(_guardarEstado());
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

  void marcarTodasNotificacionesLeidas() {
    for (final n in misNotificaciones) {
      n.leida = true;
    }
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void eliminarNotificacion(String id) {
    notificaciones.removeWhere((n) => n.id == id);
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void crearReporte({required String tipo, required String contraId, required String motivo, String? comentario}) {
    final usuario = usuarioActual;
    if (usuario == null) return;
    reportes.add(Reporte(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deUsuarioId: usuario.id,
      tipo: tipo,
      contraId: contraId,
      motivo: motivo,
      comentario: comentario,
      fecha: DateTime.now(),
    ));
    notifyListeners();
    unawaited(_guardarEstado());
  }
}
