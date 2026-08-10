/// JSON tool schemas for the OpenAI Realtime session (flat format:
/// `{'type': 'function', 'name': ..., 'description': ..., 'parameters': ...}`).
/// Moved verbatim from assistant_screen.dart.
List<Map<String, dynamic>> assistantToolSchemas({required bool translatorMode}) {
  if (translatorMode) {
    return [
        {
          'type': 'function',
          'name': 'exit_translator_mode',
          'description':
              'Exit translator mode. Call ONLY when you hear one of the exit phrases listed in your instructions. Never call otherwise.',
          'parameters': {'type': 'object', 'properties': {}},
        },
    ];
  }
  return [
          {
            'type': 'function',
            'name': 'enter_translator_mode',
            'description':
                'Enter live translator mode between two people speaking different languages. Call when user says "включи переводчика", "translator mode", "переводи нам", etc. If the user NAMES the languages ("с русского на китайский", "between English and German"), pass them as ISO 639-1 codes in lang_a/lang_b.',
            'parameters': {
              'type': 'object',
              'properties': {
                'lang_a': {
                  'type': 'string',
                  'description': 'ISO 639-1 code of the first language if the user named it (e.g. "ru")',
                },
                'lang_b': {
                  'type': 'string',
                  'description': 'ISO 639-1 code of the second language if the user named it (e.g. "zh")',
                },
              },
            },
          },
          {
            'type': 'function',
            'name': 'set_preferred_name',
            'description':
                'Remember how to address the user. Call when the user tells you their name or asks to be called differently ("называй меня Дима", "call me Alex").',
            'parameters': {
              'type': 'object',
              'properties': {
                'name': {
                  'type': 'string',
                  'description': 'The preferred form of address, exactly as the user said it',
                },
              },
              'required': ['name'],
            },
          },
          {
            'type': 'function',
            'name': 'end_session',
            'description':
                'End the assistant voice session and disconnect. Call this when the user says goodbye ("пока", "bye", "до свидания", "всё", "хватит", "конец", "stop", "quit").',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'web_search',
            'description':
                'Search the web for up-to-date information, news, facts, weather, sports, current events, prices, or anything requiring fresh data. Use this whenever the user asks about real-world information that may have changed recently.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {
                  'type': 'string',
                  'description': 'The search query in natural language',
                },
              },
              'required': ['query'],
            },
          },
          {
            'type': 'function',
            'name': 'agent_task',
            'description':
                'Run a complex task on the AI agent (Claude on analyst box). Use for: '
                'multi-step work that needs reasoning, code analysis, system administration commands, '
                'remote SSH/PM2/git operations, file reading on dev servers, deeper research. '
                'NOT for: quick weather/news lookups (use web_search), profile/messenger/calendar '
                '(use dedicated tools). Result is returned synchronously after ~10 seconds — '
                'tell the user briefly "Подождите, обдумываю" / "One moment, working on it" before calling.',
            'parameters': {
              'type': 'object',
              'properties': {
                'goal': {
                  'type': 'string',
                  'description':
                      'Clear, self-contained task description in natural language. Include all '
                      'context the agent needs — it has no memory of the current voice conversation.',
                },
              },
              'required': ['goal'],
            },
          },
          {
            'type': 'function',
            'name': 'messenger_read_recent',
            'description':
                'Read recent messenger notifications (WhatsApp, Telegram, SMS, Gmail, etc.) that arrived on this phone. '
                'Use when the user asks "что мне написали", "есть новые сообщения", "что в Telegram", "кто звонил/писал". '
                'Returns a slim list: sender, app, body, age. '
                'NOT for: searching old history — use the dedicated messenger tools (Phase 1B+). '
                'NOT for: Taler ID in-app conversations — use get_conversations / get_messages.',
            'parameters': {
              'type': 'object',
              'properties': {
                'app': {
                  'type': 'string',
                  'description': 'Optional substring of the app package name, e.g. "whatsapp", "telegram", "gmail"',
                },
                'sender': {
                  'type': 'string',
                  'description': 'Optional substring of sender/conversation title',
                },
                'since_minutes': {
                  'type': 'integer',
                  'description': 'Only notifications newer than N minutes (default 120, max 1440)',
                },
                'limit': {
                  'type': 'integer',
                  'description': 'Max items to return (default 20, max 50)',
                },
              },
            },
          },
          {
            'type': 'function',
            'name': 'messenger_reply',
            'description':
                'Send an inline reply to a specific notification you got from messenger_read_recent. '
                'Use only when the user explicitly asks to reply, e.g. "ответь Маше что буду через 20 минут", "напиши в WhatsApp Олегу что согласен". '
                'The notification_key must come from a recent messenger_read_recent call. '
                'Returns ok or an error if the notification no longer has an active reply action.',
            'parameters': {
              'type': 'object',
              'properties': {
                'notification_key': {
                  'type': 'string',
                  'description': 'The key field from messenger_read_recent',
                },
                'text': {
                  'type': 'string',
                  'description': 'The reply text. Plain text only, no markdown.',
                },
              },
              'required': ['notification_key', 'text'],
            },
          },
          {
            'type': 'function',
            'name': 'get_profile',
            'description':
                'Get current user profile: firstName, lastName, email, username, phone',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'update_profile',
            'description': 'Update user profile fields (firstName, lastName, phone)',
            'parameters': {
              'type': 'object',
              'properties': {
                'firstName': {'type': 'string'},
                'lastName': {'type': 'string'},
                'phone': {'type': 'string'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'get_sections',
            'description':
                'Get all profile sections of the current user. Returns array of sections with type, content (items + freeText), and visibility.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'upsert_section',
            'description':
                'Create or update a profile section. Merge new items with existing ones. '
                'Types: VALUES, WORLDVIEW, SKILLS, INTERESTS, DESIRES, BACKGROUND, LIKES, DISLIKES.',
            'parameters': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['VALUES', 'WORLDVIEW', 'SKILLS', 'INTERESTS', 'DESIRES', 'BACKGROUND', 'LIKES', 'DISLIKES'],
                },
                'items': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
                'freeText': {'type': 'string'},
                'visibility': {
                  'type': 'string',
                  'enum': ['PUBLIC', 'CONTACTS', 'PRIVATE'],
                },
              },
              'required': ['type'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_section',
            'description': 'Delete a profile section.',
            'parameters': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['VALUES', 'WORLDVIEW', 'SKILLS', 'INTERESTS', 'DESIRES', 'BACKGROUND', 'LIKES', 'DISLIKES'],
                },
              },
              'required': ['type'],
            },
          },
          {
            'type': 'function',
            'name': 'search_contacts',
            'description': 'Search for users/contacts by name, username, email or phone. Min 2 chars.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string', 'description': 'Search query (min 2 chars)'},
              },
              'required': ['query'],
            },
          },
          {
            'type': 'function',
            'name': 'get_conversations',
            'description': 'Get list of user conversations/chats with contact names, IDs, unreadCount and last message info.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'get_messages',
            'description': 'Get message history for a conversation. Use to analyze past discussions, meetings, agreements.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'limit': {'type': 'integer', 'description': 'Number of messages to fetch (default 50)'},
              },
              'required': ['conversationId'],
            },
          },
          {
            'type': 'function',
            'name': 'start_call',
            'description': 'Start a voice call to a contact. Creates a room, sends invite, and navigates to call screen.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'calleeName': {'type': 'string'},
              },
              'required': ['conversationId'],
            },
          },
          {
            'type': 'function',
            'name': 'send_message',
            'description':
                'Send a text message to a conversation. Pass replyToId to answer a specific message — that draws a real quote block in the chat, which plain text cannot do.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'content': {'type': 'string', 'description': 'Message text to send'},
                'replyToId': {
                  'type': 'string',
                  'description':
                      'Optional id of the message being answered. Use when the user says "ответь на это сообщение", "reply to that", or answers a specific question in a busy chat.',
                },
              },
              'required': ['conversationId', 'content'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_last_own_message',
            'description': 'Delete the user\'s last sent text message in a conversation (for everyone). Use when the user asks to delete/undo/cancel the message they just sent.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
              },
              'required': ['conversationId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_notes',
            'description': 'Get all user notes. Returns list with id, title, content, source, createdAt.',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {'type': 'integer', 'description': 'Max notes to return (default 20)'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'create_note',
            'description': 'Save a note/thought for the user. Use when user shares an idea or asks to save something.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Short title or main thought'},
                'content': {'type': 'string', 'description': 'Detailed content'},
              },
              'required': ['title', 'content'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_note',
            'description': 'Delete a note by ID.',
            'parameters': {
              'type': 'object',
              'properties': {
                'noteId': {'type': 'string'},
              },
              'required': ['noteId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_events',
            'description': 'Get calendar events for a date range. Returns events with id, title, type, startAt, reminderAt.',
            'parameters': {
              'type': 'object',
              'properties': {
                'from': {'type': 'string', 'description': 'Start date ISO string (default: today)'},
                'to': {'type': 'string', 'description': 'End date ISO string (default: 30 days from now)'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'create_event',
            'description': 'Create a calendar event, reminder, or scheduled call.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string'},
                'description': {'type': 'string'},
                'type': {'type': 'string', 'enum': ['CALL', 'EVENT', 'REMINDER']},
                'startAt': {'type': 'string', 'description': 'ISO datetime'},
                'endAt': {'type': 'string', 'description': 'ISO datetime (optional)'},
                'reminderAt': {'type': 'string', 'description': 'When to send push reminder (ISO datetime)'},
              },
              'required': ['title', 'type', 'startAt'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_event',
            'description': 'Delete a calendar event by ID.',
            'parameters': {
              'type': 'object',
              'properties': {
                'eventId': {'type': 'string'},
              },
              'required': ['eventId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_contacts',
            'description': 'Get list of accepted contacts (people the user has added). Returns name, userId, conversationId.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'send_contact_request',
            'description': 'Send a contact request to a user by userId (find userId via search_contacts first).',
            'parameters': {
              'type': 'object',
              'properties': {
                'userId': {'type': 'string', 'description': 'Target user ID'},
              },
              'required': ['userId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_contact_requests',
            'description': 'Get incoming pending contact requests from other users.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'respond_contact_request',
            'description': 'Accept or reject an incoming contact request.',
            'parameters': {
              'type': 'object',
              'properties': {
                'requestId': {'type': 'string'},
                'action': {'type': 'string', 'enum': ['accept', 'reject']},
              },
              'required': ['requestId', 'action'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_contact',
            'description': 'Remove a contact by userId.',
            'parameters': {
              'type': 'object',
              'properties': {
                'userId': {'type': 'string'},
              },
              'required': ['userId'],
            },
          },
          {
            'type': 'function',
            'name': 'block_contact',
            'description': 'Block or unblock a user by userId.',
            'parameters': {
              'type': 'object',
              'properties': {
                'userId': {'type': 'string'},
                'action': {'type': 'string', 'enum': ['block', 'unblock']},
              },
              'required': ['userId', 'action'],
            },
          },
          {
            'type': 'function',
            'name': 'get_call_history',
            'description': 'Get recent call history (incoming and outgoing calls) with duration, status, caller/callee names.',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {'type': 'integer', 'description': 'Number of calls to return (default 20)'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'get_sessions',
            'description': 'Get list of active user sessions (devices logged in). Returns device, IP, last activity.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'terminate_session',
            'description': 'Terminate (logout) a specific session by sessionId.',
            'parameters': {
              'type': 'object',
              'properties': {
                'sessionId': {'type': 'string'},
              },
              'required': ['sessionId'],
            },
          },
          {
            'type': 'function',
            'name': 'create_group',
            'description': 'Create a new group chat with specified members.',
            'parameters': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string', 'description': 'Group name'},
                'memberIds': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Array of userIds to add to the group',
                },
              },
              'required': ['name', 'memberIds'],
            },
          },
          {
            'type': 'function',
            'name': 'manage_group_members',
            'description': 'Add or remove a member from a group conversation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'userId': {'type': 'string'},
                'action': {'type': 'string', 'enum': ['add', 'remove']},
              },
              'required': ['conversationId', 'userId', 'action'],
            },
          },
          {
            'type': 'function',
            'name': 'get_tenants',
            'description': 'Get list of organizations/tenants the user belongs to.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'get_kyc_status',
            'description': 'Get current KYC (identity verification) status of the user.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'react_to_message',
            'description': 'Add an emoji reaction to a message in a conversation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'messageId': {'type': 'string'},
                'emoji': {'type': 'string', 'description': 'Emoji character, e.g. 👍 ❤️ 😂'},
              },
              'required': ['conversationId', 'messageId', 'emoji'],
            },
          },
          {
            'type': 'function',
            'name': 'forward_message',
            'description':
                'Forward one or more existing messages to another conversation, keeping the "Forwarded from X" attribution. Pass the ids of the original messages — the server copies their bodies itself. Use for "перешли это Ане", "forward those two messages to the group".',
            'parameters': {
              'type': 'object',
              'properties': {
                'targetConversationId': {'type': 'string', 'description': 'Destination conversation ID'},
                'messageIds': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Ids of the messages to forward, in the order they should appear',
                },
              },
              'required': ['targetConversationId', 'messageIds'],
            },
          },
          {
            'type': 'function',
            'name': 'pin_message',
            'description':
                'Pin a message in a conversation so it stays highlighted at the top for everyone in the chat (Telegram-style). Use when the user asks to pin a message, mark it important, or keep something easy to find later (an address, a time, a link) — e.g. "закрепи это сообщение", "pin that message", "закрепи адрес встречи".',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'messageId': {'type': 'string'},
              },
              'required': ['conversationId', 'messageId'],
            },
          },
          {
            'type': 'function',
            'name': 'unpin_message',
            'description':
                'Unpin a previously pinned message in a conversation. Use when the user asks to unpin a message or stop keeping it highlighted at the top of the chat — e.g. "открепи это сообщение", "unpin that message".',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'messageId': {'type': 'string'},
              },
              'required': ['conversationId', 'messageId'],
            },
          },
          {
            'type': 'function',
            'name': 'list_pinned',
            'description':
                'Get the messages currently pinned in a conversation. Use when the user asks what is pinned, wants to see the pinned messages, or refers back to something that was pinned earlier — e.g. "что закреплено в этом чате", "what\'s pinned here", "покажи закреплённые сообщения".',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
              },
              'required': ['conversationId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_settings',
            'description': 'Get current app settings: theme (light/dark/system), language (ru/en), biometric enabled, PIN enabled.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'set_theme',
            'description': 'Change the app theme.',
            'parameters': {
              'type': 'object',
              'properties': {
                'theme': {'type': 'string', 'enum': ['light', 'dark', 'system']},
              },
              'required': ['theme'],
            },
          },
          {
            'type': 'function',
            'name': 'set_language',
            'description': 'Change the app language.',
            'parameters': {
              'type': 'object',
              'properties': {
                'language': {'type': 'string', 'enum': ['ru', 'en']},
              },
              'required': ['language'],
            },
          },
          {
            'type': 'function',
            'name': 'set_biometric',
            'description': 'Enable or disable biometric authentication (fingerprint/Face ID). Disabling does not require authentication.',
            'parameters': {
              'type': 'object',
              'properties': {
                'enabled': {'type': 'boolean'},
              },
              'required': ['enabled'],
            },
          },
          // disable_pin was removed: it dropped the device lock with no
          // re-authentication, and this model also reads third-party content
          // (messages, mail), so the call was reachable by prompt injection.
          // Turning the PIN off now happens in Settings, like turning it on.
          {
            'type': 'function',
            'name': 'ask_analyst',
            'description':
                'Send a task or question to the AI Analyst (Claude) for deep analysis. '
                'Use this for complex tasks: document analysis, code review, research, '
                'data processing, file generation. The result will appear in the AI Analyst '
                'chat in Messages. Tell the user you sent the task and they can check '
                'the result in the AI Analyst chat.',
            'parameters': {
              'type': 'object',
              'properties': {
                'question': {
                  'type': 'string',
                  'description': 'The task or question for the AI Analyst',
                },
              },
              'required': ['question'],
            },
          },
          {
            'type': 'function',
            'name': 'get_analyst_result',
            'description':
                'Get the latest response from the AI Analyst. Use this when the user '
                'asks what the analyst said, or to check if a previously submitted '
                'task has been completed.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'get_balance',
            'description':
                'Получить текущий баланс TAL-кошелька пользователя в μTAL',
            'parameters': {
              'type': 'object',
              'properties': <String, dynamic>{},
              'required': <String>[],
            },
          },
          {
            'type': 'function',
            'name': 'get_packages',
            'description':
                'Получить список доступных пакетов для пополнения баланса',
            'parameters': {
              'type': 'object',
              'properties': <String, dynamic>{},
              'required': <String>[],
            },
          },
          {
            'type': 'function',
            'name': 'list_recent_transactions',
            'description':
                'Получить последние операции по балансу пользователя',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {
                  'type': 'integer',
                  'description':
                      'Количество операций (по умолчанию 10, максимум 50)',
                },
              },
              'required': <String>[],
            },
          },
          {
            'type': 'function',
            'name': 'toggle_feature',
            'description':
                'Включить или выключить AI-функцию. Допустимые значения featureKey: voice_assistant, web_search, ai_twin, outbound_call, whisper_transcribe, meeting_summary',
            'parameters': {
              'type': 'object',
              'properties': {
                'featureKey': {
                  'type': 'string',
                  'enum': [
                    'voice_assistant',
                    'web_search',
                    'ai_twin',
                    'outbound_call',
                    'whisper_transcribe',
                    'meeting_summary',
                  ],
                },
                'enabled': {'type': 'boolean'},
              },
              'required': ['featureKey', 'enabled'],
            },
          },
          {
            'type': 'function',
            'name': 'get_release_notes',
            'description':
                'Получить changelog ("что нового") приложения Taler ID. Без аргументов — возвращает самую свежую версию и её release notes. С version — конкретную версию. Используй при запросах вроде "что нового", "what is new", "последняя версия", "какие изменения в обновлении", "доступно ли обновление".',
            'parameters': {
              'type': 'object',
              'properties': {
                'version': {
                  'type': 'string',
                  'description': 'Optional version like "1.0.72". Omit for the latest.',
                },
              },
            },
          },
          {
            'type': 'function',
            'name': 'check_mail',
            'description':
                'Check the user\'s @talerid.io mailbox: returns the latest inbox emails (from, subject, date, seen, uid). Call when user asks "проверь почту", "есть новые письма?", "check my mail".',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {
                  'type': 'integer',
                  'description': 'How many latest emails to return (default 5, max 20)',
                },
              },
            },
          },
          {
            'type': 'function',
            'name': 'read_mail',
            'description':
                'Read one email by uid (from check_mail). Returns full text body. Call when user asks to read/open a specific email.',
            'parameters': {
              'type': 'object',
              'properties': {
                'uid': {'type': 'integer', 'description': 'Email uid from check_mail'},
              },
              'required': ['uid'],
            },
          },
          {
            'type': 'function',
            'name': 'send_mail',
            'description':
                'Send an email from the user\'s @talerid.io address. ALWAYS confirm recipient, subject and text with the user out loud BEFORE calling this tool. When REPLYING to an email, pass reply_to_uid (the uid from check_mail/read_mail) — the recipient, subject and threading are then derived from the original message automatically; NEVER send a reply to the user\'s own address.',
            'parameters': {
              'type': 'object',
              'properties': {
                'to': {
                  'type': 'string',
                  'description':
                      'Recipient email address. Omit when reply_to_uid is set.'
                },
                'subject': {'type': 'string', 'description': 'Email subject'},
                'text': {'type': 'string', 'description': 'Email body (plain text)'},
                'reply_to_uid': {
                  'type': 'integer',
                  'description':
                      'uid of the email being replied to; sets recipient/subject/threading from the original.'
                },
              },
              'required': ['text'],
            },
          },
          {
            'type': 'function',
            'name': 'create_mail_app_password',
            'description':
                'Create an app password for connecting external mail clients (Apple Mail, Gmail app). The password value is NOT returned to you — tell the user to check the App Passwords screen in Settings. Just pass a label like "iPhone Apple Mail".',
            'parameters': {
              'type': 'object',
              'properties': {
                'label': {'type': 'string', 'description': 'Device/client label'},
              },
              'required': ['label'],
            },
          },
  ];
}

/// Same tools in OpenAI chat-completions format (nested under 'function').
List<Map<String, dynamic>> assistantToolSchemasForCompletions() =>
    assistantToolSchemas(translatorMode: false)
        .map((t) => {
              'type': 'function',
              'function': {
                'name': t['name'],
                'description': t['description'],
                if (t['parameters'] != null) 'parameters': t['parameters'],
              },
            })
        .toList();
