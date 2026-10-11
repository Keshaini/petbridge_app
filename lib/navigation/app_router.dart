
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../forgot_password_screen.dart';
import '../login_screen.dart';
import '../onboarding_screen.dart';
import '../otp_verification_screen.dart';
import '../reset_password_screen.dart';
import '../signup_screen.dart';
import '../splash_screen.dart';

import '../map_screen.dart';
import '../screens/search/map_search_screen.dart';

import '../screens/reporting/create_report_screen.dart';
import '../screens/reporting/edit_report_screen.dart';
import '../screens/reporting/my_reports_screen.dart';
import '../screens/reporting/report_detail_screen.dart';

import '../screens/shelter/shelter_dashboard_screen.dart';
import '../screens/shelter/shelter_report_detail_screen.dart';
import '../screens/shelter/profile_screen.dart';
import '../screens/shelter/edit_profile_screen.dart';
import '../screens/shelter/settings_screen.dart';

import '../screens/shelter/chat_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',

  // ---------------------------------------------------------------------------
  // AUTHENTICATION REDIRECT
  // ---------------------------------------------------------------------------
  redirect: (BuildContext context, GoRouterState state) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final String location = state.matchedLocation;

    const publicRoutes = <String>{
      '/splash',
      '/onboarding',
      '/login',
      '/signup',
      '/forgot-password',
      '/otp-verification',
      '/reset-password',
    };

    final bool isPublicRoute = publicRoutes.contains(location);

    if (!isLoggedIn && !isPublicRoute) {
      return '/login';
    }

    if (isLoggedIn &&
        (location == '/onboarding' ||
            location == '/login' ||
            location == '/signup')) {
      return '/home';
    }

    return null;
  },

  // ---------------------------------------------------------------------------
  // APPLICATION ROUTES
  // ---------------------------------------------------------------------------
  routes: <RouteBase>[
    // Authentication
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // Home and map
    GoRoute(
      path: '/home',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/map-search',
      builder: (context, state) => const MapSearchScreen(),
    ),

    // Reports
    GoRoute(
      path: '/create-report',
      builder: (context, state) => const CreateReportScreen(),
    ),
    GoRoute(
      path: '/my-reports',
      builder: (context, state) => const MyReportsScreen(),
    ),
    GoRoute(
      path: '/report-details/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;

        return ReportDetailScreen(
          reportId: reportId,
        );
      },
    ),
    GoRoute(
      path: '/report-detail/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;

        return ReportDetailScreen(
          reportId: reportId,
        );
      },
    ),
    GoRoute(
      path: '/edit-report/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;

        return EditReportScreen(
          reportId: reportId,
        );
      },
    ),

    // Shelter dashboard
    GoRoute(
      path: '/shelter-dashboard',
      builder: (context, state) =>
          const ShelterDashboardScreen(),
    ),

    // Shelter report detail
    // Passes the selected Firestore report document ID.
    GoRoute(
      path: '/shelter-report-detail/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;

        return SightingReportDetailScreen(
          reportId: reportId,
        );
      },
    ),

    // Profile and settings
    GoRoute(
      path: '/profile',
      builder: (context, state) =>
          const UserProfileOverviewScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) =>
          const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const AppSettingsScreen(),
    ),

    // Chat
    GoRoute(
      path: '/chat',
      builder: (context, state) =>
          const DirectMessageChatScreen(),
    ),
  ],
);
