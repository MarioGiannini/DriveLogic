import 'package:flutter/material.dart';
import 'settings2_ui.dart';
import 'app_data.dart';

class DLDropdownWidget extends StatefulWidget {
  final List<String> options;
  final String fieldName;
  final String initialValue;
  final MyKeyStringCallback onChanged;
  final bool fillSafeAreaHeight;
  final double gap;
  final Color defaultLineColor;
  final Color lightLineColor;
  final Color backgroundColor;
  final String templateText;


  const DLDropdownWidget({
    super.key,
    required this.options,
    required this.fieldName,
    required this.initialValue,
    required this.onChanged,
    this.fillSafeAreaHeight = false,
    this.gap = 4,
    this.defaultLineColor = Colors.white12,
    this.lightLineColor = Colors.white,
    this.backgroundColor = const Color.fromARGB(255, 51, 51, 51),
    this.templateText = '',
  });

  @override
  createState() => _DLDropdownWidgetState();

}

class _DLDropdownWidgetState extends State<DLDropdownWidget> {
  late String _selected;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

  }

  void _showDropdown(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double width = renderBox.size.width;
    double padding = MediaQuery.of(context).viewPadding.top;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _removeOverlay(),
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: widget.fillSafeAreaHeight ? padding : offset.dy + renderBox.size.height,
              width: width,
              height: widget.fillSafeAreaHeight
                  ? MediaQuery.of(context).size.height
                  : null,
              child: Material(
                elevation: 4,
                color: Colors.grey[800],
                child: Container(
                  constraints: widget.fillSafeAreaHeight
                      ? BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height,
                  )
                      : const BoxConstraints(maxHeight: 300),
                  child: Column(
                    children: [

                  Container(
                      width: double.infinity,
                        color: Colors.grey[700],
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          widget.fieldName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: widget.options.map((option) {
                            final bool isSelected = option == _selected;
                            return ListTile(
                              title: Text(
                                option,
                                style: TextStyle(
                                  color: isSelected ? Colors.yellow : Colors.white,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selected = option;
                                });
                                widget.onChanged( widget.fieldName,option);
                                _removeOverlay();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    _selected = widget.initialValue;
    return GestureDetector(
      onTap: () => _showDropdown(context),
      child: CustomPaint(
        painter: _DropdownPainter( widget ),
          ),
    );
  }
}

class _DropdownPainter extends CustomPainter {
  DLDropdownWidget widget;

  _DropdownPainter(
      this.widget,
      );

  @override
  void paint(Canvas canvas, Size size) {
    paintSettings2Field(canvas, size,
      widget.initialValue,
      widget.gap,
      widget.backgroundColor,
      widget.defaultLineColor,
      widget.lightLineColor,
      textAlign: TextAlign.left,
      withDropdown: true,
      templateText: widget.templateText,
    );

  }

  @override
  bool shouldRepaint(covariant _DropdownPainter oldDelegate) {
    return oldDelegate.widget.initialValue != widget.initialValue;
  }
}
