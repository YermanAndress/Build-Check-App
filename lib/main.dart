import 'package:flutter/material.dart';

void main() {
  runApp(const BuildCheckApp());
}

class BuildCheckApp extends StatelessWidget {
  const BuildCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Build Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
      ),
      home: const BuildCheckHome(),
    );
  }
}

class BuildCheckHome extends StatefulWidget {
  const BuildCheckHome({super.key});

  @override
  State<BuildCheckHome> createState() => _BuildCheckHomeState();
}

class _BuildCheckHomeState extends State<BuildCheckHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Build Check',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF555555)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF555555)),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Por recibir hoy',
                    value: '8',
                    sublabel: 'Materiales',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF888888),
                    backgroundColor: Colors.white,
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Stock bajo',
                    value: '3',
                    sublabel: 'Alertas activas',
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Salidas hoy',
                    value: '12',
                    sublabel: 'Movimientos',
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Entradas hoy',
                    value: '5',
                    sublabel: 'Movimientos',
                    icon: Icons.subdirectory_arrow_left,
                    iconColor: const Color(0xFF4CAF50),
                    backgroundColor: const Color(0xFFEDF7EE),
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Quick Actions
            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    label: 'Registrar\nEntrada',
                    icon: Icons.arrow_downward_rounded,
                    iconBgColor: const Color(0xFFFFCDD2),
                    iconColor: const Color(0xFFE57373),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    label: 'Registrar\nSalida',
                    icon: Icons.arrow_upward_rounded,
                    iconBgColor: const Color(0xFFF8BBD0),
                    iconColor: const Color(0xFFE91E63),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    label: 'Escanear\nFactura',
                    icon: Icons.camera_alt_outlined,
                    iconBgColor: const Color(0xFFE0E0E0),
                    iconColor: const Color(0xFF757575),
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Recent Movements
            const Text(
              'Movimientos recientes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),

            _MovementItem(
              name: 'Cemento 50kg',
              detail: '200 sacos | Hace 2h',
              type: MovementType.entrada,
            ),
            _MovementItem(
              name: 'Varilla corrugada',
              detail: '50 Piezas | Hace 5h',
              type: MovementType.salida,
            ),
            _MovementItem(
              name: 'Cemento 50kg',
              detail: '15m3 | Ayer',
              type: MovementType.entrada,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'Proyectos'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_outlined), activeIcon: Icon(Icons.inventory), label: 'Inventario'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_vert), label: 'Movimientos'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Reporte'),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Movement Item ────────────────────────────────────────────────────────────

enum MovementType { entrada, salida }

class _MovementItem extends StatelessWidget {
  const _MovementItem({
    required this.name,
    required this.detail,
    required this.type,
  });

  final String name;
  final String detail;
  final MovementType type;

  @override
  Widget build(BuildContext context) {
    final isEntrada = type == MovementType.entrada;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isEntrada ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isEntrada ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEntrada ? const Color(0xFFEDF7EE) : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isEntrada ? 'ENTRADA' : 'SALIDA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEntrada ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
              ),
            ),
          ),
        ],
      ),
    );
  }
}