import '../config/env_config.dart';

class CategoryModel {
  final dynamic id;
  final String categoryName;
  final String? categoryImage;

  CategoryModel({
    required this.id,
    required this.categoryName,
    this.categoryImage,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['category_image'] ??
        json['categoryImage'] ??
        json['image'] ??
        json['icon'] ??
        json['imageUrl'] ??
        json['image_url'];

    String? formattedImage;
    if (rawImage != null && rawImage.toString().trim().isNotEmpty) {
      formattedImage = EnvConfig.formatImageUrl(rawImage.toString().trim());
    }

    return CategoryModel(
      id: json['id'] ?? json['categoryId'] ?? json['category_id'] ?? 0,
      categoryName: (json['category_name'] ??
              json['categoryName'] ??
              json['name'] ??
              'Category')
          .toString()
          .trim(),
      categoryImage: formattedImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': categoryName,
      'category_image': categoryImage,
    };
  }
}

