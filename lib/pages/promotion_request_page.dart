import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreamflow/services/promotional_service.dart';
import 'package:dreamflow/supabase/supabase_config.dart';
import 'package:dreamflow/models/promotional_models.dart';
import 'package:dreamflow/utils/arabic_helpers.dart';

class PromotionRequestPage extends ConsumerStatefulWidget {
  final String serviceId;
  final String serviceName;

  const PromotionRequestPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<PromotionRequestPage> createState() => _PromotionRequestPageState();
}

class _PromotionRequestPageState extends ConsumerState<PromotionRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  
  PromotionType _selectedPromotionType = PromotionType.featuredSection;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  double _calculatedCost = 0.0;
  int _durationDays = 0;
  bool _isSubmitting = false;
  bool _isCalculatingCost = false;

  @override
  void initState() {
    super.initState();
    _durationController.addListener(_calculateCost);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _calculateCost() async {
    final durationText = _durationController.text;
    if (durationText.isNotEmpty) {
      final duration = int.tryParse(durationText) ?? 0;
      if (duration > 0) {
        setState(() {
          _durationDays = duration;
          _isCalculatingCost = true;
        });
        
        try {
          final cost = await PromotionalService.calculatePromotionCost(
            _selectedPromotionType.value,
            duration,
            null,
          );
          
          setState(() {
            _calculatedCost = cost;
            _isCalculatingCost = false;
          });
        } catch (e) {
          setState(() {
            _calculatedCost = 0.0;
            _isCalculatingCost = false;
          });
        }
      }
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
        
        // Auto-calculate end date based on duration
        if (_durationDays > 0) {
          _selectedEndDate = picked.add(Duration(days: _durationDays));
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
        
        // Update duration based on selected dates
        if (_selectedStartDate != null) {
          final newDuration = picked.difference(_selectedStartDate!).inDays;
          _durationController.text = newDuration.toString();
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showErrorDialog('يرجى اختيار تاريخ البداية والنهاية للترويج');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      await PromotionalService.createPaidPromotionRequest(
        providerId: user.id,
        serviceId: widget.serviceId,
        promotionType: _selectedPromotionType.value,
        durationDays: _durationDays,
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog('تم إرسال طلب الترويج بنجاح! سيتم مراجعته من قبل الإدارة.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('حدث خطأ أثناء إرسال الطلب: ${e.toString()}');
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

  String _getPromotionTypeDescription(PromotionType type) {
    switch (type) {
      case PromotionType.headerBanner:
        return 'ظهور الخدمة في بانر الرأس الرئيسي';
      case PromotionType.featuredSection:
        return 'ظهور الخدمة في القسم المميز';
    }
  }

  String _getPromotionTypeTitle(PromotionType type) {
    switch (type) {
      case PromotionType.headerBanner:
        return 'بانر الرأس';
      case PromotionType.featuredSection:
        return 'القسم المميز';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب ترويج مدفوع'),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Promotion Type Selection
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الترويج',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Header Banner Option
                      RadioListTile<PromotionType>(
                        value: PromotionType.headerBanner,
                        groupValue: _selectedPromotionType,
                        onChanged: (value) {
                          setState(() {
                            _selectedPromotionType = value!;
                            _calculateCost();
                          });
                        },
                        title: Text(_getPromotionTypeTitle(PromotionType.headerBanner)),
                        subtitle: Text(_getPromotionTypeDescription(PromotionType.headerBanner)),
                        secondary: const Icon(Icons.view_headline, color: Colors.purple),
                      ),
                      
                      // Featured Section Option
                      RadioListTile<PromotionType>(
                        value: PromotionType.featuredSection,
                        groupValue: _selectedPromotionType,
                        onChanged: (value) {
                          setState(() {
                            _selectedPromotionType = value!;
                            _calculateCost();
                          });
                        },
                        title: Text(_getPromotionTypeTitle(PromotionType.featuredSection)),
                        subtitle: Text(_getPromotionTypeDescription(PromotionType.featuredSection)),
                        secondary: const Icon(Icons.stars, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Duration Selection
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مدة الترويج',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Duration Input
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          labelText: 'عدد الأيام',
                          hintText: 'مثال: 7',
                          border: OutlineInputBorder(),
                          suffixText: 'يوم',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال عدد الأيام';
                          }
                          final days = int.tryParse(value);
                          if (days == null || days < 1 || days > 365) {
                            return 'عدد الأيام يجب أن يكون بين 1 و 365';
                          }
                          return null;
                        },
                      ),
                      
                      // Cost Display
                      if (_durationDays > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'التكلفة الإجمالية:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              _isCalculatingCost
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      '${_calculatedCost.toStringAsFixed(2)} ريال',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 16,
                                      ),
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
                        'تواريخ الترويج',
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
                          labelText: 'تاريخ بداية الترويج',
                          hintText: 'اختر تاريخ البداية',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectStartDate,
                        validator: (value) {
                          if (_selectedStartDate == null) {
                            return 'يرجى اختيار تاريخ بداية الترويج';
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
                          labelText: 'تاريخ نهاية الترويج',
                          hintText: 'اختر تاريخ النهاية',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectEndDate,
                        validator: (value) {
                          if (_selectedEndDate == null) {
                            return 'يرجى اختيار تاريخ نهاية الترويج';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
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
                        'إرسال طلب الترويج للمراجعة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Pricing Info Card
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'معلومات التسعير',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• بانر الرأس: 50 ريال/يوم',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• القسم المميز (المراكز الثلاثة الأولى): 30 ريال/يوم',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• القسم المميز (المراكز الأخرى): 20 ريال/يوم',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

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
                        '• سيتم مراجعة طلب الترويج من قبل الإدارة خلال 24-48 ساعة',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• يجب دفع الرسوم قبل تفعيل الترويج',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• يمكن للإدارة تعديل التواريخ أو الموضع حسب المتاح',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '• الترويج سيظهر تلقائياً في التطبيق بعد الموافقة والدفع',
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