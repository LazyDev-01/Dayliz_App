import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../widgets/common/unified_app_bar.dart';

/// DPDP Act 2023 Compliant Privacy Policy Screen for Indian Users
/// 
/// This screen implements the Digital Personal Data Protection Act 2023 requirements
/// for Indian users of the Dayliz App. It provides comprehensive privacy information
/// and data protection rights as mandated by Indian law.
/// 
/// CRITICAL: This implementation must comply with DPDP Act 2023 to avoid
/// legal penalties up to ₹250 crores. Any modifications must be reviewed
/// by legal counsel.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
        title: 'Privacy Policy',
        fallbackRoute: '/profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF374151)),
            onPressed: _sharePrivacyPolicy,
            tooltip: 'Share Privacy Policy',
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
                _buildPrivacyContent(),
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
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
                  Icons.privacy_tip,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Privacy Policy',
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
            'Your privacy is our priority. This policy explains how Dayliz collects, uses, and protects your personal data in compliance with the Digital Personal Data Protection Act 2023.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🇮🇳 DPDP Act 2023 Compliant',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            color: AppColors.primary,
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
      'Information We Collect',
      'How We Use Your Information',
      'Data Sharing and Disclosure',
      'Your Rights Under DPDP Act 2023',
      'Data Security and Storage',
      'Cookies and Tracking',
      'Children\'s Privacy',
      'Data Retention',
      'International Transfers',
      'Changes to This Policy',
      'Grievance Redressal',
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          1,
          'Information We Collect',
          _buildInformationWeCollectContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          2,
          'How We Use Your Information',
          _buildHowWeUseContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          3,
          'Data Sharing and Disclosure',
          _buildDataSharingContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          4,
          'Your Rights Under DPDP Act 2023',
          _buildDPDPRightsContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          5,
          'Data Security and Storage',
          _buildDataSecurityContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          6,
          'Cookies and Tracking',
          _buildCookiesContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          7,
          'Children\'s Privacy',
          _buildChildrenPrivacyContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          8,
          'Data Retention',
          _buildDataRetentionContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          9,
          'International Transfers',
          _buildInternationalTransfersContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          10,
          'Changes to This Policy',
          _buildChangesToPolicyContent(),
        ),
        const SizedBox(height: 24),
        _buildSection(
          11,
          'Grievance Redressal',
          _buildGrievanceRedressalContent(),
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
                  color: AppColors.primary,
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

  Widget _buildInformationWeCollectContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'We collect the following types of personal data to provide our grocery delivery services:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildDataTypeCard(
          'Account Information',
          [
            'Full name and contact details',
            'Email address and phone number',
            'Date of birth (for age verification)',
            'Profile picture (optional)',
          ],
          Icons.person,
          AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildDataTypeCard(
          'Location Data',
          [
            'Delivery addresses',
            'GPS location for delivery optimization',
            'Zone-based service area information',
          ],
          Icons.location_on,
          AppColors.accent,
        ),
        const SizedBox(height: 12),
        _buildDataTypeCard(
          'Transaction Information',
          [
            'Order history and preferences',
            'Payment method details (encrypted)',
            'Purchase patterns and cart data',
          ],
          Icons.shopping_cart,
          AppColors.success,
        ),
        const SizedBox(height: 12),
        _buildDataTypeCard(
          'Device Information',
          [
            'Device type and operating system',
            'App usage analytics',
            'Crash reports and performance data',
          ],
          Icons.phone_android,
          AppColors.info,
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
                  'We only collect data that is necessary for providing our services and with your explicit consent.',
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

  Widget _buildDataTypeCard(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildHowWeUseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'We use your personal data for the following purposes, as permitted under the DPDP Act 2023:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildUsePurposeCard(
          'Service Delivery',
          'To process orders, coordinate deliveries, and provide customer support.',
          Icons.delivery_dining,
          AppColors.primary,
          true,
        ),
        const SizedBox(height: 12),
        _buildUsePurposeCard(
          'Account Management',
          'To create and maintain your account, authenticate access, and manage preferences.',
          Icons.account_circle,
          AppColors.accent,
          true,
        ),
        const SizedBox(height: 12),
        _buildUsePurposeCard(
          'Payment Processing',
          'To process payments securely and maintain transaction records.',
          Icons.payment,
          AppColors.success,
          true,
        ),
        const SizedBox(height: 12),
        _buildUsePurposeCard(
          'Service Improvement',
          'To analyze usage patterns and improve our app and services.',
          Icons.analytics,
          AppColors.info,
          false,
        ),
        const SizedBox(height: 12),
        _buildUsePurposeCard(
          'Marketing Communications',
          'To send promotional offers and updates (with your consent).',
          Icons.campaign,
          AppColors.warning,
          false,
        ),
      ],
    );
  }

  Widget _buildUsePurposeCard(String title, String description, IconData icon, Color color, bool isEssential) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEssential ? AppColors.success.withOpacity(0.1) : AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isEssential ? 'Essential' : 'Optional',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEssential ? AppColors.success : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildDataSharingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'We may share your personal data only in the following circumstances, as permitted under Indian law:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildSharingScenario(
          'Service Providers',
          'Delivery partners, payment processors, and technology service providers who help us operate our services.',
          Icons.handshake,
          AppColors.primary,
          'With your consent',
        ),
        const SizedBox(height: 12),
        _buildSharingScenario(
          'Legal Compliance',
          'Government authorities when required by law, court orders, or regulatory requirements.',
          Icons.gavel,
          AppColors.warning,
          'Legal obligation',
        ),
        const SizedBox(height: 12),
        _buildSharingScenario(
          'Business Transfers',
          'In case of merger, acquisition, or sale of business assets (with prior notice).',
          Icons.business,
          AppColors.info,
          'Legitimate interest',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.security,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'We never sell your personal data to third parties for marketing purposes.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSharingScenario(String title, String description, IconData icon, Color color, String legalBasis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  legalBasis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildDPDPRightsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primaryLight.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Under the Digital Personal Data Protection Act 2023, you have the following rights:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildRightCard(
          'Right to Access',
          'Request information about what personal data we have about you and how it\'s being used.',
          Icons.visibility,
          AppColors.primary,
          'Free of charge',
        ),
        const SizedBox(height: 12),
        _buildRightCard(
          'Right to Correction',
          'Request correction of inaccurate or incomplete personal data.',
          Icons.edit,
          AppColors.accent,
          'Within 30 days',
        ),
        const SizedBox(height: 12),
        _buildRightCard(
          'Right to Erasure',
          'Request deletion of your personal data when no longer necessary.',
          Icons.delete_forever,
          AppColors.error,
          'Subject to legal requirements',
        ),
        const SizedBox(height: 12),
        _buildRightCard(
          'Right to Data Portability',
          'Request your data in a structured, machine-readable format.',
          Icons.download,
          AppColors.success,
          'Common formats provided',
        ),
        const SizedBox(height: 12),
        _buildRightCard(
          'Right to Grievance Redressal',
          'File complaints about data processing with our Grievance Officer.',
          Icons.support_agent,
          AppColors.info,
          'Response within 30 days',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_support,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'How to Exercise Your Rights',
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
                'To exercise any of these rights, contact our Grievance Officer at privacy@dayliz.com or use the contact information provided at the end of this policy.',
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

  Widget _buildRightCard(String title, String description, IconData icon, Color color, String timeframe) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeframe,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  // Placeholder methods for remaining content sections
  Widget _buildDataSecurityContent() {
    return const Text(
      'We implement industry-standard security measures to protect your personal data, including encryption, secure servers, and regular security audits.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildCookiesContent() {
    return const Text(
      'We use cookies and similar technologies to enhance your experience, analyze usage patterns, and provide personalized content.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildChildrenPrivacyContent() {
    return const Text(
      'Our services are not intended for children under 18. We do not knowingly collect personal data from children without parental consent.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildDataRetentionContent() {
    return const Text(
      'We retain your personal data only as long as necessary for the purposes outlined in this policy or as required by law.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildInternationalTransfersContent() {
    return const Text(
      'Your data is primarily stored and processed in India. Any international transfers comply with DPDP Act 2023 requirements.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildChangesToPolicyContent() {
    return const Text(
      'We may update this privacy policy from time to time. We will notify you of any material changes through the app or email.',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildGrievanceRedressalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'As required by the DPDP Act 2023, we have appointed a Grievance Officer to address your privacy concerns:',
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
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grievance Officer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Name: [To be appointed]',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Email: privacy@dayliz.com',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Response Time: Within 30 days',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '12',
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
            'For any questions about this privacy policy or your personal data, please contact us:',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            'Email',
            'privacy@dayliz.com',
            Icons.email,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            'Address',
            'Dayliz App\n[Company Address]\nIndia',
            Icons.location_on,
            AppColors.accent,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            'Data Protection Officer',
            'dpo@dayliz.com',
            Icons.security,
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

  void _sharePrivacyPolicy() {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Privacy Policy sharing feature coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
