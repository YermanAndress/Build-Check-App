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
      final detectedMimeType = _detectMimeType(bytes);
      final detectedExtension = _extensionForMime(detectedMimeType) ?? 'jpg';
      debugPrint(
        "OCR Upload Debug -> bytes: ${bytes.length}, mime: $detectedMimeType, ext: $detectedExtension",
      );

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
          filename:
              'factura_${DateTime.now().millisecondsSinceEpoch}.$detectedExtension',
          contentType:
              detectedMimeType != null ? http.MediaType.parse(detectedMimeType) : null,
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

  Future<bool> registrarFacturaConImagen({
    required Factura factura,
    required Uint8List bytes,
  }) async {
    try {
      final token = await SecureStorage.read("accessToken");
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.facturasWithImage),
      );
      request.headers["Authorization"] = "Bearer $token";

      final proyectoIdHeader = ProyectoActual.id;
      if (proyectoIdHeader != null) {
        request.headers["X-Proyecto-Id"] = proyectoIdHeader.toString();
      }

      request.fields["factura"] = jsonEncode(factura.toJson());

      final detectedMimeType = _detectMimeType(bytes);
      final detectedExtension = _extensionForMime(detectedMimeType) ?? 'jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename:
              'factura_${DateTime.now().millisecondsSinceEpoch}.$detectedExtension',
          contentType:
              detectedMimeType != null ? http.MediaType.parse(detectedMimeType) : null,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error en FacturaService (Con Imagen): $e");
      return false;
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

  String? _detectMimeType(Uint8List bytes) {
    if (bytes.length < 12) {
      return null;
    }

    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    // JPEG signature: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    return null;
  }

  String? _extensionForMime(String? mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      default:
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

  Future<String?> obtenerUrlImagenFactura(int facturaId) async {
    try {
      final response = await HttpInterceptor.send(() async {
        return http.get(
          Uri.parse(ApiConfig.facturaImageUrl(facturaId)),
          headers: await AuthHeader.getHeaders(),
        );
      });

      if (response.statusCode != 200) {
        return null;
      }

      final decodedData = jsonDecode(response.body);
      return decodedData['url']?.toString();
    } catch (e) {
      debugPrint("Error obteniendo URL de imagen: $e");
      return null;
    }
  }
}
