import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/providers/address_provider.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_dropdown.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';

// Simple provider for countries
final countriesProvider = Provider<List<DaylizDropdownItem<String>>>((ref) {
  return [
    DaylizDropdownItem(label: 'India', value: 'India'),
    DaylizDropdownItem(label: 'United States', value: 'United States'),
    DaylizDropdownItem(label: 'United Kingdom', value: 'United Kingdom'),
    DaylizDropdownItem(label: 'Canada', value: 'Canada'),
    DaylizDropdownItem(label: 'Australia', value: 'Australia'),
  ];
});

// Simple provider for states in India
final indianStatesProvider = Provider<List<DaylizDropdownItem<String>>>((ref) {
  return [
    DaylizDropdownItem(label: 'Andhra Pradesh', value: 'Andhra Pradesh'),
    DaylizDropdownItem(label: 'Delhi', value: 'Delhi'),
    DaylizDropdownItem(label: 'Gujarat', value: 'Gujarat'),
    DaylizDropdownItem(label: 'Karnataka', value: 'Karnataka'),
    DaylizDropdownItem(label: 'Kerala', value: 'Kerala'),
    DaylizDropdownItem(label: 'Maharashtra', value: 'Maharashtra'),
    DaylizDropdownItem(label: 'Tamil Nadu', value: 'Tamil Nadu'),
    DaylizDropdownItem(label: 'Telangana', value: 'Telangana'),
    DaylizDropdownItem(label: 'Uttar Pradesh', value: 'Uttar Pradesh'),
    DaylizDropdownItem(label: 'West Bengal', value: 'West Bengal'),
  ];
});

class AddressFormScreen extends ConsumerStatefulWidget {
  final Address? address;
  final String? addressId;

  const AddressFormScreen({
    Key? key,
    this.address,
    this.addressId,
  }) : super(key: key);

  @override
  AddressFormScreenState createState() => AddressFormScreenState();
}

class AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  
  String _country = 'India';
  String _state = '';
  bool _isDefault = false;
  bool _isLoading = false;
  Address? _fetchedAddress;

  @override
  void initState() {
    super.initState();
    
    // If we have an address ID but no address object, set up for lazy loading
    if (widget.address == null && widget.addressId != null) {
      // Address will be loaded in didChangeDependencies
      _state = ref.read(indianStatesProvider).first.value;
    } else {
      // Use the address directly if provided
      _initializeForm();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // If we have an addressId but no address, try to fetch it
    if (widget.address == null && widget.addressId != null && _fetchedAddress == null) {
      // Attempt to get the address
      final address = ref.read(addressByIdProvider(widget.addressId!));
      if (address != null) {
        setState(() {
          _fetchedAddress = address;
          _initializeForm();
        });
      }
    }
  }

  void _initializeForm() {
    if (widget.address != null) {
      // Pre-fill the form with existing address data
      _nameController.text = widget.address!.name;
      _phoneController.text = widget.address!.phone ?? '';
      _streetController.text = widget.address!.street ?? '';
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode;
      _landmarkController.text = widget.address!.landmark ?? '';
      _country = widget.address!.country;
      _state = widget.address!.state;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = ref.read(currentUserProvider)?.id ?? 'current-user-id';
      print("Creating address for user: $userId");
      
      // Create address object - include only fields that exist in the database
      final address = Address.create(
        id: widget.address?.id,
        userId: userId,
        name: _nameController.text.trim(),
        addressLine1: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _state,
        postalCode: _postalCodeController.text.trim(),
        country: _country,
        phoneNumber: _phoneController.text.trim(),
        isDefault: _isDefault,
        street: _streetController.text.trim(),
        phone: _phoneController.text.trim(),
        landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text.trim(),
      );

      print("Saving address: ${address.toJson()}");
      
      // Wait for the operation to complete
      if (widget.address == null) {
        // Add new address
        await ref.read(addressNotifierProvider.notifier).addAddress(address);
      } else {
        // Update existing address
        await ref.read(addressNotifierProvider.notifier).updateAddress(address);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Force a refresh of the address list immediately
      await ref.read(addressNotifierProvider.notifier).fetchAddresses();
      
      // Return success result to the previous screen
      Navigator.of(context).pop(true);
    } catch (e) {
      print("Error saving address: $e");
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving address: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countries = ref.watch(countriesProvider);
    final states = ref.watch(indianStatesProvider);
    
    final isEditMode = widget.address != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Address' : 'Add New Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                DaylizTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter recipient\'s full name',
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.name,
                  prefixIcon: Icons.person_outline,
                ),
                AppSpacing.vMD,
                
                // Phone
                DaylizTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter contact phone number',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                AppSpacing.vMD,
                
                // Street
                DaylizTextField(
                  controller: _streetController,
                  label: 'Street Address',
                  hint: 'Enter street address, building, etc.',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => Validators.required(value, fieldName: 'street address'),
                  prefixIcon: Icons.home_outlined,
                ),
                AppSpacing.vMD,
                
                // City
                DaylizTextField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter city name',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => Validators.required(value, fieldName: 'city'),
                  prefixIcon: Icons.location_city_outlined,
                ),
                AppSpacing.vMD,
                
                // Country dropdown
                DaylizDropdown<String>(
                  label: 'Country',
                  hint: 'Select country',
                  value: _country,
                  items: countries,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _country = value;
                      });
                    }
                  },
                  prefixIcon: Icons.flag_outlined,
                ),
                AppSpacing.vMD,
                
                // State dropdown
                DaylizDropdown<String>(
                  label: 'State',
                  hint: 'Select state',
                  value: states.any((item) => item.value == _state) ? _state : states.first.value,
                  items: states,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _state = value;
                      });
                    }
                  },
                  prefixIcon: Icons.map_outlined,
                ),
                AppSpacing.vMD,
                
                // Postal Code Field
                DaylizTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  hint: 'Enter postal code',
                  keyboardType: TextInputType.number,
                  validator: Validators.postalCode,
                  prefixIcon: Icons.markunread_mailbox_outlined,
                ),
                AppSpacing.vMD,
                
                // Landmark Field
                DaylizTextField(
                  controller: _landmarkController,
                  label: 'Landmark (Optional)',
                  hint: 'Enter a nearby landmark',
                  maxLines: 3,
                ),
                AppSpacing.vMD,
                
                // Default Address Checkbox
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _isDefault = value;
                      });
                    }
                  },
                  title: Text(
                    'Set as default address',
                    style: theme.textTheme.bodyLarge,
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: theme.colorScheme.primary,
                ),
                AppSpacing.vLG,
                
                // Save button
                DaylizButton(
                  label: isEditMode ? 'Update Address' : 'Save Address',
                  onPressed: _isLoading ? null : _saveAddress,
                  isLoading: _isLoading,
                  type: DaylizButtonType.primary,
                  size: DaylizButtonSize.large,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 