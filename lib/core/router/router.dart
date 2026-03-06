import 'package:flutter/cupertino.dart';
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

Page<void> _slidePage(GoRouterState state, Widget child) {
  return CupertinoPage(key: state.pageKey, child: child);
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
        pageBuilder: (context, state) => _slidePage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _slidePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _slidePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) {
          final cat = state.uri.queryParameters['category'];
          return _slidePage(state, SearchScreen(initialCategory: cat));
        },
      ),
      GoRoute(
        path: '/search/results',
        pageBuilder: (context, state) => _slidePage(
          state,
          SearchResultsScreen(
            queryParams: Map<String, String>.from(state.uri.queryParameters),
          ),
        ),
      ),
      GoRoute(
        path: '/listing/:id',
        pageBuilder: (context, state) => _slidePage(
          state,
          ListingDetailScreen(listingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/profile/:id',
        pageBuilder: (context, state) => _slidePage(
          state,
          ProfileScreen(userId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => _slidePage(state, const FavoritesScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _slidePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _slidePage(state, EmailVerificationScreen(email: email));
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _slidePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/create-listing',
        pageBuilder: (context, state) => _slidePage(state, const CreateListingScreen()),
      ),
      GoRoute(
        path: '/my-listings',
        pageBuilder: (context, state) => _slidePage(state, const _PlaceholderScreen(title: 'İlanlarım')),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _slidePage(state, const _PlaceholderScreen(title: 'Ayarlar')),
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
