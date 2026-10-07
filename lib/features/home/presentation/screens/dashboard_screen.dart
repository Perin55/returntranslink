import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/helpers/onboarding_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _partner;
  Map<String, dynamic>? _truck;
  Map<String, dynamic>? _activeRequirement;
  List<Map<String, dynamic>> _notifications = [];
  int _viewsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final pResp = await supabase
          .from('profiles')
          .select('id, full_name, profile_photo_url, city, partners(id, owner_name, profile_photo_url)')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      final rawPartners = pResp?['partners'];
      Map<String, dynamic>? partnerData;
      if (rawPartners is List && rawPartners.isNotEmpty) {
        partnerData = rawPartners[0] as Map<String, dynamic>;
      } else if (rawPartners is Map) {
        partnerData = Map<String, dynamic>.from(rawPartners);
      }

      if (pResp == null || partnerData == null) {
        if (mounted) {
          final target = await OnboardingHelper.getOnboardingRoute();
          if (mounted && target != '/dashboard') {
            context.go(target);
            return;
          }
          setState(() => _isLoading = false);
        }
        return;
      }
      
      // Merge: profile fields take priority, then fallback to partner fields
      _partner = {
        ...partnerData,
        'full_name': pResp['full_name'] ?? partnerData['owner_name'],
        'profile_photo_url': pResp['profile_photo_url'] ?? partnerData['profile_photo_url'],
      };
      final partnerId = _partner!['id'];

      // Load active truck
      final truckRes = await supabase
          .from('trucks')
          .select()
          .eq('partner_id', partnerId)
          .eq('operational_status', 'active')
          .maybeSingle();
      _truck = truckRes;

      // Load active return requirement
      final reqRes = await supabase
          .from('truck_availability')
          .select()
          .eq('partner_id', partnerId)
          .eq('status', 'available')
          .maybeSingle();
      _activeRequirement = reqRes;

      // Load recent unread notifications (max 3)
      final notifRes = await supabase
          .from('notifications')
          .select()
          .eq('partner_id', partnerId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(3);
      _notifications = List<Map<String, dynamic>>.from(notifRes);

      // Load driver number views
      try {
        final viewsRes = await supabase
            .from('driver_number_views')
            .select('id')
            .eq('partner_id', partnerId);
        _viewsCount = (viewsRes as List).length;
      } catch (e) {
        print('Error loading views: $e');
      }

    } catch (e) {
      print('Dashboard load error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final rawName = _partner?['full_name'] ?? _partner?['owner_name'] ?? 'Partner';
    final name = (rawName == 'Pending' || rawName.isEmpty) ? 'Partner' : rawName;
    final status = _partner?['status'] as String? ?? 'NEW';
    final verified = _partner?['verification_status'] == 'APPROVED';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFFFC107),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(name, verified),
                    if (_isLoading) ...[
                      const SizedBox(height: 6),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: Color(0xFFFFC107),
                        minHeight: 2,
                      ),
                    ],
                          const SizedBox(height: 8),
                          if (!verified) _buildVerificationBanner(status),
                          const SizedBox(height: 24),
                          _buildReturnRequirementSection(),
                          const SizedBox(height: 24),
                          _buildAnalyticsSection(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          if (_truck != null) _buildMyTruckCard(),
                          if (_truck == null) _buildAddTruckCard(),
                          const SizedBox(height: 24),
                          if (_notifications.isNotEmpty) _buildNotificationsSection(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, bool verified) {
    final hour = DateTime.now().hour;
    final greeting = hour < 6
        ? 'Good Night'
        : hour < 12
            ? 'Good Morning'
            : hour < 17
                ? 'Good Afternoon'
                : hour < 21
                    ? 'Good Evening'
                    : 'Good Night';

    return Row(
      children: [
        // Profile pic
        GestureDetector(
          onTap: () => context.go('/account'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E7EB),
              image: (_partner?['profile_photo_url'] as String?)?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(_partner!['profile_photo_url'] as String),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (_partner?['profile_photo_url'] == null || (_partner!['profile_photo_url'] as String).isEmpty)
                ? const Icon(Icons.person, color: Color(0xFF6B7280))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              Row(
                children: [
                  Text(
                    '$name 👋',
                    style: const TextStyle(
                      color: Color(0xFF0A1128),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notifications bell
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: const Icon(Icons.notifications_none, size: 20, color: Color(0xFF0A1128)),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBanner(String status) {
    String message;
    Color color;
    IconData icon;

    if (status == 'VERIFICATION_PENDING') {
      message = 'Your profile is under review. We\'ll notify you soon.';
      color = const Color(0xFFFEF3C7);
      icon = Icons.access_time;
    } else if (status == 'DOCUMENTS_INCOMPLETE') {
      message = 'Upload required documents to get verified.';
      color = const Color(0xFFFEF3C7);
      icon = Icons.warning_amber_outlined;
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push('/document_upload'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD97706), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD97706), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnRequirementSection() {
    if (_activeRequirement != null) {
      return _buildActiveRequirementCard();
    }

    // No active requirement — show CTA
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping, color: Color(0xFFFFC107), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Return Load',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Need a Return Load?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Post your return requirement and let shippers find you.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/requirement/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF0A1128),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Return Requirement',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequirementCard() {
    final req = _activeRequirement!;
    final origin = req['origin_city'] as String? ?? req['origin'] as String? ?? 'Origin';
    final destination = req['destination_city'] as String? ?? req['destination'] as String? ?? 'Destination';
    final date = req['available_date'] as String? ?? req['route_date'] as String?;
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(date))
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE REQUIREMENT',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  origin,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFFFFC107), size: 18),
                ),
              ),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReqAction(Icons.visibility_outlined, 'View', () => _showRequirementDetails(req)),
              _buildReqAction(Icons.location_on_outlined, 'Update Location', () {}),
              _buildReqAction(Icons.delete_outline, 'Delete', () => _deleteRequirement()),
              _buildReqAction(Icons.check_circle_outline, 'Complete', () => _completeRequirement()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReqAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        ],
      ),
    );
  }

  void _showRequirementDetails(Map<String, dynamic> req) {
    final origin = req['origin_city'] as String? ?? req['origin'] as String? ?? 'N/A';
    final destination = req['destination_city'] as String? ?? req['destination'] as String? ?? 'N/A';
    final date = req['available_date'] as String? ?? req['route_date'] as String?;
    final formattedDate = date != null
        ? DateFormat('dd MMMM yyyy').format(DateTime.parse(date))
        : 'N/A';
    final status = req['status'] as String? ?? 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Requirement Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From (Origin)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(origin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('To (Destination)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0F172A)),
              ),
              title: const Text('Available Date', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              subtitle: Text(formattedDate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ),
            if (_truck != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping, size: 18, color: Color(0xFF0F172A)),
                ),
                title: const Text('Assigned Vehicle', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                subtitle: Text(
                  '${_truck!['truck_number'] ?? 'N/A'} • ${_truck!['truck_type'] ?? ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRequirement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Requirement?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this requirement? It will be marked as deleted in your history.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirm == true && _activeRequirement != null) {
      try {
        // Mark as deleted in database so it shows as DELETED in History
        await Supabase.instance.client
            .from('truck_availability')
            .update({'status': 'deleted'})
            .eq('id', _activeRequirement!['id']);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Requirement deleted and saved in history')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _completeRequirement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Requirement?'),
        content: const Text('Are you sure you want to mark this return requirement as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _activeRequirement != null) {
      try {
        await Supabase.instance.client
            .from('truck_availability')
            .update({'status': 'unavailable'})
            .eq('id', _activeRequirement!['id']);
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ANALYTICS',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_viewsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Total Number Views',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard(Icons.local_shipping_outlined, 'My Truck', const Color(0xFF3B82F6), () => context.push('/my_vehicles'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.description_outlined, 'Documents', const Color(0xFF8B5CF6), () => context.push('/kyc_documents'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.history, 'History', const Color(0xFFF97316), () => context.go('/history'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.support_agent_outlined, 'Support', const Color(0xFF10B981), () => context.push('/support'))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0A1128))),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTruckCard() {
    final truck = _truck!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MY TRUCK',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/my_vehicles'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truck['truck_number'] ?? truck['vehicle_number'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${truck['truck_type'] ?? truck['vehicle_type'] ?? 'N/A'} • ${truck['body_type'] ?? 'N/A'} • ${truck['capacity_tons'] ?? truck['capacity'] ?? ''} ${truck['capacity_unit'] ?? 'Ton'}',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTruckCard() {
    return GestureDetector(
      onTap: () => context.push('/add_vehicle'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: Color(0xFFFFC107), size: 24),
            SizedBox(width: 8),
            Text('Add Your Truck', style: TextStyle(color: Color(0xFF0A1128), fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NOTIFICATIONS',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: const Text('See all', style: TextStyle(color: Color(0xFFFFC107), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._notifications.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_none, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (n['message'] != null)
                        Text(n['message'] as String, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
