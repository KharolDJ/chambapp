class Usuario {
  final String id;
  String nombre;
  final String correo;
  String celular;
  String? oficio;
  String? fotoPath;
  double calificacionPromedio;
  int numeroCalificaciones;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.celular,
    this.oficio,
    this.fotoPath,
    this.calificacionPromedio = 0,
    this.numeroCalificaciones = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'correo': correo,
        'celular': celular,
        'oficio': oficio,
        'fotoPath': fotoPath,
        'calificacionPromedio': calificacionPromedio,
        'numeroCalificaciones': numeroCalificaciones,
      };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        celular: json['celular'] as String,
        oficio: json['oficio'] as String?,
        fotoPath: json['fotoPath'] as String?,
        calificacionPromedio: (json['calificacionPromedio'] as num?)?.toDouble() ?? 0,
        numeroCalificaciones: (json['numeroCalificaciones'] as num?)?.toInt() ?? 0,
      );
}
