import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'media_validation.dart';

/// Enhanced media upload helper for images and videos
class MediaUploadHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick multiple images from gallery
  static Future<List<MediaFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80, // Compress images to reduce size
        maxHeight: 1920,
        maxWidth: 1920,
      );

      List<MediaFile> mediaFiles = [];
      
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final validation = MediaValidation.validateImageBytes(bytes, image.name);
        
        if (validation.isValid) {
          mediaFiles.add(MediaFile(
            name: image.name,
            bytes: bytes,
            type: 'image',
          ));
        } else {
          // If validation fails, you might want to show error to user
          print('Image validation failed: ${validation.errorMessage}');
        }
      }

      return mediaFiles;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  /// Pick single image from gallery
  static Future<MediaFile?> pickSingleImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxHeight: 1920,
        maxWidth: 1920,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final validation = MediaValidation.validateImageBytes(bytes, image.name);
        
        if (validation.isValid) {
          return MediaFile(
            name: image.name,
            bytes: bytes,
            type: 'image',
          );
        } else {
          print('Image validation failed: ${validation.errorMessage}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error picking single image: $e');
      return null;
    }
  }

  /// Capture image from camera
  static Future<MediaFile?> captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxHeight: 1920,
        maxWidth: 1920,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final validation = MediaValidation.validateImageBytes(bytes, image.name);
        
        if (validation.isValid) {
          return MediaFile(
            name: image.name,
            bytes: bytes,
            type: 'image',
          );
        } else {
          print('Image validation failed: ${validation.errorMessage}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Pick video file
  static Future<MediaFile?> pickVideo() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        allowedExtensions: ['mp4'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.bytes != null) {
          // Check format
          if (!MediaValidation.isVideoFormatValid(file.name)) {
            print('Video validation failed: Unsupported format');
            return null;
          }
          
          // Check size
          if (!MediaValidation.isVideoSizeValid(file.bytes!.length)) {
            print('Video validation failed: File too large');
            return null;
          }
          
          return MediaFile(
            name: file.name,
            bytes: file.bytes!,
            type: 'video',
          );
        }
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Get image dimensions (basic implementation)
  static Future<Map<String, int>?> getImageDimensions(Uint8List imageBytes) async {
    try {
      // This is a simplified implementation
      // You might want to use a more sophisticated image processing library
      return {'width': 0, 'height': 0};
    } catch (e) {
      print('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Compress image if needed
  static Future<Uint8List?> compressImage(Uint8List imageBytes, {int quality = 80}) async {
    try {
      // For now, return original bytes
      // In a real implementation, you'd use image compression libraries
      return imageBytes;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Generate thumbnail for video
  static Future<Uint8List?> generateVideoThumbnail(Uint8List videoBytes) async {
    try {
      // This would require a video processing library
      // For now, return null
      return null;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Upload result wrapper
  static Future<MediaUploadResult> uploadMultipleImages({
    int maxImages = 10,
  }) async {
    try {
      final mediaFiles = await pickMultipleImages();
      
      if (mediaFiles.isEmpty) {
        return MediaUploadResult(
          success: false,
          message: 'لم يتم اختيار أي صور',
        );
      }

      if (mediaFiles.length > maxImages) {
        return MediaUploadResult(
          success: false,
          message: 'لا يمكن اختيار أكثر من $maxImages صور',
        );
      }

      final validation = MediaValidation.validateImageList(mediaFiles);
      if (!validation.isValid) {
        return MediaUploadResult(
          success: false,
          message: validation.errorMessage ?? 'فشل في التحقق من الصور',
        );
      }

      return MediaUploadResult(
        success: true,
        mediaFiles: mediaFiles,
      );
    } catch (e) {
      return MediaUploadResult(
        success: false,
        message: 'حدث خطأ أثناء رفع الصور',
      );
    }
  }

  /// Upload single image result
  static Future<MediaUploadResult> uploadSingleImage({bool fromCamera = false}) async {
    try {
      final MediaFile? mediaFile = fromCamera 
          ? await captureImage() 
          : await pickSingleImage();
      
      if (mediaFile == null) {
        return MediaUploadResult(
          success: false,
          message: 'لم يتم اختيار صورة',
        );
      }

      return MediaUploadResult(
        success: true,
        mediaFiles: [mediaFile],
      );
    } catch (e) {
      return MediaUploadResult(
        success: false,
        message: 'حدث خطأ أثناء رفع الصورة',
      );
    }
  }

  /// Upload video result
  static Future<MediaUploadResult> uploadVideo() async {
    try {
      final MediaFile? mediaFile = await pickVideo();
      
      if (mediaFile == null) {
        return MediaUploadResult(
          success: false,
          message: 'لم يتم اختيار فيديو',
        );
      }

      return MediaUploadResult(
        success: true,
        mediaFiles: [mediaFile],
      );
    } catch (e) {
      return MediaUploadResult(
        success: false,
        message: 'حدث خطأ أثناء رفع الفيديو',
      );
    }
  }
}

/// Result of media upload operation
class MediaUploadResult {
  final bool success;
  final String? message;
  final List<MediaFile>? mediaFiles;

  MediaUploadResult({
    required this.success,
    this.message,
    this.mediaFiles,
  });
}

