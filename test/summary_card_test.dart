import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/widgets/summary_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('SummaryCard uses iconColor for border when selected', (WidgetTester tester) async {
    const iconColor = Colors.green;
    const badgeColor = Colors.red;

    await tester.pumpWidget(
      buildTestableWidget(
        const SummaryCard(
          title: 'Monthly Income',
          value: 'R\$ 5.000,00',
          badgeText: '+25%',
          badgeColor: badgeColor,
          badgeBg: Colors.red,
          icon: Icons.trending_up,
          iconColor: iconColor,
          iconBg: Colors.green,
          isSelected: true,
        ),
      ),
    );

    // Find the Container inside SummaryCard that holds the decoration
    final containerFinder = find.descendant(
      of: find.byType(SummaryCard),
      matching: find.byType(Container),
    ).first;
    
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    final border = decoration.border as Border?;
    
    // Verify border color is iconColor (green), not badgeColor (red)
    expect(border, isNotNull);
    expect(border!.top.color, iconColor);
    expect(border.top.width, 2.0);
  });

  testWidgets('SummaryCard uses transparent border when not selected', (WidgetTester tester) async {
    const iconColor = Colors.green;
    const badgeColor = Colors.red;

    await tester.pumpWidget(
      buildTestableWidget(
        const SummaryCard(
          title: 'Monthly Income',
          value: 'R\$ 5.000,00',
          badgeText: '+25%',
          badgeColor: badgeColor,
          badgeBg: Colors.red,
          icon: Icons.trending_up,
          iconColor: iconColor,
          iconBg: Colors.green,
          isSelected: false,
        ),
      ),
    );

    final containerFinder = find.descendant(
      of: find.byType(SummaryCard),
      matching: find.byType(Container),
    ).first;
    
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    final border = decoration.border as Border?;
    
    // Verify border color is Colors.transparent when not selected
    expect(border, isNotNull);
    expect(border!.top.color, Colors.transparent);
  });
}
