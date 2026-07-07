import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/main.dart';

void main() {
  testWidgets('App dynamically switches locales and renders correct text', (WidgetTester tester) async {
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
