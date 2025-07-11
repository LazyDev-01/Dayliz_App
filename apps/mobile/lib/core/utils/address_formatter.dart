import '../../../domain/entities/address.dart';

/// Utility class for standardizing address formatting across the app
///
/// Implements the format: Street/area/locality, Floor(if entered), House no/flat/building, City, State, Pincode, Country
class AddressFormatter {
  /// Formats an address according to the standardized format
  ///
  /// Format: Street/area/locality, Floor(if entered), House no/flat/building, City, State, Pincode, Country
  ///
  /// Example with floor: "Hawakhana, 2nd Floor, H-24, Tura, Meghalaya, 794001, India"
  /// Example without floor: "Hawakhana, H-24, Tura, Meghalaya, 794001, India"
  static String formatAddress(Address address, {bool includeCountry = true}) {
    final parts = <String>[];

    // Street/area/locality (addressLine2)
    if (address.addressLine2.isNotEmpty) {
      parts.add(address.addressLine2.trim());
    }

    // Floor (if entered)
    if (address.floor != null && address.floor!.isNotEmpty) {
      parts.add(address.floor!.trim());
    }

    // House no/flat/building (addressLine1)
    if (address.addressLine1.isNotEmpty) {
      parts.add(address.addressLine1.trim());
    }

    // City
    if (address.city.isNotEmpty) {
      parts.add(address.city.trim());
    }

    // State
    if (address.state.isNotEmpty) {
      parts.add(address.state.trim());
    }

    // Pincode
    if (address.postalCode.isNotEmpty) {
      parts.add(address.postalCode.trim());
    }

    // Country (optional)
    if (includeCountry && address.country.isNotEmpty) {
      parts.add(address.country.trim());
    }

    return parts.join(', ');
  }
  
  /// Formats address for compact display (without country, shorter format)
  ///
  /// Format: Street/area, Floor(if entered), House no, City, State Pincode
  ///
  /// Example with floor: "Hawakhana, 2nd Floor, H-24, Tura, Meghalaya 794001"
  /// Example without floor: "Hawakhana, H-24, Tura, Meghalaya 794001"
  static String formatAddressCompact(Address address) {
    final parts = <String>[];

    // Street/area/locality (addressLine2)
    if (address.addressLine2.isNotEmpty) {
      parts.add(address.addressLine2.trim());
    }

    // Floor (if entered)
    if (address.floor != null && address.floor!.isNotEmpty) {
      parts.add(address.floor!.trim());
    }

    // House no/flat/building
    if (address.addressLine1.isNotEmpty) {
      parts.add(address.addressLine1.trim());
    }

    // City
    if (address.city.isNotEmpty) {
      parts.add(address.city.trim());
    }

    // State and Pincode combined
    final statePostal = <String>[];
    if (address.state.isNotEmpty) {
      statePostal.add(address.state.trim());
    }
    if (address.postalCode.isNotEmpty) {
      statePostal.add(address.postalCode.trim());
    }

    if (statePostal.isNotEmpty) {
      parts.add(statePostal.join(' '));
    }

    return parts.join(', ');
  }
  
  /// Formats address for single line display with ellipsis support
  ///
  /// Format: Street/area, Floor(if entered), House no, City, State
  ///
  /// Example with floor: "Hawakhana, 2nd Floor, H-24, Tura, Meghalaya"
  /// Example without floor: "Hawakhana, H-24, Tura, Meghalaya"
  static String formatAddressSingleLine(Address address) {
    final parts = <String>[];

    // Street/area/locality (addressLine2)
    if (address.addressLine2.isNotEmpty) {
      parts.add(address.addressLine2.trim());
    }

    // Floor (if entered)
    if (address.floor != null && address.floor!.isNotEmpty) {
      parts.add(address.floor!.trim());
    }

    // House no/flat/building
    if (address.addressLine1.isNotEmpty) {
      parts.add(address.addressLine1.trim());
    }

    // City
    if (address.city.isNotEmpty) {
      parts.add(address.city.trim());
    }

    // State
    if (address.state.isNotEmpty) {
      parts.add(address.state.trim());
    }

    return parts.join(', ');
  }
  
  /// Formats address for multi-line display
  ///
  /// Returns a list of strings for each line
  static List<String> formatAddressMultiLine(Address address, {bool includeCountry = true}) {
    final lines = <String>[];

    // Line 1: Street/area/locality, Floor(if entered), House no/flat/building
    final line1Parts = <String>[];
    if (address.addressLine2.isNotEmpty) {
      line1Parts.add(address.addressLine2.trim());
    }
    if (address.floor != null && address.floor!.isNotEmpty) {
      line1Parts.add(address.floor!.trim());
    }
    if (address.addressLine1.isNotEmpty) {
      line1Parts.add(address.addressLine1.trim());
    }
    if (line1Parts.isNotEmpty) {
      lines.add(line1Parts.join(', '));
    }

    // Line 2: City, State, Pincode
    final line2Parts = <String>[];
    if (address.city.isNotEmpty) {
      line2Parts.add(address.city.trim());
    }
    if (address.state.isNotEmpty) {
      line2Parts.add(address.state.trim());
    }
    if (address.postalCode.isNotEmpty) {
      line2Parts.add(address.postalCode.trim());
    }
    if (line2Parts.isNotEmpty) {
      lines.add(line2Parts.join(', '));
    }

    // Line 3: Country (optional)
    if (includeCountry && address.country.isNotEmpty) {
      lines.add(address.country.trim());
    }

    return lines;
  }
  
  /// Formats address with landmark if available
  /// 
  /// Format: Standard format + landmark information
  static String formatAddressWithLandmark(Address address, {bool includeCountry = true}) {
    final standardFormat = formatAddress(address, includeCountry: includeCountry);
    
    if (address.landmark != null && address.landmark!.isNotEmpty) {
      return '$standardFormat\nLandmark: ${address.landmark!.trim()}';
    }
    
    return standardFormat;
  }
}
