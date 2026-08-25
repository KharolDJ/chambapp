class Notificacion {
  final String id;
  final String paraUsuarioId;
  final String mensaje;
  final DateTime fecha;
  final String? peticionId;
  bool leida;

  Notificacion({
    required this.id,
    required this.paraUsuarioId,
    required this.mensaje,
    required this.fecha,
    this.peticionId,
    this.leida = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'paraUsuarioId': paraUsuarioId,
        'mensaje': mensaje,
        'fecha': fecha.toIso8601String(),
        'peticionId': peticionId,
        'leida': leida,
      };

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'] as String,
        paraUsuarioId: json['paraUsuarioId'] as String,
        mensaje: json['mensaje'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        peticionId: json['peticionId'] as String?,
        leida: json['leida'] as bool? ?? false,
      );
}
