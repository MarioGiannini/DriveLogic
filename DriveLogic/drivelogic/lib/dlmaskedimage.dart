import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
// DLMaskedImageWidget
//
// DLMaskedImageWidget( 'background.png', 'forgroung.png, 'toolow.png, 'toohigh.png', _curValue, _minValue, _maxValue),
// Displays a portion of a foregroung image over a background image.  Image is masked with polygon
//

const radiansInCircle = pi * 2;
const degreesToRadiansScale = pi / 180;

class DLMaskedImagePainter extends CustomPainter {
  final ui.Image? imageBG;
  final ui.Image? imageFG;
  final ui.Image? imageLow;
  final ui.Image? imageHigh;

  final DLMaskedImageWidget widget;
  double radius = 0;
  double curValue = 0, maxValue = 0, minValue = 0;

  double tickCount = 0;
  double tickStep = 0;
  double sweepRadian = 0;

  DLMaskedImagePainter({
    required this.widget,
    required this.imageBG,
    required this.imageFG,
    required this.imageLow,
    required this.imageHigh,
    required this.curValue,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Rect sourceRect = Rect.fromLTWH(0,0, size.width, size.height);
    Rect destinationRect = Rect.fromLTWH(0, 0, size.width, size.height);

    Paint paint = Paint();

    if( imageBG != null) {
      sourceRect = Rect.fromLTWH(0,0, imageBG!.width.toDouble(), imageBG!.height.toDouble() );

      canvas.drawImageRect(
        imageBG!,
        sourceRect,
        destinationRect,
        paint,
      );

      if( minValue == maxValue ) {
        return;
      }

      double angleTop = 0;
      double angleBottom = 0;
      double midValue = maxValue / 2;

      if( curValue < midValue )
      {
        angleTop = widget.angleSweep * ( (midValue - curValue ) / midValue );
        angleBottom = -angleTop;
      } else {
        angleBottom = widget.angleSweep * ( ( maxValue - curValue ) / midValue );
        angleTop = -angleBottom;

      }

      angleTop = widget.angleSweep * ( (midValue - curValue ) / midValue );
      angleBottom = -angleTop;

      final List<Offset> polygonPoints =  <Offset>[
        const Offset(0, 0),
        Offset(0, size.height ),
        Offset( size.width * (curValue / maxValue) + angleBottom, size.height ),
        Offset( size.width * (curValue / maxValue) + angleTop , 0 ),
        const Offset(0, 0),];

      Path clipPath = Path()..addPolygon(polygonPoints, true);
      canvas.save();
      canvas.clipPath(clipPath);
      //canvas.drawImage(imageFG!, Offset.zero, paint);
      canvas.drawImageRect(
        imageFG!,
        sourceRect,
        destinationRect,
        paint,
      );

      canvas.restore();
    }

  }

  @override
  bool shouldRepaint(covariant DLMaskedImagePainter oldDelegate) {
    return
      oldDelegate.curValue != curValue ||
          oldDelegate.minValue != minValue ||
          oldDelegate.maxValue != maxValue ||
          oldDelegate.widget != widget ||
          oldDelegate.imageBG != imageBG;
  }
}

class DLMaskedImageWidget extends StatefulWidget {
  final String pathBG;
  final String pathFG;
  final String pathLow;
  final String pathHigh;
  final double curValue, minValue, maxValue;
  final double angleSweep;

  const DLMaskedImageWidget( this.pathBG, this.pathFG, this.pathLow, this.pathHigh,
      this.curValue, this.minValue, this.maxValue, this.angleSweep,
      {super.key,
      });

  @override
  createState() => _DLMaskedImageWidgetState();
}

class _DLMaskedImageWidgetState extends State<DLMaskedImageWidget> {
  bool hasImageBG = false;
  bool hasImageFG = false;
  bool hasImageLow = false;
  bool hasImageHigh = false;

  double startRadian = 0, endRadian = 0, sweep = 0;

  ui.Image? _imageBG;
  ui.Image? _imageFG;
  ui.Image? _imageLow;
  ui.Image? _imageHigh;

  double valueRange = 0;

  @override
  void initState() {
    super.initState();
    _loadImage( widget.pathBG, widget.pathFG, widget.pathLow, widget.pathHigh );
  }

  Future<void> _loadImage( String pathBG, String pathFG, String pathLow, String pathHigh ) async {
    hasImageBG = ( pathBG != '' );
    hasImageFG = ( pathFG != '' );
    hasImageLow = ( pathLow != '' );
    hasImageHigh = ( pathHigh != '' );

    final ui.Image? image = await _loadAssetImage( pathBG );
    final ui.Image? imageFG = await _loadAssetImage( pathFG );
    final ui.Image? imageLow = await _loadAssetImage( pathLow );
    final ui.Image? imageHigh = await _loadAssetImage( pathHigh );

    setState(() {
      _imageBG = image;
      _imageFG = imageFG;
      _imageLow = imageLow;
      _imageHigh = imageHigh;
    });
  }

  Future<ui.Image?> _loadAssetImage(String path) async {
    if( path == '' ) {
      return null;
    }
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {

    if( ( hasImageBG && _imageBG == null )
        || ( hasImageFG && _imageFG == null )
        || ( hasImageLow && _imageLow == null )
        || ( hasImageHigh && _imageHigh == null )
    ) {
      return const Center(child: CircularProgressIndicator());
    }

    valueRange = (widget.maxValue - widget.minValue);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {

          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          if( _imageBG != null && _imageBG!.width > 0 ) {
            width = _imageBG!.width.toDouble();
            height = _imageBG!.height.toDouble();
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CustomPaint(
                    painter: DLMaskedImagePainter(
                      widget: widget,
                      imageBG: _imageBG,
                      imageFG: _imageFG,
                      imageLow: _imageLow,
                      imageHigh: _imageHigh,
                      curValue: widget.curValue,
                      minValue: widget.minValue,
                      maxValue: widget.maxValue,
                    ),
                    size: Size( width, height ),
                  ),
                ),
              ),
            ],
          );

        }// builder:

    );

  } // Build
}
