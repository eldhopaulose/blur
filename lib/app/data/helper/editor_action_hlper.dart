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
        }
        break;
    }
  }
}

class BrushAction extends EditorAction {
  final List<BrushPoint> points;
  final bool isNewStroke;

  BrushAction({
    required this.points,
    this.isNewStroke = false,
  });

  @override
  void undo(EditorState state) {
    if (isNewStroke) {
      state.strokes.removeLast();
    } else if (state.strokes.isNotEmpty) {
      final stroke = state.strokes.last;
      for (var i = 0; i < points.length; i++) {
        stroke.removeLast();
      }
      if (stroke.isEmpty) {
        state.strokes.removeLast();
      }
    }
  }

  @override
  void redo(EditorState state) {
    if (isNewStroke) {
      state.strokes.add(points);
    } else if (state.strokes.isNotEmpty) {
      state.strokes.last.addAll(points);
    } else {
      state.strokes.add(points);
    }
  }
}

enum ActionType {
  add,
  delete,
  modify,
}
