import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
// DLImageRotatorWidget
//
// DLImageRotatorWidget('images/OffRoadRearSideProfile.png', -_curValue, _minValue, _maxValue),
// Displays an image rotated by a specific amount.  The angle is calculated
// from cur, min, and max values.  For example, min can be 0 and max 360
// and 180 for curValue would be 180 degrees, or min can be 0 and max can be 100,
// and a value of 50 will give 180 degrees.
//

class DLImageRotatorPainter extends CustomPainter {
  final ui.Image image;
  final double top;
  final double left;
  final double width;
  final double height;
  final double angle;
  final Color color;
  final Color textColor;

  DLImageRotatorPainter({
    required this.image,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.angle,
    required this.color,
    required this.textColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect sourceRect = Rect.fromLTWH(left, top, width, height);
    Rect destinationRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.save();
    canvas.translate( size.width / 2, size.height / 2);
    canvas.rotate( angle );
    canvas.translate( -size.width / 2, -size.height / 2);

    if( color != Colors.transparent ) {
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      double r = max(size.width / 2, size.height / 2);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, paint);
      destinationRect = Rect.fromLTWH(
          size.width * .1, size.height * .1, size.width * .8, size.height * .8);
    }

    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint(),
    );
    if( textColor != Colors.transparent ) {
      TextStyle textStyle = TextStyle(
        color: textColor,
        fontSize: 22,
      );
      const c = 180.0 / 3.14159265;
      String text = '${(angle * c).round()}\u00B0';
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

      canvas.restore();
      final xCenter = (size.width - textPainter.width) / 2;
      final yCenter = (size.height - textPainter.height) / 2;
      final offset = Offset(xCenter, yCenter);
      textPainter.paint(canvas, offset);
    }
    else {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DLImageRotatorPainter oldDelegate) {
    return oldDelegate.top != top ||
        oldDelegate.left != left ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.image != image;
  }
}

class DLImageRotatorWidget extends StatefulWidget {
  final String path;
  final double curValue, minValue, maxValue;
  final Color color;
  final Color textColor;

  const DLImageRotatorWidget( this.path, this.curValue, this.minValue, this.maxValue, this.color, {super.key, this.textColor = Colors.white});

  @override
  createState() => _DLImageRotatorWidgetState();
}

class _DLImageRotatorWidgetState extends State<DLImageRotatorWidget> {
  ui.Image? _image;
  double distance = 0;

  @override
  void initState() {
    super.initState();

    _loadImage( widget.path );
  }

  Future<void> _loadImage( String path ) async {
    final image = await _loadAssetImage( path );
    setState(() {
      _image = image;
    });
  }

  Future<ui.Image> _loadAssetImage(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    distance = ((widget.maxValue - widget.minValue) + 1);
    if( _image == null ) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {

          // double srad = 0.7853985000000001;
          // double ssin = 0.7071070192004544; // sin( srad );
          // double scos = 0.7071065431725605; // cos( srad );
          double rotatedW = ( _image!.width * 0.7071065431725605 ).abs() + (_image!.height * 0.7071070192004544 ).abs();
          double rotatedH = ( _image!.width * 0.7071070192004544 ).abs() + (_image!.height * 0.7071065431725605 ).abs();

          // Scale image to display rectangle
          double scale = constraints.maxWidth / rotatedW;
          if (scale * rotatedW > constraints.maxHeight)
          {
            scale = constraints.maxHeight / rotatedH;
          }

          double radians =  ((widget.curValue - widget.minValue) / distance) * 6.28318530717958647692;

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CustomPaint(
                    painter: DLImageRotatorPainter(
                        image: _image!,
                        top: 0,
                        left: 0,
                        width: _image!.width.toDouble(),
                        height: _image!.height.toDouble(),
                        angle: radians,
                        color: widget.color,
                        textColor: widget.textColor,
                    ),
                    size: Size( _image!.width  * scale, _image!.height * scale ),
                  ),
                ),
              ),
            ],
          );

        }// builder:

    );

  } // Build
}
