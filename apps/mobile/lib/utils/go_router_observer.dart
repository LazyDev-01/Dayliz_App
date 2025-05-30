import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// A [NavigatorObserver] that logs navigation events for debugging.
/// Used with GoRouter to observe navigation events and handle deep links.
class GoRouterObserver extends NavigatorObserver {
  final Function(String)? onRouteChange;

  GoRouterObserver({this.onRouteChange});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  void _handleRouteChange(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName != null && onRouteChange != null) {
      onRouteChange!(routeName);
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