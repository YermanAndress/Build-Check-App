import 'dart:convert';
import 'package:build_check_app/main.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/models/movimiento_model.dart';

class MovimientoService {
  /// [soloHoy] = true  → filtra solo movimientos del día actual (comportamiento original)
  /// [soloHoy] = false → devuelve todo el historial
  Future<Map<String, dynamic>> obtenerStatsHoy({
    bool soloHoy = true,
  }) async {
    try {
      final headers = await AuthHeader.getHeaders();
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.movimientos), headers: headers),
        http.get(Uri.parse(ApiConfig.materiales), headers: headers),
      ]);

      final resMov = responses[0];
      final resMat = responses[1];

      if (resMov.statusCode == 401 || resMat.statusCode == 401) {
        await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
        return {};
      }

      if (resMov.statusCode != 200) throw 'Error: ${resMov.statusCode}';

      List normalizar(dynamic data, String key) {
        if (data is List) return data;
        if (data is Map && data.containsKey(key)) return data[key] as List;
        return [data];
      }

      // Procesar materiales
      final Map<int, MaterialItem> matMap = {};
      if (resMat.statusCode == 200) {
        final decoded = jsonDecode(resMat.body);
        final rawMat = normalizar(decoded, 'materiales');
        for (var e in rawMat) {
          final m = MaterialItem.fromJson(e);
          matMap[m.id] = m;
        }
      }

      // Procesar movimientos
      final decodedMov = jsonDecode(resMov.body);
      final rawMov = normalizar(decodedMov, 'movimientos');
      final hoy = DateTime.now();

      final lista = rawMov
          .map((e) {
            final m = MovimientoResumen.fromJson(e);
            final mat = matMap[m.materialId];
            return mat != null ? m.conMaterial(mat.nombre, mat.unidadMedida) : m;
          })
          .where((m) {
            if (!soloHoy) return true; // Sin filtro → todo el historial
            return m.fecha.year == hoy.year &&
                m.fecha.month == hoy.month &&
                m.fecha.day == hoy.day;
          })
          .toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      return {
        'movimientos': lista,
        'totalMateriales': matMap.length,
        'entradasHoy': lista.where((m) => m.tipoMovimiento == 'ENTRADA').length,
        'salidasHoy': lista.where((m) => m.tipoMovimiento == 'SALIDA').length,
      };
    } catch (e) {
      debugPrint('DEBUG: Error en MovimientoService: $e');
      rethrow;
    }
  }

  /// Actualizar un movimiento existente — PUT /movimientos/{id}
  Future<bool> actualizarMovimiento(int id, Map<String, dynamic> data) async {
    try {
      final headers = await AuthHeader.getHeaders();
      final res = await http.put(
        Uri.parse('${ApiConfig.movimientos}/$id'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (res.statusCode == 401) {
        await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
        return false;
      }

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('DEBUG: Error al actualizar movimiento: $e');
      return false;
    }
  }
}