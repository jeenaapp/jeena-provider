import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreamflow/services/promotional_service.dart';
import 'package:dreamflow/supabase/supabase_config.dart';
import 'package:dreamflow/models/promotional_models.dart';
import 'package:dreamflow/utils/arabic_helpers.dart';

class AdminReviewPage extends ConsumerStatefulWidget {
  const AdminReviewPage({super.key});

  @override
  ConsumerState<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends ConsumerState<AdminReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<ServiceOffer> _pendingOffers = [];
  List<PaidPromotionRequest> _pendingPromotions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingItems() async {
    setState(() => _isLoading = true);
    try {
      final offers = await PromotionalService.getPendingOffers();
      final promotions = await PromotionalService.getPendingPromotionRequests();
      
      setState(() {
        _pendingOffers = offers;
        _pendingPromotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('حدث خطأ أثناء تحميل البيانات: ${e.toString()}');
    }
  }

  Future<void> _reviewOffer(ServiceOffer offer, bool approve) async {
    final TextEditingController notesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'الموافقة على العرض' : 'رفض العرض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من ${approve ? 'الموافقة على' : 'رفض'} هذا العرض؟'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الإدارة',
                hintText: 'أدخل ملاحظات للمزود (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'موافق' : 'رفض'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = SupabaseConfig.currentUser;
        if (user == null) return;

        await PromotionalService.updateOfferStatus(
          offer.id,
          approve ? 'approved' : 'rejected',
          user.id,
          notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );

        // Send notification to provider
        await SupabaseConfig.createNotification({
          'user_id': offer.providerId,
          'title': approve ? 'تم الموافقة على العرض' : 'تم رفض العرض',
          'message': approve
              ? 'تم الموافقة على العرض الخاص بك وسيظهر في التطبيق'
              : 'تم رفض العرض الخاص بك. ${notesController.text.trim()}',
          'type': approve ? 'success' : 'error',
        });

        _loadPendingItems();
        _showSuccessDialog('تم ${approve ? 'الموافقة على' : 'رفض'} العرض بنجاح');
      } catch (e) {
        _showErrorDialog('حدث خطأ أثناء المراجعة: ${e.toString()}');
      }
    }
  }

  Future<void> _reviewPromotionRequest(PaidPromotionRequest request, bool approve) async {
    final TextEditingController notesController = TextEditingController();
    final TextEditingController positionController = TextEditingController();
    DateTime? approvedStartDate = request.requestedStartDate;
    DateTime? approvedEndDate = request.requestedEndDate;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'الموافقة على طلب الترويج' : 'رفض طلب الترويج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('هل أنت متأكد من ${approve ? 'الموافقة على' : 'رفض'} طلب الترويج؟'),
              const SizedBox(height: 16),
              
              if (approve) ...[
                // Position input for featured section
                if (request.promotionType == 'featured_section') ...[
                  TextField(
                    controller: positionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الموضع في القسم المميز',
                      hintText: 'مثال: 1, 2, 3...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Date adjustments
                const Text('يمكنك تعديل التواريخ حسب المتاح:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: approvedStartDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            approvedStartDate = picked;
                          }
                        },
                        child: Text(
                          'تاريخ البداية: ${approvedStartDate != null ? formatArabicDate(approvedStartDate!) : 'اختر'}',
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: approvedEndDate ?? DateTime.now(),
                            firstDate: approvedStartDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            approvedEndDate = picked;
                          }
                        },
                        child: Text(
                          'تاريخ النهاية: ${approvedEndDate != null ? formatArabicDate(approvedEndDate!) : 'اختر'}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات الإدارة',
                  hintText: 'أدخل ملاحظات للمزود (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'موافق' : 'رفض'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = SupabaseConfig.currentUser;
        if (user == null) return;

        int? approvedPosition;
        if (approve && request.promotionType == 'featured_section') {
          approvedPosition = int.tryParse(positionController.text) ?? 
              await PromotionalService.getNextAvailablePosition('featured_section');
        }

        await PromotionalService.updatePromotionRequestStatus(
          request.id,
          approve ? 'approved' : 'rejected',
          user.id,
          notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          approvedStartDate,
          approvedEndDate,
          approvedPosition,
        );

        // Send notification to provider
        await SupabaseConfig.createNotification({
          'user_id': request.providerId,
          'title': approve ? 'تم الموافقة على طلب الترويج' : 'تم رفض طلب الترويج',
          'message': approve
              ? 'تم الموافقة على طلب الترويج الخاص بك. يرجى إكمال الدفع لتفعيله.'
              : 'تم رفض طلب الترويج الخاص بك. ${notesController.text.trim()}',
          'type': approve ? 'success' : 'error',
        });

        _loadPendingItems();
        _showSuccessDialog('تم ${approve ? 'الموافقة على' : 'رفض'} طلب الترويج بنجاح');
      } catch (e) {
        _showErrorDialog('حدث خطأ أثناء المراجعة: ${e.toString()}');
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

  Widget _buildOfferCard(ServiceOffer offer) {
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
                    'عرض خصم',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${offer.discountPercentage}% خصم',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service Details
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('معرف الخدمة: '),
                Text(offer.serviceId.substring(0, 8)),
              ],
            ),
            const SizedBox(height: 4),

            // Pricing
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'السعر الأصلي: ${offer.originalPrice.toStringAsFixed(2)} ريال',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_offer, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'السعر بعد الخصم: ${offer.discountedPrice.toStringAsFixed(2)} ريال',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
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
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Created date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'تم الإنشاء: ${formatArabicDate(offer.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewOffer(offer, false),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewOffer(offer, true),
                    icon: const Icon(Icons.check),
                    label: const Text('موافق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildPromotionRequestCard(PaidPromotionRequest request) {
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
                    request.promotionType == 'header_banner' ? 'بانر الرأس' : 'القسم المميز',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${request.promotionCost.toStringAsFixed(2)} ريال',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service Details
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('معرف الخدمة: '),
                Text(request.serviceId.substring(0, 8)),
              ],
            ),
            const SizedBox(height: 4),

            // Duration
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('المدة: ${request.requestedDurationDays} يوم'),
              ],
            ),
            const SizedBox(height: 4),

            // Requested dates
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'من ${formatArabicDate(request.requestedStartDate)} إلى ${formatArabicDate(request.requestedEndDate)}',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Created date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'تم الإنشاء: ${formatArabicDate(request.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewPromotionRequest(request, false),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewPromotionRequest(request, true),
                    icon: const Icon(Icons.check),
                    label: const Text('موافق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة العروض والترويجات'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingItems,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'العروض (${_pendingOffers.length})',
              icon: const Icon(Icons.local_offer),
            ),
            Tab(
              text: 'الترويجات (${_pendingPromotions.length})',
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
                  onRefresh: _loadPendingItems,
                  child: _pendingOffers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد عروض في انتظار المراجعة'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingOffers.length,
                          itemBuilder: (context, index) => _buildOfferCard(_pendingOffers[index]),
                        ),
                ),
                
                // Promotions Tab
                RefreshIndicator(
                  onRefresh: _loadPendingItems,
                  child: _pendingPromotions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('لا توجد طلبات ترويج في انتظار المراجعة'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingPromotions.length,
                          itemBuilder: (context, index) => _buildPromotionRequestCard(_pendingPromotions[index]),
                        ),
                ),
              ],
            ),
    );
  }
}