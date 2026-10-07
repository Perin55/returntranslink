import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Terms & Privacy Policy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Return Translink Partner Agreement'),
              const SizedBox(height: 8),
              const Text(
                'Last updated: October 2026',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              
              _buildSectionTitle('1. Platform Usage & Verification'),
              _buildParagraph(
                'Return Translink is a digital transport marketplace connecting verified truck partners and drivers with cargo owners. By registering as a partner, you agree that all submitted vehicle information (RC, Fitness, Insurance, PUC) and personal identification documents (Aadhaar, Driving Licence) are authentic, valid, and legally accurate.',
              ),

              _buildSectionTitle('2. Zero Commission & Subscription'),
              _buildParagraph(
                'Return Translink does not deduct any hidden commissions from your freight settlements. Services are powered through transparent subscription plans. Subscribed partners have unlimited direct access to contact shippers and lock return loads.',
              ),

              _buildSectionTitle('3. Privacy & Personal Data Security'),
              _buildParagraph(
                'We respect your privacy. Your contact details and live vehicle availability are only made accessible to verified shippers with active booking interests. We never sell, rent, or distribute partner phone numbers, Aadhaar details, or financial documents to third-party advertising companies.',
              ),

              _buildSectionTitle('4. Compliance & Cargo Safety'),
              _buildParagraph(
                'Partners and drivers are responsible for safe cargo handling and adherence to national highway safety standards, RTO permits, and legal freight transport regulations.',
              ),

              _buildSectionTitle('5. Cancellation & Fair Use'),
              _buildParagraph(
                'Frequent unexcused cancellations or posting false truck availabilities may result in temporary or permanent profile suspension to protect shipper reliability.',
              ),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your documents and data are encrypted with bank-grade 256-bit security.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0A1128),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0A1128),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF4B5563),
        height: 1.6,
      ),
    );
  }
}
