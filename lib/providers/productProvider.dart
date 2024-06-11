import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/model/item.dart';
import 'package:ecommerce_app/model/category.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> get products => _products;
  List<Category> get categories => _categories;

  Future<void> fetchProducts() async {
    try {
      print("test");
      final querySnapshot = await _firestore.collection('products').get();
      _products = querySnapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      print("In Provider");
      //notifyListeners();
      return;
    } catch (error) {
      print('Error fetching products: $error');
      throw error;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').get();
      _categories = querySnapshot.docs
          .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (error) {
      print('Error fetching categories: $error');
      throw error;
    }
  }

  List<Product> getProductsByCategory(int categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  List<Product> searchProducts(String query) {
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> addProduct(Product product) async {
    try {
      final docRef =
          await _firestore.collection('products').add(product.toMap());
      _products.add(Product(
        id: docRef.id,
        vendorId: product.vendorId,
        imageUrl: product.imageUrl,
        inStock: product.inStock,
        name: product.name,
        price: product.price,
        categoryId: product.categoryId,
      ));
      notifyListeners();
    } catch (error) {
      print('Error adding product: $error');
      throw error;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      _products.removeWhere((product) => product.id == id);
      notifyListeners();
    } catch (error) {
      print('Error deleting product: $error');
      throw error;
    }
  }
}
