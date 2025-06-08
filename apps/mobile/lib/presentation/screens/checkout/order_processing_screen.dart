import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/order.dart' as domain;
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/payment_method.dart';
import '../../providers/order_providers.dart';
import '../order/order_summary_screen.dart';

/// Order processing screen with beautiful animations
/// Shows while the order is being processed in the backend
class OrderProcessingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const OrderProcessingScreen({
    Key? key,
    required this.orderData,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<OrderProcessingScreen> createState() => _OrderProcessingScreenState();
}

class _OrderProcessingScreenState extends ConsumerState<OrderProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  String _currentMessage = 'Processing your order...';
  bool _isProcessing = true;
  bool _isSuccess = false;
  bool _isError = false;
  String? _errorMessage;

  final List<String> _processingMessages = [
    'Processing your order...',
    'Verifying payment details...',
    'Confirming product availability...',
    'Preparing your order...',
    'Almost done...',
  ];

  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startOrderProcessing();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  void _startOrderProcessing() {
    // Cycle through processing messages
    _cycleMessages();

    // Simulate order processing
    Future.delayed(const Duration(seconds: 6), () {
      _processOrder();
    });
  }

  void _cycleMessages() {
    if (!_isProcessing) return;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _isProcessing) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _processingMessages.length;
          _currentMessage = _processingMessages[_messageIndex];
        });
        _cycleMessages();
      }
    });
  }

  Future<void> _processOrder() async {
    try {
      // TODO: Replace with actual order creation logic
      // For now, simulate processing
      await Future.delayed(const Duration(seconds: 1));

      // Simulate random success/failure for demo
      final isSuccess = DateTime.now().millisecond % 10 != 0; // 90% success rate

      if (isSuccess) {
        _showSuccess();
      } else {
        _showError('Payment failed. Please try again.');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showSuccess() {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _currentMessage = 'Order placed successfully!';
    });

    _pulseController.stop();

    // Navigate to order summary after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onSuccess?.call();
        // Navigate to order summary with generated order ID
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderSummaryScreen(
              orderId: orderId,
              orderData: widget.orderData,
            ),
          ),
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isError = true;
      _errorMessage = message;
      _currentMessage = 'Order failed';
    });

    _pulseController.stop();
    widget.onError?.call();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation during processing
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildAnimationSection(),
                  const SizedBox(height: 48),
                  _buildMessageSection(),
                  const Spacer(),
                  if (_isError) _buildErrorActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationSection() {
    if (_isSuccess) {
      return _buildSuccessAnimation();
    } else if (_isError) {
      return _buildErrorAnimation();
    } else {
      return _buildProcessingAnimation();
    }
  }

  Widget _buildProcessingAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.7),
                  Theme.of(context).primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildErrorAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      children: [
        Text(
          _currentMessage,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isError && _errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_isProcessing) ...[
          const SizedBox(height: 16),
          Text(
            'Please wait while we process your order',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_isSuccess) ...[
          const SizedBox(height: 16),
          Text(
            'Thank you for your order! You will receive a confirmation shortly.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorActions() {
    return Column(
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.go('/home');
          },
          child: const Text(
            'Back to Home',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
