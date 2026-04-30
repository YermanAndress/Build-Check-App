import 'package:flutter/material.dart';

import 'package:build_check_app/models/movimiento_model.dart';
import 'package:build_check_app/ui/features/movimientos/widget/movimiento_details.dart';
import 'package:build_check_app/ui/shared/widgets/card_base.dart';

class MovimientoCard extends StatelessWidget {
  final MovimientoResumen movimiento;
  const MovimientoCard({super.key, required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final bool esEntrada = movimiento.tipoMovimiento == 'ENTRADA';
    final now = DateTime.now();

    return CardBase(
      icon: esEntrada
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      iconBackgroundColor:
          esEntrada ? const Color(0xFFF0F7F0) : const Color(0xFFFFF3F3),
      iconColor:
          esEntrada ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovimientoDetailScreen(movimiento: movimiento),
          ),
        );
      },
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movimiento.materialNombre.isNotEmpty
                ? movimiento.materialNombre
                : 'Material #${movimiento.materialId ?? '—'}',
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
            movimiento.tiempoRelativo(now),
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${esEntrada ? '+' : '-'}${movimiento.descripcionFormateada}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: esEntrada
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE53935),
            ),
          ),
          Text(
            esEntrada ? 'Entrada' : 'Salida',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}