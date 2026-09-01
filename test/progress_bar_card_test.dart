import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/widgets/progress_bar_card.dart';
import 'package:app_finance_mobile/theme/app_colors.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets(
    'ProgressBarCard keeps original color when percentage is <= 80% (0.8)',
    (WidgetTester tester) async {
      const testColor = Colors.blue;

      await tester.pumpWidget(
        buildTestableWidget(
          const ProgressBarCard(
            title: 'Shopping',
            amount: 'R\$ 50,00 / R\$ 100,00',
            percentage: 0.5,
            color: testColor,
            icon: Icons.shopping_bag,
          ),
        ),
      );

      // Verify title and amount (with percentage) are rendered
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('R\$ 50,00 / R\$ 100,00 (50%)'), findsOneWidget);

      // Verify progress bar color is the original custom color
      final indicatorFinder = find.byType(LinearProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(indicatorFinder);
      final valueColor = indicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(valueColor.value, testColor);
    },
  );

  testWidgets('ProgressBarCard turns red when percentage is > 80% (0.8)', (
    WidgetTester tester,
  ) async {
    const testColor = Colors.blue;

    await tester.pumpWidget(
      buildTestableWidget(
        const ProgressBarCard(
          title: 'Shopping',
          amount: 'R\$ 85,00 / R\$ 100,00',
          percentage: 0.85,
          color: testColor,
          icon: Icons.shopping_bag,
        ),
      ),
    );

    // Verify amount (with percentage) is rendered
    expect(find.text('R\$ 85,00 / R\$ 100,00 (85%)'), findsOneWidget);

    // Verify progress bar color is AppColors.redAccent when percentage is > 0.8 (even if < 1.0)
    final indicatorFinder = find.byType(LinearProgressIndicator);
    expect(indicatorFinder, findsOneWidget);

    final indicator = tester.widget<LinearProgressIndicator>(indicatorFinder);
    final valueColor = indicator.valueColor as AlwaysStoppedAnimation<Color>;
    expect(valueColor.value, AppColors.redAccent);
  });

  testWidgets(
    'ProgressBarCard turns red and changes text color when percentage is > 100% (1.0)',
    (WidgetTester tester) async {
      const testColor = Colors.blue;

      await tester.pumpWidget(
        buildTestableWidget(
          const ProgressBarCard(
            title: 'Shopping',
            amount: 'R\$ 120,00 / R\$ 100,00',
            percentage: 1.2,
            color: testColor,
            icon: Icons.shopping_bag,
          ),
        ),
      );

      // Verify progress bar color is AppColors.redAccent
      final indicatorFinder = find.byType(LinearProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(indicatorFinder);
      final valueColor = indicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(valueColor.value, AppColors.redAccent);

      // Verify amount text with percentage and color is AppColors.redAccent when exceeded
      final amountTextFinder = find.text('R\$ 120,00 / R\$ 100,00 (120%)');
      expect(amountTextFinder, findsOneWidget);
      final amountTextWidget = tester.widget<Text>(amountTextFinder);
      expect(amountTextWidget.style?.color, AppColors.redAccent);
    },
  );
}
