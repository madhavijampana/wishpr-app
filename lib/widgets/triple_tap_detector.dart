import 'package:flutter/material.dart';

/// Fires [onTripleTap] after three taps within [window].
class TripleTapDetector extends StatefulWidget {
  const TripleTapDetector({
    super.key,
    required this.child,
    required this.onTripleTap,
    this.window = const Duration(milliseconds: 600),
  });

  final Widget child;
  final VoidCallback onTripleTap;
  final Duration window;

  @override
  State<TripleTapDetector> createState() => _TripleTapDetectorState();
}

class _TripleTapDetectorState extends State<TripleTapDetector> {
  int _count = 0;
  DateTime? _firstTapAt;

  void _handleTap() {
    final now = DateTime.now();
    if (_firstTapAt == null ||
        now.difference(_firstTapAt!) > widget.window) {
      _firstTapAt = now;
      _count = 1;
      return;
    }
    _count++;
    if (_count >= 3) {
      _count = 0;
      _firstTapAt = null;
      widget.onTripleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
