import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ecommerce_app/pages/MyProductsScreen.dart';
import 'package:ecommerce_app/pages/ProfilePageShopper.dart';
import 'package:ecommerce_app/providers/authProvider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/providers/aws_config.dart';
import 'package:provider/provider.dart';
import 'loginSignupScreen.dart'; // Import the LoginScreen for redirection
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';

class VendorScreen extends StatelessWidget {
  const VendorScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vendor Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Vendorscreen(),
    );
  }
}

class Vendorscreen extends StatelessWidget {
  const Vendorscreen({Key? key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/img/test.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                accountEmail: Text(authProvider.email),
                accountName: Text(authProvider.userName),
              ),
              ListTile(
                title: Text("My products"),
                leading: Icon(Icons.add_shopping_cart),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyProductsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text("Profile"),
                leading: Icon(Icons.person),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text("About"),
                leading: Icon(Icons.help_center),
                onTap: () {},
              ),
              ListTile(
                title: Text("Logout"),
                leading: Icon(Icons.exit_to_app),
                onTap: () {
                  authProvider.logout();
                },
              ),
            ]),
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Text(
                "Developed by George And Omar ",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AddProductForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProductForm extends StatefulWidget {
  @override
  _AddProductFormState createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  String _selectedInStock = 'true'; // Default value
  String _selectedCategory = 'Land'; // Default value
  File? _pickedImage;
  String? _uploadedImageUrl;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      // Get the current date and time
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}";

      // Extract the original file name
      final fileName = imageFile.path.split('/').last;

      // Create the unique file name with date and original file name
      final uniqueFileName = 'product_images/${formattedDate}_$fileName';

      final uploadedImageUrl = await AwsS3.uploadFile(
          accessKey: ".",
          secretKey: ".",
          file: imageFile,
          bucket: ".",
          region: ".",
          destDir: uniqueFileName);

      setState(() {
        _uploadedImageUrl = uploadedImageUrl;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  triggerNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10, channelKey: "basic_channel", body: "New Product Added"));
  }

  Future<void> _addProduct({
    required String image,
    required bool inStock,
    required String name,
    required double price,
    required int categoryId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      final vendorId = user.uid;
      final productId =
          FirebaseFirestore.instance.collection('products').doc().id;

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .set({
        'vendor_id': vendorId,
        'product_image': image,
        'product_instock': inStock,
        'product_name': name,
        'product_price': price,
        'categoryId': categoryId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product Added Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
    triggerNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_pickedImage != null) Image.file(_pickedImage!),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Pick Image'),
          ),
          DropdownButtonFormField<String>(
            value: _selectedInStock,
            decoration: const InputDecoration(labelText: 'Product In Stock'),
            items: ['true', 'false'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedInStock = newValue!;
              });
            },
          ),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Land', 'Sky'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedCategory = newValue!;
              });
            },
          ),
          TextFormField(
            controller: _productNameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the product name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _productPriceController,
            decoration: const InputDecoration(labelText: 'Product Price'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the product price';
              }
              try {
                double.parse(value);
              } catch (e) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() == true) {
                if (_pickedImage != null) {
                  await _uploadImage(_pickedImage!);
                  if (_uploadedImageUrl != null) {
                    await _addProduct(
                      image: _uploadedImageUrl!,
                      inStock: _selectedInStock == 'true',
                      name: _productNameController.text,
                      price: double.parse(_productPriceController.text),
                      categoryId: _selectedCategory == 'Land' ? 2 : 1,
                    );
                    _productNameController.clear();
                    _productPriceController.clear();
                    setState(() {
                      _pickedImage = null;
                      _selectedInStock = 'true'; // Reset to default value
                      _selectedCategory = 'Land'; // Reset to default value
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please pick an image')),
                  );
                }
              }
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}
