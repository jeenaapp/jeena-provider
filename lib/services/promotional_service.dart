import 'package:dreamflow/supabase/supabase_config.dart';
import 'package:dreamflow/models/promotional_models.dart';

class PromotionalService {
  // Service Offers Methods
  
  static Future<List<ServiceOffer>> getProviderOffers(String providerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('service_offers')
          .select('*')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      
      return response.map((json) => ServiceOffer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch provider offers: $e');
    }
  }

  static Future<List<ServiceOffer>> getServiceOffers(String serviceId) async {
    try {
      final response = await SupabaseConfig.client
          .from('service_offers')
          .select('*')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);
      
      return response.map((json) => ServiceOffer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch service offers: $e');
    }
  }

  static Future<ServiceOffer?> getActiveServiceOffer(String serviceId) async {
    try {
      final response = await SupabaseConfig.client
          .from('service_offers')
          .select('*')
          .eq('service_id', serviceId)
          .eq('status', 'approved')
          .gte('offer_end_date', DateTime.now().toIso8601String())
          .lte('offer_start_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);
      
      if (response.isEmpty) return null;
      return ServiceOffer.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch active service offer: $e');
    }
  }

  static Future<void> createServiceOffer({
    required String providerId,
    required String serviceId,
    required int discountPercentage,
    required double discountedPrice,
    required double originalPrice,
    required DateTime offerStartDate,
    required DateTime offerEndDate,
  }) async {
    try {
      // Validate offer dates
      if (offerStartDate.isAfter(offerEndDate)) {
        throw Exception('تاريخ بداية العرض يجب أن يكون قبل تاريخ النهاية');
      }

      if (offerStartDate.isBefore(DateTime.now())) {
        throw Exception('تاريخ بداية العرض يجب أن يكون في المستقبل');
      }

      // Check if there's already an active offer for this service
      final existingOffer = await getActiveServiceOffer(serviceId);
      if (existingOffer != null) {
        throw Exception('يوجد عرض نشط بالفعل لهذه الخدمة');
      }

      // Validate discount
      if (discountPercentage < 1 || discountPercentage > 99) {
        throw Exception('نسبة الخصم يجب أن تكون بين 1% و 99%');
      }

      // Calculate expected discounted price
      final expectedDiscountedPrice = originalPrice * (1 - discountPercentage / 100);
      if ((discountedPrice - expectedDiscountedPrice).abs() > 0.01) {
        throw Exception('السعر المخفض غير صحيح');
      }

      await SupabaseConfig.client.from('service_offers').insert({
        'provider_id': providerId,
        'service_id': serviceId,
        'discount_percentage': discountPercentage,
        'discounted_price': discountedPrice,
        'original_price': originalPrice,
        'offer_start_date': offerStartDate.toIso8601String(),
        'offer_end_date': offerEndDate.toIso8601String(),
        'status': 'pending',
      });

      // Log the action
      await _logPromotionAction(
        serviceId,
        'offer',
        'created',
        null,
        'عرض جديد تم إنشاؤه للخدمة',
      );
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
      await SupabaseConfig.client.from('service_offers').update({
        'status': status,
        'admin_notes': adminNotes,
        'admin_reviewed_by': adminId,
        'admin_reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', offerId);

      // Log the action
      await _logPromotionAction(
        offerId,
        'offer',
        status == 'approved' ? 'approved' : 'rejected',
        adminId,
        adminNotes,
      );
    } catch (e) {
      throw Exception('Failed to update offer status: $e');
    }
  }

  // Paid Promotion Methods

  static Future<List<PaidPromotionRequest>> getProviderPromotionRequests(
    String providerId,
  ) async {
    try {
      final response = await SupabaseConfig.client
          .from('paid_promotion_requests')
          .select('*')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      
      return response.map((json) => PaidPromotionRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch promotion requests: $e');
    }
  }

  static Future<double> calculatePromotionCost(
    String promotionType,
    int durationDays,
    int? position,
  ) async {
    try {
      final response = await SupabaseConfig.client.rpc(
        'calculate_promotion_cost',
        params: {
          'promotion_type': promotionType,
          'duration_days': durationDays,
          'position': position,
        },
      );
      return (response as num).toDouble();
    } catch (e) {
      // Fallback calculation
      switch (promotionType) {
        case 'header_banner':
          return durationDays * 50.0;
        case 'featured_section':
          if (position != null && position <= 3) {
            return durationDays * 30.0;
          }
          return durationDays * 20.0;
        default:
          return 0.0;
      }
    }
  }

  static Future<void> createPaidPromotionRequest({
    required String providerId,
    required String serviceId,
    required String promotionType,
    required int durationDays,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Validate dates
      if (startDate.isAfter(endDate)) {
        throw Exception('تاريخ بداية الترويج يجب أن يكون قبل تاريخ النهاية');
      }

      if (startDate.isBefore(DateTime.now())) {
        throw Exception('تاريخ بداية الترويج يجب أن يكون في المستقبل');
      }

      // Calculate cost
      final cost = await calculatePromotionCost(promotionType, durationDays, null);

      // Check for conflicting promotions
      final existingPromotion = await getActivePromotionForService(serviceId, promotionType);
      if (existingPromotion != null) {
        throw Exception('يوجد ترويج نشط بالفعل لهذه الخدمة في نفس النوع');
      }

      await SupabaseConfig.client.from('paid_promotion_requests').insert({
        'provider_id': providerId,
        'service_id': serviceId,
        'promotion_type': promotionType,
        'requested_duration_days': durationDays,
        'requested_start_date': startDate.toIso8601String(),
        'requested_end_date': endDate.toIso8601String(),
        'promotion_cost': cost,
        'status': 'pending',
      });

      // Log the action
      await _logPromotionAction(
        serviceId,
        'paid_promotion',
        'created',
        null,
        'طلب ترويج مدفوع جديد تم إنشاؤه',
      );
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
      await SupabaseConfig.client.from('paid_promotion_requests').update({
        'status': status,
        'admin_notes': adminNotes,
        'admin_reviewed_by': adminId,
        'admin_reviewed_at': DateTime.now().toIso8601String(),
        'approved_start_date': approvedStartDate?.toIso8601String(),
        'approved_end_date': approvedEndDate?.toIso8601String(),
        'approved_position': approvedPosition,
      }).eq('id', requestId);

      // Log the action
      await _logPromotionAction(
        requestId,
        'paid_promotion',
        status == 'approved' ? 'approved' : 'rejected',
        adminId,
        adminNotes,
      );
    } catch (e) {
      throw Exception('Failed to update promotion request status: $e');
    }
  }

  // Active Promotions Methods

  static Future<List<ActivePromotion>> getActivePromotions(
    String promotionType,
  ) async {
    try {
      final response = await SupabaseConfig.client
          .from('active_promotions')
          .select('*')
          .eq('promotion_type', promotionType)
          .gte('end_date', DateTime.now().toIso8601String())
          .lte('start_date', DateTime.now().toIso8601String())
          .order('position', ascending: true);
      
      return response.map((json) => ActivePromotion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active promotions: $e');
    }
  }

  static Future<ActivePromotion?> getActivePromotionForService(
    String serviceId,
    String promotionType,
  ) async {
    try {
      final response = await SupabaseConfig.client
          .from('active_promotions')
          .select('*')
          .eq('service_id', serviceId)
          .eq('promotion_type', promotionType)
          .gte('end_date', DateTime.now().toIso8601String())
          .lte('start_date', DateTime.now().toIso8601String())
          .limit(1);
      
      if (response.isEmpty) return null;
      return ActivePromotion.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch active promotion for service: $e');
    }
  }

  static Future<List<ActivePromotion>> getHeaderBannerPromotions() async {
    return await getActivePromotions('header_banner');
  }

  static Future<List<ActivePromotion>> getFeaturedSectionPromotions() async {
    return await getActivePromotions('featured_section');
  }

  // Admin Methods

  static Future<List<ServiceOffer>> getPendingOffers() async {
    try {
      final response = await SupabaseConfig.client
          .from('service_offers')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return response.map((json) => ServiceOffer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending offers: $e');
    }
  }

  static Future<List<PaidPromotionRequest>> getPendingPromotionRequests() async {
    try {
      final response = await SupabaseConfig.client
          .from('paid_promotion_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return response.map((json) => PaidPromotionRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending promotion requests: $e');
    }
  }

  static Future<void> activateApprovedPromotions() async {
    try {
      await SupabaseConfig.client.rpc('activate_approved_promotions');
    } catch (e) {
      throw Exception('Failed to activate approved promotions: $e');
    }
  }

  static Future<void> deactivateExpiredPromotions() async {
    try {
      await SupabaseConfig.client.rpc('deactivate_expired_promotions');
    } catch (e) {
      throw Exception('Failed to deactivate expired promotions: $e');
    }
  }

  // Analytics Methods

  static Future<void> trackPromotionView(
    String promotionId,
    String promotionType,
    String serviceId,
    String providerId,
  ) async {
    try {
      await _updatePromotionAnalytics(
        promotionId,
        promotionType,
        serviceId,
        providerId,
        viewsIncrement: 1,
      );
    } catch (e) {
      // Don't throw errors for analytics - log them instead
      print('Failed to track promotion view: $e');
    }
  }

  static Future<void> trackPromotionClick(
    String promotionId,
    String promotionType,
    String serviceId,
    String providerId,
  ) async {
    try {
      await _updatePromotionAnalytics(
        promotionId,
        promotionType,
        serviceId,
        providerId,
        clicksIncrement: 1,
      );
    } catch (e) {
      // Don't throw errors for analytics - log them instead
      print('Failed to track promotion click: $e');
    }
  }

  static Future<void> trackPromotionConversion(
    String promotionId,
    String promotionType,
    String serviceId,
    String providerId,
  ) async {
    try {
      await _updatePromotionAnalytics(
        promotionId,
        promotionType,
        serviceId,
        providerId,
        conversionIncrement: 1,
      );
    } catch (e) {
      // Don't throw errors for analytics - log them instead
      print('Failed to track promotion conversion: $e');
    }
  }

  static Future<List<PromotionAnalytics>> getPromotionAnalytics(
    String promotionId,
    String promotionType,
  ) async {
    try {
      final response = await SupabaseConfig.client
          .from('promotion_analytics')
          .select('*')
          .eq('promotion_id', promotionId)
          .eq('promotion_type', promotionType)
          .order('date_recorded', ascending: false);
      
      return response.map((json) => PromotionAnalytics.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch promotion analytics: $e');
    }
  }

  // Private Helper Methods

  static Future<void> _logPromotionAction(
    String promotionId,
    String promotionType,
    String action,
    String? adminId,
    String? notes,
  ) async {
    try {
      await SupabaseConfig.client.rpc('log_promotion_action', params: {
        'p_promotion_id': promotionId,
        'p_promotion_type': promotionType,
        'p_action': action,
        'p_admin_id': adminId,
        'p_notes': notes,
      });
    } catch (e) {
      // Don't throw errors for logging - just print them
      print('Failed to log promotion action: $e');
    }
  }

  static Future<void> _updatePromotionAnalytics(
    String promotionId,
    String promotionType,
    String serviceId,
    String providerId, {
    int viewsIncrement = 0,
    int clicksIncrement = 0,
    int conversionIncrement = 0,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Try to update existing record
      final response = await SupabaseConfig.client
          .from('promotion_analytics')
          .select('*')
          .eq('promotion_id', promotionId)
          .eq('promotion_type', promotionType)
          .eq('date_recorded', today)
          .limit(1);
      
      if (response.isNotEmpty) {
        // Update existing record
        final existing = response.first;
        await SupabaseConfig.client
            .from('promotion_analytics')
            .update({
              'views_count': existing['views_count'] + viewsIncrement,
              'clicks_count': existing['clicks_count'] + clicksIncrement,
              'conversion_count': existing['conversion_count'] + conversionIncrement,
            })
            .eq('id', existing['id']);
      } else {
        // Create new record
        await SupabaseConfig.client.from('promotion_analytics').insert({
          'promotion_id': promotionId,
          'promotion_type': promotionType,
          'service_id': serviceId,
          'provider_id': providerId,
          'views_count': viewsIncrement,
          'clicks_count': clicksIncrement,
          'conversion_count': conversionIncrement,
          'date_recorded': today,
        });
      }
    } catch (e) {
      throw Exception('Failed to update promotion analytics: $e');
    }
  }

  // Utility Methods

  static Future<bool> canCreateOffer(String serviceId) async {
    try {
      final activeOffer = await getActiveServiceOffer(serviceId);
      return activeOffer == null;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> canCreatePromotionRequest(
    String serviceId,
    String promotionType,
  ) async {
    try {
      final activePromotion = await getActivePromotionForService(serviceId, promotionType);
      return activePromotion == null;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getNextAvailablePosition(String promotionType) async {
    try {
      final activePromotions = await getActivePromotions(promotionType);
      if (activePromotions.isEmpty) return 1;
      
      final positions = activePromotions
          .map((p) => p.position ?? 0)
          .where((pos) => pos > 0)
          .toList();
      
      if (positions.isEmpty) return 1;
      
      positions.sort();
      return positions.last + 1;
    } catch (e) {
      return 1;
    }
  }
}