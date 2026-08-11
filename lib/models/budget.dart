class Budget {
  final String id;
  final double amount;
  final int month;
  final int year;
  final String categoryId;
  final String familyId;

  const Budget({
    required this.id,
    required this.amount,
    required this.month,
    required this.year,
    required this.categoryId,
    required this.familyId,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    double parsedAmount = 0.0;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    return Budget(
      id: json['id']?.toString() ?? '',
      amount: parsedAmount,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      categoryId: json['categoryId']?.toString() ?? '',
      familyId: json['familyId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'month': month,
      'year': year,
      'categoryId': categoryId,
      'familyId': familyId,
    };
  }
}
