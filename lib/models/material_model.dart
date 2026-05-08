/// Modelo completo de Material que corresponde con el backend
class Material {
  final int id;
  final String nombre;
  final String? descripcion;
  final String unidadMedida;
  final double? precioUnitario;
  final double stockActual;
  final double stockReferencia;
  final String usuarioCreador;
  final String fechaCreacion;

  const Material({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.unidadMedida,
    this.precioUnitario,
    required this.stockActual,
    required this.stockReferencia,
    required this.usuarioCreador,
    required this.fechaCreacion,
  });

  factory Material.fromJson(Map<String, dynamic> json) => Material(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'] ?? '',
    descripcion: json['descripcion'],
    unidadMedida: json['unidadMedida'] ?? '',
    precioUnitario: json['precioUnitario'] != null
        ? (json['precioUnitario'] as num).toDouble()
        : null,
    stockActual: (json['stockActual'] as num).toDouble(),
    stockReferencia: (json['stockReferencia'] as num).toDouble(),
    usuarioCreador: json['usuarioCreador'] ?? 'system',
    fechaCreacion: json['fechaCreacion'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'unidadMedida': unidadMedida,
    'precioUnitario': precioUnitario,
    'stockActual': stockActual,
    'stockReferencia': stockReferencia,
    'usuarioCreador': usuarioCreador,
    'fechaCreacion': fechaCreacion,
  };

  DateTime get fechaCreacionDate => DateTime.parse(fechaCreacion);
}

/// Alerta de Material con stock bajo
class AlertaMaterial {
  final int id;
  final String nombre;
  final String mensaje;
  final int stockActual;
  final int stockReferencia;
  final String unidadMedida;

  const AlertaMaterial({
    required this.id,
    required this.nombre,
    required this.mensaje,
    required this.stockActual,
    required this.stockReferencia,
    required this.unidadMedida,
  });

  factory AlertaMaterial.fromJson(Map<String, dynamic> json) => AlertaMaterial(
    id: json['id'],
    nombre: json['nombre'] ?? '',
    mensaje: json['mensaje'] ?? '',
    stockActual: (json['stockActual'] as num).toInt(),
    stockReferencia: (json['stockReferencia'] as num).toInt(),
    unidadMedida: json['unidadMedida'] ?? '',
  );

  double get porcentaje => (stockReferencia > 0)
      ? (stockActual / stockReferencia).clamp(0.0, 1.0)
      : 0.0;
}

/// Versión simplificada de Material para listas
class MaterialItem {
  final int id;
  final String nombre;
  final double? stockActual;
  final String unidadMedida;

  const MaterialItem({
    required this.id,
    required this.nombre,
    required this.stockActual,
    required this.unidadMedida,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'] ?? '',
    stockActual: json['stockActual'] != null
        ? (json['stockActual'] as num).toDouble()
        : null,
    unidadMedida: json['unidadMedida'] ?? '',
  );
}

