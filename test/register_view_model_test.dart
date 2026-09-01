import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/viewmodels/register_view_model.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RegisterViewModel Tests', () {
    test('Initial values are empty/default', () {
      final viewModel = RegisterViewModel();
      expect(viewModel.name, '');
      expect(viewModel.email, '');
      expect(viewModel.password, '');
      expect(viewModel.confirmPassword, '');
      expect(viewModel.loading, false);
      expect(viewModel.showPassword, false);
      expect(viewModel.showConfirmPassword, false);
      expect(viewModel.focusedField, null);
      expect(viewModel.errorMessage, null);
    });

    test('setEmail, setPassword, setName, setConfirmPassword work', () {
      final viewModel = RegisterViewModel();
      viewModel.setName('John Doe');
      viewModel.setEmail('test@example.com');
      viewModel.setPassword('secret123');
      viewModel.setConfirmPassword('secret123');
      viewModel.setFocusedField('name');

      expect(viewModel.name, 'John Doe');
      expect(viewModel.email, 'test@example.com');
      expect(viewModel.password, 'secret123');
      expect(viewModel.confirmPassword, 'secret123');
      expect(viewModel.focusedField, 'name');
    });

    test('toggleShowPassword and toggleShowConfirmPassword work', () {
      final viewModel = RegisterViewModel();
      expect(viewModel.showPassword, false);
      viewModel.toggleShowPassword();
      expect(viewModel.showPassword, true);

      expect(viewModel.showConfirmPassword, false);
      viewModel.toggleShowConfirmPassword();
      expect(viewModel.showConfirmPassword, true);
    });

    test('submitRegister success calls ApiService.register', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"id": "123", "email": "test@example.com", "name": "John"}', 201);
      });
      final mockApiService = ApiService(client: mockClient);
      final viewModel = RegisterViewModel(apiService: mockApiService);

      viewModel.setName('John');
      viewModel.setEmail('test@example.com');
      viewModel.setPassword('password123');
      viewModel.setConfirmPassword('password123');

      bool successCalled = false;
      String? errorMsg;

      await viewModel.submitRegister(
        onSuccess: () {
          successCalled = true;
        },
        onError: (err) {
          errorMsg = err;
        },
      );

      expect(successCalled, true);
      expect(errorMsg, null);
      expect(viewModel.loading, false);
    });

    test('submitRegister error handles ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Este e-mail já está em uso."}', 409);
      });
      final mockApiService = ApiService(client: mockClient);
      final viewModel = RegisterViewModel(apiService: mockApiService);

      viewModel.setName('John');
      viewModel.setEmail('test@example.com');
      viewModel.setPassword('password123');
      viewModel.setConfirmPassword('password123');

      bool successCalled = false;
      String? errorMsg;

      await viewModel.submitRegister(
        onSuccess: () {
          successCalled = true;
        },
        onError: (err) {
          errorMsg = err;
        },
      );

      expect(successCalled, false);
      expect(errorMsg, 'Este e-mail já está em uso.');
      expect(viewModel.loading, false);
    });
  });
}
