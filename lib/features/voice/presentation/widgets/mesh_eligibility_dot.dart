import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/voice/mesh_peer_eligibility_watcher.dart';

class MeshEligibilityDot extends StatefulWidget {
  final String userId;
  final Color color;
  final double size;

  const MeshEligibilityDot({
    super.key,
    required this.userId,
    this.color = const Color(0xFF4CAF50),
    this.size = 6.0,
  });

  @override
  State<MeshEligibilityDot> createState() => _MeshEligibilityDotState();
}

class _MeshEligibilityDotState extends State<MeshEligibilityDot> {
  StreamSubscription<({String userId, bool isOnline})>? _sub;
  bool _isOnline = false;
  bool _postFramePending = false;

  @override
  void initState() {
    super.initState();
    final watcher = GetIt.I<MeshPeerEligibilityWatcher>();
    _isOnline = watcher.isUserOnline(widget.userId);
    _sub = watcher.userChanges.listen((e) {
      if (e.userId != widget.userId) return;
      if (!mounted) return;
      setState(() => _isOnline = e.isOnline);
      // Schedule a post-frame callback that requests one extra frame after
      // the rebuild renders. This ensures the next tester.pump() sees
      // hasScheduledFrame=true and processes pending stream events correctly
      // in widget tests. In production this costs one additional no-op frame
      // per state change (acceptable for a static indicator).
      if (!_postFramePending) {
        _postFramePending = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _postFramePending = false;
          if (mounted) SchedulerBinding.instance.scheduleFrame();
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) return const SizedBox.shrink();
    return Container(
      key: const Key('mesh-eligibility-dot'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
      ),
    );
  }
}
