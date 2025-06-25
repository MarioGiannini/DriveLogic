import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

// DLImageFrameWidget
//
// DLImageFrameWidget( assetPath, frameCount, curValue, minValue, maxValue, {super.key});
// Implements a control that expects a verical image list from the asset path assetPath,
// and is made up of frameCount subimages arranged vertically.
// The correct frame to display is calculated from curValue which must be between
// minValue and maxValue.
//

class DLImageFramePainter extends CustomPainter {
  final ui.Image image;
  final double top;
  final double left;
  final double width;
  final double height;

  DLImageFramePainter({
    required this.image,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect sourceRect = Rect.fromLTWH(left, top, width, height);
    final Rect destinationRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant DLImageFramePainter oldDelegate) {
    return oldDelegate.top != top ||
        oldDelegate.left != left ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.image != image;
  }
}

class DLImageFrameWidget extends StatefulWidget {
  final String path;
  final int frameCount;
  final double curValue, minValue, maxValue;

  const DLImageFrameWidget( this.path, this.frameCount, this.curValue, this.minValue, this.maxValue, {super.key});

  @override
    createState() => _DLImageFrameWidgetState();
}

class _DLImageFrameWidgetState extends State<DLImageFrameWidget> {
  ui.Image? _image;
  double frameHeight=0, frameWidth=0;
  double jump = 0;

  @override
  void initState() {
    super.initState();
    _loadImage( widget.path );
  }

  Future<void> _loadImage( String path ) async {
    final image = await _loadAssetImage( path );
    setState(() {
      _image = image;
      frameHeight = _image!.height / widget.frameCount;
      frameWidth = _image!.width.toDouble();
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

    if( _image == null ) {
      return const Center(child: CircularProgressIndicator());
    }
    jump = ((widget.maxValue - widget.minValue) + 1) / widget.frameCount;

    int frame  = ((widget.curValue - widget.minValue ) / jump ).round();
    if( frame >= widget.frameCount ) {
      frame = widget.frameCount - 1;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double scale = constraints.maxWidth / frameWidth;
          if (scale * frameHeight > constraints.maxHeight)
          {
            scale = constraints.maxHeight / frameHeight;
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CustomPaint(
                    painter: DLImageFramePainter(
                      image: _image!,
                      top: frame * frameHeight,
                      left: 0,
                      width: frameWidth,
                      height: frameHeight,
                    ),
                    size: Size( frameWidth  * scale, frameHeight * scale ),
                  ),
                ),
              ),
            ],
          );

        }// builder:

    );

  } // Build
}
