import 'package:ecommerce_app/model/item.dart';
import 'package:flutter/material.dart';

class Cart with ChangeNotifier {
  List selectedProducts = [];
  int price = 0;

  add(Product product) {
    selectedProducts.add(product);
    price += product.price.round();
    notifyListeners();
  }

  delete(Product product) {
    selectedProducts.remove(product);
    price -= product.price.round();

    notifyListeners();
  }

  get itemCount {
    return selectedProducts.length;
  }
}
