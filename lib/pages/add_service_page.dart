import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:io';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/service_provider_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import '../image_upload.dart';
import '../utils/media_validation.dart';
import '../utils/media_upload_helper.dart';
import '../widgets/media_carousel.dart';
import '../widgets/service_confirmation_dialog.dart';

class AddServicePage extends ConsumerStatefulWidget {
  const AddServicePage({super.key});

  @override
  ConsumerState<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends ConsumerState<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _jicsController = TextEditingController();
  
  String _selectedServiceType = 'grooming';
  String _selectedCity = 'الرياض';
  bool _isLoading = false;
  Uint8List? _imageBytes;
  String? _imageUrl;
  List<Map<String, dynamic>> _warehouseServices = [];
  Map<String, dynamic>? _selectedWarehouseService;
  bool _isLoadingWarehouse = false;
  String? _warehouseId;
  String? _internalCode;
  
  // New media upload properties
  List<MediaFile> _selectedImages = [];
  MediaFile? _selectedVideo;
  bool _isUploadingMedia = false;

  final List<Map<String, dynamic>> _serviceTypes = [
    {'key': 'grooming', 'name': 'خدمات التجميل والعناية', 'icon': Icons.face},
    {'key': 'events', 'name': 'تنظيم المناسبات', 'icon': Icons.celebration},
    {'key': 'technology', 'name': 'الخدمات التقنية', 'icon': Icons.computer},
    {'key': 'education', 'name': 'التعليم والتدريب', 'icon': Icons.school},
    {'key': 'health', 'name': 'الصحة والعافية', 'icon': Icons.healing},
    {'key': 'home_services', 'name': 'خدمات المنزل', 'icon': Icons.home_repair_service},
    {'key': 'business', 'name': 'الخدمات التجارية', 'icon': Icons.business},
    {'key': 'transportation', 'name': 'النقل والمواصلات', 'icon': Icons.directions_car},
    {'key': 'food', 'name': 'الطعام والمأكولات', 'icon': Icons.restaurant},
    {'key': 'other', 'name': 'خدمات أخرى', 'icon': Icons.more_horiz},
  ];

