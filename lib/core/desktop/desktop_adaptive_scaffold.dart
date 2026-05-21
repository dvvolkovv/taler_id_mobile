// lib/core/desktop/desktop_adaptive_scaffold.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';
import 'animated_blob_background.dart';
import 'centered_card.dart';
import 'desktop_breakpoints.dart';
import 'desktop_window_chrome.dart';

/// Высокоуровневый wrapper для desktop adaptation.
///
/// На мобиле — passthrough (возвращает child).
/// На десктопе:
///   - Stack: blob bg + Column(chrome, content)
///   - При ширине ≥ kDesktopBreakpoint: content центрируется в CenteredCard
///   - При меньшей ширине: content идёт во всю ширину с боковым padding (mobile-style внутри desktop chrome)
///
/// Использовать вместо обычного Scaffold-like обёртки в любом screen.
class DesktopAdaptiveScaffold extends StatelessWidget {
  const DesktopAdaptiveScaffold({
    super.key,
    required this.child,
    this.cardMaxWidth = kCardWidthForm,
    this.useGlass = true,
    this.useBlobBackground = true,
    this.cardPadding = const EdgeInsets.all(32),
    this.chromeTitle,
  });

  final Widget child;
  final double cardMaxWidth;
  final bool useGlass;
  final bool useBlobBackground;
  final EdgeInsets cardPadding;
  final String? chromeTitle;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          if (useBlobBackground) const Positioned.fill(child: AnimatedBlobBackground()),
          SafeArea(
            top: false,
            child: Column(
              children: [
                DesktopWindowChrome(title: chromeTitle),
                Expanded(
                  child: isWide
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: cardMaxWidth),
                              child: CenteredCard(
                                useGlass: useGlass,
                                padding: cardPadding,
                                child: child,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
