class Usuario {
  final String id;
  String nombre;
  final String correo;
  String celular;
  List<String> oficios;
  String? fotoPath;
  String? cedula;
  String? barrio;
  bool perfilVerificado;
  double calificacionPromedio;
  int numeroCalificaciones;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.celular,
    List<String>? oficios,
    this.fotoPath,
    this.cedula,
    this.barrio,
    this.perfilVerificado = false,
    this.calificacionPromedio = 0,
    this.numeroCalificaciones = 0,
  }) : oficios = oficios ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'celular': celular,
    'oficios': oficios,
    'fotoPath': fotoPath,
    'cedula': cedula,
    'barrio': barrio,
    'perfilVerificado': perfilVerificado,
    'calificacionPromedio': calificacionPromedio,
    'numeroCalificaciones': numeroCalificaciones,
  };

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Migracion desde el campo viejo `oficio` (String unico) a `oficios`
    // (lista), para no perder datos ya guardados en el dispositivo.
    List<String> oficios;
    if (json['oficios'] != null) {
      oficios = (json['oficios'] as List).cast<String>();
    } else if (json['oficio'] != null) {
      oficios = [json['oficio'] as String];
    } else {
      oficios = [];
    }

    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      celular: json['celular'] as String,
      oficios: oficios,
      fotoPath: json['fotoPath'] as String?,
      cedula: json['cedula'] as String?,
      barrio: json['barrio'] as String?,
      perfilVerificado: json['perfilVerificado'] as bool? ?? false,
      calificacionPromedio:
          (json['calificacionPromedio'] as num?)?.toDouble() ?? 0,
      numeroCalificaciones:
          (json['numeroCalificaciones'] as num?)?.toInt() ?? 0,
    );
  }
}
