import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SavedWorksController extends GetxController {
  final RxList<File> savedImages = <File>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDefaultDirectory();
  }

  Future<void> loadDefaultDirectory() async {
    isLoading.value = true;
    try {
      final directory = await getApplicationDocumentsDirectory();
      currentPath.value = directory.path;
      await loadImagesFromDirectory(directory);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load default directory: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectDirectory() async {
    try {
      if (!await Permission.storage.isGranted) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission Required',
            'Storage permission is required to select folders',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        currentPath.value = selectedDirectory;
        await loadImagesFromDirectory(Directory(selectedDirectory));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to select directory: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> loadImagesFromDirectory(Directory directory) async {
    isLoading.value = true;
    savedImages.clear();

    try {
      final List<FileSystemEntity> entities = await directory.list().toList();
      for (var entity in entities) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith('.png') &&
            entity.path.contains('blurred_image')) {
          savedImages.add(entity);
        }
      }
      savedImages
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load images: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteImage(File image) async {
    try {
      await image.delete();
      savedImages.remove(image);
      Get.snackbar(
        'Success',
        'Image deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void openImage(File image) {
    Get.toNamed('/editor', arguments: image);
  }
}
