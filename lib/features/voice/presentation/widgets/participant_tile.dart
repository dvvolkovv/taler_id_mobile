import 'package:flutter/material.dart';
import '../../domain/entities/group_call_invite.dart';

/// Reusable tile for a participant in a group call.
///
/// Shows: avatar + display name + status overlay (ringing animation for
/// CALLING, gray ✕ for DECLINED, gray clock for TIMEOUT, exit-to-app for LEFT,
/// nothing for JOINED).
///
/// `isHost` adds a small badge. `isActiveSpeaker` adds a glowing border.
/// `onLongPress` is wired by the host's UI for kick action (Task 25).
class ParticipantTile extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final GroupCallInviteStatus status;
  final bool isHost;
  final bool isActiveSpeaker;
  final VoidCallback? onLongPress;

  const ParticipantTile({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.status,
    this.isHost = false,
    this.isActiveSpeaker = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? overlay;
    String? statusLabel;
    Color? labelColor;
    switch (status) {
      case GroupCallInviteStatus.calling:
        overlay = const Center(
          child: _PulsingPhoneIcon(),
        );
        statusLabel = 'звоним…';
        break;
      case GroupCallInviteStatus.declined:
        overlay = const Center(
          child: Icon(Icons.close, color: Colors.redAccent, size: 32),
        );
        statusLabel = 'отклонил';
        labelColor = Colors.redAccent;
        break;
      case GroupCallInviteStatus.timeout:
        overlay = const Center(
          child: Icon(Icons.access_time, color: Colors.orangeAccent, size: 32),
        );
        statusLabel = 'не ответил';
        labelColor = Colors.orangeAccent;
        break;
      case GroupCallInviteStatus.left:
        overlay = const Center(
          child: Icon(Icons.exit_to_app, color: Colors.grey, size: 32),
        );
        statusLabel = 'покинул';
        labelColor = Colors.grey;
        break;
      case GroupCallInviteStatus.joined:
        // No overlay — clean avatar
        break;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          border: isActiveSpeaker
              ? Border.all(color: Colors.greenAccent, width: 3)
              : null,
          borderRadius: BorderRadius.circular(40),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(displayName.isEmpty
                          ? '?'
                          : displayName.substring(0, 1))
                      : null,
                ),
                if (overlay != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: overlay,
                    ),
                  ),
                if (isHost)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (statusLabel != null)
              Text(
                statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Subtle pulsing phone icon — Material's `Icons.phone` ramping in/out
/// to convey "ringing" without an external animation package.
class _PulsingPhoneIcon extends StatefulWidget {
  const _PulsingPhoneIcon();

  @override
  State<_PulsingPhoneIcon> createState() => _PulsingPhoneIconState();
}

class _PulsingPhoneIconState extends State<_PulsingPhoneIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(Tween<double>(begin: 0.4, end: 1.0)),
      child: const Icon(Icons.phone, color: Colors.white, size: 28),
    );
  }
}
