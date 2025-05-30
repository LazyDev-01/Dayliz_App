import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../di/dependency_injection.dart' as di;
import '../../providers/auth_providers.dart';

/// A developer screen to configure backend settings
/// This screen allows switching between Supabase and FastAPI backends
/// Only available in debug mode
class BackendConfigScreen extends ConsumerStatefulWidget {
  const BackendConfigScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackendConfigScreen> createState() => _BackendConfigScreenState();
}

class _BackendConfigScreenState extends ConsumerState<BackendConfigScreen> {
  bool _useFastAPI = AppConfig.useFastAPI;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card
            Card(
              color: Colors.amber[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Developer Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These settings are for development and testing purposes only. '
                      'Changing the backend will sign you out and may cause data inconsistencies.',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Current backend info
            Text(
              'Current Backend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _useFastAPI ? 'FastAPI (Experimental)' : 'Supabase',
              style: TextStyle(
                color: _useFastAPI ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Backend switch
            SwitchListTile(
              title: const Text('Use FastAPI Backend'),
              subtitle: Text(
                _useFastAPI 
                    ? 'Using experimental FastAPI backend'
                    : 'Using stable Supabase backend',
              ),
              value: _useFastAPI,
              onChanged: _isLoading ? null : _toggleBackend,
            ),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Apply button
            if (_useFastAPI != AppConfig.useFastAPI)
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _applyChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Apply Changes'),
                ),
              ),
              
            const Spacer(),
            
            // Supabase info
            if (!_useFastAPI)
              _buildInfoSection(
                title: 'Supabase Connection',
                items: [
                  'URL: ${_truncateString(AppConfig.supabaseUrl)}',
                  'Status: ${Supabase.instance.client.auth.currentSession != null ? "Connected" : "Not Connected"}',
                ],
              ),
            
            // FastAPI info
            if (_useFastAPI)
              _buildInfoSection(
                title: 'FastAPI Connection',
                items: [
                  'URL: ${AppConfig.fastApiBaseUrl}',
                  'Status: Not Implemented',
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection({required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(item),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
  
  void _toggleBackend(bool value) {
    setState(() {
      _useFastAPI = value;
      _errorMessage = null;
    });
  }
  
  Future<void> _applyChanges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Sign out the current user
      await ref.read(authNotifierProvider.notifier).logout();
      
      // Update the backend setting
      await AppConfig.setUseFastAPI(_useFastAPI);
      
      // Reinitialize the dependency injection
      await di.reInitializeAuthDependencies();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backend changed to ${_useFastAPI ? "FastAPI" : "Supabase"}. Please sign in again.'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to change backend: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  String _truncateString(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
} 