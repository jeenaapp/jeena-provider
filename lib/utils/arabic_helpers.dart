import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ArabicHelpers {
  static const Locale arabicLocale = Locale('ar', 'SA');
  
  // Arabic number formatting
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
  
  // Arabic date formatting
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'ar_SA');
    return formatter.format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'ar_SA');
    return formatter.format(dateTime);
  }
  
  // Status translations
  static String translateOrderStatus(String status) {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'accepted':
        return 'مقبول';
      case 'in_progress':
        return 'جاري التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
  
  static String translateInvoiceStatus(String status) {
    switch (status) {
      case 'paid':
        return 'مسددة';
      case 'partial':
        return 'مسددة جزئياً';
      case 'unpaid':
        return 'غير مسددة';
      default:
        return status;
    }
  }
  
  static String translateTransferStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد التحويل';
      case 'completed':
        return 'تم التحويل';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
  
  static String translateSupportStatus(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'محلولة';
      case 'closed':
        return 'مغلقة';
      default:
        return status;
    }
  }
  
  static String translatePriority(String priority) {
    switch (priority) {
      case 'low':
        return 'منخفضة';
      case 'medium':
        return 'متوسطة';
      case 'high':
        return 'عالية';
      case 'urgent':
        return 'عاجلة';
      default:
        return priority;
    }
  }
  
  // Color helpers for status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'new':
      case 'open':
      case 'pending':
        return Colors.blue;
      case 'accepted':
      case 'in_progress':
      case 'processing':
        return Colors.orange;
      case 'completed':
      case 'paid':
      case 'resolved':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'closed':
        return Colors.red;
      case 'partial':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
  
  // Generate JICS code
  static String generateJicsCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'JICS${random.toString().substring(8)}';
  }
  
  // Format phone number
  static String formatPhoneNumber(String phone) {
    if (phone.startsWith('+966')) {
      return phone;
    } else if (phone.startsWith('966')) {
      return '+$phone';
    } else if (phone.startsWith('05')) {
      return '+966${phone.substring(1)}';
    } else if (phone.startsWith('5') && phone.length == 9) {
      return '+966$phone';
    }
    return phone;
  }
  
  // Validate Saudi phone number
  static bool isValidSaudiPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Accept formats: +9665XXXXXXXX, 05XXXXXXXX, 5XXXXXXXX
    return RegExp(r'^(\+966|0)?5[0-9]{8}$').hasMatch(cleanPhone);
  }
  
  // Validate Saudi IBAN
  static bool isValidSaudiIban(String iban) {
    final cleanIban = iban.replaceAll(' ', '').toUpperCase();
    return RegExp(r'^SA[0-9]{22}$').hasMatch(cleanIban);
  }
  
  // Format IBAN for display
  static String formatIban(String iban) {
    final cleanIban = iban.replaceAll(' ', '');
    if (cleanIban.length == 24) {
      return '${cleanIban.substring(0, 4)} ${cleanIban.substring(4, 8)} ${cleanIban.substring(8, 12)} ${cleanIban.substring(12, 16)} ${cleanIban.substring(16, 20)} ${cleanIban.substring(20)}';
    }
    return iban;
  }
  
  // Get time ago in Arabic
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}

// Helper function for formatting Arabic dates
String formatArabicDate(DateTime date) {
  return ArabicHelpers.formatDate(date);
}