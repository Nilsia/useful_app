import 'dart:math';

import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/utils/tools.dart';

enum ItemCountableSelection { all, taken, notTaken }

class ItemCountable {
  int id = -1;
  bool taken = false, selected = false;
  String amount = "";
  Item item = Item.none();
  int shopListRef = -1;
  bool deleteAfter = false;

  ItemCountable(this.id, this.taken, this.amount, this.item, this.shopListRef,
      {this.deleteAfter = false});

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

  void setShopListRef(int shopListRef) {
    this.shopListRef = shopListRef;
  }

  /// return -1 on failure and 0 on success
  Future<int> setAmountDB(String newAmount, DataBaseManager db) async {
    setAmount(newAmount);
    return await db.setAmountItemCountable(id, amount);
  }

  Map<String, String> toMapForDB({int strLen = 100}) {
    return {
      DataBaseManager.takenIC: taken.toString(),
      DataBaseManager.amountIC: amount,
      DataBaseManager.itemRefIC: item.id.toString(),
      DataBaseManager.shopListRefIC: shopListRef.toString(),
      DataBaseManager.deleteAfterIC: deleteAfter.toString(),
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
    return "ItemCountable(id: $id, taken: $taken, amount: $amount, item: $item, refShopList: $shopListRef, deleteAfter: $deleteAfter)";
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

  Future<int> setTakenDB(bool taken, DataBaseManager db) async {
    setTaken(taken);
    return await db.setTakenItemCountable(id, taken);
  }

  /// from [map] build the ItemCountable requested, the [db] is used to generate the Item, if the item data are not in it there are search with [db]
  static Future<ItemCountable?> fromMap(
      Map<String, Object?> map, DataBaseManager db) async {
    if (!map.containsKey(DataBaseManager.idI) ||
        !map.containsKey(DataBaseManager.takenIC) ||
        !map.containsKey(DataBaseManager.amountIC) ||
        !map.containsKey(DataBaseManager.takenIC) ||
        !map.containsKey(DataBaseManager.shopListRefIC) ||
        !map.containsKey(DataBaseManager.shopListRefIC)) {
      return null;
    }
    int? id = int.tryParse(map[DataBaseManager.idIC].toString());
    bool taken = Tools.stringToBool(map[DataBaseManager.takenIC].toString());
    String amount = map[DataBaseManager.amountIC].toString();
    bool deleteAfter =
        Tools.stringToBool(map[DataBaseManager.deleteAfterIC].toString());
    int? shopListRef =
        int.tryParse(map[DataBaseManager.shopListRefIC].toString());
    if (id == null || shopListRef == null) {
      return null;
    }

    int? itemID = int.tryParse(map[DataBaseManager.itemRefIC].toString());
    if (itemID == null) {
      return null;
    }
    Item? item = Item.fromMap(map) ?? await db.getItem(itemID);
    if (item == null) {
      return null;
    }

    return ItemCountable(id, taken, amount, item, shopListRef,
        deleteAfter: deleteAfter);
  }
}
