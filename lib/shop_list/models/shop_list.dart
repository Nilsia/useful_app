import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/utils/tools.dart';

class ShopList {
  int id = -1;
  String name = "";
  DateTime creationDate = DateTime.now(), expiryDate = DateTime.now();
  List<ItemCountable> _initialItemCountableList = [],
      _currentItemCountableList = [];

  ItemCountableSelection itemCountableSelection = ItemCountableSelection.all;
  SortType sortType = SortType.none;

  ShopList(this.id, this.name, this.creationDate, this.expiryDate,
      this._initialItemCountableList) {
    _currentItemCountableList = _initialItemCountableList;
  }

  ShopList.none() {
    creationDate = DateTime.now();
    expiryDate = DateTime.now();
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

  /// check the name of the Item from [itemCountable]
  bool containsItemCountable(ItemCountable itemCountable) {
    for (ItemCountable ic in _initialItemCountableList) {
      if (ic.item.name == itemCountable.item.name) {
        return true;
      }
    }
    return false;
  }

  /// 0 => success,
  /// values on error =>
  /// {cannot get shoplist: -1,
  ///  cannot update shoplist: -2,
  ///  cannot update itemCountable => -3,
  /// not found => -10}
  Future<int> removeItem(
      ItemCountable itemCountable, DataBaseManager db) async {
    for (int i = 0; i < _initialItemCountableList.length; i++) {
      if (_initialItemCountableList[i].id == itemCountable.id) {
        _initialItemCountableList.removeAt(i);
        setCurrentItemCountableList();
        return await db.deleteItemInShopList(itemCountable.id, id);
      }
    }
    return -10;
  }

  Future<int> updateItemCountable(ItemCountable initialItemC,
      ItemCountable newItemC, DataBaseManager db) async {
    int res = 0;
    int tmp = 0;
    if (initialItemC.amount != newItemC.amount) {
      tmp = await initialItemC.setAmountDB(newItemC.amount, db);
      if (res == 0) {
        res = tmp;
      }
    }
    if (initialItemC.item.name != newItemC.item.name) {
      tmp = await initialItemC.item.setNameDB(newItemC.item.name, db);
      if (res == 0) {
        res = tmp;
      }
    }
    if (initialItemC.item.affiliation != newItemC.item.affiliation) {
      tmp = await initialItemC.item
          .setAffiliationDB(newItemC.item.affiliation, db);
      if (res == 0) {
        res = tmp;
      }
    }
    if (initialItemC.item.location != newItemC.item.location) {
      tmp = await initialItemC.item.setLocationDB(newItemC.item.location, db);
      if (res == 0) {
        res = tmp;
      }
    }
    setCurrentItemCountableList(selection: itemCountableSelection);
    return res;
  }

  // return 0 on success and negativ on failure
  Future<int> addItemCountable(
      ItemCountable itemCountable, DataBaseManager db) async {
    return await db.addItemInList(itemCountable, this);
  }

  Future<void> restore(ItemCountable itemCountable, DataBaseManager db) async {
    if (!containsItemCountable(itemCountable)) {
      _initialItemCountableList.add(itemCountable);
      setCurrentItemCountableList(selection: itemCountableSelection);
      await db.addItemInList(itemCountable, this);
    }
  }

  Future<void> restoreAll(
      List<ItemCountable> itemCountableList, DataBaseManager db) async {
    for (ItemCountable itemCountable in itemCountableList) {
      await restore(itemCountable, db);
    }
    setCurrentItemCountableList(selection: itemCountableSelection);
  }

  static Future<ShopList?> fromMap(
      Map<String, Object?> map, DataBaseManager db) async {
    if (!map.containsKey("id") || !map.containsKey("listName")) {
      return null;
    }
    int? id = int.tryParse(map["id"].toString());
    String name = map["listName"].toString();
    //creationDate = map["creation"].toString();
    //expiryDate = map["expiry"].toString();

    DateTime? creationDate = DateTime.now();
    DateTime? expiryDate = DateTime.now();
    List<ItemCountable> itemCountableList = await db.getItemCountableList(map);

    return (id != null)
        ? ShopList(id, name, creationDate, expiryDate, itemCountableList)
        : null;
  }

  /// 0 => success,
  /// values on error =>
  /// {cannot get shoplist: -1,
  ///  cannot update shoplist: -2,
  ///  cannot update itemCountable => -3,
  ///  not found => -10
  /// }
  Future<int> removeItemCountableList(
      List<ItemCountable> itemCountableList, DataBaseManager db) async {
    int tmp = 0, ret = 0;
    for (ItemCountable ic in itemCountableList) {
      tmp = await removeItem(ic, db);
      if (ret == 0) {
        ret = tmp;
      }
    }
    setCurrentItemCountableList(selection: itemCountableSelection);
    return ret;
  }

  Future<int> setTakenAll(DataBaseManager db,
      List<ItemCountable> itemCountableList, bool state) async {
    int tmp, ret = 0;
    for (ItemCountable ic in itemCountableList) {
      tmp = await ic.setTakenDB(state, db);
      if (ret == 0) {
        ret = tmp;
      }
    }
    setCurrentItemCountableList(selection: itemCountableSelection);
    return ret;
  }

  void setCurrentItemCountableList(
      {ItemCountableSelection? selection, SortType? sortType}) {
    selection ??= itemCountableSelection;
    itemCountableSelection = selection;

    sortType ??= this.sortType;
    this.sortType = sortType;

    switch (selection) {
      case ItemCountableSelection.all:
        _currentItemCountableList = _initialItemCountableList;
        break;
      case ItemCountableSelection.taken:
        _currentItemCountableList =
            _initialItemCountableList.where((e) => e.isTaken()).toList();
        break;
      case ItemCountableSelection.notTaken:
        _currentItemCountableList = _initialItemCountableList
            .where((element) => !element.isTaken())
            .toList();
        break;
    }

    switch (sortType) {
      case SortType.alpha:
        _currentItemCountableList
            .sort((a, b) => a.item.name.compareTo(b.item.name));
        break;
      case SortType.alphaRev:
        _currentItemCountableList
            .sort((a, b) => b.item.name.compareTo(a.item.name));
        break;
      case SortType.takenFirst:
        _currentItemCountableList.sort((a, b) => a.taken && !b.taken ? -1 : 1);
        break;
      case SortType.takenEnd:
        _currentItemCountableList.sort((a, b) => a.taken && !b.taken ? 1 : -1);
        break;
      case SortType.none:
        break;
    }
  }

  List<ItemCountable> getCurrentItemCountableList() =>
      _currentItemCountableList;

  Future<int> purge(DataBaseManager db) async {
    int res = 0, tmp;
    for (ItemCountable ic in _initialItemCountableList) {
      tmp = await db.deleteItemInShopList(ic.id, id);
      if (res == 0) {
        res = tmp;
      }
    }
    return res;
  }

  /// remove all IC useing [db] where ic.taken = [taken],
  /// it does not remove ic from this list, so update from db
  /// 0 on success, negativ on failure
  Future<int> removeTaken(bool taken, DataBaseManager db) async {
    int res = 0, tmp;
    for (ItemCountable ic in _initialItemCountableList) {
      if (ic.taken == taken) {
        tmp = await db.deleteItemInShopList(ic.id, id);
        if (res == 0) {
          res = tmp;
        }
      }
    }
    return res;
  }
}
