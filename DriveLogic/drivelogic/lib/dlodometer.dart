import 'package:flutter/material.dart';
import 'app_ui_supp.dart';

// MG: Issue 0000841: Implement an Odometer widget

class DLOdometerWidget extends StatelessWidget {
  final double value;
  final String fontName;
  final double bevelWidth;
  final DLBevelType bevelType; // 'inner', 'outer', 'both', 'none'
  final Color bevelColor;
  final Color fontColor;
  final Color backgroundColor;
  final EdgeInsets padding;
  final double bevelShadePercent;

  const DLOdometerWidget({
    super.key,
    required this.value,
    this.fontName = 'LCD',
    this.bevelWidth = 8,
    this.bevelType = DLBevelType.inner,
    this.bevelColor = Colors.grey,
    this.fontColor = Colors.green,
    this.backgroundColor = Colors.black,
    this.bevelShadePercent = 0.25,
    this.padding = const EdgeInsets.all(4.0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _OdometerPainter(
            value: value,
            fontName: fontName,
            bevelWidth: bevelWidth,
            bevelType: bevelType,
            bevelColor: bevelColor,
            fontColor: fontColor,
            backgroundColor: backgroundColor,
            padding: padding,
            bevelShadePercent: bevelShadePercent,
          ),
        );
      },
    );
  }
}

class _OdometerPainter extends CustomPainter {
  final double value;
  final String fontName;
  final double bevelWidth;
  final DLBevelType bevelType;
  final Color bevelColor;
  final Color fontColor;
  final Color backgroundColor;
  final EdgeInsets padding;
  final double bevelShadePercent;

  _OdometerPainter( {
    required this.value,
    required this.fontName,
    required this.bevelWidth,
    required this.bevelType,
    required this.bevelColor,
    required this.fontColor,
    required this.backgroundColor,
    required this.padding,
    required this.bevelShadePercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(rect, bgPaint);

    final lighter = HSLColor.fromColor(bevelColor).withLightness((HSLColor.fromColor(bevelColor).lightness + bevelShadePercent).clamp(0.0, 1.0)).toColor();
    final darker = HSLColor.fromColor(bevelColor).withLightness((HSLColor.fromColor(bevelColor).lightness - bevelShadePercent).clamp(0.0, 1.0)).toColor();

    if (bevelType != DLBevelType.none ) {
      _drawBevel(canvas, rect, lighter, darker);
    }

    final paddedRect = Rect.fromLTWH(
      rect.left + bevelWidth + padding.left,
      rect.top + bevelWidth + padding.top,
      rect.width - 2 * bevelWidth - padding.horizontal,
      rect.height - 2 * bevelWidth - padding.vertical,
    );

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final displayValue = value.toStringAsFixed(0).padLeft(7, '0');
    double fontSize = paddedRect.height;
    TextStyle style;
    do {
      style = TextStyle(
        fontSize: fontSize,
        fontFamily: fontName,
        color: fontColor,
      );
      textPainter.text = TextSpan(text: displayValue, style: style);
      textPainter.layout();
      fontSize -= 1;
    } while ((textPainter.width > paddedRect.width || textPainter.height > paddedRect.height) && fontSize > 0);

    final offset = Offset(
      paddedRect.left + (paddedRect.width - textPainter.width) / 2,
      paddedRect.top + (paddedRect.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);
  }

  void _drawBevel(Canvas canvas, Rect rect, Color light, Color dark) {

    double realBevelWidth = bevelType== DLBevelType.both ? (bevelWidth / 2).floorToDouble() : bevelWidth;

    final paintLight = Paint()..color = light;
    final paintDark = Paint()..color = dark;
    // left and top lines
    if (bevelType == DLBevelType.outer || bevelType == DLBevelType.both) {
      final pathTopLeft = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - realBevelWidth, rect.top + realBevelWidth)
        ..lineTo(rect.left + realBevelWidth, rect.top + realBevelWidth)
        ..lineTo(rect.left + realBevelWidth, rect.bottom - realBevelWidth)
        ..close();
      canvas.drawPath(pathTopLeft, paintLight);

      final pathBottomRight = Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + realBevelWidth, rect.bottom - realBevelWidth)
        ..lineTo(rect.right - realBevelWidth, rect.bottom - realBevelWidth)
        ..lineTo(rect.right - realBevelWidth, rect.top + realBevelWidth)
        ..close();
      canvas.drawPath(pathBottomRight, paintDark);
    }
    // bottom and right lines
    Rect rect2 = rect.deflate( bevelType == DLBevelType.both ? realBevelWidth : 0 ) ;
    if (bevelType == DLBevelType.inner || bevelType == DLBevelType.both) {
      final pathTopLeft = Path()
        ..moveTo(rect2.left , rect2.bottom)
        ..lineTo(rect2.left , rect2.top)
        ..lineTo(rect2.right, rect2.top)
        ..lineTo(rect2.right - realBevelWidth, rect2.top + realBevelWidth)
        ..lineTo(rect2.left + realBevelWidth, rect2.top + realBevelWidth)
        ..lineTo(rect2.left + realBevelWidth, rect2.bottom - realBevelWidth )
        ..close();
      canvas.drawPath(pathTopLeft, paintDark);

      final pathBottomRight = Path()
        ..moveTo(rect2.right , rect2.top)
        ..lineTo(rect2.right , rect2.bottom )
        ..lineTo(rect2.left, rect2.bottom)
        ..lineTo(rect2.left+ realBevelWidth , rect2.bottom - realBevelWidth)
        ..lineTo(rect2.right- realBevelWidth , rect2.bottom - realBevelWidth)
        ..lineTo(rect2.right- realBevelWidth , rect2.top + realBevelWidth)
        ..close();
      canvas.drawPath(pathBottomRight, paintLight);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
