import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

/// 🔷 1. AUTH LANDING SCREEN
/// Purpose: Entry point for both existing agents and new applicants.
/// 
/// UI Elements:
/// 🖼 Logo + Welcome Message: "Welcome to Dayliz Delivery Agent Portal"
/// 👇 Two buttons:
/// 🔐 Login as Existing Agent
/// ✍️ Apply to Join as Agent
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              
              // 🖼 Logo Section
              Center(
                child: Column(
                  children: [
                    // Dayliz Logo (placeholder for now)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32), // Dayliz green
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Welcome Message
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dayliz Delivery Agent Portal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join our delivery team and start earning today',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 3),
              
              // 👇 Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔐 Login as Existing Agent Button
                  DaylizButton(
                    text: 'Login as Existing Agent',
                    onPressed: () => context.go('/login'),
                    backgroundColor: const Color(0xFF2E7D32), // Dayliz green
                    textColor: Colors.white,
                    icon: Icons.login,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✍️ Apply to Join as Agent Button (Disabled)
                  DaylizButton(
                    text: 'Apply to Join as Agent',
                    onPressed: null, // Disabled functionality
                    backgroundColor: Colors.grey.shade300,
                    textColor: Colors.grey.shade600,
                    borderColor: Colors.grey.shade400,
                    icon: Icons.person_add,
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
              
              // Footer text
              const Center(
                child: Text(
                  'Powered by Dayliz',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
