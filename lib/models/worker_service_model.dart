class WorkerServiceModel {
  final int workerServiceId;
  final int workerProfileId;
  final int categoryId;
  final String? customServiceName;
  final double? price;
  final String? priceType;
  final String? description;
  final bool isActive;
  final String? categoryName;

  WorkerServiceModel({
    required this.workerServiceId,
    required this.workerProfileId,
    required this.categoryId,
    this.customServiceName,
    this.price,
    this.priceType,
    this.description,
    this.isActive = true,
    this.categoryName,
  });

  String get displayName => customServiceName ?? categoryName ?? 'Service';

  String get formattedPrice {
    if (price == null || price == 0) return 'Negotiable';
    String unit = '';
    if (priceType != null && priceType != 'negotiable') {
      String pt = priceType!.toLowerCase();
      if (pt == 'oras' || pt == 'hour' || pt == 'hr') {
        pt = 'hr';
      } else if (pt == 'araw' || pt == 'day') {
        pt = 'day';
      } else if (pt == 'bahay' || pt == 'home' || pt == 'house') {
        pt = 'home';
      }
      unit = '/$pt';
    }
    return '₱${price!.toStringAsFixed(0)}$unit';
  }

  factory WorkerServiceModel.fromMap(Map<String, dynamic> map, {String? categoryName}) {
    return WorkerServiceModel(
      workerServiceId: map['worker_service_id'] is int ? map['worker_service_id'] : int.tryParse(map['worker_service_id'].toString()) ?? 0,
      workerProfileId: map['worker_profile_id'] is int ? map['worker_profile_id'] : int.tryParse(map['worker_profile_id'].toString()) ?? 0,
      categoryId: map['category_id'] is int ? map['category_id'] : int.tryParse(map['category_id'].toString()) ?? 0,
      customServiceName: map['custom_service_name']?.toString(),
      price: map['price'] != null ? double.tryParse(map['price'].toString()) : null,
      priceType: map['price_type']?.toString(),
      description: map['description']?.toString(),
      isActive: map['is_active'] == 1 || map['is_active'] == true || map['is_active'] == null,
      categoryName: categoryName ?? map['category_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'worker_service_id': workerServiceId,
      'worker_profile_id': workerProfileId,
      'category_id': categoryId,
      'custom_service_name': customServiceName,
      'price': price,
      'price_type': priceType,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }
}
