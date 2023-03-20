import 'dart:math';

import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/tools.dart';

class ItemCountable {
  int id = -1;
  bool taken = false, selected = false;
  String amount = "";
  Item item = Item.none();

  ItemCountable(this.id, this.taken, this.amount, this.item);

  ItemCountable.fromMap(Map<String, Object?> map, this.item) {
    try {
      id = int.parse(map["id"].toString());
      taken = Tools.stringToBool(map["taken"].toString());
      amount = map["amount"].toString();
    } catch (e) {
      ItemCountable.none(item);
    }
  }

  ItemCountable.none(this.item) {
    id = -1;
    taken = false;
    amount = "";
  }

  void setAmount(String amount) {
    this.amount = amount;
  }

  void setItem(Item item) {
    this.item = item;
  }

  bool isTaken() {
    return taken;
  }

  void setTaken(bool taken) {
    this.taken = taken;
  }

  void setAmountDB(String newAmount, DataBaseManager db) {
    setAmount(newAmount);
    db.setAmountItemCountable(id, amount);
  }

  Map<String, String> toMapForDB({int strLen = 100}) {
    return {
      "used".substring(0, min(4, strLen)): "true",
      "taken".substring(0, min(5, strLen)): taken.toString(),
      "amount".substring(0, min(6, strLen)): amount,
      "itemID".substring(0, min(6, strLen)): item.id.toString(),
    };
  }

  Map<String, String> toMapContent({int strLen = 100}) {
    Item citem = item;
    return {
      "taken".substring(0, min(5, strLen)): taken.toString(),
      "amount".substring(0, min(6, strLen)): amount,
      "name".substring(0, min(4, strLen)): citem.name,
      "affiliation".substring(0, min(11, strLen)): citem.affiliation,
      "location".substring(0, min(8, strLen)): citem.location,
    };
  }

  bool isNull() {
    return id == -1;
  }

  @override
  String toString() {
    return "ItemCountable(id: $id, taken: $taken, amount: $amount, item: $item)";
  }

  void editFromMap(Map<String, Object> map) {
    map.forEach((key, value) {
      switch (key) {
        case "id":
          id = int.parse(value.toString());
          break;
        case "taken":
          taken = value as bool;
          break;
        case "amount":
          amount = value.toString();
          break;
        case "item":
          item = value as Item;
          break;
      }
    });
  }

  void setTakenDB(bool taken, DataBaseManager db) {
    setTaken(taken);
    db.setTakenItemCountable(id, taken);
  }
}
