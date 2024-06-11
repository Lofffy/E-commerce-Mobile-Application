class Category {
  final int categoryId;
  final String categoryName;

  Category({
    required this.categoryId,
    required this.categoryName,
  });

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }
}
