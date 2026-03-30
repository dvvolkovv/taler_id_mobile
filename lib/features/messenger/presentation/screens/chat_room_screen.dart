import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:video_player/video_player.dart' as vp;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/services/chunked_upload_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../data/datasources/messenger_remote_datasource.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final List? sharedFiles;
  const ChatRoomScreen({super.key, required this.conversationId, this.sharedFiles});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final TextEditingController _ctrl;
  late final ScrollController _scrollCtrl;
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  double _prevKeyboardHeight = 0;
  MessageEntity? _replyTo;
  String? _replyToSenderName;
  MessageEntity? _editingMessage;
  bool _socketDisconnected = false;
  StreamSubscription? _disconnectSub;
  StreamSubscription? _reconnectSub;
  Timer? _typingTimer;
  bool _isTypingSent = false;
  late final MessengerBloc _messengerBloc;
  // Pending attachments (inline preview before send)
  final List<_PendingFile> _pendingFiles = [];

  @override
  void initState() {
    super.initState();
    _messengerBloc = context.read<MessengerBloc>();
    _ctrl = TextEditingController();
    _ctrl.addListener(_onTextChanged);
    _scrollCtrl = ScrollController();
    _messengerBloc.add(OpenConversation(widget.conversationId));
    // Mark messages as read when opening conversation
    _messengerBloc.add(MarkConversationRead(widget.conversationId));
    // Handle shared files from external apps
    if (widget.sharedFiles != null && widget.sharedFiles!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addSharedFiles(widget.sharedFiles!);
      });
    }
    // Listen for socket connectivity changes
    final ds = sl<MessengerRemoteDataSource>();
    _disconnectSub = ds.disconnectStream.listen((_) {
      if (mounted) setState(() => _socketDisconnected = true);
    });
    _reconnectSub = ds.reconnectStream.listen((_) {
      if (mounted) setState(() => _socketDisconnected = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kh = MediaQuery.of(context).viewInsets.bottom;
    if (kh > _prevKeyboardHeight) {
      // With reverse:true, bottom of chat is offset 0
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _prevKeyboardHeight = kh;
  }

  void _setReply(MessageEntity msg, String? senderName) {
    setState(() {
      _replyTo = msg;
      _replyToSenderName = senderName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
      _replyToSenderName = null;
    });
  }

  void _startEditing(MessageEntity message) {
    setState(() {
      _editingMessage = message;
      _replyTo = null;
      _replyToSenderName = null;
    });
    _ctrl.text = message.content;
    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
  }

  void _cancelEditing() {
    setState(() => _editingMessage = null);
    _ctrl.clear();
  }

  void _handleMenuAction(String action, bool isMuted) {
    if (action == 'mute') {
      if (isMuted) {
        context.read<MessengerBloc>().add(UnmuteConversation(widget.conversationId));
      } else {
        _showMuteDurationSheet();
      }
    }
  }

  void _showMuteDurationSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.muteNotifications,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor1Hour, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 60));
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor8Hours, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 480));
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor2Days, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 2880));
              },
            ),
            ListTile(
              leading: Icon(Icons.volume_off, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteForever, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _joinActiveCall(String roomName) async {
    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatAlreadyInCall),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }
    if (mounted) {
      final conv = context.read<MessengerBloc>().state.conversations
          .where((c) => c.id == widget.conversationId)
          .firstOrNull;
      final calleeName = conv?.type == 'GROUP' ? conv?.name : conv?.otherUserName;
      final calleeAvatar = conv?.type == 'GROUP' ? conv?.avatarUrl : conv?.otherUserAvatar;
      final calleeParam = calleeName != null && calleeName.isNotEmpty
          ? '&callee=${Uri.encodeComponent(calleeName)}'
          : '';
      final avatarParam = calleeAvatar != null && calleeAvatar.isNotEmpty
          ? '&calleeAvatar=${Uri.encodeComponent(calleeAvatar)}'
          : '';
      var calleeId = conv?.type == 'DIRECT' ? conv?.otherUserId : null;
      if (calleeId == null && conv != null && conv.type == 'DIRECT' && conv.participantIds.length == 2) {
        final myId = await sl<SecureStorageService>().getUserId();
        if (myId != null) {
          calleeId = conv.participantIds.firstWhere((id) => id != myId, orElse: () => '');
          if (calleeId!.isEmpty) calleeId = null;
        }
      }
      final calleeIdParam = calleeId != null && calleeId.isNotEmpty
          ? '&calleeId=$calleeId'
          : '';
      context.push('/dashboard/voice?room=$roomName&convId=${widget.conversationId}$calleeParam$avatarParam$calleeIdParam');
    }
  }

  Future<void> _startCall() async {
    // Guard: only block when max lines reached
    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatAlreadyInCall),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }

    try {
      const withAi = false;
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/rooms',
        data: {'withAi': withAi, 'conversationId': widget.conversationId},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      sl<MessengerRemoteDataSource>()
          .sendCallInvite(widget.conversationId, roomName);
      final allConvs = context.read<MessengerBloc>().state.conversations;
      debugPrint('[ChatRoom] _startCall: convCount=${allConvs.length}, looking for convId=${widget.conversationId}');
      final _conv = allConvs
          .where((c) => c.id == widget.conversationId)
          .firstOrNull;
      debugPrint('[ChatRoom] _startCall: found conv=${_conv != null}, type=${_conv?.type}, otherUserId=${_conv?.otherUserId}, participantIds=${_conv?.participantIds}');
      final calleeName = _conv?.type == 'GROUP' ? _conv?.name : _conv?.otherUserName;
      final calleeAvatar = _conv?.type == 'GROUP' ? _conv?.avatarUrl : _conv?.otherUserAvatar;
      final calleeParam = calleeName != null && calleeName.isNotEmpty
          ? '&callee=${Uri.encodeComponent(calleeName)}'
          : '';
      final avatarParam = calleeAvatar != null && calleeAvatar.isNotEmpty
          ? '&calleeAvatar=${Uri.encodeComponent(calleeAvatar)}'
          : '';
      var calleeId = _conv?.type == 'DIRECT' ? _conv?.otherUserId : null;
      debugPrint('[ChatRoom] _startCall: conv=${_conv != null}, type=${_conv?.type}, otherUserId=${_conv?.otherUserId}, participantIds=${_conv?.participantIds}, calleeAvatar=$calleeAvatar');
      // Fallback: get otherUserId from participantIds if otherUserId is null
      if (calleeId == null && _conv != null && _conv.type == 'DIRECT' && _conv.participantIds.length == 2) {
        final myId = await sl<SecureStorageService>().getUserId();
        debugPrint('[ChatRoom] myId=$myId');
        if (myId != null) {
          calleeId = _conv.participantIds.firstWhere((id) => id != myId, orElse: () => '');
          if (calleeId!.isEmpty) calleeId = null;
        }
      }
      final calleeIdParam = calleeId != null && calleeId.isNotEmpty
          ? '&calleeId=$calleeId'
          : '';
      if (mounted) context.push('/dashboard/voice?room=$roomName&convId=${widget.conversationId}$calleeParam$avatarParam$calleeIdParam');
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatCallError(e.toString())),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  void _showAttachMenu() {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.primary),
                title: Text(l10n.chatPhotoVideo, style: TextStyle(color: colors.textPrimary)),
                onTap: () { Navigator.pop(ctx); _pickMediaFromGallery(); },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: colors.primary),
                title: Text(l10n.chatCamera, style: TextStyle(color: colors.textPrimary)),
                onTap: () { Navigator.pop(ctx); _pickFromCamera(); },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file, color: colors.primary),
                title: Text(l10n.chatFile, style: TextStyle(color: colors.textPrimary)),
                onTap: () { Navigator.pop(ctx); _pickFile(); },
              ),
              ListTile(
                leading: Icon(Icons.person_rounded, color: colors.primary),
                title: Text(l10n.chatContact, style: TextStyle(color: colors.textPrimary)),
                onTap: () { Navigator.pop(ctx); _pickContact(); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMediaFromGallery() async {
    setState(() => _isPreparing = true);
    try {
      final assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 9,
          requestType: RequestType.common,
          themeColor: AppColors.of(context).primary,
        ),
      );
      if (!mounted) return;
      if (assets == null || assets.isEmpty) return;
      for (final asset in assets) {
        final file = await asset.file;
        if (file == null || !mounted) continue;
        final type = asset.type == AssetType.video ? 'video' : 'image';
        setState(() {
          _pendingFiles.add(_PendingFile(path: file.path, name: asset.title ?? file.path.split('/').last, type: type));
        });
      }
    } catch (_) {
      // ignore picker errors
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _pendingFiles.add(_PendingFile(path: picked.path, name: picked.name, type: 'image'));
    });
  }

  void _addSharedFiles(List sharedFiles) {
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    setState(() {
      for (final file in sharedFiles) {
        final path = file.path as String? ?? '';
        if (path.isEmpty) continue;
        final name = path.split('/').last;
        final ext = name.split('.').last.toLowerCase();
        String? typeOverride;
        if (imageExts.contains(ext)) typeOverride = 'image';
        if (videoExts.contains(ext)) typeOverride = 'video';
        _pendingFiles.add(_PendingFile(path: path, name: name, type: typeOverride));
      }
    });
  }

  Future<void> _pickFile() async {
    setState(() => _isPreparing = true);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
    } catch (_) {
      // ignore picker errors
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
    if (!mounted || result == null || result!.files.isEmpty) return;
    final pickedFiles = result!.files;
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    setState(() {
      for (final file in pickedFiles) {
        if (file.path == null) continue;
        final ext = file.name.split('.').last.toLowerCase();
        String? typeOverride;
        if (imageExts.contains(ext)) typeOverride = 'image';
        if (videoExts.contains(ext)) typeOverride = 'video';
        _pendingFiles.add(_PendingFile(path: file.path!, name: file.name, type: typeOverride));
      }
    });
  }

  void _pickContact() {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<MessengerBloc>();
    final convs = bloc.state.conversations.where((c) => c.type == 'DIRECT').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.chatSelectContact,
                    style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              if (convs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.chatNoContacts, style: TextStyle(color: colors.textSecondary)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: convs.length,
                    itemBuilder: (context, i) {
                      final c = convs[i];
                      final name = c.otherUserName ?? l10n.chatUser;
                      final avatar = c.otherUserAvatar;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primary,
                          backgroundImage: avatar != null && avatar.isNotEmpty
                              ? CachedNetworkImageProvider(avatar)
                              : null,
                          child: (avatar == null || avatar.isEmpty)
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(name, style: TextStyle(color: colors.textPrimary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          final contactJson = jsonEncode({'name': name, 'userId': c.otherUserId, 'avatar': c.otherUserAvatar ?? ''});
                          context.read<MessengerBloc>().add(SendMessage(widget.conversationId, '[CONTACT]$contactJson'));
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelPendingAttachment([int? index]) {
    setState(() {
      if (index != null) {
        _pendingFiles.removeAt(index);
      } else {
        _pendingFiles.clear();
      }
    });
  }

  Future<void> _sendPendingAttachment() async {
    if (_pendingFiles.isEmpty) return;
    final files = List<_PendingFile>.from(_pendingFiles);
    final caption = _ctrl.text.trim();
    setState(() => _pendingFiles.clear());
    _ctrl.clear();
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      try {
        await _uploadAndSendFile(f.path, f.name, typeOverride: f.type, caption: i == 0 && caption.isNotEmpty ? caption : null);
      } catch (_) {
        // Continue uploading remaining files even if one fails
      }
    }
  }

  bool _isPreparing = false;
  double? _uploadProgress;
  CancelToken? _uploadCancelToken;

  void _cancelUpload() {
    _uploadCancelToken?.cancel('User cancelled');
    _uploadCancelToken = null;
    setState(() => _uploadProgress = null);
  }

  Future<void> _uploadAndSendFile(String filePath, String fileName, {String? typeOverride, String? caption}) async {
    if (!File(filePath).existsSync()) return;
    _uploadCancelToken = CancelToken();
    setState(() => _uploadProgress = 0);
    try {
      final result = await ChunkedUploadService.upload(
        filePath: filePath,
        fileName: fileName,
        cancelToken: _uploadCancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() => _uploadProgress = null);
      // Use client-side type if known, fallback to backend
      final fileType = typeOverride ?? result.fileType;
      // Fix fileUrl if backend returns hardcoded prod URL on staging
      var fileUrl = result.fileUrl;
      final baseUrl = AppConfig.baseUrl;
      if (!fileUrl.startsWith(baseUrl)) {
        final uri = Uri.parse(fileUrl);
        final baseUri = Uri.parse(baseUrl);
        fileUrl = fileUrl.replaceFirst('${uri.scheme}://${uri.host}', '${baseUri.scheme}://${baseUri.host}');
      }
      final l10n = AppLocalizations.of(context)!;
      final isMedia = fileType == 'image' || fileType == 'video' || fileType == 'audio';
      String msgContent = caption ?? (isMedia ? '' : fileName);
      if (_replyTo != null) {
        final quoted = _replyTo!.fileUrl != null
            ? (_replyTo!.fileName ?? l10n.chatFileAttachment)
            : _replyTo!.content;
        final q = quoted.length > 60 ? '${quoted.substring(0, 60)}...' : quoted;
        final who = _replyToSenderName != null ? '$_replyToSenderName: ' : '';
        msgContent = '↩ $who«$q»\n$msgContent';
      }
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        msgContent,
        fileUrl: fileUrl,
        fileName: result.fileName,
        fileSize: result.fileSize,
        fileType: fileType,
        s3Key: result.s3Key,
        thumbnailSmallUrl: result.thumbnailSmallUrl,
        thumbnailMediumUrl: result.thumbnailMediumUrl,
        thumbnailLargeUrl: result.thumbnailLargeUrl,
        fileRecordId: result.fileRecordId,
      ));
      _cancelReply();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadProgress = null);
      _uploadCancelToken = null;
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatFileUploadError(e.toString())), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_editingMessage != null) {
      final msg = _editingMessage!;
      context.read<MessengerBloc>().add(EditMessage(
        conversationId: msg.conversationId,
        messageId: msg.id,
        newContent: text,
      ));
      _ctrl.clear();
      _cancelEditing();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    String content = text;
    if (_replyTo != null) {
      final quoted = _replyTo!.fileUrl != null
          ? (_replyTo!.fileName ?? l10n.chatFileAttachment)
          : _replyTo!.content;
      final q = quoted.length > 60 ? '${quoted.substring(0, 60)}...' : quoted;
      final who = _replyToSenderName != null ? '$_replyToSenderName: ' : '';
      content = '↩ $who«$q»\n$text';
    }
    context.read<MessengerBloc>().add(SendMessage(widget.conversationId, content));
    // Stop typing indicator on send
    if (_isTypingSent) {
      _isTypingSent = false;
      _typingTimer?.cancel();
      context.read<MessengerBloc>().add(SendTyping(conversationId: widget.conversationId, isTyping: false));
    }
    _ctrl.clear();
    _cancelReply();
    // With reverse:true, new messages appear at offset 0
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission || !mounted) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _isRecording = true; _recordingPath = path; });
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await _recorder.stop();
    setState(() { _isRecording = false; });
    if (path == null || !mounted) return;
    try {
      final client = sl<DioClient>();
      final file = File(path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.m4a'),
      });
      final res = await client.post(
        '/messenger/files',
        data: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        l10n.chatVoiceMessage,
        fileUrl: res['fileUrl'] as String,
        fileName: res['fileName'] as String,
        fileSize: res['fileSize'] as int?,
        fileType: 'audio',
      ));
      file.deleteSync();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _onTextChanged() {
    final bloc = context.read<MessengerBloc>();
    if (_ctrl.text.isNotEmpty && !_isTypingSent) {
      _isTypingSent = true;
      bloc.add(SendTyping(conversationId: widget.conversationId, isTyping: true));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTypingSent) {
        _isTypingSent = false;
        bloc.add(SendTyping(conversationId: widget.conversationId, isTyping: false));
      }
    });
  }

  @override
  void dispose() {
    // Send typing stop on exit — use cached bloc reference (context is deactivated in dispose)
    if (_isTypingSent) {
      _messengerBloc.add(SendTyping(conversationId: widget.conversationId, isTyping: false));
    }
    // Clear unread count and refresh conversations list on exit
    _messengerBloc.add(MarkConversationRead(widget.conversationId));
    _messengerBloc.add(LoadConversations());
    _typingTimer?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _disconnectSub?.cancel();
    _reconnectSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: BlocBuilder<MessengerBloc, MessengerState>(
          buildWhen: (prev, curr) => prev.conversations != curr.conversations,
          builder: (context, state) {
            final conv = state.conversations
                .where((c) => c.id == widget.conversationId)
                .firstOrNull;
            final l10n = AppLocalizations.of(context)!;
            final isGroup = conv?.type == 'GROUP';
            final name = isGroup ? (conv?.name ?? l10n.chatGroup) : conv?.otherUserName;
            final avatarUrl = isGroup ? conv?.avatarUrl : conv?.otherUserAvatar;
            final otherUserId = conv?.otherUserId;
            return GestureDetector(
              onTap: isGroup
                  ? () => context.push('/dashboard/messenger/${widget.conversationId}/settings')
                  : otherUserId != null
                      ? () => context.push('/dashboard/user/$otherUserId')
                      : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.of(context).primary.withValues(alpha: isGroup ? 0.4 : 0.2),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: 36, height: 36, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => isGroup
                                  ? Icon(Icons.group_rounded, color: AppColors.of(context).primary, size: 18)
                                  : Text(
                                      name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: TextStyle(color: AppColors.of(context).primary, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          )
                        : isGroup
                            ? Icon(Icons.group_rounded, color: AppColors.of(context).primary, size: 18)
                            : Text(
                                name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(color: AppColors.of(context).primary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name != null && name.isNotEmpty ? name : l10n.chatDialog,
                            overflow: TextOverflow.ellipsis),
                        if (isGroup && conv != null)
                          Text(
                            AppLocalizations.of(context)!.participantsCount(conv.participantCount),
                            style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, fontWeight: FontWeight.normal),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: _startCall,
            tooltip: AppLocalizations.of(context)!.chatCall,
          ),
          BlocBuilder<MessengerBloc, MessengerState>(
            buildWhen: (prev, curr) => prev.conversations != curr.conversations,
            builder: (context, state) {
              final conv = state.conversations
                  .where((c) => c.id == widget.conversationId)
                  .firstOrNull;
              final isMuted = conv?.isMuted ?? false;
              return PopupMenuButton<String>(
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.more_vert,
                  color: isMuted ? AppColors.of(context).textSecondary : null,
                ),
                onSelected: (value) => _handleMenuAction(value, isMuted),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'mute',
                    child: Row(
                      children: [
                        Icon(
                          isMuted ? Icons.volume_up : Icons.volume_off,
                          size: 20,
                          color: AppColors.of(context).textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(isMuted
                            ? AppLocalizations.of(context)!.unmuteNotifications
                            : AppLocalizations.of(context)!.muteNotifications),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<MessengerBloc, MessengerState>(
        listenWhen: (prev, curr) {
          final prevCount = prev.messages[widget.conversationId]?.length ?? 0;
          final currCount = curr.messages[widget.conversationId]?.length ?? 0;
          return currCount > prevCount;
        },
        listener: (context, state) {
          // Mark new incoming messages as read immediately since chat is open
          context.read<MessengerBloc>().add(MarkConversationRead(widget.conversationId));
          // With reverse:true the list starts at bottom — only scroll if user scrolled up
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollCtrl.hasClients) return;
            if (_scrollCtrl.offset > 0) {
              _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        },
        child: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final messages = state.messages[widget.conversationId] ?? [];
          final conv = state.conversations
              .where((c) => c.id == widget.conversationId)
              .firstOrNull;
          final isGroup = conv?.type == 'GROUP';
          final otherUserName = conv?.otherUserName;
          final activeRoomName = state.activeGroupCalls[widget.conversationId];
          return Column(
            children: [
              // Connectivity warning banner — shown at TOP when socket disconnected
              if (_socketDisconnected)
                _ConnectivityBanner(),
              // Active call banner for group conversations
              if (isGroup && activeRoomName != null)
                _ActiveCallBanner(
                  onJoin: () => _joinActiveCall(activeRoomName),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: messages.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.chatStartConversation,
                          style:
                              TextStyle(color: AppColors.of(context).textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[messages.length - 1 - index];
                          final isMe = _isMyMessage(msg, state);
                          final sName = isMe ? null : (msg.senderName ?? otherUserName);
                          // Show date separator above this message if it's the first
                          // message of its day (i.e. previous message in chronological
                          // order is from a different day, or this is the very first message).
                          // Since the list is reversed, "previous chronological" = index+1.
                          final msgDate = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
                          bool showDate = false;
                          if (index == messages.length - 1) {
                            // oldest message — always show date
                            showDate = true;
                          } else {
                            final prevMsg = messages[messages.length - 2 - index];
                            final prevDate = DateTime(prevMsg.sentAt.year, prevMsg.sentAt.month, prevMsg.sentAt.day);
                            showDate = msgDate != prevDate;
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDate) _DateSeparator(date: msg.sentAt),
                              _MessageBubble(
                                message: msg,
                                isMe: isMe,
                                isGroup: isGroup,
                                senderName: sName,
                                allMessages: messages,
                                onReply: msg.isSystem ? null : () => _setReply(msg, isMe ? AppLocalizations.of(context)!.chatYou : sName),
                                onEdit: (isMe && !msg.isSystem && msg.fileUrl == null) ? () => _startEditing(msg) : null,
                                onReact: msg.isSystem ? null : (emoji) {
                                  context.read<MessengerBloc>().add(ReactToMessage(
                                    conversationId: msg.conversationId,
                                    messageId: msg.id,
                                    emoji: emoji,
                                  ));
                                },
                                currentUserId: state.currentUserId,
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ),
              if (_editingMessage != null)
                _EditPreviewBar(
                  message: _editingMessage!,
                  onCancel: _cancelEditing,
                ),
              if (_replyTo != null)
                _ReplyPreviewBar(
                  message: _replyTo!,
                  senderName: _replyToSenderName,
                  onCancel: _cancelReply,
                ),
              // Typing indicator
              BlocBuilder<MessengerBloc, MessengerState>(
                buildWhen: (prev, curr) =>
                    prev.typingUsers[widget.conversationId] != curr.typingUsers[widget.conversationId],
                builder: (context, state) {
                  final typers = state.typingUsers[widget.conversationId];
                  if (typers == null || typers.isEmpty) return const SizedBox.shrink();
                  final l10n = AppLocalizations.of(context)!;
                  final names = typers.values.where((n) => n.isNotEmpty).toList();
                  final text = names.isEmpty
                      ? l10n.chatIsTyping
                      : names.length == 1
                          ? l10n.chatUserIsTyping(names.first)
                          : l10n.chatUsersAreTyping(names.join(', '));
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).card,
                      border: Border(
                        top: BorderSide(color: AppColors.of(context).border, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 16,
                          child: _TypingDots(color: AppColors.of(context).primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_pendingFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: AppColors.of(context).card,
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pendingFiles.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final f = _pendingFiles[i];
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (f.type == 'image')
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(f.path), width: 56, height: 56, fit: BoxFit.cover),
                                    )
                                  else if (f.type == 'video')
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.videocam_rounded, color: Colors.white54, size: 28),
                                    )
                                  else
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(color: AppColors.of(context).background, borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.insert_drive_file_rounded, color: AppColors.of(context).primary, size: 22),
                                          const SizedBox(height: 2),
                                          Text(
                                            f.name.length > 8 ? '${f.name.substring(0, 6)}...' : f.name,
                                            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 8),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  Positioned(
                                    top: -6, right: -6,
                                    child: GestureDetector(
                                      onTap: () => _cancelPendingAttachment(i),
                                      child: Container(
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.of(context).error,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showAttachMenu,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.of(context).primary.withOpacity(0.15),
                            ),
                            child: Icon(Icons.add, color: AppColors.of(context).primary, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isPreparing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.of(context).card,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.of(context).primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.chatPreparingFile,
                        style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (_uploadProgress != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.of(context).card,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.chatUploading((_uploadProgress! * 100).toInt()),
                              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                minHeight: 4,
                                backgroundColor: AppColors.of(context).textSecondary.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.of(context).primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _cancelUpload,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.of(context).error.withOpacity(0.15),
                          ),
                          child: Icon(Icons.close, size: 18, color: AppColors.of(context).error),
                        ),
                      ),
                    ],
                  ),
                ),
              _InputBar(
                controller: _ctrl,
                onSend: _pendingFiles.isNotEmpty ? _sendPendingAttachment : _sendMessage,
                onAttach: _showAttachMenu,
                isRecording: _isRecording,
                onRecordStart: _startRecording,
                onRecordStop: _stopRecordingAndSend,
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  bool _isMyMessage(MessageEntity msg, MessengerState state) {
    final uid = state.currentUserId;
    if (uid == null) return msg.id.startsWith('temp_');
    return msg.senderId == uid;
  }
}

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFB71C1C),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.connectionUnstable,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCallBanner extends StatelessWidget {
  final VoidCallback onJoin;
  const _ActiveCallBanner({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.callInProgress,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: onJoin,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(AppLocalizations.of(context)!.joinCall, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDay == today) {
      label = AppLocalizations.of(context)!.today;
    } else if (msgDay == yesterday) {
      label = AppLocalizations.of(context)!.yesterday;
    } else if (date.year == now.year) {
      label = DateFormat('d MMMM', Localizations.localeOf(context).languageCode).format(date);
    } else {
      label = DateFormat('d MMMM y', Localizations.localeOf(context).languageCode).format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;
  final String? senderName;
  final bool isGroup;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final void Function(String emoji)? onReact;
  final String? currentUserId;
  final List<MessageEntity> allMessages;
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.senderName,
    this.isGroup = false,
    this.onReply,
    this.onEdit,
    this.onReact,
    this.currentUserId,
    this.allMessages = const [],
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  double _dragOffset = 0;
  bool _replyTriggered = false;
  static const _replyThreshold = 56.0;
  static const _maxDrag = 72.0;

  static const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
  static const _videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};

  String _effectiveFileType(MessageEntity msg) {
    final ft = msg.fileType;
    if (ft == 'image' || ft == 'video' || ft == 'audio') return ft!;
    // Detect by URL or fileName extension
    final name = (msg.fileName ?? msg.fileUrl ?? '').split('?').first.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : '';
    if (_imageExts.contains(ext)) return 'image';
    if (_videoExts.contains(ext)) return 'video';
    return 'document';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isSystem) {
      return _buildSystemMessage(context);
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0 || _dragOffset > 0) {
          final newOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
          if (newOffset >= _replyThreshold && !_replyTriggered) {
            _replyTriggered = true;
            HapticFeedback.mediumImpact();
          }
          setState(() => _dragOffset = newOffset);
        }
      },
      onHorizontalDragEnd: (_) {
        if (_replyTriggered && widget.onReply != null) {
          widget.onReply!();
        }
        setState(() {
          _dragOffset = 0;
          _replyTriggered = false;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = 0;
          _replyTriggered = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_dragOffset > 4)
            Positioned(
              left: 4,
              top: 0,
              bottom: 8,
              child: Center(
                child: Icon(
                  Icons.reply_rounded,
                  color: AppColors.of(context).primary.withValues(
                      alpha: (_dragOffset / _replyThreshold).clamp(0.0, 1.0)),
                  size: 22,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset * 0.65, 0),
            child: Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isMe && widget.senderName != null && widget.senderName!.isNotEmpty && (widget.isGroup || widget.senderName != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.senderName!,
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (widget.message.fileUrl != null && _effectiveFileType(widget.message) == 'image')
              GestureDetector(
                onTap: () {
                  final imageMessages = widget.allMessages
                      .where((m) => m.fileUrl != null && _effectiveFileType(m) == 'image')
                      .toList();
                  final idx = imageMessages.indexWhere((m) => m.id == widget.message.id);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _FullScreenImageGallery(
                      imageUrls: imageMessages.map((m) => m.fileUrl!).toList(),
                      initialIndex: idx >= 0 ? idx : 0,
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 220,
                      height: 160,
                      child: CachedNetworkImage(
                        imageUrl: widget.message.thumbnailLargeUrl ?? widget.message.fileUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.of(context).primary,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.of(context).textSecondary),
                      ),
                    ),
                  ),
                ),
              )
            else if (widget.message.fileUrl != null && _effectiveFileType(widget.message) == 'video')
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _FullScreenVideoPlayer(videoUrl: widget.message.fileUrl!),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 220,
                      height: 160,
                      child: widget.message.thumbnailMediumUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.message.thumbnailMediumUrl!,
                              fit: BoxFit.cover,
                              width: 220,
                              height: 160,
                              placeholder: (_, __) => Container(
                                color: Colors.black26,
                                child: const Center(child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white70)),
                              ),
                              errorWidget: (_, __, ___) => _VideoThumbnail(videoUrl: widget.message.fileUrl!),
                            )
                          : _VideoThumbnail(videoUrl: widget.message.fileUrl!),
                    ),
                  ),
                ),
              )
            else if (widget.message.fileUrl != null && _effectiveFileType(widget.message) == 'audio')
              _AudioMessagePlayer(fileUrl: widget.message.fileUrl!, isMe: widget.isMe)
            else if (widget.message.fileUrl != null)
              _DocumentBubble(
                fileUrl: widget.message.fileUrl!,
                fileName: widget.message.fileName ?? widget.message.content,
                fileSize: widget.message.fileSize,
              )
            else if (widget.message.content.startsWith('[CONTACT]'))
              _ContactCardWidget(content: widget.message.content)
            else
              _LinkifiedText(
                text: widget.message.content,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                ),
                linkStyle: TextStyle(
                  color: AppColors.of(context).primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            // Show caption under image/video if content differs from fileName
            if (widget.message.fileUrl != null &&
                (_effectiveFileType(widget.message) == 'image' || _effectiveFileType(widget.message) == 'video') &&
                widget.message.content.isNotEmpty &&
                widget.message.content != widget.message.fileName)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.message.content,
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.message.isEdited) ...[
                  Text(
                    AppLocalizations.of(context)!.chatEdited,
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  DateFormat('HH:mm').format(widget.message.sentAt.toLocal()),
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.message.isRead
                        ? Icons.done_all_rounded
                        : widget.message.isDelivered
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                    size: 14,
                    color: widget.message.isRead
                        ? AppColors.of(context).primary
                        : AppColors.of(context).textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      if (widget.message.reactions.isNotEmpty)
        _ReactionsRow(
          reactions: widget.message.reactions,
          currentUserId: widget.currentUserId,
          onTap: widget.onReact,
        ),
      if (widget.message.reactions.isEmpty)
        const SizedBox(height: 8),
        ],
      ),
          ),
          ),
        ],
      ),
    );
  }

  static const _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  void _showMessageActions(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (widget.onReact != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _quickEmojis.map((emoji) {
                    final myReaction = widget.message.reactions.any(
                      (r) => r['emoji'] == emoji && r['userId'] == widget.currentUserId,
                    );
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onReact!(emoji);
                      },
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: myReaction
                              ? colors.primary.withValues(alpha: 0.2)
                              : colors.background,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 16),
            ],
            if (widget.onReply != null)
              ListTile(
                leading: Icon(Icons.reply_rounded, color: colors.primary),
                title: Text(l10n.chatReply, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReply!();
                },
              ),
            if (widget.isMe && widget.message.fileUrl == null && widget.message.content.isNotEmpty && widget.onEdit != null)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: colors.primary),
                title: Text(l10n.chatEdit, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onEdit!();
                },
              ),
            if (widget.message.fileUrl == null && widget.message.content.isNotEmpty)
              ListTile(
                leading: Icon(Icons.copy_rounded, color: colors.textSecondary),
                title: Text(l10n.chatCopy, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: widget.message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.chatCopied), duration: const Duration(seconds: 2)),
                  );
                },
              ),
            if (widget.message.fileUrl != null)
              ListTile(
                leading: Icon(Icons.download_rounded, color: colors.textSecondary),
                title: Text(l10n.chatSaveMedia, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _saveFile(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.forward_rounded, color: colors.textSecondary),
              title: Text(l10n.chatForward, style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showForwardPicker(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              title: Text(l10n.delete, style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFile(BuildContext context) async {
    final url = widget.message.fileUrl;
    if (url == null) return;
    final fileType = _effectiveFileType(widget.message);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.chatSaving), duration: const Duration(seconds: 1)),
      );

      if (fileType == 'image' || fileType == 'video') {
        // Download to temp, then save to gallery
        final dir = await getTemporaryDirectory();
        final ext = fileType == 'image' ? '.jpg' : '.mp4';
        final fileName = widget.message.fileName ?? 'taler_${DateTime.now().millisecondsSinceEpoch}$ext';
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final filePath = '${dir.path}/save_$safeName';
        await Dio().download(url, filePath);

        if (fileType == 'image') {
          await Gal.putImage(filePath);
        } else {
          await Gal.putVideo(filePath);
        }
        // Clean up temp file
        try { await File(filePath).delete(); } catch (_) {}

        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatSavedToGallery), duration: const Duration(seconds: 2)),
        );
      } else {
        // Document / audio — download and open
        final dir = await getTemporaryDirectory();
        final fileName = widget.message.fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final filePath = '${dir.path}/messenger_files/$safeName';
        await Directory('${dir.path}/messenger_files').create(recursive: true);
        await Dio().download(url, filePath);
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      if (e.toString().contains('access')) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatNoSavePermission), duration: const Duration(seconds: 3)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatFileSaveError), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _showDeleteConfirm(BuildContext context) {
    final bloc = context.read<MessengerBloc>();
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.chatDeleteMessage,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text(l10n.chatDeleteForMe, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(DeleteMessage(
                  conversationId: widget.message.conversationId,
                  messageId: widget.message.id,
                  forEveryone: false,
                ));
              },
            ),
            if (widget.isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: Text(l10n.chatDeleteForEveryone, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DeleteMessage(
                    conversationId: widget.message.conversationId,
                    messageId: widget.message.id,
                    forEveryone: true,
                  ));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showForwardPicker(BuildContext context) {
    final bloc = context.read<MessengerBloc>();
    final conversations = bloc.state.conversations;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ForwardPickerSheet(
        conversations: conversations,
        onSelected: (targetConversationId) {
          bloc.add(ForwardMessage(
            message: widget.message,
            targetConversationId: targetConversationId,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.chatMessageForwarded), duration: const Duration(seconds: 2)),
          );
        },
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    String text;
    try {
      final data = jsonDecode(widget.message.content) as Map<String, dynamic>;
      final action = data['action'] as String?;
      final actor = data['actor'] as String? ?? '';
      final target = data['target'] as String? ?? '';
      final role = data['role'] as String? ?? '';
      final l10n = AppLocalizations.of(context)!;
      switch (action) {
        case 'group_created': text = l10n.groupCreated; break;
        case 'member_added': text = l10n.memberJoined(target); break;
        case 'member_left': text = l10n.memberLeftGroup(actor); break;
        case 'member_removed': text = l10n.memberWasRemoved(target); break;
        case 'role_changed': text = l10n.roleChangedTo(target, role); break;
        default: text = widget.message.content;
      }
    } catch (_) {
      text = widget.message.content;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.of(context).card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final _urlRegex = RegExp(
  r'https?://[^\s<>\"\)]+',
  caseSensitive: false,
);

class _ContactCardWidget extends StatelessWidget {
  final String content;
  const _ContactCardWidget({required this.content});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    try {
      final jsonStr = content.substring('[CONTACT]'.length);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = data['name'] as String? ?? AppLocalizations.of(context)!.chatContact;
      final userId = data['userId'] as String? ?? '';
      final avatar = data['avatar'] as String? ?? '';

      return GestureDetector(
        onTap: userId.isNotEmpty
            ? () => GoRouter.of(context).push('/dashboard/user/$userId')
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.primary,
                backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                child: avatar.isEmpty
                    ? Icon(Icons.person_rounded, color: Colors.black, size: 22)
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(AppLocalizations.of(context)!.chatContactTapToOpen,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      );
    } catch (_) {
      return Text(content, style: TextStyle(color: colors.textPrimary, fontSize: 14));
    }
  }
}

class _LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle linkStyle;
  const _LinkifiedText({
    required this.text,
    required this.style,
    required this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return SelectionArea(child: Text(text, style: style));
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: style));
      }
      final url = m.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            final uri = Uri.tryParse(url);
            if (uri == null) return;
            const talerHosts = {'id.taler.tirol', 'staging.id.taler.tirol'};
            final isTaler = talerHosts.contains(uri.host);
            // Open room links inside the app instead of the browser
            if (isTaler && uri.path.startsWith('/room/')) {
              final code = uri.pathSegments.last;
              if (code.isNotEmpty) {
                GoRouter.of(context).go('/dashboard/voice?publicCode=$code');
                return;
              }
            }
            // Open contact profile links inside the app
            if (isTaler && uri.path.startsWith('/u/')) {
              final userId = uri.pathSegments.last;
              if (userId.isNotEmpty) {
                GoRouter.of(context).push('/dashboard/user/$userId');
                return;
              }
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
          },
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    return SelectionArea(child: Text.rich(TextSpan(children: spans)));
  }
}

