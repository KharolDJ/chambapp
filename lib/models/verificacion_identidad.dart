class VerificacionIdentidad {
  /// Igual al [usuarioId] — cada persona tiene como máximo una verificación
  /// vigente, así que no hace falta un id aleatorio como en
  /// `PremiumTrabajador` (que sí permite varias solicitudes, una por oficio).
  final String id;
  final String usuarioId;
  final String numeroCedula;
  final String fotoCedulaPath;
  final bool solicitada;
  final bool aprobada;
  final DateTime solicitadaEn;

  VerificacionIdentidad({
    required this.id,
    required this.usuarioId,
    required this.numeroCedula,
    required this.fotoCedulaPath,
    this.solicitada = false,
    this.aprobada = false,
    required this.solicitadaEn,
  });

  /// Serializa para guardar como documento de Firestore (colección
  /// `verificacionesIdentidad`, separada de `usuarios` a propósito: la foto
  /// de la cédula es más sensible que el resto del perfil y no debe
  /// sincronizarse con el directorio completo de usuarios que alimenta la
  /// búsqueda de personas). El id del documento es el propio [id].
  Map<String, dynamic> toFirestore() => {
    'usuarioId': usuarioId,
    'numeroCedula': numeroCedula,
    'fotoCedulaPath': fotoCedulaPath,
    'solicitada': solicitada,
    'aprobada': aprobada,
    'solicitadaEn': solicitadaEn.toIso8601String(),
  };

  factory VerificacionIdentidad.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) => VerificacionIdentidad(
    id: id,
    usuarioId: data['usuarioId'] as String,
    numeroCedula: data['numeroCedula'] as String,
    fotoCedulaPath: data['fotoCedulaPath'] as String,
    solicitada: data['solicitada'] as bool? ?? false,
    aprobada: data['aprobada'] as bool? ?? false,
    solicitadaEn: DateTime.parse(data['solicitadaEn'] as String),
  );
}
