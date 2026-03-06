import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/splash/presentation/screens/splash_screen.dart';
import 'package:cypcar/features/home/presentation/screens/home_screen.dart';
import 'package:cypcar/features/search/presentation/screens/search_screen.dart';
import 'package:cypcar/features/search/presentation/screens/search_results_screen.dart';
import 'package:cypcar/features/auth/presentation/screens/login_screen.dart';
import 'package:cypcar/features/auth/presentation/screens/register_screen.dart';
import 'package:cypcar/features/create_listing/presentation/screens/create_listing_screen.dart';
import 'package:cypcar/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:cypcar/features/profile/presentation/screens/profile_screen.dart';
import 'package:cypcar/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cypcar/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cypcar/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:cypcar/features/auth/presentation/screens/forgot_password_screen.dart';

Page<void> _fadePage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 1000),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadePage(context, state, const HomeScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final cat = state.uri.queryParameters['category'];
          return SearchScreen(initialCategory: cat);
        },
      ),
      GoRoute(
        path: '/search/results',
        builder: (context, state) => SearchResultsScreen(
          queryParams: Map<String, String>.from(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) =>
            ProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/create-listing',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        builder: (context, state) => const _PlaceholderScreen(title: 'İlanlarım'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _PlaceholderScreen(title: 'Ayarlar'),
      ),
    ],
  );
});

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(yakında)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
