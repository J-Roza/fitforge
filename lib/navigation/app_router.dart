import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/exercises/exercises_screen.dart';
import '../presentation/screens/exercises/exercise_detail_screen.dart';
import '../presentation/screens/log/log_home_screen.dart';
import '../presentation/screens/progress/progress_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../providers/user_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Le routeur est créé UNE SEULE FOIS. On n'utilise pas ref.watch ici :
  // sinon un changement de profil (ex : restauration cloud qui invalide
  // userProfileProvider) recréerait tout le GoRouter et réinitialiserait la
  // navigation → écran noir. À la place, un ValueNotifier notifie le routeur
  // pour qu'il réévalue sa redirection, sans être recréé.
  final refresh = ValueNotifier<int>(0);
  ref.listen(userProfileProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation:
        ref.read(userProfileProvider) == null ? '/onboarding' : '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasProfile = ref.read(userProfileProvider) != null;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!hasProfile && !onOnboarding) return '/onboarding';
      if (hasProfile && onOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const LogHomeScreen(showBack: false),
          ),
          GoRoute(
            path: '/exercises',
            builder: (_, __) => const ExercisesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ExerciseDetailScreen(
                  exerciseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/workout',
            builder: (_, __) => const LogHomeScreen(showBack: false),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class _MainScaffold extends StatelessWidget {
  final Widget child;
  const _MainScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentLocation: location),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentLocation;
  const _BottomNav({required this.currentLocation});

  int get _currentIndex {
    if (currentLocation.startsWith('/home')) return 0;
    if (currentLocation.startsWith('/workout')) return 0;
    if (currentLocation.startsWith('/exercises')) return 1;
    if (currentLocation.startsWith('/progress')) return 2;
    if (currentLocation.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // NavigationBar Material 3 (pilule d'indicateur), stylée par le thème.
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          const routes = ['/home', '/exercises', '/progress', '/profile'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Exercices',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Progrès',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
