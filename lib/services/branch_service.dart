import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dreamflow/models/branch_model.dart';
import 'package:dreamflow/supabase/supabase_config.dart';

class BranchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all branches for a provider (excluding archived)
  Future<List<Branch>> getProviderBranches(String providerId) async {
    try {
      final response = await _supabase
          .from('branches')
          .select()
          .eq('provider_id', providerId)
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((branch) => Branch.fromJson(branch))
          .toList();
    } catch (e) {
      print('Error fetching branches: $e');
      return [];
    }
  }

  // Get all branches for a provider (including archived)
  Future<List<Branch>> getAllProviderBranches(String providerId) async {
    try {
      final response = await _supabase
          .from('branches')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((branch) => Branch.fromJson(branch))
          .toList();
    } catch (e) {
      print('Error fetching all branches: $e');
      return [];
    }
  }

  // Get a specific branch by ID
  Future<Branch?> getBranchById(String branchId) async {
    try {
      final response = await _supabase
          .from('branches')
          .select()
          .eq('id', branchId)
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      print('Error fetching branch: $e');
      return null;
    }
  }

  // Create a new branch
  Future<Branch?> createBranch({
    required String providerId,
    required String branchName,
    required String city,
    required String exactLocation,
    required String contactNumber,
    required String branchManagerName,
    required String branchManagerEmail,
    String? logoUrl,
  }) async {
    try {
      // Generate branch code using the database function
      final branchCodeResponse = await _supabase
          .rpc('generate_branch_jics_code', params: {'provider_id': providerId});
      
      final branchCode = branchCodeResponse as String;

      final branchData = {
        'provider_id': providerId,
        'branch_name': branchName,
        'branch_code': branchCode,
        'city': city,
        'exact_location': exactLocation,
        'contact_number': contactNumber,
        'branch_manager_name': branchManagerName,
        'branch_manager_email': branchManagerEmail,
        'logo_url': logoUrl,
        'is_active': true,
        'is_archived': false,
      };

      final response = await _supabase
          .from('branches')
          .insert(branchData)
          .select()
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      print('Error creating branch: $e');
      return null;
    }
  }

  // Update an existing branch
  Future<Branch?> updateBranch({
    required String branchId,
    required String branchName,
    required String city,
    required String exactLocation,
    required String contactNumber,
    required String branchManagerName,
    required String branchManagerEmail,
    String? logoUrl,
  }) async {
    try {
      final branchData = {
        'branch_name': branchName,
        'city': city,
        'exact_location': exactLocation,
        'contact_number': contactNumber,
        'branch_manager_name': branchManagerName,
        'branch_manager_email': branchManagerEmail,
        'logo_url': logoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('branches')
          .update(branchData)
          .eq('id', branchId)
          .select()
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      print('Error updating branch: $e');
      return null;
    }
  }

  // Toggle branch active status
  Future<bool> toggleBranchStatus(String branchId, bool isActive) async {
    try {
      await _supabase
          .from('branches')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', branchId);

      return true;
    } catch (e) {
      print('Error toggling branch status: $e');
      return false;
    }
  }

  // Archive a branch (soft delete)
  Future<bool> archiveBranch(String branchId) async {
    try {
      await _supabase
          .from('branches')
          .update({
            'is_archived': true,
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', branchId);

      return true;
    } catch (e) {
      print('Error archiving branch: $e');
      return false;
    }
  }

  // Generate verification code for branch deletion
  Future<String?> generateDeletionVerificationCode(String branchId, String email) async {
    try {
      // Generate a 6-digit verification code
      final code = (100000 + Random().nextInt(900000)).toString();
      
      // Set expiration time to 10 minutes from now
      final expiresAt = DateTime.now().add(Duration(minutes: 10));

      await _supabase.from('verification_codes').insert({
        'email': email,
        'code': code,
        'purpose': 'branch_deletion',
        'entity_id': branchId,
        'expires_at': expiresAt.toIso8601String(),
        'is_used': false,
      });

      return code;
    } catch (e) {
      print('Error generating verification code: $e');
      return null;
    }
  }

  // Verify deletion code
  Future<bool> verifyDeletionCode(String branchId, String email, String code) async {
    try {
      final response = await _supabase
          .from('verification_codes')
          .select()
          .eq('email', email)
          .eq('code', code)
          .eq('purpose', 'branch_deletion')
          .eq('entity_id', branchId)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response == null) {
        return false;
      }

      // Mark the code as used
      await _supabase
          .from('verification_codes')
          .update({'is_used': true})
          .eq('id', response['id']);

      return true;
    } catch (e) {
      print('Error verifying deletion code: $e');
      return false;
    }
  }

  // Delete branch with verification
  Future<bool> deleteBranchWithVerification(String branchId, String email, String code) async {
    try {
      // First verify the code
      final isValidCode = await verifyDeletionCode(branchId, email, code);
      if (!isValidCode) {
        return false;
      }

      // Archive the branch (soft delete)
      return await archiveBranch(branchId);
    } catch (e) {
      print('Error deleting branch: $e');
      return false;
    }
  }

  // Upload branch logo
  Future<String?> uploadBranchLogo(String branchId, String filePath, Uint8List fileBytes) async {
    try {
      final fileName = 'branch_logo_${branchId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'branches/$branchId/$fileName';

      await _supabase.storage
          .from('branch-logos')
          .uploadBinary(storagePath, fileBytes);

      final publicUrl = _supabase.storage
          .from('branch-logos')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading branch logo: $e');
      return null;
    }
  }

  // Get branch statistics
  Future<Map<String, int>> getBranchStatistics(String providerId) async {
    try {
      final branches = await getAllProviderBranches(providerId);
      
      final activeCount = branches.where((branch) => branch.isActive && !branch.isArchived).length;
      final inactiveCount = branches.where((branch) => !branch.isActive && !branch.isArchived).length;
      final archivedCount = branches.where((branch) => branch.isArchived).length;

      return {
        'total': branches.length,
        'active': activeCount,
        'inactive': inactiveCount,
        'archived': archivedCount,
      };
    } catch (e) {
      print('Error getting branch statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'archived': 0,
      };
    }
  }

  // Link branch with services
  Future<bool> linkBranchWithServices(String branchId, List<String> serviceIds) async {
    try {
      // This would require updating the services table to include branch_id
      // For now, we'll prepare the structure
      for (String serviceId in serviceIds) {
        await _supabase
            .from('services')
            .update({'branch_id': branchId})
            .eq('id', serviceId);
      }
      return true;
    } catch (e) {
      print('Error linking branch with services: $e');
      return false;
    }
  }

  // Get services linked to a branch
  Future<List<Map<String, dynamic>>> getBranchServices(String branchId) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('branch_id', branchId)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting branch services: $e');
      return [];
    }
  }

  // Check if branch name exists for provider
  Future<bool> isBranchNameExists(String providerId, String branchName, {String? excludeBranchId}) async {
    try {
      var query = _supabase
          .from('branches')
          .select('id')
          .eq('provider_id', providerId)
          .eq('branch_name', branchName)
          .eq('is_archived', false);

      if (excludeBranchId != null) {
        query = query.neq('id', excludeBranchId);
      }

      final response = await query;
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking branch name existence: $e');
      return false;
    }
  }

  // Send email verification code (placeholder for actual email service)
  Future<bool> sendVerificationEmail(String email, String code, String branchName) async {
    // This would integrate with an actual email service
    // For now, we'll just print the code (in a real app, this would send an email)
    print('Verification code for deleting branch "$branchName": $code');
    print('This code would be sent to: $email');
    
    // In a real implementation, you would integrate with a service like:
    // - SendGrid
    // - AWS SES
    // - Firebase Functions with email service
    // - Supabase Edge Functions with email service
    
    return true;
  }
}