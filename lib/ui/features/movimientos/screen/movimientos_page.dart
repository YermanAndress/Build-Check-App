import 'package:flutter/material.dart';

import 'package:build_check_app/models/movimiento_model.dart';
import 'package:build_check_app/services/movimiento_service.dart';
import 'package:build_check_app/ui/features/movimientos/widget/movimiento_card.dart';
import 'package:build_check_app/ui/shared/widgets/list_card.dart';

class MovimientosPage extends StatelessWidget {
  const MovimientosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchableList<MovimientoResumen>(
      fetchData: () async {
        // CAMBIO AQUÍ: Pasamos el parámetro false para traer todo el historial
        final stats = await MovimientoService().obtenerStatsHoy(soloHoy: false);
        final lista = stats['movimientos'] as List<MovimientoResumen>? ?? [];
        return lista;
      },
      searchPredicate: (movimiento) => movimiento.materialNombre.isNotEmpty
          ? movimiento.materialNombre
          : 'Material #${movimiento.materialId ?? ''}',
      itemBuilder: (movimiento) => MovimientoCard(movimiento: movimiento),
      title: 'Historial de Movimientos', // Título más acorde
      hintText: 'Buscar por material...',
      emptyMessage: 'No hay movimientos registrados',
      noResultsMessage: 'No se encontraron resultados',
    );
  }
}