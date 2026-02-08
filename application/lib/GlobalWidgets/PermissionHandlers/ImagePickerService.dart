// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:application/GlobalWidgets/PermissionHandlers/ImagePickerService.dart'
    as sheet;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum ImagePickSource { camera, gallery }

class ImagePickService {
  ImagePickService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<File?> pickImage(
    BuildContext context, {
    required ImagePickSource source,
    int compressQuality = 60,
  }) async {
    final ok = await _ensurePermission(context, source: source);
    if (!ok) return null;

    final XFile? picked = await _picker.pickImage(
      source: source == ImagePickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (picked == null) return null;

    return _compress(File(picked.path), quality: compressQuality);
  }

  Future<bool> _ensurePermission(
    BuildContext context, {
    required ImagePickSource source,
  }) async {
    if (source == ImagePickSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;

      await _showPermissionDialog(
        context,
        title: "Camera permission needed",
        message: "Please allow camera access in Settings to take a photo.",
        showSettings: status.isPermanentlyDenied,
      );
      return false;
    }

    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;

    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    await _showPermissionDialog(
      context,
      title: "Gallery permission needed",
      message: "Please allow photo access in Settings to pick an image.",
      showSettings: photos.isPermanentlyDenied || storage.isPermanentlyDenied,
    );
    return false;
  }

  Future<File> _compress(File file, {required int quality}) async {
    final outPath = "${file.absolute.path}_compressed.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: quality,
    );
    return result == null ? file : File(result.path);
  }

  Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool showSettings,
  }) async {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, style: textTheme.headlineMedium),
          content: Text(message, style: textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("Cancel", style: textTheme.labelLarge),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (showSettings) {
                  await openAppSettings();
                }
              },
              child: Text(
                showSettings ? "Open Settings" : "OK",
                style: textTheme.labelLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<ImagePickSource?> showImageSourceSheet(BuildContext context) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  return showModalBottomSheet<ImagePickSource>(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo, color: theme.iconTheme.color),
              title: Text("Gallery", style: textTheme.bodyMedium),
              onTap: () => Navigator.of(ctx).pop(ImagePickSource.gallery),
            ),
            Divider(color: theme.dividerColor, height: 1),
            ListTile(
              leading: Icon(Icons.camera_alt, color: theme.iconTheme.color),
              title: Text("Camera", style: textTheme.bodyMedium),
              onTap: () => Navigator.of(ctx).pop(ImagePickSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class ImagePickerService {
  BuildContext context;
  File? image;

  ImagePickerService({required this.context});
  final _service = ImagePickService();

  Future<void> pickImage() async {
    final src = await sheet.showImageSourceSheet(context);
    if (src == null) return;

    final file = await _service.pickImage(
      context,
      source: src == sheet.ImagePickSource.camera
          ? ImagePickSource.camera
          : ImagePickSource.gallery,
      compressQuality: 60,
    );

    if (!context.mounted) return;
    image = file;
  }
}
