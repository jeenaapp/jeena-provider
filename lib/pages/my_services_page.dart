import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import 'add_service_page.dart';
import 'edit_service_page.dart';


class MyServicesPage extends ConsumerStatefulWidget {
  const MyServicesPage({super.key});

  @override
  ConsumerState<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends ConsumerState<MyServicesPage> {
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
        final servicesData = await SupabaseConfig.getUserServices(user.id);
        setState(() {
          services = servicesData;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('فشل في تحميل الخدمات: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadServices,
            ),
          ],
        ),
        body: isLoading ? _buildLoadingState() : _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddServicePage(),
              ),
            );
            _loadServices(); // Refresh services after adding new one
          },
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBody() {
    if (services.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(services[index]);
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
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد خدمات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة خدمتك الأولى',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final serviceType = service['service_type'] ?? 'other';
    final imageUrl = service['image_url'] as String?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        "https://images.unsplash.com/photo-1673526759322-2b43a11d75fe?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTI2MjMzMjB8&ixlib=rb-4.1.0&q=80&w=1080",
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getServiceIcon(serviceType),
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : null,
          ),
          
          // Service Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service['name'] ?? 'خدمة غير محددة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(service['is_active'] ?? false),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Service Type
                _buildInfoRow(
                  icon: Icons.category,
                  label: 'نوع الخدمة',
                  value: _getServiceTypeName(serviceType),
                ),
                const SizedBox(height: 8),
                
                // Price and Duration
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.attach_money,
                        label: 'السعر',
                        value: ArabicHelpers.formatCurrency(
                          (service['price'] as num?)?.toDouble() ?? 0.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'المدة',
                        value: '${service['duration_minutes'] ?? 0} دقيقة',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // City
                _buildInfoRow(
                  icon: Icons.location_city,
                  label: 'المدينة',
                  value: service['city'] ?? 'غير محدد',
                ),
                const SizedBox(height: 12),
                
                // Description
                if (service['description'] != null && service['description'].toString().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service['description'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Created Date
                Text(
                  'تم الإنشاء في: ${_formatDate(service['created_at'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editService(service),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleServiceStatus(service),
                        icon: Icon(
                          service['is_active'] ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        label: Text(service['is_active'] ? 'إخفاء' : 'إظهار'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: service['is_active'] ? Colors.orange : Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteService(service),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('حذف'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        isActive ? 'نشط' : 'معطل',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getServiceIcon(String? serviceType) {
    switch (serviceType) {
      case 'grooming':
        return Icons.face;
      case 'events':
        return Icons.celebration;
      case 'technology':
        return Icons.computer;
      case 'education':
        return Icons.school;
      case 'health':
        return Icons.healing;
      case 'home_services':
        return Icons.home_repair_service;
      case 'business':
        return Icons.business;
      case 'transportation':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.business;
    }
  }

  String _getServiceTypeName(String? serviceType) {
    switch (serviceType) {
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
      default:
        return 'خدمات أخرى';
    }
  }

  String _getImageKeyword(String serviceType) {
    switch (serviceType) {
      case 'grooming':
        return 'beauty salon';
      case 'events':
        return 'wedding party';
      case 'technology':
        return 'computer technology';
      case 'education':
        return 'education classroom';
      case 'health':
        return 'healthcare wellness';
      case 'home_services':
        return 'home repair';
      case 'business':
        return 'business office';
      case 'transportation':
        return 'transportation car';
      case 'food':
        return 'restaurant food';
      default:
        return 'service business';
    }
  }

  String _getImageCategory(String serviceType) {
    switch (serviceType) {
      case 'grooming':
        return 'people';
      case 'events':
        return 'people';
      case 'technology':
        return 'computer';
      case 'education':
        return 'education';
      case 'health':
        return 'health';
      case 'home_services':
        return 'buildings';
      case 'business':
        return 'business';
      case 'transportation':
        return 'transportation';
      case 'food':
        return 'food';
      default:
        return 'business';
    }
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

  Future<void> _editService(Map<String, dynamic> service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditServicePage(service: service),
      ),
    );
    
    if (result == true) {
      _loadServices(); // Refresh the list after editing
    }
  }

  Future<void> _toggleServiceStatus(Map<String, dynamic> service) async {
    try {
      final newStatus = !service['is_active'];
      
      await SupabaseConfig.client
          .from('services')
          .update({'is_active': newStatus})
          .eq('id', service['id']);
      
      _loadServices(); // Refresh the list
      
      _showSuccessSnackBar(
        newStatus ? 'تم تفعيل الخدمة بنجاح' : 'تم إخفاء الخدمة بنجاح',
      );
    } catch (e) {
      _showErrorSnackBar('فشل في تحديث حالة الخدمة: ${e.toString()}');
    }
  }

  Future<void> _deleteService(Map<String, dynamic> service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الخدمة'),
        content: Text('هل أنت متأكد من حذف خدمة "${service['name']}"؟\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete media files if they exist
        final imageUrls = service['image_urls'] as List<dynamic>?;
        final videoUrl = service['video_url'] as String?;
        
        if (imageUrls != null && imageUrls.isNotEmpty) {
          await SupabaseConfig.deleteMediaFiles(imageUrls.cast<String>());
        }
        
        if (videoUrl != null) {
          await SupabaseConfig.deleteMediaFiles([videoUrl]);
        }
        
        // Delete the service from database
        await SupabaseConfig.client
            .from('services')
            .delete()
            .eq('id', service['id']);
        
        _loadServices(); // Refresh the list
        _showSuccessSnackBar('تم حذف الخدمة بنجاح');
      } catch (e) {
        _showErrorSnackBar('فشل في حذف الخدمة: ${e.toString()}');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}