class ServiceOffer {
  final String id;
  final String providerId;
  final String serviceId;
  final int discountPercentage;
  final double discountedPrice;
  final double originalPrice;
  final DateTime offerStartDate;
  final DateTime offerEndDate;
  final String status;
  final String? adminNotes;
  final String? adminReviewedBy;
  final DateTime? adminReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceOffer({
    required this.id,
    required this.providerId,
    required this.serviceId,
    required this.discountPercentage,
    required this.discountedPrice,
    required this.originalPrice,
    required this.offerStartDate,
    required this.offerEndDate,
    required this.status,
    this.adminNotes,
    this.adminReviewedBy,
    this.adminReviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceOffer.fromJson(Map<String, dynamic> json) {
    return ServiceOffer(
      id: json['id'],
      providerId: json['provider_id'],
      serviceId: json['service_id'],
      discountPercentage: json['discount_percentage'],
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      offerStartDate: DateTime.parse(json['offer_start_date']),
      offerEndDate: DateTime.parse(json['offer_end_date']),
      status: json['status'],
      adminNotes: json['admin_notes'],
      adminReviewedBy: json['admin_reviewed_by'],
      adminReviewedAt: json['admin_reviewed_at'] != null 
          ? DateTime.parse(json['admin_reviewed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'service_id': serviceId,
      'discount_percentage': discountPercentage,
      'discounted_price': discountedPrice,
      'original_price': originalPrice,
      'offer_start_date': offerStartDate.toIso8601String(),
      'offer_end_date': offerEndDate.toIso8601String(),
      'status': status,
      'admin_notes': adminNotes,
      'admin_reviewed_by': adminReviewedBy,
      'admin_reviewed_at': adminReviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'approved' && 
      DateTime.now().isAfter(offerStartDate) &&
      DateTime.now().isBefore(offerEndDate);

  bool get isExpired => DateTime.now().isAfter(offerEndDate);
}

class PaidPromotionRequest {
  final String id;
  final String providerId;
  final String serviceId;
  final String promotionType;
  final int requestedDurationDays;
  final DateTime requestedStartDate;
  final DateTime requestedEndDate;
  final double promotionCost;
  final String status;
  final String? adminNotes;
  final String? adminReviewedBy;
  final DateTime? adminReviewedAt;
  final DateTime? approvedStartDate;
  final DateTime? approvedEndDate;
  final int? approvedPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaidPromotionRequest({
    required this.id,
    required this.providerId,
    required this.serviceId,
    required this.promotionType,
    required this.requestedDurationDays,
    required this.requestedStartDate,
    required this.requestedEndDate,
    required this.promotionCost,
    required this.status,
    this.adminNotes,
    this.adminReviewedBy,
    this.adminReviewedAt,
    this.approvedStartDate,
    this.approvedEndDate,
    this.approvedPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaidPromotionRequest.fromJson(Map<String, dynamic> json) {
    return PaidPromotionRequest(
      id: json['id'],
      providerId: json['provider_id'],
      serviceId: json['service_id'],
      promotionType: json['promotion_type'],
      requestedDurationDays: json['requested_duration_days'],
      requestedStartDate: DateTime.parse(json['requested_start_date']),
      requestedEndDate: DateTime.parse(json['requested_end_date']),
      promotionCost: (json['promotion_cost'] as num).toDouble(),
      status: json['status'],
      adminNotes: json['admin_notes'],
      adminReviewedBy: json['admin_reviewed_by'],
      adminReviewedAt: json['admin_reviewed_at'] != null 
          ? DateTime.parse(json['admin_reviewed_at'])
          : null,
      approvedStartDate: json['approved_start_date'] != null
          ? DateTime.parse(json['approved_start_date'])
          : null,
      approvedEndDate: json['approved_end_date'] != null
          ? DateTime.parse(json['approved_end_date'])
          : null,
      approvedPosition: json['approved_position'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'service_id': serviceId,
      'promotion_type': promotionType,
      'requested_duration_days': requestedDurationDays,
      'requested_start_date': requestedStartDate.toIso8601String(),
      'requested_end_date': requestedEndDate.toIso8601String(),
      'promotion_cost': promotionCost,
      'status': status,
      'admin_notes': adminNotes,
      'admin_reviewed_by': adminReviewedBy,
      'admin_reviewed_at': adminReviewedAt?.toIso8601String(),
      'approved_start_date': approvedStartDate?.toIso8601String(),
      'approved_end_date': approvedEndDate?.toIso8601String(),
      'approved_position': approvedPosition,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active' && 
      approvedStartDate != null &&
      approvedEndDate != null &&
      DateTime.now().isAfter(approvedStartDate!) &&
      DateTime.now().isBefore(approvedEndDate!);

  bool get isExpired => 
      approvedEndDate != null && DateTime.now().isAfter(approvedEndDate!);
}

class ActivePromotion {
  final String id;
  final String promotionRequestId;
  final String providerId;
  final String serviceId;
  final String promotionType;
  final int? position;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  ActivePromotion({
    required this.id,
    required this.promotionRequestId,
    required this.providerId,
    required this.serviceId,
    required this.promotionType,
    this.position,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory ActivePromotion.fromJson(Map<String, dynamic> json) {
    return ActivePromotion(
      id: json['id'],
      promotionRequestId: json['promotion_request_id'],
      providerId: json['provider_id'],
      serviceId: json['service_id'],
      promotionType: json['promotion_type'],
      position: json['position'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotion_request_id': promotionRequestId,
      'provider_id': providerId,
      'service_id': serviceId,
      'promotion_type': promotionType,
      'position': position,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => 
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);
}

class PromotionAuditLog {
  final String id;
  final String promotionId;
  final String promotionType;
  final String action;
  final String? adminId;
  final String? notes;
  final DateTime createdAt;

  PromotionAuditLog({
    required this.id,
    required this.promotionId,
    required this.promotionType,
    required this.action,
    this.adminId,
    this.notes,
    required this.createdAt,
  });

  factory PromotionAuditLog.fromJson(Map<String, dynamic> json) {
    return PromotionAuditLog(
      id: json['id'],
      promotionId: json['promotion_id'],
      promotionType: json['promotion_type'],
      action: json['action'],
      adminId: json['admin_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotion_id': promotionId,
      'promotion_type': promotionType,
      'action': action,
      'admin_id': adminId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PromotionAnalytics {
  final String id;
  final String promotionId;
  final String promotionType;
  final String serviceId;
  final String providerId;
  final int viewsCount;
  final int clicksCount;
  final int conversionCount;
  final DateTime dateRecorded;
  final DateTime createdAt;

  PromotionAnalytics({
    required this.id,
    required this.promotionId,
    required this.promotionType,
    required this.serviceId,
    required this.providerId,
    required this.viewsCount,
    required this.clicksCount,
    required this.conversionCount,
    required this.dateRecorded,
    required this.createdAt,
  });

  factory PromotionAnalytics.fromJson(Map<String, dynamic> json) {
    return PromotionAnalytics(
      id: json['id'],
      promotionId: json['promotion_id'],
      promotionType: json['promotion_type'],
      serviceId: json['service_id'],
      providerId: json['provider_id'],
      viewsCount: json['views_count'],
      clicksCount: json['clicks_count'],
      conversionCount: json['conversion_count'],
      dateRecorded: DateTime.parse(json['date_recorded']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotion_id': promotionId,
      'promotion_type': promotionType,
      'service_id': serviceId,
      'provider_id': providerId,
      'views_count': viewsCount,
      'clicks_count': clicksCount,
      'conversion_count': conversionCount,
      'date_recorded': dateRecorded.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Enums for better type safety
enum OfferStatus {
  pending,
  approved,
  rejected,
  expired,
}

enum PromotionType {
  headerBanner,
  featuredSection,
}

enum PromotionRequestStatus {
  pending,
  approved,
  rejected,
  active,
  expired,
}

enum PromotionAction {
  created,
  approved,
  rejected,
  expired,
  activated,
  deactivated,
}

// Extension methods for enum conversions
extension OfferStatusExtension on OfferStatus {
  String get value {
    switch (this) {
      case OfferStatus.pending:
        return 'pending';
      case OfferStatus.approved:
        return 'approved';
      case OfferStatus.rejected:
        return 'rejected';
      case OfferStatus.expired:
        return 'expired';
    }
  }

  static OfferStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OfferStatus.pending;
      case 'approved':
        return OfferStatus.approved;
      case 'rejected':
        return OfferStatus.rejected;
      case 'expired':
        return OfferStatus.expired;
      default:
        return OfferStatus.pending;
    }
  }
}

extension PromotionTypeExtension on PromotionType {
  String get value {
    switch (this) {
      case PromotionType.headerBanner:
        return 'header_banner';
      case PromotionType.featuredSection:
        return 'featured_section';
    }
  }

  static PromotionType fromString(String value) {
    switch (value) {
      case 'header_banner':
        return PromotionType.headerBanner;
      case 'featured_section':
        return PromotionType.featuredSection;
      default:
        return PromotionType.featuredSection;
    }
  }
}

extension PromotionRequestStatusExtension on PromotionRequestStatus {
  String get value {
    switch (this) {
      case PromotionRequestStatus.pending:
        return 'pending';
      case PromotionRequestStatus.approved:
        return 'approved';
      case PromotionRequestStatus.rejected:
        return 'rejected';
      case PromotionRequestStatus.active:
        return 'active';
      case PromotionRequestStatus.expired:
        return 'expired';
    }
  }

  static PromotionRequestStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PromotionRequestStatus.pending;
      case 'approved':
        return PromotionRequestStatus.approved;
      case 'rejected':
        return PromotionRequestStatus.rejected;
      case 'active':
        return PromotionRequestStatus.active;
      case 'expired':
        return PromotionRequestStatus.expired;
      default:
        return PromotionRequestStatus.pending;
    }
  }
}