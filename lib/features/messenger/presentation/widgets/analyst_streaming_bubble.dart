import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnalystStreamingBubble extends StatefulWidget {
  final String text;
  const AnalystStreamingBubble({super.key, required this.text});

  @override
  State<AnalystStreamingBubble> createState() => _AnalystStreamingBubbleState();
}

class _AnalystStreamingBubbleState extends State<AnalystStreamingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>();
    final cs = Theme.of(context).colorScheme;
    final cardColor = ext?.card ?? cs.surface;
    final textColor = ext?.textPrimary ?? cs.onSurface;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              widget.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            FadeTransition(
              key: const Key('analyst-streaming-cursor'),
              opacity: _blink,
              child: Container(
                margin: const EdgeInsets.only(left: 2),
                width: 2,
                height: 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
