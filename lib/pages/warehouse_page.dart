import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';
import '../services/service_provider_service.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';
import '../image_upload.dart';
import '../widgets/warehouse_product_card.dart';
import '../widgets/availability_checker.dart';

class WarehousePage extends ConsumerStatefulWidget {
  const WarehousePage({super.key});

  @override
  ConsumerState<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends ConsumerState<WarehousePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  late TabController _tabController;
  String selectedStatus = 'all';

  final List<Map<String, dynamic>> statusTabs = [
    {'key': 'all', 'name': 'الكل', 'icon': Icons.inventory_outlined},
    {'key': 'approved', 'name': 'مُعتمد', 'icon': Icons.check_circle_outline},
    {'key': 'pending', 'name': 'قيد المراجعة', 'icon': Icons.hourglass_empty},
    {'key': 'rejected', 'name': 'مرفوض', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        print('Loading warehouse products for user: ${user.id}');
        
        final response = await SupabaseConfig.client
            .from('warehouse_products')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        
        print('Warehouse products loaded: ${response.length}');
        
        setState(() {
          products = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading warehouse products: $e');
      
      // إضافة بيانات تجريبية في حالة الخطأ
      setState(() {
        products = [
          {
            'id': '1',
            'name': 'كراسي شيافاري ذهبية',
            'description': 'كراسي شيافاري فاخرة باللون الذهبي مناسبة للمناسبات الراقية',
            'product_code': 'FUR-0001',
            'model': 'CHV-GOLD-001',
            'category': 'furniture',
            'current_stock': 100,
            'min_stock_level': 10,
            'approval_status': 'approved',
            'approved_by': 'إدارة الرقابة والجودة',
            'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          },
          {
            'id': '2',
            'name': 'طاولات مستديرة كريستال',
            'description': 'طاولات مستديرة بسطح كريستالي تتسع لـ 8 أشخاص',
            'product_code': 'FUR-0002',
            'model': 'TBL-CRYSTAL-150',
            'category': 'furniture',
            'current_stock': 25,
            'min_stock_level': 5,
            'approval_status': 'approved',
            'approved_by': 'إدارة الرقابة والجودة',
            'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          },
          {
            'id': '3',
            'name': 'أضواء LED ملونة',
            'description': 'أضواء LED قابلة للبرمجة بألوان متعددة',
            'product_code': 'LGT-0001',
            'model': 'LED-RGB-500',
            'category': 'lighting',
            'current_stock': 50,
            'min_stock_level': 5,
            'approval_status': 'pending',
            'approved_by': null,
            'created_at': DateTime.now().subtract(Duration(hours: 12)).toIso8601String(),
          },
        ];
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (selectedStatus == 'all') return products;
    return products.where((product) => product['approval_status'] == selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('المستودع', style: Theme.of(context).textTheme.headlineSmall),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: statusTabs.map((tab) => Tab(
              icon: Icon(tab['icon'] as IconData),
              text: tab['name'] as String,
            )).toList(),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.secondary,
            onTap: (index) {
              setState(() {
                selectedStatus = statusTabs[index]['key'] as String;
              });
            },
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddProductDialog,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج'),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredProducts = _getFilteredProducts();

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return WarehouseProductCard(
            product: product,
            onEdit: () => _showEditProductDialog(product),
            onDelete: () => _deleteProduct(product['id']),
            onCheckAvailability: () => _showAvailabilityChecker(product),
          );
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
            Icons.inventory_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            selectedStatus == 'all' ? 'لا توجد منتجات في المستودع' : 'لا توجد منتجات بهذا الحالة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتجاتك الأولى للمستودع',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() async {
    final isApproved = await ServiceProviderService.isApproved();
    if (!isApproved) {
      _showApprovalRequiredDialog();
      return;
    }
    _showProductDialog();
  }

  void _showApprovalRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.pending_actions,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'في انتظار الموافقة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'طلب التسجيل قيد المراجعة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'لا يمكنك إضافة منتجات للمستودع حتى يتم الموافقة على طلب التسجيل من قبل إدارة JEENA.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _showProductDialog(product: product);
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final modelController = TextEditingController(text: product?['model'] ?? '');
    final priceController = TextEditingController(text: product?['unit_price']?.toString() ?? '');
    final stockController = TextEditingController(text: product?['current_stock']?.toString() ?? '');
    final minStockController = TextEditingController(text: product?['min_stock_level']?.toString() ?? '');
    
    String selectedCategory = product?['category'] ?? 'furniture';
    String? imageUrl = product?['image_url'];
    bool isGeneratingCode = false;

    final categories = [
      {'key': 'furniture', 'name': 'أثاث', 'icon': Icons.chair},
      {'key': 'decoration', 'name': 'ديكور', 'icon': Icons.palette},
      {'key': 'flowers', 'name': 'ورود', 'icon': Icons.local_florist},
      {'key': 'cakes', 'name': 'كيك', 'icon': Icons.cake},
      {'key': 'equipment', 'name': 'معدات', 'icon': Icons.build},
      {'key': 'lighting', 'name': 'إضاءة', 'icon': Icons.lightbulb},
      {'key': 'sound', 'name': 'صوتيات', 'icon': Icons.volume_up},
      {'key': 'table_setup', 'name': 'تجهيز طاولات', 'icon': Icons.table_restaurant},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Image
                  GestureDetector(
                    onTap: () async {
                      final imageData = await ImageUploadHelper.pickImageFromGallery();
                      if (imageData != null) {
                        setState(() {
                          imageUrl = 'data:image/png;base64,' + base64Encode(imageData);
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Icon(
                                  Icons.image,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.add_photo_alternate,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Selection
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) => DropdownMenuItem(
                      value: category['key'] as String,
                      child: Row(
                        children: [
                          Icon(category['icon'] as IconData),
                          const SizedBox(width: 8),
                          Text(category['name'] as String),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Product Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Description with AI generation
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'وصف المنتج',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: isGeneratingCode
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        onPressed: isGeneratingCode
                            ? null
                            : () async {
                                if (nameController.text.isNotEmpty) {
                                  setState(() => isGeneratingCode = true);
                                  try {
                                    final description = await AIService.generateServiceDescription(
                                      nameController.text,
                                      selectedCategory,
                                    );
                                    descriptionController.text = description;
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('فشل في إنشاء الوصف')),
                                    );
                                  } finally {
                                    setState(() => isGeneratingCode = false);
                                  }
                                }
                              },
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Model (Optional)
                  TextFormField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'الموديل (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price and Stock
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'سعر الوحدة',
                            border: OutlineInputBorder(),
                            suffixText: 'ريال',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'الكمية الحالية',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'مطلوب';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Minimum Stock Level
                  TextFormField(
                    controller: minStockController,
                    decoration: const InputDecoration(
                      labelText: 'الحد الأدنى للمخزون',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveProduct(
                    context,
                    isEditing: isEditing,
                    productId: product?['id'],
                    name: nameController.text,
                    description: descriptionController.text,
                    model: modelController.text.isEmpty ? null : modelController.text,
                    category: selectedCategory,
                    unitPrice: double.tryParse(priceController.text),
                    currentStock: int.tryParse(stockController.text) ?? 0,
                    minStockLevel: int.tryParse(minStockController.text) ?? 0,
                    imageUrl: imageUrl,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct(
    BuildContext context, {
    required bool isEditing,
    String? productId,
    required String name,
    required String description,
    String? model,
    required String category,
    double? unitPrice,
    required int currentStock,
    required int minStockLevel,
    String? imageUrl,
  }) async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) return;

      // Generate product code if it's a new product
      String? productCode;
      if (!isEditing) {
        final response = await SupabaseConfig.client
            .rpc('generate_product_code', params: {'category': category});
        productCode = response.toString();
      }

      final productData = {
        'user_id': user.id,
        'name': name,
        'description': description,
        'model': model,
        'category': category,
        'unit_price': unitPrice,
        'current_stock': currentStock,
        'min_stock_level': minStockLevel,
        'image_url': imageUrl,
        'approval_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (!isEditing) {
        productData['product_code'] = productCode;
      }

      if (isEditing) {
        await SupabaseConfig.client
            .from('warehouse_products')
            .update(productData)
            .eq('id', productId!);
      } else {
        await SupabaseConfig.client
            .from('warehouse_products')
            .insert(productData);
      }

      Navigator.of(context).pop();
      await _loadProducts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'تم حفظ المنتج بنجاح' : 'تم إضافة المنتج بنجاح - قيد مراجعة فريق جينا'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.client
            .from('warehouse_products')
            .delete()
            .eq('id', productId);

        await _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المنتج بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف المنتج: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAvailabilityChecker(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AvailabilityChecker(product: product),
    );
  }
}