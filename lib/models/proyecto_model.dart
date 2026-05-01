class Proyecto {
  final int id;
  final String nombre;
  final String descripcion;
  final String ubicacion;
  final double presupuesto;
  final String estado;
  final String fechaCreacion;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.ubicacion,
    required this.presupuesto,
    required this.estado,
    required this.fechaCreacion,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      ubicacion: json['ubicacion'],
      presupuesto: (json['presupuesto'] as num).toDouble(),
      estado: json['estado'],
      fechaCreacion: json['fechaCreacion'],
    );
  }
}
