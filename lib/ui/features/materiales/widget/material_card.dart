import 'package:flutter/material.dart';

import '../../../../models/material_model.dart';

import '../widget/material_details.dart';

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  const MaterialCard({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          material.nombre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Unidad de medida: ${material.unidadMedida}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaterialDetailScreen(material: material),
            ),
          );
        },
      ),
    );
  }
}
