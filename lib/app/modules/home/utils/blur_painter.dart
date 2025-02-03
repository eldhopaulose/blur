import 'dart:io';

import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../../data/models/main_model.dart';

class BlurPainter extends CustomPainter {
  final File image;
  final EditorState state;
  final ui.Image? cachedImage;

  BlurPainter({
    required this.image,
    required this.state,
    this.cachedImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cachedImage == null) return;

    // Draw shapes
    for (final shape in state.shapes) {
      final rect = Rect.fromCenter(
        center: shape.position,
        width: shape.size.width,
        height: shape.size.height,
      );

      final path = Path();
      switch (shape.type) {
        case ShapeType.rectangle:
          path.addRect(rect);
          break;
        case ShapeType.circle:
          final radius = math.min(shape.size.width, shape.size.height) / 2;
          path.addOval(Rect.fromCircle(
            center: shape.position,
            radius: radius,
          ));
          break;
        case ShapeType.oval:
          path.addOval(rect);
          break;
        case ShapeType.roundedRectangle:
          path.addRRect(RRect.fromRectAndRadius(
            rect,
            const Radius.circular(20),
          ));
          break;
      }

      canvas.saveLayer(rect, Paint());
      canvas.clipPath(path);

      final imagePaint = Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: shape.blurRadius.value,
          sigmaY: shape.blurRadius.value,
        );

      canvas.drawImage(cachedImage!, Offset.zero, imagePaint);
      canvas.restore();

      if (shape.isSelected.value) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.blue
            ..strokeWidth = 2,
        );

        _drawResizeHandles(canvas, rect);
      }
    }

    // Draw brush strokes
    for (final stroke in state.strokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        final current = stroke[i];
        final next = stroke[i + 1];

        final rect = Rect.fromPoints(
          current.point.translate(-current.size, -current.size),
          next.point.translate(next.size, next.size),
        );

        canvas.saveLayer(rect, Paint());

        final path = Path()
          ..moveTo(current.point.dx, current.point.dy)
          ..lineTo(next.point.dx, next.point.dy);

        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = current.size
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, current.blur),
        );

        final imagePaint = Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: current.blur,
            sigmaY: current.blur,
          );

        canvas.drawImage(cachedImage!, Offset.zero, imagePaint);
        canvas.restore();
      }
    }
  }

  void _drawResizeHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    const handleSize = 10.0;
    final handles = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    for (final point in handles) {
      canvas.drawRect(
        Rect.fromCenter(
          center: point,
          width: handleSize,
          height: handleSize,
        ),
        handlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
