import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/transction_status.dart';

class PaymentService {
  static const String baseUrl = 'http://localhost:3000';

  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Initiate a payment session
  Future<PaymentResponse> initiatePayment(PaymentRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/api/payment/initiate');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return PaymentResponse.fromJson(data);
      } else {
        return PaymentResponse(
          status: 'error',
          message: data['message'] ?? 'Failed to initiate payment',
          details: data['details'],
        );
      }
    } catch (e) {
      return PaymentResponse(
        status: 'error',
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Get transaction status
  Future<TransactionStatus> getTransactionStatus(String transactionId) async {
    try {
      final url = Uri.parse('$baseUrl/api/payment/status/$transactionId');

      final response = await http.get(url).timeout(timeoutDuration);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TransactionStatus.fromJson(data);
      } else {
        return TransactionStatus(
          status: 'error',
          message: data['message'] ?? 'Failed to get transaction status',
        );
      }
    } catch (e) {
      return TransactionStatus(
        status: 'error',
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Check backend health
  Future<bool> checkBackendHealth() async {
    try {
      final url = Uri.parse(baseUrl);
      final response = await http.get(url).timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
