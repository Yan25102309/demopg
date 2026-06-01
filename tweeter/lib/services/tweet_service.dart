import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/tweet.dart';
import '../models/tweet_comment.dart';
import '../config/api_config.dart';

class TweetService {
  final _storage = const FlutterSecureStorage();

  // Método auxiliar nativo y seguro para Web para obtener el token y depurar
  Future<String?> _getValidToken(String methodName) async {
    String? token = await _storage.read(key: 'jwt_token');

    print(
        "=================== 🔍 DEPURACIÓN FRONTEND ($methodName) ===================");
    print("• Token crudo en Storage: '$token'");

    if (token == null || token == 'null' || token.trim().isEmpty) {
      print("• ⚠️ ALERTA: El token es Inválido, nulo o un String 'null'.");
      print(
          "===================================================================\n");
      return null;
    }

    // Usamos una operación lógica simple de Dart para recortar el string de depuración de forma segura
    int logLength = token.length < 15 ? token.length : 15;
    print(
        "• ✅ Token válido recuperado. Enviando: 'Bearer ${token.substring(0, logLength)}...'");
    print(
        "===================================================================\n");
    return token;
  }

  Future<List<Tweet>> fetchTweets() async {
    final url = apiUri('/tweets');
    try {
      String? token = await _getValidToken("fetchTweets");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("➔ [HTTP GET] /tweets | Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);

        List<dynamic> body;
        if (jsonResponse is Map && jsonResponse.containsKey('content')) {
          body = jsonResponse['content'];
        } else if (jsonResponse is List) {
          body = jsonResponse;
        } else {
          throw Exception('Formato de JSON inesperado');
        }

        return body.map((dynamic item) => Tweet.fromJson(item)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<List<TweetComment>> fetchComments(int tweetId) async {
    final url = apiUri('/tweets/$tweetId/comments');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          return jsonResponse
              .map((dynamic item) => TweetComment.fromJson(item))
              .toList();
        }
        return <TweetComment>[];
      }

      throw Exception('Error al cargar comentarios: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  Future<TweetComment> addComment(int tweetId, String content) async {
    final url = apiUri('/tweets/$tweetId/comments');
    try {
      String? token = await _getValidToken("addComment");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'content': content,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TweetComment.fromJson(jsonDecode(response.body));
      }

      throw Exception('Error al publicar comentario: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error al comentar: $e');
    }
  }

  /// SUBIR TÍTULO, DESCRIPCIÓN Y FOTO REAL AL BACKEND
  Future<void> createTweetWithImage(String title, String description,
      String fileName, Uint8List fileBytes) async {
    final url = apiUri('/tweets');
    try {
      String? token = await _getValidToken("createTweetWithImage");

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['title'] = title;
      request.fields['tweet'] = description;

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(
          "➔ [HTTP POST MULTIPART] /tweets | Status Code: ${response.statusCode}");

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
            'Error en el servidor al publicar: 401 (No autorizado). Revisa la configuración de seguridad en Java.');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Error en el servidor al publicar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con la API: $e');
    }
  }

  Future<void> deleteTweet(int id) async {
    final url = apiUri('/tweets/$id');
    try {
      String? token = await _getValidToken("deleteTweet");

      final response =
          await http.delete(url, headers: {'Authorization': 'Bearer $token'});

      print(
          "➔ [HTTP DELETE] /tweets/$id | Status Code: ${response.statusCode}");

      if (response.statusCode != 200) throw Exception('Error al eliminar');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// NUEVO: ENVIAR REACCIÓN ÚNICA AL BACKEND ESTILO FACEBOOK
  Future<Tweet> reactToTweet(int id, String reactionType) async {
    final url = apiUri('/tweets/$id/react?type=$reactionType');
    try {
      String? token = await _getValidToken("reactToTweet");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print(
          "➔ [HTTP POST] /tweets/$id/react | Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        return Tweet.fromJson(jsonResponse);
      } else {
        throw Exception('Error al registrar reacción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición de reacción: $e');
    }
  }

  void dispose() {}
}
