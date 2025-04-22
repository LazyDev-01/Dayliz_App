import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/payment_method.dart';

class AddPaymentMethodDialog extends StatefulWidget {
  final Function(PaymentMethod) onAddPaymentMethod;

  const AddPaymentMethodDialog({
    Key? key, 
    required this.onAddPaymentMethod,
  }) : super(key: key);

  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'credit_card';
  
  // Credit card fields
  final _cardNumberController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cardTypeController = TextEditingController(text: 'visa');
  final _nickNameController = TextEditingController();
  
  // UPI field
  final _upiIdController = TextEditingController();
  
  bool _isDefault = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cardTypeController.dispose();
    _nickNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment Method'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentTypeSelector(),
              const SizedBox(height: 16),
              _buildPaymentMethodForm(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleAddPaymentMethod,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Payment Method Type',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'credit_card',
          child: Text('Credit/Debit Card'),
        ),
        DropdownMenuItem(
          value: 'upi',
          child: Text('UPI'),
        ),
        DropdownMenuItem(
          value: 'cod',
          child: Text('Cash on Delivery'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
    );
  }

  Widget _buildPaymentMethodForm() {
    switch (_selectedType) {
      case 'credit_card':
        return _buildCreditCardForm();
      case 'upi':
        return _buildUpiForm();
      case 'cod':
        return _buildCodForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCreditCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
            hintText: 'Last 4 digits only',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.length < 4) {
              return 'Please enter 4 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardHolderNameController,
          decoration: const InputDecoration(
            labelText: 'Card Holder Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card holder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _expiryDateController,
          decoration: const InputDecoration(
            labelText: 'Expiry Date (MM/YY)',
            border: OutlineInputBorder(),
            hintText: 'MM/YY',
          ),
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
            LengthLimitingTextInputFormatter(5),
            _ExpiryDateInputFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter expiry date';
            }
            if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
              return 'Invalid format, use MM/YY';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _cardTypeController.text,
          decoration: const InputDecoration(
            labelText: 'Card Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'visa',
              child: Text('Visa'),
            ),
            DropdownMenuItem(
              value: 'mastercard',
              child: Text('Mastercard'),
            ),
            DropdownMenuItem(
              value: 'amex',
              child: Text('American Express'),
            ),
            DropdownMenuItem(
              value: 'discover',
              child: Text('Discover'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              _cardTypeController.text = value;
            }
          },
        ),
        const SizedBox(height: 16),
        _buildNicknameAndDefaultFields(),
      ],
    );
  }

  Widget _buildUpiForm() {
    return Column(
      children: [
        TextFormField(
          controller: _upiIdController,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            border: OutlineInputBorder(),
            hintText: 'yourname@upi',
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter UPI ID';
            }
            if (!value.contains('@')) {
              return 'Invalid UPI ID format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildNicknameAndDefaultFields(),
      ],
    );
  }

  Widget _buildCodForm() {
    return _buildNicknameAndDefaultFields();
  }

  Widget _buildNicknameAndDefaultFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nickNameController,
          decoration: const InputDecoration(
            labelText: 'Nickname (Optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g. Personal Card',
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Set as default payment method'),
          value: _isDefault,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              _isDefault = value ?? false;
            });
          },
        ),
      ],
    );
  }

  void _handleAddPaymentMethod() {
    if (_formKey.currentState?.validate() ?? false) {
      // Create payment method based on type
      final paymentMethod = _createPaymentMethod();
      widget.onAddPaymentMethod(paymentMethod);
      Navigator.of(context).pop();
    }
  }

  PaymentMethod _createPaymentMethod() {
    switch (_selectedType) {
      case 'credit_card':
        return PaymentMethod(
          userId: 'temp-user-id', // This will be replaced by the actual user ID
          type: _selectedType,
          cardNumber: _cardNumberController.text,
          cardHolderName: _cardHolderNameController.text,
          expiryDate: _expiryDateController.text,
          cardType: _cardTypeController.text,
          isDefault: _isDefault,
          nickName: _nickNameController.text.isNotEmpty 
              ? _nickNameController.text 
              : null,
        );
      case 'upi':
        return PaymentMethod(
          userId: 'temp-user-id', // This will be replaced by the actual user ID
          type: _selectedType,
          upiId: _upiIdController.text,
          isDefault: _isDefault,
          nickName: _nickNameController.text.isNotEmpty 
              ? _nickNameController.text 
              : null,
        );
      case 'cod':
      default:
        return PaymentMethod(
          userId: 'temp-user-id', // This will be replaced by the actual user ID
          type: _selectedType,
          isDefault: _isDefault,
          nickName: _nickNameController.text.isNotEmpty 
              ? _nickNameController.text 
              : null,
        );
    }
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 3 == 0 && nonZeroIndex != text.length && nonZeroIndex != 2) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
} 