import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tweets'),
        actions: [
          // Botón de cerrar sesión en la esquina superior derecha
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              // Borramos el JWT de 3 días del almacenamiento seguro
              await authService.logout();
              // Lo mandamos de regreso al Login sin posibilidad de volver atrás
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Autenticación Exitosa!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu Token JWT se ha generado y guardado de manera segura en el almacenamiento local.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Aquí conectaremos pronto la carga de tus Tweets usando el Token
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cargando tweets protegidos del backend...')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Consultar Tweets Protegidos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
