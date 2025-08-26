import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Services screen showing all available services
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coming Soon Message
            _buildComingSoonMessage(),

            const SizedBox(height: 32),

            // Future Services Preview
            _buildFutureServicesPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981),
            const Color(0xFF10B981).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Services Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We\'re working hard to bring you amazing services like laundry, bakery, and more. Stay tuned!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFutureServicesPreview() {
    final futureServices = [
      {
        'icon': Icons.local_laundry_service,
        'title': 'Laundry Services',
        'description': 'Wash & Fold, Dry Cleaning, Express Service',
        'color': Colors.blue,
      },
      {
        'icon': Icons.cake,
        'title': 'Bakery Services',
        'description': 'Fresh Bakery, Custom Cakes, Occasion Cakes',
        'color': Colors.orange,
      },
      {
        'icon': Icons.local_florist,
        'title': 'Gifting & Flowers',
        'description': 'Flower Bouquets, Hampers, Personalized Gifts',
        'color': Colors.pink,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...futureServices.map((service) => _buildFutureServiceCard(service)),
        ],
      ),
    );
  }

  Widget _buildFutureServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (service['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            service['icon'] as IconData,
            color: service['color'] as Color,
            size: 24,
          ),
        ),
        title: Text(
          service['title'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          service['description'] as String,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
