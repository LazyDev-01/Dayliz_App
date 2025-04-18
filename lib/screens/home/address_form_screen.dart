import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/models/zone.dart';
import 'package:dayliz_app/providers/address_provider.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/providers/zone_provider.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/utils/permission_helper.dart';
import 'package:dayliz_app/widgets/address/zone_info_widget.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_dropdown.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

// Northeast India states provider
final northeastStatesProvider = Provider<List<DaylizDropdownItem<String>>>((ref) {
  return [
    DaylizDropdownItem(label: 'Meghalaya', value: 'Meghalaya'),
    DaylizDropdownItem(label: 'Assam', value: 'Assam'),
    DaylizDropdownItem(label: 'Nagaland', value: 'Nagaland'),
    DaylizDropdownItem(label: 'Mizoram', value: 'Mizoram'),
    DaylizDropdownItem(label: 'Manipur', value: 'Manipur'),
    DaylizDropdownItem(label: 'Arunachal Pradesh', value: 'Arunachal Pradesh'),
    DaylizDropdownItem(label: 'Tripura', value: 'Tripura'),
    DaylizDropdownItem(label: 'Sikkim', value: 'Sikkim'),
  ];
});

// Address tag options
enum AddressTag { home, work, other }

// Zone provider based on coordinates
final zoneProvider = Provider<String Function(double latitude, double longitude)>((ref) {
  return (latitude, longitude) {
    // Simple zone determination based on latitude and longitude
    // This is a placeholder - replace with your actual zone logic
    if (latitude > 25.0) {
      return 'North Zone';
    } else if (latitude > 20.0) {
      return 'Central Zone';
    } else {
      return 'South Zone';
    }
  };
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
  final TextEditingController _deliveryInstructionsController = TextEditingController();
  
  // Fixed to "India"
  final String _country = 'India';
  String _state = '';
  AddressTag _addressTag = AddressTag.home;
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  bool _isOutsideDeliveryZone = false;
  Address? _fetchedAddress;
  
  // Location data
  double? _latitude;
  double? _longitude;
  String? _zone;
  
  // Debounce timer for location detection
  Timer? _locationDebounce;

  @override
  void initState() {
    super.initState();
    
    // Default state selection
    _state = ref.read(northeastStatesProvider).first.value;
    
    // If we have an address ID but no address object, set up for lazy loading
    if (widget.address == null && widget.addressId != null) {
      // Address will be loaded in didChangeDependencies
    } else {
      // Use the address directly if provided
      _initializeForm();
    }
    
    // Silently fetch location when the form is first loaded
    _fetchLocationSilently();
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
      _nameController.text = widget.address!.recipientName ?? '';
      _phoneController.text = widget.address!.recipientPhone ?? '';
      _streetController.text = widget.address!.addressLine1;
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode;
      _landmarkController.text = widget.address!.landmark ?? '';
      
      // Set the address tag based on addressType
      if (widget.address!.addressType != null) {
        switch (widget.address!.addressType!.toLowerCase()) {
          case 'work':
            _addressTag = AddressTag.work;
            break;
          case 'other':
            _addressTag = AddressTag.other;
            break;
          default:
            _addressTag = AddressTag.home;
        }
      }
      
      // State handling with verification against available northeast states
      final states = ref.read(northeastStatesProvider);
      final stateExists = states.any((item) => item.value == widget.address!.state);
      _state = stateExists ? widget.address!.state : states.first.value;
      _isDefault = widget.address!.isDefault;
      
      // Set location data
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      _zone = widget.address!.zone;
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
    _deliveryInstructionsController.dispose();
    _locationDebounce?.cancel();
    super.dispose();
  }

  // Get address type string from enum
  String _getAddressTypeString() {
    switch (_addressTag) {
      case AddressTag.work:
        return 'work';
      case AddressTag.other:
        return 'other';
      case AddressTag.home:
      default:
        return 'home';
    }
  }

  // Check and request location permissions
  Future<bool> _handleLocationPermission() async {
    return await PermissionHelper.checkAndRequestLocationPermission(context);
  }

  // Detect location and perform reverse geocoding silently
  Future<void> _fetchLocationSilently() async {
    // Don't do anything if we're already detecting location
    if (_isDetectingLocation) return;
    
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      if (!mounted) return;
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // Determine zone based on coordinates
        _zone = ref.read(zoneProvider)(_latitude!, _longitude!);
      });
      
      debugPrint('Location detected: $_latitude, $_longitude (Zone: $_zone)');
      
      // Only populate fields if they are empty (don't override user input)
      if (_streetController.text.isEmpty && 
          _cityController.text.isEmpty && 
          _postalCodeController.text.isEmpty) {
        await _performReverseGeocoding(position);
      }
    } catch (e) {
      // Only log the error but don't show UI feedback since this is a silent operation
      debugPrint('Error detecting location silently: $e');
    }
  }
  
  // Manually detect location with UI feedback
  Future<void> _detectLocation() async {
    // Don't proceed if we're already detecting location
    if (_isDetectingLocation) return;
    
    // Debounce the location detection to prevent multiple requests
    if (_locationDebounce?.isActive ?? false) {
      _locationDebounce!.cancel();
    }
    
    _locationDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isDetectingLocation = true;
      });
      
      try {
        final hasPermission = await _handleLocationPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        
        if (!mounted) return;
        
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          
          // Determine zone based on coordinates
          _zone = ref.read(zoneProvider)(_latitude!, _longitude!);
        });
        
        await _performReverseGeocoding(position);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location detected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error detecting location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error detecting location: ${e.toString().split('\n').first}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDetectingLocation = false;
          });
        }
      }
    });
  }
  
  // Perform reverse geocoding to get address details from coordinates
  Future<void> _performReverseGeocoding(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Only update if the field is empty (don't override user input)
        setState(() {
          if (_streetController.text.isEmpty) {
            _streetController.text = '${place.street ?? ''} ${place.subThoroughfare ?? ''}'
                .trim();
          }
          
          if (_cityController.text.isEmpty && place.locality != null) {
            _cityController.text = place.locality!;
          }
          
          if (_postalCodeController.text.isEmpty && place.postalCode != null) {
            _postalCodeController.text = place.postalCode!;
          }
          
          // Match state to our northeastern states list or use default
          if (place.administrativeArea != null) {
            final states = ref.read(northeastStatesProvider);
            final stateMatch = states.firstWhere(
              (state) => state.value.toLowerCase() == place.administrativeArea!.toLowerCase(),
              orElse: () => states.first,
            );
            _state = stateMatch.value;
          }
        });
        
        debugPrint('Location geocoded successfully: ${place.locality}, ${place.administrativeArea}');
      }
    } catch (e) {
      debugPrint('Error in reverse geocoding: $e');
    }
  }

  Future<void> _saveAddress() async {
    if (_isLoading) return;

    // Form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if location is outside delivery zone
    if (_isOutsideDeliveryZone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save address. Location is outside our delivery area.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipient name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Street address is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('City is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_postalCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postal code is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      debugPrint("Creating address for user: $userId");
      
      // Get zone ID if coordinates are available
      String? zoneId;
      if (_latitude != null && _longitude != null) {
        final zone = await ref.read(zoneForCoordinatesProvider(
          (latitude: _latitude!, longitude: _longitude!)
        ).future);
        zoneId = zone?.id;
        debugPrint("Zone detected: ${zone?.name ?? 'None'} (ID: $zoneId)");
      }
      
      // Create address object
      final address = Address.create(
        id: widget.address?.id,
        userId: userId,
        addressLine1: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _state,
        postalCode: _postalCodeController.text.trim(),
        country: _country, // Always using "India" as the country
        isDefault: _isDefault,
        recipientName: _nameController.text.trim(),
        recipientPhone: _phoneController.text.trim(),
        landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text.trim(),
        addressType: _getAddressTypeString(),
        latitude: _latitude,
        longitude: _longitude,
        zone: _zone,
        zoneId: zoneId,
      );

      debugPrint("Saving address: ${address.id}");
      
      bool success = false;
      if (widget.address == null) {
        // Add new address
        final result = await ref.read(addressNotifierProvider.notifier).addAddress(address);
        success = result != null;
      } else {
        // Update existing address
        await ref.read(addressNotifierProvider.notifier).updateAddress(address);
        success = true;
      }

      if (!mounted) return;

      if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
        // Force a refresh of the address list
      await ref.read(addressNotifierProvider.notifier).fetchAddresses();
      
        // Return to previous screen
      Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save address. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving address: $e");
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
    final colorScheme = theme.colorScheme;
    final states = ref.watch(northeastStatesProvider);
    final isEditMode = widget.address != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Address' : 'Add New Address'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // GPS Location Detection Button with improved UI
          Tooltip(
            message: 'Detect current location',
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _isDetectingLocation 
                ? Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Detect current location',
                    onPressed: _detectLocation,
                  ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Section
                _buildSectionTitle(theme, 'Contact Information'),
                const SizedBox(height: 12),
                // Name
                DaylizTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'Enter recipient\'s full name',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => Validators.required(value, fieldName: 'full name'),
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                
                // Phone
                DaylizTextField(
                  controller: _phoneController,
                  label: 'Phone Number *',
                  hint: 'Enter contact phone number',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                
                // Add more space between sections
                const SizedBox(height: 32),
                
                // Address Section
                _buildSectionTitle(theme, 'Address Details'),
                const SizedBox(height: 12),
                
                // Address Tags
                _buildAddressTagSelector(theme),
                const SizedBox(height: 12),
                
                // Street Address
                DaylizTextField(
                  controller: _streetController,
                  label: 'Street Address *',
                  hint: 'Enter street address, building, etc.',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => Validators.required(value, fieldName: 'street address'),
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                
                // Landmark
                DaylizTextField(
                  controller: _landmarkController,
                  label: 'Landmark (Optional)',
                  hint: 'Enter a nearby landmark',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                
                // City and Postal Code - Side by Side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City
                    Expanded(
                      flex: 3,
                      child: DaylizTextField(
                        controller: _cityController,
                        label: 'City *',
                        hint: 'Enter city name',
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => Validators.required(value, fieldName: 'city'),
                        prefixIcon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Postal Code
                    Expanded(
                      flex: 2,
                      child: DaylizTextField(
                        controller: _postalCodeController,
                        label: 'Postal Code *',
                        hint: 'Postal code',
                        keyboardType: TextInputType.number,
                        validator: Validators.postalCode,
                        prefixIcon: Icons.markunread_mailbox_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // State and Country - Side by Side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // State dropdown
                    Expanded(
                      flex: 3,
                      child: DaylizDropdown<String>(
                        label: 'State *',
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
                    ),
                    const SizedBox(width: 12),
                    // Country (read-only)
                    Expanded(
                      flex: 2,
                      child: DaylizTextField(
                        label: 'Country *',
                        hint: 'India',
                        prefixIcon: Icons.flag_outlined,
                        enabled: false,
                        controller: TextEditingController(text: 'India'),
                      ),
                    ),
                  ],
                ),
                
                // Show coordinates and zone if available
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GPS Location',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (_zone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Zone: $_zone',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        
                        // Show delivery zone information
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final zoneAsyncValue = ref.watch(zoneForCoordinatesProvider(
                              (latitude: _latitude!, longitude: _longitude!)
                            ));
                            
                            // Update the flag based on zone availability
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (zoneAsyncValue.hasValue) {
                                setState(() {
                                  _isOutsideDeliveryZone = zoneAsyncValue.value == null;
                                });
                              }
                            });
                            
                            return ZoneInfoWidget(
                              latitude: _latitude,
                              longitude: _longitude,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Add more space between sections
                const SizedBox(height: 32),
                
                // Delivery Options Section
                _buildSectionTitle(theme, 'Delivery Options'),
                const SizedBox(height: 12),
                
                // Delivery Instructions
                DaylizTextField(
                  controller: _deliveryInstructionsController,
                  label: 'Delivery Instructions (Optional)',
                  hint: 'Any special instructions for delivery?',
                  maxLines: 2,
                  prefixIcon: Icons.delivery_dining_outlined,
                ),
                const SizedBox(height: 16),
                
                // Default Address Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_outline,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Set as default address',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isDefault,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Add note about required fields
                const SizedBox(height: 16),
                Text(
                  '* Required fields',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.error,
                  ),
                ),
                
                // Space before the save button
                const SizedBox(height: 36),
                
                // Save button
                _buildSaveButton(colorScheme, isEditMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section title widget
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  // Address tag selector
  Widget _buildAddressTagSelector(ThemeData theme) {
    return Wrap(
      spacing: 12,
      children: [
        _buildAddressTagChip(
          theme, 
          AddressTag.home, 
          'Home', 
          Icons.home_rounded
        ),
        _buildAddressTagChip(
          theme, 
          AddressTag.work, 
          'Work', 
          Icons.work_rounded
        ),
        _buildAddressTagChip(
          theme, 
          AddressTag.other, 
          'Other', 
          Icons.place_rounded
        ),
      ],
    );
  }

  // Individual address tag chip
  Widget _buildAddressTagChip(ThemeData theme, AddressTag tag, String label, IconData icon) {
    final isSelected = _addressTag == tag;
    final colorScheme = theme.colorScheme;
    
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.7),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _addressTag = tag;
        });
      },
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  // Save button widget
  Widget _buildSaveButton(ColorScheme colorScheme, bool isEditMode) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditMode ? 'Update Address' : 'Save Address',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
} 