  final List<String> _cities = [
    'الرياض',
    'جدة',
    'الدمام',
    'المدينة المنورة',
    'مكة المكرمة',
    'الطائف',
    'بريدة',
    'تبوك',
    'خميس مشيط',
    'الأحساء',
    'حفر الباطن',
    'الجبيل',
    'نجران',
    'أبها',
    'ينبع',
    'الخرج',
    'القطيف',
    'الظهران',
    'الكرك',
    'عرعر',
  ];

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
    _loadWarehouseServices();
  }

  Future<void> _checkApprovalStatus() async {
    // TEMPORARY: Skip approval check to allow new providers to add services
    // TODO: Re-enable approval check when admin panel is fully implemented
    return;
    
    // Original approval check code (commented out):
    // final isApproved = await ServiceProviderService.isApproved();
    // if (!isApproved && mounted) {
    //   _showApprovalRequiredDialog();
    // }
  }

  void _showApprovalRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.pending_actions,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'في انتظار الموافقة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'طلب التسجيل قيد المراجعة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'لا يمكنك إضافة خدمات حتى يتم الموافقة على طلب التسجيل من قبل إدارة JEENA. سيتم إشعارك عند الموافقة على طلبكم.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _quantityController.dispose();
    _jicsController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouseServices() async {
    setState(() => _isLoadingWarehouse = true);
    try {
      final services = await SupabaseConfig.getWarehouseServices();
      setState(() {
        _warehouseServices = services;
        _isLoadingWarehouse = false;
      });
    } catch (e) {
      setState(() => _isLoadingWarehouse = false);
      print('Error loading warehouse services: $e');
    }
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate media requirements
    if (_selectedImages.isEmpty) {
      _showErrorDialog('يجب إضافة صورة واحدة على الأقل للخدمة');
      return;
    }

    // Show confirmation dialog before proceeding
    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    // Extract bytes for the confirmation dialog
    List<Uint8List> imageBytes = _selectedImages.map((media) => media.bytes).toList();
    Uint8List? videoBytes = _selectedVideo?.bytes;
    
    // Get warehouse service name if selected
    String? warehouseServiceName = _selectedWarehouseService != null 
        ? _selectedWarehouseService!['service_name'] 
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ServiceConfirmationDialog(
        serviceName: _nameController.text.trim(),
        serviceDescription: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        duration: int.tryParse(_durationController.text.trim()) ?? 0,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        city: _selectedCity,
        serviceType: _serviceTypes.firstWhere(
          (type) => type['key'] == _selectedServiceType,
          orElse: () => {'name': 'غير محدد'},
        )['name'],
        jicsCode: _jicsController.text.trim().isEmpty ? null : _jicsController.text.trim(),
        images: imageBytes,
        video: videoBytes,
        warehouseServiceName: warehouseServiceName,
        onConfirm: () {
          Navigator.of(context).pop(); // Close confirmation dialog
          _proceedWithSubmission(); // Proceed with actual submission
        },
        onCancel: () {
          Navigator.of(context).pop(); // Close confirmation dialog
        },
      ),
    );
  }

  Future<void> _proceedWithSubmission() async {
    setState(() => _isLoading = true);

    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Validate warehouse service and quantity
      final serviceName = _nameController.text.trim();
      final jicsCode = _jicsController.text.trim();
      final requestedQuantity = int.tryParse(_quantityController.text.trim()) ?? 0;

      if (requestedQuantity <= 0) {
        throw Exception('يرجى إدخال كمية صحيحة');
      }

      final validationResult = await SupabaseConfig.validateServiceFromWarehouse(
        serviceName: serviceName,
        internalCode: jicsCode.isNotEmpty ? jicsCode : null,
        requestedQuantity: requestedQuantity,
      );

      if (validationResult == null) {
        // Service not found in warehouse
        _showWarehouseValidationDialog(
          'الخدمة غير موجودة في المستودع',
          'الخدمة "$serviceName" غير متوفرة في المستودع.\n\nيرجى:',
          [
            'اختيار خدمة أخرى من المستودع',
            'إضافة هذه الخدمة إلى المستودع أولاً',
          ],
        );
        return;
      }

      if (!validationResult['isQuantityValid']) {
        final availableQuantity = validationResult['availableQuantity'];
        _showWarehouseValidationDialog(
          'الكمية المطلوبة غير متوفرة',
          'الكمية المطلوبة ($requestedQuantity) تتجاوز الكمية المتوفرة في المستودع ($availableQuantity).\n\nيرجى:',
          [
            'تقليل الكمية إلى $availableQuantity أو أقل',
            'زيادة المخزون في صفحة المستودع',
          ],
        );
        return;
      }

      // Validate service content quality
      final contentValidation = MediaValidation.validateServiceContent(
        serviceName: serviceName,
        serviceDescription: _descriptionController.text.trim(),
        images: _selectedImages,
        video: _selectedVideo,
      );

      if (!contentValidation.isValid) {
        _showErrorDialog(contentValidation.errorMessage ?? 'فشل في التحقق من جودة المحتوى');
        return;
      }

      setState(() => _isUploadingMedia = true);

      // Upload images
      final imageData = _selectedImages.map((image) => {
        'name': image.name,
        'bytes': image.bytes,
      }).toList();

      final imageUrls = await SupabaseConfig.uploadMultipleImages(user.id, imageData);

      // Upload video if available
      String? videoUrl;
      if (_selectedVideo != null) {
        final videoData = {
          'name': _selectedVideo!.name,
          'bytes': _selectedVideo!.bytes,
        };
        videoUrl = await SupabaseConfig.uploadVideo(user.id, videoData);
      }

      setState(() => _isUploadingMedia = false);

      final warehouseItem = validationResult['warehouseItem'];
      final serviceData = {
        'user_id': user.id,
        'name': serviceName,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'duration_minutes': int.tryParse(_durationController.text.trim()) ?? 0,
        'service_type': _selectedServiceType,
        'city': _selectedCity,
        'quantity': requestedQuantity,
        'is_active': true,
      };

      await SupabaseConfig.createServiceWithMedia(
        serviceData,
        imageUrls,
        videoUrl,
        warehouseItem['id'],
        warehouseItem['internal_code'] ?? jicsCode,
      );

      _showSuccessDialog('تم إضافة الخدمة بنجاح! سيتم مراجعتها من قبل الإدارة قريباً.');
      _clearForm();
      
    } catch (e) {
      _showErrorDialog('فشل في إضافة الخدمة: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingMedia = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _durationController.clear();
    _quantityController.clear();
    _jicsController.clear();
    setState(() {
      _selectedServiceType = 'grooming';
      _selectedCity = 'الرياض';
      _imageBytes = null;
      _imageUrl = null;
      _selectedWarehouseService = null;
      _warehouseId = null;
      _internalCode = null;
      _selectedImages.clear();
      _selectedVideo = null;
      _isUploadingMedia = false;
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'نجح',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'موافق',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'خطأ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'موافق',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarehouseValidationDialog(String title, String message, List<String> options) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...options.map((option) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'تعديل الخدمة',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to warehouse page
              Navigator.of(context).pushNamed('/warehouse');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
            child: const Text('فتح المستودع'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final imageBytes = await ImageUploadHelper.pickImageFromGallery();
    if (imageBytes != null) {
      setState(() => _imageBytes = imageBytes);
    }
  }

  Future<void> _captureImage() async {
    final imageBytes = await ImageUploadHelper.captureImage();
    if (imageBytes != null) {
      setState(() => _imageBytes = imageBytes);
    }
  }

  // New media upload methods
  Future<void> _addImages() async {
    final result = await MediaUploadHelper.uploadMultipleImages(
      maxImages: MediaValidation.maxImageCount - _selectedImages.length,
    );
    
    if (result.success && result.mediaFiles != null) {
      setState(() {
        _selectedImages.addAll(result.mediaFiles!);
      });
    } else if (result.message != null) {
      _showErrorDialog(result.message!);
    }
  }

  Future<void> _addSingleImage({bool fromCamera = false}) async {
    if (_selectedImages.length >= MediaValidation.maxImageCount) {
      _showErrorDialog('لا يمكن إضافة أكثر من ${MediaValidation.maxImageCount} صور');
      return;
    }

    final result = await MediaUploadHelper.uploadSingleImage(fromCamera: fromCamera);
    
    if (result.success && result.mediaFiles != null) {
      setState(() {
        _selectedImages.addAll(result.mediaFiles!);
      });
    } else if (result.message != null) {
      _showErrorDialog(result.message!);
    }
  }

  Future<void> _addVideo() async {
    final result = await MediaUploadHelper.uploadVideo();
    
    if (result.success && result.mediaFiles != null && result.mediaFiles!.isNotEmpty) {
      setState(() {
        _selectedVideo = result.mediaFiles!.first;
      });
    } else if (result.message != null) {
      _showErrorDialog(result.message!);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'إضافة صور ومقاطع فيديو',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكن إضافة 1-10 صور (حد أقصى 5 ميجابايت لكل صورة)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMediaOption(
                  icon: Icons.photo_library,
                  title: 'صور متعددة',
                  subtitle: 'من المعرض',
                  onTap: () {
                    Navigator.pop(context);
                    _addImages();
                  },
                ),
                _buildMediaOption(
                  icon: Icons.camera_alt,
                  title: 'التقاط صورة',
                  subtitle: 'من الكاميرا',
                  onTap: () {
                    Navigator.pop(context);
                    _addSingleImage(fromCamera: true);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.photo,
                  title: 'صورة واحدة',
                  subtitle: 'من المعرض',
                  onTap: () {
                    Navigator.pop(context);
                    _addSingleImage(fromCamera: false);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  title: 'إضافة فيديو',
                  subtitle: 'MP4 (حد أقصى 30 ميجابايت)',
                  onTap: () {
                    Navigator.pop(context);
                    _addVideo();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'إضافة خدمة جديدة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildServiceInfoSection(),
              const SizedBox(height: 24),
              _buildServiceTypeSection(),
              const SizedBox(height: 24),
              _buildDescriptionSection(),
              const SizedBox(height: 24),
              _buildMediaSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_business,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إضافة خدمة جديدة',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أضف خدمة جديدة لعملائك واحصل على المزيد من الطلبات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الخدمة الأساسية',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildWarehouseServiceDropdown(),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _jicsController,
            label: 'رمز JICS (اختياري)',
            icon: Icons.qr_code,
            validator: null,
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _nameController,
            label: 'اسم الخدمة',
            icon: Icons.business,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال اسم الخدمة';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _priceController,
                  label: 'السعر (ريال)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'يرجى إدخال سعر صحيح';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _durationController,
                  label: 'المدة (دقيقة)',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال المدة';
                    }
                    final duration = int.tryParse(value.trim());
                    if (duration == null || duration <= 0) {
                      return 'يرجى إدخال مدة صحيحة';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _quantityController,
            label: 'الكمية المطلوبة',
            icon: Icons.inventory,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال الكمية';
              }
              final quantity = int.tryParse(value.trim());
              if (quantity == null || quantity <= 0) {
                return 'يرجى إدخال كمية صحيحة';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildCityDropdown(),
        ],
      ),
    );
  }

  Widget _buildServiceTypeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع الخدمة',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildServiceTypeGrid(),
        ],
      ),
    );
  }

  Widget _buildServiceTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: _serviceTypes.length,
      itemBuilder: (context, index) {
        final serviceType = _serviceTypes[index];
        final isSelected = _selectedServiceType == serviceType['key'];
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedServiceType = serviceType['key'];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  serviceType['icon'],
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    serviceType['name'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'وصف الخدمة',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال وصف الخدمة';
              }
              if (value.trim().length < 10) {
                return 'يرجى إدخال وصف أكثر تفصيلاً (10 أحرف على الأقل)';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'اكتب وصفاً مفصلاً للخدمة يوضح ما تقدمه للعملاء...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'صور وفيديوهات الخدمة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedImages.isEmpty ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedImages.length}/10',
                  style: TextStyle(
                    color: _selectedImages.isEmpty ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'أضف 1-10 صور (حد أقصى 5 ميجابايت لكل صورة) وفيديو اختياري (MP4, حد أقصى 30 ميجابايت)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Media carousel for images
          if (_selectedImages.isNotEmpty) ...[
            MediaCarousel(
              mediaFiles: _selectedImages,
              height: 200,
              isEditable: true,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 16),
          ],
          
          // Video section
          if (_selectedVideo != null) ...[
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'فيديو تعريفي',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedVideo!.formattedSize,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeVideo,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Upload buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedImages.length < MediaValidation.maxImageCount ? _showImagePicker : null,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(_selectedImages.isEmpty ? 'إضافة صور' : 'إضافة المزيد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedVideo == null ? _addVideo : null,
                  icon: const Icon(Icons.videocam),
                  label: Text(_selectedVideo == null ? 'إضافة فيديو' : 'فيديو مُضاف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedVideo == null 
                        ? Theme.of(context).colorScheme.secondary 
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          // Upload progress
          if (_isUploadingMedia) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'جاري رفع الملفات...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Requirements notice
          if (_selectedImages.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'يجب إضافة صورة واحدة على الأقل للخدمة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: InputDecoration(
        labelText: 'المدينة',
        prefixIcon: Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCity = value;
          });
        }
      },
    );
  }

  Widget _buildWarehouseServiceDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedWarehouseService,
      decoration: InputDecoration(
        labelText: 'اختر من المستودع (اختياري)',
        prefixIcon: Icon(Icons.warehouse, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: _isLoadingWarehouse 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: _warehouseServices.map((service) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: service,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                service['service_name'] ?? 'خدمة غير محددة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (service['internal_code'] != null)
                Text(
                  'JICS: ${service['internal_code']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              Text(
                'متوفر: ${service['quantity'] ?? 0}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedWarehouseService = value;
          if (value != null) {
            _nameController.text = value['service_name'] ?? '';
            _jicsController.text = value['internal_code'] ?? '';
            _warehouseId = value['id'];
            _internalCode = value['internal_code'];
          }
        });
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitService,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إضافة الخدمة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}