import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/load_model.dart';
import '../../repositories/driver_features_repository.dart';

class LoadDetailsScreen extends ConsumerWidget {
  final LoadModel load;
  
  const LoadDetailsScreen({super.key, required this.load});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('dd MMM yyyy').format(load.pickupDate);
    final formattedPrice = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(load.price);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0A1128)),
            ),
          ),
        ),
        title: const Text(
          'Load Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Color(0xFFFFC107), size: 24),
                      const SizedBox(width: 12),
                      Text(load.origin, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1128))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF0A1128)),
                      ),
                      Text(load.destination, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1128))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(load.distance ?? 'N/A', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      Container(height: 12, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                      Text(load.truckType, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      Container(height: 12, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                      Text(load.materialType, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pickup Location
            _buildDetailCard(
              icon: Icons.location_on_outlined,
              label: 'Pickup Location',
              value: load.pickupLocation,
            ),
            const SizedBox(height: 16),
            
            // Drop Location
            _buildDetailCard(
              icon: Icons.flag_outlined,
              label: 'Drop Location',
              value: load.dropLocation,
            ),
            const SizedBox(height: 16),
            
            // Pickup Date
            _buildDetailCard(
              icon: Icons.calendar_today_outlined,
              label: 'Pickup Date',
              value: formattedDate,
            ),
            const SizedBox(height: 16),
            
            // Goods Type
            _buildDetailCard(
              icon: Icons.inventory_2_outlined,
              label: 'Goods Type',
              value: load.materialType,
            ),
            const SizedBox(height: 16),
            
            // Estimated Earning
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Earning', style: TextStyle(color: Color(0xFF059669), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(formattedPrice, style: const TextStyle(color: Color(0xFF059669), fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF059669), size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                // Find driver's active truck
                final profileRepo = ref.read(driverFeaturesRepositoryProvider);
                // Hardcoding truck_id as this is complex to get here without user ID directly
                // In a real flow, we get the truck ID from the user state
                await profileRepo.assignLoadToDriver(load.id, 'dummy_truck_id');
                if (context.mounted) {
                  context.push('/trip_confirmed', extra: load);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning load: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: const Color(0xFF0A1128),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.call_outlined, size: 20),
            label: const Text(
              'Contact Shipper & Confirm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0A1128), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Color(0xFF0A1128), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
