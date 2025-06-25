import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'app_ui_supp.dart';

// DLGaugeWidget
//
// DLGaugeWidget('images/OffRoadRearSideProfile.png', -_curValue, _minValue, _maxValue),
// Displays an image rotated by a specific amount.  The angle is calculated
// from cur, min, and max values.  For example, min can be 0 and max 360
// and 180 for curValue would be 180 degrees, or min can be 0 and max can be 100,
// and a value of 50 will give 180 degrees.
//

const radiansInCircle = pi * 2;
const degreesToRadiansScale = pi / 180;
const halfPi = pi / 2;

class DLGaugePainter extends CustomPainter {
  final ui.Image? imageBG;
  final ui.Image? imageNeedle;
  final double needleRadians;
  final DLGaugeWidget widget;
  Offset center = const Offset(0, 0);
  double radius = 0;
  double curValue = 0, maxValue = 0, minValue = 0;

  double tickCount = 0;
  double tickStep = 0;
  double sweepRadian = 0;

  DLGaugePainter({
    required this.widget,
    required this.imageBG,
    required this.imageNeedle,
    required this.needleRadians,
    required this.curValue,
    required this.minValue,
    required this.maxValue,
  });

  void paintLabels(Canvas canvas,Rect destinationRect, Paint paint) {
    List<double> numbers = [];
    for (double v = widget.minValue;
        v <= widget.maxValue;
        v += widget.labelStep) {
      numbers.add(v);
    }

    for (int i = 0; i < tickCount; i++) {
      double angle =
          widget.startAngle * degreesToRadiansScale + (i * tickStep) - (halfPi);
      double x = center.dx + (radius - (widget.labelGap)) * cos(angle);
      double y = center.dy + (radius - (widget.labelGap)) * sin(angle);

      String n = (widget.labelDivisor > 1)
          ? (numbers[i] / widget.labelDivisor)
              .toStringAsFixed(widget.labelDecimals)
          : numbers[i].toStringAsFixed(widget.labelDecimals);

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: n,
          style: TextStyle(
            fontFamily: widget.labelFont,
            color: widget.labelColor,
            fontSize: widget.labelFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      Offset textOffset =
          Offset(x - textPainter.width / 2, y - textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }
  }

  void paintNeedle(
      Canvas canvas, Size size, Paint paint, Rect destinationRect) {
    if (imageNeedle == null) {
      return;
    }

    final double imageWidth = imageNeedle!.width.toDouble();
    final double imageHeight = imageNeedle!.height.toDouble();

    Rect sourceRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
    double ratio = (size.height / 2) / imageHeight;
    Rect destinationRectNew =
        Rect.fromLTWH( 0, 0, imageWidth * ratio, imageHeight * ratio * 0.9);

    final double pivotX = (imageWidth / 2) * ratio;
    final double pivotY = imageHeight * ratio * 0.9;

    canvas.save();
    canvas.translate( destinationRect.left + size.width / 2, destinationRect.top + size.height / 2);
    canvas.rotate(needleRadians);
    canvas.translate(-pivotX, -pivotY);

    canvas.drawImageRect(
      imageNeedle!,
      sourceRect,
      destinationRectNew,
      paint,
    );
    canvas.restore();
  }

  void paintValue(Canvas canvas, Size size) {
    if (widget.textColor != Colors.transparent) {
      TextStyle textStyle = TextStyle(
        fontFamily: 'Exo',
        fontSize: 18.0,
        color: widget.textColor,
        // fontSize: 22,
      );

      String text = "${widget.curValue} / ${widget.minValue} / ${widget.maxValue}";
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
      final yCenter = (size.height - textPainter.height) / 2;
      final offset = Offset(xCenter, yCenter);
      textPainter.paint(canvas, offset);
    } else {
      canvas.restore();
    }
  }

  void paintTicks(Canvas canvas, Rect destinationRect) {
    if (widget.tickColor == Colors.transparent) {
      return;
    }

    final Paint arcPaint = Paint()
      ..color = widget.arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = widget.arcWidth;

    final Paint tickPaint = Paint()
      ..color = widget.tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double width = destinationRect.width;
    final double height = destinationRect.height;
    final Offset center = Offset( destinationRect.left + width / 2, destinationRect.top + height / 2);
    double radius =
        (min(width, height) / 2) - (widget.arcWidth / 2); //widget.tickGap;

    final Rect arcRect =
        Rect.fromCircle(center: center, radius: radius - widget.arcGap);

    //draw arc uses 0 degrees as right of arc.  Convert it here
    double startRadian =
        (widget.startAngle - 0.5 + 270 % 361) * degreesToRadiansScale;

    if (widget.arcWidth > 0) {
      canvas.drawArc(arcRect, startRadian, sweepRadian, false, arcPaint);
      radius -= widget.arcGap;
    }

    for (int i = 0; i < tickCount; i++) {
      double angle =
          widget.startAngle * degreesToRadiansScale + (i * tickStep) - (halfPi);
      double innerX = center.dx + (radius - widget.tickLengthLong) * cos(angle);
      double innerY = center.dy + (radius - widget.tickLengthLong) * sin(angle);
      double outerX = center.dx + radius * cos(angle);
      double outerY = center.dy + radius * sin(angle);
      canvas.drawLine(
          Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);

      // Draw short ticks
      if (i < tickCount - 1) {
        for (int short = 1; short < widget.tickFractions; short++) {
          double angle = (widget.startAngle) * degreesToRadiansScale +
              (i * tickStep) +
              (tickStep / widget.tickFractions * short) -
              (halfPi);

          double innerX =
              center.dx + (radius - widget.tickLengthShort) * cos(angle);
          double innerY =
              center.dy + (radius - widget.tickLengthShort) * sin(angle);
          double outerX = center.dx + radius * cos(angle);
          double outerY = center.dy + radius * sin(angle);

          canvas.drawLine(
              Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
        }
      }
    }
  }
  @override
  void paint( Canvas canvas, Size size ) {
    Rect destinationRect = Rect.fromLTWH(0, 0, size.width, size.height);
    if( widget.bevelWidth > 0 )
    {
      paintBevel(canvas, size);
      destinationRect = Rect.fromLTWH(widget.bevelWidth, widget.bevelWidth,
          size.width-widget.bevelWidth*2, size.height-widget.bevelWidth*2);
    }
    paintGauge(canvas, destinationRect);
  }

  void paintBevel(Canvas canvas, Size size) {

    final Offset center = size.center(Offset.zero);
    double radius = size.shortestSide / 2 - widget.bevelWidth / (widget.bevelType == DLBevelType.both ? 4 : 2 );

    if( widget.bevelOuterStrokeColor != Colors.transparent ) {
      final Paint basePaint =
      Paint()
        ..color = widget.bevelOuterStrokeColor.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, size.shortestSide / 2, basePaint);
      radius -= 0.5;
    }

    // Base shape stroke
    if ( widget.bevelType == DLBevelType.both) {
      final Paint basePaint =
      Paint()
        ..color = widget.bevelColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = widget.bevelWidth / 2 ;
      canvas.drawCircle(center, radius - widget.bevelWidth/2+2, basePaint);
    }

    if ( widget.bevelLightSource == -1) {
      return;
    }

    int innerLightSource =  widget.bevelLightSource;
    int lightSource = ( widget.bevelLightSource+180) % 360;

    double curStrokeWidth = widget.bevelWidth -
        (widget.bevelType == DLBevelType.both
            ? widget.bevelWidth / 2
            : 0); // Fake inner + outer bevel

    Color lighten(Color color, [double amount = 0.1]) {
      final hsl = HSLColor.fromColor(color);
      final hslLight = hsl.withLightness(
        (hsl.lightness + amount).clamp(0.0, 1.0),
      );
      return hslLight.toColor();
    }

    Color darken(Color color, [double amount = 0.1]) {
      final hsl = HSLColor.fromColor(color);
      final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
      return hslDark.toColor();
    }

    Color darker = darken(widget.bevelColor, .2);
    Color lighter = lighten(widget.bevelColor, .2);

    final Rect gradientRect = Rect.fromCircle(center: center, radius: radius);

    if( widget.bevelType == DLBevelType.outer || widget.bevelType == DLBevelType.both || widget.bevelType == DLBevelType.inner) {

      final Gradient bevelGradient = SweepGradient(
        transform: GradientRotation(( ( widget.bevelType == DLBevelType.inner ? innerLightSource : lightSource ) - 90) * pi / 180),
        colors: [
          darker, // color.withOpacity(0.6),
          widget.bevelColor,
          lighter,
          widget.bevelColor,
          darker,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

      final Paint bevelPaint =
      Paint()
        ..shader = bevelGradient.createShader(gradientRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = curStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bevelPaint);
    }

    if (widget.bevelType == DLBevelType.both ) {
      double lightSource2 = (lightSource + 180) % 360;
      SweepGradient bevelGradient2 = SweepGradient(
        transform: GradientRotation((lightSource2 - 90) * pi / 180),
        colors: [
          darker, // color.withOpacity(0.6),
          widget.bevelColor,
          lighter,
          widget.bevelColor,
          darker,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
      double newRadius = (widget.bevelType == DLBevelType.both
          ? (size.shortestSide-widget.bevelWidth) / 2 - widget.bevelWidth / (widget.bevelType==DLBevelType.both ? 4 : 2 )
          : radius);
      final Paint bevelPaint2 =
      Paint()
        ..shader = bevelGradient2.createShader(gradientRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = curStrokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, newRadius, bevelPaint2);
    }
    if( widget.bevelInnerStrokeColor != Colors.transparent ) {
      final Paint basePaint =
      Paint()
        ..color = widget.bevelInnerStrokeColor.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center,
          radius -
              ( widget.bevelType == DLBevelType.both
                  ? widget.bevelWidth / 1.4
                  : widget.bevelWidth/2 ),
          basePaint);
      radius -= 0.5;
    }
  }

  void paintGauge(Canvas canvas, Rect destinationRect ) {
    Rect sourceRect = Rect.fromLTWH( destinationRect.left, destinationRect.top, destinationRect.width, destinationRect.height);
    Size size = Size(destinationRect.width, destinationRect.height);

    center = Offset( destinationRect.left + size.width / 2, destinationRect.top + size.height / 2);
    radius = (min(size.width, size.height) / 2);

    Paint paint = Paint();

    // draw a circle if user indicates widget has a color
    if (widget.color != Colors.transparent) {
      paint
        ..color = widget.color
        ..style = PaintingStyle.fill;
      double r = max(size.width / 2, size.height / 2);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, paint);
    }

    if (imageBG != null) {
      sourceRect = Rect.fromLTWH(
          0, 0, imageBG!.width.toDouble(), imageBG!.height.toDouble());

      if( widget.backgroundOpacity == 1.0 ) {
        canvas.drawImageRect(
          imageBG!,
          sourceRect,
          destinationRect,
          paint,
        );
      } else {
        canvas.drawImageRect(imageBG!, sourceRect, destinationRect,
            Paint()..color=Color.fromRGBO(0, 0, 0, widget.backgroundOpacity) );
      }
    }

    tickCount = ((widget.maxValue - widget.minValue) / widget.labelStep) + 1;
    if (widget.startAngle >= widget.endAngle && widget.clockwise) {
      sweepRadian = (widget.endAngle + 360 - widget.startAngle + 1) *
          degreesToRadiansScale;
      tickStep = ((360 - (widget.startAngle - widget.endAngle)) *
              degreesToRadiansScale) /
          (tickCount - 1);
    } // else ...
    // TODO: Fill in other start/end/direction sweeps and tickSteps

    tickCount = 0;
    for (double v = widget.minValue;
    v <= widget.maxValue;
    v += widget.labelStep) {
      tickCount++;
    }

    paintTicks(canvas, destinationRect);
    paintLabels(canvas, destinationRect, paint);
    paintNeedle(canvas, size, paint, destinationRect);
    //paintValue( canvas, size );
  }

  @override
  bool shouldRepaint(covariant DLGaugePainter oldDelegate) {
    return oldDelegate.curValue != curValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.widget != widget ||
        oldDelegate.needleRadians != needleRadians ||
        oldDelegate.imageBG != imageBG;
  }
}

class DLGaugeWidget extends StatefulWidget {
  final String pathBG;
  final String pathNeedle;
  final double curValue, minValue, maxValue;
  final Color color;
  final Color textColor;
  final double startAngle;
  final double endAngle;
  final bool clockwise;

  final double opacity;
  final double backgroundOpacity;
  final int labelDivisor;
  final int labelStep;
  final double labelGap;
  final Color labelColor;
  final double labelFontSize;
  final int labelDecimals;
  final String? labelFont;

  final double tickGap;
  final Color tickColor;
  final double tickLengthLong;
  final double tickLengthShort;
  final double tickFractions;

  final double arcWidth;
  final Color arcColor;
  final double arcGap;

  final double bevelWidth;
  final DLBevelType bevelType;
  final Color bevelColor;
  final int bevelLightSource;
  final Color bevelInnerStrokeColor;
  final Color bevelOuterStrokeColor;

  const DLGaugeWidget(
    this.pathBG,
    this.pathNeedle,
    this.curValue,
    this.minValue,
    this.maxValue,
    {
      super.key,
      this.color = Colors.transparent,
      this.textColor = Colors.white,
      this.startAngle = 270,
      this.endAngle = 90,
      this.clockwise = true,
      this.labelDivisor = 1,
      this.opacity = 1.0,
      this.backgroundOpacity = 1.0,
      this.labelGap = 0,
      this.labelStep = 1,
      this.labelColor = Colors.black,
      this.labelFont,
      this.labelFontSize = 16,
      this.labelDecimals = 1,
      this.arcWidth = 4,
      this.arcColor = Colors.red,
      this.arcGap = 0,
      this.tickGap = 0,
      this.tickColor = Colors.red,
      this.tickLengthLong = 16,
      this.tickLengthShort = 8,
      this.tickFractions = 2,
      this.bevelWidth = 0,
      this.bevelType = DLBevelType.none,
      this.bevelColor = Colors.grey,
      this.bevelLightSource = 0,
      this.bevelInnerStrokeColor = Colors.transparent,
      this.bevelOuterStrokeColor = Colors.transparent,
  }
  );

  @override
  createState() => _DLGaugeWidgetState();
}

class _DLGaugeWidgetState extends State<DLGaugeWidget> {
  bool hasImageBG = false;
  bool hasImageNeedle = false;
  double startRadian = 0, endRadian = 0, sweep = 0;

  ui.Image? _imageBG;
  ui.Image? _imageNeedle;
  double valueRange = 0;

  @override
  void initState() {
    super.initState();
    startRadian = (widget.startAngle * 3.14158) / 180;
    endRadian = (widget.endAngle * 3.14158) / 180;
    if (widget.startAngle >= widget.endAngle) {
      sweep = (360 + widget.endAngle - widget.startAngle) / 360.0;
    } else {
      sweep = (widget.endAngle - widget.startAngle) / 360.0;
    }

    _loadImage(widget.pathBG, widget.pathNeedle);
  }

  Future<void> _loadImage(String pathBG, String pathNeedle) async {
    hasImageBG = (pathBG != '');
    hasImageNeedle = (pathNeedle != '');

    final ui.Image? image = await _loadAssetImage(pathBG);
    final ui.Image? imageNeedle = await _loadAssetImage(pathNeedle);
    setState(() {
      _imageBG = image;
      _imageNeedle = imageNeedle;
    });
  }

  Future<ui.Image?> _loadAssetImage(String path) async {
    if (path == '') {
      return null;
    }
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    if ((hasImageBG && _imageBG == null) ||
        (hasImageNeedle && _imageNeedle == null)) {
      return const Center(child: CircularProgressIndicator());
    }

    valueRange = (widget.maxValue - widget.minValue);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double needleRadians =
          ((widget.maxValue - widget.curValue) / valueRange) * radiansInCircle;

      if (widget.clockwise) {
        needleRadians = endRadian - needleRadians * sweep;
      } else {
        needleRadians = needleRadians * sweep + startRadian;
      }

      double width = constraints.maxWidth;
      double height = constraints.maxHeight;
      if (_imageBG != null && _imageBG!.width > 0) {
        width = _imageBG!.width.toDouble();
        height = _imageBG!.height.toDouble();
      }

      return Column(
        children: [
          Expanded(
            child: Center(
              child: Opacity(
                opacity: widget.opacity,
                child: CustomPaint(
                  painter: DLGaugePainter(
                    widget: widget,
                    imageBG: _imageBG,
                    imageNeedle: _imageNeedle,
                    needleRadians: needleRadians,
                    curValue: widget.curValue,
                    minValue: widget.minValue,
                    maxValue: widget.maxValue,
                  ),
                  size: Size(width, height),
                ),
              ),
            ),
          ),
        ],
      );
    } // builder:

        );
  } // Build
}
