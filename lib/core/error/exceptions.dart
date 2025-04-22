class ServerException implements Exception {
  final String message;
  final int statusCode;

  ServerException({this.message = 'Server error occurred', this.statusCode = 500});
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Cache error occurred'});
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'Network error occurred'});
}

class GeneralException implements Exception {
  final String message;

  GeneralException({this.message = 'An unexpected error occurred'});
} 