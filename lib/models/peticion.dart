import 'usuario.dart';

class Peticion {
  final String id;
  final String autorId;
  final String autorNombre;
  final String barrio;
  final String descripcion;
  final String categoria;
  final bool urgente;
  final String? fotoUrl;
  final DateTime creadaEn;
  final double? lat;
  final double? lng;
  final List<Usuario> interesados;
  final Set<String> vistosPorEmpleador;
  String? trabajadorSeleccionadoId;
  bool cerrada;
  bool premiumSolicitada;
  bool premiumAprobada;
  String? comprobantePago;
  bool archivada;

  Peticion({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.barrio,
    required this.descripcion,
    required this.categoria,
    this.urgente = false,
    this.fotoUrl,
    required this.creadaEn,
    this.lat,
    this.lng,
    List<Usuario>? interesados,
    Set<String>? vistosPorEmpleador,
    this.trabajadorSeleccionadoId,
    this.cerrada = false,
    this.premiumSolicitada = false,
    this.premiumAprobada = false,
    this.comprobantePago,
    this.archivada = false,
  }) : interesados = interesados ?? [],
       vistosPorEmpleador = vistosPorEmpleador ?? {};

  /// Snapshot denormalizado de un interesado, tal como se guarda dentro del
  /// documento de la petición en Firestore. Evita tener que leer el
  /// documento `usuarios/{id}` de cada interesado solo para mostrar su
  /// tarjeta en la pantalla de Interesados — a cambio, la calificación
  /// mostrada ahí puede quedar levemente desactualizada si cambia después
  /// de que esa persona aplicó a esta petición específica (trade-off
  /// aceptado para el prototipo).
  static Map<String, dynamic> interesadoAMapa(Usuario u) => {
    'id': u.id,
    'nombre': u.nombre,
    'celular': u.celular,
    'oficios': u.oficios,
    'calificacionPromedio': u.calificacionPromedio,
    'numeroCalificaciones': u.numeroCalificaciones,
    'fotoPath': u.fotoPath,
  };

  static Usuario _interesadoDesdeMapa(Map<String, dynamic> m) => Usuario(
    id: m['id'] as String,
    nombre: m['nombre'] as String,
    correo: '',
    celular: m['celular'] as String? ?? '',
    oficios: (m['oficios'] as List?)?.cast<String>(),
    fotoPath: m['fotoPath'] as String?,
    calificacionPromedio: (m['calificacionPromedio'] as num?)?.toDouble() ?? 0,
    numeroCalificaciones: (m['numeroCalificaciones'] as num?)?.toInt() ?? 0,
  );

  /// Serializa para guardar como documento de Firestore (colección
  /// `peticiones`). El id del documento es el propio [id] de esta clase —
  /// no se repite dentro del mapa.
  Map<String, dynamic> toFirestore() => {
    'autorId': autorId,
    'autorNombre': autorNombre,
    'barrio': barrio,
    'descripcion': descripcion,
    'categoria': categoria,
    'urgente': urgente,
    'fotoUrl': fotoUrl,
    'creadaEn': creadaEn.toIso8601String(),
    'lat': lat,
    'lng': lng,
    'interesados': interesados.map(interesadoAMapa).toList(),
    'vistosPorEmpleador': vistosPorEmpleador.toList(),
    'trabajadorSeleccionadoId': trabajadorSeleccionadoId,
    'cerrada': cerrada,
    'premiumSolicitada': premiumSolicitada,
    'premiumAprobada': premiumAprobada,
    'comprobantePago': comprobantePago,
    'archivada': archivada,
  };

  factory Peticion.fromFirestore(Map<String, dynamic> data, String id) {
    final interesadosRaw = (data['interesados'] as List?) ?? const [];
    return Peticion(
      id: id,
      autorId: data['autorId'] as String,
      autorNombre: data['autorNombre'] as String,
      barrio: data['barrio'] as String,
      descripcion: data['descripcion'] as String,
      categoria: data['categoria'] as String,
      urgente: data['urgente'] as bool? ?? false,
      fotoUrl: data['fotoUrl'] as String?,
      creadaEn: DateTime.parse(data['creadaEn'] as String),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      interesados: interesadosRaw
          .map((m) => _interesadoDesdeMapa(Map<String, dynamic>.from(m as Map)))
          .toList(),
      vistosPorEmpleador: ((data['vistosPorEmpleador'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      trabajadorSeleccionadoId: data['trabajadorSeleccionadoId'] as String?,
      cerrada: data['cerrada'] as bool? ?? false,
      premiumSolicitada: data['premiumSolicitada'] as bool? ?? false,
      premiumAprobada: data['premiumAprobada'] as bool? ?? false,
      comprobantePago: data['comprobantePago'] as String?,
      archivada: data['archivada'] as bool? ?? false,
    );
  }
}
