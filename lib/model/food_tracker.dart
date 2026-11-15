class FoodTracker {
  const FoodTracker({
    this.id,
    this.createdAt,
    required this.foodDate,
    required this.foodMeal,
    required this.foodName,
    required this.foodPrice,
    required this.foodPerson,
    this.foodImageUrl,
  });

  final String? id;
  final DateTime? createdAt;
  final String foodDate;
  final String foodMeal;
  final String foodName;
  final double foodPrice;
  final int foodPerson;
  final String? foodImageUrl;

  Map<String, dynamic> toJson() => {
        'foodDate': foodDate,
        'foodMeal': foodMeal,
        'foodName': foodName,
        'foodPrice': foodPrice,
        'foodPerson': foodPerson,
        'foodImageUrl': foodImageUrl,
      };

  factory FoodTracker.fromJson(Map<String, dynamic> json) {
    return FoodTracker(
      id: json['id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      foodDate: json['foodDate'] as String,
      foodMeal: json['foodMeal'] as String,
      foodName: json['foodName'] as String,
      foodPrice: (json['foodPrice'] as num).toDouble(),
      foodPerson: json['foodPerson'] as int,
      foodImageUrl: json['foodImageUrl'] as String?,
    );
  }
}
