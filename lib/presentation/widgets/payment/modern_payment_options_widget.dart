import 'package:flutter/material.dart';

/// Modern payment options widget that matches the design specification
class ModernPaymentOptionsWidget extends StatefulWidget {
  final String? selectedPaymentMethod;
  final Function(String) onPaymentMethodSelected;

  const ModernPaymentOptionsWidget({
    Key? key,
    this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
  }) : super(key: key);

  @override
  State<ModernPaymentOptionsWidget> createState() => _ModernPaymentOptionsWidgetState();
}

class _ModernPaymentOptionsWidgetState extends State<ModernPaymentOptionsWidget> {
  String? selectedMethod;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Options',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // PAY BY UPI Section
            _buildSectionHeader('PAY BY UPI'),
            _buildPaymentOption(
              'phonepe',
              'PhonePe',
              'assets/icons/phonepe.png',
              const Color(0xFF5F259F),
            ),
            _buildPaymentOption(
              'googlepay',
              'GooglePay',
              'assets/icons/googlepay.png',
              const Color(0xFF4285F4),
            ),
            _buildPaymentOption(
              'paytm',
              'Paytm',
              'assets/icons/paytm.png',
              const Color(0xFF00BAF2),
            ),

            const SizedBox(height: 30),

            // Wallets Section
            _buildSectionHeader('Wallets'),
            _buildPaymentOption(
              'amazonpay',
              'AmazonPay',
              'assets/icons/amazonpay.png',
              const Color(0xFFFF9900),
            ),
            _buildPaymentOption(
              'mobikwik',
              'Mobikwik',
              null,
              const Color(0xFF2196F3),
              icon: Icons.wallet,
            ),

            const SizedBox(height: 30),

            // Pay on Delivery Section
            _buildSectionHeader('Pay on Delivery'),
            _buildPaymentOption(
              'cod',
              'Cash on Delivery',
              null,
              Colors.green,
              icon: Icons.money,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String id,
    String name,
    String? assetPath,
    Color color, {
    IconData? icon,
  }) {
    final isSelected = selectedMethod == id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedMethod = id;
          });
          widget.onPaymentMethodSelected(id);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Payment method icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: icon != null
                    ? Icon(icon, color: color, size: 18)
                    : assetPath != null
                        ? Image.asset(
                            assetPath,
                            width: 18,
                            height: 18,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ Failed to load payment icon: $assetPath');
                              debugPrint('Error: $error');
                              return Icon(Icons.payment, color: color, size: 18);
                            },
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (frame != null) {
                                debugPrint('✅ Successfully loaded payment icon: $assetPath');
                              }
                              return child;
                            },
                          )
                        : Icon(Icons.payment, color: color, size: 18),
              ),

              const SizedBox(width: 16),

              // Payment method name
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
