import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:geolocator/geolocator.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../profile/repositories/partner_repository.dart';
import '../../../profile/models/return_requirement_model.dart';

class AddRouteScreen extends ConsumerStatefulWidget {
  const AddRouteScreen({super.key});

  @override
  ConsumerState<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends ConsumerState<AddRouteScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _publishRequirement() async {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    
    if (origin.isEmpty || destination.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final uid = user!.id;
      
      final repo = ref.read(partnerRepositoryProvider);
      final partner = await repo.getPartnerById(uid);
      
      if (partner != null && partner.id != null) {
        // Position? position;
        // try {
        //   position = await _determinePosition();
        // } catch (e) {
        //   if (mounted) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(content: Text('Could not get GPS location: $e')),
        //     );
        //   }
        // }

        final activeTruck = await repo.getActiveTruck(partner.id!);
        if (activeTruck == null || activeTruck.id == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please add an active truck first.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Check for existing active route
        final existingActiveRes = await Supabase.instance.client
            .from('truck_availability')
            .select()
            .eq('partner_id', partner.id!)
            .eq('status', 'available')
            .maybeSingle();

        if (existingActiveRes != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You already have an active route! Please mark it as complete first.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final req = ReturnRequirement(
          partnerId: partner.id!,
          truckId: activeTruck.id,
          origin: origin,
          destination: destination,
          routeDate: _selectedDate!,
          notes: _notesController.text.trim(),
          currentLocationLat: null,
          currentLocationLng: null,
        );
        
        await repo.createReturnRequirement(req);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Requirement Published Successfully!')),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Partner profile not found.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Publish Return Load',
          style: TextStyle(color: Color(0xFF0A1128), fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where are you heading?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your route to let consumers contact you directly.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Origin City', 'e.g., Ahmedabad', _originController),
                      const SizedBox(height: 24),
                      _buildTextField('Destination City', 'e.g., Surat', _destinationController),
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Route Date',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate != null 
                                    ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                    : 'Select Date',
                                style: TextStyle(
                                  color: _selectedDate != null ? const Color(0xFF0A1128) : Colors.black38,
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6B7280)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField('Notes (Optional)', 'Any specific load requirement?', _notesController),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : PrimaryButton(
                    text: 'Publish',
                    onPressed: _publishRequirement,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}




