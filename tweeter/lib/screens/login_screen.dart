import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Por favor, llena todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.login(username, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Nos vamos a la pantalla principal del océano
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Usuario o contraseña incorrectos');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo con un degradado que simula el descenso al océano
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F7FA), // Azul agua claro (superficie)
              Color(0xFF80DEEA), // Azul celeste
              Color(0xFF006064), // Azul marino profundo (profundidades)
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white.withOpacity(0.92), // Tarjeta semi-transparente
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono temático de una criatura o entorno marino
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00838F).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water, // Icono de olas/agua
                        size: 64,
                        color: Color(0xFF006064),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Título de la comunidad marina
                    const Text(
                      'OceanXplorer',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006064),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Bitácora de Criaturas Marinas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Campo de Usuario
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        labelStyle: const TextStyle(color: Color(0xFF006064)),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF006064)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00838F), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo de Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(color: Color(0xFF006064)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF006064)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00838F), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Botón de Ingreso
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006064), // Azul profundo
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sumergirse',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Enlace para ir al registro
                    TextButton(
  onPressed: () {
    Navigator.pushNamed(context, '/register');
  },
  child: const Text(
    '¿Eres nuevo explorador? Regístrate aquí',
    style: TextStyle(
      color: Color(0xFF00838F),
      fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
