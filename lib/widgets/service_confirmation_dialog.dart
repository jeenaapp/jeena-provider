import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

class ServiceConfirmationDialog extends StatefulWidget {
  final String serviceName;
  final String serviceDescription;
  final double price;
  final int duration;
  final int quantity;
  final String city;
  final String serviceType;
  final String? jicsCode;
  final List<Uint8List> images;
  final Uint8List? video;
  final String? warehouseServiceName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ServiceConfirmationDialog({
    Key? key,
    required this.serviceName,
    required this.serviceDescription,
    required this.price,
    required this.duration,
    required this.quantity,
    required this.city,
    required this.serviceType,
    this.jicsCode,
    required this.images,
    this.video,
    this.warehouseServiceName,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ServiceConfirmationDialog> createState() => _ServiceConfirmationDialogState();
}

class _ServiceConfirmationDialogState extends State<ServiceConfirmationDialog> {
  bool _isTermsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFCFA55B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'تأكيد إرسال الخدمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Details Section
                    _buildSectionHeader('تفاصيل الخدمة'),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('اسم الخدمة:', widget.serviceName),
                    _buildDetailRow('الوصف:', widget.serviceDescription, maxLines: 3),
                    _buildDetailRow('السعر:', '${widget.price.toStringAsFixed(2)} ريال سعودي'),
                    _buildDetailRow('مدة التنفيذ:', '${widget.duration} دقيقة'),
                    _buildDetailRow('الكمية:', '${widget.quantity}'),
                    _buildDetailRow('المدينة:', widget.city),
                    _buildDetailRow('نوع الخدمة:', widget.serviceType),
                    
                    if (widget.jicsCode != null && widget.jicsCode!.isNotEmpty)
                      _buildDetailRow('رمز JICS:', widget.jicsCode!),
                    
                    if (widget.warehouseServiceName != null)
                      _buildDetailRow('خدمة المستودع:', widget.warehouseServiceName!),
                    
                    const SizedBox(height: 20),
                    
                    // Media Section
                    _buildSectionHeader('الوسائط المرفقة'),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('عدد الصور:', '${widget.images.length}'),
                    if (widget.video != null)
                      _buildDetailRow('فيديو:', 'مرفق'),
                    
                    // Images Preview
                    if (widget.images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: MemoryImage(widget.images[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Important Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تنويه مهم',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ستتم مراجعة الخدمة من قبل فريق مبيعات جينا، وسيتم نشرها في تطبيق العميل فقط بعد الموافقة عليها.',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Terms and Conditions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الشروط والأحكام',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 12),
                          _buildTermItem('• جميع المعلومات المدخلة صحيحة ومكتملة'),
                          _buildTermItem('• الخدمة جاهزة للتنفيذ عند الطلب'),
                          _buildTermItem('• السعر المحدد نهائي وشامل لجميع التكاليف'),
                          _buildTermItem('• أتعهد بتقديم الخدمة بالجودة المطلوبة'),
                          _buildTermItem('• أوافق على شروط وأحكام منصة جينا'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Confirmation Checkbox
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isTermsAccepted,
                            onChanged: (value) {
                              setState(() {
                                _isTermsAccepted = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFCFA55B),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'أؤكد أن جميع المعلومات صحيحة وأوافق على الشروط والأحكام المذكورة أعلاه',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isTermsAccepted ? widget.onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCFA55B),
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'تأكيد الإرسال',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFFCFA55B),
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}