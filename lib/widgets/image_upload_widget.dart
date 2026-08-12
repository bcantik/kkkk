import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../config/theme.dart';

/// Lets staff attach a poster/photo to any item from: the desktop file
/// system, the phone's photo gallery, or the camera — per spec
/// ("upload picture from file, photos, or image in desktop or mobile").
/// Shows a live preview before saving.
class ImageUploadWidget extends StatefulWidget {
  final String? initialUrl;
  final String folder;
  final ValueChanged<String> onUploaded;
  const ImageUploadWidget({
    super.key,
    this.initialUrl,
    required this.folder,
    required this.onUploaded,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final _storage = StorageService();
  Uint8List? _previewBytes;
  bool _uploading = false;

  Future<void> _pick(Future<XFile?> Function() picker) async {
    final file = await picker();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _previewBytes = bytes);
    setState(() => _uploading = true);
    try {
      final url = await _storage.uploadImage(file, folder: widget.folder);
      widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.softGrey,
            borderRadius: BorderRadius.circular(12),
            image: _previewBytes != null
                ? DecorationImage(image: MemoryImage(_previewBytes!), fit: BoxFit.cover)
                : (widget.initialUrl != null && widget.initialUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(widget.initialUrl!), fit: BoxFit.cover)
                    : null),
          ),
          child: (_previewBytes == null && (widget.initialUrl == null || widget.initialUrl!.isEmpty))
              ? const Center(
                  child: Icon(Icons.image_outlined, size: 40, color: Colors.grey))
              : (_uploading
                  ? const ColoredBox(
                      color: Colors.black38,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : null),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pick(_storage.pickFromFileSystem),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('From File'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(_storage.pickFromGallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('From Gallery'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(_storage.pickFromCamera),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Camera'),
            ),
          ],
        ),
      ],
    );
  }
}
