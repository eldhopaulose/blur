import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import '../../../data/models/main_model.dart';
import '../controllers/home_controller.dart';
import '../utils/blur_painter.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  Widget _buildShapeButton(
    HomeController controller,
    ShapeType type,
    IconData icon,
  ) {
    return Obx(() => IconButton(
          icon: Icon(icon),
          color: controller.state.shapeType.value == type &&
                  controller.state.tool.value == Tool.shape
              ? Colors.blue
              : Colors.grey,
          onPressed: () {
            controller.state.tool.value = Tool.shape;
            controller.state.shapeType.value = type;
            controller.update();
          },
          tooltip: type.toString().split('.').last,
        ));
  }

  Widget _buildImageView(HomeController controller) {
    return Obx(() {
      if (controller.selectedImage.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No image selected',
                style: Theme.of(Get.context!).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: controller.pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select Image'),
              ),
            ],
          ),
        );
      }

      return GetBuilder<HomeController>(
        builder: (controller) => GestureDetector(
          onPanStart: (details) {
            controller.state.isDragging.value = true;
            if (controller.state.tool.value == Tool.brush) {
              controller.addBrushPoint(details.localPosition, newStroke: true);
            } else {
              if (!controller.state.resizeMode.value) {
                controller.selectShape(details.localPosition);
                if (controller.state.selectedIndex.value == -1) {
                  controller.addCensorShape(details.localPosition);
                }
              }
            }
          },
          onPanUpdate: (details) {
            if (!controller.state.isDragging.value) return;

            if (controller.state.tool.value == Tool.brush) {
              controller.addBrushPoint(details.localPosition);
            } else if (controller.state.selectedIndex.value >= 0) {
              controller.updateShapePosition(
                controller.state.selectedIndex.value,
                details.delta,
              );
            }
          },
          onPanEnd: (_) {
            controller.state.isDragging.value = false;
            controller.state.activeHandle.value = ResizeHandle.none;
          },
          child: Screenshot(
            controller: controller.screenshotController,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  controller.selectedImage.value!,
                  fit: BoxFit.contain,
                ),
                Positioned.fill(
                  child: FutureBuilder<ui.Image>(
                    future: _loadImage(controller.selectedImage.value!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return CustomPaint(
                        painter: BlurPainter(
                          image: controller.selectedImage.value!,
                          state: controller.state,
                          cachedImage: snapshot.data,
                        ),
                        isComplex: true,
                        willChange: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildToolbar(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Obx(() => IconButton(
                    icon: const Icon(Icons.brush),
                    color: controller.state.tool.value == Tool.brush
                        ? Colors.blue
                        : Colors.grey,
                    onPressed: () {
                      controller.state.tool.value = Tool.brush;
                      controller.update();
                    },
                    tooltip: 'Brush Tool',
                  )),
              _buildShapeButton(
                controller,
                ShapeType.rectangle,
                Icons.crop_square,
              ),
              _buildShapeButton(
                controller,
                ShapeType.circle,
                Icons.circle_outlined,
              ),
              _buildShapeButton(
                controller,
                ShapeType.oval,
                Icons.panorama_fish_eye,
              ),
              _buildShapeButton(
                controller,
                ShapeType.roundedRectangle,
                Icons.crop_7_5,
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: controller.undo,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: controller.redo,
                tooltip: 'Redo',
              ),
            ],
          ),
          _buildShapeControls(controller),
          _buildBlurSlider(controller),
          _buildBrushSizeSlider(controller),
        ],
      ),
    );
  }

  Widget _buildShapeControls(HomeController controller) {
    return Obx(() {
      if (controller.state.selectedIndex.value >= 0 &&
          controller.state.tool.value == Tool.shape) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                const Text('Width:'),
                Expanded(
                  child: Slider(
                    value: controller.state.shapeWidth.value,
                    min: 20,
                    max: 500,
                    onChanged: (value) {
                      controller.updateShapeSize(Size(
                        value,
                        controller.state.shapeHeight.value,
                      ));
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${controller.state.shapeWidth.value.toInt()}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 16),
                const Text('Height:'),
                Expanded(
                  child: Slider(
                    value: controller.state.shapeHeight.value,
                    min: 20,
                    max: 500,
                    onChanged: (value) {
                      controller.updateShapeSize(Size(
                        controller.state.shapeWidth.value,
                        value,
                      ));
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${controller.state.shapeHeight.value.toInt()}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildBlurSlider(HomeController controller) {
    return Obx(() => Row(
          children: [
            const SizedBox(width: 16),
            const Text('Blur:'),
            Expanded(
              child: Slider(
                value: controller.state.selectedIndex.value >= 0
                    ? controller
                        .state
                        .shapes[controller.state.selectedIndex.value]
                        .blurRadius
                        .value
                    : controller.state.blur.value,
                min: 1,
                max: 50,
                onChanged: (value) {
                  if (controller.state.selectedIndex.value >= 0) {
                    controller.updateSelectedShapeBlur(value);
                  } else {
                    controller.state.blur.value = value;
                  }
                  controller.update();
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${(controller.state.selectedIndex.value >= 0 ? controller.state.shapes[controller.state.selectedIndex.value].blurRadius.value : controller.state.blur.value).toInt()}',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ));
  }

  Widget _buildBrushSizeSlider(HomeController controller) {
    return Obx(() {
      if (controller.state.tool.value == Tool.brush) {
        return Row(
          children: [
            const SizedBox(width: 16),
            const Text('Size:'),
            Expanded(
              child: Slider(
                value: controller.state.brushSize.value,
                min: 5,
                max: 100,
                onChanged: (value) {
                  controller.state.brushSize.value = value;
                  controller.update();
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${controller.state.brushSize.value.toInt()}',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Blur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveImage,
            tooltip: 'Save Image',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: controller.deleteSelectedShape,
            tooltip: 'Delete Selected Shape',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildImageView(controller),
          ),
          _buildToolbar(controller),
        ],
      ),
      floatingActionButton: Obx(() => controller.selectedImage.value == null
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: controller.pickImage,
              child: const Icon(Icons.add_photo_alternate),
              tooltip: 'Select New Image',
            )),
    );
  }
}

Future<ui.Image> _loadImage(File file) async {
  final data = await file.readAsBytes();
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(data, completer.complete);
  return completer.future;
}
