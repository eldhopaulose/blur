import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../../data/models/main_model.dart';

class BlurPainter extends CustomPainter {
  final File image;
  final EditorState state;
  final ui.Image? cachedImage;
  final Map<double, ui.ImageFilter> _blurFilterCache = {};

  BlurPainter({
    required this.image,
    required this.state,
    this.cachedImage,
  });

  ui.ImageFilter _getBlurFilter(double sigma) {
    return _blurFilterCache.putIfAbsent(
      sigma,
      () => ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cachedImage == null) return;

    // Draw shapes first
    _drawShapes(canvas, size);

    // Then draw brush strokes
    _drawOptimizedBrushStrokes(canvas, size);
  }

  void _drawShapes(Canvas canvas, Size size) {
    for (final shape in state.shapes) {
      final rect = Rect.fromCenter(
        center: shape.position,
        width: shape.size.width,
        height: shape.size.height,
      );

      if (!rect.overlaps(Offset.zero & size)) continue;

      final path = _getShapePath(shape, rect);

      canvas.saveLayer(rect, Paint());
      canvas.clipPath(path);

      final imagePaint = Paint()
        ..imageFilter = _getBlurFilter(shape.blurRadius.value);

      canvas.drawImage(cachedImage!, Offset.zero, imagePaint);
      canvas.restore();

      if (shape.isSelected.value) {
        _drawSelection(canvas, path, rect);
      }
    }
  }

  void _drawOptimizedBrushStrokes(Canvas canvas, Size size) {
    for (final stroke in state.strokes) {
      if (stroke.isEmpty) continue;

      final path = Path();
      double maxWidth = 0;

      // Create the stroke path
      for (var i = 0; i < stroke.length - 1; i++) {
        final current = stroke[i];
        final next = stroke[i + 1];

        path.moveTo(current.point.dx, current.point.dy);
        path.lineTo(next.point.dx, next.point.dy);
        maxWidth = math.max(maxWidth, current.size);
      }

      // Get the bounds of the stroke with padding for the blur
      final bounds = path.getBounds();
      final blurPadding = stroke[0].blur * 2; // Add padding for blur effect
      final paddedRect = Rect.fromLTWH(
        bounds.left - blurPadding - maxWidth,
        bounds.top - blurPadding - maxWidth,
        bounds.width + (blurPadding + maxWidth) * 2,
        bounds.height + (blurPadding + maxWidth) * 2,
      );

      if (!paddedRect.overlaps(Offset.zero & size)) continue;

      // Draw the blurred stroke
      canvas.saveLayer(paddedRect, Paint());

      // Draw the stroke mask
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..strokeWidth = stroke[0].size
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke[0].blur / 2),
      );

      // Draw the blurred image clipped to the stroke
      final imagePaint = Paint()
        ..imageFilter = _getBlurFilter(stroke[0].blur)
        ..blendMode =
            BlendMode.srcIn; // This ensures we only blur where the stroke is

      canvas.drawImage(cachedImage!, Offset.zero, imagePaint);

      canvas.restore();
    }
  }

  Path _getShapePath(CensorShape shape, Rect rect) {
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
    return path;
  }

  void _drawSelection(Canvas canvas, Path path, Rect rect) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.blue
        ..strokeWidth = 2,
    );
    _drawResizeHandles(canvas, rect);
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
