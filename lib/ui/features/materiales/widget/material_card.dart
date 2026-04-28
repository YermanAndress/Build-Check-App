import 'package:flutter/material.dart';

import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/ui/features/materiales/widget/material_details.dart';

import 'package:build_check_app/ui/shared/widgets/card_base.dart';

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  const MaterialCard({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    final bool tieneStock = (material.stockActual ?? 0) > 0;

    return CardBase(
      icon: Icons.inventory_2_outlined,
      iconBackgroundColor: const Color(0xFFF0F7F0),
      iconColor: const Color(0xFF4CAF50),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaterialDetailScreen(material: material),
          ),
        );
      },
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF263238),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Unidad: ${material.unidadMedida}',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${material.stockActual ?? 0}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: tieneStock ? const Color(0xFF2E7D32) : Colors.red,
            ),
          ),
          const Text(
            'Disponible',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
