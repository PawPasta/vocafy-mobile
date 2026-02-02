import 'package:flutter/material.dart';

class InAppNotificationBanner {
  InAppNotificationBanner._();

  static OverlayEntry? _entry;
  static DateTime? _shownAt;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // Avoid stacking many banners.
    hide();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _shownAt = DateTime.now();

    _entry = OverlayEntry(
      builder: (ctx) {
        return _AnimatedBanner(
          title: title,
          message: message,
          onTap: () {
            hide();
            onTap?.call();
          },
          onClose: hide,
        );
      },
    );

    overlay.insert(_entry!);

    Future<void>.delayed(duration, () {
      // Only auto-hide if this is still the latest banner.
      if (_shownAt != null &&
          DateTime.now().difference(_shownAt!) >= duration) {
        hide();
      }
    });
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
    _shownAt = null;
  }
}

class _AnimatedBanner extends StatefulWidget {
  const _AnimatedBanner({
    required this.title,
    required this.message,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = cs.surface;
    final fg = cs.onSurface;
    final accent = cs.primary;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 64,
                          margin: const EdgeInsets.only(left: 12, top: 12),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (widget.message.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.message,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: fg.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(
                            Icons.close,
                            color: fg.withValues(alpha: 0.7),
                          ),
                          splashRadius: 20,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
