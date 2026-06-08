# QuickMenu — Aplikasi Manajemen Resep & Meal Planning

> Aplikasi mobile Flutter untuk mengelola resep, merencanakan menu mingguan, dan menemukan resep sehat menggunakan pola arsitektur **MVVM (Model-View-ViewModel)** dengan state management **Riverpod**.

---

## 📐 Gambaran Umum Pola MVVM

QuickMenu mengikuti pola **Model-View-ViewModel (MVVM)**, yang memisahkan aplikasi menjadi tiga lapisan utama:

```
lib/
├── data/                          # LAPISAN MODEL
│   ├── models/                    # Kelas data (RecipeModel, MealPlanModel, dll.)
│   ├── repositories/              # Akses data ke Firebase RTDB & Auth
│   └── services/                  # Layanan eksternal (Cloudinary, ScraperService)
│
├── presentation/
│   ├── viewmodels/                # LAPISAN VIEWMODEL
│   │   ├── auth_viewmodel.dart
│   │   ├── home_viewmodel.dart
│   │   ├── explore_viewmodel.dart
│   │   ├── recipe_viewmodel.dart
│   │   ├── planner_viewmodel.dart
│   │   ├── add_recipe_viewmodel.dart
│   │   └── import_preview_viewmodel.dart
│   └── views/                     # LAPISAN VIEW
│       ├── auth/
│       ├── home/
│       ├── explore/
│       ├── collection/
│       ├── recipe/
│       └── splash/
│
└── shared/
    └── widgets/                   # Komponen UI yang dapat digunakan ulang
```

### Tanggung Jawab Tiap Lapisan

#### 🗄️ Lapisan Model (`data/`)
Lapisan Model bertanggung jawab atas semua logika yang berkaitan dengan data:

| Komponen | Tanggung Jawab |
|----------|----------------|
| **Models** | Kelas data yang bersifat *immutable* (`RecipeModel`, `DailyMealPlanModel`, `CategoryModel`). Dilengkapi `fromMap()`/`toMap()` untuk serialisasi Firebase dan `copyWith()` untuk pembaruan data tanpa mutasi langsung. |
| **Repositories** | Mengabstraksi semua operasi Firebase Realtime Database. Setiap domain layar memiliki repository-nya sendiri (`RecipeRepository`, `AuthRepository`, `PlannerRepository`, `HomeRepository`, `CategoryRepository`). |
| **Services** | Mengelola integrasi pihak ketiga — `CloudinaryService` untuk unggah gambar dan `ScraperService` untuk scraping URL resep melalui backend Node.js. |

#### 🧠 Lapisan ViewModel (`presentation/viewmodels/`)
Lapisan ViewModel berperan sebagai jembatan antara Model dan View:

- Dibangun dengan **Riverpod `Notifier`** — setiap ViewModel meng-extend `Notifier<State>`.
- Menyimpan kelas `State` yang *immutable* dengan pola `copyWith()`.
- Mengekspos method (misalnya `loadData()`, `toggleBookmark()`, `submit()`) yang dipanggil oleh View.
- Menerapkan **optimistic update** pada fitur bookmark — UI langsung diperbarui, lalu dikembalikan (*rollback*) jika terjadi error.
- Setiap ViewModel diekspos melalui `NotifierProvider` (contoh: `exploreViewModelProvider`).

| ViewModel | Mengelola |
|-----------|-----------|
| `AuthViewModel` | Login, register, logout via Firebase Auth |
| `HomeViewModel` | Menu hari ini + seksi resep sehat |
| `ExploreViewModel` | Resep publik dengan fitur pencarian & filter kategori |
| `RecipeViewModel` | CRUD koleksi resep pengguna + bookmark |
| `PlannerViewModel` | Navigasi rencana makan mingguan & penambahan menu |
| `AddRecipeViewModel` | Pembuatan resep manual dengan editor teks kaya Quill |
| `ImportPreviewViewModel` | Alur scraping URL, pratinjau, dan penyimpanan resep |

#### 🖼️ Lapisan View (`presentation/views/`)
Lapisan View hanya berisi logika tampilan:

- Menggunakan `ConsumerWidget` / `ConsumerStatefulWidget` dari Riverpod untuk memantau state.
- Memanggil method ViewModel melalui `ref.read(provider.notifier).method()`.
- Mendengarkan efek samping (error, navigasi) menggunakan `ref.listen()`.
- **Tanpa logika bisnis** — semua keputusan ada di ViewModel.

### Alur Data

```
Aksi Pengguna (View)
        │
        ▼
ViewModel.method()
        │
        ▼
Repository.query()  ──►  Firebase RTDB / Auth / Cloudinary
        │
        ▼
State diperbarui via copyWith()
        │
        ▼
View dirender ulang via ref.watch()
```

---

## 🚀 Cara Menjalankan Aplikasi

### Prasyarat

Pastikan alat-alat berikut sudah terpasang:

