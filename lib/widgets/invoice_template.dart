import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../utils/arabic_helpers.dart';

class InvoiceTemplate extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final Map<String, dynamic>? companyInfo;
  final List<Map<String, dynamic>>? invoiceItems;

  const InvoiceTemplate({
    super.key,
    required this.invoice,
    this.companyInfo,
    this.invoiceItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildCompanyInfo(context),
            const SizedBox(height: 20),
            _buildInvoiceInfo(context),
            const SizedBox(height: 20),
            _buildCustomerInfo(context),
            const SizedBox(height: 24),
            _buildItemsSection(context),
            const SizedBox(height: 24),
            _buildTotalSection(context),
            const SizedBox(height: 20),
            _buildPaymentInfo(context),
            const SizedBox(height: 24),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'فاتورة ضريبية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'رقم الفاتورة: ${invoice['invoice_number']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice['status']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ArabicHelpers.translateInvoiceStatus(invoice['status']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات الشركة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B4E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            companyInfo?['name'] ?? 'شركة جينا للخدمات المتميزة',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B4E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                companyInfo?['address'] ?? 'الرياض، المملكة العربية السعودية',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                companyInfo?['phone'] ?? '+966 50 123 4567',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                companyInfo?['email'] ?? 'info@jeena.com',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  'الرقم الضريبي',
                  companyInfo?['tax_number'] ?? '300001234567890',
                  Icons.receipt,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  context,
                  'السجل التجاري',
                  companyInfo?['cr_number'] ?? '1010123456',
                  Icons.business,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            'تاريخ الإصدار',
            _formatDate(invoice['created_at']),
            Icons.calendar_today,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            context,
            'تاريخ الاستحقاق',
            _formatDate(invoice['due_date']),
            Icons.schedule,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات العميل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B4E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            invoice['customer_name'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B4E),
            ),
          ),
          const SizedBox(height: 8),
          if (invoice['customer_email'] != null)
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  invoice['customer_email'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (invoice['customer_phone'] != null)
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  invoice['customer_phone'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

   Widget _buildItemsSection(BuildContext context) {
    final items = invoiceItems ?? [
      {
        'description': invoice['service_type'] ?? 'خدمة',
        'quantity': 1,
        'price': invoice['total_amount'],
        'total': invoice['total_amount'],
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل الخدمات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B4E),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Table(
            border: TableBorder.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                children: [
                  _buildTableCell('الوصف', isHeader: true),
                  _buildTableCell('الكمية', isHeader: true),
                  _buildTableCell('السعر', isHeader: true),
                  _buildTableCell('الإجمالي', isHeader: true),
                ],
              ),
              // Items
              ...items.map((item) => TableRow(
                children: [
                  _buildTableCell(item['description'].toString()),
                  _buildTableCell(item['quantity'].toString(), isCenter: true),
                  _buildTableCell(ArabicHelpers.formatCurrency(item['price']), isCenter: true),
                  _buildTableCell(ArabicHelpers.formatCurrency(item['total']), isCenter: true),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isCenter = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.right,
        style: TextStyle(
          fontSize: isHeader ? 14 : 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    final subtotal = invoice['total_amount'];
    final vat = subtotal * 0.15;
    final total = subtotal + vat;
    final paidAmount = invoice['paid_amount'] ?? 0.0;
    final remainingAmount = total - paidAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTotalRow('المجموع الفرعي', subtotal, false),
          _buildTotalRow('ضريبة القيمة المضافة (15%)', vat, false),
          const Divider(thickness: 2),
          _buildTotalRow('الإجمالي', total, true),
          _buildTotalRow('المبلغ المدفوع', paidAmount, false, Colors.green),
          _buildTotalRow('المبلغ المتبقي', remainingAmount, true, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isBold, [Color? color]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color,
          ),
        ),
        Text(
          ArabicHelpers.formatCurrency(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'معلومات الدفع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'حالة التحويل: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice['transfer_status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ArabicHelpers.translateTransferStatus(invoice['transfer_status']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (invoice['paid_date'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'تاريخ الدفع: ${_formatDate(invoice['paid_date'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملاحظات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B4E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'شكراً لتعاملكم معنا. نحن نقدر ثقتكم في خدماتنا.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'للاستفسارات: info@jeena.com',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                'تم الإنشاء في: ${_formatDate(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (e) {
      return 'غير محدد';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'partial':
      case 'processing':
        return Colors.orange;
      case 'unpaid':
      case 'pending':
        return Colors.red;
      case 'rejected':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }
}