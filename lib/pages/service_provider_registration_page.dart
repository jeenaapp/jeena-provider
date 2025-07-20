import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../theme.dart';
import '../services/service_provider_service.dart';
import '../utils/arabic_helpers.dart';
import '../image_upload.dart';
import '../supabase/supabase_config.dart';

class ServiceProviderRegistrationPage extends ConsumerStatefulWidget {
  const ServiceProviderRegistrationPage({super.key});

  @override
  ConsumerState<ServiceProviderRegistrationPage> createState() => _ServiceProviderRegistrationPageState();
}

class _ServiceProviderRegistrationPageState extends ConsumerState<ServiceProviderRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  // JEENA Required Fields
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
  
  // Optional fields
  String _selectedCity = '';
  Uint8List? _logoBytes;
  String? _logoUrl;
  List<Map<String, String>> _branches = [];
  
  String _selectedServiceType = 'grooming';
  bool _isLoading = false;
  bool _hasAcceptedTerms = false;
  String? _generatedJICS;

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_hasAcceptedTerms) {
      _showErrorDialog('يرجى الموافقة على الشروط والأحكام');
      return;
    }
    
    if (_selectedCity.isEmpty) {
      _showErrorDialog('يرجى اختيار المدينة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ServiceProviderService.submitServiceProviderRegistration(
        commercialName: _commercialNameController.text.trim(),
        registeredName: _registeredNameController.text.trim(),
        authorizedPersonName: _authorizedPersonController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _selectedCity,
        streetAddress: _streetAddressController.text.trim(),
        serviceType: _selectedServiceType,
        description: _descriptionController.text.trim(),
        logoBytes: _logoBytes,
        branches: _branches,
        taxNumber: _taxNumberController.text.trim().isNotEmpty ? _taxNumberController.text.trim() : null,
        bankAccount: _bankAccountController.text.trim().isNotEmpty ? _bankAccountController.text.trim() : null,
        iban: _ibanController.text.trim().isNotEmpty ? _ibanController.text.trim() : null,
      );

      if (result['success']) {
        setState(() {
          _generatedJICS = result['jics_code'];
        });
        _showSuccessDialog(
          'تم تسجيل طلبكم بنجاح!\n\n'
          'رمز JEENA الخاص بكم: ${result['jics_code']}\n\n'
          'سيتم مراجعة طلبكم من قبل فريق JEENA وسيتم التواصل معكم قريباً.\n\n'
          'شكراً لانضمامكم لشبكة مقدمي الخدمات.'
        );
        _clearForm();
      } else {
        _showErrorDialog(result['message']);
      }
    } catch (e) {
      _showErrorDialog('حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _commercialNameController.clear();
    _registeredNameController.clear();
    _authorizedPersonController.clear();
    _idNumberController.clear();
    _phoneController.clear();
    _emailController.clear();
    _streetAddressController.clear();
    _descriptionController.clear();
    _taxNumberController.clear();
    _bankAccountController.clear();
    _ibanController.clear();
    setState(() {
      _selectedServiceType = 'grooming';
      _selectedCity = '';
      _logoBytes = null;
      _logoUrl = null;
      _branches.clear();
      _hasAcceptedTerms = false;
      _generatedJICS = null;
    });
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
        title: const Text('تسجيل مقدم خدمة'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
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
                _buildTermsSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
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
              Icons.business_center,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'انضم إلى شبكة مقدمي الخدمات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'املأ النموذج أدناه لتسجيل خدماتك والوصول إلى عملاء جدد',
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
              validator: (value) => value?.trim().isEmpty == true ? 'الاسم التجاري مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _registeredNameController,
              label: 'الاسم المسجل (من السجل التجاري) *',
              icon: Icons.assignment,
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
              validator: (value) => value?.trim().isEmpty == true ? 'اسم الشخص المفوض مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _idNumberController,
              label: 'رقم الهوية *',
              icon: Icons.credit_card,
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
            _buildServiceTypeGrid(),
          ],
        ),
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
              decoration: InputDecoration(
                labelText: 'وصف تفصيلي للخدمة',
                hintText: 'اكتب وصفاً مفصلاً للخدمة التي تقدمها...',
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
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
      ),
    );
  }

  Future<void> _pickLogo() async {
    final imageBytes = await ImageUploadHelper.pickImageFromGallery();
    if (imageBytes != null) {
      setState(() => _logoBytes = imageBytes);
    }
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
                  'المعلومات المالية (اختياري)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFC9A14C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _taxNumberController,
              label: 'الرقم الضريبي',
              icon: Icons.receipt_long,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _bankAccountController,
              label: 'رقم الحساب البنكي',
              icon: Icons.account_balance_wallet,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _ibanController,
              label: 'رقم الآيبان (IBAN)',
              icon: Icons.credit_card,
              keyboardType: TextInputType.text,
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
            _buildCityDropdown(),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _streetAddressController,
              label: 'العنوان التفصيلي *',
              icon: Icons.home,
              maxLines: 2,
              validator: (value) => value?.trim().isEmpty == true ? 'العنوان التفصيلي مطلوب' : null,
            ),
          ],
        ),
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
              onTap: _pickLogo,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: _logoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _logoBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لرفع شعار الشركة',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '(اختياري)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildTermsSection() {
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
                  Icons.gavel,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'الشروط والأحكام',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _hasAcceptedTerms,
              onChanged: (value) {
                setState(() {
                  _hasAcceptedTerms = value ?? false;
                });
              },
              title: Text(
                'أوافق على شروط وأحكام منصة JEENA ومعايير الجودة المطلوبة',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
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
                const Text('جاري الإرسال...'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'إرسال الطلب',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}