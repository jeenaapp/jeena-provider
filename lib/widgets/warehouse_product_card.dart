import 'package:flutter/material.dart';
import '../utils/arabic_helpers.dart';


class WarehouseProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCheckAvailability;

  const WarehouseProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onCheckAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final approvalStatus = product['approval_status'] as String;
    final currentStock = product['current_stock'] as int? ?? 0;
    final minStockLevel = product['min_stock_level'] as int? ?? 0;
    final isLowStock = currentStock <= minStockLevel;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image and Status
            Stack(
              children: [
                _buildProductImage(context),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStatusChip(context, approvalStatus),
                ),
                if (isLowStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'مخزون منخفض',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Product Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Code
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? 'غير محدد',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (product['product_code'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product['product_code'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  if (product['description'] != null)
                    Text(
                      product['description'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  
                  // Category and Model
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(product['category']),
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryName(product['category']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (product['model'] != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product['model'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Stock and Price Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          icon: Icons.inventory_2,
                          label: 'المخزون',
                          value: '$currentStock قطعة',
                          color: isLowStock ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (product['unit_price'] != null)
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            icon: Icons.attach_money,
                            label: 'السعر',
                            value: ArabicHelpers.formatCurrency(product['unit_price']),
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Approval Status Message
                  if (approvalStatus == 'pending')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 20,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المنتج قيد المراجعة من فريق جينا المختص',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (approvalStatus == 'approved' && product['approved_by'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم اعتماد المنتج من قبل: ${product['approved_by']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (approvalStatus == 'rejected')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تم رفض المنتج',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product['rejection_reason'] != null)
                                  Text(
                                    'السبب: ${product['rejection_reason']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (approvalStatus == 'approved') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCheckAvailability,
                            icon: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(
                              'فحص التوفر',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          label: Text(
                            'تعديل',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: product['image_url'] != null
            ? Image.network(
                product['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildPlaceholderImage(context),
              )
            : _buildPlaceholderImage(context),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    final category = product['category'] as String? ?? 'furniture';
    final imageUrl = "https://images.unsplash.com/photo-1615715757274-29f82b8f5488?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTI0MTUwMjZ8&ixlib=rb-4.1.0&q=80&w=1080";
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _buildDefaultPlaceholder(context),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(product['category']),
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color chipColor;
    Color textColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        chipColor = Colors.green;
        textColor = Colors.white;
        statusText = 'مُعتمد';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        chipColor = Theme.of(context).colorScheme.error;
        textColor = Colors.white;
        statusText = 'مرفوض';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        chipColor = Colors.orange;
        textColor = Colors.white;
        statusText = 'قيد المراجعة';
        statusIcon = Icons.hourglass_empty;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'furniture':
        return Icons.chair;
      case 'decoration':
        return Icons.palette;
      case 'flowers':
        return Icons.local_florist;
      case 'cakes':
        return Icons.cake;
      case 'equipment':
        return Icons.build;
      case 'lighting':
        return Icons.lightbulb;
      case 'sound':
        return Icons.volume_up;
      case 'table_setup':
        return Icons.table_restaurant;
      default:
        return Icons.inventory;
    }
  }

  String _getCategoryName(String? category) {
    switch (category) {
      case 'furniture':
        return 'أثاث';
      case 'decoration':
        return 'ديكور';
      case 'flowers':
        return 'ورود';
      case 'cakes':
        return 'كيك';
      case 'equipment':
        return 'معدات';
      case 'lighting':
        return 'إضاءة';
      case 'sound':
        return 'صوتيات';
      case 'table_setup':
        return 'تجهيز طاولات';
      default:
        return 'أخرى';
    }
  }

  String _getImageKeyword(String category) {
    switch (category) {
      case 'furniture':
        return 'luxury furniture';
      case 'decoration':
        return 'event decoration';
      case 'flowers':
        return 'wedding flowers';
      case 'cakes':
        return 'wedding cake';
      case 'equipment':
        return 'event equipment';
      case 'lighting':
        return 'event lighting';
      case 'sound':
        return 'audio equipment';
      case 'table_setup':
        return 'table setting';
      default:
        return 'event supplies';
    }
  }

  String _getImageCategory(String category) {
    switch (category) {
      case 'furniture':
        return 'business';
      case 'decoration':
        return 'fashion';
      case 'flowers':
        return 'nature';
      case 'cakes':
        return 'food';
      case 'equipment':
        return 'industry';
      case 'lighting':
        return 'business';
      case 'sound':
        return 'music';
      case 'table_setup':
        return 'food';
      default:
        return 'business';
    }
  }
}