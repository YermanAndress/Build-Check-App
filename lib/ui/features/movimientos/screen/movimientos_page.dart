import 'package:flutter/material.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/models/movimiento_model.dart';
import 'package:build_check_app/services/movimiento_service.dart';
import 'package:build_check_app/ui/features/movimientos/widget/movimiento_card.dart';
import 'package:build_check_app/ui/shared/widgets/list_card.dart';

class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  int? _proyectoKey;

  @override
  void initState() {
    super.initState();
    _proyectoKey = ProyectoActual.id;
    ProyectoActual.notifier.addListener(_onProyectoChanged);
  }

  @override
  void dispose() {
    ProyectoActual.notifier.removeListener(_onProyectoChanged);
    super.dispose();
  }

  void _onProyectoChanged() {
    if (mounted) {
      MovimientoService.invalidarCache();
      setState(() => _proyectoKey = ProyectoActual.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchableList<MovimientoResumen>(
      key: ValueKey(_proyectoKey),
      fetchData: () async {
        final mapa = await MovimientoService().obtenerMapaMovimientos();
        return mapa.values.toList();
      },
      searchPredicate: (movimiento) => movimiento.materialNombre,
      itemBuilder: (movimiento) => MovimientoCard(movimiento: movimiento),
      title: 'Historial de Movimientos',
      hintText: 'Buscar por material...',
      emptyMessage: 'No hay movimientos registrados aún',
      noResultsMessage: 'No se encontraron movimientos',
    );
  }
}
