import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/model/item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/providers/authProvider.dart';
import 'package:provider/provider.dart';

class Details extends StatefulWidget {
  final Product product;

  Details({required this.product});

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final _commentController = TextEditingController();
  double _rating = -1;

  @override
  Widget build(BuildContext context) {
    triggerNotification() {
      AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: 10,
              channelKey: "basic_channel",
              body: "You Added A Comment On a Product"));
    }

    final authProv = Provider.of<MyAuthProvider>(context, listen: false);
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(widget.product.imageUrl),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "\$${widget.product.price}",
                          style: TextStyle(fontSize: 18, color: Colors.green),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.product.inStock ? "In Stock" : "Out of Stock",
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.product.inStock
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        SizedBox(height: 16),
                        FutureBuilder<double>(
                          future: _getAverageRating(widget.product.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return Text(
                                'Average Rating: N/A',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Rating: ${snapshot.data}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                _buildRatingStars(snapshot.data!),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (authProv.isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Comment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Enter your comment',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add Rating',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        icon: Icon(
                          index < _rating.floor()
                              ? Icons.star
                              : index == _rating.floor() && _rating % 1 != 0
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.yellow,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_rating == -1) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please enter a rating.'),
                        ));
                      } else {
                        if (user != null) {
                          {
                            triggerNotification();
                            _addComment(user);
                          }
                        }
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('productId', isEqualTo: widget.product.id)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> comment =
                          comments[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(comment['comment'] as String),
                        subtitle: Text('User: ${comment['user_email']}'),
                        trailing: _buildRatingStars(
                            (comment['rating'] as num).toDouble()),
                      );
                    },
                  );
                }
                return SizedBox(); // Placeholder widget
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addComment(User user) {
    FirebaseFirestore.instance.collection('comments').add({
      'comment': _commentController.text,
      'productId': widget.product.id,
      'rating': _rating,
      'user_email': user.email,
    }).then((_) {
      setState(() {
        _commentController.clear();
        _rating = -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Comment added successfully.'),
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add comment: $error'),
      ));
    });
  }

  Future<double> _getAverageRating(String productId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('productId', isEqualTo: productId)
        .get();
    if (snapshot.docs.isEmpty) {
      return 0.0;
    }
    final ratings =
        snapshot.docs.map((doc) => doc['rating'] as double).toList();
    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    return double.parse(avgRating.toStringAsFixed(2)); // Limit to 2 digits
  }

  Widget _buildRatingStars(double rating) {
    if (rating == -1) {
      return Text('No rating');
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          if (index < rating.floor().toDouble()) {
            return Icon(Icons.star, color: Colors.yellow);
          } else if (index == rating.floor().toDouble() && rating % 1 != 0) {
            return Icon(Icons.star_half, color: Colors.yellow);
          } else {
            return Icon(Icons.star_border, color: Colors.yellow);
          }
        }),
      );
    }
  }
}
