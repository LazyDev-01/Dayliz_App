import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/banner.dart';
import '../../repositories/banner_repository.dart';

/// Use case for getting a banner by ID
class GetBannerById implements UseCase<Banner, GetBannerByIdParams> {
  final BannerRepository repository;

  GetBannerById(this.repository);

  @override
  Future<Either<Failure, Banner>> call(GetBannerByIdParams params) async {
    return await repository.getBannerById(params.id);
  }
}

/// Parameters for GetBannerById use case
class GetBannerByIdParams extends Equatable {
  final String id;

  const GetBannerByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}
