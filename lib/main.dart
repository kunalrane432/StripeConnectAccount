import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:stripe_payment/stripe_payment.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();

    StripePayment.setOptions(
      StripeOptions(
        publishableKey:
            "pk_test_51PdfANJkWv19XhlOifMiA95lYznRNnMiFpyRdaoD955zxCINzvAMN9JUb5CYCx7KVpjZ23D2GQ4qAI7SWQx3Slyk00crdiJZOC",
        merchantId: "Test",
        androidPayMode: 'test',
      ),
    );
  }

  Future<void> _createPaymentIntent() async {
    final url =
        'http://localhost:3000/create-payment-intent'; // Replace with your server URL
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': 1000, // Amount in cents
        'currency': 'usd',
        'payment_method_types': ['card'],
        'destination':
            'acct_1Pf934QulZjnaiA7',
      }),
    );

    final paymentIntentData = jsonDecode(response.body);
    _confirmPayment(paymentIntentData['clientSecret']);
  }

  Future<void> _confirmPayment(String clientSecret) async {
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
        CardFormPaymentRequest(),
      );

      final paymentIntent = await StripePayment.confirmPaymentIntent(
        PaymentIntent(
          clientSecret: clientSecret,
          paymentMethodId: paymentMethod.id,
        ),
      );

      if (paymentIntent.status == 'succeeded') {
        // Payment was successful
        print('Payment succeeded');
        _showSuccessDialog();
      } else {
        // Payment failed
        print('Payment failed');
        _showErrorDialog(paymentIntent.status ?? 'payment failed');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Successful"),
          content: Text("Your payment was successful."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Failed"),
          content: Text("There was an error with your payment: $errorMessage"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stripe Payment'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _createPaymentIntent,
          child: Text('Pay with Stripe'),
        ),
      ),
    );
  }
}
