class Material {
  final int id;
  final String nombre;
  final String? descripcion;
  final String unidadMedida;
  final double? precioUnitario;
  final double stockActual;
  final double stockReferencia;
  final DateTime? fechaCreacion;

  const Material({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.unidadMedida,
    this.precioUnitario,
    required this.stockActual,
    required this.stockReferencia,
    this.fechaCreacion,
  });

  factory Material.fromJson(Map<String, dynamic> json) => Material(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'].toString(),
    descripcion: json['descripcion']?.toString(),
    unidadMedida: json['unidadMedida'].toString(),
    precioUnitario: (json['precioUnitario'] as num?)?.toDouble(),
    stockActual: (json['stockActual'] as num).toDouble(),
    stockReferencia: (json['stockReferencia'] as num).toDouble(),
    fechaCreacion: json['fechaCreacion'] != null
        ? DateTime.parse(json['fechaCreacion'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'unidadMedida': unidadMedida,
    'precioUnitario': precioUnitario,
    'stockActual': stockActual,
    'stockReferencia': stockReferencia,
    'fechaCreacion': fechaCreacion,
  };
}

class AlertaMaterial {
  final int id;
  final String nombre;
  final String mensaje;
  final double stockActual;
  final double stockReferencia;
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
    id: (json['id'] as int).toInt(),
    nombre: json['nombre'].toString(),
    mensaje: json['mensaje'].toString(),
    stockActual: (json['stockActual'] as num).toDouble(),
    stockReferencia: (json['stockReferencia'] as num).toDouble(),
    unidadMedida: json['unidadMedida'].toString(),
  );

  double get porcentaje => (stockReferencia > 0)
      ? (stockActual / stockReferencia).clamp(0.0, 1.0)
      : 0.0;
}

class MaterialItem {
  final int id;
  final String nombre;
  final double stockActual;
  final String unidadMedida;
  final DateTime? fechaCreacion;

  const MaterialItem({
    required this.id,
    required this.nombre,
    required this.stockActual,
    required this.unidadMedida,
    this.fechaCreacion,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'].toString(),
    stockActual: (json['stockActual'] as num).toDouble(),
    unidadMedida: json['unidadMedida'].toString(),
    fechaCreacion: json['fechaCreacion'] != null
        ? DateTime.parse(json['fechaCreacion'].toString())
        : null,
  );
}
