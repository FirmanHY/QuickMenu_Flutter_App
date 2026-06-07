import 'package:dio/dio.dart';
import '../../core/constants/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/recipe_model.dart';

class ScrapedRecipe {
  final String title;
  final String duration;
  final String ingredients;
  final String steps;
  final String? imageUrl;
  final String source;
  final String originalUrl;

  const ScrapedRecipe({
    required this.title,
    required this.duration,
    required this.ingredients,
    required this.steps,
    this.imageUrl,
    required this.source,
    required this.originalUrl,
  });

  RecipeModel toRecipeModel() => RecipeModel(
    id: '',
    title: title,
    imageUrl: imageUrl,
    duration: duration,
    categories: [],
    ingredients: ingredients,
    steps: steps,
    source: source,
    originalUrl: originalUrl,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

class ScraperService {
  final Dio _dio;

  ScraperService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.scraperBaseUrl,
              connectTimeout:
                  Duration(seconds: AppConfig.connectTimeoutSec),
              receiveTimeout:
                  Duration(seconds: AppConfig.receiveTimeoutSec),
            ));

  Future<ScrapedRecipe> scrapeFromUrl(String url) async {
    try {
      final response = await _dio
          .post(AppConfig.scraperScrapeEndpoint, data: {'url': url});
      final body = response.data as Map<String, dynamic>;

      if (body['success'] != true) {
        throw ScraperException(
            body['error']?.toString() ?? 'Gagal scraping');
      }

      final data = body['data'] as Map<String, dynamic>;
      return ScrapedRecipe(
        title: data['title']?.toString() ?? '',
        duration: data['duration']?.toString() ?? '0',
        ingredients: data['ingredients']?.toString() ?? '',
        steps: data['steps']?.toString() ?? '',
        imageUrl: data['imageUrl']?.toString(),
        source: data['source']?.toString() ?? 'Web',
        originalUrl: data['originalUrl']?.toString() ?? url,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Koneksi timeout');
      }
      throw ScraperException(
          e.response?.data?['error']?.toString() ??
              'Gagal menghubungi scraper');
    }
  }
}