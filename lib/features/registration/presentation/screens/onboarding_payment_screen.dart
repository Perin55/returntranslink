import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/primary_button.dart';

class OnboardingPaymentScreen extends StatelessWidget {
  const OnboardingPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Activate Your Account',
          style: TextStyle(color: Color(0xFF0A1128), fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'One-Time Verification Fee',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'To maintain a high-quality network of genuine truck owners, we charge a small one-time verification fee.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFC107), width: 2),
                          color: const Color(0xFFFFFBEB),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.verified_user, color: Color(0xFFD97706), size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Lifetime Access',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1128)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '₹99',
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Only once. No hidden charges.',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Benefits
                      _buildBenefitRow(Icons.check_circle, 'Direct contact with customers'),
                      _buildBenefitRow(Icons.check_circle, 'Publish unlimited return routes'),
                      _buildBenefitRow(Icons.check_circle, 'Priority support'),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Buttons (Fixed at bottom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      text: 'Pay ₹99 & Continue',
                      onPressed: () async {
                        try {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            final profile = await Supabase.instance.client.from('profiles').select('id').eq('auth_user_id', user.id).maybeSingle();
                            if (profile != null) {
                              await Supabase.instance.client.from('partners').update({'status': 'ACTIVE'}).eq('profile_id', profile['id']);
                            }
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment Successful! Welcome to Return Translink.')),
                            );
                            context.go('/dashboard');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          try {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                              final profile = await Supabase.instance.client.from('profiles').select('id').eq('auth_user_id', user.id).maybeSingle();
                              if (profile != null) {
                                await Supabase.instance.client.from('partners').update({'status': 'ACTIVE'}).eq('profile_id', profile['id']);
                              }
                            }
                            if (context.mounted) context.go('/dashboard');
                          } catch (e) {
                            if (context.mounted) context.go('/dashboard');
                          }
                        },
                        child: const Text(
                          'I\'ll pay later',
                          style: TextStyle(color: Color(0xFF6B7280), decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}
