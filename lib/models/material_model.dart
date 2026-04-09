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

class MaterialItem {
  final int id;
  final String nombre;
  final int? stockActual;
  final String unidadMedida;

  const MaterialItem({
    required this.id,
    required this.nombre,
    required this.stockActual,
    required this.unidadMedida,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    id: json['id'],
    nombre: json['nombre'],
    stockActual: json['stockActual'] != null
        ? (json['stockActual'] as num).toInt()
        : null,
    unidadMedida: json['unidadMedida'] ?? '',
  );
}
