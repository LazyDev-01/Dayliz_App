import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

                FeatureCard(
                  title: 'Product Listing',
                  subtitle: 'Browse our catalog of products',
                  iconData: Icons.shopping_bag,
                  onTap: () {
                    GoRouter.of(context).push('/clean/products');
                  },
                ), 