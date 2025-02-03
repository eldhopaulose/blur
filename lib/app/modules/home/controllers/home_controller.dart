import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import '../../../data/helper/editor_action_hlper.dart';
import '../../../data/models/main_model.dart';

class HomeController extends GetxController {
  final state = EditorState();
  final selectedImage = Rx<File?>(null);
  final screenshotController = ScreenshotController();
  Timer? _brushTimer;
  List<BrushPoint> _currentStrokeBuffer = [];

  @override
  void onInit() {
    super.onInit();
    // Check if there's a saved image being opened
    if (Get.arguments != null && Get.arguments is File) {
      selectedImage.value = Get.arguments as File;
      clearCanvas();
    }
  }

  void addBrushPoint(Offset point, {bool newStroke = false}) {
    final brushPoint = BrushPoint(
      point: point,
      size: state.brushSize.value,
      blur: state.blur.value,
    );

    if (newStroke) {
      _currentStrokeBuffer = [brushPoint];
      state.strokes.add(_currentStrokeBuffer);
      state.undoStack.add(BrushAction(
        points: [brushPoint],
        strokeIndex: state.strokes.length - 1,
        isNewStroke: true,
      ));
    } else if (state.strokes.isNotEmpty) {
      _currentStrokeBuffer.add(brushPoint);
      state.strokes.last.add(brushPoint);

      // Throttle the creation of undo actions for brush strokes
      _brushTimer?.cancel();
      _brushTimer = Timer(const Duration(milliseconds: 100), () {
        if (_currentStrokeBuffer.isNotEmpty) {
          state.undoStack.add(BrushAction(
            points: List<BrushPoint>.from(_currentStrokeBuffer),
            strokeIndex: state.strokes.length - 1,
          ));
          _currentStrokeBuffer = [];
        }
      });
    }
    state.redoStack.clear();
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

    state.undoStack.add(ShapeAction(
      newShape: shape.copyWith(),
      type: ActionType.add,
    ));
    state.redoStack.clear();
    update();
  }

  void selectShape(Offset position) {
    final oldSelectedIndex = state.selectedIndex.value;
    CensorShape? oldSelectedShape;
    if (oldSelectedIndex >= 0 && oldSelectedIndex < state.shapes.length) {
      oldSelectedShape = state.shapes[oldSelectedIndex].copyWith();
    }

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
        state.shapeWidth.value = shape.size.width;
        state.shapeHeight.value = shape.size.height;
        found = true;

        // Add to undo stack if we're changing selection
        if (oldSelectedIndex != i) {
          if (oldSelectedShape != null) {
            state.undoStack.add(ShapeAction(
              shapeIndex: oldSelectedIndex,
              oldShape: oldSelectedShape,
              newShape: state.shapes[oldSelectedIndex].copyWith(),
              type: ActionType.modify,
            ));
          }
          state.undoStack.add(ShapeAction(
            shapeIndex: i,
            oldShape: shape.copyWith(isSelected: false),
            newShape: shape.copyWith(),
            type: ActionType.modify,
          ));
          state.redoStack.clear();
        }
      } else {
        shape.isSelected.value = false;
      }
    }
    update();
  }

  void updateShapePosition(int index, Offset delta) {
    if (index >= 0 && index < state.shapes.length) {
      final shape = state.shapes[index];
      final oldShape = shape.copyWith();

      shape.position = Offset(
        shape.position.dx + delta.dx,
        shape.position.dy + delta.dy,
      );

      // Throttle the creation of undo actions for drag operations
      _brushTimer?.cancel();
      _brushTimer = Timer(const Duration(milliseconds: 100), () {
        state.undoStack.add(ShapeAction(
          shapeIndex: index,
          oldShape: oldShape,
          newShape: shape.copyWith(),
          type: ActionType.modify,
        ));
        state.redoStack.clear();
      });

      update();
    }
  }

  void updateShapeSize(Size newSize) {
    if (state.selectedIndex.value >= 0) {
      final index = state.selectedIndex.value;
      final shape = state.shapes[index];
      final oldShape = shape.copyWith();

      shape.size = newSize;
      state.shapeWidth.value = newSize.width;
      state.shapeHeight.value = newSize.height;

      state.undoStack.add(ShapeAction(
        shapeIndex: index,
        oldShape: oldShape,
        newShape: shape.copyWith(),
        type: ActionType.modify,
      ));
      state.redoStack.clear();
      update();
    }
  }

  void updateSelectedShapeBlur(double newBlur) {
    if (state.selectedIndex.value >= 0) {
      final index = state.selectedIndex.value;
      final shape = state.shapes[index];
      final oldShape = shape.copyWith();

      shape.blurRadius.value = newBlur;

      // Throttle the creation of undo actions for blur adjustments
      _brushTimer?.cancel();
      _brushTimer = Timer(const Duration(milliseconds: 100), () {
        state.undoStack.add(ShapeAction(
          shapeIndex: index,
          oldShape: oldShape,
          newShape: shape.copyWith(),
          type: ActionType.modify,
        ));
        state.redoStack.clear();
      });

      update();
    }
  }

  void deleteSelectedShape() {
    if (state.selectedIndex.value >= 0) {
      final index = state.selectedIndex.value;
      final oldShape = state.shapes[index].copyWith();

      state.shapes.removeAt(index);
      state.selectedIndex.value = -1;

      state.undoStack.add(ShapeAction(
        shapeIndex: index,
        oldShape: oldShape,
        type: ActionType.delete,
      ));
      state.redoStack.clear();
      update();
    }
  }

  void undo() {
    if (state.undoStack.isEmpty) return;

    final action = state.undoStack.removeLast();
    action.undo(state);
    state.redoStack.add(action);
    update();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final action = state.redoStack.removeLast();
    action.redo(state);
    state.undoStack.add(action);
    update();
  }

  Future<void> saveImage() async {
    if (selectedImage.value == null) return;

    try {
      state.tool.value = Tool.brush;

      final selectedIndex = state.selectedIndex.value;
      final selectedShape =
          selectedIndex >= 0 ? state.shapes[selectedIndex] : null;
      final wasSelected = selectedShape?.isSelected.value ?? false;

      // Temporarily hide selection
      if (selectedShape != null) {
        selectedShape.isSelected.value = false;
      }

      // Take screenshot
      final image = await screenshotController.capture();

      // Restore selection state
      if (selectedShape != null) {
        selectedShape.isSelected.value = wasSelected;
      }

      if (image == null) return;

      // Save the image
      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/blurred_image_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(imagePath);
      await file.writeAsBytes(image);

      // Show success message
      await Get.snackbar(
        'Success',
        'Image saved successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Wait a brief moment for the snackbar to be visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Return to saved works page and refresh
      if (Get.previousRoute == '/') {
        Get.back(result: true); // Pass true to indicate successful save
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      update(); // Ensure UI is updated
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
    _currentStrokeBuffer.clear();
    _brushTimer?.cancel();
    update();
  }

  @override
  void onClose() {
    _brushTimer?.cancel();
    super.onClose();
  }
}
