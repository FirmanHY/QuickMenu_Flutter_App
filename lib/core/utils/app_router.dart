import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/splash/splash_screen.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/auth/register_screen.dart';
import '../../presentation/views/home/home_screen.dart';

abstract final class AppRoutes {
  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String home          = '/home';
  static const String explore       = '/explore';
  static const String collection    = '/collection';
  static const String planner       = '/planner';
  static const String recipeDetail  = '/recipe/:recipeId';
  static const String addManual     = '/recipe/add/manual';
  static const String editRecipe    = '/recipe/edit/:recipeId';
  static const String importPreview = '/recipe/import-preview';

  static String recipeDetailPath(String id) => '/recipe/$id';
  static String editRecipePath(String id)   => '/recipe/edit/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final currentPath = state.matchedLocation;

      if (currentPath == AppRoutes.splash) return null;


      if (authState.isLoading) return null;

      final isLoggedIn  = authState.value != null;
      final isAuthRoute = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register;


      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      if (isLoggedIn && currentPath == AppRoutes.login) return AppRoutes.home;

      return null;
    },
    routes: [
      // ── Splash — cold start only ──────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Main App — ShellRoute dengan bottom nav ───────────────
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.explore,
            name: 'explore',
            builder: (_, __) => const _Placeholder('Explore'),
          ),
          GoRoute(
            path: AppRoutes.collection,
            name: 'collection',
            builder: (_, __) => const _Placeholder('Koleksi'),
          ),
          GoRoute(
            path: AppRoutes.planner,
            name: 'planner',
            builder: (_, __) => const _Placeholder('Planner'),
          ),
        ],
      ),

      // ── Detail routes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.recipeDetail,
        name: 'recipe-detail',
        builder: (_, state) =>
            _Placeholder('Detail: ${state.pathParameters['recipeId']}'),
      ),
      GoRoute(
        path: AppRoutes.addManual,
        name: 'add-manual',
        builder: (_, __) => const _Placeholder('Tambah Manual'),
      ),
      GoRoute(
        path: AppRoutes.editRecipe,
        name: 'edit-recipe',
        builder: (_, state) =>
            _Placeholder('Edit: ${state.pathParameters['recipeId']}'),
      ),
      GoRoute(
        path: AppRoutes.importPreview,
        name: 'import-preview',
        builder: (_, state) => _Placeholder(
            'Preview: ${state.uri.queryParameters['url'] ?? ''}'),
      ),
    ],
  );
});

// ── Bottom Nav Shell ──────────────────────────────────────────
class _MainShell extends StatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  static const _tabs = [
    (label: AppStrings.home,       icon: Icons.home_outlined,           active: Icons.home,           path: AppRoutes.home),
    (label: AppStrings.explore,    icon: Icons.search_outlined,          active: Icons.search,         path: AppRoutes.explore),
    (label: AppStrings.collection, icon: Icons.bookmark_border_outlined, active: Icons.bookmark,       path: AppRoutes.collection),
    (label: AppStrings.planner,    icon: Icons.calendar_month_outlined,  active: Icons.calendar_month, path: AppRoutes.planner),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) {
                setState(() => _index = i);
                context.go(_tabs[i].path);
              },
              items: _tabs
                  .map((t) => BottomNavigationBarItem(
                        icon: Icon(t.icon),
                        activeIcon: Icon(t.active),
                        label: t.label,
                      ))
                  .toList(),
            ),
          ),
        ),
      );
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );
}