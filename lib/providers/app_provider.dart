import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/peticion.dart';
import '../models/usuario.dart';
import '../models/calificacion.dart';
import '../models/notificacion.dart';
import '../models/reporte.dart';

enum RolUsuario { empleador, trabajador }

// Persistencia local temporal (solo este dispositivo, no sincroniza entre
// celulares). Se reemplaza por Firebase Auth + Firestore en la Fase B.
class AppProvider extends ChangeNotifier {
  static const _claveUsuarios = 'chambapp_usuarios';
  static const _claveRol = 'chambapp_rol_actual';
  static const _claveUsuarioActualId = 'chambapp_usuario_actual_id';
  static const _claveNotificaciones = 'chambapp_notificaciones_activas';
  static const _claveRadio = 'chambapp_radio_busqueda_km';
  static const _claveNotificacionesLista = 'chambapp_notificaciones';
  static const _clavePeticiones = 'chambapp_peticiones';
  static const _claveCalificaciones = 'chambapp_calificaciones';
  static const _claveReportes = 'chambapp_reportes';

  RolUsuario? rolActual;
  Usuario? usuarioActual;
  bool notificacionesActivas = true;
  double radioBusquedaKm = 50;

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

  final List<Calificacion> calificaciones = [
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
  final List<Notificacion> notificaciones = [];
  final List<Reporte> reportes = [];

  late final List<Peticion> peticiones = [
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

    final usuarioId = prefs.getString(_claveUsuarioActualId);
    if (usuarioId != null) {
      try {
        usuarioActual = usuarios.firstWhere((u) => u.id == usuarioId);
      } catch (_) {
        usuarioActual = null;
      }
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

    // Las peticiones se restauran después de usuarios, ya que necesitan
    // resolver a los mismos objetos Usuario para los interesados.
    final peticionesJson = prefs.getString(_clavePeticiones);
    if (peticionesJson != null) {
      final lista = (jsonDecode(peticionesJson) as List)
          .map((e) => Peticion.fromJson(e as Map<String, dynamic>, usuarios))
          .toList();
      peticiones
        ..clear()
        ..addAll(lista);
    }

    final calificacionesJson = prefs.getString(_claveCalificaciones);
    if (calificacionesJson != null) {
      final lista = (jsonDecode(calificacionesJson) as List)
          .map((e) => Calificacion.fromJson(e as Map<String, dynamic>))
          .toList();
      calificaciones
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

    notifyListeners();
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

    if (usuarioActual != null) {
      await prefs.setString(_claveUsuarioActualId, usuarioActual!.id);
    } else {
      await prefs.remove(_claveUsuarioActualId);
    }

    await prefs.setBool(_claveNotificaciones, notificacionesActivas);
    await prefs.setDouble(_claveRadio, radioBusquedaKm);

    final notificacionesJson = jsonEncode(notificaciones.map((n) => n.toJson()).toList());
    await prefs.setString(_claveNotificacionesLista, notificacionesJson);

    final peticionesJson = jsonEncode(peticiones.map((p) => p.toJson()).toList());
    await prefs.setString(_clavePeticiones, peticionesJson);

    final calificacionesJson = jsonEncode(calificaciones.map((c) => c.toJson()).toList());
    await prefs.setString(_claveCalificaciones, calificacionesJson);

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

  void registrarUsuario(Usuario usuario) {
    final existente = usuarios.any((u) => u.id == usuario.id);
    if (!existente) {
      usuarios.add(usuario);
    }
    usuarioActual = usuario;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void actualizarPerfil({
    required String nombre,
    required String celular,
    List<String>? oficios,
    String? fotoPath,
    String? cedula,
  }) {
    final actual = usuarioActual;
    if (actual == null) return;
    actual.nombre = nombre;
    actual.celular = celular;
    actual.oficios = oficios ?? [];
    if (fotoPath != null) actual.fotoPath = fotoPath;
    if (cedula != null) actual.cedula = cedula;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void cerrarSesion() {
    rolActual = null;
    usuarioActual = null;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void eliminarCuentaActual() {
    final actual = usuarioActual;
    if (actual == null) return;
    usuarios.removeWhere((u) => u.id == actual.id);
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

  Usuario? buscarPorCorreo(String correo) {
    final normalizado = correo.trim().toLowerCase();
    try {
      return usuarios.firstWhere((u) => u.correo.trim().toLowerCase() == normalizado);
    } catch (_) {
      return null;
    }
  }

  void iniciarSesion(Usuario usuario) {
    usuarioActual = usuario;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void publicarPeticion(Peticion peticion) {
    peticiones.insert(0, peticion);
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void marcarInteres(String peticionId) {
    final usuario = usuarioActual;
    assert(usuario != null, 'No se puede marcar interés sin un usuario registrado');
    if (usuario == null) return;

    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    final yaInteresado = peticion.interesados.any((u) => u.id == usuario.id);
    if (yaInteresado) {
      // Ya fue seleccionado por el empleador para este trabajo: no puede
      // retirar su interés (dejaría a trabajadorSeleccionadoId apuntando a
      // alguien fuera de la lista de interesados, y rompería la pantalla de
      // "Calificar al trabajador" más adelante).
      if (peticion.trabajadorSeleccionadoId == usuario.id) return;
      peticion.interesados.removeWhere((u) => u.id == usuario.id);
    } else {
      peticion.interesados.add(usuario);
      _crearNotificacion(
        paraUsuarioId: peticion.autorId,
        mensaje: '${usuario.nombre} se interesó en tu publicación "${_truncar(peticion.descripcion)}"',
        peticionId: peticion.id,
      );
    }
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void marcarVistoPorEmpleador(String peticionId) {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    final nuevos = peticion.interesados
        .map((u) => u.id)
        .where((id) => !peticion.vistosPorEmpleador.contains(id));
    for (final id in nuevos) {
      _crearNotificacion(
        paraUsuarioId: id,
        mensaje: 'El empleador vio tu perfil en "${_truncar(peticion.descripcion)}"',
        peticionId: peticion.id,
      );
    }
    peticion.vistosPorEmpleador.addAll(peticion.interesados.map((u) => u.id));
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void seleccionarTrabajador(String peticionId, String usuarioId) {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    peticion.trabajadorSeleccionadoId = usuarioId;
    _crearNotificacion(
      paraUsuarioId: usuarioId,
      mensaje:
          '¡Fuiste seleccionado para "${_truncar(peticion.descripcion)}"! El empleador te contactará por WhatsApp',
      peticionId: peticionId,
    );
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void cerrarPeticion(String peticionId) {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    peticion.cerrada = true;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void calificarUsuario(Calificacion calificacion) {
    calificaciones.add(calificacion);
    _crearNotificacion(
      paraUsuarioId: calificacion.paraUsuarioId,
      mensaje: 'Recibiste una calificación de ${calificacion.estrellas} estrellas',
    );

    final calificacionesDelUsuario =
        calificaciones.where((c) => c.paraUsuarioId == calificacion.paraUsuarioId).toList();
    final promedio =
        calificacionesDelUsuario.map((c) => c.estrellas).reduce((a, b) => a + b) /
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
    unawaited(_guardarEstado());
  }

  void solicitarPremium(String peticionId, String comprobante) {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    peticion.premiumSolicitada = true;
    peticion.comprobantePago = comprobante;
    notifyListeners();
    unawaited(_guardarEstado());
  }

  void aprobarPremiumDemo(String peticionId) {
    final peticion = peticiones.firstWhere((p) => p.id == peticionId);
    peticion.premiumAprobada = true;
    _crearNotificacion(
      paraUsuarioId: peticion.autorId,
      mensaje: 'Tu Visibilidad Premium fue aprobada para "${_truncar(peticion.descripcion)}"',
      peticionId: peticionId,
    );
    notifyListeners();
    unawaited(_guardarEstado());
  }

  bool yaCalifique({required String deUsuarioId, required String peticionId}) => calificaciones
      .any((c) => c.deUsuarioId == deUsuarioId && c.peticionId == peticionId);

  List<Peticion> get misPublicaciones =>
      peticiones.where((p) => p.autorId == usuarioActual?.id).toList();

  List<Peticion> get misIntereses => peticiones
      .where((p) => p.interesados.any((u) => u.id == usuarioActual?.id))
      .toList();

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
