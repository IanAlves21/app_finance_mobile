class CurrencyFormatter {
  /// Formats a double value into two parts:
  /// 1. The currency prefix and integer part with thousands dot separator (e.g. `R$ 24.381` or `-R$ 10.000`)
  /// 2. The cents part (e.g. `,50`)
  static List<String> formatBalanceParts(double value) {
    final String sign = value < 0 ? '-' : '';
    final double absValue = value.abs();
    final String cents = (absValue % 1).toStringAsFixed(2).split('.')[1];
    final int integers = absValue.toInt();

    // Format thousands separator
    final String integerStr = integers.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < integerStr.length; i++) {
      if (i > 0 && (integerStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerStr[i]);
    }

    return ['${sign}R\$ $buffer', ',$cents'];
  }

  /// Formats a double value into a single BRL currency string.
  /// If the cents part is `00`, it truncates it (e.g. `R$ 9.200`).
  /// Otherwise, it shows with cents (e.g. `R$ 9.200,50`).
  static String formatSummaryValue(double value) {
    final double absValue = value.abs();
    final String cents = (absValue % 1).toStringAsFixed(2).split('.')[1];
    final int integers = absValue.toInt();

    // Format thousands separator
    final String integerStr = integers.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < integerStr.length; i++) {
      if (i > 0 && (integerStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerStr[i]);
    }

    if (cents == '00') {
      return 'R\$ $buffer';
    } else {
      return 'R\$ $buffer,$cents';
    }
  }
}
