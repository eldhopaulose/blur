import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../data/models/main_model.dart';

class HomeController extends GetxController {
  final state = EditorState();
  final selectedImage = Rx<File?>(null);
  final screenshotController = ScreenshotController();
  void updateSelectedShapeBlur(double newBlur) {
    if (state.selectedIndex.value >= 0) {
      final index = state.selectedIndex.value;
      final shape = state.shapes[index];
      final oldBlur = shape.blurRadius.value;

      // Create action before modifying the shape
      state.undoStack.add(BlurAction(
        shapeIndex: index,
        oldBlur: oldBlur,
        newBlur: newBlur,
        shape: shape.copyWith(), // Store complete shape state
      ));
      state.redoStack.clear();

      // Update the blur value
      shape.blurRadius.value = newBlur;
      update();
    }
  }

  void undo() {
    if (state.undoStack.isEmpty) return;

    final action = state.undoStack.removeLast();
    if (action.shapeIndex < state.shapes.length) {
      final shape = state.shapes[action.shapeIndex];

      // Save current state for redo
      state.redoStack.add(BlurAction(
        shapeIndex: action.shapeIndex,
        oldBlur: shape.blurRadius.value,
        newBlur: action.oldBlur,
        shape: shape.copyWith(),
      ));

      // Restore old blur value
      shape.blurRadius.value = action.oldBlur;
      update();
    }
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final action = state.redoStack.removeLast();
    if (action.shapeIndex < state.shapes.length) {
      final shape = state.shapes[action.shapeIndex];

      // Save current state for undo
      state.undoStack.add(BlurAction(
        shapeIndex: action.shapeIndex,
        oldBlur: shape.blurRadius.value,
        newBlur: action.newBlur,
        shape: shape.copyWith(),
      ));

      // Apply redo blur value
      shape.blurRadius.value = action.newBlur;
      update();
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
      clearCanvas();
    }
  }

  void clearCanvas() {
    state.shapes.clear();
    state.strokes.clear();
    state.selectedIndex.value = -1;
    state.resizeMode.value = false;
    state.undoStack.clear();
    state.redoStack.clear();
    update();
  }

  void addBrushPoint(Offset point, {bool newStroke = false}) {
    final brushPoint = BrushPoint(
      point: point,
      size: state.brushSize.value,
      blur: state.blur.value,
    );

    if (newStroke) {
      state.strokes.add([brushPoint]);
    } else if (state.strokes.isNotEmpty) {
      state.strokes.last.add(brushPoint);
    }
    update();
  }

  void addCensorShape(Offset position) {
    // Deselect all shapes
    for (final shape in state.shapes) {
      shape.isSelected.value = false;
    }

    final shape = CensorShape(
      type: state.shapeType.value,
      position: position,
      size: Size(state.shapeWidth.value, state.shapeHeight.value),
      blurRadius: state.blur.value,
      isSelected: true,
    );

    state.shapes.add(shape);
    state.selectedIndex.value = state.shapes.length - 1;
    update();
  }

  void selectShape(Offset position) {
    state.selectedIndex.value = -1;
    bool found = false;

    for (var i = state.shapes.length - 1; i >= 0; i--) {
      final shape = state.shapes[i];
      final rect = Rect.fromCenter(
        center: shape.position,
        width: shape.size.width,
        height: shape.size.height,
      );

      if (!found && rect.contains(position)) {
        state.selectedIndex.value = i;
        shape.isSelected.value = true;

        // Update shape dimensions in state
        state.shapeWidth.value = shape.size.width;
        state.shapeHeight.value = shape.size.height;
        found = true;
      } else {
        shape.isSelected.value = false;
      }
    }
    update();
  }

  void updateShapePosition(int index, Offset delta) {
    if (index >= 0 && index < state.shapes.length) {
      final shape = state.shapes[index];
      shape.position = Offset(
        shape.position.dx + delta.dx,
        shape.position.dy + delta.dy,
      );
      update();
    }
  }

  void updateShapeSize(Size newSize) {
    if (state.selectedIndex.value >= 0) {
      final shape = state.shapes[state.selectedIndex.value];
      shape.size = newSize;
      state.shapeWidth.value = newSize.width;
      state.shapeHeight.value = newSize.height;
      update();
    }
  }

  void deleteSelectedShape() {
    if (state.selectedIndex.value >= 0) {
      state.shapes.removeAt(state.selectedIndex.value);
      state.selectedIndex.value = -1;
      update();
    }
  }

  Future<void> saveImage() async {
    if (selectedImage.value == null) return;

    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/blurred_image_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(imagePath);
      await file.writeAsBytes(image);

      Get.snackbar(
        'Success',
        'Image saved successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
