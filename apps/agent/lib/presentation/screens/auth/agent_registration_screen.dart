import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/providers/auth_provider.dart';

/// 🔷 3. APPLY TO JOIN (NEW AGENT)
/// 📄 Screen Title: "Apply to Join as Agent"
/// Single-page application form with all required fields
class AgentRegistrationScreen extends ConsumerStatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  ConsumerState<AgentRegistrationScreen> createState() => _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends ConsumerState<AgentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Dropdown values
  String _gender = 'Male';
  String _drivingLicense = 'Yes';
  String _govtId = 'Yes';
  String _vehicle = 'Bike';

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 25550)), // 70 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = "${_firstNameController.text.trim()} ${_middleNameController.text.trim().isNotEmpty ? '${_middleNameController.text.trim()} ' : ''}${_lastNameController.text.trim()}";
      
      final message = await ref.read(authProvider.notifier).submitApplication(
        fullName: fullName,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        workType: 'full-time', // Default work type
        age: _calculateAge(_dobController.text),
        gender: _gender.toLowerCase(),
        address: _addressController.text.trim(),
        vehicleType: _vehicle.toLowerCase(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog(message ?? 'Application submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _calculateAge(String dobString) {
    try {
      final parts = dobString.split('/');
      final dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 18; // Default age
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 12),
            Text('Application Submitted!'),
          ],
        ),
        content: Text(
          'Thank you for applying to join the Dayliz delivery team! We have received your application and our team will review it carefully.\n\nYou will receive an email confirmation at ${_emailController.text.trim()} and we will contact you within 24-48 hours regarding the next steps.\n\nPlease check your email regularly, including your spam folder, for updates from hello@dayliz.in.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          DaylizButton(
            text: 'Got it!',
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            backgroundColor: const Color(0xFF2E7D32),
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Apply to Join as Agent',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please fill in all the required information to apply as a delivery agent.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Name Fields
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DaylizTextField(
                      controller: _firstNameController,
                      labelText: 'First Name *',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DaylizTextField(
                      controller: _middleNameController,
                      labelText: 'Middle Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DaylizTextField(
                controller: _lastNameController,
                labelText: 'Last Name *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              DaylizTextField(
                controller: _dobController,
                labelText: 'Date of Birth *',
                readOnly: true,
                onTap: _selectDate,
                suffixIcon: Icons.calendar_today,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Date of birth is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              DaylizTextField(
                controller: _addressController,
                labelText: 'Address *',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _gender = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              DaylizTextField(
                controller: _emailController,
                labelText: 'Email Address *',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DaylizTextField(
                controller: _phoneController,
                labelText: 'Phone Number *',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Additional Questions
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Driving License
              DropdownButtonFormField<String>(
                value: _drivingLicense,
                decoration: const InputDecoration(
                  labelText: 'Do you have a valid driving license? *',
                  border: OutlineInputBorder(),
                ),
                items: ['Yes', 'No'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _drivingLicense = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Government ID
              DropdownButtonFormField<String>(
                value: _govtId,
                decoration: const InputDecoration(
                  labelText: 'Do you have government ID (PAN or Aadhaar)? *',
                  border: OutlineInputBorder(),
                ),
                items: ['Yes', 'No'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _govtId = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Vehicle
              DropdownButtonFormField<String>(
                value: _vehicle,
                decoration: const InputDecoration(
                  labelText: 'What vehicle do you have? *',
                  border: OutlineInputBorder(),
                ),
                items: ['Bike', 'Scooty', 'None'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _vehicle = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              DaylizButton(
                text: 'Submit Application',
                onPressed: _isLoading ? null : _submitApplication,
                backgroundColor: const Color(0xFF2E7D32),
                textColor: Colors.white,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