- **Flutter SDK** `^3.x` — [Pasang Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** `^3.11.5` (sudah termasuk dalam Flutter)
- **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart
- **Firebase CLI** — untuk menghubungkan ke proyek Firebase
- **Node.js** (untuk backend scraper lokal, opsional untuk fitur import)

### Langkah-Langkah Setup

**1. Clone repositori**
```bash
git clone https://github.com/your-username/quickmenu.git
cd quickmenu
```

**2. Pasang dependensi Flutter**
```bash
flutter pub get
```

**3. Konfigurasi Firebase**

Proyek ini menggunakan Firebase Realtime Database dan Firebase Auth. File `google-services.json` (Android) harus ada di:

```
android/app/google-services.json
```

> ⚠️ File ini tidak disertakan dalam version control. Hubungi pemilik proyek atau buat proyek Firebase sendiri melalui [console.firebase.google.com](https://console.firebase.google.com).

**4. Konfigurasi Cloudinary** *(untuk fitur upload gambar)*

Buka `lib/core/constants/app_config.dart` dan ganti:
```dart
static const String cloudinaryCloudName = 'YOUR_CLOUD_NAME';
```
dengan nama cloud dan upload preset Cloudinary milikmu.

**5. Jalankan Backend Scraper** *(opsional — untuk fitur Import dari URL)*

```bash
cd scraper-backend/   # Direktori proyek Node.js kamu
npm install
node index.js         # Berjalan di port 3000
```

Untuk Android Emulator, base URL di `app_config.dart` sudah dikonfigurasi ke `http://10.0.2.2:3000`. Untuk perangkat fisik, ganti dengan alamat IP lokal mesin kamu.

**6. Jalankan Aplikasi Flutter**

```bash
# Cek perangkat yang terhubung
flutter devices

# Jalankan di emulator Android
flutter run

# Jalankan dengan log lengkap
flutter run -v

# Build APK (release)
flutter build apk --release
```

### Aturan Firebase Realtime Database (Pengembangan)

Untuk keperluan pengembangan, atur aturan Firebase RTDB menjadi:
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",

    "recipes": {
      ".indexOn": ["createdAt"]
    },

    "categories": {
      ".indexOn": ["order"]
    },

    "user_recipes": {
      "$uid": {
        ".indexOn": ["createdAt"],
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },

    "user_bookmarks": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },

    "user_meal_plans": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },

    "user_categories": {
      "$uid": {
        ".indexOn": ["createdAt"],
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },

    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

---

## 📦 Dependensi Utama

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `flutter_riverpod` | ^3.3.1 | State management (provider ViewModel) |
| `go_router` | ^17.3.0 | Navigasi deklaratif & deep linking |
| `firebase_auth` | ^6.5.2 | Autentikasi pengguna |
| `firebase_database` | ^12.4.2 | Realtime Database (resep, meal plan) |
| `dio` | ^5.9.2 | HTTP client untuk scraper API |
| `flutter_quill` | ^11.5.0 | Editor teks kaya untuk pembuatan resep |
| `cached_network_image` | ^3.4.1 | Pemuatan gambar dari jaringan yang efisien |
| `flutter_html` | ^3.0.0 | Menampilkan bahan-bahan & langkah masak berformat HTML |
| `image_picker` | ^1.2.2 | Pemilihan gambar dari galeri/kamera |
| `intl` | ^0.20.2 | Format tanggal (lokal Bahasa Indonesia) |

---

## 🗂️ Ringkasan Struktur Proyek

```
quickmenu/
├── lib/
│   ├── core/
│   │   ├── constants/        # AppColors, AppDimensions, AppTextStyles, AppStrings
│   │   ├── errors/           # Hierarki sealed AppException
│   │   ├── theme/            # AppTheme (Material 3)
│   │   └── utils/            # AppRouter (GoRouter), Responsive
│   ├── data/
│   │   ├── models/           # RecipeModel, MealPlanModel, CategoryModel
│   │   ├── repositories/     # Akses data Firebase
│   │   └── services/         # Cloudinary, ScraperService
│   ├── presentation/
│   │   ├── viewmodels/       # Riverpod Notifier ViewModels
│   │   └── views/            # Layar-layar Flutter
│   └── shared/
│       └── widgets/          # Dapat digunakan ulang: RecipeCard, AppButton, AppInput, dll.
├── assets/
│   ├── fonts/                # NunitoSans (400, 600, 700)
│   └── images/               # Ikon aplikasi
├── pubspec.yaml
└── README.md
```

---

## 💡 Refleksi

Membangun QuickMenu memberikan pemahaman yang jauh lebih dalam tentang bagaimana pola **MVVM memisahkan tanggung jawab** dalam proyek Flutter nyata. Hal yang paling berharga adalah melihat bagaimana pola `Notifier` dari Riverpod memetakan secara langsung ke peran ViewModel — menyimpan state, mengekspos method, dan tetap sepenuhnya terpisah dari UI. Sebelumnya, saya sering mencampur logika bisnis di dalam `StatefulWidget`, yang membuat kode sulit diuji dan dipelihara. Dengan MVVM, setiap lapisan memiliki kontrak yang jelas sehingga kode menjadi lebih rapi dan terorganisir.

Tantangan terbesar adalah mengelola **optimistic update dengan rollback**. Pada fitur bookmark, UI harus diperbarui secara instan sementara proses tulis ke Firebase berjalan di latar belakang — lalu dikembalikan ke kondisi semula jika gagal. Merancang pola ini dengan benar di beberapa ViewModel memerlukan desain `copyWith()` yang cermat pada kelas State. Tantangan lainnya adalah **alur import/scraping** — mengkoordinasikan state loading, error, pratinjau, dan penyimpanan dalam satu layar bertahap memperlihatkan mengapa menggunakan enum `ImportStatus` yang terdedikasi jauh lebih mudah dipahami dibandingkan menggunakan banyak flag boolean terpisah.

---

## 👨‍💻 Pembuat

**QuickMenu** — Aplikasi Flutter Meal Planning  
Dibangun dengan Flutter + Firebase + Riverpod