import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreamflow/services/promotional_service.dart';
import 'package:dreamflow/services/service_provider_service.dart';
import 'package:dreamflow/supabase/supabase_config.dart';
import 'package:dreamflow/models/promotional_models.dart';
import 'package:dreamflow/utils/arabic_helpers.dart';

class OfferSubmissionPage extends ConsumerStatefulWidget {
  final String serviceId;
  final String serviceName;
  final double originalPrice;

  const OfferSubmissionPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.originalPrice,
  });

  @override
  ConsumerState<OfferSubmissionPage> createState() => _OfferSubmissionPageState();
}

class _OfferSubmissionPageState extends ConsumerState<OfferSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  double _discountedPrice = 0.0;
  int _discountPercentage = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_calculateDiscountedPrice);
  }

  @override
  void dispose() {
    _discountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _calculateDiscountedPrice() {
    final discountText = _discountController.text;
    if (discountText.isNotEmpty) {
      final discount = int.tryParse(discountText) ?? 0;
      setState(() {
        _discountPercentage = discount;
        _discountedPrice = widget.originalPrice * (1 - discount / 100);
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = formatArabicDate(picked);
        
        // Auto-adjust end date if it's before start date
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
          _selectedEndDate = picked.add(const Duration(days: 1));
          _endDateController.text = formatArabicDate(_selectedEndDate!);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final initialDate = _selectedStartDate != null 
        ? _selectedStartDate!.add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 2));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = formatArabicDate(picked);
      });
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showErrorDialog('يرجى اختيار تاريخ البداية والنهاية للعرض');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      await PromotionalService.createServiceOffer(
        providerId: user.id,
        serviceId: widget.serviceId,
        discountPercentage: _discountPercentage,
        discountedPrice: _discountedPrice,
        originalPrice: widget.originalPrice,
        offerStartDate: _selectedStartDate!,
        offerEndDate: _selectedEndDate!,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog('تم إرسال العرض بنجاح! سيتم مراجعته من قبل الإدارة.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('حدث خطأ أثناء إرسال العرض: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نجح'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء عرض جديد'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات الخدمة',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.business, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.serviceName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'السعر الأصلي: ${widget.originalPrice.toStringAsFixed(2)} ريال',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Discount Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل الخصم',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Discount Percentage
                      TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          labelText: 'نسبة الخصم (%)',
                          hintText: 'مثال: 20',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال نسبة الخصم';
                          }
                          final discount = int.tryParse(value);
                          if (discount == null || discount < 1 || discount > 99) {
                            return 'نسبة الخصم يجب أن تكون بين 1% و 99%';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Calculated Price Display
                      if (_discountPercentage > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'السعر الأصلي:',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    '${widget.originalPrice.toStringAsFixed(2)} ريال',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'السعر بعد الخصم:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '${_discountedPrice.toStringAsFixed(2)} ريال',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('مبلغ الوفر:'),
                                  Text(
                                    '${(widget.originalPrice - _discountedPrice).toStringAsFixed(2)} ريال',
                                    style: const TextStyle(color: Colors.orange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Selection
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مدة العرض',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Start Date
                      TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ بداية العرض',
                          hintText: 'اختر تاريخ البداية',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectStartDate,
                        validator: (value) {
                          if (_selectedStartDate == null) {
                            return 'يرجى اختيار تاريخ بداية العرض';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // End Date
                      TextFormField(
                        controller: _endDateController,
                        readOnly: true,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ نهاية العرض',
                          hintText: 'اختر تاريخ النهاية',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectEndDate,
                        validator: (value) {
                          if (_selectedEndDate == null) {
                            return 'يرجى اختيار تاريخ نهاية العرض';
                          }
                          return null;
                        },
                      ),
                      
                      // Duration Display
                      if (_selectedStartDate != null && _selectedEndDate != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'مدة العرض: ${_selectedEndDate!.difference(_selectedStartDate!).inDays} يوم',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('جاري الإرسال...'),
                        ],
                      )
                    : const Text(
                        'إرسال العرض للمراجعة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.amber.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'معلومات مهمة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• سيتم مراجعة العرض من قبل الإدارة خلال 24-48 ساعة',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• يمكنك إلغاء العرض قبل الموافقة عليه',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• لا يمكن تعديل العرض بعد الموافقة عليه',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• العرض سيظهر تلقائياً في التطبيق بعد الموافقة',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}