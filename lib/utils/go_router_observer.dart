import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// A [NavigatorObserver] that logs navigation events for debugging.
/// Used with GoRouter to observe navigation events and handle deep links.
class GoRouterObserver extends NavigatorObserver {
  GoRouterObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('🧭 Navigator: PUSHED ${route.settings.name} (previous: ${previousRoute?.settings.name})');
    _logRouteInfo(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('🧭 Navigator: POPPED ${route.settings.name} (previous: ${previousRoute?.settings.name})');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('🧭 Navigator: REMOVED ${route.settings.name} (previous: ${previousRoute?.settings.name})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('🧭 Navigator: REPLACED ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
    if (newRoute != null) {
      _logRouteInfo(newRoute);
    }
  }

  void _logRouteInfo(Route<dynamic> route) {
    // Log additional information about the route for deep linking
    final settings = route.settings;
    if (settings.arguments != null) {
      debugPrint('🧭 Route arguments: ${settings.arguments}');
    }
    
    final pathParams = _extractPathParams(settings.name);
    if (pathParams.isNotEmpty) {
      debugPrint('🧭 Path parameters: $pathParams');
    }
  }

  Map<String, String> _extractPathParams(String? routeName) {
    if (routeName == null) return {};
    
    // Extract path parameters from a route name
    // Example: extracting 'id' from '/products/:id'
    final params = <String, String>{};
    final parts = routeName.split('/').where((part) => part.isNotEmpty).toList();
    
    for (var part in parts) {
      if (part.startsWith(':')) {
        final paramName = part.substring(1);
        final value = part.contains('=') ? part.split('=')[1] : '';
        params[paramName] = value;
      }
    }
    
    return params;
  }
} 