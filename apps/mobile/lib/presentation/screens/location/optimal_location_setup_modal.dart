import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'optimal_location_setup_content.dart';

/// Half-page modal wrapper for the optimal location setup
/// Preserves all the architectural benefits while providing better UX
class OptimalLocationSetupModal extends ConsumerStatefulWidget {
  final VoidCallback onLocationSetupComplete;
  final String? initialError;

  const OptimalLocationSetupModal({
    Key? key,
    required this.onLocationSetupComplete,
    this.initialError,
  }) : super(key: key);

  @override
  ConsumerState<OptimalLocationSetupModal> createState() => _OptimalLocationSetupModalState();
}

class _OptimalLocationSetupModalState extends ConsumerState<OptimalLocationSetupModal>
    with TickerProviderStateMixin {

  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start slide-up animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: screenHeight,
          child: Stack(
            children: [
              // Background overlay
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5 * _slideAnimation.value),
                ),
              ),

              // Modal content
              Positioned(
                bottom: -screenHeight * (1 - _slideAnimation.value),
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.75, // 75% of screen height
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: OptimalLocationSetupContent(
                    isModal: true,
                    initialError: widget.initialError,
                    onLocationSetupComplete: widget.onLocationSetupComplete,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


}
