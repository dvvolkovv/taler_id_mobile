import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/presence_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/presence_entity.dart';
import '../../domain/repositories/i_presence_repository.dart';

/// Subtitle widget that polls `/presence/:userId` every 30 s while mounted.
/// Renders an empty box on first frame to avoid layout jitter.
class PresenceLabel extends StatefulWidget {
  final String userId;
  final TextStyle? style;

  const PresenceLabel({super.key, required this.userId, this.style});

  @override
  State<PresenceLabel> createState() => _PresenceLabelState();
}

class _PresenceLabelState extends State<PresenceLabel> {
  static const Duration _pollInterval = Duration(seconds: 30);

  PresenceEntity? _entity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_fetch()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final e = await GetIt.instance<IPresenceRepository>().getPresence(widget.userId);
      if (!mounted) return;
      setState(() => _entity = e);
    } catch (_) {
      // swallow; keep last known value
    }
  }

  @override
  Widget build(BuildContext context) {
    final entity = _entity;
    if (entity == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Text(
      formatLastSeen(entity, l10n, DateTime.now()),
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
