import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:app_finance_mobile/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formatBalanceParts formats positive, negative and zero values correctly', () {
      expect(CurrencyFormatter.formatBalanceParts(1234.56), ['R\$ 1.234', ',56']);
      expect(CurrencyFormatter.formatBalanceParts(-50.0), ['-R\$ 50', ',00']);
      expect(CurrencyFormatter.formatBalanceParts(0.0), ['R\$ 0', ',00']);
    });

    test('formatSummaryValue formats with and without cents appropriately', () {
      expect(CurrencyFormatter.formatSummaryValue(100.0), 'R\$ 100');
      expect(CurrencyFormatter.formatSummaryValue(100.50), 'R\$ 100,50');
      expect(CurrencyFormatter.formatSummaryValue(1234567.89), 'R\$ 1.234.567,89');
    });
  });

  group('CurrencyInputFormatter Tests', () {
    test('formats digits progressively as financial currency', () {
      const formatter = CurrencyInputFormatter();

      // Typing '5'
      var result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '5',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(result.text, 'R\$\u00A00,05');

      // Typing '50'
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '50',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, 'R\$\u00A00,50');

      // Typing '500'
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '500',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, 'R\$\u00A05,00');

      // Typing '50000'
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '50000',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(result.text, 'R\$\u00A0500,00');
    });

    test('handles empty input when allowEmpty is true', () {
      const formatter = CurrencyInputFormatter(allowEmpty: true);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: 'R\$ 0,05'),
        const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(result.text, '');
    });

    test('handles empty input when allowEmpty is false', () {
      const formatter = CurrencyInputFormatter(allowEmpty: false);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: 'R\$ 0,05'),
        const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(result.text, 'R\$ 0,00');
    });
  });
}
