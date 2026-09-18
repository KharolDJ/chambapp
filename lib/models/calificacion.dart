class Calificacion {
  final String id;
  final String deUsuarioId;
  final String paraUsuarioId;
  final int estrellas;
  final String? comentario;
  final DateTime fecha;
  final String? peticionId;

  Calificacion({
    required this.id,
    required this.deUsuarioId,
    required this.paraUsuarioId,
    required this.estrellas,
    this.comentario,
    required this.fecha,
    this.peticionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deUsuarioId': deUsuarioId,
    'paraUsuarioId': paraUsuarioId,
    'estrellas': estrellas,
    'comentario': comentario,
    'fecha': fecha.toIso8601String(),
    'peticionId': peticionId,
  };

  factory Calificacion.fromJson(Map<String, dynamic> json) => Calificacion(
    id: json['id'] as String,
    deUsuarioId: json['deUsuarioId'] as String,
    paraUsuarioId: json['paraUsuarioId'] as String,
    estrellas: json['estrellas'] as int,
    comentario: json['comentario'] as String?,
    fecha: DateTime.parse(json['fecha'] as String),
    peticionId: json['peticionId'] as String?,
  );
}
