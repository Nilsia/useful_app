import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';

class DataBaseManager {
  DataBaseManager({bool haveToInit = false}) {
    if (haveToInit) {
      init();
    }
  }

  final String _TBNameSL = "ShopList";
  final String _TBNameIC = "itemCountableList";
  final String _TBNameI = "item";

  // DB ShopList
  final String _idCSL = "id";
  final String _usedCSL = "used";
  final String _listNameCSL = "listName";
  final String _creationCSL = "creation";
  final String _expiryCSL = "expiry";
  final String _itemCountableListCSL = "itemCountableList";

  // DB ItemCountable
  final String _idCIC = "id";
  final String _usedCIC = "used";
  final String _takenCIC = "taken";
  final String _amountCIC = "amount";
  final String _deleteAfterCIC = "delete_after";
  final String _itemIDCIC = "itemID";

  // DB Item
  final String _idCI = "id";
  final String _usedCI = "used";
  final String _itemNameCI = "itemName";
  final String _locationCI = "location";
  final String _affiliationCI = "affiliation";
  final String _timeUsedCI = "time_used";

  late Future<Database> database;

  Future<void> init() async {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'shop_list.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) => createDb(db),
      version: 1,
    );
  }

  void createDb(Database db) {
    String createTB = "CREATE TABLE IF NOT EXISTS";
    String idColDef = "INTEGER PRIMARY KEY AUTOINCREMENT";
    db.execute(
        '$createTB $_TBNameI($_idCI $idColDef, $_usedCI TEXT, $_itemNameCI TEXT, $_locationCI TEXT, $_affiliationCI TEXT, $_timeUsedCI INTEGER);');
    db.execute(
        '$createTB $_TBNameIC($_idCIC $idColDef, $_usedCIC TEXT, $_takenCIC TEXT, $_amountCIC TEXT, $_deleteAfterCIC INTEGER, $_itemIDCIC TEXT);');
    db.execute('$createTB $_TBNameSL($_idCSL $idColDef, '
        '$_usedCSL TEXT, '
        '$_listNameCSL TEXT, '
        '$_creationCSL TEXT, '
        '$_expiryCSL TEXT, '
        '$_itemCountableListCSL TEXT);');
  }

  void dropTables() async {
    final db = await database;
    db.execute("DROP TABLE IF EXISTS $_TBNameIC");
    db.execute("DROP TABLE IF EXISTS $_TBNameSL");
    db.execute("DROP TABLE IF EXISTS $_TBNameI");
  }

  Future<int> addList(ShopList shopList) async {
    final Database db = await database;

    final values = shopList.toMapForDB();

    var c = await db.rawQuery("SELECT $_idCSL FROM $_TBNameSL WHERE $_usedCSL = ?", ["false"]);
    int res = -1;
    if (c.isEmpty) {
      res = await db.insert(_TBNameSL, values, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(_TBNameSL, values,
          where: "$_usedCSL = ? AND $_idCSL = ?", whereArgs: ["false", c[0][_idCSL].toString()]);
      res = int.parse(c[0][_idCSL].toString());
    }

    db.close();

    return res;
  }

  Future<List<ShopList>> getAllLists() async {
    List<ShopList> shopLists = <ShopList>[];
    final Database db = await database;

    final List<Map<String, Object?>> res =
        await db.rawQuery("SELECT * FROM $_TBNameSL WHERE $_usedCSL = ?", ["true"]);

    for (var o in res) {
      shopLists.add(ShopList(int.parse(o[_idCSL].toString()), o[_listNameCSL].toString(),
          DateTime.now(), DateTime.now(), <ItemCountable>[]));
    }

    return shopLists;
  }

  Future<List<Item>> getAllItem() async {
    List<Item> itemList = <Item>[];
    final Database db = await database;

    final List<Map<String, Object?>> res =
        await db.rawQuery("SELECT * FROM $_TBNameI WHERE $_usedCI = ?", ["true"]);

    for (var o in res) {
      itemList.add(Item.fromMap(o));
    }

    return itemList;
  }

  Future<ShopList> getShopList(int id) async {
    final Database db = await database;

    final List<Map<String, Object?>> res = await db.rawQuery(
        "SELECT * FROM $_TBNameSL WHERE $_idCSL = ? AND $_usedCSL = ?", [id.toString(), "true"]);
    if (res.isEmpty) {
      return ShopList(-1, "", DateTime.now(), DateTime.now(), []);
    }

    return ShopList.fromMap(res.first);
  }

  Future<List<ItemCountable>> getItemCountableList(Map<String, Object?> map) async {
    final db = await database;
    List<ItemCountable> itemCountableList = <ItemCountable>[];

    if (!map.containsKey(_itemCountableListCSL)) {
      return itemCountableList;
    }

    for (String id in map[_itemCountableListCSL].toString().split(",")) {
      if (id.isEmpty) {
        continue;
      }

      // get item countable
      List<Map<String, Object?>> resItemC =
          await db.rawQuery("SELECT * FROM $_TBNameIC WHERE $_idCIC = ?", [id]);

      if (resItemC.isEmpty || !resItemC[0].containsKey(_itemIDCIC)) {
        return itemCountableList;
      }

      // get item
      List<Map<String, Object?>> resItem = await db.rawQuery(
          "SELECT * FROM $_TBNameI WHERE $_idCI = ?", [resItemC[0][_itemIDCIC].toString()]);

      if (resItem.isEmpty) {
        return itemCountableList;
      }

      Item item = Item.fromMap(resItem.first);
      ItemCountable itemCountable = ItemCountable.fromMap(resItemC.first, item);

      itemCountableList.add(itemCountable);
    }

    return itemCountableList;
  }

  Future<ShopList> getShopListFromName(String name) async {
    final Database db = await database;

    final List<Map<String, Object?>> res = await db.rawQuery(
        "SELECT * FROM $_TBNameSL WHERE $_listNameCSL = ? AND $_usedCSL = ?", [name, "true"]);
    if (res.isEmpty) {
      return ShopList(-1, "", DateTime.now(), DateTime.now(), []);
    }

    return ShopList.fromMap(res.first);
  }

  Future<void> deleteItem(Item item) async {
    final Database db = await database;

    await db.update(_TBNameI, {_usedCI: "false"},
        where: "$_itemNameCI = ? AND $_usedCI = ?", whereArgs: [item.name, "true"]);
  }

  void deleteAllLists() async {
    final db = await database;

    await db.delete(_TBNameSL);
  }

  Future<void> deleteShopList(int id) async {
    final db = await database;

    final List<Map<String, Object?>> res = await db.rawQuery(
        "SELECT $_itemCountableListCSL FROM $_TBNameSL WHERE $_idCSL = ?", [id.toString()]);

    if (res.isEmpty) {
      return;
    }
    for (String str in res[0][_itemCountableListCSL].toString().split(",")) {
      await db.update(_TBNameIC, {_usedCIC: "false"}, where: "$_idCIC = ?", whereArgs: [str]);
    }

    await db.update(_TBNameSL, {_usedCSL: "false"},
        where: "$_idCSL = ?", whereArgs: [id.toString()]);
  }

  void setShopListName(String oldName, String newName) async {
    final db = await database;

    await db.update(_TBNameSL, {_listNameCSL: newName},
        where: "$_listNameCSL = ? AND $_usedCSL = ?", whereArgs: [oldName, "true"]);
  }

  Future<int> addItem(Item item) async {
    final db = await database;
    final List<Map<String, Object?>> res =
        await db.rawQuery("SELECT $_idCI FROM $_TBNameI WHERE $_usedCI = ?", ["false"]);

    if (res.isEmpty) {
      return db.insert(_TBNameI, item.toMapForDB(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      db.update(_TBNameI, item.toMapForDB(),
          where: "$_usedCI = ? AND $_idCI = ?", whereArgs: ["false", res[0][_idCI].toString()]);
      return int.parse(res[0][_idCI].toString());
    }
  }

  void setTakenItemCountable(int id, bool newValue) async {
    final db = await database;

    await db.update(_TBNameIC, {_takenCIC: newValue.toString()},
        where: "$_idCIC = ?", whereArgs: [id.toString()]);
  }

  void setAmountItemCountable(int id, String newValue) async {
    final db = await database;

    await db.update(_TBNameIC, {_amountCIC: newValue},
        where: "$_idCIC = ?", whereArgs: [id.toString()]);
  }

  Future<bool> restoreShopList(ShopList shopList) async {
    final db = await database;

    final List<Map<String, Object?>> c = await db.rawQuery(
        "SELECT $_idCSL FROM $_TBNameSL WHERE $_listNameCSL = ? AND $_usedCSL = ? AND $_idCSL = ?",
        [shopList.name, "false", shopList.id.toString()]);
    if (c.isEmpty) {
      return false;
    } else {
      return (await db.update(_TBNameSL, {_usedCSL: "true"},
              where: "id = ?", whereArgs: [c[0][_idCSL].toString()]) !=
          0);
    }
  }

  Future<bool> setAffiliationItem(Item item, String oldAff) async {
    final db = await database;

    return await db.update(_TBNameI, {_affiliationCI: item.affiliation},
            where: "$_idCI = ? AND $_usedCI = ?", whereArgs: [item.id.toString(), "true"]) !=
        0;
  }

  Future<bool> setLocationItem(Item item, String oldLoc) async {
    final db = await database;

    return await db.update(_TBNameI, {_locationCI: item.location},
            where: "$_idCI = ? AND $_usedCI = ?", whereArgs: [item.id.toString(), "true"]) !=
        0;
  }

  Future<bool> setNameItem(Item item, String oldName) async {
    final db = await database;

    return await db.update(_TBNameI, {_itemNameCI: item.name},
            where: "$_idCI = ? AND $_usedCI = ?", whereArgs: [item.id.toString(), "true"]) !=
        0;
  }

  Future<bool> addItemInList(ItemCountable itemCountable, ShopList shopList) async {
    final db = await database;

    // verify that the Item is in the database
    List<Map<String, Object?>> queryItem = await db.rawQuery(
        "SELECT $_idCI,$_timeUsedCI FROM $_TBNameI WHERE $_usedCI = ? AND $_itemNameCI = ?",
        ["true", itemCountable.item.name]);
    int positionItem;
    int timeUsed = 0;

    // not in the database, have to add it (Item
    if (queryItem.isEmpty) {
      positionItem = await addItem(itemCountable.item);
    }
    // already in database, get id of Item and item used
    else {
      print("in database");
      positionItem = int.parse(queryItem.first[_idCIC].toString());
      timeUsed = int.parse(queryItem.first[_timeUsedCI].toString());
    }

    // get an empty ItemCountable
    List<Map<String, Object?>> queryItemC =
        await db.rawQuery("SELECT $_idCIC FROM $_TBNameIC WHERE $_usedCIC = ?", ["false"]);
    int positionItemC;

    Map<String, String> map = itemCountable.toMapForDB();
    map[_deleteAfterCIC] = "false";
    map[_itemIDCIC] = positionItem.toString();

    // no raw available, have to add one
    if (queryItemC.isEmpty || !queryItemC.first.containsKey(_idCIC)) {
      print("one row inserted");
      positionItemC = await db.insert(_TBNameIC, map);
    }
    // there an empty space
    else {
      await db.update(_TBNameIC, map,
          where: "$_idCIC = ? AND $_usedCIC = ?", whereArgs: [queryItemC.first[_idCIC], "false"]);
      positionItemC = int.parse(queryItemC.first[_idCIC].toString());
    }

    List<Map<String, Object?>> querySL = await db.query(_TBNameSL,
        columns: [_itemCountableListCSL],
        where: "$_idCSL = ? AND $_listNameCSL = ? AND $_usedCSL = ?",
        whereArgs: [shopList.id.toString(), shopList.name, "true"],
        limit: 1);

    if (querySL.isEmpty) {
      return false;
    }

    String listIntItemID = querySL.first[_itemCountableListCSL].toString();
    print("avant : $listIntItemID");
    if (listIntItemID == "") {
      listIntItemID = "$positionItemC,";
    } else {
      listIntItemID = "$listIntItemID$positionItemC,";
    }
    print("après : $listIntItemID");

    // update time used
    db.update(_TBNameI, {_timeUsedCI: (timeUsed + 1).toString()},
        where: "$_idCI = ? AND $_usedCI = ?", whereArgs: [positionItem.toString(), "true"]);

    // update shopList ItemC
    db.update(_TBNameSL, {_itemCountableListCSL: listIntItemID},
        where: "$_idCSL = ? AND $_usedCSL = ?", whereArgs: [shopList.id.toString(), "true"]);

    return true;
  }

  Future<bool> deleteItemInShopList(int itemCountableID, int listID) async {
    final db = await database;

    List<Map<String, Object?>> querySL = await db.query(_TBNameSL,
        columns: [_itemCountableListCSL],
        where: "$_usedCSL = ? AND $_idCSL = ?",
        whereArgs: ["true", listID.toString()]);

    if (querySL.isEmpty) {
      return false;
    }

    List<String> strList = <String>[];

    for (String id in querySL.first[_itemCountableListCSL].toString().split(",")) {
      if (id != itemCountableID.toString() && id.isNotEmpty) {
        strList.add(id);
      }
    }

    String idList = "";
    if (strList.isNotEmpty) {
      for (int i = 0; i < strList.length - 1; i++) {
        idList = "$idList${strList[i]},";
      }
      idList = "$idList${strList[strList.length - 1]},";
      print(idList);
    }

    await db.update(_TBNameSL, {_itemCountableListCSL: idList},
        where: "$_idCSL = ?", whereArgs: [listID.toString()]);
    await db.update(_TBNameIC, {_usedCIC: "false"},
        where: "$_usedCIC = ? AND $_idCIC = ?", whereArgs: ["true", itemCountableID]);

    return true;
  }

/*Future<bool> restoreItemInShopList(String)*/
}