class _CallOptionsSheet extends StatefulWidget {
  const _CallOptionsSheet();

  @override
  State<_CallOptionsSheet> createState() => _CallOptionsSheetState();
}

class _CallOptionsSheetState extends State<_CallOptionsSheet> {
  bool _withAi = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voiceCallSettings,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _withAi,
              onChanged: (v) => setState(() => _withAi = v),
              activeColor: AppColors.of(context).primary,
              title: Text(
                l10n.voiceEnableAI,
                style: TextStyle(color: AppColors.of(context).textPrimary),
              ),
              subtitle: Text(
                _withAi
                    ? l10n.voiceAIParticipating
                    : l10n.voiceNormalCall,
                style: TextStyle(
                    color: AppColors.of(context).textSecondary, fontSize: 12),
              ),
              secondary: Icon(
                Icons.smart_toy_outlined,
                color: _withAi ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _withAi),
              icon: const Icon(Icons.call_rounded, color: Colors.black),
              label: Text(
                l10n.chatCall,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForwardPickerSheet extends StatefulWidget {
  final List<ConversationEntity> conversations;
  final void Function(String conversationId) onSelected;

  const _ForwardPickerSheet({
    required this.conversations,
    required this.onSelected,
  });

  @override
  State<_ForwardPickerSheet> createState() => _ForwardPickerSheetState();
}

class _ForwardPickerSheetState extends State<_ForwardPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.conversations.where((c) {
      final name = c.name ?? c.otherUserName ?? '';
      return name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.chatForwardTo,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.chatSearchHint,
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final conv = filtered[i];
                final name = conv.name ?? conv.otherUserName ?? l10n.chatDialog;
                final avatarUrl = conv.type == 'DIRECT' ? conv.otherUserAvatar : conv.avatarUrl;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primary.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(name, style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelected(conv.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isRecording;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.isRecording,
    required this.onRecordStart,
    required this.onRecordStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        border: Border(
          top: BorderSide(color: AppColors.of(context).border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isRecording ? null : onAttach,
            icon: Icon(Icons.attach_file_rounded, color: AppColors.of(context).textSecondary),
          ),
          Expanded(
            child: isRecording
                ? Row(
                    children: [
                      Icon(Icons.circle, color: AppColors.of(context).error, size: 12),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.chatRecording, style: TextStyle(color: AppColors.of(context).error, fontSize: 14)),
                    ],
                  )
                : TextField(
                    controller: controller,
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.chatMessageHint,
                      hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
          ),
          IconButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            icon: Icon(Icons.keyboard_hide_rounded, color: AppColors.of(context).textSecondary),
            tooltip: AppLocalizations.of(context)!.chatHideKeyboard,
          ),
          // Voice button: hold to record voice message
          GestureDetector(
              onLongPressStart: (_) => onRecordStart(),
              onLongPressEnd: (_) => onRecordStop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: isRecording ? AppColors.of(context).error : AppColors.of(context).textSecondary,
                ),
              ),
            ),
          if (!isRecording)
            IconButton(
              onPressed: onSend,
              icon: Icon(Icons.send_rounded, color: AppColors.of(context).primary),
            ),
        ],
      ),
    );
  }
}

