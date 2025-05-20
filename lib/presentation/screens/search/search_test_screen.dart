import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../providers/search_providers.dart';

/// A simple test screen for the search functionality
class SearchTestScreen extends ConsumerWidget {
  const SearchTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.push('/search');
              },
              child: const Text('Go to Search Screen'),
            ),
            const SizedBox(height: 20),
            const Text('This is a test screen for the search functionality'),
          ],
        ),
      ),
    );
  }
}
