import '../models/main_model.dart';

abstract class EditorAction {
  void undo(EditorState state);
  void redo(EditorState state);
}

class ShapeAction extends EditorAction {
  final int? shapeIndex;
  final CensorShape? oldShape;
  final CensorShape? newShape;
  final ActionType type;

  ShapeAction({
    this.shapeIndex,
    this.oldShape,
    this.newShape,
    required this.type,
  });

  @override
  void undo(EditorState state) {
    switch (type) {
      case ActionType.add:
        state.shapes.removeLast();
        state.selectedIndex.value = -1;
        break;
      case ActionType.delete:
        if (oldShape != null) {
          state.shapes.insert(shapeIndex!, oldShape!);
          state.selectedIndex.value = shapeIndex!;
        }
        break;
      case ActionType.modify:
        if (shapeIndex != null && oldShape != null) {
          state.shapes[shapeIndex!] = oldShape!;
          state.selectedIndex.value = shapeIndex!;
          // Update state dimensions if shape is selected
          if (oldShape!.isSelected.value) {
            state.shapeWidth.value = oldShape!.size.width;
            state.shapeHeight.value = oldShape!.size.height;
          }
        }
        break;
    }
  }

  @override
  void redo(EditorState state) {
    switch (type) {
      case ActionType.add:
        if (newShape != null) {
          state.shapes.add(newShape!);
          state.selectedIndex.value = state.shapes.length - 1;
        }
        break;
      case ActionType.delete:
        if (shapeIndex != null) {
          state.shapes.removeAt(shapeIndex!);
          state.selectedIndex.value = -1;
        }
        break;
      case ActionType.modify:
        if (shapeIndex != null && newShape != null) {
          state.shapes[shapeIndex!] = newShape!;
          state.selectedIndex.value = shapeIndex!;
          // Update state dimensions if shape is selected
          if (newShape!.isSelected.value) {
            state.shapeWidth.value = newShape!.size.width;
            state.shapeHeight.value = newShape!.size.height;
          }
        }
        break;
    }
  }
}

class BrushAction extends EditorAction {
  final List<BrushPoint> points;
  final bool isNewStroke;
  final int strokeIndex;

  BrushAction({
    required this.points,
    required this.strokeIndex,
    this.isNewStroke = false,
  });

  @override
  void undo(EditorState state) {
    if (isNewStroke) {
      if (strokeIndex < state.strokes.length) {
        state.strokes.removeAt(strokeIndex);
      }
    } else {
      if (strokeIndex < state.strokes.length) {
        final stroke = state.strokes[strokeIndex];
        for (var i = 0; i < points.length; i++) {
          if (stroke.isNotEmpty) {
            stroke.removeLast();
          }
        }
        if (stroke.isEmpty) {
          state.strokes.removeAt(strokeIndex);
        }
      }
    }
  }

  @override
  void redo(EditorState state) {
    if (isNewStroke) {
      if (strokeIndex <= state.strokes.length) {
        state.strokes.insert(strokeIndex, List<BrushPoint>.from(points));
      }
    } else {
      if (strokeIndex < state.strokes.length) {
        state.strokes[strokeIndex].addAll(points);
      } else {
        state.strokes.add(List<BrushPoint>.from(points));
      }
    }
  }
}

enum ActionType {
  add,
  delete,
  modify,
}
