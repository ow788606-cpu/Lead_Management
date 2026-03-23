import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/app_drawer.dart';
import '../../managers/auth_manager.dart';
import '../../services/api_config.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickImage() async {
    try {
      if (!mounted) return;
      
      final source = await showDialog<ImageSource>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: Color(0xFF131416),
                  size: 24.0,
                ),
                title: const Text('Camera'),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedImage02,
                  color: Color(0xFF131416),
                  size: 24.0,
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission is required')),
            );
          }
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null && mounted) {
        setState(() {
          _profileImagePath = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await AuthManager().getUserId();
      if (userId == null || userId <= 0) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users.php?user_id=$userId'),
      );
      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      _nameController.text = (data['name'] ?? '').toString();
      _locationController.text = (data['location'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();
      _addressController.text = (data['address'] ?? '').toString();
      _cityController.text = (data['city'] ?? '').toString();
      _zipController.text = (data['zip'] ?? '').toString();
      _countryController.text = (data['country'] ?? '').toString();
    } catch (_) {
      // Keep form editable even when load fails.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await AuthManager().getUserId();
      if (userId == null || userId <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login again.')),
        );
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'zip': _zipController.text.trim(),
          'country': _countryController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: AppDrawer(
        selectedIndex: -2,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMenu01,
              color: Colors.black,
              size: 24.0,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Manage Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF131416),
                                  child: _profileImagePath != null
                                      ? ClipOval(
                                          child: Image.file(
                                            File(_profileImagePath!),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.person,
                                                  size: 50, color: Colors.white);
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.person,
                                          size: 50, color: Colors.white),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedCamera01,
                                        color: Color(0xFF131416),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text('Personal Details',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 16),
                          _buildTextField(
                              'Name', _nameController, Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField('Location', _locationController,
                              Icons.location_on_outlined),
                          const SizedBox(height: 16),
                          _buildTextField(
                              'Email', _emailController, Icons.email_outlined),
                          const SizedBox(height: 16),
                          _buildTextField(
                              'Phone', _phoneController, Icons.phone_outlined),
                          const SizedBox(height: 16),
                          _buildTextField('Address', _addressController,
                              Icons.home_outlined),
                          const SizedBox(height: 16),
                          _buildTextField('City', _cityController,
                              Icons.location_city_outlined),
                          const SizedBox(height: 16),
                          _buildTextField('Zip Code', _zipController,
                              Icons.markunread_mailbox_outlined),
                          const SizedBox(height: 16),
                          _buildTextField('Country', _countryController,
                              Icons.flag_outlined),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF131416),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Update Profile',
                                      style: TextStyle(
                                          fontSize: 14, fontFamily: 'Inter')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter')),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF131416)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}
