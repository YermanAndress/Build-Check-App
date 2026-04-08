class MovimientoResumen {
  final String tipoMovimiento;
  final DateTime fecha;
  final double cantidad;
  final int? materialId;
  final String materialNombre;
  final String unidadMedida;
  final DateTime fechaCreacion;

  const MovimientoResumen({
    required this.tipoMovimiento,
    required this.fecha,
    required this.cantidad,
    required this.fechaCreacion,
    this.materialId,
    this.materialNombre = '',
    this.unidadMedida = '',
  });

  factory MovimientoResumen.fromJson(Map<String, dynamic> json) {
    return MovimientoResumen(
      tipoMovimiento: json['tipoMovimiento'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime(2000),
      fechaCreacion: DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime(2000),
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      materialId: json['materialId'] as int?,
    );
  }

  MovimientoResumen conMaterial(String nombre, String unidad) =>
      MovimientoResumen(
        tipoMovimiento: tipoMovimiento,
        fecha: fecha,
        fechaCreacion: fechaCreacion,
        cantidad: cantidad,
        materialId: materialId,
        materialNombre: nombre,
        unidadMedida: unidad,
      );

  String get detalle {
    final cantStr = cantidad % 1 == 0 ? cantidad.toInt().toString() : cantidad.toString();
    final diff = DateTime.now().difference(fecha);
    String tiempo;
    if (diff.inMinutes < 60) {
      tiempo = 'Hace ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      tiempo = 'Hace ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      tiempo = 'Ayer';
    } else {
      tiempo = 'Hace ${diff.inDays}d';
    }
    return '$cantStr ${unidadMedida.trim()} | $tiempo';
  }
}