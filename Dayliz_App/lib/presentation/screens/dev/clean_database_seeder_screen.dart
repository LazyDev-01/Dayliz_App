import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/clean_database_seeder.dart';

final seedingLogProvider = StateProvider<List<String>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final seedingProgressProvider = StateProvider<double>((ref) => 0.0);
final seedingStepProvider = StateProvider<String>((ref) => '');

/// A clean architecture development utility screen that allows seeding the database
/// with sample data for testing purposes.
class CleanDatabaseSeederScreen extends ConsumerStatefulWidget {
  static const String routeName = '/dev/clean-database-seeder';

  const CleanDatabaseSeederScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanDatabaseSeederScreen> createState() => _CleanDatabaseSeederScreenState();
}

class _CleanDatabaseSeederScreenState extends ConsumerState<CleanDatabaseSeederScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _clearExistingData = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLogMessage(String message) {
    final logs = [...ref.read(seedingLogProvider)];
    logs.add(message);
    ref.read(seedingLogProvider.notifier).state = logs;
    
    // Scroll to bottom
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
          await CleanDatabaseSeeder.instance.clearExistingData(
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
      await CleanDatabaseSeeder.instance.seedDatabase(
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

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(seedingLogProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final progress = ref.watch(seedingProgressProvider);
    final step = ref.watch(seedingStepProvider);
    
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
          
          // Progress indicator
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(step),
                ],
              ),
            ),
          
          // Seed button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : _seedDatabase,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Seed Database'),
            ),
          ),
          
          // Log output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  Color textColor = Colors.white;
                  
                  if (log.contains('✅')) {
                    textColor = Colors.green;
                  } else if (log.contains('❌')) {
                    textColor = Colors.red;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.yellow;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
