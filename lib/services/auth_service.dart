import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../utils/arabic_helpers.dart';

class AuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  // Sign in with email and password
  static Future<User?> signIn(String email, String password) async {
    try {
      final response = await SupabaseConfig.signInWithEmail(email, password);
      return response.user;
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: ${e.toString()}');
    }
  }

  // Sign up with email and password
  static Future<User?> signUp(String email, String password, Map<String, dynamic> profileData) async {
    try {
      final response = await SupabaseConfig.signUpWithEmail(email, password);
      
      if (response.user != null) {
        // Create user profile
        await createUserProfile(response.user!.id, email, profileData);
        return response.user;
      }
      return null;
    } catch (e) {
      throw Exception('فشل إنشاء الحساب: ${e.toString()}');
    }
  }

  // Create user profile in database
  static Future<void> createUserProfile(String userId, String email, Map<String, dynamic> profileData) async {
    try {
      final jicsCode = ArabicHelpers.generateJicsCode();
      
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': profileData['full_name'] ?? '',
        'specialty': profileData['specialty'] ?? '',
        'city': profileData['city'] ?? '',
        'phone': profileData['phone'] ?? '',
        'jics_code': jicsCode,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create initial balance record
      await _supabase.from('balance').insert({
        'user_id': userId,
        'current_balance': 0.0,
        'total_earned': 0.0,
        'total_withdrawn': 0.0,
      });

      // Create service provider record (to prevent 404 errors when updating profile)
      await _supabase.from('service_providers').insert({
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send welcome notification
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'مرحباً بك في جينا',
        'message': 'مرحباً بك في منصة جينا للخدمات. نتمنى لك تجربة ممتازة!',
        'type': 'success',
        'is_read': false,
      });
    } catch (e) {
      throw Exception('فشل إنشاء الملف الشخصي: ${e.toString()}');
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return SupabaseConfig.currentUser;
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await SupabaseConfig.signOut();
    } catch (e) {
      throw Exception('فشل تسجيل الخروج: ${e.toString()}');
    }
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return SupabaseConfig.currentUser != null;
  }

  // Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await SupabaseConfig.getUserProfile(userId);
    } catch (e) {
      throw Exception('فشل جلب بيانات المستخدم: ${e.toString()}');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await SupabaseConfig.updateUserProfile(userId, updates);
    } catch (e) {
      throw Exception('فشل تحديث الملف الشخصي: ${e.toString()}');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('فشل إرسال رابط إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('فشل تحديث كلمة المرور: ${e.toString()}');
    }
  }

  // Delete account
  static Future<void> deleteAccount(String userId) async {
    try {
      // Delete user data from custom tables (cascade will handle most)
      await _supabase.from('users').delete().eq('id', userId);
      
      // Note: Deleting from auth.users requires admin privileges
      // This should be handled by the backend/admin panel
    } catch (e) {
      throw Exception('فشل حذف الحساب: ${e.toString()}');
    }
  }
}

// Riverpod providers for state management
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.authStateChanges.map((event) => event.session?.user);
});

final userProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  if (userId.isEmpty) return null;
  return await AuthService.getUserProfile(userId);
});