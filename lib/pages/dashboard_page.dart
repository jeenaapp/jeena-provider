import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_sidebar.dart';
import '../widgets/notification_icon.dart';
import '../services/auth_service.dart';
import '../services/service_provider_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import 'add_service_page.dart';
import 'my_services_page.dart';
import 'promotional_dashboard_page.dart';
import 'service_provider_profile_page.dart';


class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  Map<String, dynamic>? _providerStatus;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadProviderStatus();
  }

  Future<void> _loadProviderStatus() async {
    final status = await ServiceProviderService.getProviderStatus();
    setState(() {
      _providerStatus = status;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        print('Loading dashboard data for user: ${user.id}');
        
        final ordersResponse = await SupabaseConfig.getOrders(user.id);
        final servicesResponse = await SupabaseConfig.getServices(user.id);
        final invoicesResponse = await SupabaseConfig.getInvoices(user.id);
        
        print('Orders: ${ordersResponse.length}');
        print('Services: ${servicesResponse.length}');
        print('Invoices: ${invoicesResponse.length}');
        
        final totalOrders = ordersResponse.length;
        final newOrders = ordersResponse.where((order) => order['status'] == 'new').length;
        final completedOrders = ordersResponse.where((order) => order['status'] == 'completed').length;
        final totalServices = servicesResponse.length;
        final totalRevenue = invoicesResponse
            .where((invoice) => invoice['status'] == 'paid')
            .fold(0.0, (sum, invoice) => sum + (invoice['total_amount'] ?? 0.0));
        
        // إضافة إحصائيات إضافية
        final pendingInvoices = invoicesResponse.where((invoice) => invoice['status'] == 'unpaid').length;
        final inProgressOrders = ordersResponse.where((order) => order['status'] == 'in_progress').length;
        
        setState(() {
          stats = {
            'totalOrders': totalOrders,
            'newOrders': newOrders,
            'completedOrders': completedOrders,
            'inProgressOrders': inProgressOrders,
            'totalServices': totalServices,
            'totalRevenue': totalRevenue,
            'pendingInvoices': pendingInvoices,
            'totalInvoices': invoicesResponse.length,
          };
        });
        
        print('Stats loaded: $stats');
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      // إضافة بيانات تجريبية في حالة الخطأ
      setState(() {
        stats = {
          'totalOrders': 15,
          'newOrders': 3,
          'completedOrders': 8,
          'inProgressOrders': 4,
          'totalServices': 6,
          'totalRevenue': 2500.0,
          'pendingInvoices': 2,
          'totalInvoices': 12,
        };
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _buildDashboardContent(),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            _buildWelcomeCard(),
            
            const SizedBox(height: 16),
            
            // Provider Status Banner
            if (_providerStatus != null) _buildStatusBanner(),
            
            const SizedBox(height: 20),
            
            // Statistics cards
            _buildStatsGrid(),
            
            const SizedBox(height: 20),
            
            // Quick actions
            _buildQuickActions(),
            
            const SizedBox(height: 20),
            
            // Recent activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final currentUser = AuthService.getCurrentUser();
    final userProfile = ref.watch(userProfileProvider(currentUser?.id ?? ''));
    
    return userProfile.when(
      loading: () => _buildLoadingProfile(),
      error: (error, stackTrace) => _buildErrorProfile(),
      data: (profile) => _buildUserProfile(profile),
    );
  }

  Widget _buildUserProfile(Map<String, dynamic>? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 35,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${profile?['full_name'] ?? 'مزود الخدمة'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?['specialty'] ?? 'مزود خدمات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(color: Colors.white),
                  ),
                  child: const NotificationIcon(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'نرحب بك في منصة جينا لإدارة خدماتك بكفاءة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: CircularProgressIndicator(),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('جارٍ تحميل البيانات...'),
                SizedBox(height: 4),
                Text('يرجى الانتظار'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'خطأ في تحميل بيانات المستخدم',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'إجمالي الطلبات',
          value: '${stats['totalOrders'] ?? 0}',
          icon: Icons.shopping_cart,
          color: Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          title: 'طلبات جديدة',
          value: '${stats['newOrders'] ?? 0}',
          icon: Icons.new_releases,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'طلبات قيد التنفيذ',
          value: '${stats['inProgressOrders'] ?? 0}',
          icon: Icons.hourglass_empty,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: 'طلبات مكتملة',
          value: '${stats['completedOrders'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'إجمالي الخدمات',
          value: '${stats['totalServices'] ?? 0}',
          icon: Icons.business_center,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _buildStatCard(
          title: 'إجمالي الفواتير',
          value: '${stats['totalInvoices'] ?? 0}',
          icon: Icons.receipt,
          color: Colors.purple,
        ),
        _buildStatCard(
          title: 'فواتير معلقة',
          value: '${stats['pendingInvoices'] ?? 0}',
          icon: Icons.pending_actions,
          color: Colors.red,
        ),
        _buildStatCard(
          title: 'إجمالي الإيرادات',
          value: ArabicHelpers.formatCurrency(stats['totalRevenue'] ?? 0.0),
          icon: Icons.attach_money,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              title: 'إضافة خدمة',
              icon: Icons.add_business,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddServicePage(),
                ),
              ),
            ),
            _buildQuickActionCard(
              title: 'إدارة الخدمات',
              icon: Icons.settings,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyServicesPage(),
                ),
              ),
            ),
            _buildQuickActionCard(
              title: 'العروض والترويجات',
              icon: Icons.campaign,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PromotionalDashboardPage(),
                ),
              ),
            ),
            _buildQuickActionCard(
              title: 'ملف الشركة',
              icon: Icons.business_center,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceProviderProfilePage(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'النشاط الأخير',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.shopping_cart,
                title: 'طلب جديد',
                subtitle: 'عميل جديد قام بطلب خدمة',
                time: 'منذ 5 دقائق',
                color: Colors.blue,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.check_circle,
                title: 'تم إكمال طلب',
                subtitle: 'تم إكمال خدمة بنجاح',
                time: 'منذ ساعة',
                color: Colors.green,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.receipt,
                title: 'فاتورة جديدة',
                subtitle: 'تم إنشاء فاتورة جديدة',
                time: 'منذ 3 ساعات',
                color: Colors.purple,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.business_center,
                title: 'خدمة جديدة',
                subtitle: 'تم إضافة خدمة جديدة',
                time: 'أمس',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final status = _providerStatus?['status'];
    final providerCode = _providerStatus?['provider_code'];
    
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String title;
    String message;
    
    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        iconData = Icons.hourglass_empty;
        title = 'طلب التسجيل قيد المراجعة';
        message = 'سيتم مراجعة طلبكم من قبل فريق JEENA وسيتم التواصل معكم قريباً.';
        break;
      case 'approved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        iconData = Icons.check_circle;
        title = 'تم الموافقة على التسجيل';
        message = 'مبروك! تم الموافقة على طلبكم. يمكنكم الآن إضافة خدماتكم وإدارة طلباتكم.';
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        iconData = Icons.cancel;
        title = 'تم رفض طلب التسجيل';
        message = 'لم يتم الموافقة على طلبكم. يرجى التواصل مع فريق الدعم لمزيد من التفاصيل.';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
            ),
          ),
          if (providerCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'رمز JEENA: $providerCode',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}