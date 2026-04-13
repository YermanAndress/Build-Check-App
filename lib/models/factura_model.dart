class Factura {
  final int? id;
  final String? numeroFactura;
  final DateTime fecha;
  final String? proveedor;
  final double? valorTotal;
  final int proyectoId;
  final String? urlImagen;

  Factura({
    this.id,
    this.numeroFactura,
    required this.fecha,
    this.proveedor,
    this.valorTotal,
    required this.proyectoId,
    this.urlImagen,
  });

  // Convertir JSON a Objeto
  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['id'],
      numeroFactura: json['numeroFactura']?.toString() ?? '',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'].toString())
          : DateTime.now(),
      proveedor: json['proveedor']?.toString() ?? 'Sin proveedor',
      valorTotal: json['valorTotal'] != null
          ? double.tryParse(json['valorTotal'].toString()) ?? 0.0
          : 0.0,
      proyectoId: int.tryParse(json['proyectoId']?.toString() ?? '1') ?? 1,
      urlImagen: json['urlImagen']?.toString(),
    );
  }

  // Convertir Objeto a JSON para el body del POST
  Map<String, dynamic> toJson() => {
    'numeroFactura': numeroFactura,
    'fecha':
        "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}",
    'proveedor': proveedor,
    'valorTotal': valorTotal,
    'proyectoId': proyectoId,
  };
}