import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// Media validation utility for images and videos
class MediaValidation {
  // Size limits
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSizeBytes = 30 * 1024 * 1024; // 30MB
  static const int maxImageCount = 10;
  static const int minImageCount = 1;
  
  // Supported formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedVideoFormats = ['mp4'];
  
  /// Validate image size
  static bool isImageSizeValid(int sizeBytes) {
    return sizeBytes <= maxImageSizeBytes;
  }
  
  /// Validate video size
  static bool isVideoSizeValid(int sizeBytes) {
    return sizeBytes <= maxVideoSizeBytes;
  }
  
  /// Validate image format
  static bool isImageFormatValid(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return supportedImageFormats.contains(extension);
  }
  
  /// Validate video format
  static bool isVideoFormatValid(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return supportedVideoFormats.contains(extension);
  }
  
  /// Validate image count
  static bool isImageCountValid(int count) {
    return count >= minImageCount && count <= maxImageCount;
  }
  
  /// Format file size to human readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  /// Validate uploaded image
  static ValidationResult validateImage(XFile image) {
    // Check format
    if (!isImageFormatValid(image.name)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'صيغة الصورة غير مدعومة. يرجى استخدام JPG, PNG, أو WebP فقط.',
      );
    }
    
    // Check size (if available)
    return ValidationResult(isValid: true);
  }
  
  /// Validate uploaded video
  static ValidationResult validateVideo(File video) {
    // Check format
    if (!isVideoFormatValid(video.path)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'صيغة الفيديو غير مدعومة. يرجى استخدام MP4 فقط.',
      );
    }
    
    // Check size
    final sizeBytes = video.lengthSync();
    if (!isVideoSizeValid(sizeBytes)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'حجم الفيديو كبير جداً. الحد الأقصى ${formatFileSize(maxVideoSizeBytes)}.',
      );
    }
    
    return ValidationResult(isValid: true);
  }
  
  /// Validate image bytes and size
  static ValidationResult validateImageBytes(Uint8List imageBytes, String fileName) {
    // Check format
    if (!isImageFormatValid(fileName)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'صيغة الصورة غير مدعومة. يرجى استخدام JPG, PNG, أو WebP فقط.',
      );
    }
    
    // Check size
    if (!isImageSizeValid(imageBytes.length)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'حجم الصورة كبير جداً. الحد الأقصى ${formatFileSize(maxImageSizeBytes)}.',
      );
    }
    
    return ValidationResult(isValid: true);
  }
  
  /// Validate multiple images
  static ValidationResult validateImageList(List<MediaFile> images) {
    // Check count
    if (!isImageCountValid(images.length)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'عدد الصور يجب أن يكون بين $minImageCount و $maxImageCount صور.',
      );
    }
    
    // Validate each image
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final result = validateImageBytes(image.bytes, image.name);
      if (!result.isValid) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'الصورة ${i + 1}: ${result.errorMessage}',
        );
      }
    }
    
    return ValidationResult(isValid: true);
  }
  
  /// Check if image has clear quality (basic validation)
  static bool isImageQualityGood(Uint8List imageBytes) {
    // Basic quality check - file size should be reasonable for the format
    // This is a simple heuristic - very small files might indicate poor quality
    return imageBytes.length >= 10 * 1024; // At least 10KB
  }
  
  /// Admin validation rules
  static ValidationResult validateServiceContent({
    required String serviceName,
    required String serviceDescription,
    required List<MediaFile> images,
    MediaFile? video,
  }) {
    // Check service name clarity
    if (serviceName.trim().length < 3) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'اسم الخدمة قصير جداً. يجب أن يكون 3 أحرف على الأقل.',
      );
    }
    
    // Check description clarity
    if (serviceDescription.trim().length < 20) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'وصف الخدمة قصير جداً. يجب أن يكون 20 حرف على الأقل.',
      );
    }
    
    // Check for basic grammar indicators (simple checks)
    if (!_hasBasicGrammarStructure(serviceDescription)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'يرجى مراجعة النص للتأكد من سلامة القواعد النحوية.',
      );
    }
    
    // Validate images
    final imageValidation = validateImageList(images);
    if (!imageValidation.isValid) {
      return imageValidation;
    }
    
    // Check image quality
    for (int i = 0; i < images.length; i++) {
      if (!isImageQualityGood(images[i].bytes)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'جودة الصورة ${i + 1} منخفضة. يرجى استخدام صورة بجودة أفضل.',
        );
      }
    }
    
    // Validate video if present
    if (video != null) {
      if (!isVideoFormatValid(video.name)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'صيغة الفيديو غير مدعومة. يرجى استخدام MP4 فقط.',
        );
      }
      
      if (!isVideoSizeValid(video.bytes.length)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'حجم الفيديو كبير جداً. الحد الأقصى ${formatFileSize(maxVideoSizeBytes)}.',
        );
      }
    }
    
    return ValidationResult(isValid: true);
  }
  
  /// Basic grammar structure check (simplified)
  static bool _hasBasicGrammarStructure(String text) {
    // Simple checks for Arabic text structure
    final trimmed = text.trim();
    
    // Should have some basic punctuation or be reasonably long
    if (trimmed.length < 10) return false;
    
    // Should not be all caps (indicates shouting/poor formatting)
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 20) return false;
    
    // Should have some word variety (not just repeated words)
    final words = trimmed.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 3) return false;
    
    // Check for excessive repetition
    final uniqueWords = words.toSet();
    if (uniqueWords.length < words.length * 0.5) return false;
    
    return true;
  }
}

/// Result of validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Media file representation
class MediaFile {
  final String name;
  final Uint8List bytes;
  final String type; // 'image' or 'video'
  
  MediaFile({
    required this.name,
    required this.bytes,
    required this.type,
  });
  
  int get sizeBytes => bytes.length;
  String get formattedSize => MediaValidation.formatFileSize(sizeBytes);
}