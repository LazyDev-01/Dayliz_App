import '../domain/entities/address.dart' as domain;
import '../models/address.dart' as legacy;

/// Adapter to convert between legacy Address and clean architecture Address
class AddressAdapter {
  /// Convert from legacy Address to domain Address
  static domain.Address toDomain(legacy.Address legacyAddress) {
    return domain.Address(
      id: legacyAddress.id,
      userId: legacyAddress.userId,
      addressLine1: legacyAddress.addressLine1,
      addressLine2: legacyAddress.addressLine2 ?? '',
      city: legacyAddress.city,
      state: legacyAddress.state,
      postalCode: legacyAddress.postalCode,
      country: legacyAddress.country,
      isDefault: legacyAddress.isDefault,
      // Label field removed
      addressType: legacyAddress.addressType,
      landmark: legacyAddress.landmark,
      phoneNumber: legacyAddress.recipientPhone,
      recipientName: legacyAddress.recipientName,
      latitude: legacyAddress.latitude,
      longitude: legacyAddress.longitude,
      zoneId: legacyAddress.zoneId,
    );
  }

  /// Convert from domain Address to legacy Address
  static legacy.Address toLegacy(domain.Address domainAddress) {
    return legacy.Address(
      id: domainAddress.id,
      userId: domainAddress.userId,
      addressLine1: domainAddress.addressLine1,
      addressLine2: domainAddress.addressLine2,
      city: domainAddress.city,
      state: domainAddress.state,
      postalCode: domainAddress.postalCode,
      country: domainAddress.country,
      isDefault: domainAddress.isDefault,
      addressType: domainAddress.addressType,
      recipientName: domainAddress.recipientName,
      recipientPhone: domainAddress.phoneNumber,
      landmark: domainAddress.landmark,
      latitude: domainAddress.latitude,
      longitude: domainAddress.longitude,
      zoneId: domainAddress.zoneId,
    );
  }

  /// Convert a list of legacy addresses to domain addresses
  static List<domain.Address> toDomainList(List<legacy.Address> legacyAddresses) {
    return legacyAddresses.map((address) => toDomain(address)).toList();
  }

  /// Convert a list of domain addresses to legacy addresses
  static List<legacy.Address> toLegacyList(List<domain.Address> domainAddresses) {
    return domainAddresses.map((address) => toLegacy(address)).toList();
  }
}
