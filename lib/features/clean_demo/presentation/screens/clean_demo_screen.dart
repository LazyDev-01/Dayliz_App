import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/feature_card.dart';

class CleanDemoScreen extends StatelessWidget {
  const CleanDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clean Architecture Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                FeatureCard(
                  title: 'Product Listing',
                  subtitle: 'Browse our catalog of products',
                  iconData: Icons.shopping_bag,
                  onTap: () {
                    GoRouter.of(context).push('/clean/products');
                  },
                ),
                FeatureCard(
                  title: 'Categories',
                  subtitle: 'Browse product categories',
                  iconData: Icons.category,
                  onTap: () {
                    GoRouter.of(context).push('/clean/categories');
                  },
                ),
                FeatureCard(
                  title: 'Profile',
                  subtitle: 'View your profile',
                  iconData: Icons.person,
                  onTap: () {
                    GoRouter.of(context).push('/clean/profile');
                  },
                ),
                FeatureCard(
                  title: 'Cart',
                  subtitle: 'View your shopping cart',
                  iconData: Icons.shopping_cart,
                  onTap: () {
                    GoRouter.of(context).push('/clean/cart');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}