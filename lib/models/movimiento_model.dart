class MovimientoResumen {
  final int id;
  final String tipoMovimiento;
  final DateTime fecha;
  final double cantidad;
  final int materialId;
  final int proyectoId;
  final String materialNombre;
  final String unidadMedida;
  final DateTime fechaCreacion;

  const MovimientoResumen({
    required this.id,
    required this.tipoMovimiento,
    required this.fecha,
    required this.cantidad,
    required this.fechaCreacion,
    required this.materialId,
    required this.proyectoId,
    required this.materialNombre,
    required this.unidadMedida,
  });

  String get descripcionFormateada {
    final valor = cantidad % 1 == 0 ? cantidad.toInt() : cantidad;
    return '$valor ${unidadMedida.trim()}';
  }

  factory MovimientoResumen.fromJson(Map<String, dynamic> json) {
    return MovimientoResumen(
      id: (json['id'] as num).toInt(),
      tipoMovimiento: json['tipoMovimiento'].toString(),
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime(2000),
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime(2000),
      cantidad: (json['cantidad'] as num).toDouble(),
      materialId: (json['materialId'] as num).toInt(),
      proyectoId: (json['proyectoId'] as num).toInt(),
      materialNombre: json['materialNombre'].toString(),
      unidadMedida: json['unidadMedida'].toString(),
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
