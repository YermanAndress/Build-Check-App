import 'package:flutter/material.dart';
import '../widget/login_items.dart';

class RegistrarsePage extends StatefulWidget {
  const RegistrarsePage({super.key});

  @override
  State<RegistrarsePage> createState() => _RegistrarsePageState();
}

class _RegistrarsePageState extends State<RegistrarsePage> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String selectedRole = "ROLE_RESIDENTE";

  void registrar() async {
    setState(() => loading = true);

    // Aquí luego llamas a tu servicio real
    await Future.delayed(const Duration(seconds: 1));

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usuario registrado (simulado)")),
    );

    Navigator.pop(context); // volver al login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141B40),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141B40),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const LoginLogo(),
            const SizedBox(height: 20),
            const Text(
              "Crear cuenta",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            LoginInput(label: "Nombre completo", controller: nombreController),
            const SizedBox(height: 20),

            LoginInput(
              label: "Correo electrónico",
              controller: correoController,
            ),
            const SizedBox(height: 20),

            LoginInput(
              label: "Contraseña",
              controller: passwordController,
              obscure: true,
            ),

            const SizedBox(height: 20),

            const Text(
              "Selecciona tu rol",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),

            RoleSelector(
              selectedRole: selectedRole,
              onSelect: (rol) {
                setState(() => selectedRole = rol);
              },
            ),

            const SizedBox(height: 30),

            LoginButton(
              text: "Registrarse",
              loading: loading,
              onPressed: registrar,
            ),
          ],
        ),
      ),
    );
  }
}
