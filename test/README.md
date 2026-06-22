# Unit Testing — QuickMenu (AFL 3)

## Fitur yang Dipilih

**Search & Filter pada layar Explore** (User Story US-10 / US-12).

Di layar Explore, pengguna dapat mencari resep dengan kata kunci dan menyaringnya
berdasarkan kategori (mis. "Sarapan", "Makan Malam"). Hasil yang ditampilkan adalah
gabungan dari kedua filter tersebut.

## Logika yang Diuji

Getter **`ExploreState.filteredRecipes`** pada
`lib/presentation/viewmodels/explore_viewmodel.dart`.

Getter ini menerima daftar lengkap resep (`allRecipes`) lalu mengembalikan daftar
yang sudah disaring berdasarkan:

1. **Kategori terpilih** (`selectedCategory`) — `'Semua'` berarti tanpa filter.
2. **Kata kunci pencarian** (`searchQuery`) — dicocokkan dengan **judul** maupun
   **nama kategori** resep, dan bersifat *case-insensitive*.

Logika ini dipilih karena **murni (pure)**: tidak bergantung pada Firebase,
jaringan, atau widget UI, sehingga dapat diuji secara terisolasi tanpa mocking.
Ini adalah inti dari fitur pencarian, sehingga kebenarannya penting.

## Cakupan Test

File: `test/explore_filter_test.dart` — 7 test case, semuanya mengikuti pola
**Arrange – Act – Assert**:

| # | Skenario | Yang diverifikasi |
|---|----------|-------------------|
| 1 | Tanpa filter | Semua resep dikembalikan |
| 2 | Filter kategori | Hanya resep pada kategori tsb |
| 3 | Kategori huruf kecil | Pencocokan *case-insensitive* |
| 4 | Cari kata kunci di judul | Resep dengan judul cocok |
| 5 | Cari kata kunci di kategori | Pencocokan juga ke nama kategori |
| 6 | Kategori + kata kunci | Kedua filter berlaku bersamaan |
| 7 | Tidak ada yang cocok | List kosong + `isEmpty == true` |

## Cara Menjalankan

```bash
flutter pub get
flutter test test/explore_filter_test.dart
```

Hasil yang diharapkan: `+7: All tests passed!`
