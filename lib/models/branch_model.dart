class Branch {
  final String id;
  final String providerId;
  final String branchName;
  final String branchCode;
  final String city;
  final String exactLocation;
  final String contactNumber;
  final String branchManagerName;
  final String branchManagerEmail;
  final String? logoUrl;
  final bool isActive;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.providerId,
    required this.branchName,
    required this.branchCode,
    required this.city,
    required this.exactLocation,
    required this.contactNumber,
    required this.branchManagerName,
    required this.branchManagerEmail,
    this.logoUrl,
    required this.isActive,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      providerId: json['provider_id'],
      branchName: json['branch_name'],
      branchCode: json['branch_code'],
      city: json['city'],
      exactLocation: json['exact_location'],
      contactNumber: json['contact_number'],
      branchManagerName: json['branch_manager_name'],
      branchManagerEmail: json['branch_manager_email'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'branch_name': branchName,
      'branch_code': branchCode,
      'city': city,
      'exact_location': exactLocation,
      'contact_number': contactNumber,
      'branch_manager_name': branchManagerName,
      'branch_manager_email': branchManagerEmail,
      'logo_url': logoUrl,
      'is_active': isActive,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Branch copyWith({
    String? id,
    String? providerId,
    String? branchName,
    String? branchCode,
    String? city,
    String? exactLocation,
    String? contactNumber,
    String? branchManagerName,
    String? branchManagerEmail,
    String? logoUrl,
    bool? isActive,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      branchName: branchName ?? this.branchName,
      branchCode: branchCode ?? this.branchCode,
      city: city ?? this.city,
      exactLocation: exactLocation ?? this.exactLocation,
      contactNumber: contactNumber ?? this.contactNumber,
      branchManagerName: branchManagerName ?? this.branchManagerName,
      branchManagerEmail: branchManagerEmail ?? this.branchManagerEmail,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VerificationCode {
  final String id;
  final String email;
  final String code;
  final String purpose;
  final String? entityId;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  VerificationCode({
    required this.id,
    required this.email,
    required this.code,
    required this.purpose,
    this.entityId,
    required this.expiresAt,
    required this.isUsed,
    required this.createdAt,
  });

  factory VerificationCode.fromJson(Map<String, dynamic> json) {
    return VerificationCode(
      id: json['id'],
      email: json['email'],
      code: json['code'],
      purpose: json['purpose'],
      entityId: json['entity_id'],
      expiresAt: DateTime.parse(json['expires_at']),
      isUsed: json['is_used'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'code': code,
      'purpose': purpose,
      'entity_id': entityId,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Saudi cities data
class SaudiCities {
  static const List<String> cities = [
    'الرياض', // Riyadh
    'جدة', // Jeddah
    'مكة المكرمة', // Mecca
    'المدينة المنورة', // Medina
    'الدمام', // Dammam
    'الخبر', // Khobar
    'الظهران', // Dhahran
    'الطائف', // Taif
    'بريدة', // Buraidah
    'تبوك', // Tabuk
    'خميس مشيط', // Khamis Mushait
    'أبها', // Abha
    'الهفوف', // Hofuf
    'حفر الباطن', // Hafr Al-Batin
    'الجبيل', // Jubail
    'ينبع', // Yanbu
    'عرعر', // Arar
    'سكاكا', // Sakaka
    'جازان', // Jazan
    'نجران', // Najran
    'الباحة', // Al Bahah
    'القطيف', // Qatif
    'عنيزة', // Unaizah
    'الرس', // Ar Rass
    'الدوادمي', // Al Dawadmi
    'الخرج', // Al Kharj
    'الزلفي', // Az Zulfi
    'وادي الدواسر', // Wadi Al-Dawasir
    'الليث', // Al Lith
    'رابغ', // Rabigh
    'الخرمة', // Al Khurmah
    'الحوية', // Al Hawiyah
    'بيشة', // Bisha
    'الدرعية', // Diriyah
    'الملز', // Al Malaz
    'الخرج', // Al Kharj
    'الأحساء', // Al Ahsa
    'حائل', // Hail
    'الدمام', // Dammam
    'الخبر', // Al Khobar
    'النعيرية', // An Nuayriyah
    'الخرج', // Al Kharj
    'الزلفي', // Az Zulfi
    'القريات', // Al Qurayyat
    'طريف', // Turaif
    'الخفجي', // Al Khafji
    'رفحاء', // Rafha
    'الدوادمي', // Al Dawadmi
    'الخرج', // Al Kharj
    'الزلفي', // Az Zulfi
    'المجمعة', // Al Majma'ah
    'القصيم', // Al Qassim
    'الدمام', // Dammam
    'الخبر', // Al Khobar
    'الظهران', // Dhahran
    'الأحساء', // Al Ahsa
    'حفر الباطن', // Hafr Al-Batin
    'الجبيل', // Jubail
    'الخفجي', // Al Khafji
    'النعيرية', // An Nuayriyah
    'القطيف', // Qatif
    'الزلفي', // Az Zulfi
    'الخرج', // Al Kharj
    'الدوادمي', // Al Dawadmi
    'الدرعية', // Diriyah
    'الملز', // Al Malaz
    'الخرج', // Al Kharj
    'الأحساء', // Al Ahsa
    'حائل', // Hail
    'الدمام', // Dammam
    'الخبر', // Al Khobar
    'النعيرية', // An Nuayriyah
    'الخرج', // Al Kharj
    'الزلفي', // Az Zulfi
    'القريات', // Al Qurayyat
    'طريف', // Turaif
    'الخفجي', // Al Khafji
    'رفحاء', // Rafha
    'الدوادمي', // Al Dawadmi
    'الخرج', // Al Kharj
    'الزلفي', // Az Zulfi
    'المجمعة', // Al Majma'ah
    'القصيم', // Al Qassim
  ];

  static List<String> getUniqueCities() {
    return cities.toSet().toList()..sort();
  }
}