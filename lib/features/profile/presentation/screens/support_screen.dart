import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final Uri url = Uri.parse('https://wa.me/$phone?text=Hello%20Return%20Translink%20Support');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
          '24x7 Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top support card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1128), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'We are here for you 24/7',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Need help with return loads, truck verification, or payments? Contact our dedicated partner support anytime.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Direct Contact',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
              ),
              const SizedBox(height: 12),

              _buildContactTile(
                icon: Icons.phone_in_talk,
                iconColor: const Color(0xFF2563EB),
                title: 'Call Support Helpline',
                subtitle: '+91 81550 69901',
                badgeText: 'Toll-Free',
                onTap: () => _makePhoneCall('+918155069901'),
              ),

              const SizedBox(height: 12),

              _buildContactTile(
                icon: Icons.chat,
                iconColor: const Color(0xFF16A34A),
                title: 'Chat on WhatsApp',
                subtitle: 'Instant response on WhatsApp chat',
                badgeText: 'Fastest',
                onTap: () => _openWhatsApp('918155069901'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
              ),
              const SizedBox(height: 12),

              _buildFaqItem('How do I post a return trip?',
                  'Go to the Home dashboard and tap "Add Return Requirement" or "Post New Trip". Enter your starting and return destination cities and choose your date.'),
              _buildFaqItem('How does truck verification work?',
                  'Once you upload your vehicle RC and driving licence under KYC & Documents, our team reviews the submission within 24 to 48 hours.'),
              _buildFaqItem('Are there any hidden booking fees?',
                  'No! Return Translink charges zero commission on loads. Shippers contact you directly to negotiate and finalize trip rates.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0A1128)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.5),
          ),
        ],
      ),
    );
  }
}
