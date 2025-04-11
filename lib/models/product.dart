class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final double? rating;
  final double? discountPercentage;
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.rating,
    this.discountPercentage,
  });
  
  // Create a Product from JSON data
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['image_url'],
      description: json['description'] ?? '',
      rating: json['rating']?.toDouble(),
      discountPercentage: json['discount_percentage']?.toDouble(),
    );
  }
  
  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'rating': rating,
      'discount_percentage': discountPercentage,
    };
  }
} 