import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:build_check_app/models/movimiento_model.dart';

class MovimientoDetailScreen extends StatelessWidget {
  final MovimientoResumen movimiento;
  const MovimientoDetailScreen({super.key, required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final bool esEntrada = movimiento.tipoMovimiento == 'ENTRADA';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detalle del Movimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cabecera con ícono grande
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  esEntrada
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 50,
                  color: esEntrada
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Badge de tipo
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: esEntrada
                    ? const Color(0xFFF0F7F0)
                    : const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                movimiento.tipoMovimiento,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                  color: esEntrada
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE53935),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Tarjeta de información
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfo(
                    'Material',
                    movimiento.materialNombre.isNotEmpty
                        ? movimiento.materialNombre
                        : 'Material #${movimiento.materialId ?? '—'}',
                    Icons.inventory_2_outlined,
                  ),
                  const Divider(height: 30),
                  _buildInfo(
                    'Cantidad',
                    movimiento.descripcionFormateada,
                    Icons.straighten,
                    valueColor: esEntrada
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
                  ),
                  const Divider(height: 30),
                  _buildInfo(
                    'Fecha del Movimiento',
                    dateFormat.format(movimiento.fecha),
                    Icons.calendar_today_outlined,
                  ),
                  const Divider(height: 30),
                  _buildInfo(
                    'Registrado',
                    dateFormat.format(movimiento.fechaCreacion),
                    Icons.access_time_outlined,
                    valueColor: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF263238),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}