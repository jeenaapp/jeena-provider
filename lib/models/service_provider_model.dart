import 'dart:convert';

class ServiceProvider {
  final String id;
  final String userId;
  final String? commercialName;
  final String? authorizedPersonName;
  final String? nationalId;
  final String? phone;
  final String? email;
  final String? city;
  final String? streetAddress;
  final String? taxNumber;
  final String? bankAccountNumber;
  final String? iban;
  final String? logoUrl;
  final String? branches;
  final String? serviceType;
  final String? description;
  final bool? isApproved;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Legacy fields for backward compatibility
  final String? name;
  final String? registeredName;
  final String? idNumber;
  final String? providerCode;
  final DateTime? approvalDate;

  ServiceProvider({
    required this.id,
    required this.userId,
    this.commercialName,
    this.authorizedPersonName,
    this.nationalId,
    this.phone,
    this.email,
    this.city,
    this.streetAddress,
    this.taxNumber,
    this.bankAccountNumber,
    this.iban,
    this.logoUrl,
    this.branches,
    this.serviceType,
    this.description,
    this.isApproved,
    this.status,
    this.createdAt,
    this.updatedAt,
    // Legacy fields
    this.name,
    this.registeredName,
    this.idNumber,
    this.providerCode,
    this.approvalDate,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      commercialName: json['commercial_name']?.toString(),
      authorizedPersonName: json['authorized_person_name']?.toString(),
      nationalId: json['national_id']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      city: json['city']?.toString(),
      streetAddress: json['street_address']?.toString(),
      taxNumber: json['tax_number']?.toString(),
      bankAccountNumber: json['bank_account_number']?.toString(),
      iban: json['iban']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      branches: json['branches']?.toString(),
      serviceType: json['service_type']?.toString(),
      description: json['description']?.toString(),
      isApproved: json['is_approved'] as bool?,
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      // Legacy fields for backward compatibility
      name: json['name']?.toString(),
      registeredName: json['registered_name']?.toString(),
      idNumber: json['id_number']?.toString(),
      providerCode: json['provider_code']?.toString(),
      approvalDate: json['approval_date'] != null 
          ? DateTime.parse(json['approval_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'commercial_name': commercialName,
      'authorized_person_name': authorizedPersonName,
      'national_id': nationalId,
      'phone': phone,
      'email': email,
      'city': city,
      'street_address': streetAddress,
      'tax_number': taxNumber,
      'bank_account_number': bankAccountNumber,
      'iban': iban,
      'logo_url': logoUrl,
      'branches': branches,
      'service_type': serviceType,
      'description': description,
      'is_approved': isApproved,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Legacy fields
      'name': name,
      'registered_name': registeredName,
      'id_number': idNumber,
      'provider_code': providerCode,
      'approval_date': approvalDate?.toIso8601String(),
    };
  }

  // Helper method to get branches as a list
  List<Map<String, String>> getBranchesList() {
    if (branches == null || branches!.isEmpty) return [];
    try {
      final decoded = jsonDecode(branches!) as List;
      return decoded.map((branch) => {
        'name': branch['name'].toString(),
        'city': branch['city'].toString(),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper method to get the effective commercial name
  String getEffectiveCommercialName() {
    return commercialName ?? name ?? 'غير محدد';
  }

  // Helper method to get the effective authorized person name
  String getEffectiveAuthorizedPersonName() {
    return authorizedPersonName ?? 'غير محدد';
  }

  // Helper method to get the effective national ID
  String getEffectiveNationalId() {
    return nationalId ?? idNumber ?? 'غير محدد';
  }

  // Helper method to get the effective registered name
  String getEffectiveRegisteredName() {
    return registeredName ?? commercialName ?? name ?? 'غير محدد';
  }

  // Helper method to check if provider is approved
  bool get isProviderApproved {
    // TEMPORARY: Always return true to bypass approval requirement
    // TODO: Re-enable approval check when admin panel is fully implemented
    return true;
    
    // Original approval check code (commented out):
    // return isApproved == true || status == 'approved';
  }

  // Helper method to get status display name
  String getStatusDisplayName() {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'suspended':
        return 'معلق';
      default:
        return status ?? 'غير محدد';
    }
  }

  // Helper method to get service type display name
  String getServiceTypeDisplayName() {
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
      case 'other':
        return 'خدمات أخرى';
      default:
        return serviceType ?? 'غير محدد';
    }
  }

  // Copy with method for updating fields
  ServiceProvider copyWith({
    String? id,
    String? userId,
    String? commercialName,
    String? authorizedPersonName,
    String? nationalId,
    String? phone,
    String? email,
    String? city,
    String? streetAddress,
    String? taxNumber,
    String? bankAccountNumber,
    String? iban,
    String? logoUrl,
    String? branches,
    String? serviceType,
    String? description,
    bool? isApproved,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? registeredName,
    String? idNumber,
    String? providerCode,
    DateTime? approvalDate,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commercialName: commercialName ?? this.commercialName,
      authorizedPersonName: authorizedPersonName ?? this.authorizedPersonName,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      streetAddress: streetAddress ?? this.streetAddress,
      taxNumber: taxNumber ?? this.taxNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      iban: iban ?? this.iban,
      logoUrl: logoUrl ?? this.logoUrl,
      branches: branches ?? this.branches,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      registeredName: registeredName ?? this.registeredName,
      idNumber: idNumber ?? this.idNumber,
      providerCode: providerCode ?? this.providerCode,
      approvalDate: approvalDate ?? this.approvalDate,
    );
  }

  @override
  String toString() {
    return 'ServiceProvider(id: $id, commercialName: $commercialName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}