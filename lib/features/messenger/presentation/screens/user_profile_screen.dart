import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import 'shared_media_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  // Contact status
  bool _isContact = false;
  String? _pendingRequest; // 'sent' | 'received' | null
  String? _requestId;
  bool _contactActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final client = sl<DioClient>();
    try {
      final results = await Future.wait([
        client.get('/profile/${widget.userId}', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
        client.get('/messenger/contacts/check/${widget.userId}', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          final cs = results[1] as Map<String, dynamic>;
          _isContact = cs['isContact'] as bool? ?? false;
          _pendingRequest = cs['pendingRequest'] as String?;
          _requestId = cs['requestId'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _sendContactRequest() async {
    setState(() => _contactActionLoading = true);
    try {
      final client = sl<DioClient>();
      await client.post(
        '/messenger/contacts/request',
        data: {'receiverId': widget.userId},
        fromJson: (d) => d,
      );
      if (mounted) setState(() { _pendingRequest = 'sent'; _contactActionLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  Future<void> _acceptContactRequest() async {
    if (_requestId == null) return;
    setState(() => _contactActionLoading = true);
    try {
      final client = sl<DioClient>();
      await client.patch(
        '/messenger/contacts/requests/$_requestId/accept',
        fromJson: (d) => d,
      );
      if (mounted) setState(() { _isContact = true; _pendingRequest = null; _requestId = null; _contactActionLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  Future<String?> _getOrCreateConversation() async {
    final bloc = context.read<MessengerBloc>();
    bloc.add(StartConversationWith(widget.userId));
    final state = await bloc.stream.firstWhere(
      (s) => s.newConversationId != null || (!s.isLoading && s.error != null),
    );
    if (!mounted) return null;
    final convId = state.newConversationId;
    if (convId != null) {
      bloc.add(ClearNewConversation());
    } else if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не удалось открыть чат'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
    }
    return convId;
  }

  Future<void> _openChat() async {
    final convId = await _getOrCreateConversation();
    if (convId != null && mounted) {
      context.push('/dashboard/messenger/$convId');
    }
  }

  Future<void> _startDirectCall() async {
    if (CallStateService.instance.isInCall) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Уже идёт звонок'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }

    final convId = await _getOrCreateConversation();
    if (convId == null || !mounted) return;

    try {
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/rooms',
        data: {'withAi': false, 'conversationId': convId},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      sl<MessengerRemoteDataSource>().sendCallInvite(convId, roomName);

      final firstName = _profile?['firstName'] as String? ?? '';
      final lastName = _profile?['lastName'] as String? ?? '';
      final calleeName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
      final calleeParam = calleeName.isNotEmpty
          ? '&callee=${Uri.encodeComponent(calleeName)}'
          : '';
      final avatarUrl = _profile?['avatarUrl'] as String?;
      final avatarParam = avatarUrl != null && avatarUrl.isNotEmpty
          ? '&calleeAvatar=${Uri.encodeComponent(avatarUrl)}'
          : '';
      if (mounted) {
        context.push('/dashboard/voice?room=$roomName&convId=$convId$calleeParam$avatarParam');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка звонка: $e'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _profile?['firstName'] as String? ?? '';
    final lastName = _profile?['lastName'] as String? ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final username = _profile?['username'] as String?;
    final avatarUrl = _profile?['avatarUrl'] as String?;
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : 'Профиль'),
        backgroundColor: AppColors.of(context).surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки профиля',
                          style: TextStyle(color: AppColors.of(context).textPrimary)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.2),
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Text(
                                    initials,
                                    style: TextStyle(
                                        color: AppColors.of(context).primary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Text(
                                initials,
                                style: TextStyle(
                                    color: AppColors.of(context).primary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),
                      if (fullName.isNotEmpty)
                        Text(
                          fullName,
                          style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      if (username != null && username.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '@$username',
                          style: TextStyle(
                              color: AppColors.of(context).textSecondary, fontSize: 15),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildActionButtons(colors),
                      const SizedBox(height: 24),
                      _buildSharedMediaButton(colors),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActionButtons(AppColorsExtension colors) {
    if (_contactActionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isContact) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black),
              label: const Text('Написать', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startDirectCall,
              icon: const Icon(Icons.call_outlined, color: Colors.black),
              label: const Text('Позвонить', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (_pendingRequest == 'sent') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.hourglass_empty_rounded, color: colors.textSecondary),
          label: Text('Запрос отправлен', style: TextStyle(color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (_pendingRequest == 'received') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acceptContactRequest,
              icon: const Icon(Icons.check_rounded, color: Colors.black),
              label: const Text('Принять', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              label: Text('Отклонить', style: TextStyle(color: colors.textSecondary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // No contact — show Add button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendContactRequest,
        icon: const Icon(Icons.person_add_outlined, color: Colors.black),
        label: const Text('Добавить в контакты', style: TextStyle(color: Colors.black)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSharedMediaButton(AppColorsExtension colors) {
    final convs = context.read<MessengerBloc>().state.conversations;
    final conv = convs.where((c) => c.type == 'DIRECT' && c.otherUserId == widget.userId).firstOrNull;
    if (conv == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SharedMediaScreen(conversationId: conv.id)),
        ),
        icon: Icon(Icons.perm_media_outlined, color: colors.textPrimary),
        label: Text('Медиа и файлы', style: TextStyle(color: colors.textPrimary)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
