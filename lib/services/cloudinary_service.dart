import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final File file;
  final String url;

  PickedImage({required this.file, required this.url});
}

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'yhlm9yv6',
    'serviko_uploads',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera and upload directly to Cloudinary
  Future<PickedImage?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    String? folder,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );

      return PickedImage(file: file, url: response.secureUrl);
    } catch (e) {
      debugPrint('[CloudinaryService] Upload error: $e');
      return null;
    }
  }

  /// Upload an existing File directly to Cloudinary
  Future<String?> uploadFile(File file, {String? folder}) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('[CloudinaryService] uploadFile error: $e');
      return null;
    }
  }
}
