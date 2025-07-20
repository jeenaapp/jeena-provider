import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dreamflow/models/branch_model.dart';
import 'package:dreamflow/services/branch_service.dart';
import 'package:dreamflow/utils/media_upload_helper.dart';

class AddEditBranchPage extends StatefulWidget {
  final String? providerId;
  final Branch? branch;

  const AddEditBranchPage({
    Key? key,
    this.providerId,
    this.branch,
  }) : super(key: key);

  @override
  _AddEditBranchPageState createState() => _AddEditBranchPageState();
}

class _AddEditBranchPageState extends State<AddEditBranchPage> {
  final _formKey = GlobalKey<FormState>();
  final BranchService _branchService = BranchService();
  
  // Controllers
  final _branchNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _branchManagerNameController = TextEditingController();
  final _branchManagerEmailController = TextEditingController();
  final _exactLocationController = TextEditingController();
  
  // Variables
  String? _selectedCity;
  String? _logoUrl;
  Uint8List? _logoBytes;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final branch = widget.branch!;
    _branchNameController.text = branch.branchName;
    _contactNumberController.text = branch.contactNumber;
    _branchManagerNameController.text = branch.branchManagerName;
    _branchManagerEmailController.text = branch.branchManagerEmail;
    _exactLocationController.text = branch.exactLocation;
    _selectedCity = branch.city;
    _logoUrl = branch.logoUrl;
  }

  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _logoBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? logoUrl = _logoUrl;

      // Upload logo if a new one was selected
      if (_logoBytes != null) {
        setState(() => _isUploading = true);
        
        final branchId = widget.branch?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        logoUrl = await _branchService.uploadBranchLogo(
          branchId,
          'branch_logo.jpg',
          _logoBytes!,
        );
        
        setState(() => _isUploading = false);
      }

      Branch? result;
      
      if (widget.branch == null) {
        // Create new branch
        result = await _branchService.createBranch(
          providerId: widget.providerId!,
          branchName: _branchNameController.text,
          city: _selectedCity!,
          exactLocation: _exactLocationController.text,
          contactNumber: _contactNumberController.text,
          branchManagerName: _branchManagerNameController.text,
          branchManagerEmail: _branchManagerEmailController.text,
          logoUrl: logoUrl,
        );
      } else {
        // Update existing branch
        result = await _branchService.updateBranch(
          branchId: widget.branch!.id,
          branchName: _branchNameController.text,
          city: _selectedCity!,
          exactLocation: _exactLocationController.text,
          contactNumber: _contactNumberController.text,
          branchManagerName: _branchManagerNameController.text,
          branchManagerEmail: _branchManagerEmailController.text,
          logoUrl: logoUrl,
        );
      }

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.branch == null ? 'تم إنشاء الفرع بنجاح' : 'تم تحديث الفرع بنجاح',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('فشل في حفظ الفرع');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ الفرع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.branch == null ? 'إضافة فرع جديد' : 'تعديل الفرع',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFCFA55B),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _isUploading
                            ? Center(child: CircularProgressIndicator())
                            : _logoBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _logoBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _logoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _logoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.store, size: 50, color: Colors.grey),
                                        ),
                                      )
                                    : Icon(Icons.store, size: 50, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اضغط لاختيار شعار الفرع',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Branch Information Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات الفرع',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCFA55B),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Branch Name
                      TextFormField(
                        controller: _branchNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الفرع *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم الفرع';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // City Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'المدينة *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: SaudiCities.getUniqueCities().map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى اختيار المدينة';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Exact Location
                      TextFormField(
                        controller: _exactLocationController,
                        decoration: InputDecoration(
                          labelText: 'الموقع التفصيلي *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () {
                              // TODO: Implement map picker
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خاصية اختيار الموقع من الخريطة قيد التطوير'),
                                ),
                              );
                            },
                          ),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال الموقع التفصيلي';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Contact Number
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رقم الهاتف';
                          }
                          if (value.length < 10) {
                            return 'رقم الهاتف يجب أن يكون 10 أرقام';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Branch Manager Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات مدير الفرع',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCFA55B),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Manager Name
                      TextFormField(
                        controller: _branchManagerNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم مدير الفرع *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم مدير الفرع';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Manager Email
                      TextFormField(
                        controller: _branchManagerEmailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني للمدير *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'يرجى إدخال بريد إلكتروني صحيح';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBranch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFCFA55B),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.branch == null ? 'إضافة الفرع' : 'حفظ التغييرات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _contactNumberController.dispose();
    _branchManagerNameController.dispose();
    _branchManagerEmailController.dispose();
    _exactLocationController.dispose();
    super.dispose();
  }
}