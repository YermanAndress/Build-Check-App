import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/ui/features/proyectos/widget/proyecto_details.dart';
import 'package:build_check_app/ui/shared/widgets/card_base.dart';
import 'package:flutter/material.dart';

class ProyectoCard extends StatelessWidget {
  final Proyecto proyecto;

  const ProyectoCard({super.key, required this.proyecto});

  @override
  Widget build(BuildContext context) {
    return CardBase(
      icon: Icons.apartment_outlined,
      iconBackgroundColor: const Color(0xFFF0F7F0),
      iconColor: const Color(0xFF4CAF50),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProyectoDetails(proyectoId: proyecto.id),
          ),
        );
      },
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            proyecto.nombre,
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
            "Estadp: ${proyecto.estado}",
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            proyecto.fechaCreacion.split("T").first,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF2E7D32),
            ),
          ),
          const Text(
            "Creado",
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
