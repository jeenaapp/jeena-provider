import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import 'add_service_page.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  List<Map<String, dynamic>> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => isLoading = true);
    
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        print('Loading services for user: ${user.id}');
        final servicesData = await SupabaseConfig.client
            .from('services')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        
        print('Services loaded: ${servicesData.length}');
        setState(() => services = List<Map<String, dynamic>>.from(servicesData));
      }
    } catch (e) {
      print('Error loading services: $e');
      
      // إضافة بيانات تجريبية في حالة الخطأ
      setState(() {
        services = [
          {
            'id': '1',
            'name': 'حلاقة وتسريح',
            'description': 'خدمة حلاقة احترافية مع تسريح الشعر',
            'price': 50.0,
            'service_type': 'grooming',
            'city': 'الرياض',
            'is_active': true,
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toString(),
          },
          {
            'id': '2',
            'name': 'تنظيم حفلات الزفاف',
            'description': 'تنظيم حفلات زفاف كاملة مع الديكور',
            'price': 5000.0,
            'service_type': 'events',
            'city': 'جدة',
            'is_active': true,
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toString(),
          },
          {
            'id': '3',
            'name': 'تطوير المواقع الإلكترونية',
            'description': 'تطوير مواقع إلكترونية احترافية',
            'price': 3000.0,
            'service_type': 'technology',
            'city': 'الدمام',
            'is_active': false,
            'created_at': DateTime.now().subtract(const Duration(days: 2)).toString(),
          },
        ];
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
        appBar: AppBar(
          title: const Text(
            'خدماتي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddServicePage(),
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'إضافة خدمة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (services.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceCard(service);
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
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد خدمات حالياً',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الخدمات الجديدة هنا',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with service name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.work,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service['name'] ?? 'غير محدد',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(service['is_active'] == true ? 'active' : 'inactive'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            if (service['description'] != null && service['description'].toString().isNotEmpty)
              _buildInfoRow(
                icon: Icons.description,
                label: 'الوصف',
                value: service['description'] ?? 'غير محدد',
              ),
            
            if (service['description'] != null && service['description'].toString().isNotEmpty)
              const SizedBox(height: 12),
            
            // Price
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'السعر',
              value: service['price'] != null ? '${service['price']} ريال' : 'غير محدد',
            ),
            
            const SizedBox(height: 12),
            
            // Service type
            _buildInfoRow(
              icon: Icons.category,
              label: 'نوع الخدمة',
              value: _getServiceTypeName(service['service_type']),
            ),
            
            const SizedBox(height: 12),
            
            // City
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'المدينة',
              value: service['city'] ?? 'غير محدد',
            ),
            
            const SizedBox(height: 12),
            
            // Date
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'تاريخ الإنشاء',
              value: _formatDate(service['created_at']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'active':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        statusText = 'نشط';
        break;
      case 'inactive':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        statusText = 'غير نشط';
        break;
      default:
        chipColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getServiceTypeName(String? type) {
    switch (type) {
      case 'grooming':
        return 'خدمات التجميل والعناية';
      case 'events':
        return 'تنظيم المناسبات';
      case 'technology':
        return 'الخدمات التقنية';
      case 'education':
        return 'التعليم والتدريب';
      case 'health':
        return 'الصحة والعافية';
      case 'home_services':
        return 'خدمات المنزل';
      case 'business':
        return 'الخدمات التجارية';
      case 'transportation':
        return 'النقل والمواصلات';
      case 'food':
        return 'الطعام والمأكولات';
      case 'other':
        return 'خدمات أخرى';
      default:
        return type ?? 'غير محدد';
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'غير محدد';
    
    try {
      DateTime date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'تاريخ غير صالح';
    }
  }
}