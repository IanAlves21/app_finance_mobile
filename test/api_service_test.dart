import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';

void main() {
  group('ApiService Tests', () {
    setUp(() {
      SecureStorageManager.useMock = true;
      SecureStorageManager.mockToken = 'mock_token';
    });

    test('isTokenExpired returns false if token mock is used', () {
      expect(ApiService.isTokenExpired('some.token.here'), isFalse);
    });

    test('isTokenExpired decodes real JWT and checks expiration', () {
      SecureStorageManager.useMock = false;

      // Generate a payload that has exp set in the future
      final payload = {
        'sub': 'u-1',
        'email': 'test@test.com',
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600, // 1 hour in the future
      };
      final payloadBase64 = base64Url.encode(utf8.encode(json.encode(payload)));
      final token = 'header.$payloadBase64.signature';

      expect(ApiService.isTokenExpired(token), isFalse);

      // Generate expired payload
      final expiredPayload = {
        'sub': 'u-1',
        'email': 'test@test.com',
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600, // 1 hour in the past
      };
      final expiredPayloadBase64 = base64Url.encode(utf8.encode(json.encode(expiredPayload)));
      final expiredToken = 'header.$expiredPayloadBase64.signature';

      expect(ApiService.isTokenExpired(expiredToken), isTrue);
    });

    test('login returns token map on 200/201', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/login');
        return http.Response(
          json.encode({'access_token': 'mock_token', 'user': {'id': '1'}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.login('email@test.com', 'pass123');

      expect(result['access_token'], 'mock_token');
      expect(result['user']['id'], '1');
    });

    test('login throws HttpException on error status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Invalid credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      expect(
        () => apiService.login('email@test.com', 'wrong'),
        throwsA(isA<HttpException>().having((e) => e.message, 'message', 'Invalid credentials')),
      );
    });

    test('register returns user map on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/register');
        return http.Response(
          json.encode({'id': 'user-123'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.register('John', 'email@test.com', 'pass123');

      expect(result['id'], 'user-123');
    });

    test('loginGoogle returns token map on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/google');
        return http.Response(
          json.encode({'access_token': 'google_jwt'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.loginGoogle('google_id_token');

      expect(result['access_token'], 'google_jwt');
    });

    test('get appends Authorization header and calls GET', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer mock_token');
        return http.Response('[]', 200);
      });

      final apiService = ApiService(client: mockClient);
      final response = await apiService.get('/transactions');

      expect(response.statusCode, 200);
    });

    test('post appends Authorization and body, then calls POST', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer mock_token');
        expect(json.decode(request.body)['description'], 'test');
        return http.Response('{}', 201);
      });

      final apiService = ApiService(client: mockClient);
      final response = await apiService.post('/transactions', {'description': 'test'});

      expect(response.statusCode, 201);
    });

    test('patch calls PATCH', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.headers['Authorization'], 'Bearer mock_token');
        return http.Response('{}', 200);
      });

      final apiService = ApiService(client: mockClient);
      final response = await apiService.patch('/transactions/1', {'amount': 50});

      expect(response.statusCode, 200);
    });

    test('delete calls DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer mock_token');
        return http.Response('{}', 200);
      });

      final apiService = ApiService(client: mockClient);
      final response = await apiService.delete('/transactions/1');

      expect(response.statusCode, 200);
    });
  });
}
