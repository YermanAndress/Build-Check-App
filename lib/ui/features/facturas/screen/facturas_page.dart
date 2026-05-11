import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/services/factura_service.dart';
import 'package:build_check_app/ui/features/facturas/widget/factura_card.dart';
import 'package:build_check_app/ui/shared/widgets/list_card.dart';
import 'package:flutter/material.dart';

class FacturasPage extends StatefulWidget {
  const FacturasPage({super.key});

  @override
  State<FacturasPage> createState() => _FacturasPageState();
}

class _FacturasPageState extends State<FacturasPage> {
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
    if (mounted) setState(() => _proyectoKey = ProyectoActual.id);
  }

  @override
  Widget build(BuildContext context) {
    return SearchableList<Factura>(
      key: ValueKey(_proyectoKey),
      fetchData: () => FacturaService().obtenerFacturas(),
      searchPredicate: (factura) =>
          '${factura.proveedor} ${factura.numeroFactura ?? ''}',
      itemBuilder: (factura) => FacturaCard(factura: factura),
      title: 'Historial de Gastos',
      hintText: 'Buscar por proveedor o número...',
      emptyMessage: 'No hay facturas registradas aún',
      noResultsMessage: 'No se encontraron resultados',
    );
  }
}
