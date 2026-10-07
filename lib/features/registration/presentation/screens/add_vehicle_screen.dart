import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/primary_button.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final bool isRegistration;
  const AddVehicleScreen({super.key, this.isRegistration = false});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _vehicleNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _currentLocationController = TextEditingController();
  final _regularStartingLocationController = TextEditingController();
  final _regularRoutesController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverMobileController = TextEditingController();
  String? _selectedBodyType;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _capacityController.dispose();
    _currentLocationController.dispose();
    _regularStartingLocationController.dispose();
    _regularRoutesController.dispose();
    _driverNameController.dispose();
    _driverMobileController.dispose();
    super.dispose();
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
                    onTap: () => context.pop(),
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
                    'Add Your Vehicle',
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
                'Step 2 of 3 — Vehicle Details',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // Vehicle Number
                      const Text(
                        'Vehicle Number',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _vehicleNumberController,
                          decoration: const InputDecoration(
                            hintText: 'GJ01AB1234',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: Icon(Icons.qr_code_scanner, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Body Type (Dropdown)
                      const Text(
                        'Body Type',
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
                            isExpanded: true,
                            hint: const Text('Select Body Type', style: TextStyle(color: Colors.black38, fontSize: 14)),
                            value: _selectedBodyType,
                            items: ['Open', 'Closed', 'Container', 'Trailer', 'Tanker'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBodyType = value;
                              });
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const SizedBox(height: 24),

                      // Truck Capacity
                      const Text(
                        'Truck Capacity (in Tons)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 14',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Current Location
                      const Text(
                        'Current Location',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _currentLocationController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Surat',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: Icon(Icons.my_location, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Regular Starting Location
                      const Text(
                        'Regular Starting Location',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _regularStartingLocationController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Ahmedabad',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: Icon(Icons.home_outlined, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Regular Routes
                      const Text(
                        'Regular Routes',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _regularRoutesController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Ahmedabad to Mumbai',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: Icon(Icons.route, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Driver Name
                      const Text(
                        'Driver Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _driverNameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Suresh Kumar',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: Icon(Icons.person_outline, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Driver Mobile Number
                      const Text(
                        'Driver Mobile Number',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _driverMobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            hintText: '10-digit Mobile Number',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            counterText: '',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                              child: Text('+91 ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              PrimaryButton(
                text: widget.isRegistration ? 'Next' : 'Add Vehicle',
                onPressed: () async {
                  final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
                  
                  final RegExp truckNumRegex = RegExp(r'^[A-Z]{2}\s?[0-9]{1,2}\s?[A-Z]{0,2}\s?[0-9]{4}$');
                  if (!truckNumRegex.hasMatch(vehicleNumber)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Format (e.g. MH 04 AB 1234)')),
                    );
                    return;
                  }

                  final user = Supabase.instance.client.auth.currentUser;
                  final uid = user!.id;
                  
                  try {
                    final profileResp = await Supabase.instance.client
                        .from('profiles')
                        .select('id, partners(id)')
                        .eq('auth_user_id', uid)
                        .maybeSingle();

                    final partnersRaw = profileResp?['partners'];
                    Map<String, dynamic>? partner;
                    if (partnersRaw is List && partnersRaw.isNotEmpty) {
                      partner = partnersRaw[0] as Map<String, dynamic>;
                    } else if (partnersRaw is Map) {
                      partner = Map<String, dynamic>.from(partnersRaw);
                    }

                    if (partner == null || partner['id'] == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error: Partner profile not found')),
                        );
                      }
                      return;
                    }
                    
                    final partnerIdStr = partner['id'].toString();
                    
                    final existingTruck = await Supabase.instance.client
                        .from('trucks')
                        .select('id')
                        .eq('partner_id', partnerIdStr)
                        .eq('operational_status', 'active')
                        .maybeSingle();
                        
                    final truckCapacityTons = double.tryParse(_capacityController.text.trim()) ?? 0.0;
                    final truckCapacityKg = (truckCapacityTons * 1000).toInt();

                    final truckData = {
                      'partner_id': partnerIdStr,
                      'truck_number': vehicleNumber,
                      'truck_type': _selectedBodyType ?? 'Open',
                      'body_type': _selectedBodyType ?? 'Open',
                      'capacity_tons': truckCapacityTons,
                      'capacity_kg': truckCapacityKg > 0 ? truckCapacityKg : 1000,
                      'availability_status': 'available',
                      'operational_status': 'active',
                    };

                    if (existingTruck != null) {
                      await Supabase.instance.client
                          .from('trucks')
                          .update(truckData)
                          .eq('id', existingTruck['id']);
                    } else {
                      await Supabase.instance.client
                          .from('trucks')
                          .insert(truckData);
                    }
                    
                    if (widget.isRegistration) {
                      // PRD: Move to document upload before dashboard
                      if (context.mounted) context.go('/document_upload');
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vehicle added successfully!')),
                        );
                        context.pop();
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}




