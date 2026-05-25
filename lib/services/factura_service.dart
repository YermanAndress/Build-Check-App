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

  Future<Factura?> procesarImagenOcr({
    required Uint8List bytes,
    required int proyectoId,
    required int usuarioId,
  }) async {
    try {
      final token = await SecureStorage.read("accessToken");
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.facturasOcr),
      );
      request.headers["Authorization"] = "Bearer $token";
      final proyectoIdHeader = ProyectoActual.id;
      if (proyectoIdHeader != null) {
        request.headers["X-Proyecto-Id"] = proyectoIdHeader.toString();
      }

      request.fields['proyectoId'] = proyectoId.toString();
      request.fields['usuarioId'] = usuarioId.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("OCR Response Status: ${response.statusCode}");
      debugPrint("OCR Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedData = jsonDecode(response.body);
        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('factura')) {
          return Factura.fromJson(decodedData['factura']);
        }
      } else if (response.statusCode == 422) {
        debugPrint("OCR Error 422: ${response.body}");
        // Items vacío o factura no válida
        throw Exception('Materiales es un campo obligatorio');
      } else if (response.statusCode == 504) {
        throw Exception('Tiempo de procesamiento agotado (OCR timeout)');
      } else if (response.statusCode == 502) {
        throw Exception('Error al procesar imagen (servicio externo)');
      } else {
        final errorMsg = _extractErrorMessage(response.body);
        throw Exception(errorMsg ?? 'Error en OCR: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint("Error en FacturaService (OCR): $e");
      rethrow;
    }
  }

  String? _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['mensaje']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<List<Factura>> obtenerFacturas({int? proyectoId}) async {
    try {
      final pId = proyectoId ?? ProyectoActual.id;
      final url = pId != null
          ? ApiConfig.facturasPorProyecto(pId)
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
