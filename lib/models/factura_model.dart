import 'package:build_check_app/enum/unidad_medida.dart';

class Factura {
  final int? id;
  final String? numeroFactura;
  final DateTime fecha;
  final String proveedor;
  final String? observaciones;
  final double? valorTotal;
  final DateTime fechaCreacion;
  final int proyectoId;
  final int usuarioId;
  final String? urlImagen;
  final List<FacturaMaterialItem> items;

  Factura({
    this.id,
    this.numeroFactura,
    required this.fecha,
    required this.proveedor,
    this.observaciones,
    this.valorTotal,
    required this.fechaCreacion,
    required this.proyectoId,
    required this.usuarioId,
    this.urlImagen,
    this.items = const [],
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    // Función auxiliar segura para int
    int? toInt(dynamic value) => (value as num?)?.toInt();
    double toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

    String proveedorNombre;
    final proveedorRaw = json['proveedor'];
    if (proveedorRaw is Map) {
      proveedorNombre = proveedorRaw['nombre']?.toString() ?? 'Sin proveedor';
    } else {
      proveedorNombre = proveedorRaw?.toString() ?? 'Sin proveedor';
    }

    final itemsList =
        (json['items'] as List?)
            ?.map(
              (e) => FacturaMaterialItem.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [];

    return Factura(
      id: toInt(json['id']),
      numeroFactura: json['numeroFactura']?.toString() ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      proveedor: proveedorNombre,
      observaciones: json['observaciones']?.toString() ?? '',
      valorTotal: toDouble(json['valorTotal']),
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime.now(),
      proyectoId: toInt(json['proyectoId']) ?? 0,
      usuarioId: toInt(json['usuarioId']) ?? 0,
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
    'usuarioId': usuarioId,
    'items': items.map((i) => i.toJson()).toList(),
  };

  @override
  String toString() =>
      'Factura(id: $id, proveedor: $proveedor, total: $valorTotal)';
}

class FacturaMaterialItem {
  final int? materialId;
  final String nombre;
  final double cantidad;
  final double precioUnitario;
  final UnidadMedida unidadMedida;
  final int usuarioId;
  final DateTime? fechaCreacion;

  FacturaMaterialItem({
    this.materialId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.unidadMedida,
    required this.usuarioId,
    this.fechaCreacion,
  });

  factory FacturaMaterialItem.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) => (v as num?)?.toInt();
    double toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    // El backend usa "nombreMaterial", no "nombre"
    final nombreMaterial =
        json['nombreMaterial']?.toString() ??
        json['nombre']?.toString() ??
        'Sin nombre';

    return FacturaMaterialItem(
      materialId: toInt(json['materialId']),
      nombre: nombreMaterial,
      cantidad: toDouble(json['cantidad']),
      precioUnitario: toDouble(json['precioUnitario']),
      unidadMedida: UnidadMedida.values.firstWhere(
        (e) => e.name == (json['unidadMedida'] ?? 'UNIDAD'),
        orElse: () => UnidadMedida.UNIDAD,
      ),
      usuarioId: toInt(json['usuarioId']) ?? 0,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'].toString())
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
    'materialId': materialId,
    'nombre': nombre,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
    'unidadMedida': unidadMedida.name,
    'usuarioId': usuarioId,
  };
}
