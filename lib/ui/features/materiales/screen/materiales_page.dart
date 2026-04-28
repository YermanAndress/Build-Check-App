import 'package:flutter/material.dart';

import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/services/material_service.dart';

import 'package:build_check_app/ui/features/materiales/widget/material_card.dart';

import 'package:build_check_app/ui/shared/widgets/list_card.dart';

class MaterialesPage extends StatelessWidget {
  const MaterialesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchableList<MaterialItem>(
      fetchData: () async {
        final mapa = await MaterialService().obtenerMapaMateriales();
        return mapa.values.toList();
      },
      searchPredicate: (material) => material.nombre,
      itemBuilder: (material) => MaterialCard(material: material),
      title: 'Catálogo de Materiales',
      hintText: 'Buscar material...',
      emptyMessage: 'No hay materiales registrados aún',
      noResultsMessage: 'No se encontraron resultados',
    );
  }
}
