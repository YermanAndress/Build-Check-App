import 'package:flutter/material.dart';

import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/ui/shared/widgets/card_base.dart';

class ProyectoCard extends StatelessWidget {
  final Proyecto proyecto;
  final bool esActivo;
  final VoidCallback? onTap;

  const ProyectoCard({
    super.key,
    required this.proyecto,
    this.esActivo = false,
    this.onTap,
  });

  Color get _rolColor {
    switch (proyecto.rolProyecto) {
      case 'ROLE_OWNER':
        return const Color(0xFFFF9800);
      case 'ROLE_ADMIN':
        return const Color(0xFF2196F3);
      case 'ROLE_ALMACENISTA':
        return const Color(0xFF4CAF50);
      case 'ROLE_DIRECTOR_OBRA':
        return const Color(0xFF9C27B0);
      case 'ROLE_RESIDENTE':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _rolLabel {
    if (proyecto.rolProyecto == null) return '';
    return proyecto.rolProyecto!.replaceAll('ROLE_', '').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return CardBase(
      icon: Icons.apartment_outlined,
      iconBackgroundColor: const Color(0xFFF0F7F0),
      iconColor: const Color(0xFF4CAF50),
      borderColor: esActivo ? const Color(0xFF4CAF50) : null,
      onTap: onTap ?? () {},
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esActivo) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Proyecto activo',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
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
            "Estado: ${proyecto.estado}",
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          if (proyecto.rolProyecto != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _rolColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tu rol: $_rolLabel',
                style: TextStyle(
                  color: _rolColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            proyecto.fechaCreacion.toString().split("T").first,
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
