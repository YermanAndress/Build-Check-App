import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../core/api_config.dart';
import '../models/factura_model.dart';

class FacturaService {
  Future<bool> registrarFacturaManual(Factura factura) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.facturas),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(factura.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error en FacturaService (Manual): $e");
      return false;
    }
  }

  Future<bool> registrarFacturaConFoto({
    required Uint8List bytes,
    required DateTime fecha,
    required int proyectoId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.facturas),
      );

      request.fields['fecha'] =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      request.fields['proyectoId'] = proyectoId.toString();
      request.fields['modo'] = 'ocr';

      // Adjuntar la imagen
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error en FacturaService (Foto): $e");
      return false;
    }
  }

  // En lib/services/factura_service.dart

  Future<List<Factura>> obtenerFacturas() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.facturas));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Factura.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error obteniendo facturas: $e");
      return [];
    }
  }
}
