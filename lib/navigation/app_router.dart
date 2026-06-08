import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/exercises/exercises_screen.dart';
import '../presentation/screens/exercises/exercise_detail_screen.dart';
import '../presentation/screens/workout/workout_screen.dart';
import '../presentation/screens/workout/active_workout_screen.dart';
import '../presentation/screens/workout/workout_editor_screen.dart';
import '../presentation/screens/progress/progress_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/log/log_home_screen.dart';
import '../presentation/screens/log/active_log_screen.dart';
import '../presentation/screens/log/history_screen.dart';
import '../presentation/screens/log/planning_screen.dart';
import '../providers/user_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: user == null ? '/onboarding' : '/home',
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
            builder: (_, __) => const HomeScreen(),
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
            builder: (_, __) => const WorkoutScreen(),
            routes: [
              GoRoute(
                path: 'active',
                builder: (_, __) => const ActiveWorkoutScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (_, state) => WorkoutEditorScreen(
                  workoutId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/log',
            builder: (_, __) => const LogHomeScreen(),
          ),
          GoRoute(
            path: '/log/history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/log/planning',
            builder: (_, __) => const PlanningScreen(),
          ),
          GoRoute(
            path: '/log/session/:type',
            builder: (_, state) => ActiveLogScreen(
              sessionType: int.parse(state.pathParameters['type'] ?? '1'),
            ),
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
    final isActiveWorkout = location.contains('/workout/active');

    return Scaffold(
      body: child,
      bottomNavigationBar: isActiveWorkout
          ? null
          : _BottomNav(currentLocation: location),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentLocation;
  const _BottomNav({required this.currentLocation});

  int get _currentIndex {
    if (currentLocation.startsWith('/home')) return 0;
    if (currentLocation.startsWith('/exercises')) return 1;
    if (currentLocation.startsWith('/workout')) return 2;
    if (currentLocation.startsWith('/progress')) return 3;
    if (currentLocation.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A3A), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          const routes = ['/home', '/exercises', '/workout', '/progress', '/profile'];
          context.go(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Exercices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center_rounded),
            label: 'Séances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart_rounded),
            label: 'Progrès',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
