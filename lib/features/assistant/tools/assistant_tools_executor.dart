import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/agent/agent_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/update_check_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../billing/domain/repositories/billing_repository.dart';
import '../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../messenger/domain/entities/message_entity.dart';
import '../../messenger/domain/repositories/i_messenger_repository.dart';
import '../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../messenger/presentation/bloc/messenger_event.dart';
import '../../notifications/notification_filter.dart';
import '../../notifications/notification_permission_service.dart';
import '../../notifications/notification_store.dart';
import '../domain/assistant_action.dart';

/// Session-bound operations available only during an active voice session.
///
/// The callbacks are closures over the assistant screen's private state, so
/// the executor never touches widgets or BuildContext. In text mode
/// `hooks == null` → strictly session-bound tools (end_session) return a
/// polite refusal, while partially session-bound tools (set_theme,
/// set_language, set_preferred_name, get_release_notes, agent_task) simply
/// skip the screen-side effect.
class AssistantSessionHooks {
  AssistantSessionHooks({
    required this.endSession,
    required this.onPreferredNameChanged,
    required this.applyTheme,
    required this.applyLanguage,
    required this.localeCode,
    required this.getAgentConversationId,
    required this.setAgentConversationId,
  });

  /// end_session: schedule the graceful disconnect (AI says goodbye first)
  /// and return the tool output string.
  final Future<String> Function() endSession;

  /// set_preferred_name: reflect the new name in the screen state.
  final void Function(String name) onPreferredNameChanged;

  /// set_theme: apply the theme to the running app (needs BuildContext).
  final void Function(String theme) applyTheme;

  /// set_language: apply the locale to the running app (needs BuildContext).
  final void Function(String language) applyLanguage;

  /// get_release_notes: current UI locale code ('ru' fallback).
  final String Function() localeCode;

  /// agent_task: conversation continuity across agent_task calls within one
  /// voice session (screen resets it on each new session).
  final String? Function() getAgentConversationId;
  final void Function(String? id) setAgentConversationId;
}

/// Executes assistant tool calls (the former `_handleFunctionCall` switch of
/// AssistantScreen). Self-contained tools run over `sl<...>` services;
/// session-bound behaviors are delegated to [AssistantSessionHooks].
///
/// NOT handled here (kept in the screen because they send realtime events
/// mid-execution or return no output at all): `enter_translator_mode`,
/// `exit_translator_mode`, `start_call`.
class AssistantToolsExecutor {
  AssistantToolsExecutor({this.hooks, this.onAction});

  final AssistantSessionHooks? hooks;

  /// Reports created entities for action bubbles (instrumented in a later task).
  final void Function(AssistantAction action)? onAction;

