import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase/supabase_config.dart';
import '../services/auth_service.dart';
import '../utils/arabic_helpers.dart';

class AvailabilityChecker extends StatefulWidget {
  final Map<String, dynamic> product;

  const AvailabilityChecker({
    super.key,
    required this.product,
  });

  @override
  State<AvailabilityChecker> createState() => _AvailabilityCheckerState();
}

class _AvailabilityCheckerState extends State<AvailabilityChecker> {
  DateTime? startDate;
  DateTime? endDate;
  int requiredQuantity = 1;
  bool isChecking = false;
  Map<String, dynamic>? availabilityResult;
  List<Map<String, dynamic>> reservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        final response = await SupabaseConfig.client
            .from('warehouse_reservations')
            .select('*')
            .eq('product_id', widget.product['id'])
            .eq('user_id', user.id)
            .inFilter('status', ['reserved', 'confirmed'])
            .order('start_date', ascending: true);
        
        setState(() {
          reservations = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error loading reservations: $e');
    }
  }

  Future<void> _checkAvailability() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد التاريخ المطلوب')),
      );
      return;
    }

    setState(() {
      isChecking = true;
      availabilityResult = null;
    });

    try {
      final response = await SupabaseConfig.client
          .rpc('check_product_availability', params: {
        'product_id': widget.product['id'],
        'start_date': startDate!.toIso8601String(),
        'end_date': endDate!.toIso8601String(),
        'required_quantity': requiredQuantity,
      });

      setState(() {
        availabilityResult = {
          'available': response as bool,
          'total_stock': widget.product['current_stock'],
          'available_quantity': widget.product['current_stock'],
        };
        isChecking = false;
      });
    } catch (e) {
      setState(() {
        isChecking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('فحص توفر المنتج'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الكمية المتوفرة: ${widget.product['current_stock']} قطعة',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.product['product_code'] != null)
                    Text(
                      'الكود: ${widget.product['product_code']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Selection
            Text(
              'اختر التاريخ المطلوب:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          startDate = date;
                          availabilityResult = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            startDate != null
                                ? DateFormat('yyyy/MM/dd').format(startDate!)
                                : 'تاريخ البداية',
                            style: TextStyle(
                              color: startDate != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          endDate = date;
                          availabilityResult = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            endDate != null
                                ? DateFormat('yyyy/MM/dd').format(endDate!)
                                : 'تاريخ النهاية',
                            style: TextStyle(
                              color: endDate != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quantity Selection
            Text(
              'الكمية المطلوبة:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                IconButton(
                  onPressed: requiredQuantity > 1
                      ? () => setState(() {
                            requiredQuantity--;
                            availabilityResult = null;
                          })
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$requiredQuantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: requiredQuantity < (widget.product['current_stock'] as int)
                      ? () => setState(() {
                            requiredQuantity++;
                            availabilityResult = null;
                          })
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Check Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isChecking ? null : _checkAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('فحص التوفر'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Availability Result
            if (availabilityResult != null) _buildAvailabilityResult(),
            
            // Existing Reservations
            if (reservations.isNotEmpty) _buildReservationsList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildAvailabilityResult() {
    final result = availabilityResult!;
    final isAvailable = result['available'] as bool;
    final totalStock = result['total_stock'] as int;
    final availableQuantity = result['available_quantity'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                color: isAvailable ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isAvailable ? 'متوفر' : 'غير متوفر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            'إجمالي المخزون: $totalStock قطعة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'متاح: $availableQuantity قطعة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: availableQuantity >= requiredQuantity ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'الحجوزات الحالية:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final startDate = DateTime.parse(reservation['start_date']);
              final endDate = DateTime.parse(reservation['end_date']);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    reservation['customer_name'] ?? 'عميل غير محدد',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الكمية: ${reservation['reserved_quantity']} قطعة',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(reservation['status']),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(reservation['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'مؤكد';
      case 'reserved':
        return 'محجوز';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير محدد';
    }
  }
}