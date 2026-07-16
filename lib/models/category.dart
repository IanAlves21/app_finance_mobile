class Category {
  final String id;
  final String name;
  final String? icon;
  final String type; // 'INCOME' ou 'EXPENSE'
  final String color; // formato hex (ex: '#1A2D5A')
  final String? familyId;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    this.color = '#1A2D5A',
    this.familyId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      type: json['type']?.toString() ?? 'EXPENSE',
      color: json['color']?.toString() ?? '#1A2D5A',
      familyId: json['familyId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
      'color': color,
      'familyId': familyId,
    };
  }
}
