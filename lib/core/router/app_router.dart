import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/messenger/presentation/bloc/messenger_bloc.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/two_fa_screen.dart';
import '../../features/auth/presentation/screens/pin_setup_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/ai_twin_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/notes/presentation/screens/notes_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';

import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/tenant/presentation/screens/organization_list_screen.dart';
import '../../features/tenant/presentation/screens/organization_detail_screen.dart';
import '../../features/tenant/presentation/screens/invite_screen.dart';
import '../../features/sessions/presentation/screens/sessions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/wallpaper_picker_screen.dart';
import '../../features/messenger/presentation/screens/conversations_screen.dart';
import '../../features/messenger/presentation/screens/chat_room_screen.dart';
import '../../features/messenger/presentation/screens/user_search_screen.dart';
import '../../features/messenger/presentation/screens/contact_requests_screen.dart';
import '../../features/messenger/presentation/screens/user_profile_screen.dart';
import '../../features/messenger/presentation/screens/create_group_screen.dart';
import '../../features/messenger/presentation/screens/group_settings_screen.dart';
import '../../features/messenger/presentation/screens/add_group_members_screen.dart';
import '../../features/messenger/presentation/screens/channel_directory_screen.dart';
import '../../features/messenger/presentation/screens/channel_settings_screen.dart';
import '../../features/voice/presentation/screens/voice_call_screen.dart';
import '../../features/call_history/presentation/screens/call_history_screen.dart';
import '../../features/profile_sections/presentation/screens/profile_sections_screen.dart';
import '../storage/secure_storage_service.dart';
import '../di/service_locator.dart';
import '../utils/constants.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/messenger/presentation/screens/share_target_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final appRouter = GoRouter(
  initialLocation: RouteConstants.splash,
  redirect: _globalRedirect,
  routes: [
    GoRoute(
      path: RouteConstants.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteConstants.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RouteConstants.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteConstants.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RouteConstants.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteConstants.twoFA,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TwoFAScreen(
          email: extra?['email'] as String? ?? '',
          tempToken: extra?['tempToken'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: RouteConstants.pinSetup,
      builder: (_, __) => const PinSetupScreen(),
    ),
    GoRoute(
      path: RouteConstants.pinEntry,
      builder: (_, __) => const PinEntryScreen(),
    ),
    // Deep link: invite
    GoRoute(
      path: RouteConstants.invite,
      builder: (_, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return InviteScreen(token: token);
      },
    ),
    // Public room deep link: /room/{code} → redirect to voice screen
    GoRoute(
      path: '/room/:code',
      redirect: (_, state) {
        final code = state.pathParameters['code'] ?? '';
        return '${RouteConstants.voice}?publicCode=$code';
      },
    ),
    // Voice call (full-screen, outside ShellRoute)
    GoRoute(
      path: RouteConstants.voice,
      builder: (_, state) {
        final roomName = state.uri.queryParameters['room'];
        final conversationId = state.uri.queryParameters['convId'];
        final incoming = state.uri.queryParameters['incoming'] == '1';
        final callee = state.uri.queryParameters['callee'];
        final calleeAvatar = state.uri.queryParameters['calleeAvatar'];
        final calleeId = state.uri.queryParameters['calleeId'];
        final e2eeKey = state.uri.queryParameters['e2ee'];
        final publicCode = state.uri.queryParameters['publicCode'];
        return VoiceCallScreen(
          roomName: roomName,
          conversationId: conversationId,
          isIncoming: incoming,
          calleeName: callee,
          calleeAvatar: calleeAvatar,
          calleeId: calleeId,
          e2eeKey: e2eeKey,
          publicCode: publicCode,
        );
      },
    ),
    // Share-in recipient picker (full-screen, outside shell)
    GoRoute(
      path: '/share-target',
      builder: (context, state) {
        final files = (state.extra as List?)?.cast<SharedMediaFile>() ?? const <SharedMediaFile>[];
        return ShareTargetScreen(sharedFiles: files);
      },
    ),
    // Dashboard shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => BlocProvider.value(
        value: sl<MessengerBloc>(),
        child: DashboardScreen(child: child),
      ),
      routes: [
        GoRoute(
          path: RouteConstants.assistant,
          builder: (_, __) => const AssistantScreen(),
        ),
        GoRoute(
          path: RouteConstants.contacts,
          builder: (_, __) => const ContactsScreen(),
        ),
        GoRoute(
          path: RouteConstants.notes,
          builder: (_, __) => const NotesScreen(),
        ),
        GoRoute(
          path: RouteConstants.calendar,
          builder: (_, __) => const CalendarScreen(),
        ),
        GoRoute(
          path: RouteConstants.profile,
          builder: (_, __) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'sections',
              builder: (_, __) => const ProfileSectionsScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (_, __) => const EditProfileScreen(),
            ),
            GoRoute(
              path: 'ai-twin',
              builder: (_, __) => const AiTwinScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RouteConstants.kyc,
          builder: (_, __) => const KycScreen(),
        ),
        GoRoute(
          path: RouteConstants.organization,
          builder: (_, __) => const OrganizationListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => OrganizationDetailScreen(
                tenantId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RouteConstants.callHistory,
          builder: (_, __) => const CallHistoryScreen(),
        ),
        GoRoute(
          path: RouteConstants.sessions,
          builder: (_, __) => const SessionsScreen(),
        ),
        GoRoute(
          path: RouteConstants.settings,
          builder: (_, __) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'wallpaper',
              builder: (_, __) => const WallpaperPickerScreen(),
            ),
          ],
        ),
        // User profile
        GoRoute(
          path: '/dashboard/user/:userId',
          builder: (_, state) => UserProfileScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
        // Messenger
        GoRoute(
          path: RouteConstants.messenger,
          builder: (_, __) => const ConversationsScreen(),
          routes: [
            GoRoute(
              path: 'search',
              builder: (_, __) => const UserSearchScreen(),
            ),
            GoRoute(
              path: 'contacts',
              builder: (_, state) {
                final tab = state.uri.queryParameters['tab'];
                return ContactRequestsScreen(initialTab: tab == 'incoming' ? 1 : 0);
              },
            ),
            GoRoute(
              path: 'create-group',
              builder: (_, __) => const CreateGroupScreen(),
            ),
            GoRoute(
              path: 'channels',
              builder: (_, __) => const ChannelDirectoryScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return ChatRoomScreen(
                  conversationId: state.pathParameters['id']!,
                  sharedFiles: extra?['sharedFiles'] as List?,
                  topicId: extra?['topicId'] as String?,
                  topicTitle: extra?['topicTitle'] as String?,
                );
              },
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (_, state) => GroupSettingsScreen(
                    conversationId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'add-members',
                  builder: (_, state) => AddGroupMembersScreen(
                    conversationId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'channel-settings',
                  builder: (_, state) => ChannelSettingsScreen(
                    channelId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  // Allow all auth routes and splash without token check
  final publicRoutes = [
    RouteConstants.login,
    RouteConstants.register,
    RouteConstants.twoFA,
    RouteConstants.splash,
    RouteConstants.pinEntry,
    RouteConstants.pinSetup,
    RouteConstants.onboarding,
    RouteConstants.forgotPassword,
  ];
  if (publicRoutes.any((r) => state.matchedLocation.startsWith(r))) return null;

  // Public room deep links don't need auth — join endpoint is unauthenticated
  if (state.matchedLocation.startsWith('/room/')) return null;

  // Public room voice calls: join-auth is tried first, guest join with name dialog
  // as fallback — no login required. The screen handles auth itself.
  if (state.uri.path == RouteConstants.voice &&
      state.uri.queryParameters['publicCode'] != null) {
    return null;
  }

  // Incoming voice calls are time-critical: bypass token check so the voice screen
  // opens immediately after CallKit accept. The join API itself requires a valid
  // token — AuthInterceptor refreshes it if expired. Blocking navigation here
  // causes silent failure when flutter_secure_storage is momentarily unavailable
  // right after the device unlocks (between CallKit accept and app resume).
  if (state.uri.path == RouteConstants.voice &&
      state.uri.queryParameters['incoming'] == '1') {
    return null;
  }

  // Check token for protected routes — wrapped to avoid silent navigation failure
  // if Keychain is briefly inaccessible during device unlock transition.
  try {
    final storage = sl<SecureStorageService>();
    final hasToken = await storage.hasRefreshToken;
    if (!hasToken) return RouteConstants.login;
  } catch (_) {
    // Storage temporarily unavailable — allow navigation; API auth handles the rest.
    return null;
  }

  return null;
}
