import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class ShoppingService {
final DatabaseReference _database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: "https://proyek-pertama-f873c-default-rtdb.firebaseio.com",
).ref().child('shopping_list');

  Stream<Map<String, String>> getShoppingList() {
    return _database.onValue.map((event) {
      final Map<String, String> items = {};
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> values =
            snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          items[key] = value['name'] as String;
        });
      }
      return items;
    });
  }

  void addShoppingItem(String itemName) {
    _database.push().set({'name': itemName});
  }

  Future<void> removeShoppingItem(String key) async {
    await _database.child(key).remove();
  }
}