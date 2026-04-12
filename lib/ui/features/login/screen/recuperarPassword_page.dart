import 'package:flutter/material.dart';
import '../widget/login_items.dart';

class RecuperarpasswordPage extends StatefulWidget {
  const RecuperarpasswordPage({super.key});

  @override
  State<RecuperarpasswordPage> createState() => _RecuperarpasswordPageState();
}

class _RecuperarpasswordPageState extends State<RecuperarpasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;

  void enviarCorreo() async {
    setState(() => loading = true);

    // Aquí luego llamas a tu servicio real
    await Future.delayed(const Duration(seconds: 1));

    setState(() => loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Correo enviado (simulado)")));
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
              "Recuperar contraseña",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            LoginInput(
              label: "Correo electrónico",
              controller: emailController,
            ),

            const SizedBox(height: 30),

            LoginButton(
              text: "Enviar correo",
              loading: loading,
              onPressed: enviarCorreo,
            ),
          ],
        ),
      ),
    );
  }
}
