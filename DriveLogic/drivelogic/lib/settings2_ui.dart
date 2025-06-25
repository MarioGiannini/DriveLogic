import 'package:flutter/material.dart';
import 'app_ui.dart';
import 'dart:ui' as ui;

// This unit is supporting methods for the Settings2 config screens.


void paintSettings2Field(Canvas canvas, Size size,
    String value, double gap, Color backgroundColor, Color defaultLineColor,
    Color lightLineColor,
{TextAlign textAlign = TextAlign.center, bool withDropdown = false, String templateText='' }) {
  final double width = size.width - gap * 2;
  final double height = size.height - gap * 2;

  final Paint fillPaint = Paint()
    ..color =  backgroundColor
    ..style = PaintingStyle.fill;

  final Paint defaultLinePaint = Paint()
    ..color = defaultLineColor
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  final Paint lightLinePaint = Paint()
    ..color = lightLineColor
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  // Fill the inner block
  final Path tabPath = Path();
  List<Offset> points = [
    Offset( gap, gap), // left-top
    Offset( gap + width, gap), // right-top
    Offset( gap + width, height + gap), // right-bottom
    Offset( gap, height + gap), // left-bottom
    Offset( gap, gap), // back to left-top
  ];

  // Draw complete border
  for (int i = 0; i < points.length; i++) {
    final Offset start = points[i];
    final Offset end = points[(i + 1) % points.length];
    canvas.drawLine(start, end, defaultLinePaint);
  }

  double innerGap = 4;
  // Highlight and edge strokes of selected tab
  for (int i = 0; i < points.length; i++) {
    final Offset start = points[i];
    final Offset end = points[(i + 1) % points.length];
    canvas.drawLine(start, end, defaultLinePaint);

    final Offset midHi = points[i];
    Offset startHi = Offset(midHi.dx, midHi.dy + innerGap * 2);
    Offset endHi = Offset(midHi.dx + innerGap * 2, midHi.dy);
    if (i == 1) {
      startHi = Offset(midHi.dx - innerGap * 2, midHi.dy);
      endHi = Offset(midHi.dx, midHi.dy + innerGap * 2);
    } else if (i == 2) {
      startHi = Offset(midHi.dx, midHi.dy - innerGap * 2);
      endHi = Offset(midHi.dx - innerGap * 2, midHi.dy);
    } else if (i == 3) {
      startHi = Offset(midHi.dx + innerGap * 2, midHi.dy);
      endHi = Offset(midHi.dx, midHi.dy - innerGap * 2);
    }

    canvas.drawLine(startHi, midHi, lightLinePaint);
    canvas.drawLine(midHi, endHi, lightLinePaint);
  }

  points = [
    Offset( gap + innerGap, gap + innerGap),
    // left-top
    Offset( gap + width - innerGap, gap + innerGap),
    // right-top
    Offset( gap + width - innerGap, height + gap - innerGap),
    // right-bottom
    Offset( gap + innerGap, height + gap - innerGap),
    // left-bottom
    Offset( gap + innerGap, gap + innerGap),
    // back to left-top
  ];

  for (int i = 0; i < points.length; i++) {
    if (i == 0) {
      tabPath.moveTo(points[i].dx, points[i].dy);
    } else {
      tabPath.lineTo(points[i].dx, points[i].dy);
    }
  }
  tabPath.close();
  canvas.drawPath(tabPath, fillPaint);

  final double xOffset = textAlign == TextAlign.center ? 0 : gap * 3;
  final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontFamily: 'ChakraPetch',
      textAlign: textAlign,
      fontSize: defaultFontSize,
      fontWeight: FontWeight.bold,
      maxLines: 1,
    ),
  )
    ..pushStyle(ui.TextStyle(color: Colors.white))
    ..addText( value );

  final ui.Paragraph paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: size.width));

  //canvas.drawParagraph(paragraph, Offset(widget.gap*2  + tab * widget.tabWidth, widget.gap * 2));
  final double yOffset = (size.height - paragraph.height) / 2;
  canvas.drawParagraph(paragraph, Offset(xOffset, yOffset));

  if( withDropdown ) {
    double iconLeft = width - 40;
    double iconTop = height / 2 - 20;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.arrow_drop_down.codePoint),
        style: TextStyle(
          fontSize: 48,
          fontFamily: Icons.arrow_drop_down.fontFamily,
          package: Icons.arrow_drop_down.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(iconLeft, iconTop));
  }

}
