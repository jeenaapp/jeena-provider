import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../supabase/supabase_config.dart';
import '../models/service_provider_model.dart';

class ServiceProviderService {
  static Future<Map<String, dynamic>> submitServiceProvider({
    required String fullName,
    String? email,
    String? phone,
    required String city,
    required String serviceType,
    required String description,
    Uint8List? imageBytes,
  }) async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final url = Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/service_providers');
      
      final headers = {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.client.auth.currentSession?.accessToken ?? SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

      final body = {
        'name': fullName,
        'service_type': serviceType,
        'city': city,
        'description': description,
        'status': 'pending',
        'user_id': user.id,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'تم إرسال طلب التسجيل بنجاح',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'حدث خطأ في إرسال البيانات',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في الاتصال: ${e.toString()}',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getServiceProviders() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = await SupabaseConfig.client
          .from('service_providers')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل في تحميل البيانات: ${e.toString()}');
    }
  }

  static Future<void> updateServiceProvider(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      await SupabaseConfig.client
          .from('service_providers')
          .update(updates)
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('فشل في تحديث البيانات: ${e.toString()}');
    }
  }

  static Future<void> deleteServiceProvider(String id) async {
    try {
      await SupabaseConfig.client
          .from('service_providers')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('حدث خطأ أثناء حذف البيانات: ${e.toString()}');
    }
  }

  static Future<bool> hasCompletedProfile() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return false;

      final response = await SupabaseConfig.client
          .from('service_providers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // JEENA Comprehensive Registration Method
  static Future<Map<String, dynamic>> submitServiceProviderRegistration({
    required String commercialName,
    required String registeredName,
    required String authorizedPersonName,
    required String idNumber,
    required String phone,
    required String email,
    required String city,
    required String streetAddress,
    required String serviceType,
    required String description,
    Uint8List? logoBytes,
    List<Map<String, String>>? branches,
    String? taxNumber,
    String? bankAccount,
    String? iban,
  }) async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Generate JICS code
      final jicsCode = await SupabaseConfig.generateJICSCode();

      // Upload logo if provided
      String? logoUrl;
      if (logoBytes != null) {
        final fileName = 'logo_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'provider-logos/$fileName';
        
        try {
          await SupabaseConfig.client.storage
              .from('provider-logos')
              .uploadBinary(filePath, logoBytes);
          
          logoUrl = SupabaseConfig.client.storage
              .from('provider-logos')
              .getPublicUrl(filePath);
        } catch (e) {
          print('Logo upload failed: $e');
          // Continue without logo if upload fails
        }
      }

      // Prepare provider data with new schema fields
      final providerData = {
        'user_id': user.id,
        'commercial_name': commercialName,
        'authorized_person_name': authorizedPersonName,
        'national_id': idNumber,
        'phone': phone,
        'email': email,
        'city': city,
        'street_address': streetAddress,
        'service_type': serviceType,
        'description': description,
        'logo_url': logoUrl,
        'branches': branches != null ? jsonEncode(branches) : null,
        'is_approved': true,
        'status': 'approved',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // Legacy fields for backward compatibility
        'name': commercialName,
        'registered_name': registeredName,
        'id_number': idNumber,
        'provider_code': jicsCode,
      };
      
      // Add financial information if provided
      if (taxNumber != null && taxNumber.isNotEmpty) {
        providerData['tax_number'] = taxNumber;
      }
      if (bankAccount != null && bankAccount.isNotEmpty) {
        providerData['bank_account_number'] = bankAccount;
      }
      if (iban != null && iban.isNotEmpty) {
        providerData['iban'] = iban;
      }

      // Create service provider record
      await SupabaseConfig.createServiceProvider(providerData);

      // Create welcome notification
      await SupabaseConfig.createNotification({
        'user_id': user.id,
        'title': 'طلب التسجيل تم بنجاح',
        'message': 'تم استلام طلب التسجيل في منصة JEENA. سيتم مراجعة طلبكم من قبل الفريق المختص وسيتم التواصل معكم قريباً.',
        'type': 'registration',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'jics_code': jicsCode,
        'message': 'تم تسجيل طلبكم بنجاح! رمز JEENA الخاص بكم: $jicsCode',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في التسجيل: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>?> getProviderStatus() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return null;

      return await SupabaseConfig.getServiceProviderStatus(user.id);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isApproved() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return false;

      // TEMPORARY: Always return true to bypass approval requirement
      // TODO: Re-enable approval check when admin panel is fully implemented
      return true;
      
      // Original approval check code (commented out):
      // return await SupabaseConfig.isProviderApproved(user.id);
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateProviderProfile({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      await SupabaseConfig.client
          .from('service_providers')
          .update(updateData)
          .eq('user_id', userId);

      return {
        'success': true,
        'message': 'تم تحديث البيانات بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث البيانات: ${e.toString()}',
      };
    }
  }

  static Future<ServiceProvider?> getProviderProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('service_providers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return ServiceProvider.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProviderProfileMap(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('service_providers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateFinancialInfo({
    required String userId,
    required String taxNumber,
    required String bankAccount,
    String? iban,
  }) async {
    try {
      final updateData = {
        'tax_number': taxNumber,
        'bank_account_number': bankAccount,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (iban != null && iban.isNotEmpty) {
        updateData['iban'] = iban;
      }
      
      await SupabaseConfig.client
          .from('service_providers')
          .update(updateData)
          .eq('user_id', userId);

      return {
        'success': true,
        'message': 'تم تحديث المعلومات المالية بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث المعلومات المالية: ${e.toString()}',
      };
    }
  }

  // Define field categories for profile editing
  static const Set<String> _basicFields = {
    'commercial_name',
    'authorized_person_name',
    'phone',
    'email',
    'city',
    'street_address',
    'service_type',
    'description',
    'logo_url',
    'branches',
  };

  static const Set<String> _sensitiveFields = {
    'registered_name',
    'national_id',
    'id_number',
    'tax_number',
    'bank_account_number',
    'bank_account',
    'iban',
  };

  static bool isBasicField(String fieldName) {
    return _basicFields.contains(fieldName);
  }

  static bool isSensitiveField(String fieldName) {
    return _sensitiveFields.contains(fieldName);
  }

  // Update basic fields directly
  static Future<Map<String, dynamic>> updateBasicFields({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      for (final entry in updates.entries) {
        if (isBasicField(entry.key)) {
          updateData[entry.key] = entry.value;
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      // First check if the service provider exists
      final existingProvider = await SupabaseConfig.client
          .from('service_providers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingProvider == null) {
        // Create a new service provider record if it doesn't exist
        final newProviderData = {
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
          ...updateData,
        };
        
        await SupabaseConfig.client
            .from('service_providers')
            .insert(newProviderData);
      } else {
        // Update existing provider
        final result = await SupabaseConfig.client
            .from('service_providers')
            .update(updateData)
            .eq('user_id', userId)
            .select();

        if (result.isEmpty) {
          throw Exception('لم يتم العثور على مزود الخدمة للتحديث');
        }
      }

      return {
        'success': true,
        'message': 'تم تحديث البيانات بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث البيانات: ${e.toString()}',
      };
    }
  }

  // Submit sensitive field changes for approval
  static Future<Map<String, dynamic>> submitSensitiveFieldChanges({
    required String userId,
    required Map<String, dynamic> changes,
  }) async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Get provider ID and current values
      final providerResponse = await SupabaseConfig.client
          .from('service_providers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (providerResponse == null) {
        throw Exception('لم يتم العثور على ملف مزود الخدمة. يرجى إكمال التسجيل أولاً.');
      }

      final providerId = providerResponse['id'];
      final currentProvider = providerResponse;

      final List<Map<String, dynamic>> pendingChanges = [];

      for (final entry in changes.entries) {
        if (isSensitiveField(entry.key)) {
          pendingChanges.add({
            'provider_id': providerId,
            'field_name': entry.key,
            'old_value': currentProvider[entry.key]?.toString(),
            'new_value': entry.value?.toString(),
            'change_type': 'update',
            'status': 'pending',
            'requested_by': user.id,
            'requested_at': DateTime.now().toIso8601String(),
          });
        }
      }

      if (pendingChanges.isNotEmpty) {
        await SupabaseConfig.client
            .from('pending_profile_changes')
            .insert(pendingChanges);

        // Create notification for admin
        await SupabaseConfig.client
            .from('notifications')
            .insert({
              'user_id': user.id,
              'title': 'طلب تعديل البيانات الحساسة',
              'message': 'تم إرسال طلب تعديل البيانات الحساسة للمراجعة. سيتم التواصل معك قريباً.',
              'type': 'info',
              'is_read': false,
            });
      }

      return {
        'success': true,
        'message': 'تم إرسال طلب التعديل للمراجعة من قبل فريق جينا',
        'pending_changes': pendingChanges.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إرسال طلب التعديل: ${e.toString()}',
      };
    }
  }

  // Get pending changes for a provider
  static Future<List<Map<String, dynamic>>> getPendingChanges(String userId) async {
    try {
      final providerResponse = await SupabaseConfig.client
          .from('service_providers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (providerResponse == null) {
        return []; // No provider found, return empty list
      }

      final providerId = providerResponse['id'];

      final response = await SupabaseConfig.client
          .from('pending_profile_changes')
          .select()
          .eq('provider_id', providerId)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Get field display name in Arabic
  static String getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'commercial_name':
        return 'الاسم التجاري';
      case 'registered_name':
        return 'الاسم المسجل';
      case 'authorized_person_name':
        return 'الشخص المفوض';
      case 'national_id':
      case 'id_number':
        return 'رقم الهوية';
      case 'phone':
        return 'رقم الهاتف';
      case 'email':
        return 'البريد الإلكتروني';
      case 'city':
        return 'المدينة';
      case 'street_address':
        return 'العنوان التفصيلي';
      case 'service_type':
        return 'نوع الخدمة';
      case 'description':
        return 'وصف الخدمة';
      case 'tax_number':
        return 'الرقم الضريبي';
      case 'bank_account_number':
      case 'bank_account':
        return 'رقم الحساب البنكي';
      case 'iban':
        return 'رقم الآيبان';
      case 'logo_url':
        return 'شعار الشركة';
      case 'branches':
        return 'الفروع';
      default:
        return fieldName;
    }
  }

  // Get status display name in Arabic
  static String getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}