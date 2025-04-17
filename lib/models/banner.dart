import 'package:flutter/foundation.dart';

/// Model class for carousel banners on the home screen
class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionUrl;
  
  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.actionUrl,
  });
  
  /// Create a BannerModel from JSON data
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['image_url'] as String,
      actionUrl: json['action_url'] as String,
    );
  }
  
  /// Convert BannerModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'action_url': actionUrl,
    };
  }
  
  /// Create a copy of BannerModel with optional field updates
  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BannerModel &&
        other.id == id &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.imageUrl == imageUrl &&
        other.actionUrl == actionUrl;
  }
  
  @override
  int get hashCode => 
    id.hashCode ^ 
    title.hashCode ^ 
    subtitle.hashCode ^ 
    imageUrl.hashCode ^ 
    actionUrl.hashCode;
} 