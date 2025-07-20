import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://eedimdyjyblhumqjbekx.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlZGltZHlqeWJsaHVtcWpiZWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI0MDA0ODIsImV4cCI6MjA2Nzk3NjQ4Mn0.fC-fMT-C4Im_3TRzmRQBg7h6PUTgZw76iyBxbXCBftY';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
    );
  }
  
  // Authentication helpers
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  // Database helpers
  static Future<List<Map<String, dynamic>>> getServices(String userId) async {
    try {
      final response = await client
          .from('services')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .eq('provider_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getInvoices(String userId) async {
    try {
      final response = await client
          .from('invoices')
          .select()
          .eq('provider_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }
  
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }
  
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('users')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
  
  static Future<void> createService(Map<String, dynamic> serviceData) async {
    try {
      await client.from('services').insert(serviceData);
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserServices(String userId) async {
    try {
      final response = await client
          .from('services')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Failed to load services: $e');
    }
  }
  
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await client.from('orders').update({'status': status}).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Warehouse helpers
  static Future<List<Map<String, dynamic>>> getWarehouseProducts(String userId) async {
    try {
      final response = await client
          .from('warehouse_products')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get warehouse products: $e');
    }
  }
  
  static Future<void> createWarehouseProduct(Map<String, dynamic> productData) async {
    try {
      await client.from('warehouse_products').insert(productData);
    } catch (e) {
      throw Exception('Failed to create warehouse product: $e');
    }
  }
  
  static Future<bool> checkProductAvailability(
    String productId,
    DateTime startDate,
    DateTime endDate,
    int requiredQuantity,
  ) async {
    try {
      final response = await client.rpc('check_product_availability', params: {
        'product_id': productId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'required_quantity': requiredQuantity,
      });
      return response as bool;
    } catch (e) {
      throw Exception('Failed to check product availability: $e');
    }
  }

  // Warehouse validation methods for service creation
  static Future<List<Map<String, dynamic>>> getWarehouseServices() async {
    try {
      final response = await client
          .from('warehouse')
          .select('*')
          .eq('approval_status', 'approved')
          .order('service_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get warehouse services: $e');
    }
  }

  static Future<Map<String, dynamic>?> validateServiceFromWarehouse({
    required String serviceName,
    String? internalCode,
    required int requestedQuantity,
  }) async {
    try {
      // Search by service_name or internal_code (JICS)
      var query = client.from('warehouse').select('*');
      
      if (internalCode != null && internalCode.isNotEmpty) {
        query = query.eq('internal_code', internalCode);
      } else {
        query = query.eq('service_name', serviceName);
      }

      final response = await query.limit(1);
      
      if (response.isEmpty) {
        return null; // Service not found in warehouse
      }

      final warehouseItem = response.first;
      final availableQuantity = warehouseItem['quantity'] as int? ?? 0;
      
      return {
        'warehouseItem': warehouseItem,
        'availableQuantity': availableQuantity,
        'isQuantityValid': requestedQuantity <= availableQuantity,
        'requestedQuantity': requestedQuantity,
      };
    } catch (e) {
      throw Exception('Failed to validate service from warehouse: $e');
    }
  }

  static Future<void> createServiceWithWarehouseLink(Map<String, dynamic> serviceData, String warehouseId, String internalCode) async {
    try {
      final enrichedServiceData = {
        ...serviceData,
        'warehouse_id': warehouseId,
        'internal_code': internalCode,
      };
      await client.from('services').insert(enrichedServiceData);
    } catch (e) {
      throw Exception('Failed to create service with warehouse link: $e');
    }
  }

  // JEENA Provider Registration methods
  static Future<String> generateJICSCode() async {
    try {
      // Generate JICS code with format: JEENA-YYYY-XXXX (where XXXX is incremental)
      final year = DateTime.now().year;
      final response = await client.rpc('generate_jics_code', params: {'year': year});
      return response.toString();
    } catch (e) {
      // Fallback: generate random JICS if RPC fails
      final year = DateTime.now().year;
      final random = DateTime.now().millisecondsSinceEpoch % 10000;
      return 'JEENA-$year-${random.toString().padLeft(4, '0')}';
    }
  }

  static Future<void> createServiceProvider(Map<String, dynamic> providerData) async {
    try {
      await client.from('service_providers').insert(providerData);
    } catch (e) {
      throw Exception('Failed to create service provider: $e');
    }
  }

  // Create initial service provider record for new users
  static Future<void> createInitialServiceProviderRecord(String userId) async {
    try {
      await client.from('service_providers').insert({
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create initial service provider record: $e');
    }
  }

  static Future<Map<String, dynamic>?> getServiceProviderStatus(String userId) async {
    try {
      final response = await client
          .from('service_providers')
          .select('status, provider_code, approval_date')
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to get provider status: $e');
    }
  }

  static Future<bool> isProviderApproved(String userId) async {
    try {
      // TEMPORARY: Always return true to bypass approval requirement
      // TODO: Re-enable approval check when admin panel is fully implemented
      return true;
      
      // Original approval check code (commented out):
      // final status = await getServiceProviderStatus(userId);
      // return status?['status'] == 'approved';
    } catch (e) {
      return false;
    }
  }

  static Future<void> createNotification(Map<String, dynamic> notificationData) async {
    try {
      await client.from('notifications').insert(notificationData);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Media upload methods
  static Future<List<String>> uploadMultipleImages(
    String userId,
    List<Map<String, dynamic>> images, // {name: String, bytes: Uint8List}
  ) async {
    try {
      List<String> uploadedUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'service_image_${timestamp}_$i.jpg';
        final filePath = '$userId/services/$fileName';
        
        // Upload to Supabase Storage
        await client.storage
            .from('service-images')
            .uploadBinary(filePath, image['bytes']);
        
        // Get public URL
        final publicUrl = client.storage
            .from('service-images')
            .getPublicUrl(filePath);
        
        uploadedUrls.add(publicUrl);
      }
      
      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  static Future<String?> uploadVideo(
    String userId,
    Map<String, dynamic> video, // {name: String, bytes: Uint8List}
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'service_video_$timestamp.mp4';
      final filePath = '$userId/services/videos/$fileName';
      
      // Upload to Supabase Storage
      await client.storage
          .from('service-videos')
          .uploadBinary(filePath, video['bytes']);
      
      // Get public URL
      final publicUrl = client.storage
          .from('service-videos')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  static Future<void> createServiceWithMedia(
    Map<String, dynamic> serviceData,
    List<String> imageUrls,
    String? videoUrl,
    String? warehouseId,
    String? internalCode,
  ) async {
    try {
      final enrichedServiceData = {
        ...serviceData,
        'image_urls': imageUrls,
        'video_url': videoUrl,
        'warehouse_id': warehouseId,
        'internal_code': internalCode,
        'admin_status': 'pending', // Add admin approval status
        'admin_notes': null,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await client.from('services').insert(enrichedServiceData);
    } catch (e) {
      throw Exception('Failed to create service with media: $e');
    }
  }

  // Admin validation methods
  static Future<List<Map<String, dynamic>>> getPendingServices() async {
    try {
      final response = await client
          .from('services')
          .select('*')
          .eq('admin_status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get pending services: $e');
    }
  }

  static Future<void> updateServiceAdminStatus(
    String serviceId,
    String status, // 'approved', 'rejected'
    String? adminNotes,
  ) async {
    try {
      await client.from('services').update({
        'admin_status': status,
        'admin_notes': adminNotes,
        'admin_reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', serviceId);
    } catch (e) {
      throw Exception('Failed to update service admin status: $e');
    }
  }

  static Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      final response = await client
          .from('services')
          .select('*')
          .eq('id', serviceId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to get service by ID: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getServicesByStatus(
    String userId,
    String status, // 'pending', 'approved', 'rejected'
  ) async {
    try {
      final response = await client
          .from('services')
          .select('*')
          .eq('user_id', userId)
          .eq('admin_status', status)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get services by status: $e');
    }
  }

  // Content quality validation
  static Future<Map<String, dynamic>> validateServiceContent(
    String serviceName,
    String serviceDescription,
    List<String> imageUrls,
    String? videoUrl,
  ) async {
    try {
      // Basic content validation
      final issues = <String>[];
      
      // Check service name
      if (serviceName.trim().length < 3) {
        issues.add('اسم الخدمة قصير جداً');
      }
      
      // Check description
      if (serviceDescription.trim().length < 20) {
        issues.add('وصف الخدمة قصير جداً');
      }
      
      // Check images
      if (imageUrls.isEmpty) {
        issues.add('يجب إضافة صورة واحدة على الأقل');
      }
      
      if (imageUrls.length > 10) {
        issues.add('لا يمكن إضافة أكثر من 10 صور');
      }
      
      // Check for duplicate content (simplified check)
      final existingServices = await client
          .from('services')
          .select('name, description')
          .eq('name', serviceName)
          .limit(1);
      
      if (existingServices.isNotEmpty) {
        issues.add('يوجد خدمة بنفس الاسم مسبقاً');
      }
      
      return {
        'isValid': issues.isEmpty,
        'issues': issues,
        'score': issues.isEmpty ? 100 : (100 - (issues.length * 20)).clamp(0, 100),
      };
    } catch (e) {
      throw Exception('Failed to validate service content: $e');
    }
  }

  // Delete media files
  static Future<void> deleteMediaFiles(List<String> urls) async {
    try {
      for (final url in urls) {
        // Extract file path from URL
        final uri = Uri.parse(url);
        final path = uri.path.split('/').last;
        
        // Delete from storage
        if (url.contains('service-images')) {
          await client.storage.from('service-images').remove([path]);
        } else if (url.contains('service-videos')) {
          await client.storage.from('service-videos').remove([path]);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete media files: $e');
    }
  }

  // Promotional methods
  static Future<List<Map<String, dynamic>>> getServiceOffers(String serviceId) async {
    try {
      final response = await client
          .from('service_offers')
          .select('*')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get service offers: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProviderOffers(String providerId) async {
    try {
      final response = await client
          .from('service_offers')
          .select('*')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get provider offers: $e');
    }
  }

  static Future<void> createServiceOffer(Map<String, dynamic> offerData) async {
    try {
      await client.from('service_offers').insert(offerData);
    } catch (e) {
      throw Exception('Failed to create service offer: $e');
    }
  }

  static Future<void> updateOfferStatus(
    String offerId,
    String status,
    String adminId,
    String? adminNotes,
  ) async {
    try {
      await client.from('service_offers').update({
        'status': status,
        'admin_notes': adminNotes,
        'admin_reviewed_by': adminId,
        'admin_reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', offerId);
    } catch (e) {
      throw Exception('Failed to update offer status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingOffers() async {
    try {
      final response = await client
          .from('service_offers')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get pending offers: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProviderPromotionRequests(String providerId) async {
    try {
      final response = await client
          .from('paid_promotion_requests')
          .select('*')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get provider promotion requests: $e');
    }
  }

  static Future<void> createPaidPromotionRequest(Map<String, dynamic> requestData) async {
    try {
      await client.from('paid_promotion_requests').insert(requestData);
    } catch (e) {
      throw Exception('Failed to create paid promotion request: $e');
    }
  }

  static Future<void> updatePromotionRequestStatus(
    String requestId,
    String status,
    String adminId,
    String? adminNotes,
    DateTime? approvedStartDate,
    DateTime? approvedEndDate,
    int? approvedPosition,
  ) async {
    try {
      await client.from('paid_promotion_requests').update({
        'status': status,
        'admin_notes': adminNotes,
        'admin_reviewed_by': adminId,
        'admin_reviewed_at': DateTime.now().toIso8601String(),
        'approved_start_date': approvedStartDate?.toIso8601String(),
        'approved_end_date': approvedEndDate?.toIso8601String(),
        'approved_position': approvedPosition,
      }).eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to update promotion request status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingPromotionRequests() async {
    try {
      final response = await client
          .from('paid_promotion_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get pending promotion requests: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getActivePromotions(String promotionType) async {
    try {
      final response = await client
          .from('active_promotions')
          .select('*')
          .eq('promotion_type', promotionType)
          .gte('end_date', DateTime.now().toIso8601String())
          .lte('start_date', DateTime.now().toIso8601String())
          .order('position', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get active promotions: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHeaderBannerPromotions() async {
    return await getActivePromotions('header_banner');
  }

  static Future<List<Map<String, dynamic>>> getFeaturedSectionPromotions() async {
    return await getActivePromotions('featured_section');
  }

  static Future<Map<String, dynamic>?> getActiveServiceOffer(String serviceId) async {
    try {
      final response = await client
          .from('service_offers')
          .select('*')
          .eq('service_id', serviceId)
          .eq('status', 'approved')
          .gte('offer_end_date', DateTime.now().toIso8601String())
          .lte('offer_start_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);
      
      if (response.isEmpty) return null;
      return response.first;
    } catch (e) {
      throw Exception('Failed to get active service offer: $e');
    }
  }

  static Future<void> activateApprovedPromotions() async {
    try {
      await client.rpc('activate_approved_promotions');
    } catch (e) {
      throw Exception('Failed to activate approved promotions: $e');
    }
  }

  static Future<void> deactivateExpiredPromotions() async {
    try {
      await client.rpc('deactivate_expired_promotions');
    } catch (e) {
      throw Exception('Failed to deactivate expired promotions: $e');
    }
  }

  static Future<void> trackPromotionAnalytics(
    String promotionId,
    String promotionType,
    String serviceId,
    String providerId,
    String actionType, // 'view', 'click', 'conversion'
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Try to update existing record
      final response = await client
          .from('promotion_analytics')
          .select('*')
          .eq('promotion_id', promotionId)
          .eq('promotion_type', promotionType)
          .eq('date_recorded', today)
          .limit(1);
      
      if (response.isNotEmpty) {
        // Update existing record
        final existing = response.first;
        final updateData = <String, dynamic>{};
        
        switch (actionType) {
          case 'view':
            updateData['views_count'] = existing['views_count'] + 1;
            break;
          case 'click':
            updateData['clicks_count'] = existing['clicks_count'] + 1;
            break;
          case 'conversion':
            updateData['conversion_count'] = existing['conversion_count'] + 1;
            break;
        }
        
        await client
            .from('promotion_analytics')
            .update(updateData)
            .eq('id', existing['id']);
      } else {
        // Create new record
        final insertData = {
          'promotion_id': promotionId,
          'promotion_type': promotionType,
          'service_id': serviceId,
          'provider_id': providerId,
          'views_count': actionType == 'view' ? 1 : 0,
          'clicks_count': actionType == 'click' ? 1 : 0,
          'conversion_count': actionType == 'conversion' ? 1 : 0,
          'date_recorded': today,
        };
        
        await client.from('promotion_analytics').insert(insertData);
      }
    } catch (e) {
      // Don't throw errors for analytics - just log them
      print('Failed to track promotion analytics: $e');
    }
  }
}