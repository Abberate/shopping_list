import 'dart:convert';
import 'package:shopping_list/data/categories.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  Future<List<GroceryItem>> _loadItem() async {
    final url = Uri.https(
        'flutter-learn-7a2ef-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping_list.json');
    final response = await http.get(url);

    if (response.body == 'null') {
      return [];
    }

    if (response.statusCode >= 400) {
      throw Exception('Failled to fetch date. Please try again later !');
    }

    final Map<String, dynamic> listData = jsonDecode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries.firstWhere(
        (element) => element.value.title == item.value['category'],
      );

      loadedItems.add(GroceryItem(
        id: item.key,
        name: item.value['name'],
        quantity: int.parse(item.value['quantity']),
        category: category.value,
      ));
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      (MaterialPageRoute(builder: (ctx) => const NewItem())),
    );

    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'flutter-learn-7a2ef-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping_list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting item")));
      groceryItems.insert(index, item);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadedItems = _loadItem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Groceries",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items yet!'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              key: ValueKey(snapshot.data![index].id),
              onDismissed: (ctx) => _removeItem(snapshot.data![index]),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                title: Text(snapshot.data![index].name),
                trailing: Text(snapshot.data![index].quantity.toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}
