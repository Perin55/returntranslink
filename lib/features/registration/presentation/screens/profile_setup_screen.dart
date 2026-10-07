import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import '../../../profile/models/partner_model.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../profile/repositories/partner_repository.dart';
import '../../../profile/models/partner_profile_model.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;

  String? _selectedCity;
  String? _selectedVehicleType;
  Uint8List? _imageBytes;
  XFile? _profileImage;

  final List<String> _cities = ['Ahmedabad', 'Surat', 'Rajkot', 'Vadodara', 'Mumbai', 'Pune', 'Delhi', 'Jaipur', 'Indore', 'Nagpur', 'Bhopal', 'Hyderabad', 'Bangalore', 'Chennai', 'Kolkata', 'Lucknow', 'Kanpur', 'Patna', 'Ludhiana', 'Agra'];
  final List<String> _vehicleTypes = ['Truck', 'Tempo', 'Trailer', 'Pickup'];

  @override
  void initState() {
    super.initState();
    // Pre-fill mobile number from auth
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.phone != null) {
      // Remove +91 or + if present, just for display (or keep as is)
      _phoneController.text = user.phone!.replaceAll('+91', '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfileData() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final uid = user.id;
      
      String? imageUrl;
      if (_profileImage != null && _imageBytes != null) {
        try {
          final fileExt = _profileImage!.path.split('.').last;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final filePath = 'profile_pics/$uid/$fileName';
          
          await Supabase.instance.client.storage
              .from('profiles')
              .uploadBinary(filePath, _imageBytes!);
              
          imageUrl = Supabase.instance.client.storage.from('profiles').getPublicUrl(filePath);
        } catch (e) {
          debugPrint('Image upload failed: $e');
        }
      }
      
      final profileResp = await Supabase.instance.client.from('profiles').upsert({
        'auth_user_id': uid,
        'role': 'partner',
        'full_name': name,
        'mobile_number': phone,
        'email': email,
        'city': _selectedCity,
        if (imageUrl != null) 'profile_photo_url': imageUrl,
      }, onConflict: 'auth_user_id').select().single();

      await Supabase.instance.client.from('partners').upsert({
        'profile_id': profileResp['id'],
        'owner_name': name,
        'mobile_number': phone,
        'email': email,
        'city': _selectedCity,
        'partner_type': 'individual_owner',
        if (imageUrl != null) 'profile_photo_url': imageUrl,
      }, onConflict: 'profile_id');
      
      if (mounted) {
        context.go('/add_vehicle');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0A1128)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Create Your Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A1128),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 1 of 3 — Basic Details',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  color: const Color(0xFFF9FAFB),
                                  image: _imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _imageBytes == null
                                    ? const Icon(Icons.person_outline, size: 40, color: Color(0xFF6B7280))
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFC107),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Color(0xFF0A1128), size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Ramesh Patel',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Email
                      const Text(
                        'Email Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'e.g. ramesh@gmail.com',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phone Number
                      const Text(
                        'Mobile Number',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          readOnly: true, // Make it read-only
                          decoration: const InputDecoration(
                            hintText: '10-digit Mobile Number',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Color(0xFFF3F4F6),
                            counterText: '',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                              child: Text('+91 ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // City
                      const Text(
                        'City',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            isExpanded: true,
                            hint: const Text('Select City', style: TextStyle(color: Colors.black38, fontSize: 14)),
                            items: _cities.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                              });
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                  : PrimaryButton(
                      text: 'Next',
                      onPressed: _saveProfileData,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}




