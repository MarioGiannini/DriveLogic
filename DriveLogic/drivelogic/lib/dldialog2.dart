import 'package:flutter/material.dart';
import 'settings2_ui.dart';

void dlDialog2({
  required BuildContext context,
  required List<String> buttons,
  required String dlType,
  required String message,
  required void Function(String result) onResult,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => _DialogOverlay(
        buttons: buttons,
        dlType: dlType,
        message: message,
        onResult: onResult,
      ),
    ),
  );
}

class _DialogOverlay extends StatelessWidget {
  final List<String> buttons;
  final String dlType;
  final String message;
  final void Function(String result) onResult;

  const _DialogOverlay({
    required this.buttons,
    required this.dlType,
    required this.message,
    required this.onResult,
  });

  IconData _getIcon() {
    switch (dlType) {
      case 'Error':
        return Icons.error_outline;
      case 'Warning':
        return Icons.warning_amber_rounded;
      case 'Information':
      default:
        return Icons.info_outline;
    }
  }

  Color _getColor() {
    switch (dlType) {
      case 'Error':
        return Colors.redAccent;
      case 'Warning':
        return Colors.orangeAccent;
      case 'Information':
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: CustomPaint(
          painter: _DialogPainter(borderColor: _getColor()),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(_getIcon(), color: _getColor(), size: 28),
                    const SizedBox(width: 10),
                    Text(
                      dlType,
                      style: const TextStyle( color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle( color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: buttons
                      .map((label) => ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onResult(label);
                    },
                    child: Text(label),
                  ))
                      .toList(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogPainter extends CustomPainter {
  final Color borderColor;

  _DialogPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      const Radius.circular(16),
    );

    final Paint fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    paintSettings2Field( canvas, size,'', 4, Colors.white12, const Color.fromARGB(255, 51, 51, 51), Colors.white);

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
