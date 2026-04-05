import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart' show rainbowColorFor;
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  // Contact status
  bool _isContact = false;
  String? _pendingRequest; // 'sent' | 'received' | null
  String? _requestId;
  bool _contactActionLoading = false;
  bool _isBlocked = false;    // they blocked me
  bool _iBlockedThem = false; // I blocked them

  // Conversation for shared media
  String? _conversationId;

  // Custom alias for this contact
  String? _customName;

  // Shared media tab controller
  late TabController _mediaTabCtrl;

  @override
  void initState() {
    super.initState();
    _mediaTabCtrl = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _mediaTabCtrl.dispose();
    super.dispose();
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
          _profile = results[0];
          final cs = results[1];
          _isContact = cs['isContact'] as bool? ?? false;
          _pendingRequest = cs['pendingRequest'] as String?;
          _requestId = cs['requestId'] as String?;
          _isBlocked = cs['isBlocked'] as bool? ?? false;
          _iBlockedThem = cs['iBlockedThem'] as bool? ?? false;
          _loading = false;
        });
        _findConversation();
        _loadAlias();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadAlias() async {
    try {
      final aliases = await sl<DioClient>().get<dynamic>('/messenger/contacts/aliases');
      final list = (aliases as List?) ?? [];
      for (final a in list) {
        final alias = Map<String, dynamic>.from(a as Map);
        if (alias['targetId'] == widget.userId) {
          if (mounted) setState(() => _customName = alias['customName'] as String?);
          break;
        }
      }
    } catch (_) {}
  }

  void _editAlias(String originalName) {
    // Navigate to a separate screen to avoid dialog/context issues
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditAliasScreen(
          userId: widget.userId,
          currentAlias: _customName,
          originalName: originalName,
        ),
      ),
    ).then((changed) {
      if (changed == true && mounted) {
        _loadAll();
        try { context.read<MessengerBloc>().add(LoadConversations()); } catch (_) {}
      }
    });
  }

  void _findConversation() {
    try {
      final convs = context.read<MessengerBloc>().state.conversations;
      final conv = convs.where((c) => c.type == 'DIRECT' && c.otherUserId == widget.userId).firstOrNull;
      if (conv != null && mounted) {
        setState(() => _conversationId = conv.id);
      }
    } catch (_) {}
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  Future<void> _acceptContactRequest() async {
    if (_requestId == null || _contactActionLoading) return;
    final reqId = _requestId!;
    setState(() {
      _contactActionLoading = true;
      _isContact = true;
      _pendingRequest = null;
      _requestId = null;
    });
    // Delegate to the bloc so the global messenger state (chats list) updates
    // immediately; bloc calls the API, drops the row, reloads conversations.
    context.read<MessengerBloc>().add(AcceptContactRequest(reqId));
    if (mounted) setState(() => _contactActionLoading = false);
  }

  Future<void> _declineContactRequest() async {
    if (_requestId == null || _contactActionLoading) return;
    final reqId = _requestId!;
    setState(() {
      _contactActionLoading = true;
      _pendingRequest = null;
      _requestId = null;
    });
    context.read<MessengerBloc>().add(RejectContactRequest(reqId));
    if (mounted) setState(() => _contactActionLoading = false);
  }

  Future<String?> _getOrCreateConversation() async {
    // If we already know the conversation ID, return it
    if (_conversationId != null) return _conversationId;
    try {
      final ds = sl<MessengerRemoteDataSource>();
      final conv = await ds.createConversation(widget.userId);
      if (mounted) {
        setState(() => _conversationId = conv.id);
        context.read<MessengerBloc>().add(LoadConversations());
      }
      return conv.id;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userProfileFailedOpenChat),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _openChat() async {
    final convId = await _getOrCreateConversation();
    if (convId != null && mounted) {
      context.push('/dashboard/messenger/$convId');
    }
  }

  Future<void> _startDirectCall() async {
    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatAlreadyInCall),
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
            content: Text(AppLocalizations.of(context)!.chatCallError(e.toString())),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  void _shareContact() {
    final firstName = _profile?['firstName'] as String? ?? '';
    final lastName = _profile?['lastName'] as String? ?? '';
    final username = _profile?['username'] as String?;
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.share_rounded, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.userProfileShareContact, style: TextStyle(color: AppColors.of(context).textPrimary)),
              subtitle: Text(AppLocalizations.of(context)!.userProfileShareContactDesc, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                final shareText = username != null
                    ? '${AppLocalizations.of(context)!.messengerShareContact(fullName)} (@$username)\nhttps://id.taler.tirol/u/$username'
                    : AppLocalizations.of(context)!.messengerShareContact(fullName);
                Share.share(shareText);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.userProfileCopyLink, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                final link = username != null
                    ? 'https://id.taler.tirol/u/$username'
                    : fullName;
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.userProfileCopied), duration: const Duration(seconds: 1)),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<MessengerBloc, MessengerState>(
      listenWhen: (prev, cur) =>
          prev.contactRequests.length != cur.contactRequests.length ||
          prev.conversations.length != cur.conversations.length ||
          prev.sentContactRequests.length != cur.sentContactRequests.length ||
          prev.contactRequestSent != cur.contactRequestSent,
      listener: (_, __) => _loadAll(),
      child: Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(_customName ?? (fullName.isNotEmpty ? fullName : l10n.userProfileTitle)),
        backgroundColor: AppColors.of(context).surface,
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareContact,
            ),
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showMoreMenu,
            ),
        ],
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
                      Text(l10n.userProfileLoadError,
                          style: TextStyle(color: AppColors.of(context).textPrimary)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: () {
                        final ringColor = rainbowColorFor(
                          fullName.isNotEmpty
                              ? fullName
                              : (username ?? widget.userId),
                        );
                        return Container(
                          width: 124,
                          height: 124,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: ringColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: ringColor.withValues(alpha: 0.5),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.3, -0.4),
                                radius: 1.1,
                                colors: [
                                  Color.lerp(ringColor, Colors.white, 0.3)!,
                                  ringColor,
                                  Color.lerp(ringColor, Colors.black, 0.4)!,
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                            ),
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        );
                      }(),
                    ),
                    const SizedBox(height: 20),
                    if (fullName.isNotEmpty)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _customName ?? fullName,
                                style: TextStyle(
                                    color: AppColors.of(context).textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _editAlias(fullName),
                              child: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                    if (username != null && username.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '@$username',
                          style: TextStyle(
                              color: AppColors.of(context).textSecondary, fontSize: 15),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildActionButtons(colors),
                    const SizedBox(height: 24),
                    // Inline shared media with tabs
                    if (_conversationId != null)
                      _InlineSharedMedia(conversationId: _conversationId!, tabController: _mediaTabCtrl),
                  ],
                ),
      ),
    );
  }

  Future<void> _deleteContact() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(l10n.contactDeleteTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.contactDeleteConfirm, style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.contactDelete, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      setState(() => _contactActionLoading = true);
      await sl<DioClient>().delete('/messenger/contacts/${widget.userId}');
      if (mounted) {
        setState(() { _isContact = false; _pendingRequest = null; _requestId = null; _contactActionLoading = false; });
        try { context.read<MessengerBloc>().add(LoadConversations()); } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.of(context).error));
      }
    }
  }

  Future<void> _blockUser() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(l10n.contactBlockTitle, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.contactBlockConfirm, style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.contactBlock, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      setState(() => _contactActionLoading = true);
      await sl<DioClient>().post('/messenger/contacts/${widget.userId}/block');
      if (mounted) {
        setState(() { _isContact = false; _pendingRequest = null; _requestId = null; _iBlockedThem = true; _contactActionLoading = false; });
        try { context.read<MessengerBloc>().add(LoadConversations()); } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.of(context).error));
      }
    }
  }

  Future<void> _unblockUser() async {
    try {
      setState(() => _contactActionLoading = true);
      await sl<DioClient>().delete('/messenger/contacts/${widget.userId}/block');
      if (mounted) {
        await _loadAll();
        setState(() => _contactActionLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.of(context).error));
      }
    }
  }

  Future<void> _revokeRequest() async {
    if (_requestId == null) return;
    try {
      setState(() => _contactActionLoading = true);
      await sl<DioClient>().patch('/messenger/contacts/requests/$_requestId/reject');
      if (mounted) setState(() { _pendingRequest = null; _requestId = null; _contactActionLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.of(context).error));
      }
    }
  }

  void _showMoreMenu() {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isContact)
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: colors.error),
                title: Text(l10n.contactDelete, style: TextStyle(color: colors.error)),
                onTap: () { Navigator.pop(ctx); _deleteContact(); },
              ),
            if (_pendingRequest == 'sent' && _requestId != null)
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: colors.textSecondary),
                title: Text(l10n.contactRevokeRequest, style: TextStyle(color: colors.textSecondary)),
                onTap: () { Navigator.pop(ctx); _revokeRequest(); },
              ),
            if (_iBlockedThem)
              ListTile(
                leading: Icon(Icons.lock_open_outlined, color: colors.primary),
                title: Text(l10n.contactUnblock, style: TextStyle(color: colors.primary)),
                onTap: () { Navigator.pop(ctx); _unblockUser(); },
              )
            else
              ListTile(
                leading: Icon(Icons.block_rounded, color: colors.error),
                title: Text(l10n.contactBlock, style: TextStyle(color: colors.error)),
                onTap: () { Navigator.pop(ctx); _blockUser(); },
              ),
          ],
        ),
      ),
    );
  }

  /// Full-width gradient action button with icon + label and a colored
  /// glow drop-shadow.
  Widget _gradientActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    if (_contactActionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_iBlockedThem) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.block_rounded, color: colors.error, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(AppLocalizations.of(context)!.contactBlocked, style: TextStyle(color: colors.error, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _unblockUser,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(AppLocalizations.of(context)!.contactUnblock, style: TextStyle(color: colors.primary, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_isBlocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, color: colors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.contactYouAreBlocked, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    if (_isContact) {
      return Row(
        children: [
          Expanded(
            child: _gradientActionButton(
              onTap: _openChat,
              icon: Icons.chat_bubble_rounded,
              label: l10n.userProfileMessage,
              gradient: const [Color(0xFF22D3EE), Color(0xFF3B82F6)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _gradientActionButton(
              onTap: _startDirectCall,
              icon: Icons.call_rounded,
              label: l10n.userProfileCall,
              gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
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
          label: Text(l10n.userProfileRequestSent, style: TextStyle(color: colors.textSecondary)),
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
            child: _gradientActionButton(
              onTap: _acceptContactRequest,
              icon: Icons.check_rounded,
              label: l10n.userProfileAccept,
              gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _contactActionLoading ? null : _declineContactRequest,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              label: Text(l10n.userProfileDecline, style: TextStyle(color: colors.textSecondary)),
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
    return _gradientActionButton(
      onTap: _sendContactRequest,
      icon: Icons.person_add_rounded,
      label: l10n.userProfileAddToContacts,
      gradient: const [Color(0xFF22D3EE), Color(0xFFA855F7)],
    );
  }
}

/// Inline shared media widget with tabs: Медиа / Файлы / Ссылки / Записи / Резюме
class _InlineSharedMedia extends StatefulWidget {
  final String conversationId;
  final TabController tabController;

  const _InlineSharedMedia({required this.conversationId, required this.tabController});

  @override
  State<_InlineSharedMedia> createState() => _InlineSharedMediaState();
}

class _InlineSharedMediaState extends State<_InlineSharedMedia> {
  final _mediaItems = <_MediaItem>[];
  final _docItems = <_MediaItem>[];
  final _linkItems = <_MediaItem>[];
  final _recordings = <Map<String, dynamic>>[];
  final _summaries = <Map<String, dynamic>>[];
  bool _mediaLoading = true;
  bool _docsLoading = true;
  bool _linksLoading = true;
  bool _callsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final client = sl<DioClient>();
    final convId = widget.conversationId;
    try {
      final results = await Future.wait([
        client.get('/messenger/conversations/$convId/media?type=media', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
        client.get('/messenger/conversations/$convId/media?type=documents', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
        client.get('/messenger/conversations/$convId/media?type=links', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
      ]);
      if (mounted) {
        setState(() {
          _mediaItems.addAll((results[0]['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)));
          _docItems.addAll((results[1]['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)));
          _linkItems.addAll((results[2]['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)));
          _mediaLoading = false;
          _docsLoading = false;
          _linksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _mediaLoading = false; _docsLoading = false; _linksLoading = false; });
    }
    // Load call history for this conversation
    _loadCallHistory(client, convId);
  }

  Future<void> _loadCallHistory(DioClient client, String convId) async {
    try {
      final data = await client.get<dynamic>(
        '/voice/call-history',
        queryParameters: {'page': 0, 'limit': 100},
      );
      final items = (data as List?) ?? [];
      if (mounted) {
        final calls = items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((c) => c['conversationId'] == convId)
            .toList();
        final recs = <Map<String, dynamic>>[];
        final sums = <Map<String, dynamic>>[];
        for (final c in calls) {
          final summary = c['meetingSummary'] as Map<String, dynamic>?;
          if (summary != null) {
            final recordingUrl = summary['recordingUrl'] as String?;
            if (recordingUrl != null && recordingUrl.isNotEmpty) {
              recs.add({...c, 'recordingUrl': recordingUrl});
            }
            final summaryText = summary['summary'] as String?;
            if (summaryText != null && summaryText.isNotEmpty) {
              sums.add({...c, 'summaryText': summaryText});
            }
          }
        }
        setState(() {
          _recordings.addAll(recs);
          _summaries.addAll(sums);
          _callsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _callsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasContent = _mediaItems.isNotEmpty || _docItems.isNotEmpty ||
        _linkItems.isNotEmpty || _recordings.isNotEmpty || _summaries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: widget.tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: '${l10n.userProfileMediaTab}${_mediaLoading ? '' : ' (${_mediaItems.length})'}'),
            Tab(text: '${l10n.userProfileFilesTab}${_docsLoading ? '' : ' (${_docItems.length})'}'),
            Tab(text: '${l10n.userProfileLinksTab}${_linksLoading ? '' : ' (${_linkItems.length})'}'),
            Tab(text: '${l10n.userProfileRecordingsTab}${_callsLoading ? '' : ' (${_recordings.length})'}'),
            Tab(text: '${l10n.userProfileSummariesTab}${_callsLoading ? '' : ' (${_summaries.length})'}'),
          ],
        ),
        SizedBox(
          height: !hasContent && !_mediaLoading ? 80 : 260,
          child: TabBarView(
            controller: widget.tabController,
            children: [
              _buildMediaGrid(colors),
              _buildDocsList(colors),
              _buildLinksList(colors),
              _buildRecordingsList(colors),
              _buildSummariesList(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid(AppColorsExtension colors) {
    if (_mediaLoading) return const Center(child: CircularProgressIndicator());
    if (_mediaItems.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoMedia, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final item = _mediaItems[index];
        final thumb = item.thumbnailMediumUrl ?? item.thumbnailSmallUrl ?? item.fileUrl;
        if (thumb == null) return const SizedBox();
        return GestureDetector(
          onTap: () {
            if (item.fileUrl != null) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _FullScreenMediaView(item: item),
              ));
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Widget _buildDocsList(AppColorsExtension colors) {
    if (_docsLoading) return const Center(child: CircularProgressIndicator());
    if (_docItems.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoFiles, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _docItems.length,
      itemBuilder: (context, index) {
        final item = _docItems[index];
        final ext = item.fileName?.split('.').last.toUpperCase() ?? 'FILE';
        return ListTile(
          dense: true,
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(ext.length > 4 ? ext.substring(0, 4) : ext,
                  style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          title: Text(item.fileName ?? AppLocalizations.of(context)!.messengerDefaultFile,
              style: TextStyle(color: colors.textPrimary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }

  Widget _buildLinksList(AppColorsExtension colors) {
    if (_linksLoading) return const Center(child: CircularProgressIndicator());
    if (_linkItems.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoLinks, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _linkItems.length,
      itemBuilder: (context, index) {
        final item = _linkItems[index];
        final url = _extractUrl(item.content ?? '');
        return ListTile(
          dense: true,
          leading: Icon(Icons.link, color: colors.primary, size: 20),
          title: Text(url ?? item.content ?? '',
              style: TextStyle(color: colors.primary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }

  Widget _buildRecordingsList(AppColorsExtension colors) {
    if (_callsLoading) return const Center(child: CircularProgressIndicator());
    if (_recordings.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoRecordings, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final rec = _recordings[index];
        final createdAt = rec['startedAt'] as String?;
        final date = createdAt != null ? DateTime.tryParse(createdAt) : null;
        final dateStr = date != null ? DateFormat('dd.MM.yy HH:mm').format(date.toLocal()) : '';
        final url = rec['recordingUrl'] as String?;
        return _RecordingTile(
          dateStr: dateStr,
          recordingUrl: url ?? '',
          colors: colors,
        );
      },
    );
  }

  Widget _buildSummariesList(AppColorsExtension colors) {
    if (_callsLoading) return const Center(child: CircularProgressIndicator());
    if (_summaries.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoSummaries, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _summaries.length,
      itemBuilder: (context, index) {
        final sum = _summaries[index];
        final text = sum['summaryText'] as String? ?? '';
        final createdAt = sum['startedAt'] as String?;
        final date = createdAt != null ? DateTime.tryParse(createdAt) : null;
        final dateStr = date != null ? DateFormat('dd.MM.yy HH:mm').format(date.toLocal()) : '';
        return ListTile(
          dense: true,
          leading: Icon(Icons.summarize_rounded, color: colors.primary, size: 20),
          title: Text(
            text.length > 60 ? '${text.substring(0, 60)}...' : text,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: dateStr.isNotEmpty ? Text(dateStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)) : null,
          onTap: () => _showSummaryDetail(context, text, dateStr),
        );
      },
    );
  }

  void _showSummaryDetail(BuildContext context, String text, String dateStr) {
    final colors = AppColors.of(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Text('${AppLocalizations.of(context)!.userProfileMeetingSummary}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
            style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.userProfileCopied), backgroundColor: colors.primary, duration: const Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(text, style: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5)),
        ),
      ),
    ));
  }

  String? _extractUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match?.group(0);
  }
}

class _MediaItem {
  final String id;
  final String? content;
  final DateTime? sentAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final String? thumbnailSmallUrl;
  final String? thumbnailMediumUrl;
  final String? thumbnailLargeUrl;

  _MediaItem({
    required this.id, this.content, this.sentAt, this.fileUrl,
    this.fileName, this.fileSize, this.fileType,
    this.thumbnailSmallUrl, this.thumbnailMediumUrl, this.thumbnailLargeUrl,
  });

  factory _MediaItem.fromJson(Map<String, dynamic> json) => _MediaItem(
    id: json['id'] as String,
    content: json['content'] as String?,
    sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null,
    fileUrl: json['fileUrl'] as String?,
    fileName: json['fileName'] as String?,
    fileSize: json['fileSize'] as int?,
    fileType: json['fileType'] as String?,
    thumbnailSmallUrl: json['thumbnailSmallUrl'] as String?,
    thumbnailMediumUrl: json['thumbnailMediumUrl'] as String?,
    thumbnailLargeUrl: json['thumbnailLargeUrl'] as String?,
  );
}

class _RecordingTile extends StatefulWidget {
  final String dateStr;
  final String recordingUrl;
  final AppColorsExtension colors;

  const _RecordingTile({required this.dateStr, required this.recordingUrl, required this.colors});

  @override
  State<_RecordingTile> createState() => _RecordingTileState();
}

class _RecordingTileState extends State<_RecordingTile> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_playing) {
                await _player.pause();
              } else {
                if (_position == Duration.zero) {
                  await _player.play(UrlSource(widget.recordingUrl));
                } else {
                  await _player.resume();
                }
              }
            },
            child: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: colors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.textSecondary.withValues(alpha: 0.2),
                    thumbColor: colors.primary,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    onChanged: (v) {
                      final newPos = Duration(milliseconds: (v * _duration.inMilliseconds).toInt());
                      _player.seek(newPos);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position), style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    Text(widget.dateStr, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    Text(_fmt(_duration), style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenMediaView extends StatelessWidget {
  final _MediaItem item;
  const _FullScreenMediaView({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(item.fileName ?? '', style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: item.thumbnailLargeUrl ?? item.fileUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}

class _EditAliasScreen extends StatefulWidget {
  final String userId;
  final String? currentAlias;
  final String originalName;
  const _EditAliasScreen({required this.userId, this.currentAlias, required this.originalName});
  @override
  State<_EditAliasScreen> createState() => _EditAliasScreenState();
}

class _EditAliasScreenState extends State<_EditAliasScreen> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentAlias ?? widget.originalName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await sl<DioClient>().put<Map<String, dynamic>>(
        '/messenger/contacts/aliases/${widget.userId}',
        data: {'customName': name},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    try {
      await sl<DioClient>().delete('/messenger/contacts/aliases/${widget.userId}');
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messengerContactName),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                : Text(AppLocalizations.of(context)!.save, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.messengerOriginalName(widget.originalName), style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.messengerDisplayName,
                labelStyle: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
