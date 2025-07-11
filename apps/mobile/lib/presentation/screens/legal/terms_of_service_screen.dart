import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../widgets/common/unified_app_bar.dart';

/// Terms of Service Screen for Indian Users
/// 
/// This screen implements comprehensive terms of service specifically designed
/// for Indian jurisdiction and compliance with Indian laws including:
/// - Indian Contract Act 1872
/// - Consumer Protection Act 2019
/// - Information Technology Act 2000
/// - DPDP Act 2023
/// 
/// CRITICAL: This implementation must comply with Indian legal requirements
/// to ensure enforceability and user protection under Indian law.
class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400) {
      if (!_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      }
    } else {
      if (_showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UnifiedAppBars.withBackButton(
        title: 'Terms of Service',
        fallbackRoute: '/profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF374151)),
            onPressed: _shareTermsOfService,
            tooltip: 'Share Terms of Service',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildLastUpdated(),
                const SizedBox(height: 32),
                _buildTableOfContents(),
                const SizedBox(height: 32),
                _buildTermsContent(),
                const SizedBox(height: 32),
                _buildContactInformation(),
                const SizedBox(height: 100), // Extra space for FAB
              ],
            ),
          ),
          if (_showScrollToTop)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _scrollToTop,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent,
            AppColors.accentDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'These terms govern your use of Dayliz grocery delivery services in India. By using our app, you agree to these terms under Indian law.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🇮🇳 Indian Jurisdiction',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '⚖️ Legally Binding',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Last Updated: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'December 20, 2024',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Current',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfContents() {
    final sections = [
      'Acceptance of Terms',
      'Service Description',
      'User Accounts and Registration',
      'Order Placement and Delivery',
      'Payment Terms',
      'User Responsibilities',
      'Prohibited Activities',
      'Intellectual Property',
      'Limitation of Liability',
      'Dispute Resolution',
      'Governing Law',
      'Termination',
      'Changes to Terms',
      'Contact Information',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Table of Contents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...sections.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final section = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _scrollToSection(index),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          section,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          1,
          'Acceptance of Terms',
          _buildAcceptanceContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          2,
          'Service Description',
          _buildServiceDescriptionContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          3,
          'User Accounts and Registration',
          _buildUserAccountsContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          4,
          'Order Placement and Delivery',
          _buildOrderDeliveryContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          5,
          'Payment Terms',
          _buildPaymentTermsContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          6,
          'User Responsibilities',
          _buildUserResponsibilitiesContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          7,
          'Prohibited Activities',
          _buildProhibitedActivitiesContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          8,
          'Intellectual Property',
          _buildIntellectualPropertyContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          9,
          'Limitation of Liability',
          _buildLimitationLiabilityContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          10,
          'Dispute Resolution',
          _buildDisputeResolutionContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          11,
          'Governing Law',
          _buildGoverningLawContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          12,
          'Termination',
          _buildTerminationContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          13,
          'Changes to Terms',
          _buildChangesToTermsContent(),
        ),
      ],
    );
  }

  Widget _buildSection(int number, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildAcceptanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By accessing and using the Dayliz mobile application and services, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Legal Agreement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'These terms constitute a legally binding agreement between you and Dayliz under the Indian Contract Act, 1872. If you do not agree to these terms, please do not use our services.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildKeyPoint(
          'Age Requirement',
          'You must be at least 18 years old to use our services independently. Users under 18 require parental consent.',
          Icons.person,
          AppColors.warning,
        ),
        const SizedBox(height: 12),
        _buildKeyPoint(
          'Capacity to Contract',
          'You represent that you have the legal capacity to enter into this agreement under Indian law.',
          Icons.verified_user,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildKeyPoint(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDescriptionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dayliz provides on-demand grocery delivery services within designated zones in India. Our services include:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceFeature(
          'Grocery Delivery',
          'Fresh groceries, household items, and daily essentials delivered to your doorstep.',
          Icons.local_grocery_store,
          AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildServiceFeature(
          'Zone-Based Service',
          'Delivery services available only within our designated service zones.',
          Icons.location_on,
          AppColors.accent,
        ),
        const SizedBox(height: 12),
        _buildServiceFeature(
          'Real-Time Tracking',
          'Track your orders and delivery agents in real-time through our app.',
          Icons.track_changes,
          AppColors.info,
        ),
        const SizedBox(height: 12),
        _buildServiceFeature(
          'Customer Support',
          '24/7 customer support for order assistance and issue resolution.',
          Icons.support_agent,
          AppColors.success,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Service availability may vary based on location, weather conditions, and operational capacity. We reserve the right to modify or discontinue services with reasonable notice.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceFeature(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for remaining content sections
  Widget _buildUserAccountsContent() {
    return const Text(
      'You must create an account to use our services. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildOrderDeliveryContent() {
    return const Text(
      'Orders are subject to product availability and delivery zone coverage. Delivery times are estimates and may vary based on demand and external factors.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildPaymentTermsContent() {
    return const Text(
      'We accept various payment methods including Cash on Delivery, UPI, and other digital payment options. All payments are processed securely through our payment partners.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildUserResponsibilitiesContent() {
    return const Text(
      'You agree to use our services responsibly, provide accurate information, and comply with all applicable laws and regulations.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildProhibitedActivitiesContent() {
    return const Text(
      'You may not use our services for any unlawful purpose, to harm others, or to interfere with the proper functioning of our platform.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildIntellectualPropertyContent() {
    return const Text(
      'All content, trademarks, and intellectual property on our platform are owned by Dayliz or our licensors and are protected under Indian intellectual property laws.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildLimitationLiabilityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'To the maximum extent permitted by Indian law, Dayliz\'s liability is limited as follows:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Important Limitation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Our liability for any claim shall not exceed the amount paid by you for the specific order in question. We are not liable for indirect, incidental, or consequential damages.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisputeResolutionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Any disputes arising from these terms or our services shall be resolved through the following process:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildDisputeStep(
          '1. Direct Resolution',
          'Contact our customer support team first to resolve the issue amicably.',
          Icons.support_agent,
          AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildDisputeStep(
          '2. Mediation',
          'If direct resolution fails, disputes may be referred to mediation.',
          Icons.balance,
          AppColors.accent,
        ),
        const SizedBox(height: 12),
        _buildDisputeStep(
          '3. Arbitration',
          'Final disputes shall be resolved through arbitration under Indian Arbitration Act.',
          Icons.gavel,
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildDisputeStep(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoverningLawContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Indian Jurisdiction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'These Terms of Service are governed by and construed in accordance with the laws of India. Any legal proceedings shall be subject to the exclusive jurisdiction of the courts in [City], India.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This agreement is subject to:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Indian Contract Act, 1872\n• Consumer Protection Act, 2019\n• Information Technology Act, 2000\n• Digital Personal Data Protection Act, 2023',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminationContent() {
    return const Text(
      'Either party may terminate this agreement at any time. Upon termination, your right to use our services ceases immediately, but these terms remain in effect for past transactions.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildChangesToTermsContent() {
    return const Text(
      'We may update these terms from time to time. We will notify you of any material changes through the app or email. Continued use of our services constitutes acceptance of the updated terms.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildContactInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '14',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'For any questions about these terms of service, please contact us:',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            'Legal Department',
            'legal@dayliz.com',
            Icons.email,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            'Customer Support',
            'support@dayliz.com',
            Icons.support_agent,
            AppColors.accent,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            'Registered Address',
            'Dayliz App\n[Company Address]\nIndia',
            Icons.location_on,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String info, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(int sectionNumber) {
    // Calculate approximate scroll position based on section number
    final double targetPosition = sectionNumber * 400.0;
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _shareTermsOfService() {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Terms of Service sharing feature coming soon'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
