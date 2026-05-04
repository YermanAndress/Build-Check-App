class MovimientoResumen {
  final int? id; // ← Necesario para el PUT /movimientos/{id}
  final String tipoMovimiento;
  final DateTime fecha;
  final double cantidad;
  final int? materialId;
  final int? proyectoId; // ← Requerido por MovimientoRequest
  final String materialNombre;
  final String unidadMedida;
  final DateTime fechaCreacion;

  const MovimientoResumen({
    this.id,
    required this.tipoMovimiento,
    required this.fecha,
    required this.cantidad,
    required this.fechaCreacion,
    this.materialId,
    this.proyectoId,
    this.materialNombre = '',
    this.unidadMedida = '',
  });

  String get descripcionFormateada {
    final valor = cantidad % 1 == 0 ? cantidad.toInt() : cantidad;
    return '$valor ${unidadMedida.trim()}';
  }

  factory MovimientoResumen.fromJson(Map<String, dynamic> json) {
    return MovimientoResumen(
      id: json['id'] as int?,
      tipoMovimiento: json['tipoMovimiento'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime(2000),
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime(2000),
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      materialId: json['materialId'] as int?,
      proyectoId: json['proyectoId'] as int?,
    );
  }

  MovimientoResumen conMaterial(String nombre, String unidad) =>
      MovimientoResumen(
        id: id,
        tipoMovimiento: tipoMovimiento,
        fecha: fecha,
        fechaCreacion: fechaCreacion,
        cantidad: cantidad,
        materialId: materialId,
        proyectoId: proyectoId,
        materialNombre: nombre,
        unidadMedida: unidad,
      );

  String tiempoRelativo(DateTime momentoActual) {
    final diff = momentoActual.difference(fechaCreacion);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays}d';
  }
}