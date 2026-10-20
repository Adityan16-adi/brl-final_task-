import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/mentor/presentation/mentor_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/mentor',
      builder: (context, state) => const MentorScreen(),
    ),
  ],
);
