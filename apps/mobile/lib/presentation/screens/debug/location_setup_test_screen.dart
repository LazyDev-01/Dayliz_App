import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/usecases/usecase.dart';
import '../../providers/location_providers.dart';

/// Debug screen for testing location setup workflow
class LocationSetupTestScreen extends ConsumerWidget {
  const LocationSetupTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Setup Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Location Setup Workflow Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Test Location Permission
            ElevatedButton(
              onPressed: () async {
                final useCase = ref.read(requestLocationPermissionUseCaseProvider);
                final result = await useCase(NoParams());
                result.fold(
                  (failure) => _showSnackBar(context, 'Permission Error: ${failure.message}', Colors.red),
                  (permission) => _showSnackBar(context, 'Permission Status: $permission', Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Location Permission'),
            ),
            const SizedBox(height: 16),

            // Test Get Current Location
            ElevatedButton(
              onPressed: () async {
                final useCase = ref.read(getCurrentLocationUseCaseProvider);
                final result = await useCase(NoParams());
                result.fold(
                  (failure) => _showSnackBar(context, 'Location Error: ${failure.message}', Colors.red),
                  (coordinates) => _showSnackBar(
                    context,
                    'Location: ${coordinates.latitude}, ${coordinates.longitude}',
                    Colors.green
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Get Current Location'),
            ),
            const SizedBox(height: 16),

            // Test Location Services Status
            ElevatedButton(
              onPressed: () async {
                final useCase = ref.read(isLocationServiceEnabledUseCaseProvider);
                final result = await useCase(NoParams());
                result.fold(
                  (failure) => _showSnackBar(context, 'Service Error: ${failure.message}', Colors.red),
                  (isEnabled) => _showSnackBar(
                    context,
                    'Location Services: ${isEnabled ? "Enabled" : "Disabled"}',
                    isEnabled ? Colors.green : Colors.orange
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Location Services'),
            ),
            const SizedBox(height: 32),

            // Navigation Tests
            const Text(
              'Navigation Tests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => context.go('/location-setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Go to Location Setup'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => context.go('/location-search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Go to Location Search'),
            ),
            const SizedBox(height: 16),

            // Setup Status
            Consumer(
              builder: (context, ref, child) {
                final isSetupCompleted = ref.watch(isLocationSetupCompletedProvider);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSetupCompleted ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSetupCompleted ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    'Location Setup Status: ${isSetupCompleted ? "Completed" : "Not Completed"}',
                    style: TextStyle(
                      color: isSetupCompleted ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
