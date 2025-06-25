import 'package:flutter/material.dart';
// import 'dart:ui' as ui;

import 'dart:math';
import 'datapoint.dart';
// DLArcWidget
//
// DLArcWidget('images/OffRoadRearSideProfile.png', -_curValue, _minValue, _maxValue),
// Displays an image rotated by a specific amount.  The angle is calculated
// from cur, min, and max values.  For example, min can be 0 and max 360
// and 180 for curValue would be 180 degrees, or min can be 0 and max can be 100,
// and a value of 50 will give 180 degrees.
//

const dlArcCornerTopLeft = 1;
const dlArcCornerTopRight = 2;
const dlArcCornerBottomLeft = 4;
const dlArcCornerBottomRight = 8;

class DLArcPainter extends CustomPainter {
  //final ui.Image image;
  final double top;
  final double left;
  final double width;
  final double height;
  final double angle;
  final Datapoint datapoint;
  // final double curValue;
  // final double minValue;
  // final double maxValue;
  // final double warnLow;
  // final double warnHigh;
  final Color color;
  final Color colorBG;
  final Color colorArc;
  final Color colorArcWarn;
  final Color valueTextColor;
  final Color endLabelTextColor;
  final String startLabelText;
  final String endLabelText;
  final double labelFontSize;
  final String nameText;
  final int cornerRadius;
  final String errMsg;

  DLArcPainter({
    //required this.image,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.angle,
    required this.datapoint,
    // required this.curValue,
    // required this.minValue,
    // required this.maxValue,
    // required this.warnLow,
    // required this.warnHigh,
    // required this.decimals,

    required this.color,
    required this.colorBG,
    required this.colorArc,
    required this.colorArcWarn,
    required this.valueTextColor,
    required this.endLabelTextColor,
    required this.startLabelText,
    required this.endLabelText,
    required this.labelFontSize,
    required this.nameText,
    required this.cornerRadius,
    required this.errMsg,

  });

