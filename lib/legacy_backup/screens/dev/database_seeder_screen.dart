import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:dayliz_app/services/database_seeder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final seedingLogProvider = StateProvider<List<String>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final seedingProgressProvider = StateProvider<double>((ref) => 0.0);
final seedingStepProvider = StateProvider<String>((ref) => '');

/// A development utility screen that allows seeding the database
/// with sample data for testing purposes.
class DatabaseSeederScreen extends ConsumerStatefulWidget {
  static const String routeName = '/dev/database-seeder';

  const DatabaseSeederScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DatabaseSeederScreen> createState() => _DatabaseSeederScreenState();
}

class _DatabaseSeederScreenState extends ConsumerState<DatabaseSeederScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _clearExistingData = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _seedDatabase() async {
    // Clear previous logs
    ref.read(seedingLogProvider.notifier).state = [];
    
    // Reset progress
    ref.read(seedingProgressProvider.notifier).state = 0.0;
    ref.read(seedingStepProvider.notifier).state = 'Preparing...';
    
    // Set loading state
    ref.read(isLoadingProvider.notifier).state = true;
    
    try {
      // Add initial log message
      _addLogMessage('Starting database seeding process...');
      
      if (_clearExistingData) {
        _addLogMessage('Clearing existing data before seeding...');
        ref.read(seedingStepProvider.notifier).state = 'Clearing data...';
        
        try {
          await DatabaseSeeder.instance.clearExistingData(
            onLog: (message) {
              _addLogMessage(message);
            },
            onProgress: (progress) {
              ref.read(seedingProgressProvider.notifier).state = progress * 0.3;
            },
          );
          
          _addLogMessage('✅ Existing data cleared successfully');
        } catch (e) {
          _addLogMessage('❌ Error clearing data: $e');
        }
      }
      
      // Update step
      ref.read(seedingStepProvider.notifier).state = 'Testing connections...';
      ref.read(seedingProgressProvider.notifier).state = _clearExistingData ? 0.3 : 0.1;
      
      // Run the database seeder
      await DatabaseSeeder.instance.seedDatabase(
        onLog: (message) {
          _addLogMessage(message);
          
          // Update progress based on the message
          if (message.contains('Testing database connections')) {
            ref.read(seedingStepProvider.notifier).state = 'Testing connections...';
            ref.read(seedingProgressProvider.notifier).state = _clearExistingData ? 0.4 : 0.2;
          } else if (message.contains('Seeding categories')) {
            ref.read(seedingStepProvider.notifier).state = 'Seeding categories...';
            ref.read(seedingProgressProvider.notifier).state = _clearExistingData ? 0.6 : 0.5;
          } else if (message.contains('Seeding products')) {
            ref.read(seedingStepProvider.notifier).state = 'Seeding products...';
            ref.read(seedingProgressProvider.notifier).state = _clearExistingData ? 0.8 : 0.8;
          }
        },
      );
      
      // Complete progress
      ref.read(seedingProgressProvider.notifier).state = 1.0;
      ref.read(seedingStepProvider.notifier).state = 'Completed';
      
      // Add completion message
      _addLogMessage('✅ Database seeding process completed!');
      
      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database seeded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _addLogMessage('❌ Error during database seeding: $e');
      log('Error seeding database: $e');
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding database: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Reset loading state
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }
  
  void _addLogMessage(String message) {
    final currentLogs = [...ref.read(seedingLogProvider)];
    currentLogs.add(message);
    ref.read(seedingLogProvider.notifier).state = currentLogs;
    
    // Scroll to bottom of log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(seedingLogProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final progress = ref.watch(seedingProgressProvider);
    final currentStep = ref.watch(seedingStepProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Seeder'),
      ),
      body: Column(
        children: [
          // Instructions
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This utility allows you to seed the database with sample data for development purposes.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          
          // Clear data checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SwitchListTile(
              title: const Text('Clear existing data before seeding'),
              subtitle: const Text(
                'Warning: This will delete all existing categories, subcategories and products',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              value: _clearExistingData,
              onChanged: isLoading 
                  ? null 
                  : (value) {
                      setState(() {
                        _clearExistingData = value;
                      });
                    },
            ),
          ),
          
          // Progress indicator (only visible when loading)
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStep,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              ),
            ),
          
          // Seed button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _seedDatabase,
                icon: isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ) 
                    : const Icon(Icons.cloud_upload),
                label: Text(isLoading ? 'Seeding...' : 'Seed Database'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Log output
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Log Output:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const Divider(height: 8),
          
          // Log content
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet. Press the button to start seeding.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          
                          // Determine if this is an error or success message
                          final bool isError = log.contains('❌') || log.contains('Error');
                          final bool isSuccess = log.contains('✅');
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                color: isError 
                                    ? Colors.red[700]
                                    : isSuccess
                                        ? Colors.green[700]
                                        : Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 