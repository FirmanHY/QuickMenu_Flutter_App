abstract final class AppStrings {
  static const String appName = 'QuickMenu';

  // Auth
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String loginWithGoogle = 'Masuk dengan Google';
  static const String noAccount = 'Belum punya akun? ';
  static const String haveAccount = 'Sudah punya akun? ';

  // Navigation
  static const String home = 'Beranda';
  static const String explore = 'Explore';
  static const String collection = 'Koleksi';
  static const String planner = 'Planner';

  // Home
  static const String greetingMorning = 'Selamat Pagi 🌤';
  static const String greetingAfternoon = 'Selamat Siang ☀️';
  static const String greetingEvening = 'Selamat Sore 🌇';
  static const String greetingNight = 'Selamat Malam 🌙';
  static const String dailyMenuTitle = 'Menu Hari Ini';
  static const String recommendedTitle = 'Rekomendasi Resep';
  static const String seeAll = 'Lihat Semua';

  // Explore
  static const String searchRecipe = 'Cari resep...';
  static const String allCategory = 'Semua';

  // Collection
  static const String myCollection = 'Koleksi Saya';
  static const String addRecipe = 'Tambah Resep';
  static const String importFromLink = 'Import dari Link';
  static const String smartPaste = 'Smart Paste';
  static const String addManual = 'Tambah Manual';
  static const String emptyCollection = 'Koleksi Masih Kosong';
  static const String emptyCollectionSub = 'Mulai tambahkan resep favoritmu';

  // Recipe
  static const String ingredients = 'Bahan-bahan';
  static const String steps = 'Cara Memasak';
  static const String duration = 'Durasi';
  static const String saveRecipe = 'Simpan Resep';
  static const String updateRecipe = 'Update Resep';
  static const String scheduleRecipe = 'Jadwalkan';
  static const String editRecipe = 'Edit Resep';

  // Planner
  static const String breakfast = 'Sarapan';
  static const String lunch = 'Makan Siang';
  static const String dinner = 'Makan Malam';

  // General
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String delete = 'Hapus';
  static const String loading = 'Memuat...';
  static const String retry = 'Coba Lagi';

  // Error
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorNetwork = 'Tidak ada koneksi internet';
  static const String errorEmptyField = 'Field ini tidak boleh kosong';
  static const String errorInvalidEmail = 'Format email tidak valid';
  static const String errorPasswordShort = 'Password minimal 6 karakter';

  // Success
  static const String successSaveRecipe = 'Resep berhasil disimpan!';
  static const String successDeleteRecipe = 'Resep berhasil dihapus!';
  static const String successBookmark = 'Resep ditambahkan ke koleksi!';
  static const String successSchedule = 'Resep berhasil dijadwalkan!';

  // Days & Categories
  static const List<String> dayLabels = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];
  static const List<String> defaultCategories = [
    'Semua',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Healthy',
    'Quick',
  ];
}
