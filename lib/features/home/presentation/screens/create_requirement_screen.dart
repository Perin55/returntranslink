import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

class CreateRequirementScreen extends ConsumerStatefulWidget {
  const CreateRequirementScreen({super.key});

  @override
  ConsumerState<CreateRequirementScreen> createState() => _CreateRequirementScreenState();
}

class _CreateRequirementScreenState extends ConsumerState<CreateRequirementScreen> {
  // Outward Trip Details
  final _outwardOriginCityController = TextEditingController();
  final _outwardDestinationCityController = TextEditingController();

  // Return Trip Details
  bool _wantsAutoReturn = true;
  final _returnOriginCityController = TextEditingController();
  final _returnDestinationCityController = TextEditingController();

  DateTime? _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _timeWindow = 'Any Time'; 
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  
  double? _originLat;
  double? _originLng;
  double? _originAccuracy;
  DateTime? _originTimestamp;
  String _locationSource = 'GPS';

  Map<String, dynamic>? _partner;
  Map<String, dynamic>? _truck;

  @override
  void initState() {
    super.initState();
    _loadPartnerAndTruck();
    _fetchCurrentLocation();
    
    _outwardOriginCityController.addListener(_updateAutoReturnState);
    _outwardDestinationCityController.addListener(_updateAutoReturnState);
  }
  
  void _updateAutoReturnState() {
    if (_wantsAutoReturn) setState(() {}); 
  }

