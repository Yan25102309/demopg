import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Registrar un nuevo usuario (/signup)
  Future<bool> register(String username, String email, String password) async {
    final url = apiUri('/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error en registro: $e");
      return false;
    }
  }

  // Iniciar sesión y guardar el Token JWT (/signin)
  Future<bool> login(String username, String password) async {
    final url = apiUri('/auth/signin');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['accessToken'];
        
        // -----------------------------------------------------------------
        // ¡IMPRIMIMOS EL TOKEN EN CONSOLA PARA MOSTRAR AL PROFESOR!
        print("=================== JWT TOKEN GENERADO ===================");
        print("🔑 Token recibido con éxito de Spring Boot:");
        print(token);
        print("==========================================================");
        // -----------------------------------------------------------------

        // Guardamos el token de forma segura en el llavero local
        await _storage.write(key: 'jwt_token', value: token);
        
        // 🌟 EXTRACCIÓN SEGURA DEL ROL PARA QUE NUNCA SE QUEDE CARGANDO
        String userRole = 'ROLE_USER';
        try {
          if (data['roles'] != null && (data['roles'] as List).isNotEmpty) {
            userRole = data['roles'][0].toString();
          } else if (data['role'] != null) {
            userRole = data['role'].toString();
          }
        } catch (roleError) {
          print("Aviso: No se pudo mapear el rol del JSON, usando ROLE_USER: $roleError");
        }

        // Guardamos el rol en el storage para que lo lea tu main.dart
        await _storage.write(key: 'user_role', value: userRole);
        return true;
      }
      return false;
    } catch (e) {
      print("Error en login: $e");
      return false;
    }
  }
  
  // Leer el rol del usuario guardado localmente
  Future<String> getUserRole() async {
    String? role = await _storage.read(key: 'user_role');
    if (role == null || role == 'null' || role.trim().isEmpty) {
      return 'ROLE_USER';
    }
    return role;
  }

  // Leer el token guardado
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Borrar el token al cerrar sesión
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role'); // 🌟 Limpiamos también el rol de la sesión anterior
  }
}