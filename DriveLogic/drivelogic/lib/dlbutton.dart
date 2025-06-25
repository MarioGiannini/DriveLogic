import 'package:flutter/material.dart';
import 'settings2_ui.dart';

class DLButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final double gap;
  final Color defaultLineColor;
  final Color lightLineColor;
  final Color backgroundColor;

  const DLButtonWidget({
    super.key,
    required this.onPressed,
    this.label = "DLButtonWidget",
    this.gap = 4,
    this.lightLineColor = Colors.white,
    this.defaultLineColor = Colors.white12,
    this.backgroundColor = const Color.fromARGB(255, 51, 51, 51),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        painter: _DLButtonWidgetPainter( this ),
      ),
    );
  }
}

class _DLButtonWidgetPainter extends CustomPainter {
  DLButtonWidget widget;

  _DLButtonWidgetPainter(this.widget );

  @override
  void paint(Canvas canvas, Size size) {
    paintSettings2Field(canvas, size,
        widget.label,
        widget.gap,
        widget.backgroundColor,
        widget.defaultLineColor,
        widget.lightLineColor,
        textAlign: TextAlign.center
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
