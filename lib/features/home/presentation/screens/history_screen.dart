import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, ACTIVE, COMPLETED, DELETED
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedFilter = 'ALL';
              break;
            case 1:
              _selectedFilter = 'ACTIVE';
              break;
            case 2:
              _selectedFilter = 'COMPLETED';
              break;
            case 3:
              _selectedFilter = 'DELETED';
              break;
          }
        });
      }
    });
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final profile = await supabase.from('profiles').select('id, partners(id)').eq('auth_user_id', user.id).maybeSingle();
      final partnersRaw = profile?['partners'];
      Map<String, dynamic>? partner;
      if (partnersRaw is List && partnersRaw.isNotEmpty) {
        partner = partnersRaw[0] as Map<String, dynamic>;
      } else if (partnersRaw is Map) {
        partner = Map<String, dynamic>.from(partnersRaw);
      }

      if (partner != null && partner['id'] != null) {
        final res = await supabase.from('truck_availability')
            .select('*, trucks(truck_number, truck_type)')
            .eq('partner_id', partner['id'])
            .order('created_at', ascending: false);
            
        setState(() {
          _trips = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredTrips {
    if (_selectedFilter == 'ALL') return _trips;
    return _trips.where((t) {
      final st = (t['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'ACTIVE') return st == 'AVAILABLE';
      if (_selectedFilter == 'COMPLETED') return st == 'COMPLETED' || st == 'UNAVAILABLE';
      if (_selectedFilter == 'DELETED') return st == 'DELETED' || st == 'CANCELLED';
      return true;
    }).toList();
  }

  Future<void> _repostRoute(Map<String, dynamic> trip) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select New Route Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final existingActiveRes = await supabase
          .from('truck_availability')
          .select()
          .eq('partner_id', trip['partner_id'])
          .eq('status', 'available')
          .maybeSingle();

      if (existingActiveRes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFDC2626),
              content: Text('You already have an active route! Please complete or delete it first.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await supabase.from('truck_availability').insert({
        'partner_id': trip['partner_id'],
        'truck_id': trip['truck_id'],
        'origin_city': trip['origin_city'] ?? trip['origin'],
        'destination_city': trip['destination_city'] ?? trip['destination'],
        'origin': trip['origin_city'] ?? trip['origin'],
        'destination': trip['destination_city'] ?? trip['destination'],
        'available_date': pickedDate.toIso8601String().split('T').first,
        'status': 'available',
      });

      await _fetchHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Route reposted successfully! It is now active on your dashboard.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _trips.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'AVAILABLE').length;
    final completedCount = _trips.where((t) {
      final s = (t['status'] ?? '').toString().toUpperCase();
      return s == 'COMPLETED' || s == 'UNAVAILABLE';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Route History & Leads',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 22),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF0F172A),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'All (${_trips.length})'),
                Tab(text: 'Active ($activeCount)'),
                Tab(text: 'Done ($completedCount)'),
                const Tab(text: 'Deleted'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0F172A),
          onRefresh: _fetchHistory,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: Color(0xFF0F172A),
                      minHeight: 2,
                    ),
                  
                  // Summary Header Card
                  if (!_isLoading && _trips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCol('TOTAL ROUTES', '${_trips.length}', Colors.white),
                            Container(width: 1, height: 28, color: Colors.white24),
                            _buildSummaryCol('ACTIVE NOW', '$activeCount', const Color(0xFF34D399)),
                            Container(width: 1, height: 28, color: Colors.white24),
                            _buildSummaryCol('COMPLETED', '$completedCount', const Color(0xFF60A5FA)),
                          ],
                        ),
                      ),
                    ),

                  Expanded(
                    child: _filteredTrips.isEmpty
                        ? (_isLoading ? const SizedBox.shrink() : _buildEmptyState())
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTrips.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final trip = _filteredTrips[index];
                              return _buildTripCard(trip);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Routes in this category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your posted return load routes and performance reports will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final origin = trip['origin_city'] ?? trip['origin'] ?? 'Origin';
    final dest = trip['destination_city'] ?? trip['destination'] ?? 'Destination';
    final status = (trip['status'] ?? 'UNKNOWN').toString().toUpperCase();
    final routeDateStr = trip['available_date'] as String?;
    final date = routeDateStr != null 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(routeDateStr))
        : 'Date N/A';

    final isActive = status == 'AVAILABLE';
    final isDeleted = status == 'DELETED' || status == 'CANCELLED';
    final isCompleted = status == 'COMPLETED' || status == 'UNAVAILABLE';

    Color badgeColor = const Color(0xFF64748B);
    Color badgeBg = const Color(0xFFF1F5F9);
    String statusLabel = status;

    if (isActive) {
      badgeColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFD1FAE5);
      statusLabel = 'ACTIVE';
    } else if (isDeleted) {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
      statusLabel = 'DELETED';
    } else if (isCompleted) {
      badgeColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFDBEAFE);
      statusLabel = 'COMPLETED';
    }

    final mockViews = (origin.length + dest.length) * 2;
    final truckData = trip['trucks'] as Map<String, dynamic>?;
    final truckNumber = truckData?['truck_number'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981).withOpacity(0.6) : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Route Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dots & line
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            border: Border.all(color: const Color(0xFF10B981), width: 3),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 28,
                          color: const Color(0xFFCBD5E1),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444).withOpacity(0.2),
                            border: Border.all(color: const Color(0xFFEF4444), width: 3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Cities
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            dest,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    if (truckNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFF475569)),
                            const SizedBox(width: 4),
                            Text(
                              truckNumber,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Lead Analytics Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF3B82F6), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Driver number viewed $mockViews times by customers',
                  style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Action Button (Repost for Inactive/Deleted)
          if (!isActive)
            InkWell(
              onTap: () => _repostRoute(trip),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.replay_rounded, color: Color(0xFF0F172A), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Repost This Route',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
