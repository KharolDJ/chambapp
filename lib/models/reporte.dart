class Reporte {
  final String id;
  final String deUsuarioId;
  final String tipo;
  final String contraId;
  final String motivo;
  final String? comentario;
  final DateTime fecha;

  Reporte({
    required this.id,
    required this.deUsuarioId,
    required this.tipo,
    required this.contraId,
    required this.motivo,
    this.comentario,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deUsuarioId': deUsuarioId,
    'tipo': tipo,
    'contraId': contraId,
    'motivo': motivo,
    'comentario': comentario,
    'fecha': fecha.toIso8601String(),
  };

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
    id: json['id'] as String,
    deUsuarioId: json['deUsuarioId'] as String,
    tipo: json['tipo'] as String,
    contraId: json['contraId'] as String,
    motivo: json['motivo'] as String,
    comentario: json['comentario'] as String?,
    fecha: DateTime.parse(json['fecha'] as String),
  );

  /// Serializa para guardar como documento de Firestore (colección
  /// `reportes`). El id del documento es el propio [id] de esta clase — no
  /// se repite dentro del mapa.
  Map<String, dynamic> toFirestore() => {
    'deUsuarioId': deUsuarioId,
    'tipo': tipo,
    'contraId': contraId,
    'motivo': motivo,
    'comentario': comentario,
    'fecha': fecha.toIso8601String(),
  };

  factory Reporte.fromFirestore(Map<String, dynamic> data, String id) =>
      Reporte(
        id: id,
        deUsuarioId: data['deUsuarioId'] as String,
        tipo: data['tipo'] as String,
        contraId: data['contraId'] as String,
        motivo: data['motivo'] as String,
        comentario: data['comentario'] as String?,
        fecha: DateTime.parse(data['fecha'] as String),
      );
}
