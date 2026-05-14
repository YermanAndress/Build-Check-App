import 'package:flutter/material.dart';

import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/services/material_service.dart';
import 'package:build_check_app/ui/features/materiales/widget/material_card.dart';
import 'package:build_check_app/ui/shared/widgets/list_card.dart';

class MaterialesPage extends StatefulWidget {
  const MaterialesPage({super.key});
  @override
  State<MaterialesPage> createState() => _MaterialesPageState();
}

class _MaterialesPageState extends State<MaterialesPage> {
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
      MaterialService.invalidarCache();
      setState(() => _proyectoKey = ProyectoActual.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchableList<MaterialItem>(
      key: ValueKey(_proyectoKey),
      fetchData: () async {
        final mapa = await MaterialService().obtenerMapaMateriales();
        return mapa.values.toList();
      },
      searchPredicate: (m) => m.nombre,
      itemBuilder: (m) => MaterialCard(material: m),
      title: 'Catálogo de Materiales',
      hintText: 'Buscar material...',
      emptyMessage: 'No hay materiales registrados aún',
      noResultsMessage: 'No se encontraron resultados',
    );
  }
}
