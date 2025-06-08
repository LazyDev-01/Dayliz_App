import 'package:flutter/material.dart';
import 'presentation/screens/home/category_icons_demo.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const CategoryIconsTestApp());
}

class CategoryIconsTestApp extends StatelessWidget {
  const CategoryIconsTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Category Icons Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CategoryIconsDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}