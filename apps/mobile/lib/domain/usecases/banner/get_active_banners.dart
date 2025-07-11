import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/banner.dart';
import '../../repositories/banner_repository.dart';

/// Use case for getting active banners
class GetActiveBanners implements UseCase<List<Banner>, NoParams> {
  final BannerRepository repository;

  GetActiveBanners(this.repository);

  @override
  Future<Either<Failure, List<Banner>>> call(NoParams params) async {
    return await repository.getActiveBanners();
  }
}
