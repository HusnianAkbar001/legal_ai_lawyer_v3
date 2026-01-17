import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell_screen.dart';
import '../../features/content/presentation/screens/browse_content_screen.dart';
import '../../features/directory/presentation/screens/directory_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/preferences_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/checklists/presentation/screens/checklists_screen.dart';
import '../../features/checklists/presentation/screens/checklist_detail_screen.dart';
import '../../features/drafts/presentation/screens/drafts_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/user_features/presentation/screens/bookmarks_screen.dart';
import '../../features/user_features/presentation/screens/activity_log_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/admin/presentation/widgets/admin_layout.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_lawyers_screen.dart';
import '../../features/admin/presentation/screens/admin_knowledge_screen.dart';
import '../../features/admin/presentation/screens/admin_rights_screen.dart';
import '../../features/admin/presentation/screens/admin_templates_screen.dart';
import '../../features/admin/presentation/screens/admin_pathways_screen.dart';
import '../../features/admin/presentation/screens/admin_checklist_categories_screen.dart';
import '../../features/admin/presentation/screens/admin_checklist_items_screen.dart';
import '../../features/admin/presentation/screens/admin_contact_messages_screen.dart';
import '../../features/admin/presentation/screens/admin_feedback_screen.dart';
import '../../features/admin/presentation/screens/admin_rag_queries_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../preferences/preferences_providers.dart';

part 'app_router.g.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(Ref ref) {
    ref.listen<AsyncValue<dynamic>>(
      authControllerProvider,
      (previous, next) {
        notifyListeners();
      },
    );
    ref.listen<bool>(
      onboardingControllerProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

@Riverpod(keepAlive: true)
AuthStateNotifier authStateNotifier(Ref ref) {
  return AuthStateNotifier(ref);
}

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final authNotifier = ref.watch(authStateProvider);
  final onboardingComplete = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoading = authState.isLoading;
      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final isAdmin = user?.isAdmin == true;
      final path = state.uri.path;
      final isLoggingIn = path == '/login';
      final isSigningUp = path == '/signup';
      final isForgotPassword = path == '/forgot-password';
      final isResetPassword = path == '/reset-password';
      final isVerifyEmail = path == '/verify-email';
      final isSplash = path == '/splash';
      final isOnboarding = path == '/onboarding';
      final isAdminRoute = path.startsWith('/admin');
      final isAuthRoute = isLoggingIn || isSigningUp || isForgotPassword || isResetPassword || isVerifyEmail;
      final isOnboardingRoute = isSplash || isOnboarding;

      if (!onboardingComplete && !isOnboardingRoute) {
        return '/onboarding';
      }

      if (onboardingComplete && isOnboarding) {
        if (isLoggedIn && isAdmin) {
          return '/admin/overview';
        }
        if (isLoggedIn && !isAdmin) {
          return '/';
        }
        return '/login';
      }

      if (isLoading) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute && !isSplash && !isOnboarding) {
        return '/login';
      }

      if (isLoggedIn && isAdmin) {
        if (!isAdminRoute) {
          return '/admin/overview';
        }
        if (isAuthRoute) {
          return '/admin/overview';
        }
      }

      if (isLoggedIn && !isAdmin) {
        if (isAdminRoute) {
          return '/';
        }
        if (isAuthRoute) {
          return '/';
        }
      }

      return null;
    },
    routes: [
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
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => EmailVerificationScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) => const BrowseContentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checklists',
                builder: (context, state) => const ChecklistsScreen(),
                routes: [
                  GoRoute(
                    path: ':categoryId',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['categoryId'] ?? '');
                      return ChecklistDetailScreen(
                        categoryId: id ?? 0,
                        categoryTitle: state.uri.queryParameters['title'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/directory',
                builder: (context, state) => const DirectoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/overview',
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin/overview',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/lawyers',
            builder: (context, state) => const AdminLawyersScreen(),
          ),
          GoRoute(
            path: '/admin/knowledge',
            builder: (context, state) => const AdminKnowledgeScreen(),
          ),
          GoRoute(
            path: '/admin/rights',
            builder: (context, state) => const AdminRightsScreen(),
          ),
          GoRoute(
            path: '/admin/templates',
            builder: (context, state) => const AdminTemplatesScreen(),
          ),
          GoRoute(
            path: '/admin/pathways',
            builder: (context, state) => const AdminPathwaysScreen(),
          ),
          GoRoute(
            path: '/admin/checklists',
            builder: (context, state) => const AdminChecklistCategoriesScreen(),
          ),
          GoRoute(
            path: '/admin/checklists/:categoryId',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['categoryId'] ?? '');
              return AdminChecklistItemsScreen(
                categoryId: id ?? 0,
                categoryTitle: state.uri.queryParameters['title'],
              );
            },
          ),
          GoRoute(
            path: '/admin/contact',
            builder: (context, state) => const AdminContactMessagesScreen(),
          ),
          GoRoute(
            path: '/admin/contact/:messageId',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['messageId'] ?? '');
              return AdminContactMessageDetailScreen(messageId: id ?? 0);
            },
          ),
          GoRoute(
            path: '/admin/feedback',
            builder: (context, state) => const AdminFeedbackScreen(),
          ),
          GoRoute(
            path: '/admin/feedback/:feedbackId',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['feedbackId'] ?? '');
              return AdminFeedbackDetailScreen(feedbackId: id ?? 0);
            },
          ),
          GoRoute(
            path: '/admin/rag-queries',
            builder: (context, state) => const AdminRagQueriesScreen(),
          ),
          GoRoute(
            path: '/admin/rag-queries/:queryId',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['queryId'] ?? '');
              return AdminRagQueryDetailScreen(queryId: id ?? 0);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/drafts',
        builder: (context, state) => const DraftsScreen(),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityLogScreen(),
      ),
    ],
  );
}

