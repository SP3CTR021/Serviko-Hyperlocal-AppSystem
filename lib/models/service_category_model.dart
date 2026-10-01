class ServiceCategoryModel {
  final int categoryId;
  final String categoryName;
  final String? categoryImageUrl;
  final String? description;
  final int displayOrder;
  final bool isActive;

  ServiceCategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryImageUrl,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ServiceCategoryModel.fromMap(Map<String, dynamic> map) {
    return ServiceCategoryModel(
      categoryId: map['category_id'] is int ? map['category_id'] : int.tryParse(map['category_id'].toString()) ?? 0,
      categoryName: map['category_name']?.toString() ?? '',
      categoryImageUrl: map['category_image_url']?.toString(),
      description: map['description']?.toString(),
      displayOrder: map['display_order'] is int ? map['display_order'] : int.tryParse(map['display_order']?.toString() ?? '0') ?? 0,
      isActive: map['is_active'] == 1 || map['is_active'] == true || map['is_active'] == null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_image_url': categoryImageUrl,
      'description': description,
      'display_order': displayOrder,
      'is_active': isActive ? 1 : 0,
    };
  }
}
