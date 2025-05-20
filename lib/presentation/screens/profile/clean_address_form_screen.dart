import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Temporarily comment out geolocator import
// import 'package:geolocator/geolocator.dart';

import '../../../domain/entities/address.dart';
import '../../providers/user_providers.dart';

class CleanAddressFormScreen extends ConsumerStatefulWidget {
  final Address? address;
  final String? addressId;

  const CleanAddressFormScreen({Key? key, this.address, this.addressId}) : super(key: key);

  @override
  ConsumerState<CleanAddressFormScreen> createState() => _CleanAddressFormScreenState();
}

class _CleanAddressFormScreenState extends ConsumerState<CleanAddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Label controller removed
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
  String? _addressType;
  String? _addressTypeError;
  late bool _isDefault;

  // Location data (temporarily disabled)
  double? _latitude;
  double? _longitude;
  String? _zoneId;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.address != null || widget.addressId != null;

    // If we have an addressId but no address, we'll need to fetch it
    if (widget.addressId != null && widget.address == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAddress(widget.addressId!);
      });
    }

    // Label controller removed
    _addressLine1Controller = TextEditingController(text: widget.address?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: widget.address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? 'Tura');
    _stateController = TextEditingController(text: widget.address?.state ?? 'Meghalaya');
    _postalCodeController = TextEditingController(text: widget.address?.postalCode ?? '794101');
    _countryController = TextEditingController(text: widget.address?.country ?? 'India');
    _phoneNumberController = TextEditingController(text: widget.address?.phoneNumber ?? '');
    _landmarkController = TextEditingController(text: widget.address?.landmark ?? '');
    _additionalInfoController = TextEditingController(text: widget.address?.additionalInfo ?? '');
    _recipientNameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _addressType = widget.address?.addressType;
    _isDefault = widget.address?.isDefault ?? false;

    // If editing, store the initial location data
    if (_isEditing) {
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      _zoneId = widget.address!.zoneId;
    }
  }

  @override
  void dispose() {
    // Label controller removed
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
    super.dispose();
  }

  // Fetch address by ID
  Future<void> _fetchAddress(String addressId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userId = currentUser.id;
      final address = await ref.read(addressesNotifierProvider.notifier).getAddressById(userId, addressId);

      if (address != null) {
        setState(() {
          // Label field removed
          _addressLine1Controller.text = address.addressLine1;
          _addressLine2Controller.text = address.addressLine2;
          _cityController.text = address.city;
          _stateController.text = address.state;
          _postalCodeController.text = address.postalCode;
          _countryController.text = address.country;
          _phoneNumberController.text = address.phoneNumber ?? '';
          _landmarkController.text = address.landmark ?? '';
          _additionalInfoController.text = address.additionalInfo ?? '';
          _recipientNameController.text = address.recipientName ?? '';
          _addressType = address.addressType;
          _isDefault = address.isDefault;
          _latitude = address.latitude;
          _longitude = address.longitude;
          _zoneId = address.zoneId;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address not found'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading address: ${e.toString()}'),
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

  // Location functionality temporarily disabled

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
      debugPrint('Using authenticated user ID: $userId');

      final address = Address(
        id: _isEditing ? widget.address!.id : const Uuid().v4(),
        userId: userId,
        // Label field removed
        addressType: _addressType,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty ? '' : _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
        phoneNumber: _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
        isDefault: _isDefault,
        additionalInfo: null, // Field removed from UI
        landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text,
        latitude: _latitude,
        longitude: _longitude,
        zoneId: _zoneId,
        recipientName: _recipientNameController.text.isEmpty ? null : _recipientNameController.text,
      );

      try {
        debugPrint('Saving address with data:');
        debugPrint('ID: ${address.id}');
        debugPrint('User ID: $userId');
        debugPrint('Address Line 1: ${address.addressLine1}');
        debugPrint('City: ${address.city}');
        debugPrint('State: ${address.state}');
        debugPrint('Postal Code: ${address.postalCode}');
        debugPrint('Country: ${address.country}');
        debugPrint('Is Default: ${address.isDefault}');
        debugPrint('Landmark: ${address.landmark}');

        if (_isEditing) {
          debugPrint('Updating existing address...');
          await ref.read(addressesNotifierProvider.notifier).updateAddress(userId, address);
          debugPrint('Address updated successfully');
        } else {
          debugPrint('Adding new address...');
          await ref.read(addressesNotifierProvider.notifier).addAddress(userId, address);
          debugPrint('Address added successfully');
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
        debugPrint('Error saving address: $e');
        if (e is PostgrestException) {
          debugPrint('PostgrestException details:');
          debugPrint('Message: ${e.message}');
          debugPrint('Details: ${e.details}');
          debugPrint('Hint: ${e.hint}');
          debugPrint('Code: ${e.code}');
        }

        if (mounted) {
          String errorMessage = 'Error saving address';

          if (e is PostgrestException) {
            // Handle Supabase-specific errors
            if (e.code == '42501') {
              errorMessage = 'Permission denied. You may need to log in again.';
            } else {
              errorMessage = 'Database error: ${e.message}';
            }
          } else {
            errorMessage = 'Error: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
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
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _addressType = type;
          _addressTypeError = null; // Clear error when a type is selected
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withAlpha(26) : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Address' : 'Add New Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. Recipient Name
            TextFormField(
              controller: _recipientNameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                hintText: 'Name of person receiving delivery',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Recipient Phone
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Recipient Phone',
                hintText: 'Phone number for delivery contact',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // 3. Address Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildAddressTypeButton(
                        type: 'home',
                        label: 'Home',
                        icon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAddressTypeButton(
                        type: 'work',
                        label: 'Work',
                        icon: Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ],
            ),
            const SizedBox(height: 16),

            // 4. House No/Building/Floor
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'House No/Building/Floor',
                hintText: 'Enter flat number, building name, floor, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Area/Street
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Area/Street',
                hintText: 'Enter area and street name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter area and street name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 6. Landmark (Optional)
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark (Optional)',
                hintText: 'E.g., Near Tura Bazaar',
                border: OutlineInputBorder(),
              ),
            ),

            // Hidden fields for City, State, Postal Code, and Country
            // These fields are not displayed to the user but still stored in the database
            // Values are populated from GPS/location data
            Visibility(
              visible: false,
              maintainState: true,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State/Province',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            // Additional Information field removed
            const SizedBox(height: 16),
            // Temporarily disabled location functionality
            ElevatedButton.icon(
              onPressed: null, // Disabled
              icon: const Icon(Icons.my_location),
              label: const Text('Location functionality temporarily disabled'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set as Default Address'),
              subtitle: const Text('Use this address as your default delivery address'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Address' : 'Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}