import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class KycDocumentsScreen extends StatefulWidget {
  const KycDocumentsScreen({super.key});

  @override
  State<KycDocumentsScreen> createState() => _KycDocumentsScreenState();
}

class _KycDocumentsScreenState extends State<KycDocumentsScreen> {
  bool _isLoading = true;
  String? _partnerVerificationStatus;
  List<Map<String, dynamic>> _documents = [];

  final List<String> _requiredDocTypes = [
    'Aadhaar',
    'Driving Licence',
    'RC',
    'PUC',
    'Fitness Certificate',
    'Insurance',
  ];

  @override
  void initState() {
    super.initState();
    _fetchKycDocuments();
  }

  Future<void> _fetchKycDocuments() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch profile & partner info
      final pResp = await supabase
          .from('profiles')
          .select('id, is_verified, partners(id, verification_status, trucks(id))')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (pResp != null) {
        final rawPartners = pResp['partners'];
        Map<String, dynamic>? partner;
        if (rawPartners is List && rawPartners.isNotEmpty) {
          partner = rawPartners[0] as Map<String, dynamic>;
        } else if (rawPartners is Map) {
          partner = Map<String, dynamic>.from(rawPartners);
        }

        if (partner != null) {
          _partnerVerificationStatus = partner['verification_status'] as String? ?? 'pending';

          // Extract truck ID
          final trucksRaw = partner['trucks'];
          List<dynamic> trucksList = [];
          if (trucksRaw is List) {
            trucksList = trucksRaw;
          } else if (trucksRaw is Map) {
            trucksList = [trucksRaw];
          }

          String? truckId;
          if (trucksList.isNotEmpty && trucksList[0] is Map) {
            truckId = (trucksList[0] as Map)['id']?.toString();
          }

          // 2. Fetch truck_documents from Supabase
          List<Map<String, dynamic>> fetchedDocs = [];
          if (truckId != null) {
            final docsRes = await supabase
                .from('truck_documents')
                .select()
                .eq('truck_id', truckId)
                .order('created_at', ascending: false);

            fetchedDocs = List<Map<String, dynamic>>.from(docsRes);
          }

          // Also check fallback 'documents' table if any
          try {
            final partnerDocsRes = await supabase
                .from('documents')
                .select()
                .eq('partner_id', partner['id'])
                .order('created_at', ascending: false);
            for (final d in partnerDocsRes) {
              final docType = d['document_type'];
              if (!fetchedDocs.any((f) => f['document_type'] == docType)) {
                fetchedDocs.add({
                  'document_type': docType,
                  'document_url': d['file_url'] ?? d['file_path'],
                  'verification_status': d['verification_status'] ?? 'pending',
                  'created_at': d['created_at'],
                });
              }
            }
          } catch (_) {}

          _documents = fetchedDocs;
        }
      }
    } catch (e) {
      debugPrint('Error fetching KYC documents: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'KYC & Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _fetchKycDocuments,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    _buildStatusBanner(),
                    const SizedBox(height: 20),
                    const Text(
                      'Partner & Vehicle Documents',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1128),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Documents uploaded to Return Translink for verification',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    ..._requiredDocTypes.map((type) => _buildDocumentTile(type)),
                    const SizedBox(height: 24),
                    _buildUploadNewDocButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _partnerVerificationStatus?.toLowerCase() ?? 'pending';
    final isVerified = status == 'verified' || status == 'approved';
    final isRejected = status == 'rejected';

    Color bgColor = const Color(0xFFFFFBEB); // yellow/orange
    Color borderColor = const Color(0xFFFDE68A);
    Color textColor = const Color(0xFFB45309);
    IconData icon = Icons.access_time_filled;
    String title = 'Verification Under Review';
    String desc = 'Your documents are currently being checked by our compliance team. Verification takes 24-48 hours.';

    if (isVerified) {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      textColor = const Color(0xFF065F46);
      icon = Icons.verified;
      title = 'KYC Verified Partner';
      desc = 'All your submitted documents have been approved. You are ready to accept unlimited return loads.';
    } else if (isRejected) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = const Color(0xFF991B1B);
      icon = Icons.cancel;
      title = 'Verification Rejected';
      desc = 'One or more of your documents could not be verified. Please re-upload clearer copies.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String docType) {
    // Find matching uploaded doc
    final doc = _documents.firstWhere(
      (d) => (d['document_type'] as String?)?.toLowerCase() == docType.toLowerCase(),
      orElse: () => {},
    );

    final isUploaded = doc.isNotEmpty;
    final fileUrl = doc['document_url'] as String?;
    final verificationStatus = (doc['verification_status'] as String? ?? 'pending').toLowerCase();

    Color statusBadgeColor = const Color(0xFFF3F4F6);
    Color statusTextColor = const Color(0xFF4B5563);
    String statusLabel = 'Not Uploaded';

    if (isUploaded) {
      if (verificationStatus == 'verified') {
        statusBadgeColor = const Color(0xFFDCFCE7);
        statusTextColor = const Color(0xFF15803D);
        statusLabel = 'Verified';
      } else if (verificationStatus == 'rejected') {
        statusBadgeColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFB91C1C);
        statusLabel = 'Rejected';
      } else {
        statusBadgeColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFD97706);
        statusLabel = 'Under Review';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUploaded ? Icons.description : Icons.upload_file,
              color: isUploaded ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0A1128),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUploaded ? 'Document uploaded & on file' : 'Action required: Upload copy',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUploaded ? const Color(0xFF4B5563) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusTextColor,
                  ),
                ),
              ),
              if (fileUrl != null && fileUrl.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _viewDocument(fileUrl, docType),
                  child: const Text(
                    'View File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (c, e, s) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                          SizedBox(height: 8),
                          Text('PDF or secure file preview'),
                        ],
                      ),
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

  Widget _buildUploadNewDocButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.push('/document_upload');
          _fetchKycDocuments();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: const Color(0xFF0A1128),
        ),
        icon: const Icon(Icons.upload_file, color: Color(0xFF0A1128), size: 20),
        label: const Text(
          'Re-upload or Update Documents',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}
