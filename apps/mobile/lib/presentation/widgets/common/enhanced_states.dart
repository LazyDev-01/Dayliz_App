import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Enhanced error and empty states for better user experience
class EnhancedStates {
  
  /// Premium error state with illustration
  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    String retryText = 'Try Again',
    IconData? icon,
    String? illustration,
  }) {
    return _EnhancedErrorState(
      message: message,
      onRetry: onRetry,
      retryText: retryText,
      icon: icon,
      illustration: illustration,
    );
  }

  /// Empty cart state with call-to-action
  static Widget emptyCartState({
    VoidCallback? onStartShopping,
    String title = 'Your cart is empty',
    String subtitle = 'Add some delicious items to get started!',
    String buttonText = 'Start Shopping',
  }) {
    return _EmptyCartState(
      onStartShopping: onStartShopping,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
    );
  }

  /// Empty search results state
  static Widget emptySearchState({
    required String query,
    VoidCallback? onClearSearch,
    List<String>? suggestions,
  }) {
    return _EmptySearchState(
      query: query,
      onClearSearch: onClearSearch,
      suggestions: suggestions,
    );
  }

  /// No internet connection state
  static Widget noInternetState({
    VoidCallback? onRetry,
  }) {
    return _NoInternetState(onRetry: onRetry);
  }

  /// Success state with animation
  static Widget successState({
    required String message,
    VoidCallback? onContinue,
    String continueText = 'Continue',
    Duration autoNavigateDelay = const Duration(seconds: 3),
  }) {
    return _SuccessState(
      message: message,
      onContinue: onContinue,
      continueText: continueText,
      autoNavigateDelay: autoNavigateDelay,
    );
  }
}

/// Enhanced error state implementation
class _EnhancedErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData? icon;
  final String? illustration;

  const _EnhancedErrorState({
    required this.message,
    this.onRetry,
    required this.retryText,
    this.icon,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or icon
            if (illustration != null)
              Lottie.asset(
                illustration!,
                width: 200,
                height: 200,
                repeat: false,
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.error_outline,
                  size: 60,
                  color: Colors.red[400],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Error message
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty cart state implementation
class _EmptyCartState extends StatelessWidget {
  final VoidCallback? onStartShopping;
  final String title;
  final String subtitle;
  final String buttonText;

  const _EmptyCartState({
    this.onStartShopping,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cart illustration
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onStartShopping != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onStartShopping,
                icon: const Icon(Icons.shopping_bag),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty search state implementation
class _EmptySearchState extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;
  final List<String>? suggestions;

  const _EmptySearchState({
    required this.query,
    this.onClearSearch,
    this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Search illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                children: [
                  const TextSpan(text: 'We couldn\'t find anything for '),
                  TextSpan(
                    text: '"$query"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '. Try a different search term.'),
                ],
              ),
            ),
            
            if (onClearSearch != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
            ],
            
            if (suggestions != null && suggestions!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Try searching for:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions!.map((suggestion) => 
                  Chip(
                    label: Text(suggestion),
                    backgroundColor: Colors.grey[100],
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No internet state implementation
class _NoInternetState extends StatelessWidget {
  final VoidCallback? onRetry;

  const _NoInternetState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off,
                size: 60,
                color: Colors.orange[400],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Please check your internet connection and try again.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success state implementation
class _SuccessState extends StatefulWidget {
  final String message;
  final VoidCallback? onContinue;
  final String continueText;
  final Duration autoNavigateDelay;

  const _SuccessState({
    required this.message,
    this.onContinue,
    required this.continueText,
    required this.autoNavigateDelay,
  });

  @override
  State<_SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<_SuccessState> {
  @override
  void initState() {
    super.initState();
    if (widget.onContinue != null) {
      Future.delayed(widget.autoNavigateDelay, () {
        if (mounted) {
          widget.onContinue!();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[400],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Success!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (widget.onContinue != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.continueText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
