import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../domain/entities/address.dart';
import '../../providers/user_providers.dart';

class AddressFormBottomSheet extends ConsumerStatefulWidget {
  final Address? address;
  final String? addressId;
  final LocationData? locationData;

  const AddressFormBottomSheet({Key? key, this.address, this.addressId, this.locationData}) : super(key: key);

  @override
  ConsumerState<AddressFormBottomSheet> createState() => _AddressFormBottomSheetState();

  static Future<void> show(BuildContext context, {Address? address, String? addressId, LocationData? locationData}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormBottomSheet(address: address, addressId: addressId, locationData: locationData),
    );
  }
}

class _AddressFormBottomSheetState extends ConsumerState<AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _landmarkController;
  late TextEditingController _additionalInfoController;
  late TextEditingController _recipientNameController;
  late TextEditingController _floorController;
  String? _addressType;
  String? _addressTypeError;

  // Location data (temporarily disabled)
  double? _latitude;
  double? _longitude;
  String? _zoneId;

  bool _isEditing = false;
  bool _isLoading = false;

  // Reusable input decoration for performance
  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.address != null || widget.addressId != null;

    // Initialize controllers - GPS data takes priority for Area/Locality field
    _addressLine1Controller = TextEditingController(text:
      widget.locationData?.locality ?? widget.address?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: widget.address?.addressLine2 ?? '');

    // GPS location data takes priority, then existing address, then empty
    _cityController = TextEditingController(text:
      widget.locationData?.city ?? widget.address?.city ?? '');
    _stateController = TextEditingController(text:
      widget.locationData?.state ?? widget.address?.state ?? '');
    _postalCodeController = TextEditingController(text:
      widget.locationData?.postalCode ?? widget.address?.postalCode ?? '');
    _countryController = TextEditingController(text:
      widget.locationData?.country ?? widget.address?.country ?? 'India');
    _phoneNumberController = TextEditingController(text: widget.address?.phoneNumber ?? '');
    _landmarkController = TextEditingController(text: widget.address?.landmark ?? '');
    _additionalInfoController = TextEditingController(text: widget.address?.additionalInfo ?? '');
    _recipientNameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _floorController = TextEditingController(text: ''); // Initialize with empty string
    _addressType = widget.address?.addressType;

    // Store location data - GPS data takes priority over existing address data
    if (widget.locationData != null) {
      _latitude = widget.locationData!.latitude;
      _longitude = widget.locationData!.longitude;
      _zoneId = null; // Zone will be determined later based on coordinates
    } else if (_isEditing && widget.address != null) {
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      _zoneId = widget.address!.zoneId;
    }
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneNumberController.dispose();
    _landmarkController.dispose();
    _additionalInfoController.dispose();
    _recipientNameController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_isLoading) return;

    // Validate address type selection
    if (_addressType == null || _addressType!.isEmpty) {
      setState(() {
        _addressTypeError = 'Please select an address type';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Get the current authenticated user ID from Supabase directly
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to save an address'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userId = currentUser.id;

      final address = Address(
        id: _isEditing ? widget.address!.id : const Uuid().v4(),
        userId: userId,
        addressType: _addressType,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty ? '' : _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
        phoneNumber: _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
        isDefault: false, // Always false since we removed default functionality
        additionalInfo: null, // Field removed from UI
        landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text,
        latitude: _latitude,
        longitude: _longitude,
        zoneId: _zoneId,
        recipientName: _recipientNameController.text.isEmpty ? null : _recipientNameController.text,
      );

      try {
        if (_isEditing) {
          await ref.read(addressesNotifierProvider.notifier).updateAddress(userId, address);
        } else {
          await ref.read(addressesNotifierProvider.notifier).addAddress(userId, address);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Address updated successfully' : 'Address added successfully'),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving address: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Build a selectable address type button
  Widget _buildAddressTypeButton({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _addressType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _addressType = type;
          _addressTypeError = null; // Clear error when a type is selected
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B7C32).withAlpha(26) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF6B7C32) : const Color(0xFF9CAF50),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6B7C32) : const Color(0xFF9CAF50),
              size: 16,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6B7C32) : const Color(0xFF9CAF50),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // X button outside the form at the top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Form container with white background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white, // White background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Enter complete address',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Divider line
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),

                  // Form content
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                  // Address Type Section
                  const Text(
                    'Save address as*',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressTypeButton(
                          type: 'home',
                          label: 'Home',
                          icon: Icons.home_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildAddressTypeButton(
                          type: 'work',
                          label: 'Work',
                          icon: Icons.work_outline,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildAddressTypeButton(
                          type: 'hotel',
                          label: 'Hotel',
                          icon: Icons.hotel_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildAddressTypeButton(
                          type: 'other',
                          label: 'Other',
                          icon: Icons.place_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (_addressTypeError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _addressTypeError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Recipient Name
                  TextFormField(
                    controller: _recipientNameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: _buildInputDecoration('Receiver\'s name *'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter receiver\'s name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Recipient Phone
                  TextFormField(
                    controller: _phoneNumberController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Receiver\'s contact *',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter receiver\'s contact';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Delivery Address Section Title
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // House No/Building
                  TextFormField(
                    controller: _addressLine2Controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Flat / House no. / Building *',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Floor (optional)
                  TextFormField(
                    controller: _floorController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Floor (optional)',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Area/Street
                  TextFormField(
                    controller: _addressLine1Controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Area / Sector / Locality *',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter area and locality';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Nearby landmark
                  TextFormField(
                    controller: _landmarkController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Nearby landmark (optional)',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hidden fields for City, State, Postal Code, and Country
                  Visibility(
                    visible: false,
                    maintainState: true,
                    child: Column(
                      children: [
                        TextFormField(controller: _cityController),
                        TextFormField(controller: _stateController),
                        TextFormField(controller: _postalCodeController),
                        TextFormField(controller: _countryController),
                      ],
                    ),
                  ),

                  // Save button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 32),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
