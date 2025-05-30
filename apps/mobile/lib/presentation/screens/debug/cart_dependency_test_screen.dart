import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// A debug screen to test cart dependencies
class CartDependencyTestScreen extends StatefulWidget {
  const CartDependencyTestScreen({Key? key}) : super(key: key);

  @override
  State<CartDependencyTestScreen> createState() => _CartDependencyTestScreenState();
}

class _CartDependencyTestScreenState extends State<CartDependencyTestScreen> {
  final sl = GetIt.instance;
  final List<String> _logs = [];
  bool _isLoading = true;
  Map<String, bool> _dependencies = {};

  @override
  void initState() {
    super.initState();
    _checkDependencies();
  }

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
    debugPrint(message);
  }

  Future<void> _checkDependencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _log('Checking cart dependencies...');

      final dependencies = {
        'GetCartItemsUseCase': _checkDependencyByName('GetCartItemsUseCase'),
        'AddToCartUseCase': _checkDependencyByName('AddToCartUseCase'),
        'RemoveFromCartUseCase': _checkDependencyByName('RemoveFromCartUseCase'),
        'UpdateCartQuantityUseCase': _checkDependencyByName('UpdateCartQuantityUseCase'),
        'ClearCartUseCase': _checkDependencyByName('ClearCartUseCase'),
        'GetCartTotalPriceUseCase': _checkDependencyByName('GetCartTotalPriceUseCase'),
        'GetCartItemCountUseCase': _checkDependencyByName('GetCartItemCountUseCase'),
        'IsInCartUseCase': _checkDependencyByName('IsInCartUseCase'),
      };

      setState(() {
        _dependencies = dependencies;
        _isLoading = false;
      });

      final allRegistered = dependencies.values.every((registered) => registered);
      _log(allRegistered
        ? '✅ All cart dependencies are registered properly'
        : '⚠️ Some cart dependencies are not registered properly!');
    } catch (e) {
      _log('Error checking dependencies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _checkDependencyByName(String name) {
    try {
      // First try by instance name
      final isRegisteredByName = sl.isRegistered(instanceName: name);

      // Then try by type if available (this might not work for all types)
      bool isRegisteredByType = false;
      try {
        // We can't use generic type parameters here, so we'll just check if it's registered
        // This is just a fallback and might not be accurate
        isRegisteredByType = false;
      } catch (e) {
        // Ignore errors when checking by type
      }

      final isRegistered = isRegisteredByName || isRegisteredByType;
      _log('$name registered: $isRegistered (by name: $isRegisteredByName)');
      return isRegistered;
    } catch (e) {
      _log('Error checking $name: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Dependency Test'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cart Dependencies Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._dependencies.entries.map((entry) => _buildDependencyItem(entry.key, entry.value)),
                  const SizedBox(height: 24),
                  const Text(
                    'Logs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _logs
                          .map((log) => Text(
                                log,
                                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkDependencies,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDependencyItem(String name, bool isRegistered) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isRegistered ? Icons.check_circle : Icons.error,
            color: isRegistered ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
