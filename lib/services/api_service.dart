import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;

import 'secure_storage_manager.dart';
import 'session_manager.dart';

class ApiService {
  static String languageCode = 'pt';
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  /// O Client ID Web gerado pelo Google Console (Necessário para o Google Sign-In no Android v7+)
  /// ATENÇÃO: Cole o seu ID de Cliente Web aqui (ex: "634529212241-xxxxxxxxxx.apps.googleusercontent.com")
  static const String googleServerClientId = '634529212241-j6dmtm8df0l8lo0sgbvvpdjqn5lav6g7.apps.googleusercontent.com';

  static String get baseUrl {
    // API Gateway runs on 8080. On Android emulator, use 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Verifica de forma preventiva e decodificada se o token JWT está expirado
  static bool isTokenExpired(String token) {
    if (SecureStorageManager.useMock) {
      return false; // Ignora expiração em ambiente de teste
    }
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return true;

      // O payload do JWT está na segunda parte
      final String payload = parts[1];

      // Decodifica Base64Url (ajusta padding e caracteres especiais)
      String normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));

      final Map<String, dynamic> claims = json.decode(decoded);
      if (!claims.containsKey('exp')) return true;

      final int exp = claims['exp'] as int;
      final DateTime expirationDate = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
      );

      // Expira um minuto antes por segurança preventiva
      return DateTime.now().isAfter(
        expirationDate.subtract(const Duration(minutes: 1)),
      );
    } catch (_) {
      return true; // Se falhar na decodificação, considera expirado por segurança
    }
  }

  /// Encerra a sessão de login limpando as informações locais
  Future<void> logout() async {
    await SessionManager.logout();
  }

  /// Realiza o login retornando as credenciais de JWT e o perfil do usuário
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': languageCode,
          },
          body: json.encode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Falha ao autenticar';
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {}
      throw HttpException(errorMessage);
    }
  }

  /// Realiza o cadastro de um novo usuário
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await client
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': languageCode,
          },
          body: json.encode({'name': name, 'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Falha ao cadastrar';
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {}
      throw HttpException(errorMessage);
    }
  }

  /// Realiza o login com o Google enviando o idToken para validação no backend
  Future<Map<String, dynamic>> loginGoogle(String idToken) async {
    final response = await client
        .post(
          Uri.parse('$baseUrl/auth/google'),
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': languageCode,
          },
          body: json.encode({'idToken': idToken}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Falha ao autenticar com o Google';
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {}
      throw HttpException(errorMessage);
    }
  }

  /// Executa uma requisição GET autenticada com injeção automática de JWT
  Future<http.Response> get(String path) async {
    final String? token = await SecureStorageManager.readToken();
    final Map<String, String> headers = {'Accept-Language': languageCode};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await client.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  /// Executa uma requisição POST autenticada enviando um JSON com injeção automática de JWT
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final String? token = await SecureStorageManager.readToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept-Language': languageCode,
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    );
  }

  /// Executa uma requisição PATCH autenticada enviando um JSON com injeção automática de JWT
  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final String? token = await SecureStorageManager.readToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept-Language': languageCode,
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await client.patch(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    );
  }

  /// Executa uma requisição DELETE autenticada com injeção automática de JWT
  Future<http.Response> delete(String path) async {
    final String? token = await SecureStorageManager.readToken();
    final Map<String, String> headers = {'Accept-Language': languageCode};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await client.delete(Uri.parse('$baseUrl$path'), headers: headers);
  }
}
