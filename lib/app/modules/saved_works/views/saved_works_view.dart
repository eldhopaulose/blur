import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/saved_works_controller.dart';

class SavedWorksView extends GetView<SavedWorksController> {
  const SavedWorksView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SavedWorksController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Works'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: controller.selectDirectory,
            tooltip: 'Select Folder',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCurrentPath(controller),
          Expanded(
            child: _buildImageGrid(controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/home'),
        child: const Icon(Icons.add),
        tooltip: 'New Image',
      ),
    );
  }

  Widget _buildCurrentPath(SavedWorksController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.folder, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => Text(
                  controller.currentPath.value,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(SavedWorksController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.savedImages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No saved images found',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/editor'),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Create New'),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: controller.savedImages.length,
        itemBuilder: (context, index) {
          final image = controller.savedImages[index];
          return _buildImageCard(controller, image);
        },
      );
    });
  }

  Widget _buildImageCard(SavedWorksController controller, File image) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.openImage(image),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                image,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _showDeleteConfirmation(controller, image),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Text(
                image.path.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    SavedWorksController controller,
    File image,
  ) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await controller.deleteImage(image);
    }
  }
}
