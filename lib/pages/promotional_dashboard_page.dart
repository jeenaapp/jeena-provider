import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreamflow/services/promotional_service.dart';
import 'package:dreamflow/supabase/supabase_config.dart';
import 'package:dreamflow/models/promotional_models.dart';
import 'package:dreamflow/pages/offer_submission_page.dart';
import 'package:dreamflow/pages/promotion_request_page.dart';
import 'package:dreamflow/utils/arabic_helpers.dart';

class PromotionalDashboardPage extends ConsumerStatefulWidget {
  const PromotionalDashboardPage({super.key});

  @override
  ConsumerState<PromotionalDashboardPage> createState() => _PromotionalDashboardPageState();
}

class _PromotionalDashboardPageState extends ConsumerState<PromotionalDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ServiceOffer> _offers = [];
  List<PaidPromotionRequest> _promotionRequests = [];
  List<Map<String, dynamic>> _userServices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return;

      final offers = await PromotionalService.getProviderOffers(user.id);
      final promotions = await PromotionalService.getProviderPromotionRequests(user.id);
      final services = await SupabaseConfig.getUserServices(user.id);
      
      setState(() {
        _offers = offers;
        _promotionRequests = promotions;
        _userServices = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('حدث خطأ أثناء تحميل البيانات: ${e.toString()}');
    }
  }

  void _navigateToOfferSubmission(String serviceId, String serviceName, double price) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferSubmissionPage(
          serviceId: serviceId,
          serviceName: serviceName,
          originalPrice: price,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToPromotionRequest(String serviceId, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromotionRequestPage(
          serviceId: serviceId,
          serviceName: serviceName,
        ),
      ),
    ).then((_) => _loadData());
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'في انتظار المراجعة';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'active':
        return 'نشط';
      case 'expired':
        return 'منتهي';
      default:
        return status;
    }
  }

  Widget _buildOfferCard(ServiceOffer offer) {
    final service = _userServices.firstWhere(
      (s) => s['id'] == offer.serviceId,
      orElse: () => {'name': 'خدمة غير معروفة'},
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service['name'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(offer.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(offer.status),
                    style: TextStyle(
                      color: _getStatusColor(offer.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Discount info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${offer.discountPercentage}% خصم',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السعر الأصلي: ${offer.originalPrice.toStringAsFixed(2)} ريال',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'السعر بعد الخصم: ${offer.discountedPrice.toStringAsFixed(2)} ريال',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Duration
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'من ${formatArabicDate(offer.offerStartDate)} إلى ${formatArabicDate(offer.offerEndDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),

            // Admin notes if rejected
            if (offer.status == 'rejected' && offer.adminNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ملاحظات الإدارة: ${offer.adminNotes}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Active indicator
            if (offer.isActive) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'العرض نشط الآن!',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionRequestCard(PaidPromotionRequest request) {
    final service = _userServices.firstWhere(
      (s) => s['id'] == request.serviceId,
      orElse: () => {'name': 'خدمة غير معروفة'},
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  request.promotionType == 'header_banner' ? Icons.view_headline : Icons.stars,
                  color: request.promotionType == 'header_banner' ? Colors.purple : Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service['name'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(request.status),
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Promotion type and cost
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.promotionType == 'header_banner' ? 'بانر الرأس' : 'القسم المميز',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المدة: ${request.requestedDurationDays} يوم',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'التكلفة: ${request.promotionCost.toStringAsFixed(2)} ريال',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Requested dates
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'المطلوب: ${formatArabicDate(request.requestedStartDate)} - ${formatArabicDate(request.requestedEndDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),

            // Approved dates if different
            if (request.status == 'approved' && request.approvedStartDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'المعتمد: ${formatArabicDate(request.approvedStartDate!)} - ${formatArabicDate(request.approvedEndDate!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ],

            // Position for featured section
            if (request.promotionType == 'featured_section' && request.approvedPosition != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.format_list_numbered, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'الموضع: ${request.approvedPosition}',
                    style: const TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ],
              ),
            ],

            // Admin notes if rejected
            if (request.status == 'rejected' && request.adminNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ملاحظات الإدارة: ${request.adminNotes}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Active indicator
            if (request.isActive) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'الترويج نشط الآن!',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelectionDialog() {
    return AlertDialog(
      title: const Text('اختر خدمة'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _userServices.length,
          itemBuilder: (context, index) {
            final service = _userServices[index];
            return ListTile(
              leading: const Icon(Icons.business),
              title: Text(service['name']),
              subtitle: Text('${service['price']} ريال'),
              onTap: () {
                Navigator.pop(context);
                _navigateToOfferSubmission(
                  service['id'],
                  service['name'],
                  (service['price'] as num).toDouble(),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  Widget _buildPromotionServiceSelectionDialog() {
    return AlertDialog(
      title: const Text('اختر خدمة للترويج'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _userServices.length,
          itemBuilder: (context, index) {
            final service = _userServices[index];
            return ListTile(
              leading: const Icon(Icons.business),
              title: Text(service['name']),
              subtitle: Text('${service['price']} ريال'),
              onTap: () {
                Navigator.pop(context);
                _navigateToPromotionRequest(
                  service['id'],
                  service['name'],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العروض والترويجات'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'العروض (${_offers.length})',
              icon: const Icon(Icons.local_offer),
            ),
            Tab(
              text: 'الترويجات (${_promotionRequests.length})',
              icon: const Icon(Icons.campaign),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Offers Tab
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _offers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد عروض'),
                              SizedBox(height: 8),
                              Text(
                                'اضغط على زر + لإنشاء عرض جديد',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _offers.length,
                          itemBuilder: (context, index) => _buildOfferCard(_offers[index]),
                        ),
                ),
                
                // Promotions Tab
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _promotionRequests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد طلبات ترويج'),
                              SizedBox(height: 8),
                              Text(
                                'اضغط على زر + لإنشاء طلب ترويج جديد',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _promotionRequests.length,
                          itemBuilder: (context, index) => _buildPromotionRequestCard(_promotionRequests[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userServices.isEmpty) {
            _showErrorDialog('يجب أن تضيف خدمة أولاً قبل إنشاء عرض أو ترويج');
            return;
          }
          
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ماذا تريد أن تفعل؟',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.local_offer, color: Colors.orange),
                    title: const Text('إنشاء عرض خصم'),
                    subtitle: const Text('إنشاء عرض خصم لخدمة معينة'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => _buildServiceSelectionDialog(),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.campaign, color: Colors.purple),
                    title: const Text('طلب ترويج مدفوع'),
                    subtitle: const Text('طلب ترويج الخدمة في بانر الرأس أو القسم المميز'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => _buildPromotionServiceSelectionDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}