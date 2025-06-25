import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'app_ui.dart';

class DLSettings2TabWidget extends StatefulWidget {
  final double gap;
  final double tabWidth;
  final double tabHeight;
  final String currentTab;
  final List<String> tabs;
  final Color defaultLineColor;
  

  final void Function(String ,List<String>) callback;

  const DLSettings2TabWidget(
  this.callback, this.currentTab, this.tabs, {
    super.key,
    this.gap = 4,
    this.tabWidth = 40,
    this.tabHeight = 30,
    this.defaultLineColor = Colors.white12,
  });

  @override
  State<DLSettings2TabWidget> createState() => _DLSettings2TabWidgetState();

  List<String> curTabs( ) {
    List<String> ret = [];
    if( currentTab.isNotEmpty) {
      ret.add(currentTab);
    }
    for (String tab in tabs) {
      if (tab != currentTab) {
        ret.add(tab);
      }
    }
    return ret;
  }
}

class _DLSettings2TabWidgetState extends State<DLSettings2TabWidget> {

  void _handleTapDown(TapDownDetails details) {
    final Offset pos = details.localPosition;
    double rightSide = (widget.tabWidth + widget.tabHeight / 2) * widget.tabs.length + widget.gap;
    // Check if the tap is within ( widget.gap, widget.gap) to (tabWidth, tabHeight)
    if (pos.dx >= widget.gap &&
        pos.dx <= rightSide &&
        pos.dy >= widget.gap &&
        pos.dy <= widget.tabHeight + widget.gap) {

      List<String> curTabs = widget.curTabs( );
      int tabIndex = (pos.dx - widget.gap) ~/ (widget.tabWidth + widget.tabHeight / 2);
      widget.callback( curTabs[ tabIndex], curTabs );

    }
  }

  @override
  Widget build(BuildContext context) {
    return
      GestureDetector(
        onTapDown: _handleTapDown,
        child:CustomPaint(
      painter: _Settings2TabPainter( widget// Pass the current tab string
      ),
        ),
    );
  }
}
class _Settings2TabPainter extends CustomPainter {
  DLSettings2TabWidget widget;

