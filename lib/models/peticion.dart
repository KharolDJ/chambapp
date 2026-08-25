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
  }) : interesados = interesados ?? [],
       vistosPorEmpleador = vistosPorEmpleador ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
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
        'interesadosIds': interesados.map((u) => u.id).toList(),
        'vistosPorEmpleador': vistosPorEmpleador.toList(),
        'trabajadorSeleccionadoId': trabajadorSeleccionadoId,
        'cerrada': cerrada,
        'premiumSolicitada': premiumSolicitada,
        'premiumAprobada': premiumAprobada,
        'comprobantePago': comprobantePago,
      };

  /// [usuariosDisponibles] se usa para resolver los interesados (guardados
  /// solo como id) de vuelta a los objetos `Usuario` reales ya cargados.
  /// Un id que ya no exista (ej. cuenta eliminada) se omite en silencio.
  factory Peticion.fromJson(Map<String, dynamic> json, List<Usuario> usuariosDisponibles) {
    Usuario? buscar(String id) {
      for (final u in usuariosDisponibles) {
        if (u.id == id) return u;
      }
      return null;
    }

    final interesadosIds = (json['interesadosIds'] as List).cast<String>();
    return Peticion(
      id: json['id'] as String,
      autorId: json['autorId'] as String,
      autorNombre: json['autorNombre'] as String,
      barrio: json['barrio'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      urgente: json['urgente'] as bool? ?? false,
      fotoUrl: json['fotoUrl'] as String?,
      creadaEn: DateTime.parse(json['creadaEn'] as String),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      interesados: interesadosIds.map(buscar).whereType<Usuario>().toList(),
      vistosPorEmpleador: (json['vistosPorEmpleador'] as List).cast<String>().toSet(),
      trabajadorSeleccionadoId: json['trabajadorSeleccionadoId'] as String?,
      cerrada: json['cerrada'] as bool? ?? false,
      premiumSolicitada: json['premiumSolicitada'] as bool? ?? false,
      premiumAprobada: json['premiumAprobada'] as bool? ?? false,
      comprobantePago: json['comprobantePago'] as String?,
    );
  }
}
