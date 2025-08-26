import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/laundry_service.dart';
import '../../../domain/entities/address.dart';
import '../../providers/laundry_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/address/address_form_bottom_sheet.dart';

class LaundryBookingScreen extends ConsumerStatefulWidget {
  const LaundryBookingScreen({super.key});

  @override
  ConsumerState<LaundryBookingScreen> createState() => _LaundryBookingScreenState();
}

class _LaundryBookingScreenState extends ConsumerState<LaundryBookingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(laundryBookingFormNotifierProvider);
    final formNotifier = ref.read(laundryBookingFormNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UnifiedAppBars.withBackButton(
        title: 'Book Laundry Services',
        fallbackRoute: '/services/laundry',
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ServiceSelectionStep(
                  formState: formState,
                  formNotifier: formNotifier,
                  onNext: _nextStep,
                ),
                _SchedulingStep(
                  formState: formState,
                  formNotifier: formNotifier,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                ),
                _ConfirmationStep(
                  formState: formState,
                  formNotifier: formNotifier,
                  onPrevious: _previousStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Services', Icons.cleaning_services),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Schedule', Icons.schedule),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Confirm', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                  ? Colors.green 
                  : isActive 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300],
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted ? Colors.green : Colors.grey[300],
      ),
    );
  }
}

// Service Selection Step Widget
class _ServiceSelectionStep extends StatelessWidget {
  final LaundryBookingFormState formState;
  final LaundryBookingFormNotifier formNotifier;
  final VoidCallback onNext;

  const _ServiceSelectionStep({
    required this.formState,
    required this.formNotifier,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose one or more laundry services for your booking',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final servicesAsync = ref.watch(laundryServicesProvider);
                
                return servicesAsync.when(
                  data: (services) => _buildServicesList(context, services),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading services: $error'),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: formState.selectedServices.isNotEmpty ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue (${formState.selectedServices.length} service${formState.selectedServices.length == 1 ? '' : 's'})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, List<LaundryService> services) {
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final isSelected = formState.selectedServices.any((s) => s.id == service.id);
        
        return _ServiceCard(
          service: service,
          isSelected: isSelected,
          onTap: () => formNotifier.toggleService(service),
        );
      },
    );
  }
}

// Service Card Widget
class _ServiceCard extends StatelessWidget {
  final LaundryService service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Service Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getServiceColor(service.serviceType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getServiceIcon(service.serviceType),
                    color: _getServiceColor(service.serviceType),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From ₹${service.basePrice.toStringAsFixed(0)} + ₹${service.pricePerKg?.toStringAsFixed(0) ?? '0'}/kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${service.turnaroundHours}h turnaround',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection Indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(LaundryServiceType type) {
    switch (type) {
      case LaundryServiceType.dryClean:
        return Colors.purple;
      case LaundryServiceType.washFold:
        return Colors.green;
      case LaundryServiceType.steamIron:
        return Colors.orange;
      case LaundryServiceType.washIron:
        return Colors.blue;
    }
  }

  IconData _getServiceIcon(LaundryServiceType type) {
    switch (type) {
      case LaundryServiceType.dryClean:
        return Icons.dry_cleaning;
      case LaundryServiceType.washFold:
        return Icons.local_laundry_service;
      case LaundryServiceType.steamIron:
        return Icons.iron;
      case LaundryServiceType.washIron:
        return Icons.iron;
    }
  }
}