  _Settings2TabPainter(
      this.widget,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width -  widget.gap * 2;
    final double height = size.height -  widget.gap * 2;

    final Paint fillPaint = Paint()
      ..color = Colors.black.withValues( alpha: 0.5)
      ..style = PaintingStyle.fill;

    final Paint defaultLinePaint = Paint()
      ..color = widget.defaultLineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint lightLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Fill the first/main tab
    final Path tabPath = Path();
    final List<Offset> points = [
      Offset( widget.gap, widget.gap), // top-left
      Offset( widget.gap + widget.tabWidth, widget.gap), // tab top-right
      Offset( widget.gap + widget.tabWidth + widget.tabHeight, widget.gap + widget.tabHeight), // tab-bottom-right
      Offset(width,  widget.gap +  widget.tabHeight), // page top right
      Offset(width, height +  widget.gap), // page bottom right
      Offset( widget.gap, height +  widget.gap), // page bottom left
      Offset( widget.gap,  widget.gap), // back to tab top left
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

    // Draw complete border
    for (int i = 0; i < points.length; i++) {
      final Offset start = points[i];
      final Offset end = points[(i + 1) % points.length];
      canvas.drawLine(start, end, defaultLinePaint);
    }

    // Highlights and edge strokes of selected tab
    for (int i = 0; i < points.length; i++) {
      final Offset start = points[i];
      final Offset end = points[(i + 1) % points.length];
      canvas.drawLine(start, end, defaultLinePaint);

      final Offset midHi = points[i];
      Offset startHi = Offset(midHi.dx, midHi.dy);
      Offset endHi = Offset(midHi.dx, midHi.dy -  widget.gap);
      if (i == 0) {
        startHi = Offset(midHi.dx, midHi.dy +  widget.gap);
        endHi = Offset(midHi.dx +  widget.gap, midHi.dy);
      } else if (i == 1) {
        startHi = Offset(midHi.dx -  widget.gap, midHi.dy);
        endHi = Offset(midHi.dx +  widget.gap * 0.7, midHi.dy +  widget.gap * 0.7);
      } else if (i == 2) {
        startHi = Offset(midHi.dx -  widget.gap * 0.7, midHi.dy -  widget.gap * 0.7);
        endHi = Offset(midHi.dx +  widget.gap, midHi.dy);
      } else if (i == 3) {
        startHi = Offset(midHi.dx -  widget.gap, midHi.dy);
        endHi = Offset(midHi.dx, midHi.dy +  widget.gap);
      } else if (i == 4) {
        startHi = Offset(midHi.dx, midHi.dy -  widget.gap);
        endHi = Offset(midHi.dx -  widget.gap, midHi.dy);
      } else if (i == 5) {
        startHi = Offset(midHi.dx +  widget.gap, midHi.dy);
        endHi = Offset(midHi.dx, midHi.dy -  widget.gap);
      }

      if (i < 6) {
        canvas.drawLine(startHi, midHi, lightLinePaint);
        canvas.drawLine(midHi, endHi, lightLinePaint);
      }
    }

    // Draw additional tab sections
    for( int tab=1; tab < widget.tabs.length; tab++) {
      final Path tabPath = Path();
      final double xOffset = tab * (widget.tabWidth + widget.tabHeight/2);
      final List<Offset> points = [
        Offset( widget.gap + xOffset, widget.gap), // top-left
        Offset( widget.gap + widget.tabWidth + xOffset, widget.gap), // tab top-right
        Offset( widget.gap + widget.tabWidth + widget.tabHeight+ xOffset, widget.gap + widget.tabHeight), // tab-bottom-right

        Offset( widget.gap+ xOffset + widget.tabHeight / 2, widget.tabHeight +  widget.gap), // page bottom left
        Offset( widget.gap+ xOffset, widget.tabHeight/2 +  widget.gap), // page bottom left mid

        Offset( widget.gap+ xOffset,  widget.gap), // back to tab top left

      ];
      for( int point = 0; point < points.length; point++) {
        if ( point == 0) {
          tabPath.moveTo(points[point].dx, points[point].dy);
        } else {
          tabPath.lineTo(points[point].dx, points[point].dy);
        }
      }
      tabPath.close();
      canvas.drawPath(tabPath, fillPaint);

      for (int i = 0; i < points.length; i++) {
        final Offset start = points[i];
        final Offset end = points[(i + 1) % points.length];
        canvas.drawLine(start, end, defaultLinePaint);

        final Offset midHi = points[i];
        Offset startHi = Offset(midHi.dx, midHi.dy);
        Offset endHi = Offset(midHi.dx, midHi.dy -  widget.gap);
        if (i == 0) {
          startHi = Offset(midHi.dx, midHi.dy +  widget.gap);
          endHi = Offset(midHi.dx +  widget.gap, midHi.dy);
        } else if (i == 1) {
          startHi = Offset(midHi.dx -  widget.gap, midHi.dy);
          endHi = Offset(midHi.dx +  widget.gap * 0.7, midHi.dy +  widget.gap * 0.7);
        } else if (i == 2) {
          startHi = Offset(midHi.dx -  widget.gap * 0.7, midHi.dy -  widget.gap * 0.7);
          endHi = Offset(midHi.dx +  widget.gap, midHi.dy);
        }

        if (i < 3) {
          canvas.drawLine(startHi, midHi, lightLinePaint);
          if( endHi.dx <= width ) {
            canvas.drawLine(midHi, endHi, lightLinePaint);
          }
        }
      }
    }

    // Draw label with currentTab
    List<String> curTabs = widget.curTabs( );
    for( int tab = 0; tab < curTabs.length; tab++) {
      final double xOffset = tab * (widget.tabWidth + widget.tabHeight/2) + widget.gap*3;
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontFamily: 'ChakraPetch',
          textAlign: TextAlign.left,
          fontSize: defaultFontSize,
          fontWeight: FontWeight.bold,
          maxLines: 1,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(curTabs[tab]);

      final ui.Paragraph paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: size.width));

      //canvas.drawParagraph(paragraph, Offset(widget.gap*2  + tab * widget.tabWidth, widget.gap * 2));
      canvas.drawParagraph(paragraph, Offset(xOffset, widget.gap * 2));
    }

  }

  @override
  bool shouldRepaint(covariant _Settings2TabPainter oldDelegate) {
    return oldDelegate.widget.currentTab != widget.currentTab || oldDelegate.widget.tabs.length != widget.tabs.length;
  }

}
