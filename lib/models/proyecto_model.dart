class Proyecto {
  final int? id;
  final String nombre;
  final String descripcion;
  final String ubicacion;
  final double presupuesto;
  final String estado;
  final DateTime fechaCreacion;
  final String? rolProyecto;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.ubicacion,
    required this.presupuesto,
    required this.estado,
    required this.fechaCreacion,
    this.rolProyecto,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'].toString(),
      descripcion: json['descripcion'].toString(),
      ubicacion: json['ubicacion'].toString(),
      presupuesto: (json['presupuesto'] as num).toDouble(),
      estado: json['estado'].toString(),
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime(2000),
      rolProyecto:
          json['rolDelUsuario'] as String? ?? json['rolProyecto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'presupuesto': presupuesto,
      'estado': estado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
    return json;
  }
}
