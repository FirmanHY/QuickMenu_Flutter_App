import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/app_router.dart';
import '../../../presentation/viewmodels/auth_viewmodel.dart';
import '../../../presentation/viewmodels/home_viewmodel.dart';
import '../../../shared/widgets/daily_menu_card.dart';
import '../../../shared/widgets/recipe_card.dart';
import '../../../shared/widgets/empty_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data saat screen pertama kali mount
    Future.microtask(
      () => ref.read(homeViewModelProvider.notifier).loadHomeData(),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  static IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return Icons.wb_sunny_rounded;
    if (hour >= 11 && hour < 15) return Icons.wb_sunny_rounded;
    if (hour >= 15 && hour < 18) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }

  static Color _getGreetingIconColor() {
    final hour = DateTime.now().hour;
    if (hour >= 18 || hour < 5) return AppColors.primary;
    return const Color(0xFFFDB813);
  }

  static String _getDayName() {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return days[DateTime.now().weekday % 7];
  }

  Future<void> _onRefresh() async {
    await ref
        .read(homeViewModelProvider.notifier)
        .loadHomeData(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final firstName = homeState.userName.split(' ').first;

    // Snackbar error
    ref.listen(homeViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        ref.read(homeViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenHorizontal,
                    AppDimensions.xl,
                    AppDimensions.screenHorizontal,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting + nama
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getGreetingIcon(),
                                size: 18,
                                color: _getGreetingIconColor(),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getGreeting(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(firstName, style: AppTextStyles.h2),
                        ],
                      ),

                      // Menu button (untuk logout, dll)
                      _MenuButton(),
                    ],
                  ),
                ),
              ),

              // ── Search bar (non-editable, tap → Explore) ────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenHorizontal,
                    AppDimensions.xxl,
                    AppDimensions.screenHorizontal,
                    0,
                  ),
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.explore),
                    child: Container(
                      height: AppDimensions.inputHeight,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: AppDimensions.lg),
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.gray400,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text(
                            'Cari resep sehat...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Daily Menu Card ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenHorizontal,
                    AppDimensions.xxl,
                    AppDimensions.screenHorizontal,
                    0,
                  ),
                  child: DailyMenuCard(
                    dayName: _getDayName(),
                    plan: homeState.todayPlan,
                    onPressWeeklyPlan: () => context.go(AppRoutes.planner),
                  ),
                ),
              ),

              // ── Section Header: Resep Sehat ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenHorizontal,
                    AppDimensions.xxxl,
                    AppDimensions.screenHorizontal,
                    AppDimensions.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Resep Sehat Pilihan', style: AppTextStyles.h3),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.explore),
                        child: Text(
                          'Lihat Semua',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recipe List / Loading / Empty ────────────────────
              if (homeState.isLoading)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (homeState.healthyRecipes.isEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: EmptyState.section(
                      message: 'Belum ada resep sehat.',
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenHorizontal,
                      ),
                      itemCount: homeState.healthyRecipes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppDimensions.md),
                      itemBuilder: (context, index) {
                        final recipe = homeState.healthyRecipes[index];
                        return RecipeCard(
                          imageUrl: recipe.imageUrl ?? '',
                          title: recipe.title,
                          duration: recipe.duration,
                          category: recipe.categories.isNotEmpty
                              ? '#${recipe.categories.first}'
                              : '#Sehat',
                          variant: RecipeCardVariant.large,
                          showBookmark: true,
                          isBookmarked: recipe.isBookmarked,
                          onPress: () => context.push(
                            AppRoutes.recipeDetailPath(recipe.id),
                          ),
                          onBookmarkPress: () => ref
                              .read(homeViewModelProvider.notifier)
                              .toggleBookmark(recipe.id, recipe.isBookmarked),
                        );
                      },
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.xxxxl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu Button dengan bottom sheet logout ────────────────────
class _MenuButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showMenuSheet(context, ref),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  void _showMenuSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Profil user
            Consumer(
              builder: (_, r, _) {
                final name = r.watch(homeViewModelProvider).userName;
                final user = r.watch(authStateProvider).value;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'Q',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.labelLarge),
                        Text(user?.email ?? '', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Tombol Logout
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              title: Text(
                'Keluar',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Keluar'),
                    content: const Text('Yakin mau keluar dari akun?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(d, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authViewModelProvider.notifier).logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
