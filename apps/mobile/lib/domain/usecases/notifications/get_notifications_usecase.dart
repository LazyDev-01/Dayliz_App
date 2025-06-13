import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/notification.dart';
import '../../repositories/notification_repository.dart';

/// Use case for getting notifications
class GetNotificationsUseCase implements UseCase<List<NotificationEntity>, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(GetNotificationsParams params) async {
    return await repository.getNotifications(
      page: params.page,
      limit: params.limit,
      type: params.type,
      isRead: params.isRead,
    );
  }
}

/// Parameters for getting notifications
class GetNotificationsParams extends Equatable {
  final int page;
  final int limit;
  final String? type;
  final bool? isRead;

  const GetNotificationsParams({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.isRead,
  });

  @override
  List<Object?> get props => [page, limit, type, isRead];
}

/// Use case for marking notification as read
class MarkNotificationAsReadUseCase implements UseCase<NotificationEntity, MarkNotificationAsReadParams> {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationEntity>> call(MarkNotificationAsReadParams params) async {
    return await repository.markAsRead(params.notificationId);
  }
}

/// Parameters for marking notification as read
class MarkNotificationAsReadParams extends Equatable {
  final String notificationId;

  const MarkNotificationAsReadParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Use case for getting unread notification count
class GetUnreadNotificationCountUseCase implements UseCase<int, NoParams> {
  final NotificationRepository repository;

  GetUnreadNotificationCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getUnreadCount();
  }
}

/// Use case for marking all notifications as read
class MarkAllNotificationsAsReadUseCase implements UseCase<bool, NoParams> {
  final NotificationRepository repository;

  MarkAllNotificationsAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.markAllAsRead();
  }
}

/// Use case for deleting notification
class DeleteNotificationUseCase implements UseCase<bool, DeleteNotificationParams> {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteNotificationParams params) async {
    return await repository.deleteNotification(params.notificationId);
  }
}

/// Parameters for deleting notification
class DeleteNotificationParams extends Equatable {
  final String notificationId;

  const DeleteNotificationParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Use case for clearing all notifications
class ClearAllNotificationsUseCase implements UseCase<bool, NoParams> {
  final NotificationRepository repository;

  ClearAllNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.clearAllNotifications();
  }
}

/// Use case for getting notification preferences
class GetNotificationPreferencesUseCase implements UseCase<NotificationPreferences, NoParams> {
  final NotificationRepository repository;

  GetNotificationPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationPreferences>> call(NoParams params) async {
    return await repository.getNotificationPreferences();
  }
}

/// Use case for updating notification preferences
class UpdateNotificationPreferencesUseCase implements UseCase<NotificationPreferences, UpdateNotificationPreferencesParams> {
  final NotificationRepository repository;

  UpdateNotificationPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationPreferences>> call(UpdateNotificationPreferencesParams params) async {
    return await repository.updateNotificationPreferences(params.preferences);
  }
}

/// Parameters for updating notification preferences
class UpdateNotificationPreferencesParams extends Equatable {
  final NotificationPreferences preferences;

  const UpdateNotificationPreferencesParams({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

/// Use case for registering FCM token
class RegisterFCMTokenUseCase implements UseCase<bool, RegisterFCMTokenParams> {
  final NotificationRepository repository;

  RegisterFCMTokenUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(RegisterFCMTokenParams params) async {
    return await repository.registerFCMToken(params.token);
  }
}

/// Parameters for registering FCM token
class RegisterFCMTokenParams extends Equatable {
  final String token;

  const RegisterFCMTokenParams({required this.token});

  @override
  List<Object?> get props => [token];
}
