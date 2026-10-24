import 'package:flutter/material.dart';

class ButtonAnimator extends StatefulWidget {
  final Widget Function(bool isPressed) builder;
  final VoidCallback? onPressed;
  final bool disabled;

  const ButtonAnimator({
    Key? key,
    required this.builder,
    this.onPressed,
    this.disabled = false,
  }) : super(key: key);

  @override
  _ButtonAnimatorState createState() => _ButtonAnimatorState();
}

class _ButtonAnimatorState extends State<ButtonAnimator> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.disabled && widget.onPressed != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (!widget.disabled && widget.onPressed != null) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (!widget.disabled && widget.onPressed != null) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: widget.builder(_isPressed),
      ),
    );
  }
}
