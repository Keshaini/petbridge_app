import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../splash_screen.dart';
import '../onboarding_screen.dart';
import '../login_screen.dart';
import '../signup_screen.dart';
import '../forgot_password_screen.dart';
import '../otp_verification_screen.dart';
import '../map_screen.dart';
import '../reset_password_screen.dart';

// Reporting screens
import '../screens/reporting/create_report_screen.dart' hide MapSearchScreen;
import '../screens/reporting/report_detail_screen.dart';
import '../screens/reporting/edit_report_screen.dart';
import '../screens/reporting/my_reports_screen.dart';

// Search
import '../screens/search/map_search_screen.dart';

// Shelter screens
import '../screens/shelter/shelter_dashboard_screen.dart';
import '../screens/shelter/shelter_report_detail_screen.dart';
import '../screens/shelter/settings_screen.dart';
import '../screens/shelter/profile_screen.dart';
import '../screens/shelter/edit_profile_screen.dart';
import '../screens/shelter/chat_screen.dart';

/// Screens a logged-out user is allowed to see.
const List<String> _publicRoutes = [
  '/splash',
  '/onboarding',
  '/login',
  '/signup',
  '/forgot-password',
  '/otp-verification',
  '/reset-password',
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',

  redirect: (context, state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final String loc = state.matchedLocation;

    // Logged out and opening an app screen -> send to Login
    if (!loggedIn && !_publicRoutes.contains(loc)) return '/login';

    // Logged in and opening Onboarding, Login or Sign Up -> send to Home
    if (loggedIn &&
        (loc == '/onboarding' || loc == '/login' || loc == '/signup')) {
      return '/home';
    }

    return null; // no redirect
  },

  routes: [
    // =========================
    // AUTHENTICATION
    // =========================
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

    // =========================
    // HOME
    // =========================
    GoRoute(
      path: '/home',
      builder: (context, state) => const MapScreen(),
    ),

    // =========================
    // REPORTING
    // =========================
    GoRoute(
      path: '/create-report',
      builder: (context, state) => const CreateReportScreen(),
    ),
    GoRoute(
      path: '/my-reports',
      builder: (context, state) => const MyReportsScreen(),
    ),
    GoRoute(
      path: '/report-detail/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return ReportDetailScreen(reportId: reportId);
      },
    ),
    GoRoute(
      path: '/edit-report/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return EditReportScreen(reportId: reportId);
      },
    ),

    // =========================
    // SEARCH
    // =========================
    GoRoute(
      path: '/map-search',
      builder: (context, state) => const MapSearchScreen(),
    ),

    // =========================
    // SHELTER
    // =========================
    GoRoute(
      path: '/shelter-dashboard',
      builder: (context, state) => const ShelterDashboardScreen(),
    ),
    GoRoute(
      path: '/shelter-report-detail',
      builder: (context, state) => const SightingReportDetailScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const UserProfileOverviewScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const DirectMessageChatScreen(),
    ),
  ],
);