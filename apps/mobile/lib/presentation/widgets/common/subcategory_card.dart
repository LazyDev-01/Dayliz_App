import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SubCategory {
  final String id;
  final String name;
  final String parentId;
  final String? imageUrl;
  final int productCount;

  SubCategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.imageUrl,
    required this.productCount,
  });
}

class SubcategoryCard extends StatelessWidget {
  final SubCategory subCategory;
  final String parentCategoryName;
  final VoidCallback? onTap;
  final Color? themeColor;

  const SubcategoryCard({
    Key? key,
    required this.subCategory,
    required this.parentCategoryName,
    this.onTap,
    this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: subCategory.imageUrl ?? 'https://placehold.co/100/CCCCCC/FFFFFF?text=No+Image',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                subCategory.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subCategory.productCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${subCategory.productCount} ${subCategory.productCount == 1 ? 'product' : 'products'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 