import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreamflow/models/branch_model.dart';
import 'package:dreamflow/services/branch_service.dart';
import 'package:dreamflow/services/service_provider_service.dart';
import 'package:dreamflow/models/service_provider_model.dart';
import 'package:dreamflow/pages/add_edit_branch_page.dart';
import 'package:dreamflow/widgets/custom_sidebar.dart';
import 'package:dreamflow/supabase/supabase_config.dart';

class BranchesPage extends ConsumerStatefulWidget {
  @override
  _BranchesPageState createState() => _BranchesPageState();
}

class _BranchesPageState extends ConsumerState<BranchesPage> {
  final BranchService _branchService = BranchService();
  final ServiceProviderService _providerService = ServiceProviderService();
  List<Branch> _branches = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String? _providerId;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user ID
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser != null) {
        final provider = await ServiceProviderService.getProviderProfile(currentUser.id);
        if (provider != null) {
          _providerId = provider.id;
          final branches = await _branchService.getProviderBranches(_providerId!);
          final statistics = await _branchService.getBranchStatistics(_providerId!);
          
          setState(() {
            _branches = branches;
            _statistics = statistics;
          });
        }
      }
    } catch (e) {
      print('Error loading branches: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBranchStatus(Branch branch) async {
    final success = await _branchService.toggleBranchStatus(branch.id, !branch.isActive);
    if (success) {
      _loadBranches();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            branch.isActive ? 'تم إلغاء تفعيل الفرع' : 'تم تفعيل الفرع',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: branch.isActive ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(Branch branch) async {
    final TextEditingController _codeController = TextEditingController();
    bool _codeSent = false;
    bool _isVerifying = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('حذف الفرع', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('هل أنت متأكد من حذف فرع "${branch.branchName}"؟'),
              SizedBox(height: 16),
              if (!_codeSent) ...[
                Text('سيتم إرسال رمز التحقق إلى: ${branch.branchManagerEmail}'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final code = await _branchService.generateDeletionVerificationCode(
                          branch.id,
                          branch.branchManagerEmail,
                        );
                        if (code != null) {
                          await _branchService.sendVerificationEmail(
                            branch.branchManagerEmail,
                            code,
                            branch.branchName,
                          );
                          setDialogState(() => _codeSent = true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('إرسال رمز التحقق', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ] else ...[
                Text('أدخل رمز التحقق المرسل إلى ${branch.branchManagerEmail}'),
                SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'رمز التحقق',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : () async {
                        setDialogState(() => _isVerifying = true);
                        final success = await _branchService.deleteBranchWithVerification(
                          branch.id,
                          branch.branchManagerEmail,
                          _codeController.text,
                        );
                        if (success) {
                          Navigator.pop(context);
                          _loadBranches();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم حذف الفرع بنجاح', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('رمز التحقق غير صحيح أو منتهي الصلاحية', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setDialogState(() => _isVerifying = false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: _isVerifying 
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text('حذف الفرع', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الفروع', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFCFA55B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBranches,
          ),
        ],
      ),
      drawer: CustomSidebar(
        currentPage: 'branches',
        onPageChanged: (page) {
          Navigator.pop(context);
          // Handle page navigation - this would typically be handled by the main navigator
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'إجمالي الفروع',
                          _statistics['total']?.toString() ?? '0',
                          Icons.store,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'الفروع النشطة',
                          _statistics['active']?.toString() ?? '0',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'الفروع المعطلة',
                          _statistics['inactive']?.toString() ?? '0',
                          Icons.pause_circle,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Branch List
                Expanded(
                  child: _branches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد فروع حالياً',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'قم بإضافة فرع جديد للبدء',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            final branch = _branches[index];
                            return _buildBranchCard(branch);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditBranchPage(providerId: _providerId),
            ),
          ).then((_) => _loadBranches());
        },
        backgroundColor: Color(0xFFCFA55B),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Branch Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: branch.logoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            branch.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.store, size: 30, color: Colors.grey),
                          ),
                        )
                      : Icon(Icons.store, size: 30, color: Colors.grey),
                ),
                SizedBox(width: 16),
                
                // Branch Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.branchName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'رمز الفرع: ${branch.branchCode}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            branch.city,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: branch.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    branch.isActive ? 'نشط' : 'معطل',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Branch Details
            _buildInfoRow('المدير', branch.branchManagerName),
            _buildInfoRow('الهاتف', branch.contactNumber),
            _buildInfoRow('الموقع', branch.exactLocation),
            
            SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'تعديل',
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditBranchPage(
                          providerId: _providerId,
                          branch: branch,
                        ),
                      ),
                    ).then((_) => _loadBranches());
                  },
                ),
                _buildActionButton(
                  icon: branch.isActive ? Icons.pause : Icons.play_arrow,
                  label: branch.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                  color: branch.isActive ? Colors.orange : Colors.green,
                  onPressed: () => _toggleBranchStatus(branch),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'حذف',
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(branch),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}