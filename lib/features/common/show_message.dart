import 'package:flutter/material.dart';

enum MessageStatus {
  info,
  success,
  warning,
  error,
}

/// Shows a status toast that slides in from the top.
/// [message] – body text.
/// [context] – build context (for overlay and theme).
/// [status] – info (blue), success (green), warning (orange), error (red).
/// [title] – optional bold title above the message.
void showMessage(
    String message,
    BuildContext context, {
      MessageStatus status = MessageStatus.info,
      String? title,
    }) {
  final overlay = Overlay.of(context);
  final colorScheme = _statusColors(status);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => _ToastFromTop(
      status: status,
      colorScheme: colorScheme,
      title: title,
      message: message,
      onDismiss: () {
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}

_ToastColors _statusColors(MessageStatus status) {
  switch (status) {
    case MessageStatus.info:
      return _ToastColors(
        bar: const Color(0xFF2196F3),
        iconBg: const Color(0xFFE3F2FD),
        iconFg: const Color(0xFF2196F3),
      );
    case MessageStatus.success:
      return _ToastColors(
        bar: const Color(0xFF2E7D32),
        iconBg: const Color(0xFFE8F5E9),
        iconFg: const Color(0xFF1B5E20),
      );
    case MessageStatus.warning:
      return _ToastColors(
        bar: const Color(0xFFF79E1B),
        iconBg: const Color(0xFFFDF6ED),
        iconFg: const Color(0xFFE89D34),
      );
    case MessageStatus.error:
      return _ToastColors(
        bar: const Color(0xFFD32F2F),
        iconBg: const Color(0xFFFFEBEE),
        iconFg: const Color(0xFFC62828),
      );
  }
}

class _ToastColors {
  const _ToastColors({
    required this.bar,
    required this.iconBg,
    required this.iconFg,
  });
  final Color bar;
  final Color iconBg;
  final Color iconFg;
}

class _ToastFromTop extends StatefulWidget {
  const _ToastFromTop({
    required this.status,
    required this.colorScheme,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  final MessageStatus status;
  final _ToastColors colorScheme;
  final String? title;
  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ToastFromTop> createState() => _ToastFromTopState();
}

class _ToastFromTopState extends State<_ToastFromTop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E232C);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF646A73);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: widget.colorScheme.bar,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Row(
                            children: [
                              _buildIcon(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.title != null &&
                                        widget.title!.isNotEmpty)
                                      Text(
                                        widget.title!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                          color: titleColor,
                                        ),
                                      ),
                                    if (widget.title != null &&
                                        widget.title!.isNotEmpty)
                                      const SizedBox(height: 2),
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Inter',
                                        color: widget.title != null &&
                                            widget.title!.isNotEmpty
                                            ? subtitleColor
                                            : titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _dismiss,
                                icon: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: textColor,
                                ),
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(32, 32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final c = widget.colorScheme;
    final icon = _statusIcon();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.iconBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.iconFg.withOpacity(0.3), width: 1),
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }

  Widget _statusIcon() {
    final color = widget.colorScheme.iconFg;
    switch (widget.status) {
      case MessageStatus.success:
        return Icon(Icons.check, size: 22, color: color);
      case MessageStatus.warning:
        return Icon(Icons.warning_amber_rounded, size: 22, color: color);
      case MessageStatus.error:
        return Icon(Icons.error_outline, size: 22, color: color);
      case MessageStatus.info:
        return Icon(Icons.info_outline, size: 22, color: color);
    }
  }
}
