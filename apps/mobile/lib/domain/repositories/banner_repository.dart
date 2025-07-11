import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/banner.dart';

/// Abstract repository interface for banner operations
abstract class BannerRepository {
  /// Get all active banners
  Future<Either<Failure, List<Banner>>> getActiveBanners();
  
  /// Get all banners (including inactive)
  Future<Either<Failure, List<Banner>>> getAllBanners();
  
  /// Get a specific banner by ID
  Future<Either<Failure, Banner>> getBannerById(String id);
  
  /// Create a new banner
  Future<Either<Failure, Banner>> createBanner(Banner banner);
  
  /// Update an existing banner
  Future<Either<Failure, Banner>> updateBanner(Banner banner);
  
  /// Delete a banner
  Future<Either<Failure, void>> deleteBanner(String id);
}
