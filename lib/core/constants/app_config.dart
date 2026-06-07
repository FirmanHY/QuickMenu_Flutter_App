abstract final class AppConfig {
  // Cloudinary — ganti dengan nilai dashboard kamu
  static const String cloudinaryCloudName   = 'YOUR_CLOUD_NAME';
  static const String cloudinaryUploadPreset = 'quickmenu_preset';
  static const String cloudinaryFolder      = 'user_recipes';
  static const String cloudinaryBaseUrl     =
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // Backend scraper
  // Android emulator: 10.0.2.2 | Real device: IP lokal PC
  static const String scraperBaseUrl       = 'http://10.0.2.2:3000';
  static const String scraperScrapeEndpoint = '/api/scrape';

  // Timeouts
  static const int connectTimeoutSec = 30;
  static const int receiveTimeoutSec = 30;
}