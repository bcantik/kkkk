import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

/// Handles image selection from gallery / camera / file system (works on
/// desktop, mobile and web) and uploads to Supabase Storage.
class StorageService {
  final _client = Supabase.instance.client;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  /// Pick from the phone's photo gallery.
  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

  /// Pick from camera (mobile only — caller should hide this option on desktop/web).
  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera, imageQuality: 85);

  /// Pick any image file from the desktop file system (also works on web/mobile).
  Future<XFile?> pickFromFileSystem() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.bytes != null) {
      return XFile.fromData(f.bytes!,
          name: f.name, mimeType: 'image/${f.extension}');
    } else if (f.path != null) {
      return XFile(f.path!);
    }
    return null;
  }

  /// Uploads bytes to the `item-images` bucket and returns the public URL.
  Future<String> uploadImage(XFile file, {required String folder}) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final path = '$folder/${_uuid.v4()}.$ext';
    await _client.storage.from(SupabaseConfig.itemImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage
        .from(SupabaseConfig.itemImagesBucket)
        .getPublicUrl(path);
  }
}
