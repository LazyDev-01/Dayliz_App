import 'package:flutter/material.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/svg_icon_button.dart';
import '../../widgets/common/svg_icon.dart';

/// Demo screen to showcase the unified app bar system
class UnifiedAppBarDemoScreen extends StatelessWidget {
  const UnifiedAppBarDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Unified App Bar Demo',
        fallbackRoute: '/home',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unified App Bar System Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'This screen demonstrates the new unified app bar system with:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            const _FeatureItem(
              icon: DaylizIcons.home,
              title: 'White Background',
              description: 'Clean white background for consistency',
            ),
            const _FeatureItem(
              icon: DaylizIcons.eye,
              title: 'Shadow Effect',
              description: 'Subtle shadow for depth and separation',
            ),
            const _FeatureItem(
              icon: DaylizIcons.edit,
              title: 'Dark Grey Text',
              description: 'Consistent dark grey text for titles',
            ),
            const _FeatureItem(
              icon: DaylizIcons.arrowBackward,
              title: 'Smart Back Button',
              description: 'Two types: previous page & direct home',
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Test Different App Bar Types:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            
            // Demo buttons for different app bar types
            _DemoButton(
              title: 'Previous Page Back',
              description: 'Standard back navigation',
              onPressed: () => _navigateToDemo(context, BackButtonType.previousPage),
            ),
            const SizedBox(height: 12),
            _DemoButton(
              title: 'Direct Home Back',
              description: 'Direct navigation to home',
              onPressed: () => _navigateToDemo(context, BackButtonType.directHome),
            ),
            const SizedBox(height: 12),
            _DemoButton(
              title: 'With Search Action',
              description: 'App bar with search functionality',
              onPressed: () => _navigateToSearchDemo(context),
            ),
            const SizedBox(height: 12),
            _DemoButton(
              title: 'With Cart Action',
              description: 'App bar with cart functionality',
              onPressed: () => _navigateToCartDemo(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDemo(BuildContext context, BackButtonType backType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DemoDetailScreen(
          title: backType == BackButtonType.previousPage 
              ? 'Previous Page Demo' 
              : 'Direct Home Demo',
          backButtonType: backType,
        ),
      ),
    );
  }

  void _navigateToSearchDemo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _SearchDemoScreen(),
      ),
    );
  }

  void _navigateToCartDemo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _CartDemoScreen(),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final DaylizIcons icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF374151).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon.small(color: const Color(0xFF374151)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;

  const _DemoButton({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                DaylizIcons.right.small(color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoDetailScreen extends StatelessWidget {
  final String title;
  final BackButtonType backButtonType;

  const _DemoDetailScreen({
    required this.title,
    required this.backButtonType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBar(
        title: title,
        backButtonType: backButtonType,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF374151).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  (backButtonType == BackButtonType.previousPage 
                      ? DaylizIcons.arrowBackward 
                      : DaylizIcons.home).extraLarge(
                    color: const Color(0xFF374151),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    backButtonType == BackButtonType.previousPage
                        ? 'Previous Page Navigation'
                        : 'Direct Home Navigation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    backButtonType == BackButtonType.previousPage
                        ? 'Back button will navigate to the previous screen'
                        : 'Back button will navigate directly to home screen',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDemoScreen extends StatelessWidget {
  const _SearchDemoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBars.withSearch(
        title: 'Search Demo',
        onSearchPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search pressed!')),
          );
        },
      ),
      body: const Center(
        child: Text(
          'App bar with search action',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _CartDemoScreen extends StatelessWidget {
  const _CartDemoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBars.withCart(
        title: 'Cart Demo',
        onCartPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cart pressed!')),
          );
        },
        cartItemCount: 3,
      ),
      body: const Center(
        child: Text(
          'App bar with cart action (3 items)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
