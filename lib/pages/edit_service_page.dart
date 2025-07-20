import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/service_provider_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import '../utils/media_validation.dart';
import '../utils/media_upload_helper.dart';
import '../widgets/media_carousel.dart';

class EditServicePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> service;

  const EditServicePage({
    super.key,
    required this.service,
  });

  @override
  ConsumerState<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends ConsumerState<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _jicsController = TextEditingController();
  
  String _selectedServiceType = 'grooming';
  String _selectedCity = 'الرياض';
  bool _isLoading = false;
  bool _isAvailable = true;
  List<Map<String, dynamic>> _warehouseServices = [];
  Map<String, dynamic>? _selectedWarehouseService;
  bool _isLoadingWarehouse = false;
  String? _warehouseId;
  String? _internalCode;
  
  // Media upload properties
  List<MediaFile> _selectedImages = [];
  MediaFile? _selectedVideo;
  bool _isUploadingMedia = false;
  List<String> _existingImageUrls = [];
  String? _existingVideoUrl;

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
    _initializeFormData();
    _loadWarehouseServices();
  }

  void _initializeFormData() {
    // Initialize form fields with existing service data
    _nameController.text = widget.service['name'] ?? '';
    _descriptionController.text = widget.service['description'] ?? '';
    _priceController.text = widget.service['price']?.toString() ?? '';
    _durationController.text = widget.service['duration_minutes']?.toString() ?? '';
    _quantityController.text = widget.service['quantity']?.toString() ?? '1';
    _notesController.text = widget.service['notes'] ?? '';
    _jicsController.text = widget.service['internal_code'] ?? '';
    
    _selectedServiceType = widget.service['service_type'] ?? 'grooming';
    _selectedCity = widget.service['city'] ?? 'الرياض';
    _isAvailable = widget.service['is_active'] ?? true;
    _warehouseId = widget.service['warehouse_id'];
    _internalCode = widget.service['internal_code'];
    
    // Initialize existing media
    if (widget.service['image_urls'] != null) {
      _existingImageUrls = List<String>.from(widget.service['image_urls']);
    } else if (widget.service['image_url'] != null) {
      _existingImageUrls = [widget.service['image_url']];
    }
    
    _existingVideoUrl = widget.service['video_url'];
  }

  Future<void> _loadWarehouseServices() async {
    setState(() => _isLoadingWarehouse = true);
    
    try {
      final services = await SupabaseConfig.getWarehouseServices();
      setState(() {
        _warehouseServices = services;
        _isLoadingWarehouse = false;
      });
      
      // Find and select the current warehouse service if exists
      if (_warehouseId != null) {
        final currentService = _warehouseServices.firstWhere(
          (service) => service['id'] == _warehouseId,
          orElse: () => {},
        );
        if (currentService.isNotEmpty) {
          setState(() {
            _selectedWarehouseService = currentService;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoadingWarehouse = false);
      _showErrorSnackBar('فشل في تحميل خدمات المستودع: ${e.toString()}');
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await MediaUploadHelper.pickMultipleImages();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصور: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await MediaUploadHelper.pickVideo();
      if (video != null) {
        setState(() {
          _selectedVideo = video;
        });
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الفيديو: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
    });
  }

  void _removeExistingVideo() {
    setState(() {
      _existingVideoUrl = null;
    });
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        _showErrorSnackBar('المستخدم غير مسجل الدخول');
        return;
      }

      // Upload new media if any
      List<String> newImageUrls = [];
      String? newVideoUrl;

      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingMedia = true);
        
        final imageData = _selectedImages.map((img) => {
          'name': img.name,
          'bytes': img.bytes,
        }).toList();
        
        newImageUrls = await SupabaseConfig.uploadMultipleImages(user.id, imageData);
      }

      if (_selectedVideo != null) {
        setState(() => _isUploadingMedia = true);
        
        final videoData = {
          'name': _selectedVideo!.name,
          'bytes': _selectedVideo!.bytes,
        };
        
        newVideoUrl = await SupabaseConfig.uploadVideo(user.id, videoData);
      }

      // Combine existing and new media URLs
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];
      final finalVideoUrl = newVideoUrl ?? _existingVideoUrl;

      // Validate service from warehouse if selected
      if (_selectedWarehouseService != null) {
        final validation = await SupabaseConfig.validateServiceFromWarehouse(
          serviceName: _selectedWarehouseService!['service_name'],
          internalCode: _selectedWarehouseService!['internal_code'],
          requestedQuantity: int.tryParse(_quantityController.text) ?? 1,
        );

        if (validation == null) {
          _showErrorSnackBar('الخدمة غير موجودة في المستودع');
          setState(() => _isLoading = false);
          return;
        }

        if (!validation['isQuantityValid']) {
          _showErrorSnackBar('الكمية المطلوبة غير متوفرة في المستودع');
          setState(() => _isLoading = false);
          return;
        }

        _warehouseId = validation['warehouseItem']['id'];
        _internalCode = validation['warehouseItem']['internal_code'];
      }

      // Prepare service data
      final serviceData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration_minutes': int.tryParse(_durationController.text) ?? 0,
        'service_type': _selectedServiceType,
        'city': _selectedCity,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'notes': _notesController.text.trim(),
        'is_active': _isAvailable,
        'image_urls': allImageUrls,
        'video_url': finalVideoUrl,
        'warehouse_id': _warehouseId,
        'internal_code': _internalCode,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update service in database
      await SupabaseConfig.client
          .from('services')
          .update(serviceData)
          .eq('id', widget.service['id']);

      setState(() => _isLoading = false);
      _showSuccessSnackBar('تم تحديث الخدمة بنجاح');
      
      // Return to previous page
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('فشل في تحديث الخدمة: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تعديل الخدمة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading ? _buildLoadingState() : _buildForm(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحديث الخدمة...'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceNameSelection(),
            const SizedBox(height: 16),
            _buildServiceDetails(),
            const SizedBox(height: 16),
            _buildLocationAndAvailability(),
            const SizedBox(height: 16),
            _buildMediaSection(),
            const SizedBox(height: 16),
            _buildQuantityAndNotes(),
            const SizedBox(height: 24),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceNameSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختيار الخدمة من الكتالوج',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingWarehouse)
              const Center(child: CircularProgressIndicator())
            else if (_warehouseServices.isEmpty)
              const Text('لا توجد خدمات متاحة في المستودع')
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedWarehouseService,
                decoration: const InputDecoration(
                  labelText: 'اختر الخدمة من المستودع',
                  border: OutlineInputBorder(),
                ),
                items: _warehouseServices.map((service) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: service,
                    child: Text(service['service_name'] ?? 'خدمة غير محددة'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWarehouseService = value;
                    if (value != null) {
                      _nameController.text = value['service_name'] ?? '';
                      _jicsController.text = value['internal_code'] ?? '';
                      _selectedServiceType = value['service_type'] ?? 'grooming';
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'يجب اختيار خدمة من المستودع';
                  }
                  return null;
                },
              ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الخدمة',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم الخدمة';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              decoration: const InputDecoration(
                labelText: 'نوع الخدمة',
                border: OutlineInputBorder(),
              ),
              items: _serviceTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['key'],
                  child: Row(
                    children: [
                      Icon(type['icon'], size: 20),
                      const SizedBox(width: 8),
                      Text(type['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServiceType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الخدمة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'وصف الخدمة',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال وصف الخدمة';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر (ريال)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال السعر';
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'المدة (دقيقة)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال المدة';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAndAvailability() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الموقع والتوفر',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                labelText: 'المدينة',
                border: OutlineInputBorder(),
              ),
              items: _cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('متوفر للحجز'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الصور والفيديو',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Existing Images
            if (_existingImageUrls.isNotEmpty) ...[
              const Text('الصور الحالية:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingImageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // New Images
            if (_selectedImages.isNotEmpty) ...[
              const Text('الصور الجديدة:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImages[index].bytes,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Video Section
            if (_existingVideoUrl != null || _selectedVideo != null) ...[
              const Text('الفيديو:'),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.video_library, size: 40),
                          Text(_selectedVideo?.name ?? 'فيديو موجود'),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _selectedVideo != null 
                            ? _removeVideo 
                            : _removeExistingVideo,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
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
            
            // Media Upload Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('إضافة صور'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('إضافة فيديو'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_isUploadingMedia) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('جاري رفع الملفات...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityAndNotes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الكمية والملاحظات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية المتاحة',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الكمية';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'يرجى إدخال كمية صحيحة';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _jicsController,
              decoration: const InputDecoration(
                labelText: 'كود JICS',
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateService,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'تحديث الخدمة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    _notesController.dispose();
    _jicsController.dispose();
    super.dispose();
  }
}