  @override
  void paint(Canvas canvas, Size size) {
    //final Rect sourceRect = Rect.fromLTWH(left, top, width, height);
    Rect destinationRect = Rect.fromLTWH(0, 0, size.width, size.height);
    Radius radius10 = const Radius.circular(10);

    final paintBG = Paint()
      ..color = colorBG;
    //canvas.drawRect( destinationRect, paintBG );
    RRect rrect = RRect.fromRectAndCorners(destinationRect,
        topLeft: cornerRadius & dlArcCornerTopLeft == 0 ? Radius.zero : radius10,
        topRight: cornerRadius & dlArcCornerTopRight == 0 ? Radius.zero : radius10,
        bottomLeft: cornerRadius & dlArcCornerBottomLeft == 0 ? Radius.zero : radius10,
        bottomRight: cornerRadius & dlArcCornerBottomRight == 0 ? Radius.zero : radius10,
      );


    canvas.drawRRect( rrect, paintBG);

    Color arcColor = datapoint.isWarning() ? colorArcWarn : colorArc;

    const startAngle = pi;
    final sweepAngle = angle / 2;
    const useCenter = false;
    final strokeWidth = size.width / 10;
    final paintArc = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    destinationRect = destinationRect.deflate(strokeWidth);

    if( errMsg.isNotEmpty )
    {
      double tmplabelFontSize = ( labelFontSize == 0 ) ? destinationRect.height / 7 : labelFontSize;

      TextStyle textStyle = TextStyle(
        color: valueTextColor,
        fontSize: tmplabelFontSize*1.5,
      );

      TextSpan textSpan = TextSpan(
        text: errMsg,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      const offset = Offset(4, 4);
      textPainter.paint(canvas, offset);
      return;
    }

    canvas.drawArc(destinationRect, startAngle, sweepAngle, useCenter, paintArc);

    double topOffset = 0.0;
    if( valueTextColor != Colors.transparent ) {
      double tmplabelFontSize = ( labelFontSize == 0 ) ? destinationRect.height / 7 : labelFontSize;

      TextStyle textStyle = TextStyle(
        color: valueTextColor,
        fontSize: tmplabelFontSize*2,
      );

      String text = datapoint.getDecimaled();

      TextSpan textSpan = TextSpan(
        text: text,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      final xCenter = (size.width - textPainter.width) / 2;
      final yCenter = (size.height ) / 2 - (tmplabelFontSize  ) ;
      final offset = Offset(xCenter, yCenter);
      textPainter.paint(canvas, offset);
    }

    if( endLabelTextColor != Colors.transparent ) {
      double tmplabelFontSize = ( labelFontSize == 0 ) ? destinationRect.height / 7 : labelFontSize;
      topOffset = tmplabelFontSize;
      TextStyle textStyle = TextStyle(
        color: endLabelTextColor,
        fontSize: tmplabelFontSize,
      );

      // double pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
      String text = startLabelText;
      TextSpan textSpan = TextSpan(
        text: text,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      double xCenter = 5.0;
      double yCenter = (size.height - textPainter.height) / 2 + (tmplabelFontSize /2 )  + 2 ;
      Offset offset = Offset(xCenter, yCenter);
      textPainter.paint(canvas, offset);

      text = endLabelText;
      textSpan = TextSpan(
        text: text,
        style: textStyle,
      );
      final endtextPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      endtextPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      xCenter = destinationRect.width+4;
      yCenter = (size.height - endtextPainter.height) / 2 + (tmplabelFontSize /2 ) + 2 ;
      offset = Offset(xCenter, yCenter);
      endtextPainter.paint(canvas, offset);

    }

////////////////////////
    if( valueTextColor != Colors.transparent ) {
      double tmplabelFontSize = ( labelFontSize == 0 ) ? destinationRect.height / 7 : labelFontSize;

      TextStyle textStyle = TextStyle(
        color: valueTextColor,
        fontSize: tmplabelFontSize * 1.5,
      );

      String text = nameText;
      TextSpan textSpan = TextSpan(
        text: text,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      final xCenter = (size.width - textPainter.width) / 2;
      final yCenter = (size.height - textPainter.height ) / 2 - (tmplabelFontSize /2 ) + topOffset *3  ;
      final offset = Offset(xCenter, yCenter);
      textPainter.paint(canvas, offset);
    }

  }

  @override
  bool shouldRepaint(covariant DLArcPainter oldDelegate) {
    return oldDelegate.top != top ||
        oldDelegate.left != left ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
    // || oldDelegate.image != image;
  }
}

class DLArcWidget extends StatefulWidget {
  // final String path;
  //final double curValue, minValue, maxValue, warnLow, warnHigh;
  final Datapoint datapoint;
  final Color color;
  final Color colorBG;
  final Color colorArc;
  final Color colorArcWarn;
  final Color valueTextColor;
  final Color endlabelTextColor;
  final String startlabelText;
  final String endlabelText;
  final double labelFontSize;
  final String nameText;
  final int cornerRadius;
  //final int decimals;

  const DLArcWidget( // this.path,
      this.datapoint,
      //this.curValue, this.minValue, this.maxValue, this.warnLow, this.warnHigh,
      this.color,
      {super.key,
        this.colorBG = Colors.grey,
        this.colorArc = Colors.green,
        this.colorArcWarn = Colors.red,
        this.valueTextColor = Colors.white,
        this.endlabelTextColor = Colors.white,
        this.startlabelText = "",
        this.endlabelText = "",
        this.labelFontSize = 0,
        this.nameText = "",
        this.cornerRadius = 0,
        //this.decimals = 0,
      });

  @override
  createState() => _DLArcWidgetState();
}

class _DLArcWidgetState extends State<DLArcWidget> {
  // ui.Image? _image;
  double distance = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    distance = widget.datapoint.distance();
    String errMsg = "";

    if( widget.datapoint.isSensor() && widget.datapoint.min == widget.datapoint.max )
    {
      String name = widget.datapoint.labelNoOverride.replaceAll( 'SEN', 'Sensor ');
      errMsg = "$name is not setup properly.";
    }


    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {

          // Scale image to display rectangle
          double radians =  ((widget.datapoint.value - widget.datapoint.min) / distance) * 6.28318530717958647692;
          //String decimalVal = widget.datapoint.getDecimaled();


          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CustomPaint(
                    painter: DLArcPainter(
                      //image: _image!,
                      top: 0,
                      left: 0,
                      width: constraints.maxWidth.toDouble(),
                      height: constraints.maxHeight.toDouble(),
                      datapoint: widget.datapoint,
                      angle: radians,
                      color: widget.color,
                      colorBG: widget.colorBG,
                      colorArc: widget.colorArc,
                      colorArcWarn: widget.colorArcWarn,
                      valueTextColor: widget.valueTextColor,
                      endLabelTextColor:  widget.endlabelTextColor,
                      startLabelText: widget.startlabelText,
                      endLabelText: widget.endlabelText,
                      nameText: widget.nameText,
                      labelFontSize: widget.labelFontSize,
                      cornerRadius: widget.cornerRadius,
                      errMsg: errMsg,
                    ),
                    size: Size( constraints.maxWidth, constraints.maxHeight ),
                  ),
                ),
              ),
            ],
          );
        }// builder:
    );
  } // Build
}
