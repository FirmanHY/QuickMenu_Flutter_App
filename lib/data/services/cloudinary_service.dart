import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/app_config.dart';
import '../../core/errors/app_exception.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final int width;
  final int height;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.width,
    required this.height,
  });
}

class CloudinaryService {
  final Dio _dio;

  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  Future<CloudinaryUploadResult> uploadImage(
    File imageFile, {
    String folder = 'user_recipes',
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final formData = FormData.fromMap({
        'file': base64Img,
        'upload_preset': AppConfig.cloudinaryUploadPreset,
        'folder': '${AppConfig.cloudinaryFolder}/$folder',
      });

      final response = await _dio.post(
        AppConfig.cloudinaryBaseUrl,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return CloudinaryUploadResult(
        secureUrl: data['secure_url'] as String,
        publicId: data['public_id'] as String,
        width: data['width'] as int,
        height: data['height'] as int,
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error']?['message']?.toString() ??
          'Gagal upload ke Cloudinary';
      throw StorageException(msg);
    } catch (e) {
      throw StorageException('Gagal upload gambar: $e');
    }
  }
}
