import 'dart:convert';
import 'package:build_check_app/services/auth_header.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/models/factura_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacturaService {
  Future<bool> registrarFacturaManual(Factura factura) async {
    try {
      final headers = await AuthHeader.getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.facturas),
        headers: headers,
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.facturas),
      );
      request.headers["Authorization"] = "Bearer $token";

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

  Future<List<Factura>> obtenerFacturas() async {
    try {
      final headers = await AuthHeader.getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.facturas),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('facturas')) {
          final List listado = decodedData['facturas'];
          return listado.map((json) => Factura.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error detallado: $e");
      return [];
    }
  }
}
