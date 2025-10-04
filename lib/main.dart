import 'package:easy_pay_ssl/views/payment_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const EasyPaySSL());
}

class EasyPaySSL extends StatelessWidget {
  const EasyPaySSL({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Pay SSL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
      home: const PaymentFormScreen(),
    );
  }
}