  /// Same contract as the old _handleFunctionCall body: returns the string
  /// (JSON or human text) that is fed back to the LLM.
  Future<String> execute(String name, Map<String, dynamic> args) async {
    // Lazy: tools that don't hit the REST API (and the unknown-tool /
    // hookless-refusal paths) must work without a DI container (unit tests).
    late final DioClient client = sl<DioClient>();
    String output;
    try {
      if (name == 'end_session') {
        final h = hooks;
        if (h == null) {
          return 'This action is only available during a voice session.';
        }
        output = await h.endSession();
      } else if (name == 'web_search') {
        final query = args['query'] as String? ?? '';
        final data = await client.post<Map<String, dynamic>>(
          '/assistant/web-search',
          data: {'query': query},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
        final citations = (data['citations'] as List?)?.cast<String>();
        if (citations != null && citations.isNotEmpty) {
          onAction?.call(AssistantAction(
            type: AssistantActionType.webLink,
            entityId: citations.first,
            title:
                'Найдено: ${query.length > 40 ? query.substring(0, 40) : query}',
          ));
        }
      } else if (name == 'set_preferred_name') {
        final newName = (args['name'] as String? ?? '').trim();
        if (newName.isEmpty) {
          output = jsonEncode({'error': 'empty_name'});
        } else {
          await client.put(
            '/profile',
            data: {'assistantName': newName},
            fromJson: (d) => d,
          );
          hooks?.onPreferredNameChanged(newName);
          output = jsonEncode({'ok': true, 'name': newName});
        }
      } else if (name == 'get_profile') {
        final data = await client.get(
          '/profile',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'update_profile') {
        final data = await client.put(
          '/profile',
          data: args,
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'get_sections') {
        final data = await client.get<List<dynamic>>(
          '/profile-sections',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'upsert_section') {
        final data = await client.put<Map<String, dynamic>>(
          '/profile-sections',
          data: {
            'type': args['type'],
            'content': {
              'items': args['items'] ?? [],
              if (args['freeText'] != null) 'freeText': args['freeText'],
            },
            if (args['visibility'] != null) 'visibility': args['visibility'],
          },
          fromJson: (d) => d as Map<String, dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'delete_section') {
        await client.delete('/profile-sections/${args['type']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'search_contacts') {
        final query = args['query'] as String? ?? '';
        final data = await client.get<List<dynamic>>(
          '/messenger/users/search?q=${Uri.encodeComponent(query)}',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'get_conversations') {
        final data = await client.get<List<dynamic>>(
          '/messenger/conversations',
          fromJson: (d) => d as List<dynamic>,
        );
        // Return essential fields including unread info
        final slim = (data ?? []).map((c) {
          final m = c as Map<String, dynamic>;
          return {
            'id': m['id'],
            'otherUserName': m['otherUserName'],
            'otherUserId': m['otherUserId'],
            'type': m['type'],
            'unreadCount': m['unreadCount'] ?? 0,
            'lastMessageContent': m['lastMessageContent'],
            'lastMessageSenderName': m['lastMessageSenderName'],
          };
        }).toList();
        output = jsonEncode(slim);
      } else if (name == 'get_messages') {
        final convId = args['conversationId'] as String;
        final limit = args['limit'] as int? ?? 50;
        final data = await client.get<Map<String, dynamic>>(
          '/messenger/conversations/$convId/messages?limit=$limit',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'send_message') {
        final convId = args['conversationId'] as String;
        final content = args['content'] as String;
        sl<MessengerRemoteDataSource>().sendMessage(convId, content);
        onAction?.call(AssistantAction(
          type: AssistantActionType.messageSent,
          entityId: convId,
          conversationId: convId,
          title: 'Сообщение: ${content.length > 40 ? content.substring(0, 40) : content}',
        ));
        output = jsonEncode({'ok': true, 'message': 'sent'});
      } else if (name == 'delete_last_own_message') {
        final convId = args['conversationId'] as String;
        final bloc = sl<MessengerBloc>();
        final me = bloc.state.currentUserId;
        final msgs = bloc.state.messages[convId] ?? const [];
        final myMsgs = msgs.where((m) =>
          m.senderId == me &&
          !m.id.startsWith('temp_') &&
          !m.id.startsWith('call_invite_') &&
          !m.isSystem).toList();
        if (me == null || myMsgs.isEmpty) {
          output = jsonEncode({'ok': false, 'error': 'no own messages found in this conversation'});
        } else {
          final target = myMsgs.last;
          bloc.add(DeleteMessage(
            conversationId: convId,
            messageId: target.id,
            forEveryone: true,
          ));
          output = jsonEncode({
            'ok': true,
            'deletedMessageId': target.id,
            'deletedContent': target.content.length > 60
                ? '${target.content.substring(0, 60)}…'
                : target.content,
          });
        }
      } else if (name == 'get_notes') {
        final limit = args['limit'] as int? ?? 20;
        final data = await client.get<dynamic>('/notes?limit=$limit');
        output = jsonEncode(data);
      } else if (name == 'create_note') {
        final data = await client.post('/notes', data: {
          'title': args['title'] as String,
          'content': args['content'] as String,
          'source': 'ASSISTANT',
        }, fromJson: (d) => d);
        output = jsonEncode(data);
      } else if (name == 'delete_note') {
        await client.delete('/notes/${args['noteId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'get_events') {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        // Convert from/to to UTC for backend query
        String fromStr = args['from'] as String? ?? startOfDay.toUtc().toIso8601String();
        String toStr = args['to'] as String? ?? today.add(const Duration(days: 30)).toUtc().toIso8601String();
        if (!fromStr.endsWith('Z')) {
          final f = DateTime.tryParse(fromStr);
          if (f != null) fromStr = f.toUtc().toIso8601String();
        }
        if (!toStr.endsWith('Z')) {
          final t = DateTime.tryParse(toStr);
          if (t != null) toStr = t.toUtc().toIso8601String();
        }
        final data = await client.get<dynamic>('/calendar?from=$fromStr&to=$toStr');
        // Convert UTC times to local for the AI to read correct times
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final startUtc = DateTime.tryParse(item['startAt'] as String? ?? '');
              if (startUtc != null) item['startAt'] = startUtc.toLocal().toIso8601String();
              final endUtc = DateTime.tryParse(item['endAt'] as String? ?? '');
              if (endUtc != null) item['endAt'] = endUtc.toLocal().toIso8601String();
            }
          }
        }
        output = jsonEncode(data);
      } else if (name == 'create_event') {
        // Convert local time to UTC for correct storage
        String startAtUtc = args['startAt'] as String? ?? '';
        String displayTime = startAtUtc; // keep original for push display
        if (startAtUtc.isNotEmpty && !startAtUtc.endsWith('Z')) {
          final local = DateTime.tryParse(startAtUtc);
          if (local != null) {
            displayTime = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
            startAtUtc = local.toUtc().toIso8601String();
          }
        }
        String? reminderUtc;
        if (args['reminderAt'] != null) {
          final r = DateTime.tryParse(args['reminderAt'] as String);
          if (r != null) reminderUtc = r.toUtc().toIso8601String();
        }
        String? endUtc;
        if (args['endAt'] != null) {
          final e = DateTime.tryParse(args['endAt'] as String);
          if (e != null) endUtc = e.toUtc().toIso8601String();
        }
        final data = await client.post('/calendar', data: {
          'title': args['title'],
          'description': args['description'],
          'type': args['type'],
          'startAt': startAtUtc,
          if (endUtc != null) 'endAt': endUtc,
          if (reminderUtc != null) 'reminderAt': reminderUtc,
          if (args['contactIds'] != null) 'contactIds': args['contactIds'],
          'displayTime': displayTime,
          'createdBy': 'ASSISTANT',
        }, fromJson: (d) => d);
        final createdEventId = (data is Map && data['id'] is String)
            ? data['id'] as String
            : null;
        if (createdEventId != null) {
          onAction?.call(AssistantAction(
            type: AssistantActionType.eventCreated,
            entityId: createdEventId,
            title: args['title'] as String? ?? 'Событие',
          ));
        }
        output = jsonEncode(data);
      } else if (name == 'delete_event') {
        await client.delete('/calendar/${args['eventId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'get_contacts') {
        final data = await client.get<List<dynamic>>(
          '/messenger/conversations',
          fromJson: (d) => d as List<dynamic>,
        );
        final contacts = (data ?? [])
            .where((c) => (c as Map<String, dynamic>)['type'] == 'DIRECT')
            .map((c) {
          final m = c as Map<String, dynamic>;
          return {
            'userId': m['otherUserId'],
            'name': m['otherUserName'],
            'conversationId': m['id'],
          };
        }).toList();
        output = jsonEncode(contacts);
      } else if (name == 'send_contact_request') {
        final data = await client.post(
          '/messenger/contacts/request',
          data: {'receiverId': args['userId']},
          fromJson: (d) => d,
        );
        final receiverName = (data is Map)
            ? (data['receiverName'] as String? ??
                (data['receiver'] is Map
                    ? (data['receiver'] as Map)['name'] as String?
                    : null))
            : null;
        onAction?.call(AssistantAction(
          type: AssistantActionType.contactAdded,
          entityId: args['userId'] as String? ?? '',
          title: receiverName ?? 'Контакт',
        ));
        output = jsonEncode({'ok': true, 'data': data});
      } else if (name == 'get_contact_requests') {
        final data = await client.get<List<dynamic>>(
          '/messenger/contacts/requests',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'respond_contact_request') {
        final requestId = args['requestId'] as String;
        final action = args['action'] as String;
        final res = await client.patch(
          '/messenger/contacts/requests/$requestId/$action',
          data: {},
          fromJson: (d) => d,
        );
        if (action == 'accept') {
          final requesterId = (res is Map)
              ? (res['senderId'] as String? ?? res['requesterId'] as String?)
              : null;
          final requesterName = (res is Map)
              ? (res['senderName'] as String? ??
                  (res['sender'] is Map
                      ? (res['sender'] as Map)['name'] as String?
                      : null))
              : null;
          onAction?.call(AssistantAction(
            type: AssistantActionType.contactAdded,
            entityId: requesterId ?? requestId,
            title: requesterName ?? 'Контакт',
          ));
        }
        output = jsonEncode({'ok': true, 'action': action});
      } else if (name == 'delete_contact') {
        await client.delete('/messenger/contacts/${args['userId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'block_contact') {
        final userId = args['userId'] as String;
        final action = args['action'] as String;
        if (action == 'block') {
          await client.post('/messenger/contacts/$userId/block', data: {}, fromJson: (d) => d);
        } else {
          await client.delete('/messenger/contacts/$userId/block');
        }
        output = jsonEncode({'ok': true, 'action': action});
      } else if (name == 'get_call_history') {
        final limit = args['limit'] as int? ?? 20;
        final data = await client.get<dynamic>(
          '/voice/call-history?limit=$limit',
          fromJson: (d) => d,
        );
        output = jsonEncode(data);
      } else if (name == 'get_sessions') {
        final data = await client.get<List<dynamic>>(
          '/auth/sessions',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'terminate_session') {
        await client.delete('/auth/sessions/${args['sessionId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'create_group') {
        final data = await client.post(
          '/messenger/conversations/group',
          data: {
            'name': args['name'],
            'memberIds': args['memberIds'],
          },
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'manage_group_members') {
        final convId = args['conversationId'] as String;
        final userId = args['userId'] as String;
        final action = args['action'] as String;
        if (action == 'add') {
          await client.post(
            '/messenger/conversations/$convId/members',
            data: {'userId': userId},
            fromJson: (d) => d,
          );
        } else {
          await client.delete('/messenger/conversations/$convId/members/$userId');
        }
        output = jsonEncode({'ok': true, 'action': action});
      } else if (name == 'get_tenants') {
        final data = await client.get<List<dynamic>>(
          '/tenant',
          fromJson: (d) => d as List<dynamic>,
        );
        final slim = (data ?? []).map((t) {
          final m = t as Map<String, dynamic>;
          return {
            'id': m['id'],
            'name': m['name'],
            'role': m['role'],
            'membersCount': m['membersCount'],
          };
        }).toList();
        output = jsonEncode(slim);
      } else if (name == 'get_kyc_status') {
        final data = await client.get(
          '/kyc/status',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'react_to_message') {
        sl<MessengerRemoteDataSource>().reactToMessage(
          args['conversationId'] as String,
          args['messageId'] as String,
          args['emoji'] as String,
        );
        output = jsonEncode({'ok': true});
      } else if (name == 'forward_message') {
        sl<MessengerRemoteDataSource>().sendMessage(
          args['targetConversationId'] as String,
          args['content'] as String,
        );
        output = jsonEncode({'ok': true, 'message': 'forwarded'});
      } else if (name == 'pin_message' || name == 'unpin_message') {
        final convId = args['conversationId'] as String;
        final msgId = args['messageId'] as String;
        final pinning = name == 'pin_message';
        // Route the mutation through the bloc — not the repository — so the
        // chat UI reacts the same way it does when the user taps Pin/Unpin
        // (see PinMessage/UnpinMessage in messenger_bloc.dart). Bloc.add()
        // returns before its own HTTP call lands (the same caveat
        // PinnedMessagesScreen._reconcile documents), so confirm the outcome
        // by polling the authoritative pinned list with that screen's short
        // backoff instead of guessing at it.
        sl<MessengerBloc>().add(pinning
            ? PinMessage(conversationId: convId, messageId: msgId)
            : UnpinMessage(conversationId: convId, messageId: msgId));
        var pins = <MessageEntity>[];
        var confirmed = false;
        const maxAttempts = 3;
        for (var attempt = 0; attempt < maxAttempts; attempt++) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
          try {
            pins = await sl<IMessengerRepository>().getPinnedMessages(convId);
            confirmed = true;
          } catch (_) {
            break;
          }
          final isPinned = pins.any((p) => p.id == msgId);
          if (isPinned == pinning || attempt == maxAttempts - 1) break;
        }
        output = jsonEncode({
          'ok': confirmed,
          'pinned': pins.any((p) => p.id == msgId),
          'pinnedCount': pins.length,
        });
      } else if (name == 'list_pinned') {
        final convId = args['conversationId'] as String;
        final pins = await sl<IMessengerRepository>().getPinnedMessages(convId);
        output = jsonEncode(pins
            .map((m) => {
                  'messageId': m.id,
                  'text': m.content,
                  'senderName': m.senderName,
                })
            .toList());
      } else if (name == 'get_settings') {
        final storage = sl<SecureStorageService>();
        final theme = await storage.getThemeMode() ?? 'light';
        final lang = await storage.getLanguage() ?? 'ru';
        final biometric = await storage.isBiometricEnabled;
        final pin = await storage.isPinEnabled;
        output = jsonEncode({
          'theme': theme,
          'language': lang,
          'biometricEnabled': biometric,
          'pinEnabled': pin,
        });
      } else if (name == 'set_theme') {
        final theme = args['theme'] as String;
        final storage = sl<SecureStorageService>();
        await storage.saveThemeMode(theme);
        hooks?.applyTheme(theme);
        output = jsonEncode({'ok': true, 'theme': theme});
      } else if (name == 'set_language') {
        final lang = args['language'] as String;
        final storage = sl<SecureStorageService>();
        await storage.saveLanguage(lang);
        hooks?.applyLanguage(lang);
        output = jsonEncode({'ok': true, 'language': lang});
      } else if (name == 'set_biometric') {
        final enabled = args['enabled'] as bool;
        if (enabled) {
          // Enabling requires device authentication — not safe to do from assistant
          output = jsonEncode({'ok': false, 'error': 'Enabling biometrics requires user authentication. Please go to Settings to enable it.'});
        } else {
          await sl<SecureStorageService>().setBiometricEnabled(false);
          output = jsonEncode({'ok': true, 'biometricEnabled': false});
        }
      } else if (name == 'disable_pin') {
        // Same rule as enabling biometrics above, for the stronger reason:
        // removing the PIN takes away the last barrier on an unlocked device.
        // This model also reads third-party content (messenger_read_recent,
        // get_messages, check_mail), so a message crafted by someone else can
        // steer it into calling this — turning "read my messages" into
        // "disable my lock screen".
        output = jsonEncode({
          'ok': false,
          'error':
              'Disabling the PIN requires user authentication. Please go to Settings to turn it off.',
        });
      } else if (name == 'ask_analyst') {
        final question = args['question'] as String? ?? '';
        // 1. Get or create the AI Analyst conversation
        final convRes = await client.post<Map<String, dynamic>>(
          '/messenger/ai-analyst',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        final convId = convRes['conversationId'] as String;
        // 2. Send the question as a user message via Socket.io
        sl<MessengerRemoteDataSource>().sendMessage(convId, question, origin: 'assistant');
        output = jsonEncode({
          'ok': true,
          'conversationId': convId,
          'message': 'Task sent to AI Analyst. The result will appear in the AI Analyst chat in Messages.',
        });
      } else if (name == 'get_analyst_result') {
        final res = await client.get<Map<String, dynamic>>(
          '/ai-analyst/latest',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        final text = res['text'] as String?;
        final createdAt = res['createdAt'] as String?;
        if (text != null && text.isNotEmpty) {
          output = jsonEncode({
            'ok': true,
            'result': text.length > 500 ? '${text.substring(0, 500)}...' : text,
            'createdAt': createdAt,
          });
        } else {
          output = jsonEncode({
            'ok': true,
            'result': null,
            'message': 'No analyst response yet. The task may still be processing.',
          });
        }
      } else if (name == 'get_balance') {
        try {
          final balance = await sl<BillingRepository>().getBalance();
          output = jsonEncode({
            'balanceMicroTal': balance.balanceMicroTal,
            'balancePlanck': balance.balancePlanck,
            'recentTxCount': balance.recentTx.length,
          });
        } catch (e) {
          output = jsonEncode({
            'error': 'failed_to_get_balance',
            'details': e.toString(),
          });
        }
      } else if (name == 'get_packages') {
        try {
          final packages = await sl<BillingRepository>().getPackages();
          final list = packages.map((p) {
            final highlights =
                p.highlights['ru'] ?? p.highlights['en'] ?? const <String>[];
            final label = p.label['ru'] ?? p.label['en'] ?? p.id;
            return {
              'id': p.id,
              'label': label,
              'priceEur': p.priceEurCents / 100.0,
              'highlights': highlights,
            };
          }).toList();
          output = jsonEncode(list);
        } catch (e) {
          output = jsonEncode({
            'error': 'failed_to_get_packages',
            'details': e.toString(),
          });
        }
      } else if (name == 'list_recent_transactions') {
        try {
          var limit = (args['limit'] as int?) ?? 10;
          if (limit < 1) limit = 1;
          if (limit > 50) limit = 50;
          final txs = await sl<BillingRepository>().getTransactions();
          final sliced = txs.take(limit).map((t) => {
                'type': t.type,
                'amountPlanck': t.amountPlanck,
                'featureKey': t.featureKey,
                'createdAt': t.createdAt,
              }).toList();
          output = jsonEncode(sliced);
        } catch (e) {
          output = jsonEncode({
            'error': 'failed_to_list_transactions',
            'details': e.toString(),
          });
        }
      } else if (name == 'toggle_feature') {
        try {
          final featureKey = args['featureKey'] as String?;
          final enabled = args['enabled'] as bool?;
          if (featureKey == null || enabled == null) {
            output = jsonEncode({
              'error': 'invalid_args',
              'details': 'featureKey and enabled are required',
            });
          } else {
            final toggle = await sl<BillingRepository>()
                .setToggle(featureKey, enabled);
            output = jsonEncode({
              'ok': true,
              'featureKey': toggle.featureKey,
              'enabled': toggle.enabled,
            });
          }
        } catch (e) {
          output = jsonEncode({
            'error': 'failed_to_toggle',
            'details': e.toString(),
          });
        }
      } else if (name == 'get_release_notes') {
        try {
          final requested = (args['version'] as String?)?.trim();
          final info = await sl<UpdateCheckService>().checkForUpdate();
          if (info == null) {
            output = jsonEncode({'error': 'version_endpoint_unreachable'});
          } else {
            final localeCode = hooks?.localeCode() ?? 'ru';
            final pick = (requested == null || requested.isEmpty)
                ? info.latestVersion
                : requested;
            ReleaseEntry? match;
            for (final r in info.releases) {
              if (r.version == pick) {
                match = r;
                break;
              }
            }
            output = jsonEncode({
              'currentVersion': info.currentVersion,
              'latestVersion': info.latestVersion,
              'updateAvailable': info.isAvailable,
              'requestedVersion': pick,
              'found': match != null,
              if (match != null) ...{
                'version': match.version,
                'date': match.date,
                'notes': match.notesFor(localeCode),
              },
              'recentVersions': info.releases
                  .take(5)
                  .map((r) => {
                        'version': r.version,
                        'date': r.date,
                      })
                  .toList(),
            });
          }
        } catch (e) {
          output = jsonEncode({
            'error': 'failed_to_get_release_notes',
            'details': e.toString(),
          });
        }
      } else if (name == 'agent_task') {
        final goal = args['goal'] as String? ?? '';
        if (goal.isEmpty) {
          output = jsonEncode({'error': 'goal is required'});
        } else {
          try {
            final h = hooks;
            final agent = sl<AgentClient>();
            final result = await agent.runAgent(
              goal: goal,
              conversationId: h?.getAgentConversationId(),
            );
            if (h != null) {
              h.setAgentConversationId(
                  result.conversationId ?? h.getAgentConversationId());
            }
            output = jsonEncode({
              'finalText': result.finalText,
              'aborted': result.aborted,
            });
          } catch (e) {
            debugPrint('[Assistant] agent_task error: $e');
            output = jsonEncode({'error': e.toString()});
          }
        }
      } else if (name == 'messenger_read_recent') {
        final filter = NotificationFilter(
          app: args['app'] as String?,
          sender: args['sender'] as String?,
          sinceMinutes: (args['since_minutes'] as num?)?.toInt() ?? 120,
          limit: (args['limit'] as num?)?.toInt() ?? 20,
        );
        final granted = await sl<NotificationPermissionService>().isGranted();
        if (!granted) {
          output = jsonEncode({
            'error': 'notification_access_not_granted',
            'hint': 'Скажи пользователю что нужно дать доступ к уведомлениям',
          });
        } else {
          final items = await sl<NotificationStore>().recent(filter);
          output = jsonEncode({
            'items': items.map((n) => n.toToolJson()).toList(),
          });
        }
      } else if (name == 'messenger_reply') {
        final key = args['notification_key'] as String? ?? '';
        final text = args['text'] as String? ?? '';
        if (key.isEmpty || text.isEmpty) {
          output = jsonEncode({
            'ok': false,
            'error': 'missing notification_key or text',
          });
        } else {
          try {
            await sl<NotificationStore>().replyOnKey(key, text);
            output = jsonEncode({'ok': true});
          } catch (e) {
            output = jsonEncode({'ok': false, 'error': e.toString()});
          }
        }
      } else if (name == 'check_mail') {
        final limit = ((args['limit'] as num?)?.toInt() ?? 5).clamp(1, 20);
        try {
          final data = await client.get<Map<String, dynamic>>(
            '/mail/messages',
            fromJson: (d) => Map<String, dynamic>.from(d as Map),
          );
          final items = (data['items'] as List? ?? [])
              .take(limit)
              .map((m) => {
                    'uid': m['uid'],
                    'from': m['from'],
                    'fromAddress': m['fromAddress'],
                    'subject': m['subject'],
                    'date': m['date'],
                    'seen': m['seen'],
                    'snippet': m['snippet'],
                  })
              .toList();
          output = jsonEncode({'emails': items, 'total_loaded': items.length});
        } catch (e) {
          output = jsonEncode({
            'error': (e is ApiException && e.statusCode == 404)
                ? 'no_mailbox_yet — suggest creating an address in Settings → Mail'
                : 'mail_unavailable',
          });
        }
      } else if (name == 'read_mail') {
        final uid = (args['uid'] as num?)?.toInt();
        if (uid == null) {
          output = jsonEncode({'error': 'uid_required'});
        } else {
          try {
            final data = await client.get<Map<String, dynamic>>(
              '/mail/messages/$uid',
              fromJson: (d) => Map<String, dynamic>.from(d as Map),
            );
            final fromText = data['from'] as String? ?? '';
            final addrMatch = RegExp(r'<([^>]+)>').firstMatch(fromText);
            output = jsonEncode({
              'from': data['from'],
              'fromAddress':
                  data['fromAddress'] ?? addrMatch?.group(1) ?? fromText,
              'to': data['to'],
              'subject': data['subject'],
              'date': data['date'],
              'text': (data['text'] as String? ?? '').length > 4000
                  ? (data['text'] as String).substring(0, 4000)
                  : data['text'],
              'attachments':
                  (data['attachments'] as List? ?? []).map((a) => a['filename']).toList(),
            });
          } catch (e) {
            output = jsonEncode({
              'error': (e is ApiException && e.statusCode == 404)
                  ? 'message_not_found'
                  : 'mail_unavailable',
            });
          }
        }
      } else if (name == 'send_mail') {
        var to = (args['to'] as String? ?? '').trim();
        var subject = args['subject'] as String? ?? '';
        final text = args['text'] as String? ?? '';
        String? inReplyTo;
        final replyToUid = (args['reply_to_uid'] as num?)?.toInt();
        if (replyToUid != null) {
          // Ответ на письмо: адресат/тема/threading берутся из оригинала,
          // а не из LLM — защита от «ответил сам себе».
          try {
            final orig = await client.get<Map<String, dynamic>>(
              '/mail/messages/$replyToUid',
              fromJson: (d) => Map<String, dynamic>.from(d as Map),
            );
            final fromText = orig['from'] as String? ?? '';
            final addr = orig['fromAddress'] as String? ??
                RegExp(r'<([^>]+)>').firstMatch(fromText)?.group(1) ??
                fromText;
            if (addr.trim().isNotEmpty) to = addr.trim();
            final origSubject = orig['subject'] as String? ?? '';
            if (subject.isEmpty) {
              subject = origSubject.startsWith('Re:')
                  ? origSubject
                  : 'Re: ' + origSubject;
            }
            inReplyTo = orig['messageId'] as String?;
          } catch (_) {}
        }
        if (to.isEmpty || text.isEmpty) {
          output = jsonEncode({'error': 'to_and_text_required'});
        } else {
          try {
            await client.post(
              '/mail/messages',
              data: {
                'to': to,
                'subject': subject,
                'text': text,
                if (inReplyTo != null) 'inReplyTo': inReplyTo,
              },
              fromJson: (d) => d,
            );
            output = jsonEncode({'ok': true, 'sent_to': to});
          } catch (e) {
            output = jsonEncode({
              'error': (e is ApiException && e.statusCode == 429)
                  ? 'daily_send_limit_reached'
                  : 'mail_send_failed',
            });
          }
        }
      } else if (name == 'create_mail_app_password') {
        final label = (args['label'] as String? ?? 'Mail client').trim();
        try {
          final data = await client.post<Map<String, dynamic>>(
            '/mail/app-passwords',
            data: {'label': label},
            fromJson: (d) => Map<String, dynamic>.from(d as Map),
          );
          // Пароль НЕ отдаём в LLM (не должен проговариваться вслух).
          output = jsonEncode({
            'ok': true,
            'label': data['label'],
            'note':
                'Password created. Tell the user to open Settings → Mail → App passwords to view it (it is NOT shown here for security).',
          });
        } catch (e) {
          output = jsonEncode({'error': 'mail_unavailable'});
        }
      } else {
        return 'Unknown tool: $name';
      }
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }
    return output;
  }
}
