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
        ));
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
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: controller.deleteSelectedShape,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Obx(() {
                if (controller.selectedImage.value == null) {
                  return const Text('No image selected');
                }

                return GetBuilder<HomeController>(
                  builder: (controller) => GestureDetector(
                    onPanStart: (details) {
                      controller.state.isDragging.value = true;
                      if (controller.state.tool.value == Tool.brush) {
                        controller.addBrushPoint(details.localPosition,
                            newStroke: true);
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
                        children: [
                          Image.file(
                            controller.selectedImage.value!,
                            fit: BoxFit.contain,
                          ),
                          Positioned.fill(
                            child: FutureBuilder<ui.Image>(
                              future:
                                  _loadImage(controller.selectedImage.value!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return Container();
                                return CustomPaint(
                                  painter: BlurPainter(
                                    image: controller.selectedImage.value!,
                                    state: controller.state,
                                    cachedImage: snapshot.data,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          _buildToolbar(controller),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.pickImage,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildToolbar(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(8.0),
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
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: controller.redo,
              ),
            ],
          ),
          // Shape controls when shape is selected
          Obx(() {
            if (controller.state.selectedIndex.value >= 0 &&
                controller.state.tool.value == Tool.shape) {
              return Column(
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
                    ],
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          // Blur slider
          Obx(() => Row(
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
                ],
              )),
          // Brush size slider (only show when brush tool is selected)
          Obx(() {
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
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

Future<ui.Image> _loadImage(File file) async {
  final data = await file.readAsBytes();
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(data, completer.complete);
  return completer.future;
}
