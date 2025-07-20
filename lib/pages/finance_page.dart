import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import '../widgets/invoice_template.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> invoices = [];
  Map<String, dynamic>? balance;
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() => isLoading = true);
    
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        print('Loading finance data for user: ${user.id}');
        
        final invoicesData = await SupabaseConfig.getInvoices(user.id);
        print('Invoices loaded: ${invoicesData.length}');
        
        // Load balance data
        final balanceData = await SupabaseConfig.client
            .from('balance')
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();
        
        print('Balance loaded: $balanceData');
        
        setState(() {
          invoices = invoicesData;
          balance = balanceData;
        });
      }
    } catch (e) {
      print('Error loading finance data: $e');
      
      // إضافة بيانات تجريبية في حالة الخطأ
        // Add sample data for testing
        setState(() {
          invoices = [
            {
              'id': '1',
              'invoice_number': 'INV-20241201-001',
              'customer_name': 'أحمد محمد العلي',
              'customer_email': 'ahmed.ali@email.com',
              'customer_phone': '+966 50 123 4567',
              'service_type': 'حلاقة وتسريح احترافية',
              'total_amount': 150.0,
              'paid_amount': 150.0,
              'status': 'paid',
              'due_date': '2024-12-01',
              'paid_date': '2024-11-30',
              'transfer_status': 'completed',
              'created_at': '2024-11-25',
            },
            {
              'id': '2',
              'invoice_number': 'INV-20241202-002',
              'customer_name': 'فاطمة أحمد الزهراني',
              'customer_email': 'fatima.ahmed@email.com',
              'customer_phone': '+966 55 987 6543',
              'service_type': 'تنظيم حفلات الزفاف الفاخرة',
              'total_amount': 5000.0,
              'paid_amount': 2500.0,
              'status': 'partial',
              'due_date': '2024-12-15',
              'paid_date': null,
              'transfer_status': 'pending',
              'created_at': '2024-11-28',
            },
            {
              'id': '3',
              'invoice_number': 'INV-20241203-003',
              'customer_name': 'عبدالله سالم النجار',
              'customer_email': 'abdullah.salem@email.com',
              'customer_phone': '+966 56 789 0123',
              'service_type': 'تطوير موقع إلكتروني متجاوب',
              'total_amount': 3000.0,
              'paid_amount': 0.0,
              'status': 'unpaid',
              'due_date': '2024-12-20',
              'paid_date': null,
              'transfer_status': 'pending',
              'created_at': '2024-12-01',
            },
            {
              'id': '4',
              'invoice_number': 'INV-20241204-004',
              'customer_name': 'نوف محمد الشهري',
              'customer_email': 'nouf.mohammed@email.com',
              'customer_phone': '+966 53 456 7890',
              'service_type': 'تنسيق حفلات التخرج',
              'total_amount': 2500.0,
              'paid_amount': 1250.0,
              'status': 'partial',
              'due_date': '2024-12-25',
              'paid_date': null,
              'transfer_status': 'processing',
              'created_at': '2024-12-02',
            },
            {
              'id': '5',
              'invoice_number': 'INV-20241205-005',
              'customer_name': 'خالد عبدالرحمن',
              'customer_email': 'khalid.abdulrahman@email.com',
              'customer_phone': '+966 54 321 0987',
              'service_type': 'صيانة أجهزة الكمبيوتر',
              'total_amount': 800.0,
              'paid_amount': 800.0,
              'status': 'paid',
              'due_date': '2024-11-30',
              'paid_date': '2024-11-28',
              'transfer_status': 'completed',
              'created_at': '2024-11-20',
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الفواتير والرصيد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: const [
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'الرصيد'),
              Tab(icon: Icon(Icons.receipt), text: 'الفواتير'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBalanceTab(),
            _buildInvoicesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current balance card
          _buildBalanceCard(),
          
          const SizedBox(height: 20),
          
          // Statistics cards
          _buildBalanceStats(),
          
          const SizedBox(height: 20),
          
          // Transfer info
          _buildTransferInfo(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final currentBalance = balance?['current_balance']?.toDouble() ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'رصيدك الحالي',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Text(
            ArabicHelpers.formatCurrency(currentBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'المبلغ المتاح للسحب',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStats() {
    final totalEarned = balance?['total_earned']?.toDouble() ?? 0.0;
    final totalWithdrawn = balance?['total_withdrawn']?.toDouble() ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'إجمالي الأرباح',
            amount: totalEarned,
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'إجمالي المسحوبات',
            amount: totalWithdrawn,
            icon: Icons.trending_down,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            ArabicHelpers.formatCurrency(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات التحويل',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('موعد التحويل', 'خلال 7 أيام عمل من تاريخ الموافقة'),
          _buildInfoRow('الحد الأدنى للسحب', '100 ريال سعودي'),
          _buildInfoRow('رسوم التحويل', 'مجاني'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _requestWithdrawal(),
              icon: const Icon(Icons.account_balance, color: Colors.white),
              label: const Text('طلب سحب الرصيد', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invoices.isEmpty) {
      return _buildEmptyInvoices();
    }

    return RefreshIndicator(
      onRefresh: _loadFinanceData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return _buildInvoiceCard(invoices[index]);
        },
      ),
    );
  }

  Widget _buildEmptyInvoices() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الفواتير هنا عند إتمام الطلبات',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final status = invoice['status'] ?? 'unpaid';
    final statusColor = ArabicHelpers.getStatusColor(status);
    final statusText = ArabicHelpers.translateInvoiceStatus(status);
    final transferStatus = invoice['transfer_status'] ?? 'pending';
    final transferStatusText = ArabicHelpers.translateTransferStatus(transferStatus);

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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'فاتورة ${invoice['invoice_number'] ?? '#'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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

            // Customer and service info
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
                      Text(
                        invoice['customer_name'] ?? 'عميل غير محدد',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (invoice['service_type'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_center, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          invoice['service_type'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Amount details
            Row(
              children: [
                Expanded(
                  child: _buildAmountDetail(
                    'إجمالي المبلغ',
                    invoice['total_amount']?.toDouble() ?? 0.0,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAmountDetail(
                    'المبلغ المدفوع',
                    invoice['paid_amount']?.toDouble() ?? 0.0,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الاستحقاق',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDate(invoice['due_date']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (invoice['paid_date'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ الدفع',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDate(invoice['paid_date']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Transfer status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArabicHelpers.getStatusColor(transferStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ArabicHelpers.getStatusColor(transferStatus).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 16,
                    color: ArabicHelpers.getStatusColor(transferStatus),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'حالة التحويل: $transferStatusText',
                    style: TextStyle(
                      color: ArabicHelpers.getStatusColor(transferStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showFullInvoice(invoice),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('عرض الفاتورة'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadPDF(invoice),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('تحميل PDF'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (status != 'paid')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _requestPayment(invoice),
                      icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                      label: const Text('مطالبة بالدفع', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDetail(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          ArabicHelpers.formatCurrency(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateStr.toString());
      return ArabicHelpers.formatDate(date);
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _requestWithdrawal() {
    final currentBalance = balance?['current_balance']?.toDouble() ?? 0.0;
    
    if (currentBalance < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأدنى للسحب 100 ريال سعودي'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('طلب سحب الرصيد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الرصيد المتاح: ${ArabicHelpers.formatCurrency(currentBalance)}'),
              const SizedBox(height: 16),
              const Text('سيتم تحويل المبلغ إلى حسابك البنكي المسجل خلال 7 أيام عمل.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال طلب السحب بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد السحب'),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadPDF(Map<String, dynamic> invoice) {
    // TODO: Implement PDF generation and download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تحميل الفاتورة قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showFullInvoice(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'فاتورة ${invoice['invoice_number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: InvoiceTemplate(
                    invoice: invoice,
                    companyInfo: {
                      'name': 'شركة جينا للخدمات المتميزة',
                      'address': 'الرياض، المملكة العربية السعودية',
                      'phone': '+966 50 123 4567',
                      'email': 'info@jeena.com',
                      'tax_number': '300001234567890',
                      'cr_number': '1010123456',
                    },
                  ),
                ),
              ),
              // Footer buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadPDF(invoice),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('تحميل PDF'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _requestPayment(invoice),
                        icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                        label: const Text('مطالبة بالدفع', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestPayment(Map<String, dynamic> invoice) {
    // TODO: Implement payment request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال مطالبة الدفع'),
      ),
    );
  }
}