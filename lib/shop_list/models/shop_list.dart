import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';


class ShopList {
  int id = -1;
  String name = "";
  DateTime creationDate = DateTime.now(), expiryDate = DateTime.now();
  List<ItemCountable> itemCountableList = [];

  ShopList(this.id, this.name, this.creationDate, this.expiryDate,
      this.itemCountableList);

  ShopList.fromMap(Map<String, Object?> map) {
    try {
      id = int.parse(map["id"].toString());
      name = map["listName"].toString();
      //creationDate = map["creation"].toString();
      //expiryDate = map["expiry"].toString();
      creationDate = DateTime.now();
      expiryDate = DateTime.now();
      DataBaseManager dataBaseManager = DataBaseManager();
      dataBaseManager.init().then((value) => {
            dataBaseManager
                .getItemCountableList(map)
                .then((value) => {itemCountableList = value})
          });
    } catch (e) {
      ShopList.none();
    }
  }

  ShopList.none() {
    id = -1;
    name = "";
    creationDate = DateTime.now();
    expiryDate = DateTime.now();
    itemCountableList = [];
  }

  void setName(String name) {
    this.name = name;
  }

  void setID(int id) {
    this.id = id;
  }

  void setExpiryDate(DateTime expiry) {
    expiryDate = expiry;
  }

  List<ItemCountable> getItemCountableTaken() {
    List<ItemCountable> currentList = <ItemCountable>[];

    for (ItemCountable itemCountable in itemCountableList) {
      if (itemCountable.isTaken()) {
        currentList.add(itemCountable);
      }
    }

    return currentList;
  }

  List<ItemCountable> getItemCountableNotTaken() {
    List<ItemCountable> currentList = <ItemCountable>[];

    for (ItemCountable itemCountable in itemCountableList) {
      if (!itemCountable.isTaken()) {
        currentList.add(itemCountable);
      }
    }

    return currentList;
  }

  Map<String, String> toMap() {
    return {
      "id": id.toString(),
      "used": "true",
      "listName": name,
      "creation": creationDate.toString(),
      "expiry": expiryDate.toString(),
      "itemCountableList": "",
    };
  }

  Map<String, String> toMapForDB() {
    return {
      "used": "true",
      "listName": name,
      "creation": creationDate.toString(),
      "expiry": expiryDate.toString(),
      "itemCountableList": "",
    };
  }

  bool containsItemCountable(ItemCountable itemCountable) {
    for (ItemCountable ic in itemCountableList) {
      if (ic.item.name == itemCountable.item.name) {
        return true;
      }
    }
    return false;
  }

  Future<void> removeItem(ItemCountable itemCountable, DataBaseManager db) async {
    for (int i = 0; i < itemCountableList.length; i++) {
      if (itemCountableList[i].item.name == itemCountable.item.name) {
        itemCountableList.removeAt(i);
        print("item removed");
        await db.deleteItemInShopList(itemCountable.id, id);
        break;
      }
    }
  }

  void updateItemCountable(
      ItemCountable initialItemC, ItemCountable newItemC, DataBaseManager db) {
    if (initialItemC.amount != newItemC.amount) {
      initialItemC.setAmountDB(newItemC.amount, db);
    }
    if (initialItemC.item.name != newItemC.item.name) {
      initialItemC.item.setNameDB(newItemC.item.name, db);
    }
    if (initialItemC.item.affiliation != newItemC.item.affiliation) {
      initialItemC.item.setAffiliationDB(newItemC.item.affiliation, db);
    }
    if (initialItemC.item.location != newItemC.item.location) {
      initialItemC.item.setLocationDB(newItemC.item.location, db);
    }
  }

  Future<bool> addItemCountable(
      ItemCountable itemCountable, DataBaseManager db) async {
    itemCountableList.add(itemCountable);
    return await db.addItemInList(itemCountable, this);
  }

  Future<void> restore(ItemCountable itemCountable, DataBaseManager db) async {
    if (!containsItemCountable(itemCountable)) {
      itemCountableList.add(itemCountable);
      await db.addItemInList(itemCountable, this);
    }
  }

  Future<void> restoreAll(List<ItemCountable> itemCountableList, DataBaseManager db) async {
    for (ItemCountable itemCountable in itemCountableList) {
      await restore(itemCountable, db);
    }
  }
}
