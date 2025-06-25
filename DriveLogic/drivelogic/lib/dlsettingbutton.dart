import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

// DLSettingButtonWidget
//
// DLSettingButtonWidget('images/OffRoadRearSideProfile.png', -_curValue, _minValue, _maxValue),
// Displays an image rotated by a specific amount.  The angle is calculated
// from cur, min, and max values.  For example, min can be 0 and max 360
// and 180 for curValue would be 180 degrees, or min can be 0 and max can be 100,
// and a value of 50 will give 180 degrees.
//


class DLSettingButtonWidget extends StatefulWidget {
  final String path;
  final String pathBG;
  final double width;
  final double height;
  final double backgroundOpacity;
  final void Function(BuildContext, String) callback;
  final String label;

  const DLSettingButtonWidget( this.path, this.label, this.width, this.height,
      this.callback, {
        this.pathBG = '',
        this.backgroundOpacity = 1.0,
        super.key
  });

  @override
  createState() => _DLSettingButtonWidgetState();
}

class _DLSettingButtonWidgetState extends State<DLSettingButtonWidget> {
  ui.Image? _image;
  ui.Image? _imageBG;
  double distance = 0;

  @override
  void initState() {
    super.initState();
       _loadImage(widget.path, widget.pathBG );
  }

  Future<void> _loadImage( String path, String pathBG ) async {
    final image = await _loadAssetImage( path );
    final imageBG = await _loadAssetImage( pathBG );
    setState(() {
      _image = image;
      _imageBG = imageBG;
    });
  }

  Future<ui.Image?> _loadAssetImage(String path) async {
    if( path.isEmpty ) {
      return null;
    }

    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {

    if( _imageBG != null && _image != null ) {

      Widget ch = Stack( children: [
      Opacity(opacity: 0.5, child:
      Container( width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage( widget.pathBG ),
            fit: BoxFit.cover,
          ),
        ),
      ),
      ),

          Container( width: widget.width, height: widget.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage( widget.path ),
                fit: BoxFit.cover,
              ),
            ),
            ),

    ]
      );

      return  GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          widget.callback(context, widget.label);
        }, // Image tapped
        child: ch,
      );
    }

    else {
      Widget ch = Container( width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          //color: Colors.orange.withAlpha(128),
          image: DecorationImage(
            image: AssetImage( widget.path ),
            fit: BoxFit.cover,
          ),
        ),
      );

      return  GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          widget.callback(context, widget.label);
        }, // Image tapped
        child: ch,
      );

    }

  } // Build

}
