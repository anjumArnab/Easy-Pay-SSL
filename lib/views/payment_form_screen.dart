import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../models/payment_callback_data.dart';
import '../models/payment_request.dart';
import '../widgets/app_button.dart';
import '../widgets/input_field.dart';
import 'payment_webview_screen.dart';
import 'payment_result_screen.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();

  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productController = TextEditingController(text: 'Product');

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _productController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = PaymentRequest(
        amount: double.parse(_amountController.text),
        customerName: _nameController.text,
        customerEmail: _emailController.text,
        customerPhone: _phoneController.text,
        productName: _productController.text,
      );

      final response = await _paymentService.initiatePayment(request);

      if (!mounted) return;

      if (response.isSuccess && response.gatewayUrl != null) {
        if (kIsWeb) {
          // For Flutter Web
          _handleWebPayment(response.gatewayUrl!, response.transactionId!);
        } else {
          // For Mobile
          _handleMobilePayment(response.gatewayUrl!, response.transactionId!);
        }
      } else {
        _showErrorDialog(response.message ?? 'Failed to initiate payment');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWebPayment(
    String gatewayUrl,
    String transactionId,
  ) async {
    // Open in new tab
    final uri = Uri.parse(gatewayUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Show status check dialog
      if (mounted) {
        _showPaymentStatusDialog(transactionId);
      }
    } else {
      _showErrorDialog('Could not open payment gateway');
    }
  }

  Future<void> _handleMobilePayment(
    String gatewayUrl,
    String transactionId,
  ) async {
    final result = await Navigator.push<PaymentCallbackData>(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentWebViewScreen(
              gatewayUrl: gatewayUrl,
              transactionId: transactionId,
            ),
      ),
    );

    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(callbackData: result),
        ),
      );
    }
  }

  void _showPaymentStatusDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment in Progress'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Complete your payment in the opened tab.\n\nOnce done, click "Check Status" to verify your payment.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Transaction ID: $transactionId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _checkPaymentStatus(transactionId);
                },
                child: const Text('Check Status'),
              ),
            ],
          ),
    );
  }

  Future<void> _checkPaymentStatus(String transactionId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _paymentService.getTransactionStatus(transactionId);

      if (!mounted) return;

      if (status.transaction != null) {
        PaymentResult result;
        switch (status.transaction!.status) {
          case 'success':
            result = PaymentResult.success;
            break;
          case 'failed':
            result = PaymentResult.failed;
            break;
          case 'cancelled':
            result = PaymentResult.cancelled;
            break;
          default:
            result = PaymentResult.pending;
        }

        if (result != PaymentResult.pending) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PaymentResultScreen(
                    callbackData: PaymentCallbackData(
                      result: result,
                      transactionId: transactionId,
                      amount: status.transaction!.amount.toString(),
                    ),
                  ),
            ),
          );
        } else {
          _showErrorDialog('Payment is still pending. Please try again.');
        }
      } else {
        _showErrorDialog('Could not retrieve payment status');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Pay SSL'), elevation: 0),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      InputField(
                        controller: _amountController,
                        label: 'Amount (BDT)',
                        hintText: 'Enter amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      InputField(
                        controller: _productController,
                        label: 'Product Name',
                        hintText: 'Enter product name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      InputField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Enter your name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      InputField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      InputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter your phone number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      AppButton(
                        label: 'Proceed to Payment',
                        loadingLabel: 'Processing...',
                        onPressed: _initiatePayment,
                        isLoading: _isLoading,
                        backgroundColor: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Secure payment powered by SSLCOMMERZ',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