// Scheduling Step Widget
class _SchedulingStep extends ConsumerWidget {
  final LaundryBookingFormState formState;
  final LaundryBookingFormNotifier formNotifier;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _SchedulingStep({
    required this.formState,
    required this.formNotifier,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load addresses when this step is displayed
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser != null) {
      // Load addresses if not already loaded
      final userProfileState = ref.watch(userProfileNotifierProvider);
      if (userProfileState.addresses == null && !userProfileState.isAddressesLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userProfileNotifierProvider.notifier).loadAddresses(currentUser.id);
        });
      }
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Pickup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your pickup date and time',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  _buildDateSelection(context),

                  const SizedBox(height: 24),

                  // Time Slot Selection
                  _buildTimeSlotSelection(context),

                  const SizedBox(height: 24),

                  // Pickup Address Section (moved to bottom)
                  _buildAddressSection(context, ref),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSchedulingValid() ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, WidgetRef ref) {
    // Get addresses from user profile
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final addresses = userProfileState.addresses ?? [];

    // Get default address
    final defaultAddress = addresses.isNotEmpty
        ? addresses.firstWhere(
            (address) => address.isDefault,
            orElse: () => addresses.first,
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pickup Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address display based on cart implementation
          if (defaultAddress != null) ...[
            // Show selected address with change button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        defaultAddress.addressType?.toUpperCase() ?? 'ADDRESS',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${defaultAddress.addressLine1}${defaultAddress.addressLine2.isNotEmpty ? ', ${defaultAddress.addressLine2}' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      if (defaultAddress.landmark != null && defaultAddress.landmark!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Near ${defaultAddress.landmark}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  onPressed: () => _handleAddressSelection(context, ref),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Show add address button when no addresses
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NO ADDRESS SELECTED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Please add a pickup address',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  onPressed: () => _handleAddressSelection(context, ref),
                  child: const Text(
                    'ADD',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pickup Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index + 1));
                final isSelected = formState.pickupDate?.day == date.day;

                return _DateCard(
                  date: date,
                  isSelected: isSelected,
                  onTap: () => formNotifier.updatePickupDateTime(date, formState.pickupTimeSlot ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelection(BuildContext context) {
    final timeSlots = [
      '9:00 AM - 11:00 AM',
      '11:00 AM - 1:00 PM',
      '1:00 PM - 3:00 PM',
      '3:00 PM - 5:00 PM',
      '5:00 PM - 7:00 PM',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pickup Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((slot) {
              final isSelected = formState.pickupTimeSlot == slot;

              return _TimeSlotChip(
                timeSlot: slot,
                isSelected: isSelected,
                onTap: () => formNotifier.updatePickupDateTime(
                  formState.pickupDate ?? DateTime.now().add(const Duration(days: 1)),
                  slot,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Handles address selection with cart-style logic
  void _handleAddressSelection(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final addresses = userProfileState.addresses ?? [];

    if (addresses.isEmpty) {
      // Navigate to add new address
      _navigateToAddAddress(context, ref);
    } else if (addresses.length <= 10) {
      // Show scrollable bottom sheet for addresses
      _showInlineAddressSelection(context, ref, addresses);
    } else {
      // Navigate to full address selection page for many addresses
      _navigateToAddressSelection(context);
    }
  }

  /// Shows inline address selection bottom sheet (from cart implementation)
  void _showInlineAddressSelection(BuildContext context, WidgetRef ref, List<Address> addresses) {
    final defaultAddress = addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => addresses.first,
    );

    String? selectedAddressId = defaultAddress.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Select Pickup Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scrollable address list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: addresses.length + 1, // +1 for add button
                      itemBuilder: (context, index) {
                        if (index < addresses.length) {
                          // Address item
                          return _buildAddressOptionWithFeedback(
                            context,
                            ref,
                            addresses[index],
                            selectedAddressId,
                            (String addressId) {
                              setState(() {
                                selectedAddressId = addressId;
                              });
                            },
                          );
                        } else {
                          // Add new address button at the end
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildAddNewAddressButton(context, ref),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSchedulingValid() {
    return formState.pickupDate != null &&
           formState.pickupTimeSlot != null &&
           formState.selectedServices.isNotEmpty;
  }

  /// Builds address option with feedback (from cart implementation)
  Widget _buildAddressOptionWithFeedback(
    BuildContext context,
    WidgetRef ref,
    Address address,
    String? selectedAddressId,
    Function(String) onAddressSelected,
  ) {
    final isSelected = selectedAddressId == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // First, update the visual selection immediately
          onAddressSelected(address.id);

          // Capture context-dependent objects before async gap
          final navigator = Navigator.of(context);

          // Show immediate visual feedback with a slight delay
          await Future.delayed(const Duration(milliseconds: 300));

          // Then close the bottom sheet
          if (context.mounted) {
            navigator.pop();
          }

          // Update the default address in the background
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            try {
              await ref.read(userProfileNotifierProvider.notifier).setDefaultAddress(
                currentUser.id,
                address.id,
              );
            } catch (error) {
              debugPrint('❌ Address update failed: $error');
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? const Color(0xFF4CAF50).withValues(alpha: 0.05) : Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.addressType?.toUpperCase() ?? 'ADDRESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.addressLine1}${address.addressLine2.isNotEmpty ? ', ${address.addressLine2}' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                    if (address.landmark != null && address.landmark!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Near ${address.landmark}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds add new address button (from cart implementation)
  Widget _buildAddNewAddressButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _navigateToAddAddress(context, ref);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.add,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Add New Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to add new address using bottom sheet
  void _navigateToAddAddress(BuildContext context, WidgetRef ref) {
    AddressFormBottomSheet.show(context).then((_) {
      // Refresh addresses when returning from address form
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(userProfileNotifierProvider.notifier).loadAddresses(currentUser.id);
      }
    });
  }

  /// Navigate to full address selection page (placeholder)
  void _navigateToAddressSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Address Selection'),
          content: const Text(
            'Full address selection page will be implemented in the next development phase.\n\n'
            'For now, you can use the quick address selection or add a new address.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Date Card Widget
class _DateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[date.weekday - 1];

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Time Slot Chip Widget
class _TimeSlotChip extends StatelessWidget {
  final String timeSlot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.timeSlot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Text(
            timeSlot,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

// Confirmation Step Widget
class _ConfirmationStep extends ConsumerWidget {
  final LaundryBookingFormState formState;
  final LaundryBookingFormNotifier formNotifier;
  final VoidCallback onPrevious;

  const _ConfirmationStep({
    required this.formState,
    required this.formNotifier,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Booking',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your booking details before confirming',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services Summary
                  _buildServicesSummary(context),

                  const SizedBox(height: 16),

                  // Pickup Details
                  _buildPickupDetails(context, ref),

                  const SizedBox(height: 16),

                  // Payment Information
                  _buildPaymentInfo(context),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmBooking(context, ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...formState.selectedServices.map((service) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getServiceColor(service.serviceType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getServiceIcon(service.serviceType),
                      color: _getServiceColor(service.serviceType),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service.turnaroundHours}h turnaround time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPickupDetails(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                formState.pickupDate != null
                    ? '${formState.pickupDate!.day}/${formState.pickupDate!.month}/${formState.pickupDate!.year}'
                    : 'Not selected',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                formState.pickupTimeSlot ?? 'Not selected',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final selectedAddress = ref.watch(defaultAddressProvider);
                    if (selectedAddress != null) {
                      return Text(
                        '${selectedAddress.addressType ?? 'Address'} - ${selectedAddress.addressLine1}${selectedAddress.addressLine2.isNotEmpty ? ', ${selectedAddress.addressLine2}' : ''}',
                        style: const TextStyle(fontSize: 14),
                      );
                    } else {
                      return const Text(
                        'No address selected',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Our team will visit your location at the scheduled time',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Items will be inspected and final pricing will be calculated',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Payment will be collected during pickup',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• No advance payment required',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }



  void _confirmBooking(BuildContext context, WidgetRef ref) async {
    try {
      // Validate form before proceeding
      if (!_validateBookingForm(context, ref)) {
        return;
      }

      // Get current user
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        _showErrorDialog(context, 'Please login to continue with booking');
        return;
      }

      // Show loading dialog
      _showLoadingDialog(context);

      // Get selected address
      final selectedAddress = ref.read(defaultAddressProvider);
      if (selectedAddress == null) {
        _showErrorDialog(context, 'Please select a pickup address');
        return;
      }

      // Create the booking
      final bookingNotifier = ref.read(laundryBookingNotifierProvider.notifier);
      await bookingNotifier.createSimplifiedBooking(
        userId: currentUser.id,
        selectedServices: formState.selectedServices,
        pickupDate: formState.pickupDate!,
        pickupTimeSlot: formState.pickupTimeSlot!,
        pickupAddressId: selectedAddress.id,
        specialInstructions: formState.specialInstructions,
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Check booking result
      final bookingState = ref.read(laundryBookingNotifierProvider);
      bookingState.when(
        data: (booking) {
          // Success - navigate to success screen
          if (context.mounted && booking != null) {
            final selectedAddress = ref.read(defaultAddressProvider);
            context.pushReplacement('/services/booking-success', extra: {
              'bookingId': booking.id,
              'services': formState.selectedServices,
              'pickupDate': formState.pickupDate!,
              'pickupTimeSlot': formState.pickupTimeSlot!,
              'address': selectedAddress,
            });
          }
        },
        loading: () {
          // Still loading - shouldn't happen here
          if (context.mounted) {
            _showErrorDialog(context, 'Booking is still processing. Please try again.');
          }
        },
        error: (error, stackTrace) {
          // Error occurred
          if (context.mounted) {
            _showErrorDialog(context, 'Failed to create booking: $error');
          }
        },
      );
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'An unexpected error occurred: $e');
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Creating your booking...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateBookingForm(BuildContext context, WidgetRef ref) {
    // Validate services selection
    if (formState.selectedServices.isEmpty) {
      _showErrorDialog(context, 'Please select at least one service');
      return false;
    }

    // Validate address selection
    final selectedAddress = ref.read(defaultAddressProvider);
    if (selectedAddress == null) {
      _showErrorDialog(context, 'Please select a pickup address');
      return false;
    }

    // Validate pickup date
    if (formState.pickupDate == null) {
      _showErrorDialog(context, 'Please select a pickup date');
      return false;
    }

    // Validate pickup date is not in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(
      formState.pickupDate!.year,
      formState.pickupDate!.month,
      formState.pickupDate!.day,
    );

    if (selectedDate.isBefore(today)) {
      _showErrorDialog(context, 'Pickup date cannot be in the past');
      return false;
    }

    // Validate pickup time slot
    if (formState.pickupTimeSlot == null || formState.pickupTimeSlot!.isEmpty) {
      _showErrorDialog(context, 'Please select a pickup time slot');
      return false;
    }

    // Validate pickup date is not too far in the future (max 30 days)
    final maxDate = today.add(const Duration(days: 30));
    if (selectedDate.isAfter(maxDate)) {
      _showErrorDialog(context, 'Pickup date cannot be more than 30 days in advance');
      return false;
    }

    return true;
  }



  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getServiceColor(LaundryServiceType type) {
    switch (type) {
      case LaundryServiceType.dryClean:
        return Colors.purple;
      case LaundryServiceType.washFold:
        return Colors.green;
      case LaundryServiceType.steamIron:
        return Colors.orange;
      case LaundryServiceType.washIron:
        return Colors.blue;
    }
  }

  IconData _getServiceIcon(LaundryServiceType type) {
    switch (type) {
      case LaundryServiceType.dryClean:
        return Icons.dry_cleaning;
      case LaundryServiceType.washFold:
        return Icons.local_laundry_service;
      case LaundryServiceType.steamIron:
        return Icons.iron;
      case LaundryServiceType.washIron:
        return Icons.iron;
    }
  }


}
