import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';
import '../../core/error/exceptions.dart';

/// Abstract interface for banner remote data source
abstract class BannerRemoteDataSource {
  /// Fetch all active banners from remote source
  Future<List<BannerModel>> getActiveBanners();
  
  /// Fetch all banners (including inactive) from remote source
  Future<List<BannerModel>> getAllBanners();
  
  /// Fetch a specific banner by ID
  Future<BannerModel> getBannerById(String id);
  
  /// Create a new banner
  Future<BannerModel> createBanner(BannerModel banner);
  
  /// Update an existing banner
  Future<BannerModel> updateBanner(BannerModel banner);
  
  /// Delete a banner
  Future<void> deleteBanner(String id);
}

/// Implementation of BannerRemoteDataSource using Supabase
class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final SupabaseClient supabaseClient;
  static const String tableName = 'banners';

  BannerRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await supabaseClient
          .from(tableName)
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return response
          .map<BannerModel>((json) => BannerModel.fromJson(json))
          .where((banner) => banner.isValid) // Additional validation
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        'Failed to fetch active banners: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while fetching active banners: $e',
      );
    }
  }

  @override
  Future<List<BannerModel>> getAllBanners() async {
    try {
      final response = await supabaseClient
          .from(tableName)
          .select()
          .order('display_order', ascending: true);

      return response
          .map<BannerModel>((json) => BannerModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        'Failed to fetch all banners: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while fetching all banners: $e',
      );
    }
  }

  @override
  Future<BannerModel> getBannerById(String id) async {
    try {
      final response = await supabaseClient
          .from(tableName)
          .select()
          .eq('id', id)
          .single();

      return BannerModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Banner with ID $id not found');
      }
      throw ServerException(
        'Failed to fetch banner: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while fetching banner: $e',
      );
    }
  }

  @override
  Future<BannerModel> createBanner(BannerModel banner) async {
    try {
      final bannerData = banner.toJson();
      bannerData.remove('id'); // Let Supabase generate the ID
      bannerData.remove('created_at'); // Let Supabase set the timestamp
      bannerData.remove('updated_at'); // Let Supabase set the timestamp

      final response = await supabaseClient
          .from(tableName)
          .insert(bannerData)
          .select()
          .single();

      return BannerModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        'Failed to create banner: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while creating banner: $e',
      );
    }
  }

  @override
  Future<BannerModel> updateBanner(BannerModel banner) async {
    try {
      final bannerData = banner.toJson();
      bannerData.remove('id'); // Don't update the ID
      bannerData.remove('created_at'); // Don't update creation timestamp
      bannerData.remove('updated_at'); // Let Supabase handle this

      final response = await supabaseClient
          .from(tableName)
          .update(bannerData)
          .eq('id', banner.id)
          .select()
          .single();

      return BannerModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Banner with ID ${banner.id} not found');
      }
      throw ServerException(
        'Failed to update banner: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while updating banner: $e',
      );
    }
  }

  @override
  Future<void> deleteBanner(String id) async {
    try {
      await supabaseClient
          .from(tableName)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(
        'Failed to delete banner: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while deleting banner: $e',
      );
    }
  }
}
