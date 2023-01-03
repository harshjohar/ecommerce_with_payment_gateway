import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  Stripe.publishableKey = dotenv.env['PUBLISHABLE_KEY']!;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo ecommerce',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Demo ecommerce'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic>? paymentIntent;

  String calculateAmount(String amount) {
    final calculatedAmount = (int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }

  Future<Map<String, dynamic>?> createPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
        'description': 'hmm ok?',
        'shipping': json.encode({
          'name': 'Jenny Rosen',
          'address': {
            'line1': '510 Townsend St',
            'postal_code': '98140',
            'city': 'San Francisco',
            'state': 'CA',
            'country': 'US',
          },
        }),
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          // 'Authorization': 'Bearer ${dotenv.env["SECRET_KEY"]}',
          'Authorization':
              'Bearer sk_test_51MMEjSSEISaujeeayLSZS8A9xfWCaHQ1NnamUDmbWZ1rTKEl09RKwfWL6zRDwOPEDjh8s2prZZl4yfSdTywEEHoR00WxlUNjlF',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      // ignore: avoid_print
      print('Payment Intent Body->>> ${response.body.toString()}');
      return Map<String, dynamic>.from(json.decode(response.body));
    } catch (err) {
      // ignore: avoid_print
      print('err charging user: ${err.toString()}');
    }
    return null;
  }

  void displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          Text("Payment Successful"),
                        ],
                      ),
                    ],
                  ),
                ));
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("paid successfully")));

        paymentIntent = null;
      }).onError((error, stackTrace) {
        print('Error is:--->$error $stackTrace');
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      showDialog(
          context: context,
          builder: (_) => const AlertDialog(
                content: Text("Cancelled "),
              ));
    } catch (e) {
      print(e);
    }
  }

  Future<void> makePayment() async {
    try {
      paymentIntent = await createPaymentIntent('10', 'INR');
      //Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentIntent!['client_secret'],
                // applePay: const PaymentSheetApplePay(merchantCountryCode: '+92',),
                // googlePay: const PaymentSheetGooglePay(testEnv: true, currencyCode: "US", merchantCountryCode: "+92"),
                style: ThemeMode.light,
                merchantDisplayName: 'Harsh'),
          )
          .then((value) {});

      ///now finally display payment sheet
      displayPaymentSheet();
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) {
                      return const OrdersPage();
                    },
                  ),
                );
              },
              child: const Text("My orders"),
            ),
            CupertinoButton.filled(
              child: const Text("Make Payment"),
              onPressed: () async {
                await makePayment();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My orders",
        ),
      ),
      body: Container(),
    );
  }
}
