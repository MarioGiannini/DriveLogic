import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dldatafield.dart';

class DLEditTextDialog extends StatefulWidget {
  final String initialText;
  final String labelText;
  final int maxChars;
  final String valueKey;
  final ValueChanged<String> onSubmitted;
  final double width;
  final double height;

  // New parameters for customization
  final String fontFamily;
  final double labelFontSize;
  final Color labelColor;
  final double editorFontSize;
  final Color editorTextColor;
  final Color editorBackgroundColor;
  final TextInputType keyboardType;

  const DLEditTextDialog({
    super.key,
    required this.initialText,
    required this.labelText,
    required this.onSubmitted,
    this.valueKey = '',
    this.fontFamily = 'ChakraPetch',
    this.labelFontSize = 28.0,
    this.labelColor = Colors.white,
    this.editorFontSize = 22.0,
    this.editorTextColor = Colors.black,
    this.editorBackgroundColor = Colors.white,
    this.maxChars = 255,
    this.width = double.infinity,
    this.height = double.infinity,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<DLEditTextDialog> createState() => _DLEditTextDialogState();
}

class _DLEditTextDialogState extends State<DLEditTextDialog> {
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.initialText;
  }

  void _openDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditTextDialog(
        initialText: _currentText,
        labelText: '${widget.labelText}:',
        labelFontSize: widget.labelFontSize,
        labelColor: widget.labelColor,
        editorFontSize: widget.editorFontSize,
        fontFamily: widget.fontFamily,
        editorTextColor: widget.editorTextColor,
        editorBackgroundColor: widget.editorBackgroundColor,
        keyboardType: widget.keyboardType,
        maxChars: widget.maxChars,
      ),
    );

    if (result != null && result != _currentText) {
      setState(() {
        _currentText = result;
      });
      if( widget.valueKey != '') {
        widget.onSubmitted( '${widget.valueKey}:$result' );
      }
      else {
        widget.onSubmitted(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _currentText = widget.initialText;
    return GestureDetector(
      onTap: _openDialog,
      child: SizedBox(
        width: widget.width, height: widget.height,
        child:
            DLDataFieldWidget( _currentText, ),
      ),
    );
  }
}

class _EditTextDialog extends StatefulWidget {
  final String initialText;
  final String fontFamily;
  final String labelText;
  final double labelFontSize;
  final Color labelColor;
  final double editorFontSize;
  final Color editorTextColor;
  final Color editorBackgroundColor;
  final int maxChars;
  final TextInputType keyboardType;

  const _EditTextDialog({
    required this.initialText,
    this.fontFamily = 'ChakraPetch',
    required this.labelText,
    required this.labelFontSize,
    required this.labelColor,
    required this.editorFontSize,
    required this.editorTextColor,
    required this.editorBackgroundColor,
    this.maxChars = 255,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<_EditTextDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
     // Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.of(context).pop(_controller.text);
     // });
  }
  void _cancel() {
    FocusScope.of(context).unfocus();
     // Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.of(context).pop( widget.initialText );
     // });

    //Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    //_controller.text = widget.initialText;
    final double maxEditorWidth = MediaQuery.of(context).size.width * 0.8;
    double editorWidth = min( maxEditorWidth, widget.maxChars * 25 + 20 );
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body:


      Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'images/CheckeredFlagBackground.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Close button
          Positioned(
            top: 0,
            right: 20,
            child: GestureDetector(
              onTap: _cancel,
              child: const Icon(Icons.close, size: 30, color: Colors.white),
            ),
          ),
          // Dialog content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                //mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.labelText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: widget.fontFamily,
                      fontSize: widget.labelFontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.labelColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox( width: editorWidth, height: 50,
                    child:

                    TextField(
                      //keyboardAppearance: Brightness.dark,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                      ],
                      keyboardType: widget.keyboardType,
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: TextStyle(
                        fontFamily: widget.fontFamily,
                        fontSize: widget.editorFontSize,
                        color: widget.editorTextColor,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: widget.editorBackgroundColor,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),


    );
  }
}
