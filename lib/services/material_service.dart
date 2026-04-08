import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/material_model.dart';

class MaterialService {
  static Map<int, MaterialItem>? _cacheMapaMateriales;
  static DateTime? _ultimaCarga;

  // Obtener alertas de stock bajo
  Future<List<AlertaMaterial>> obtenerAlertas() async {
    final res = await http.get(Uri.parse(ApiConfig.alertas));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      List raw = (decoded is List)
          ? decoded
          : (decoded['alertas'] ?? [decoded]);
      return raw.map((e) => AlertaMaterial.fromJson(e)).toList();
    }
    throw Exception('Error al cargar alertas: ${res.statusCode}');
  }

  Future<Map<int, MaterialItem>> obtenerMapaMateriales({
    bool forzarRefresco = false,
  }) async {
    if (!forzarRefresco &&
        _cacheMapaMateriales != null &&
        _ultimaCarga != null) {
      final diferencia = DateTime.now().difference(_ultimaCarga!);
      if (diferencia.inMinutes < 5) return _cacheMapaMateriales!;
    }

    final res = await http.get(Uri.parse(ApiConfig.materiales));
    final Map<int, MaterialItem> nuevoMapa = {};

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      List raw = decoded is List ? decoded : (decoded['materiales'] ?? []);

      for (var item in raw) {
        final m = MaterialItem.fromJson(item);
        nuevoMapa[m.id] = m;
      }

      _cacheMapaMateriales = nuevoMapa;
      _ultimaCarga = DateTime.now();
    }
    return nuevoMapa;
  }

  // Registrar un nuevo movimiento
  Future<bool> registrarMovimiento(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(ApiConfig.movimientos),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Registro de factura con imagen (Multipart)
  Future<bool> registrarFacturaMultipart(
    Map<String, String> fields,
    Uint8List? imageBytes,
  ) async {
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.facturas));
    request.fields.addAll(fields);

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Este nombre debe coincidir con el nodo "Binary Property" en n8n
          imageBytes,
          filename: 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }

    final streamedRes = await request.send();
    return streamedRes.statusCode == 200 || streamedRes.statusCode == 201;
  }
}
