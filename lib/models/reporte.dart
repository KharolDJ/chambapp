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
}