  @override
  void dispose() {
    _outwardOriginCityController.removeListener(_updateAutoReturnState);
    _outwardDestinationCityController.removeListener(_updateAutoReturnState);
    _outwardOriginCityController.dispose();
    _outwardDestinationCityController.dispose();
    _returnOriginCityController.dispose();
    _returnDestinationCityController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerAndTruck() async {
    // DEV BYPASS: if no user is logged in, provide mock data for UI testing
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _partner = {'id': 'mock-partner-id'};
          _truck = {
            'id': 'mock-truck-id',
            'vehicle_number': 'GJ 05 XY 1234',
            'vehicle_type': 'Open Body',
            'capacity': '10',
            'capacity_unit': 'Ton'
          };
        });
      }
      return;
    }

    try {
      final partnerRes = await supabase
          .from('profiles')
          .select('id, partners(id)')
          .eq('auth_user_id', user.id)
          .maybeSingle();
          
      final rawPartners = partnerRes?['partners'];
      Map<String, dynamic>? partner;
      if (rawPartners is List && rawPartners.isNotEmpty) {
        partner = rawPartners[0] as Map<String, dynamic>;
      } else if (rawPartners is Map) {
        partner = Map<String, dynamic>.from(rawPartners);
      }

      if (partner == null || partner['id'] == null) {
        debugPrint('No partner found for user');
        return;
      }
      
      final partnerId = partner['id'];
      if (mounted) setState(() => _partner = {'id': partnerId});

      // Use partner ID (not profile ID) to find the truck
      final truckRes = await supabase
          .from('trucks')
          .select()
          .eq('partner_id', partnerId)
          .maybeSingle();
          
      if (mounted) setState(() => _truck = truckRes);
    } catch (e) {
      debugPrint("Error loading partner/truck: $e");
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          setState(() {
            _isLoadingLocation = false;
            _locationSource = 'MANUAL';
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _originLat = position.latitude;
        _originLng = position.longitude;
        _originAccuracy = position.accuracy;
        _originTimestamp = DateTime.now();
        _locationSource = 'GPS';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationSource = 'MANUAL';
      });
    }
  }

  Future<void> _saveRequirement() async {
    if (_outwardOriginCityController.text.isEmpty) {
      _showError('Please enter starting city');
      return;
    }
    if (_outwardDestinationCityController.text.isEmpty) {
      _showError('Please enter destination city');
      return;
    }
    
    final returnOrigin = _wantsAutoReturn ? _outwardDestinationCityController.text : _returnOriginCityController.text;
    final returnDest = _wantsAutoReturn ? _outwardOriginCityController.text : _returnDestinationCityController.text;
    
    if (returnOrigin.isEmpty || returnDest.isEmpty) {
      _showError('Please provide return trip locations');
      return;
    }
    
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_partner == null) {
      _showError('Profile not loaded correctly.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      // DEV MOCK: Check if we are in test mode
      if (supabase.auth.currentUser == null) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Mode: Trips posted successfully!'), backgroundColor: Colors.green));
          context.go('/dashboard');
        }
        return;
      }

      // 1. Cancel any existing active requirements to prevent unique constraint errors
      await supabase.from('truck_availability')
          .update({'status': 'cancelled'})
          .eq('partner_id', _partner!['id'])
          .eq('status', 'available');

      TimeOfDay? start;
      TimeOfDay? end;
      switch (_timeWindow) {
        case 'Morning': start = const TimeOfDay(hour: 6, minute: 0); end = const TimeOfDay(hour: 12, minute: 0); break;
        case 'Afternoon': start = const TimeOfDay(hour: 12, minute: 0); end = const TimeOfDay(hour: 17, minute: 0); break;
        case 'Evening': start = const TimeOfDay(hour: 17, minute: 0); end = const TimeOfDay(hour: 21, minute: 0); break;
        default: start = const TimeOfDay(hour: 0, minute: 0); end = const TimeOfDay(hour: 23, minute: 59);
      }
      
      final outwardData = {
        'partner_id': _partner!['id'],
        'truck_id': _truck?['id'],
        'origin_city': _outwardOriginCityController.text.trim(),
        'destination_city': _outwardDestinationCityController.text.trim(),
        'origin_latitude': _originLat,
        'origin_longitude': _originLng,
        'available_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'available_from_time': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
        'available_until_time': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
        'status': 'unavailable', // Outward trip is being taken
      };

      await supabase.from('truck_availability').insert(outwardData);

      final returnData = {
        'partner_id': _partner!['id'],
        'truck_id': _truck?['id'],
        'origin_city': returnOrigin.trim(),
        'destination_city': returnDest.trim(),
        'available_date': DateFormat('yyyy-MM-dd').format(_selectedDate!.add(const Duration(days: 1))),
        'available_from_time': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
        'available_until_time': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
        'status': 'available', // Return trip is available
      };

      await supabase.from('truck_availability').insert(returnData);

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trips posted successfully!'), backgroundColor: Color(0xFF10B981)));
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey background for contrast
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Post New Trip',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TRUCK INFO CARD ---
                  _buildTruckCard(),
                  const SizedBox(height: 20),

                  // --- OUTWARD ROUTE CARD ---
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('ROUTE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  ),
                  _buildRouteCard(),
                  const SizedBox(height: 20),

                  // --- RETURN TRIP CARD ---
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('RETURN LOAD (RECOMMENDED)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  ),
                  _buildReturnTripCard(),
                  const SizedBox(height: 20),

                  // --- DATE & TIME CARD ---
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('DATE & TIMINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  ),
                  _buildDateTimeCard(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: _isSaving 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : PrimaryButton(
              text: 'Confirm & Post Trips',
              onPressed: _saveRequirement,
            ),
      ),
    );
  }

  // Helper UI Builders
  Widget _buildTruckCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_shipping, color: AppColors.primaryDark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _truck != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_truck!['vehicle_number'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${_truck!['vehicle_type']} • ${_truck!['capacity']} ${_truck!['capacity_unit']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                )
              : const Text('Loading vehicle...', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // GPS Tag (Optional)
          if (_originLat != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Text('GPS Active', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  const Icon(Icons.circle, color: Colors.green, size: 16),
                  Container(height: 40, width: 2, color: Colors.grey.shade200),
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _outwardOriginCityController,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Enter Pickup City (e.g. Surat)',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.black38),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                    const Divider(height: 30),
                    TextField(
                      controller: _outwardDestinationCityController,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Enter Drop City (e.g. Vadodara)',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.black38),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTripCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wantsAutoReturn ? AppColors.primary : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto-add Reverse Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Get loads for your journey back automatically?', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _wantsAutoReturn = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _wantsAutoReturn ? AppColors.primary : Colors.white,
                            border: Border.all(color: _wantsAutoReturn ? AppColors.primary : AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('Yes, Auto Reverse', style: TextStyle(
                              color: _wantsAutoReturn ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _wantsAutoReturn = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_wantsAutoReturn ? const Color(0xFF1E293B) : Colors.white,
                            border: Border.all(color: !_wantsAutoReturn ? const Color(0xFF1E293B) : AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('No, Custom Route', style: TextStyle(
                              color: !_wantsAutoReturn ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_wantsAutoReturn)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14))),
              child: Row(
                children: [
                  const Icon(Icons.autorenew, color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                        children: [
                          const TextSpan(text: 'Return trip will automatically be created from '),
                          TextSpan(text: _outwardDestinationCityController.text.isNotEmpty ? _outwardDestinationCityController.text : 'Drop City', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' to '),
                          TextSpan(text: _outwardOriginCityController.text.isNotEmpty ? _outwardOriginCityController.text : 'Pickup City', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      controller: _returnOriginCityController,
                      decoration: const InputDecoration(hintText: 'Custom Return Pickup City', border: InputBorder.none, prefixIcon: Icon(Icons.my_location, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      controller: _returnDestinationCityController,
                      decoration: const InputDecoration(hintText: 'Custom Return Drop City', border: InputBorder.none, prefixIcon: Icon(Icons.location_on_outlined, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selection
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: AppColors.textPrimary)), child: child!),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null ? DateFormat('EEEE, dd MMM yyyy').format(_selectedDate!) : 'Select Date',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Time Chips
          const Text('Preferred Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Morning', 'Afternoon', 'Evening', 'Any Time'].map((time) {
              final isSelected = _timeWindow == time;
              return GestureDetector(
                onTap: () => setState(() => _timeWindow = time),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textPrimary : Colors.white,
                    border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
