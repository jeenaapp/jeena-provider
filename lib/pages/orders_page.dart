import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  late TabController _tabController;
  String selectedStatus = 'all';

  final List<Map<String, dynamic>> statusTabs = [
    {'key': 'all', 'name': 'الكل', 'icon': Icons.list_alt},
    {'key': 'new', 'name': 'جديد', 'icon': Icons.new_releases},
    {'key': 'accepted', 'name': 'مقبول', 'icon': Icons.check_circle_outline},
    {'key': 'in_progress', 'name': 'جاري التنفيذ', 'icon': Icons.hourglass_empty},
    {'key': 'completed', 'name': 'مكتمل', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        print('Loading orders for user: ${user.id}');
        final ordersData = await SupabaseConfig.getOrders(user.id);
        print('Orders loaded: ${ordersData.length}');
        setState(() => orders = ordersData);
      }
    } catch (e) {
      print('Error loading orders: $e');
      
      // إضافة بيانات تجريبية في حالة الخطأ
      setState(() {
        orders = [
          {
            'id': '1',
            'customer_name': 'محمد العلي',
            'customer_email': 'mohammed.ali@example.com',
            'customer_phone': '+966501111111',
            'status': 'completed',
            'total_amount': 50.0,
            'scheduled_date': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
            'notes': 'حلاقة عادية',
            'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          },
          {
            'id': '2',
            'customer_name': 'سارة أحمد',
            'customer_email': 'sara.ahmed@example.com',
            'customer_phone': '+966502222222',
            'status': 'in_progress',
            'total_amount': 5000.0,
            'scheduled_date': DateTime.now().add(Duration(days: 7)).toIso8601String(),
            'notes': 'حفل زفاف في قاعة الماسة',
            'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          },
          {
            'id': '3',
            'customer_name': 'أحمد محمد',
            'customer_email': 'ahmed.mohammed@example.com',
            'customer_phone': '+966503333333',
            'status': 'new',
            'total_amount': 150.0,
            'scheduled_date': DateTime.now().add(Duration(days: 3)).toIso8601String(),
            'notes': 'خدمة تطوير موقع إلكتروني',
            'created_at': DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
          },
        ];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل بيانات تجريبية - يرجى التحقق من الاتصال'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    if (selectedStatus == 'all') return orders;
    return orders.where((order) => order['status'] == selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الطلبات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: statusTabs.map((tab) => Tab(
              icon: Icon(tab['icon'], size: 20),
              text: tab['name'],
            )).toList(),
            onTap: (index) {
              setState(() => selectedStatus = statusTabs[index]['key']);
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredOrders = _getFilteredOrders();

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            selectedStatus == 'all' ? 'لا توجد طلبات' : 'لا توجد طلبات بهذه الحالة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الطلبات هنا عندما يطلب العملاء خدماتك',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'new';
    final statusColor = ArabicHelpers.getStatusColor(status);
    final statusText = ArabicHelpers.translateOrderStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    'طلب رقم #${order['id'].toString().substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order['customer_name'] ?? 'عميل غير محدد',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (order['customer_phone'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          order['customer_phone'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  if (order['customer_email'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order['customer_email'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Order details
            if (order['total_amount'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'المبلغ: ${ArabicHelpers.formatCurrency(order['total_amount'].toDouble())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (order['scheduled_date'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'موعد الخدمة: ${_formatDateTime(order['scheduled_date'])}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'تاريخ الطلب: ${_formatDateTime(order['created_at'])}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملاحظات العميل:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['notes'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = order['status'] ?? 'new';
    
    return Row(
      children: [
        if (status == 'new') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order['id'], 'accepted'),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('قبول الطلب', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('رفض', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (status == 'accepted') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order['id'], 'in_progress'),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('بدء التنفيذ', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (status == 'in_progress') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order['id'], 'completed'),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('إتمام الطلب', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        
        const SizedBox(width: 8),
        
        // Contact button
        IconButton(
          onPressed: () => _showContactOptions(order),
          icon: const Icon(Icons.message),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseConfig.updateOrderStatus(orderId, newStatus);
      _loadOrders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الطلب إلى: ${ArabicHelpers.translateOrderStatus(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث حالة الطلب: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContactOptions(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'التواصل مع ${order['customer_name']}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (order['customer_phone'] != null)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('اتصال هاتفي'),
                  subtitle: Text(order['customer_phone']),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement phone call
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح تطبيق الهاتف')),
                    );
                  },
                ),
              if (order['customer_phone'] != null)
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.blue),
                  title: const Text('رسالة نصية'),
                  subtitle: Text(order['customer_phone']),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement SMS
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح تطبيق الرسائل')),
                    );
                  },
                ),
              if (order['customer_email'] != null)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.orange),
                  title: const Text('بريد إلكتروني'),
                  subtitle: Text(order['customer_email']),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement email
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح تطبيق البريد')),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateStr.toString());
      return ArabicHelpers.formatDateTime(date);
    } catch (e) {
      return 'غير محدد';
    }
  }
}