import 'dart:convert';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/models/factura_model.dart';

class FacturaService {
  Future<bool> registrarFacturaManual(Factura factura) async {
    try {
      final response = await HttpInterceptor.send(() async {
        return http.post(
          Uri.parse(ApiConfig.facturas),
          headers: await AuthHeader.getHeaders(),
          body: jsonEncode(factura.toJson()),
        );
      });
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
      final token = await SecureStorage.read("accessToken");
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.facturas),
      );
      request.headers["Authorization"] = "Bearer $token";

      request.fields['fecha'] =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      request.fields['proyectoId'] = proyectoId.toString();
      request.fields['modo'] = 'ocr';

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
      final proyectoId = ProyectoActual.id;
      final url = proyectoId != null
          ? ApiConfig.facturasPorProyecto(proyectoId)
          : ApiConfig.facturas;

      final response = await HttpInterceptor.send(() async {
        return http.get(Uri.parse(url), headers: await AuthHeader.getHeaders());
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('facturas')) {
          return (decodedData['facturas'] as List)
              .map((json) => Factura.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error detallado: $e");
      return [];
    }
  }
}
