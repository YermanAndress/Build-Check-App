import 'package:flutter/material.dart';

import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/services/factura_service.dart';

import 'package:build_check_app/ui/features/facturas/widget/factura_card.dart';

import 'package:build_check_app/ui/shared/widgets/list_card.dart';

class FacturasPage extends StatelessWidget {
  const FacturasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchableList<Factura>(
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
