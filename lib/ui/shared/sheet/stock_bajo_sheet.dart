import 'package:flutter/material.dart';

import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/ui/shared/widgets/form_utils.dart';

class StockBajoSheet extends StatelessWidget {
  final List<AlertaMaterial> alertas;
  final bool cargando;

  const StockBajoSheet({
    super.key,
    required this.alertas,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF888888),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Stock bajo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (!cargando && alertas.isNotEmpty) BadgeOpcional(),
            ],
          ),
          const SizedBox(height: 20),

          // ── Cuerpo del Sheet ──
          if (cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            )
          else if (alertas.isEmpty)
            const _EmptyStockState()
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: alertas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    AlertaItem(alerta: alertas[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStockState extends StatelessWidget {
  const _EmptyStockState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 12),
            Text(
              'Todo el stock está en orden',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF777777),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertaItem extends StatelessWidget {
  final AlertaMaterial alerta;
  const AlertaItem({required this.alerta, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Quedan: ${alerta.stockActual} ${alerta.unidadMedida}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          // Mensaje de alerta
          Text(
            alerta.mensaje,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
