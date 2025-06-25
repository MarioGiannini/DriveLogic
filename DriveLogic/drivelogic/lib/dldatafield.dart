import 'package:flutter/material.dart';
import 'settings2_ui.dart';

class DLDataFieldWidget extends StatefulWidget {
  final double gap;
  final String value;
  final String valueKey;
  final String editLabel;
  
  final Color defaultLineColor;
  final Color lightLineColor;
  final Color backgroundColor;

  const DLDataFieldWidget(
      this.value,
      {
        super.key,
        this.valueKey = '',
        this.editLabel = '',
        this.gap = 4,
        this.defaultLineColor = Colors.white12,
        this.lightLineColor = Colors.white,
        this.backgroundColor = const Color.fromARGB(255, 51, 51, 51),
      });

  @override
  State<DLDataFieldWidget> createState() => _DLDataFieldWidgetState();
  
}

class _DLDataFieldWidgetState extends State<DLDataFieldWidget> {

  @override
  Widget build(BuildContext context) {
    return

          CustomPaint(
            painter: _DLDataFieldPainter( widget ),
        );


    /*
    return
      GestureDetector(
        onTapDown: _handleTapDown,
        child:CustomPaint(
          painter: _DLDataFieldPainter( widget ),
        ),
      );
    */
  }
}
class _DLDataFieldPainter extends CustomPainter {
  DLDataFieldWidget widget;

  _DLDataFieldPainter(
      this.widget,
      );

  @override
  void paint(Canvas canvas, Size size) {
    paintSettings2Field(canvas, size,
      widget.value,
      widget.gap,
      widget.backgroundColor,
      widget.defaultLineColor,
      widget.lightLineColor,
      textAlign: TextAlign.left
    );
  }

  @override
  bool shouldRepaint(covariant _DLDataFieldPainter oldDelegate) {
    return oldDelegate.widget.value != widget.value;
  }

}
