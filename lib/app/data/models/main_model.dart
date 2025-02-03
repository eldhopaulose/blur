import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ShapeType { rectangle, circle, oval, roundedRectangle }

enum Tool { brush, shape }

enum ResizeHandle { none, topLeft, topRight, bottomLeft, bottomRight }

class BlurAction {
  final int shapeIndex;
  final double oldBlur;
  final double newBlur;
  final CensorShape shape; // Added to store complete shape state

  BlurAction({
    required this.shapeIndex,
    required this.oldBlur,
    required this.newBlur,
    required this.shape,
  });
}

class BrushPoint {
  final Offset point;
  final double size;
  final double blur;

  BrushPoint({
    required this.point,
    required this.size,
    required this.blur,
  });
}

class CensorShape {
  final ShapeType type;
  Offset position;
  Size size;
  RxDouble blurRadius;
  RxBool isSelected;

  CensorShape({
    required this.type,
    required this.position,
    required this.size,
    double blurRadius = 10.0,
    bool isSelected = false,
  })  : blurRadius = blurRadius.obs,
        isSelected = isSelected.obs;

  CensorShape copyWith({
    ShapeType? type,
    Offset? position,
    Size? size,
    double? blurRadius,
    bool? isSelected,
  }) {
    return CensorShape(
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      blurRadius: blurRadius ?? this.blurRadius.value,
      isSelected: isSelected ?? this.isSelected.value,
    );
  }
}

class EditorState {
  final RxList<CensorShape> shapes;
  final RxList<List<BrushPoint>> strokes;
  final RxDouble blur;
  final RxDouble brushSize;
  final RxDouble shapeWidth;
  final RxDouble shapeHeight;
  final Rx<Tool> tool;
  final Rx<ShapeType> shapeType;
  final RxBool resizeMode;
  final RxInt selectedIndex;
  final RxBool isDragging;
  final RxList<BlurAction> undoStack;
  final RxList<BlurAction> redoStack;
  final Rx<ResizeHandle> activeHandle;

  EditorState()
      : shapes = <CensorShape>[].obs,
        strokes = <List<BrushPoint>>[].obs,
        blur = 10.0.obs,
        brushSize = 30.0.obs,
        shapeWidth = 100.0.obs,
        shapeHeight = 100.0.obs,
        tool = Tool.shape.obs,
        shapeType = ShapeType.rectangle.obs,
        resizeMode = false.obs,
        selectedIndex = (-1).obs,
        isDragging = false.obs,
        undoStack = <BlurAction>[].obs,
        redoStack = <BlurAction>[].obs,
        activeHandle = ResizeHandle.none.obs;
}
