import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/language_selection_screen.dart';
import '../../features/registration/presentation/screens/role_selection_screen.dart';
import '../../features/registration/presentation/screens/profile_setup_screen.dart';
import '../../features/registration/presentation/screens/add_vehicle_screen.dart';
import '../../features/registration/presentation/screens/document_upload_screen.dart';
import '../../features/registration/presentation/screens/onboarding_payment_screen.dart';
import '../../features/registration/presentation/screens/subscription_plan_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/my_vehicles_screen.dart';
import '../../features/home/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/kyc_documents_screen.dart';
import '../../features/profile/presentation/screens/terms_privacy_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/home/presentation/screens/create_requirement_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../shared/widgets/main_layout.dart';
import '../helpers/onboarding_helper.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context, 
  required GoRouterState state, 
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ─── Auth / Onboarding ───────────────────────────────────────────
    GoRoute(
      path: '/',
      redirect: (_, __) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const LanguageSelectionScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) {
        final phone = state.extra as String?;
        return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: OtpScreen(phoneNumber: phone ?? ''));
      },
    ),
    GoRoute(
      path: '/role_selection',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const RoleSelectionScreen()),
    ),

    // ─── Partner Onboarding ──────────────────────────────────────────
    GoRoute(
      path: '/profile_setup',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const ProfileSetupScreen()),
    ),
    GoRoute(
      path: '/edit_profile',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const EditProfileScreen()),
    ),
    GoRoute(
      path: '/add_vehicle',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const AddVehicleScreen(isRegistration: true)),
    ),
    GoRoute(
      path: '/document_upload',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const DocumentUploadScreen()),
    ),
    GoRoute(
      path: '/onboarding_payment',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const OnboardingPaymentScreen()),
    ),

    // ─── Partner Screens (outside shell / full-screen) ───────────────
    GoRoute(
      path: '/my_vehicles',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const MyVehiclesScreen()),
    ),
    GoRoute(
      path: '/kyc_documents',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const KycDocumentsScreen()),
    ),
    GoRoute(
      path: '/subscription_plan',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const SubscriptionPlanScreen()),
    ),
    GoRoute(
      path: '/terms_privacy',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const TermsPrivacyScreen()),
    ),
    GoRoute(
      path: '/support',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const SupportScreen()),
    ),
    GoRoute(
      path: '/requirement/create',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const CreateRequirementScreen()),
    ),
    GoRoute(
      path: '/requirement/edit',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const CreateRequirementScreen()),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const NotificationsScreen()),
    ),

    // ─── Shell (Bottom Nav) — Instant IndexedStack Switching ────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              pageBuilder: (context, state) => const NoTransitionPage(child: AccountScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