class _ReplyPreviewBar extends StatelessWidget {
  final MessageEntity message;
  final String? senderName;
  final VoidCallback onCancel;
  const _ReplyPreviewBar({required this.message, this.senderName, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final preview = message.fileUrl != null
        ? '📎 ${message.fileName ?? l10n.chatFile}'
        : message.content;
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName ?? '',
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _EditPreviewBar extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onCancel;
  const _EditPreviewBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final preview = message.content;
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, color: colors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.chatEditing,
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _DocumentBubble extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  const _DocumentBubble({required this.fileUrl, required this.fileName, this.fileSize});
  @override
  State<_DocumentBubble> createState() => _DocumentBubbleState();
}

class _DocumentBubbleState extends State<_DocumentBubble> {
  double? _progress;
  bool _downloading = false;

  String get _sizeLabel {
    if (widget.fileSize == null) return '';
    final kb = widget.fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _openFile() async {
    final dir = await getTemporaryDirectory();
    final safeName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final filePath = '${dir.path}/messenger_files/$safeName';
    final file = File(filePath);

    // Use cached file if exists
    if (await file.exists()) {
      await OpenFilex.open(filePath);
      return;
    }

    setState(() { _downloading = true; _progress = 0; });

    try {
      await Directory('${dir.path}/messenger_files').create(recursive: true);
      await Dio().download(
        widget.fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (!mounted) return;
      setState(() { _downloading = false; _progress = null; });
      await OpenFilex.open(filePath);
    } catch (e) {
      if (!mounted) return;
      setState(() { _downloading = false; _progress = null; });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatFileDownloadError),
          action: SnackBarAction(label: l10n.retry, onPressed: _openFile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _downloading ? null : _openFile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_downloading)
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 2,
                color: AppColors.of(context).primary,
              ),
            )
          else
            Icon(Icons.insert_drive_file_rounded, color: AppColors.of(context).primary, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fileName,
                  style: TextStyle(color: AppColors.of(context).primary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_sizeLabel.isNotEmpty)
                  Text(_sizeLabel, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumb;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final data = await vt.VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 440,
        quality: 75,
      );
      if (mounted && data != null) {
        setState(() {
          _thumb = data;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        if (_thumb != null)
          Image.memory(_thumb!, fit: BoxFit.cover)
        else
          Container(
            color: Colors.black87,
            child: Center(
              child: _loaded
                  ? Icon(Icons.videocam_rounded, color: Colors.white54, size: 48)
                  : CircularProgressIndicator(strokeWidth: 2, color: AppColors.of(context).primary),
            ),
          ),
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  final String fileUrl;
  final bool isMe;
  const _AudioMessagePlayer({required this.fileUrl, required this.isMe});

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      try {
        final file = await DefaultCacheManager().getSingleFile(widget.fileUrl);
        await _player.play(DeviceFileSource(file.path));
      } catch (_) {
        await _player.play(UrlSource(widget.fileUrl));
      }
      setState(() => _playing = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
            color: AppColors.of(context).primary,
            size: 32,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.chatVoiceMessageShort,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final scale = t < 0.5 ? 0.5 + t : 1.5 - t;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.4 + 0.6 * scale.clamp(0.0, 1.0)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  final List<Map<String, dynamic>> reactions;
  final String? currentUserId;
  final void Function(String emoji)? onTap;
  const _ReactionsRow({required this.reactions, this.currentUserId, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Group reactions by emoji: { emoji: [userId, ...] }
    final grouped = <String, List<String>>{};
    for (final r in reactions) {
      final emoji = r['emoji'] as String? ?? '';
      final userId = r['userId'] as String? ?? '';
      grouped.putIfAbsent(emoji, () => []).add(userId);
    }
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: grouped.entries.map((entry) {
          final isMine = entry.value.contains(currentUserId);
          return GestureDetector(
            onTap: onTap != null ? () => onTap!(entry.key) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMine
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.card,
                borderRadius: BorderRadius.circular(12),
                border: isMine
                    ? Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  if (entry.value.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${entry.value.length}',
                      style: TextStyle(
                        color: isMine ? colors.primary : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Fullscreen Image Gallery ────────────────────────────

class _FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullScreenImageGallery({required this.imageUrls, this.initialIndex = 0});

  @override
  State<_FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
              onPressed: _saving ? null : _saveCurrentImage,
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _saving = false;

  Future<void> _saveCurrentImage() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/save_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(widget.imageUrls[_currentIndex], filePath);
      await Gal.putImage(filePath);
      try { await File(filePath).delete(); } catch (_) {}
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatSavedToGallery), duration: const Duration(seconds: 2)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatSavingError), duration: const Duration(seconds: 2)),
      );
    }
    if (mounted) setState(() => _saving = false);
  }
}

// ─── Fullscreen Video Player ─────────────────────────────

class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  vp.VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _savingVideo = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      if (!mounted) return;
      _ctrl = vp.VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _ctrl!.play();
            _scheduleHideControls();
          }
        });
      _ctrl!.addListener(_onVideoUpdate);
    } catch (_) {
      if (!mounted) return;
      _ctrl = vp.VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _ctrl!.play();
            _scheduleHideControls();
          }
        });
      _ctrl!.addListener(_onVideoUpdate);
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  Future<void> _saveVideo() async {
    setState(() => _savingVideo = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/save_vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await Dio().download(widget.videoUrl, filePath);
      await Gal.putVideo(filePath);
      try { await File(filePath).delete(); } catch (_) {}
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatVideoSavedToGallery), duration: const Duration(seconds: 2)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatSavingError), duration: const Duration(seconds: 2)),
      );
    }
    if (mounted) setState(() => _savingVideo = false);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl?.removeListener(_onVideoUpdate);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: _initialized && _ctrl != null
                  ? AspectRatio(
                      aspectRatio: _ctrl!.value.aspectRatio,
                      child: vp.VideoPlayer(_ctrl!),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            if (_showControls) ...[
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                  onPressed: _savingVideo ? null : _saveVideo,
                ),
              ),
              if (_initialized)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 48,
                        icon: Icon(
                          _ctrl!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
                          _scheduleHideControls();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDuration(_ctrl!.value.position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Expanded(
                            child: Slider(
                              value: _ctrl!.value.duration.inMilliseconds > 0
                                  ? _ctrl!.value.position.inMilliseconds / _ctrl!.value.duration.inMilliseconds
                                  : 0,
                              onChanged: (v) {
                                _ctrl!.seekTo(Duration(
                                  milliseconds: (v * _ctrl!.value.duration.inMilliseconds).toInt(),
                                ));
                                _scheduleHideControls();
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                            ),
                          ),
                          Text(
                            _formatDuration(_ctrl!.value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingFile {
  final String path;
  final String name;
  final String? type;
  const _PendingFile({required this.path, required this.name, this.type});
}
