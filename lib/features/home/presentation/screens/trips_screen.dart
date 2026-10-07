// trips_screen.dart → Renamed purpose: Customer "Find Trucks" search screen.
// Customers search ACTIVE return requirements (partner trucks needing return load).
// No booking flow. Call/WhatsApp directly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _searched = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _searched = true;
    });
    try {
      var query = Supabase.instance.client
          .from('truck_availability')
          .select('''
            *,
            partners!inner(id, owner_name, mobile_number, profile_id),
            trucks!inner(truck_number, truck_type, body_type, capacity_tons, capacity_kg)
          ''')
          .eq('status', 'available');

      if (_fromController.text.trim().isNotEmpty) {
        query = query.ilike('origin_city', '%${_fromController.text.trim()}%');
      }
      if (_toController.text.trim().isNotEmpty) {
        query = query.ilike('destination_city', '%${_toController.text.trim()}%');
      }

      final res = await query.order('available_date', ascending: true);
      setState(() {
        _results = List<Map<String, dynamic>>.from(res as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _trackContact(String partnerId, String requirementId, String type) async {
    try {
      await Supabase.instance.client.from('contact_events').insert({
        'partner_id': partnerId,
        'requirement_id': requirementId,
        'contact_type': type,
      });
    } catch (_) {}
  }

  Future<void> _callPartner(Map<String, dynamic> req) async {
    final partner = req['partners'] as Map<String, dynamic>;
    final phone = partner['mobile_number'] as String? ?? '';
    await _trackContact(partner['id'] as String, req['id'] as String, 'CALL');
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsappPartner(Map<String, dynamic> req) async {
    final partner = req['partners'] as Map<String, dynamic>;
    final wp = partner['mobile_number'] as String? ?? '';
    final num = wp.replaceAll(RegExp(r'[^0-9]'), '');
    await _trackContact(partner['id'] as String, req['id'] as String, 'WHATSAPP');
    final uri = Uri.parse('https://wa.me/91$num');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find Trucks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0A1128))),
            Text('Search available return trucks', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchField(_fromController, 'From (e.g., Ahmedabad)', Icons.trip_origin),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSearchField(_toController, 'To (e.g., Rajkot)', Icons.location_on_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: const Color(0xFF0A1128),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Search Trucks', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : !_searched
                    ? _buildEmptyPrompt()
                    : _results.isEmpty
                        ? _buildNoResults()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) => _buildResultCard(_results[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Search for available trucks', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Enter pickup and drop location above', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Color(0xFFE5E7EB)),
          SizedBox(height: 16),
          Text('No trucks found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A1128))),
          SizedBox(height: 8),
          Text('Try different cities or dates', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> req) {
    final partner = req['partners'] as Map<String, dynamic>? ?? {};
    final truck = req['trucks'] as Map<String, dynamic>? ?? {};
    final origin = req['origin_city'] as String? ?? 'N/A';
    final dest = req['destination_city'] as String? ?? 'N/A';
    final date = req['available_date'] as String?;
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(date))
        : 'N/A';
    final isVerified = true; // Temporary mock, wait for proper join with profiles for verification status

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route
          Row(
            children: [
              Text(origin, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0A1128))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFFFC107)),
                ),
              ),
              Text(dest, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0A1128))),
            ],
          ),
          const SizedBox(height: 8),

          // Truck details
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                '${truck['truck_type'] ?? 'N/A'} • ${truck['body_type'] ?? 'N/A'} • ${truck['capacity_tons'] ?? 'N/A'} Ton',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text('Available: $formattedDate', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 12),

          // Partner info + actions
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image: null,
                ),
                child: const Icon(Icons.person, size: 20, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner['owner_name'] as String? ?? 'Partner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (isVerified)
                      Row(
                        children: const [
                          Icon(Icons.verified, color: Color(0xFF10B981), size: 12),
                          SizedBox(width: 3),
                          Text('Verified Partner', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                        ],
                      ),
                  ],
                ),
              ),
              // Call
              _buildContactBtn(
                icon: Icons.call_outlined,
                label: 'Call',
                color: const Color(0xFF3B82F6),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () => _callPartner(req),
              ),
              const SizedBox(width: 8),
              // WhatsApp
              _buildContactBtn(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                onTap: () => _whatsappPartner(req),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
