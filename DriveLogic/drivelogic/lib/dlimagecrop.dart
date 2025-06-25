import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DLImageCrop extends StatefulWidget {
  final String file;
  final double aspectRatio;
  final ValueChanged<Rect> onChanged;

  const DLImageCrop({
    super.key,
    required this.file,
    required this.aspectRatio,
    required this.onChanged,
  });

  @override
  State<DLImageCrop> createState() => _DLImageCropState();
}

class _DLImageCropState extends State<DLImageCrop> {
  ui.Image? _image;
  Rect? _selectionRect;
  Offset? _dragStart;
  String? _draggingHandle; // "move", "tl", "tr", "bl", "br"
  late double _imageScale;
  late Offset _imageOffset;
  String lastFile = '';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.file).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if( lastFile != widget.file ) {
      lastFile = widget.file;
      _selectionRect = null;
      _loadImage();
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_image == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final imageSize = Size(_image!.width.toDouble(), _image!.height.toDouble());
        final displaySize = _fitSize(imageSize, Size(constraints.maxWidth, constraints.maxHeight));
        _imageScale = displaySize.width / imageSize.width;
        _imageOffset = Offset(
          (constraints.maxWidth - displaySize.width) / 2,
          (constraints.maxHeight - displaySize.height) / 2,
        );

        _selectionRect ??= _initialSelection(displaySize);

        return GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child:
          Stack(
            children: [
              Positioned(
                left: _imageOffset.dx,
                top: _imageOffset.dy,
                width: displaySize.width,
                height: displaySize.height,
                child: RawImage( image: _image!, fit: BoxFit.contain),// Image.file(File(widget.file), fit: BoxFit.contain),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SelectionPainter(
                    imageOffset: _imageOffset,
                    selectionRect: _selectionRect!,
                    handleSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Size _fitSize(Size source, Size bounds) {
    final aspectSource = source.width / source.height;
    final aspectBounds = bounds.width / bounds.height;

    if (aspectSource > aspectBounds) {
      final width = bounds.width;
      final height = width / aspectSource;
      return Size(width, height);
    } else {
      final height = bounds.height;
      final width = height * aspectSource;
      return Size(width, height);
    }
  }

  Rect _initialSelection(Size displaySize) {
    final displayAspect = displaySize.width / displaySize.height;
    double selWidth, selHeight;

    if (displayAspect > widget.aspectRatio) {
      selHeight = displaySize.height;
      selWidth = selHeight * widget.aspectRatio;
    } else {
      selWidth = displaySize.width;
      selHeight = selWidth / widget.aspectRatio;
    }

    final left = _imageOffset.dx + (displaySize.width - selWidth) / 2;
    final top = _imageOffset.dy + (displaySize.height - selHeight) / 2;
    return Rect.fromLTWH(left, top, selWidth, selHeight);
  }

  void _handlePanStart(DragStartDetails details) {
    final pos = details.localPosition;
    final rect = _selectionRect!;
    const handleRadius = 15;

    Offset topLeft = rect.topLeft;
    Offset topRight = rect.topRight;
    Offset bottomLeft = rect.bottomLeft;
    Offset bottomRight = rect.bottomRight;

    if ((pos - topLeft).distance <= handleRadius) {_draggingHandle = "tl";}
    else if ((pos - topRight).distance <= handleRadius) {_draggingHandle = "tr";}
    else if ((pos - bottomLeft).distance <= handleRadius) {_draggingHandle = "bl";}
    else if ((pos - bottomRight).distance <= handleRadius) {_draggingHandle = "br";}
    else if (rect.contains(pos)) {_draggingHandle = "move";}

    _dragStart = pos;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;

    final delta = details.localPosition - _dragStart!;
    Rect newRect = _selectionRect!;

    switch (_draggingHandle) {
      case "move":
        newRect = newRect.shift(delta);
        break;

      case "tl":
      case "tr":
      case "bl":
      case "br":
        newRect = _resizeRect(_selectionRect!, _draggingHandle!, delta);
        break;
    }

    // Constrain to image display area
    final displayBounds = Rect.fromLTWH(
      _imageOffset.dx, _imageOffset.dy,
      _image!.width * _imageScale, _image!.height * _imageScale,
    );
    newRect = _constrainRectToBounds(newRect, displayBounds);

    setState(() {
      _selectionRect = newRect;
      _dragStart = details.localPosition;
      _emitSelection();
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _dragStart = null;
    _draggingHandle = null;
  }

  Rect _resizeRect(Rect rect, String handle, Offset delta) {
    double width = rect.width;
    double height = rect.height;

    double newWidth, newHeight;
    if (widget.aspectRatio >= 1.0) {
      newWidth = width + (handle.contains('r') ? delta.dx : -delta.dx);
      newHeight = newWidth / widget.aspectRatio;
    } else {
      newHeight = height + (handle.contains('b') ? delta.dy : -delta.dy);
      newWidth = newHeight * widget.aspectRatio;
    }

    double left = rect.left;
    double top = rect.top;

    if (handle.contains('t')) top = rect.bottom - newHeight;
    if (handle.contains('l')) left = rect.right - newWidth;

    return Rect.fromLTWH(left, top, newWidth, newHeight);
  }

  Rect _constrainRectToBounds(Rect rect, Rect bounds) {
    double left = rect.left.clamp(bounds.left, bounds.right - rect.width);
    double top = rect.top.clamp(bounds.top, bounds.bottom - rect.height);
    double right = left + rect.width;
    double bottom = top + rect.height;

    if (right > bounds.right) {
      left = bounds.right - rect.width;
      right = bounds.right;
    }
    if (bottom > bounds.bottom) {
      top = bounds.bottom - rect.height;
      bottom = bounds.bottom;
    }

    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  void _emitSelection() {
    final scale = 1 / _imageScale;
    final x = (_selectionRect!.left - _imageOffset.dx) * scale;
    final y = (_selectionRect!.top - _imageOffset.dy) * scale;
    final w = _selectionRect!.width * scale;
    final h = _selectionRect!.height * scale;

    widget.onChanged(Rect.fromLTWH(x, y, w, h));
  }
}

class _SelectionPainter extends CustomPainter {
  final Rect selectionRect;
  final Offset imageOffset;
  final double handleSize;

  _SelectionPainter({
    required this.selectionRect,
    required this.imageOffset,
    this.handleSize = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Dark overlay
    paint.color = Colors.black.withAlpha(128);
    canvas.drawRect(Rect.fromLTWH(0, 0, selectionRect.left, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(selectionRect.left, 0, selectionRect.width, selectionRect.top), paint);
    canvas.drawRect(Rect.fromLTWH(selectionRect.right, 0, size.width-selectionRect.right, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(selectionRect.left, selectionRect.bottom, selectionRect.width, size.height-selectionRect.bottom), paint);
    //paint.blendMode = BlendMode.clear;
    //canvas.drawRect(selectionRect, paint);

    // White border
    paint
      ..blendMode = BlendMode.srcOver
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(selectionRect, paint);

    // Corner handles
    paint.style = PaintingStyle.fill;
    double sweep =1.571428571428;
    canvas.drawArc(Rect.fromCenter(center: selectionRect.topLeft, width: 24, height: 24), 0.0, sweep, true, paint);
    canvas.drawArc(Rect.fromCenter(center: selectionRect.topRight, width: 24, height: 24), 3.14159 / 2, sweep, true, paint);
    canvas.drawArc(Rect.fromCenter(center: selectionRect.bottomLeft, width: 24, height: 24),  3 * 3.14159 / 2, sweep, true, paint);
    canvas.drawArc(Rect.fromCenter(center: selectionRect.bottomRight, width: 24, height: 24), 2 * 3.14159 / 2, sweep, true, paint);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
