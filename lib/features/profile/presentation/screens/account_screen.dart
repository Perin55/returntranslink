import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/helpers/onboarding_helper.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- 1. PROFILE HEADER ---
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client.auth.currentUser != null
                          ? Supabase.instance.client.from('profiles').select('*, partners(*)').eq('auth_user_id', Supabase.instance.client.auth.currentUser!.id)
                          : Future.value([]),
                      builder: (context, snapshot) {
                        String name = 'Loading...';
                        String mobileNumber = '';
                        String? profilePicUrl;
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          name = 'Loading...';
                        } else if (Supabase.instance.client.auth.currentUser == null) {
                          name = 'Demo Driver';
                          mobileNumber = '+91 98765 43210';
                        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final profile = snapshot.data!.first;
                          final rawPartners = profile['partners'];
                          Map<String, dynamic> partner = {};
                          if (rawPartners is List && rawPartners.isNotEmpty) {
                            partner = rawPartners[0] as Map<String, dynamic>;
                          } else if (rawPartners is Map) {
                            partner = Map<String, dynamic>.from(rawPartners);
                          }
                          
                          name = profile['full_name'] ?? partner['owner_name'] ?? 'Partner';
                          
                          final phone = profile['mobile_number'] ?? partner['mobile_number'] ?? Supabase.instance.client.auth.currentUser?.phone ?? '';
                          mobileNumber = (phone != '') ? phone : '';
                          
                          profilePicUrl = profile['profile_photo_url'] ?? partner['profile_photo_url'];
                        } else {
                          name = 'Partner';
                        }
                        
                        return Row(
                          children: [
                            // Profile Image
                            Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 2),
                                    image: profilePicUrl != null && profilePicUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(profilePicUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (profilePicUrl == null || profilePicUrl.isEmpty) 
                                      ? const Icon(Icons.person, size: 40, color: AppColors.primaryDark) 
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, size: 12, color: AppColors.textPrimary),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Name & Rating
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mobileNumber,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.star, color: Colors.green, size: 14),
                                        SizedBox(width: 4),
                                        Text('4.8 Rating', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // --- 2. ACCOUNT & KYC ---
                  _buildSectionHeader('Account & Verification'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem(context, Icons.person_outline, 'Edit Profile', subtitle: 'Name, Phone, Address'),
                        _buildMenuItem(context, Icons.verified_user_outlined, 'KYC & Documents', subtitle: 'Aadhaar, PAN, DL', status: 'Verified', statusColor: Colors.green, showDivider: false),
                        // _buildMenuItem(context, Icons.account_balance_outlined, 'Bank & UPI Details', subtitle: 'For freight settlements', showDivider: false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 3. PAYMENTS & PLAN ---
                  _buildSectionHeader('Payments & App'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem(context, Icons.credit_card_outlined, 'Subscription Plan', subtitle: 'Active: Premium User'),
                        _buildMenuItem(context, Icons.language_outlined, 'App Language', subtitle: 'English', showDivider: false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 4. SUPPORT & HELP ---
                  _buildSectionHeader('Help & Legal'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          context, 
                          Icons.support_agent_outlined, 
                          '24x7 Help & Support', 
                          subtitle: 'Call or WhatsApp us',
                          iconColor: AppColors.primaryDark,
                        ),
                        _buildMenuItem(context, Icons.info_outline, 'Terms & Privacy Policy', showDivider: false),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // --- 5. LOGOUT BUTTON ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          OnboardingHelper.resetCache();
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2), // Light red bg
                          foregroundColor: const Color(0xFFEF4444), // Red text/icon
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFCA5A5)), // Red border
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Secure Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, 
    IconData icon, 
    String title, 
    {
      String? subtitle, 
      bool showDivider = true, 
      String? status,
      Color? statusColor,
      Color? iconColor,
    }
  ) {
    return InkWell(
      onTap: () {
        if (title == 'Edit Profile') {
          context.push('/edit_profile');
        } else if (title == 'KYC & Documents') {
          context.push('/kyc_documents');
        } else if (title == 'Subscription Plan') {
          context.push('/subscription_plan');
        } else if (title == 'Terms & Privacy Policy') {
          context.push('/terms_privacy');
        } else if (title == '24x7 Help & Support') {
          context.push('/support');
        } else if (title == 'App Language') {
          context.push('/language');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title is coming soon!')),
          );
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.textSecondary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                if (status != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColor ?? Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor ?? Colors.grey,
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
          if (showDivider)
            const Divider(height: 1, indent: 72, endIndent: 24, color: Color(0xFFF3F4F6)),
        ],
      ),
    );
  }
}
