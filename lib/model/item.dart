class Product {
  String id;
  String vendorId;
  String imageUrl;
  bool inStock;
  String name;
  double price;
  int categoryId;

  Product({
    required this.id,
    required this.vendorId,
    required this.imageUrl,
    required this.inStock,
    required this.name,
    required this.price,
    required this.categoryId
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      vendorId: data['vendor_id'],
      imageUrl: data['product_image'],
      inStock: data['product_instock'],
      name: data['product_name'],
      price: (data['product_price'] as num).toDouble(),
      categoryId: data['categoryId'],
      
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'product_image': imageUrl,
      'product_instock': inStock,
      'product_name': name,
      'product_price': price,    
      "categoryId": categoryId,


    };
  }
}
