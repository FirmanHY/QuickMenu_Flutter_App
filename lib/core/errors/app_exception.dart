sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException   extends AppException { const NetworkException([super.message = 'Tidak ada koneksi internet']); }
class AuthException      extends AppException { const AuthException([super.message = 'Autentikasi gagal']); }
class NotFoundException  extends AppException { const NotFoundException([super.message = 'Data tidak ditemukan']); }
class ValidationException extends AppException { const ValidationException(super.message); }
class StorageException   extends AppException { const StorageException([super.message = 'Gagal menyimpan data']); }
class ScraperException   extends AppException { const ScraperException([super.message = 'Gagal mengambil resep dari URL']); }

class ServerException extends AppException {
  final int? statusCode;
  const ServerException({String message = 'Terjadi kesalahan server', this.statusCode}) : super(message);
}