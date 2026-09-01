import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/views/register_screen.dart';
import 'package:app_finance_mobile/viewmodels/register_view_model.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:app_finance_mobile/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Widget createRegisterScreen(RegisterViewModel viewModel) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: RegisterScreen(viewModel: viewModel),
  );
}

void main() {
  setUp(() async {
    await locator.reset();
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders all fields and submit button', (WidgetTester tester) async {
      final viewModel = RegisterViewModel(
        apiService: ApiService(
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );

      await tester.pumpWidget(createRegisterScreen(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.text('Cadastre-se para começar'), findsOneWidget);
      expect(find.text('NOME'), findsOneWidget);
      expect(find.text('E-MAIL'), findsOneWidget);
      expect(find.text('SENHA'), findsOneWidget);
      expect(find.text('CONFIRMAR SENHA'), findsOneWidget);
      expect(find.text('Cadastrar'), findsOneWidget);
      expect(find.text('Já tem uma conta? '), findsOneWidget);
    });

    testWidgets('Validates short password', (WidgetTester tester) async {
      final viewModel = RegisterViewModel(
        apiService: ApiService(
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );

      await tester.pumpWidget(createRegisterScreen(viewModel));
      await tester.pumpAndSettle();

      // Enter name, email and short password
      await tester.enterText(find.byType(TextField).at(0), 'John');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.enterText(find.byType(TextField).at(3), '123');
      await tester.pump();

      // Tap register button
      final registerButton = find.text('Cadastrar');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show error message / toast or validate internally
      expect(viewModel.loading, false);
    });
  });
}
