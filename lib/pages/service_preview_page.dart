import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../widgets/media_carousel.dart';
import '../utils/media_validation.dart';
import '../supabase/supabase_config.dart';

class ServicePreviewPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> service;
  
  const ServicePreviewPage({
    super.key,
    required this.service,
  });

  @override
  ConsumerState<ServicePreviewPage> createState() => _ServicePreviewPageState();
}

class _ServicePreviewPageState extends ConsumerState<ServicePreviewPage> {
  List<MediaFile> _mediaFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  void _loadMedia() async {
    try {
      List<MediaFile> mediaFiles = [];
      
      // Load images
      final imageUrls = widget.service['image_urls'] as List<dynamic>? ?? [];
      for (int i = 0; i < imageUrls.length; i++) {
        final imageUrl = imageUrls[i].toString();
        try {
          // In a real implementation, you'd download the image bytes
          // For now, we'll create a placeholder
          final mediaFile = MediaFile(
            name: 'image_$i.jpg',
            bytes: Uint8List.fromList(await _downloadMediaBytes(imageUrl)),
            type: 'image',
          );
          mediaFiles.add(mediaFile);
        } catch (e) {
          print('Failed to load image $i: $e');
        }
      }
      
      // Load video if available
      final videoUrl = widget.service['video_url'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        try {
          final videoFile = MediaFile(
            name: 'service_video.mp4',
            bytes: Uint8List.fromList(await _downloadMediaBytes(videoUrl)),
            type: 'video',
          );
          mediaFiles.add(videoFile);
        } catch (e) {
          print('Failed to load video: $e');
        }
      }
      
      setState(() {
        _mediaFiles = mediaFiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading media: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<int>> _downloadMediaBytes(String url) async {
    // In a real implementation, you'd use http to download the file
    // For now, return empty bytes as placeholder
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'معاينة الخدمة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaSection(),
                  _buildServiceInfo(),
                  _buildServiceDetails(),
                  _buildAdminStatus(),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to edit service page
          Navigator.of(context).pushNamed('/edit_service', arguments: widget.service);
        },
        icon: const Icon(Icons.edit),
        label: const Text('تعديل الخدمة'),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'الصور والفيديوهات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_mediaFiles.where((m) => m.type == 'image').length} صور',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_mediaFiles.isNotEmpty)
            MediaCarousel(
              mediaFiles: _mediaFiles,
              height: 250,
              showControls: true,
              isEditable: false,
            )
          else
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'لا توجد صور أو فيديوهات',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getServiceTypeIcon(widget.service['service_type']),
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.service['name'] ?? 'اسم الخدمة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.service['description'] ?? 'وصف الخدمة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.attach_money,
                label: '${widget.service['price']} ريال',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${widget.service['duration_minutes']} دقيقة',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.location_city,
                label: widget.service['city'] ?? 'المدينة',
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.inventory,
                label: 'الكمية: ${widget.service['quantity']}',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل إضافية',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'نوع الخدمة',
            _getServiceTypeName(widget.service['service_type']),
          ),
          _buildDetailRow(
            'تاريخ الإنشاء',
            _formatDate(widget.service['created_at']),
          ),
          if (widget.service['internal_code'] != null)
            _buildDetailRow(
              'رمز JICS',
              widget.service['internal_code'].toString(),
            ),
          _buildDetailRow(
            'حالة الخدمة',
            widget.service['is_active'] == true ? 'نشط' : 'غير نشط',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatus() {
    final adminStatus = widget.service['admin_status'] ?? 'pending';
    final adminNotes = widget.service['admin_notes'] as String?;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (adminStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'تم الموافقة';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'قيد المراجعة';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'حالة المراجعة الإدارية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (adminNotes != null && adminNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'ملاحظات الإدارة:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                adminNotes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceTypeIcon(String? serviceType) {
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
        return Icons.more_horiz;
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'تاريخ غير صالح';
    }
  }
}