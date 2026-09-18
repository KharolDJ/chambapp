class PremiumTrabajador {
  final String id;
  final String usuarioId;
  final String oficio;
  final bool solicitada;
  final bool aprobada;
  final String? comprobantePago;
  final DateTime solicitadaEn;
  final DateTime? expiraEn;

  /// Snapshot del trabajador tomado al momento de solicitar, igual que
  /// [Peticion.interesados] — evita depender de `todosLosUsuarios` (que
  /// solo se sincroniza con sesión activa) para poder mostrar el Podio de
  /// Recomendados a cualquiera que explore el feed sin cuenta. Puede quedar
  /// levemente desactualizado si la calificación del trabajador cambia
  /// después de solicitar (mismo trade-off ya aceptado para interesados).
  final String usuarioNombre;
  final String? usuarioFotoPath;
  final double calificacionPromedio;
  final int numeroCalificaciones;

  PremiumTrabajador({
    required this.id,
    required this.usuarioId,
    required this.oficio,
    this.solicitada = false,
    this.aprobada = false,
    this.comprobantePago,
    required this.solicitadaEn,
    this.expiraEn,
    required this.usuarioNombre,
    this.usuarioFotoPath,
    this.calificacionPromedio = 0,
    this.numeroCalificaciones = 0,
  });

  bool get activo =>
      aprobada && expiraEn != null && expiraEn!.isAfter(DateTime.now());

  /// Serializa para guardar como documento de Firestore (colección
  /// `premiumTrabajador`). El id del documento es el propio [id] de esta
  /// clase — no se repite dentro del mapa.
  Map<String, dynamic> toFirestore() => {
    'usuarioId': usuarioId,
    'oficio': oficio,
    'solicitada': solicitada,
    'aprobada': aprobada,
    'comprobantePago': comprobantePago,
    'solicitadaEn': solicitadaEn.toIso8601String(),
    'expiraEn': expiraEn?.toIso8601String(),
    'usuarioNombre': usuarioNombre,
    'usuarioFotoPath': usuarioFotoPath,
    'calificacionPromedio': calificacionPromedio,
    'numeroCalificaciones': numeroCalificaciones,
  };

  factory PremiumTrabajador.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) => PremiumTrabajador(
    id: id,
    usuarioId: data['usuarioId'] as String,
    oficio: data['oficio'] as String,
    solicitada: data['solicitada'] as bool? ?? false,
    aprobada: data['aprobada'] as bool? ?? false,
    comprobantePago: data['comprobantePago'] as String?,
    solicitadaEn: DateTime.parse(data['solicitadaEn'] as String),
    expiraEn: data['expiraEn'] != null
        ? DateTime.parse(data['expiraEn'] as String)
        : null,
    usuarioNombre: data['usuarioNombre'] as String? ?? 'Usuario',
    usuarioFotoPath: data['usuarioFotoPath'] as String?,
    calificacionPromedio:
        (data['calificacionPromedio'] as num?)?.toDouble() ?? 0,
    numeroCalificaciones: (data['numeroCalificaciones'] as num?)?.toInt() ?? 0,
  );
}
