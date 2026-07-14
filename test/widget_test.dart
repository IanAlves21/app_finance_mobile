import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/main.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/viewmodels/login_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('App renders LoginScreen initially and performs successful login', (WidgetTester tester) async {
    // Reset login status to false initially
    isLoggedInNotifier.value = false;
    
    // Force Portuguese for deterministic assertions
    localeNotifier.value = const Locale('pt');

    final mockClient = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          json.encode({
            'access_token': 'mocked_jwt_token',
            'user': {
              'id': 'mocked_user_id',
              'name': 'Ian Gustavo',
              'email': 'ian@teste.com'
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final mockApiService = ApiService(client: mockClient);
    final mockLoginViewModel = LoginViewModel(apiService: mockApiService);

    await tester.pumpWidget(MyApp(loginViewModel: mockLoginViewModel));
    await tester.pumpAndSettle();

    // Verify LoginScreen is shown
    expect(find.text('Bem-vindos de volta'), findsOneWidget);
    expect(find.text('Sua vida financeira a dois'), findsOneWidget);
    expect(find.text('E-MAIL'), findsOneWidget);
    expect(find.text('SENHA'), findsOneWidget);

    // Enter email and password
    await tester.enterText(find.byType(TextField).at(0), 'teste@email.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha123');
    await tester.pumpAndSettle();

    // Tap on Submit Button
    final loginButtonFinder = find.text('Entrar');
    expect(loginButtonFinder, findsOneWidget);
    await tester.tap(loginButtonFinder);
    
    // Pump frames to let the animation and delay run (LoginViewModel has a 1200ms delay)
    await tester.pump(const Duration(milliseconds: 500));
    // Verify it is loading (showing CircularProgressIndicator)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump remainder of delay
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Verify it entered the Dashboard and login screen is gone
    expect(find.text('Bem-vindos de volta'), findsNothing);
    expect(find.text('SALDO TOTAL COMPARTILHADO'), findsOneWidget);
  });

  testWidgets('App dynamically switches locales and renders correct text', (WidgetTester tester) async {
    // Force login state to bypass login screen in existing test flows
    isLoggedInNotifier.value = true;
    
    // Force Portuguese initially for deterministic test assertion
    localeNotifier.value = const Locale('pt');

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that Portuguese localized text is rendered
    expect(find.text('BOM DIA'), findsOneWidget);
    expect(find.text('SALDO TOTAL COMPARTILHADO'), findsOneWidget);

    // Switch dynamically to English
    localeNotifier.value = const Locale('en');
    await tester.pumpAndSettle();

    // Verify that English localized text is now rendered
    expect(find.text('GOOD MORNING'), findsOneWidget);
    expect(find.text('SHARED TOTAL BALANCE'), findsOneWidget);
  });

  testWidgets('App opens TransactionDetailBottomSheet on transaction tap and closes it', (WidgetTester tester) async {
    // Force login state to bypass login screen in existing test flows
    isLoggedInNotifier.value = true;

    // Set locale to Portuguese
    localeNotifier.value = const Locale('pt');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify first transaction is listed (translated under the hood to "Pagamento Freelance")
    final transactionFinder = find.text('Pagamento Freelance');
    expect(transactionFinder, findsOneWidget);

    // Ensure the transaction widget is fully visible and scrollable in screen
    await tester.ensureVisible(transactionFinder);
    await tester.pumpAndSettle();

    // Tap on the transaction to open the detail bottom sheet
    await tester.tap(transactionFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet title is visible in Portuguese
    expect(find.text('Detalhes da Transação'), findsOneWidget);

    // Verify detail row values are visible
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Payment for design system deliverables'), findsOneWidget);
    expect(find.text('Shared Wallet Account'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);

    // Tap the close button to close the bottom sheet
    final closeButtonFinder = find.byIcon(Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet is dismissed
    expect(find.text('Detalhes da Transação'), findsNothing);
  });
}
