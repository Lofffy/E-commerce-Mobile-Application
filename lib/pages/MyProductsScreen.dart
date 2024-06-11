import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

  

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('vendor_id', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data?.docs;

          return ListView.builder(
            itemCount: products?.length ?? 0,
            itemBuilder: (context, index) {
              final product = products?[index];

              return ListTile(
                title: Text(product?['product_name'] ?? ''),
                subtitle: Text('\$${product?['product_price']}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    
                    // Navigate to screen to apply discount
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ApplyDiscountScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ApplyDiscountScreen extends StatefulWidget {
  final QueryDocumentSnapshot? product;

  const ApplyDiscountScreen({Key? key, this.product}) : super(key: key);

  @override
  _ApplyDiscountScreenState createState() => _ApplyDiscountScreenState();
}

class _ApplyDiscountScreenState extends State<ApplyDiscountScreen> {
  TextEditingController _percentageController = TextEditingController();
  double _discountedPrice = 0.0;

  @override
  Widget build(BuildContext context) {
      triggerNotification() {
      AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: 10,
              channelKey: "basic_channel",
              body: "Disscount Added On a Product"));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Discount'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Product: ${widget.product?['product_name']}'),
            SizedBox(height: 20),
            TextField(
              controller: _percentageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount Percentage (%)',
                hintText: 'Enter percentage',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed:
               () async {
                triggerNotification();
                // Validate input
                double percentage =
                    double.tryParse(_percentageController.text) ?? 0.0;
                if (percentage > 0 && percentage <= 100) {
                  // Calculate discounted price
                  double originalPrice =
                      widget.product?['product_price'] ?? 0.0;
                  double discountAmount = originalPrice * (percentage / 100);
                  double discountedPrice = originalPrice - discountAmount;

                  try {
                    // Update Firestore document with discounted price
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.product?.id)
                        .update({'product_price': discountedPrice});

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Discount applied successfully')),
                    );

                    // Send email notification to shoppers
                    _sendEmailToShoppers(
                        percentage, widget.product?['product_name'] ?? '');
                  } catch (e) {
                    // Show error message if update fails
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Error'),
                          content: Text('Failed to apply discount: $e'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                } else {
                  // Show error message for invalid input
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Invalid Percentage'),
                        content: Text(
                            'Please enter a valid percentage between 0 and 100.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Apply Discount'),
            ),
            SizedBox(height: 20),
            if (_discountedPrice > 0)
              Text(
                  'Discounted Price: \$${_discountedPrice.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmailToShoppers(
      double discountPercentage, String productName) async {
    try {
      // Get all users with role "shopper"
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Shopper')
          .get();

      // Extract their email addresses
      final List<String> emailAddresses =
          snapshot.docs.map((doc) => doc['email'] as String).toList();
      // Send email to each shopper
      for (var email in emailAddresses) {
        final message = Message()
          ..from = Address('infohelpdesk00@gmail.com', 'Shop')
          ..recipients.add(email)
          ..subject = 'Discount Notification'
          ..html =
              '<h1>Discount Notification</h1>\n<p>Dear Shopper,</p>\n<p>We are pleased to inform you that a ${discountPercentage}% discount has been applied to the product "$productName". Take advantage of this limited-time offer!</p>';

        final server = SmtpServer('smtp.gmail.com',
            username: 'infohelpdesk00@gmail.com',
            password: "bgll bqug dzfz plbc");
        print(message.html.toString());

        await send(message, server);
      }

      print('Email sent successfully to shoppers.');
    } catch (e) {
      print('Failed to send email: $e');
    }
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }
}
