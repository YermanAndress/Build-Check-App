class Factura {
  final int? id;
  final String? numeroFactura;
  final DateTime fecha;
  final String proveedor;
  final String? observaciones;
  final double? valorTotal;
  final int proyectoId;
  final String? urlImagen;
  final List<FacturaMaterialItem> items;

  Factura({
    this.id,
    this.numeroFactura,
    required this.fecha,
    required this.proveedor,
    this.observaciones,
    this.valorTotal,
    required this.proyectoId,
    this.urlImagen,
    this.items = const [],
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List?;
    List<FacturaMaterialItem> itemsList = list != null
        ? list.map((i) => FacturaMaterialItem.fromJson(i)).toList()
        : [];

    return Factura(
      id: json['id'],
      numeroFactura: json['numeroFactura']?.toString() ?? '',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'].toString())
          : DateTime.now(),
      proveedor: json['proveedor']?.toString() ?? 'Sin proveedor',

      observaciones: json['observaciones']?.toString() ?? '',
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0.0,
      proyectoId: (json['proyectoId'] as num?)?.toInt() ?? 1,
      urlImagen: json['urlImagen']?.toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'numeroFactura': numeroFactura,
    'fecha':
        "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}",
    'proveedor': proveedor,
    'observaciones': observaciones,
    'valorTotal': valorTotal,
    'proyectoId': proyectoId,
    'items': items.map((i) => i.toJson()).toList(),
  };

  @override
  String toString() =>
      'Factura(id: $id, proveedor: $proveedor, total: $valorTotal)';
}

class FacturaMaterialItem {
  final int materialId;
  final String nombre;
  final double cantidad;
  final double precioUnitario;

  FacturaMaterialItem({
    required this.materialId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory FacturaMaterialItem.fromJson(Map<String, dynamic> json) {
    return FacturaMaterialItem(
      materialId: json['materialId'] ?? 0,
      nombre: json['nombreMaterial'] ?? 'Sin nombre',
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'materialId': materialId,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
  };
}
