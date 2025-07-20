import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../theme.dart';
import '../services/service_provider_service.dart';
import '../utils/arabic_helpers.dart';
import '../image_upload.dart';
import '../supabase/supabase_config.dart';
import '../models/service_provider_model.dart';

class ServiceProviderProfilePage extends ConsumerStatefulWidget {
  const ServiceProviderProfilePage({super.key});

  @override
  ConsumerState<ServiceProviderProfilePage> createState() => _ServiceProviderProfilePageState();
}

class _ServiceProviderProfilePageState extends ConsumerState<ServiceProviderProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all fields
  final _commercialNameController = TextEditingController();
  final _registeredNameController = TextEditingController();
  final _authorizedPersonController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ibanController = TextEditingController();
  
  // State variables
  String _selectedCity = '';
  String _selectedServiceType = 'grooming';
  Uint8List? _logoBytes;
  String? _logoUrl;
  List<Map<String, String>> _branches = [];
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Current provider data
  ServiceProvider? _currentProvider;
  Map<String, dynamic>? _currentProviderMap;
  
  // Pending changes tracking
  List<Map<String, dynamic>> _pendingChanges = [];
  
  // Changed fields tracking
  Map<String, dynamic> _changedFields = {};

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
    'الرياض', 'جدة', 'الدمام', 'المدينة المنورة', 'مكة المكرمة', 'الطائف',
    'بريدة', 'تبوك', 'خميس مشيط', 'الأحساء', 'حفر الباطن', 'الجبيل',
    'نجران', 'أبها', 'ينبع', 'الخرج', 'القطيف', 'الظهران', 'الكرك', 'عرعر',
  ];

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _commercialNameController.dispose();
    _registeredNameController.dispose();
    _authorizedPersonController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetAddressController.dispose();
    _descriptionController.dispose();
    _taxNumberController.dispose();
    _bankAccountController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        _showErrorDialog('المستخدم غير مسجل الدخول');
        return;
      }

      final response = await SupabaseConfig.client
          .from('service_providers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _currentProvider = ServiceProvider.fromJson(response);
        _currentProviderMap = response;
        _populateFields(response);
        
        // Load pending changes
        final pendingChanges = await ServiceProviderService.getPendingChanges(user.id);
        setState(() {
          _pendingChanges = pendingChanges;
        });
      } else {
        // If no profile exists, show a message but don't treat it as an error
        print('No service provider profile found for user: ${user.id}');
      }
    } catch (e) {
      _showErrorDialog('فشل في تحميل البيانات: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      _commercialNameController.text = data['commercial_name'] ?? '';
      _registeredNameController.text = data['registered_name'] ?? '';
      _authorizedPersonController.text = data['authorized_person_name'] ?? '';
      _idNumberController.text = data['national_id'] ?? data['id_number'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _streetAddressController.text = data['street_address'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _taxNumberController.text = data['tax_number'] ?? '';
      _bankAccountController.text = data['bank_account_number'] ?? data['bank_account'] ?? '';
      _ibanController.text = data['iban'] ?? '';
      
      _selectedCity = data['city'] ?? '';
      _selectedServiceType = data['service_type'] ?? 'grooming';
      _logoUrl = data['logo_url'];
      
      // Parse branches if available
      if (data['branches'] != null) {
        try {
          final branchesData = data['branches'] as List;
          _branches = branchesData.map((branch) => {
            'name': branch['name'].toString(),
            'city': branch['city'].toString(),
          }).toList();
        } catch (e) {
          _branches = [];
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCity.isEmpty) {
      _showErrorDialog('يرجى اختيار المدينة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        _showErrorDialog('المستخدم غير مسجل الدخول');
        return;
      }

      // Upload logo if new one is provided
      String? logoUrl = _logoUrl;
      if (_logoBytes != null) {
        final fileName = 'logo_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'provider-logos/$fileName';
        
        try {
          await SupabaseConfig.client.storage
              .from('provider-logos')
              .uploadBinary(filePath, _logoBytes!);
          
          logoUrl = SupabaseConfig.client.storage
              .from('provider-logos')
              .getPublicUrl(filePath);
        } catch (e) {
          print('Logo upload failed: $e');
          // Continue without logo update if upload fails
        }
      }

      // Prepare all update data
      final allUpdateData = {
        'commercial_name': _commercialNameController.text.trim(),
        'registered_name': _registeredNameController.text.trim(),
        'authorized_person_name': _authorizedPersonController.text.trim(),
        'national_id': _idNumberController.text.trim(),
        'id_number': _idNumberController.text.trim(), // Legacy field
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'city': _selectedCity,
        'street_address': _streetAddressController.text.trim(),
        'service_type': _selectedServiceType,
        'description': _descriptionController.text.trim(),
        'tax_number': _taxNumberController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'bank_account': _bankAccountController.text.trim(), // Legacy field
        'iban': _ibanController.text.trim(),
        'logo_url': logoUrl,
        'branches': _branches.isNotEmpty ? _branches : null,
      };

      // Separate basic and sensitive fields
      final basicFields = <String, dynamic>{};
      final sensitiveFields = <String, dynamic>{};
      
      for (final entry in allUpdateData.entries) {
        if (ServiceProviderService.isBasicField(entry.key)) {
          basicFields[entry.key] = entry.value;
        } else if (ServiceProviderService.isSensitiveField(entry.key)) {
          sensitiveFields[entry.key] = entry.value;
        }
      }

      // Update basic fields directly
      if (basicFields.isNotEmpty) {
        final basicResult = await ServiceProviderService.updateBasicFields(
          userId: user.id,
          updates: basicFields,
        );
        
        if (!basicResult['success']) {
          _showErrorDialog('فشل في تحديث البيانات الأساسية: ${basicResult['message']}');
          return;
        }
      }

      // Submit sensitive fields for approval
      if (sensitiveFields.isNotEmpty) {
        final sensitiveResult = await ServiceProviderService.submitSensitiveFieldChanges(
          userId: user.id,
          changes: sensitiveFields,
        );
        
        if (!sensitiveResult['success']) {
          _showErrorDialog('فشل في إرسال التعديلات الحساسة: ${sensitiveResult['message']}');
          return;
        }
      }

      // Show appropriate success message
      if (sensitiveFields.isNotEmpty && basicFields.isNotEmpty) {
        _showSuccessDialog('تم تحديث البيانات الأساسية بنجاح. البيانات الحساسة في انتظار المراجعة من قبل فريق جينا.');
      } else if (sensitiveFields.isNotEmpty) {
        _showSuccessDialog('تم إرسال طلب التعديل للمراجعة من قبل فريق جينا.');
      } else {
        _showSuccessDialog('تم تحديث البيانات بنجاح');
      }

      setState(() => _isEditing = false);
      
      // Reload data to reflect changes
      await _loadProviderData();
    } catch (e) {
      _showErrorDialog('فشل في تحديث البيانات: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('تم بنجاح'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف مزود الخدمة'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_currentProvider != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveProfile,
            ),
        ],
      ),
      body: _isLoading && _currentProvider == null
          ? const Center(child: CircularProgressIndicator())
          : _currentProvider == null
              ? _buildNoDataMessage()
              : _buildProfileContent(),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات ملف شخصي',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى إكمال التسجيل أولاً',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildCompanyInfoSection(),
              const SizedBox(height: 24),
              _buildAuthorizedPersonSection(),
              const SizedBox(height: 24),
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              _buildBusinessLocationSection(),
              const SizedBox(height: 24),
              _buildFinancialInfoSection(),
              const SizedBox(height: 24),
              _buildLogoSection(),
              const SizedBox(height: 24),
              _buildBranchesSection(),
              const SizedBox(height: 24),
              _buildServiceInfoSection(),
              const SizedBox(height: 24),
              _buildDescriptionSection(),
              const SizedBox(height: 24),
              if (_pendingChanges.isNotEmpty) _buildPendingChangesSection(),
              if (_pendingChanges.isNotEmpty) const SizedBox(height: 24),
              if (_isEditing) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              _isEditing ? Icons.edit : Icons.business_center,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'تعديل ملف مزود الخدمة' : 'ملف مزود الخدمة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isEditing 
                  ? 'يمكنك تعديل المعلومات أدناه وحفظ التغييرات'
                  : 'معلومات مزود الخدمة المسجلة في المنصة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات الشركة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _commercialNameController,
              label: 'الاسم التجاري *',
              icon: Icons.store,
              readOnly: !_isEditing,
              validator: (value) => value?.trim().isEmpty == true ? 'الاسم التجاري مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildSensitiveTextFormField(
              controller: _registeredNameController,
              label: 'الاسم المسجل (من السجل التجاري) *',
              icon: Icons.assignment,
              readOnly: !_isEditing,
              validator: (value) => value?.trim().isEmpty == true ? 'الاسم المسجل مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizedPersonSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'الشخص المفوض',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _authorizedPersonController,
              label: 'اسم الشخص المفوض الكامل *',
              icon: Icons.person,
              readOnly: !_isEditing,
              validator: (value) => value?.trim().isEmpty == true ? 'اسم الشخص المفوض مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildSensitiveTextFormField(
              controller: _idNumberController,
              label: 'رقم الهوية / رقم الهوية الوطنية *',
              icon: Icons.credit_card,
              readOnly: !_isEditing,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.trim().isEmpty == true) return 'رقم الهوية مطلوب';
                if (value!.length != 10) return 'رقم الهوية يجب أن يكون 10 أرقام';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات التواصل',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _phoneController,
              label: 'رقم الهاتف *',
              icon: Icons.phone,
              readOnly: !_isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.trim().isEmpty == true) return 'رقم الهاتف مطلوب';
                if (!ArabicHelpers.isValidSaudiPhone(value!)) return 'رقم الهاتف غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _emailController,
              label: 'البريد الإلكتروني *',
              icon: Icons.email,
              readOnly: !_isEditing,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.trim().isEmpty == true) return 'البريد الإلكتروني مطلوب';
                if (!value!.contains('@')) return 'البريد الإلكتروني غير صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessLocationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'موقع النشاط التجاري',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isEditing ? _buildCityDropdown() : _buildCityDisplay(),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _streetAddressController,
              label: 'العنوان التفصيلي *',
              icon: Icons.home,
              readOnly: !_isEditing,
              maxLines: 2,
              validator: (value) => value?.trim().isEmpty == true ? 'العنوان التفصيلي مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: const Color(0xFFC9A14C), // Jeena Gold
                ),
                const SizedBox(width: 8),
                Text(
                  'المعلومات المالية',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFC9A14C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'يتطلب موافقة',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSensitiveTextFormField(
              controller: _taxNumberController,
              label: 'الرقم الضريبي *',
              icon: Icons.receipt_long,
              readOnly: !_isEditing,
              keyboardType: TextInputType.number,
              validator: (value) => value?.trim().isEmpty == true ? 'الرقم الضريبي مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildSensitiveTextFormField(
              controller: _bankAccountController,
              label: 'رقم الحساب البنكي',
              icon: Icons.account_balance_wallet,
              readOnly: !_isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildSensitiveTextFormField(
              controller: _ibanController,
              label: 'رقم الآيبان (IBAN)',
              icon: Icons.credit_card,
              readOnly: !_isEditing,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value?.trim().isNotEmpty == true) {
                  if (value!.length < 15) return 'رقم الآيبان غير صحيح';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات الخدمة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'نوع الخدمة',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _isEditing ? _buildServiceTypeGrid() : _buildServiceTypeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'وصف الخدمة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'وصف تفصيلي للخدمة',
                hintText: _isEditing ? 'اكتب وصفاً مفصلاً للخدمة التي تقدمها...' : null,
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.tertiary,
                    width: 2,
                  ),
                ),
                filled: !_isEditing,
                fillColor: !_isEditing ? Colors.grey[100] : null,
              ),
              validator: (value) => value?.trim().isEmpty == true ? 'وصف الخدمة مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : null,
      ),
    );
  }

  Widget _buildSensitiveTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: _isEditing ? Icon(
          Icons.security,
          color: Colors.orange[600],
          size: 20,
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isEditing ? Colors.orange[300]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isEditing ? Colors.orange[500]! : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : (_isEditing ? Colors.orange[50] : null),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity.isEmpty ? null : _selectedCity,
      decoration: InputDecoration(
        labelText: 'المدينة *',
        prefixIcon: Icon(
          Icons.location_city,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
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
      validator: (value) => value == null ? 'المدينة مطلوبة' : null,
    );
  }

  Widget _buildCityDisplay() {
    return TextFormField(
      initialValue: _selectedCity,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'المدينة',
        prefixIcon: Icon(
          Icons.location_city,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildServiceTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3.5,
      ),
      itemCount: _serviceTypes.length,
      itemBuilder: (context, index) {
        final serviceType = _serviceTypes[index];
        final isSelected = _selectedServiceType == serviceType['key'];
        
        return InkWell(
          onTap: () => setState(() => _selectedServiceType = serviceType['key']),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  serviceType['icon'],
                  size: 16,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    serviceType['name'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
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

  Widget _buildServiceTypeDisplay() {
    final selectedType = _serviceTypes.firstWhere(
      (type) => type['key'] == _selectedServiceType,
      orElse: () => _serviceTypes[0],
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            selectedType['icon'],
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            selectedType['name'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'شعار الشركة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isEditing ? _pickLogo : null,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: _isEditing ? Colors.grey[50] : Colors.grey[100],
                ),
                child: _logoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _logoBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : _logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => _buildLogoPlaceholder(),
                            ),
                          )
                        : _buildLogoPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isEditing ? Icons.cloud_upload : Icons.image,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          _isEditing ? 'اضغط لرفع شعار الشركة' : 'لا يوجد شعار',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (_isEditing)
          Text(
            '(اختياري)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final imageBytes = await ImageUploadHelper.pickImageFromGallery();
    if (imageBytes != null) {
      setState(() => _logoBytes = imageBytes);
    }
  }

  Widget _buildBranchesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'الفروع (اختياري)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_branches.isNotEmpty)
              ...List.generate(_branches.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: _isEditing ? Colors.white : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _branches[index]['name']!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _branches[index]['city']!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _branches.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                    ],
                  ),
                );
              }),
            if (_isEditing)
              ElevatedButton.icon(
                onPressed: _showAddBranchDialog,
                icon: const Icon(Icons.add),
                label: const Text('إضافة فرع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddBranchDialog() {
    final branchNameController = TextEditingController();
    String selectedBranchCity = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة فرع جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: branchNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الفرع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBranchCity.isEmpty ? null : selectedBranchCity,
                decoration: const InputDecoration(
                  labelText: 'مدينة الفرع',
                  border: OutlineInputBorder(),
                ),
                items: _cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBranchCity = value ?? '';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (branchNameController.text.isNotEmpty && selectedBranchCity.isNotEmpty) {
                  this.setState(() {
                    _branches.add({
                      'name': branchNameController.text.trim(),
                      'city': selectedBranchCity,
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('جاري الحفظ...'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.save,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'حفظ التغييرات',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPendingChangesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pending_actions,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'التغييرات المرسلة للمراجعة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_pendingChanges.length, (index) {
              final change = _pendingChanges[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(change['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(change['status']).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ServiceProviderService.getFieldDisplayName(change['field_name']),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(change['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ServiceProviderService.getStatusDisplayName(change['status']),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (change['old_value'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'القيمة الحالية:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            change['old_value'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    Text(
                      'القيمة المطلوبة:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      change['new_value'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تاريخ الطلب: ${formatArabicDate(DateTime.parse(change['requested_at']))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    if (change['admin_notes'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'ملاحظات الإدارة:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            change['admin_notes'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
            if (_pendingChanges.where((change) => change['status'] == 'pending').isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم مراجعة التغييرات المرسلة من قبل فريق جينا والتواصل معكم قريباً.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // Format date in Arabic
  String formatArabicDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}