import 'package:ecommerce_app/pages/ProfilePageShopper.dart';
import 'package:ecommerce_app/pages/checkout.dart';
import 'package:ecommerce_app/pages/details_screen.dart';
import 'package:ecommerce_app/pages/loginSignupScreen.dart';
import 'package:ecommerce_app/providers/cart.dart';
import 'package:ecommerce_app/providers/productProvider.dart';
import 'package:ecommerce_app/shared/appbar.dart';
import 'package:ecommerce_app/shared/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/providers/authProvider.dart';
import 'package:ecommerce_app/model/item.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedCategoryId = 0;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      productProvider.fetchCategories();
      print("Before Prov");
      productProvider.fetchProducts();
      print("After Prov");
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<Cart>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<MyAuthProvider>(context);
    print(authProvider.role);
    if (authProvider.role == "Vendor") {}
    print(_selectedCategoryId);
    List<Product> displayedProducts = _selectedCategoryId == 0
        ? productProvider.products
        : productProvider.getProductsByCategory(_selectedCategoryId);
    print(displayedProducts);
    if (_searchQuery.isNotEmpty) {
      displayedProducts = productProvider.searchProducts(_searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [ProductsAndPrice()],
        backgroundColor: appbarGreen,
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
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
                  title: Text("Home"),
                  leading: Icon(Icons.home),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text("My products"),
                  leading: Icon(Icons.add_shopping_cart),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckOut(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text("Profile"),
                  leading: Icon(Icons.person),
                  onTap: () {
                    var user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                        Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(),
                      ),
                    );
                    }
                  
                  },
                ),
                ListTile(
                  title: Text("About"),
                  leading: Icon(Icons.help_center),
                  onTap: () {},
                ),
                if (authProvider.isAuthenticated)
                  ListTile(
                    title: Text("Logout"),
                    leading: Icon(Icons.exit_to_app),
                    onTap: () {
                      authProvider.logout();
                    },
                  )
                else
                  ListTile(
                    title: Text("Sign in"),
                    leading: Icon(Icons.exit_to_app),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Text(
                "Developed by George, Omar And Ahmed",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedCategoryId,
                  items: productProvider.categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.categoryId,
                      child: Text(category.categoryName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value!;
                    });
                  },
                  hint: Text("Category"),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: productProvider.fetchProducts(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.error != null) {
                  return Center(child: Text('An error occurred!'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 33,
                      ),
                      itemCount: displayedProducts.length,
                      itemBuilder: (BuildContext context, int index) {
                        final product = displayedProducts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Details(product: product),
                              ),
                            );
                          },
                          child: GridTile(
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -3,
                                  bottom: -9,
                                  right: 0,
                                  left: 0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(55),
                                    child: Image.network(product.imageUrl,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                              ],
                            ),
                            footer: GridTileBar(
                              trailing: IconButton(
                                color: Color.fromARGB(255, 62, 94, 70),
                                onPressed: () {
                                  cartProvider.add(product);
                                },
                                icon: Icon(Icons.add),
                              ),
                              leading:
                                  Text("\$${product.price.toStringAsFixed(2)}"),
                              title: Text(""),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
