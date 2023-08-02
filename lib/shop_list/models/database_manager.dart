import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/utils/tools.dart';

// optimiser getItemCountableList

class DataBaseManager {
  DataBaseManager({bool haveToInit = false}) {
    if (haveToInit) {
      init();
    }
  }

  final String _tbNameSL = "ShopList";
  final String _tbNameIC = "itemCountableList";
  final String _tbNameI = "item";

  final String _id = "id";
  final String _used = "used";

  // DB ShopList
  final String _listNameCSL = "listName";
  final String _creationCSL = "creation";
  final String _expiryCSL = "expiry";
  final String _itemCountableListCSL = "itemCountableList";

  // DB ItemCountable
  final String _takenCIC = "taken";
  final String _amountCIC = "amount";
  final String _deleteAfterCIC = "delete_after";
  final String _itemIDCIC = "itemID";

  // DB Item
  final String _itemNameCI = "itemName";
  final String _locationCI = "location";
  final String _affiliationCI = "affiliation";
  final String _timeUsedCI = "time_used";

  late Future<Database> database;
  bool hasInit = false;

  Future<void> init() async {
    if (hasInit) {
      return;
    }
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'shop_list.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) => createDb(db),
      version: 1,
    );
    hasInit = true;
  }

  void createDb(Database db) {
    String createTB = "CREATE TABLE IF NOT EXISTS";
    String idColDef = "INTEGER PRIMARY KEY AUTOINCREMENT";
    db.execute(
        '$createTB $_tbNameI($_id $idColDef, $_used TEXT, $_itemNameCI TEXT, $_locationCI TEXT, $_affiliationCI TEXT, $_timeUsedCI INTEGER);');
    db.execute(
        '$createTB $_tbNameIC($_id $idColDef, $_used TEXT, $_takenCIC TEXT, $_amountCIC TEXT, $_deleteAfterCIC INTEGER, $_itemIDCIC TEXT);');
    db.execute('$createTB $_tbNameSL($_id $idColDef, '
        '$_used TEXT, '
        '$_listNameCSL TEXT, '
        '$_creationCSL TEXT, '
        '$_expiryCSL TEXT, '
        '$_itemCountableListCSL TEXT);');
  }

  void dropTables() async {
    final db = await database;
    db.execute("DROP TABLE IF EXISTS $_tbNameIC");
    db.execute("DROP TABLE IF EXISTS $_tbNameSL");
    db.execute("DROP TABLE IF EXISTS $_tbNameI");
  }

  /// return 0 on success and -1 on failure
  Future<int> addList(ShopList shopList) async {
    final Database db = await database;

    final values = shopList.toMapForDB();

    var c = await db
        .rawQuery("SELECT $_id FROM $_tbNameSL WHERE $_used = ?", ["false"]);
    int res = -1;
    if (c.isEmpty) {
      res = await db.insert(_tbNameSL, values,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(_tbNameSL, values,
          where: "$_used = ? AND $_id = ?",
          whereArgs: ["false", c[0][_id].toString()]);
      res = int.parse(c[0][_id].toString());
    }

    db.close();

    return res;
  }

  /// get all the list without there content
  Future<List<ShopList>> getAllLists() async {
    List<ShopList> shopLists = <ShopList>[];
    final Database db = await database;

    final List<Map<String, Object?>> res = await db
        .rawQuery("SELECT * FROM $_tbNameSL WHERE $_used = ?", ["true"]);

    for (var o in res) {
      shopLists.add(ShopList(
          int.parse(o[_id].toString()),
          o[_listNameCSL].toString(),
          DateTime.now(),
          DateTime.now(), <ItemCountable>[]));
    }

    return shopLists;
  }

  /// grab all the known item of the database
  Future<List<Item>> getAllItem() async {
    List<Item> itemList = <Item>[];
    final Database db = await database;

    final List<Map<String, Object?>> res =
        await db.rawQuery("SELECT * FROM $_tbNameI WHERE $_used = ?", ["true"]);

    Item? item;
    for (var o in res) {
      item = Item.fromMap(o);

      if (item != null) {
        itemList.add(item);
      }
    }

    return itemList;
  }

  /// get the list that has for id [id]
  Future<ShopList> getShopList(int id) async {
    final Database db = await database;

    final List<Map<String, Object?>> res = await db.rawQuery(
        "SELECT * FROM $_tbNameSL WHERE $_id = ? AND $_used = ?",
        [id.toString(), "true"]);
    if (res.isEmpty) {
      return ShopList(-1, "", DateTime.now(), DateTime.now(), []);
    }

    return await ShopList.fromMap(res.first, this) ?? ShopList.none();
  }

  Future<List<ItemCountable>> getItemCountableList(
      Map<String, Object?> map) async {
    final db = await database;
    List<ItemCountable?> itemCountableList = <ItemCountable?>[];

    if (!map.containsKey(_itemCountableListCSL)) {
      return [];
    }

    String inStr = "(?";
    List<int> ids = [];
    int? tmp;
    List<String> idListStr = map[_itemCountableListCSL].toString().split(",");
    if (idListStr.isEmpty) {
      return [];
    }
    if (idListStr.length == 1) {
      tmp = int.tryParse(idListStr.first);
      if (tmp == null) {
        return [];
      }

      ids = [tmp];
      inStr = "$inStr)";
    } else {
      tmp = int.tryParse(idListStr[0]);
      if (tmp == null) {
        return [];
      }
      ids = [tmp];
      for (int i = 1; i < idListStr.length; i++) {
        tmp = int.tryParse(idListStr[i]);
        if (tmp == null) {
          continue;
        }
        ids.add(tmp);
        inStr = "$inStr, ?";
      }
      inStr += ")";
    }

    // get all item Countable
    List<Map<String, Object?>> resItemC =
        await db.query(_tbNameIC, where: "$_id IN $inStr", whereArgs: ids);

    for (final Map<String, Object?> map in resItemC) {
      itemCountableList.add(await ItemCountable.fromMap(map, this));
    }
    return Tools.nullFilter(itemCountableList);

    // get all items
    /* List<Map<String, Object?>> resItem = await db.query(_TBNameI, where: )

    for (String id in map[_itemCountableListCSL].toString().split(",")) {
      if (id.isEmpty) {
        continue;
      }

      // get item countable
      List<Map<String, Object?>> resItemC =
          await db.rawQuery("SELECT * FROM $_TBNameIC WHERE $_id = ?", [id]);

      if (resItemC.isEmpty || !resItemC[0].containsKey(_itemIDCIC)) {
        return itemCountableList;
      }

      // get item
      List<Map<String, Object?>> resItem = await db.rawQuery(
          "SELECT * FROM $_TBNameI WHERE $_id = ?",
          [resItemC[0][_itemIDCIC].toString()]);

      if (resItem.isEmpty) {
        return itemCountableList;
      }

      Item item = Item.fromMap(resItem.first);
      ItemCountable itemCountable = ItemCountable.fromMap(resItemC.first, item);

      itemCountableList.add(itemCountable);
    }

    return itemCountableList; */
  }

  Future<Item?> getItem(int itemID) async {
    return Item.fromMap((await (await database).query(_tbNameI,
            where: "$_id = ? AND $_used = ?", whereArgs: [itemID, "true"]))
        .first);
  }

  Future<ShopList> getShopListFromName(String name) async {
    final Database db = await database;

    final List<Map<String, Object?>> res = await db.rawQuery(
        "SELECT * FROM $_tbNameSL WHERE $_listNameCSL = ? AND $_used = ?",
        [name, "true"]);
    if (res.isEmpty) {
      return ShopList(-1, "", DateTime.now(), DateTime.now(), []);
    }

    var s = await ShopList.fromMap(res.first, this);
    if (s == null) {
      return ShopList.none();
    }
    return s;
  }

  /// return -1 in error and 0 on success
  Future<int> deleteItem(Item item) async {
    final Database db = await database;

    return (await db.update(_tbNameI, {_used: "false"},
                where: "$_itemNameCI = ? AND $_used = ?",
                whereArgs: [item.name, "true"])) ==
            1
        ? 0
        : -1;
  }

  void deleteAllLists() async {
    final db = await database;

    await db.delete(_tbNameSL);
  }

  /// return -1 in error and 0 in success
  Future<int> deleteShopList(int id) async {
    final db = await database;

    final List<Map<String, Object?>> res = await db.rawQuery(
        "SELECT $_itemCountableListCSL FROM $_tbNameSL WHERE $_id = ?",
        [id.toString()]);

    if (res.isEmpty) {
      return -1;
    }
    int tmp = 0;
    int ret = 1;
    for (String str in res[0][_itemCountableListCSL].toString().split(",")) {
      tmp = await db.update(_tbNameIC, {_used: "false"},
          where: "$_id = ?", whereArgs: [str]);
      if (ret == 1) {
        ret = tmp;
      }
    }

    tmp = await db.update(_tbNameSL, {_used: "false"},
        where: "$_id = ?", whereArgs: [id.toString()]);
    return (tmp != 0 && ret != 0) ? 0 : -1;
  }

  /// return -1 on failture and 0 on success
  Future<int> setShopListName(String oldName, String newName) async {
    final db = await database;

    return (await db.update(_tbNameSL, {_listNameCSL: newName},
                where: "$_listNameCSL = ? AND $_used = ?",
                whereArgs: [oldName, "true"])) ==
            1
        ? 0
        : -1;
  }

  /// the id of the new item or -1 on failure
  Future<int> addItem(Item item) async {
    final db = await database;
    final List<Map<String, Object?>> res = await db
        .rawQuery("SELECT $_id FROM $_tbNameI WHERE $_used = ?", ["false"]);

    if (res.isEmpty) {
      return db.insert(_tbNameI, item.toMapForDB(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      if (await db.update(_tbNameI, item.toMapForDB(),
              where: "$_used = ? AND $_id = ?",
              whereArgs: ["false", res[0][_id].toString()]) ==
          0) {
        return -1;
      }
      int? id = int.tryParse(res[0][_id].toString());
      return id == null ? -1 : 0;
    }
  }

  /// return -1 on failure and 0 on success
  Future<int> setTakenItemCountable(int id, bool newValue) async {
    final db = await database;

    return (await db.update(_tbNameIC, {_takenCIC: newValue.toString()},
                where: "$_id = ?", whereArgs: [id.toString()])) ==
            1
        ? 0
        : -1;
  }

  /// return -1 on failure and 0 on success
  Future<int> setAmountItemCountable(int id, String newValue) async {
    final db = await database;

    return (await db.update(_tbNameIC, {_amountCIC: newValue},
                where: "$_id = ?", whereArgs: [id.toString()])) ==
            1
        ? 0
        : -1;
  }

  /// return -1 on failure and 0 on success
  Future<int> restoreShopList(ShopList shopList) async {
    final db = await database;

    final List<Map<String, Object?>> c = await db.rawQuery(
        "SELECT $_id FROM $_tbNameSL WHERE $_listNameCSL = ? AND $_used = ? AND $_id = ?",
        [shopList.name, "false", shopList.id.toString()]);
    if (c.isEmpty) {
      return -1;
    } else {
      return (await db.update(_tbNameSL, {_used: "true"},
                  where: "id = ?", whereArgs: [c[0][_id].toString()])) ==
              1
          ? 0
          : -1;
    }
  }

  /// return -1 on failure and 0 on success
  Future<int> setAffiliationItem(Item item, String oldAff) async {
    final db = await database;

    return (await db.update(_tbNameI, {_affiliationCI: item.affiliation},
                where: "$_id = ? AND $_used = ?",
                whereArgs: [item.id.toString(), "true"])) ==
            1
        ? 0
        : -1;
  }

  /// return -1 on failure and 0 on success
  Future<int> setLocationItem(Item item, String oldLoc) async {
    final db = await database;

    return (await db.update(_tbNameI, {_locationCI: item.location},
                where: "$_id = ? AND $_used = ?",
                whereArgs: [item.id.toString(), "true"])) ==
            1
        ? 0
        : -1;
  }

  Future<int> setNameItem(Item item, String oldName) async {
    final db = await database;

    return (await db.update(_tbNameI, {_itemNameCI: item.name},
                where: "$_id = ? AND $_used = ?",
                whereArgs: [item.id.toString(), "true"])) ==
            1
        ? 0
        : -1;
  }

  /// 0 => success,
  /// values on error =>
  /// {cannot insert: -1,
  ///  id invalid: -2,
  ///  timeUsed invalide => -3,
  ///  error id parsing => -4,
  ///  cannot get shoplist => -5,
  ///  cannot update item => -6,
  ///  cannot update shoplist => -7}
  Future<int> addItemInList(
      ItemCountable itemCountable, ShopList shopList) async {
    final Database db = await database;

    // verify that the Item is in the database
    List<Map<String, Object?>> queryItem = await db.rawQuery(
        "SELECT $_id,$_timeUsedCI FROM $_tbNameI WHERE $_used = ? AND $_itemNameCI = ?",
        ["true", itemCountable.item.name]);
    int? positionItem;
    int? timeUsed = 0;

    // not in the database, have to add it (Item
    if (queryItem.isEmpty) {
      positionItem = await addItem(itemCountable.item);
      if (positionItem <= -1) {
        return -1;
      }
    }
    // already in database, get id of Item and item used
    else {
      positionItem = int.tryParse(queryItem.first[_id].toString());
      timeUsed = int.tryParse(queryItem.first[_timeUsedCI].toString());
      if (positionItem == null) {
        return -2;
      } else if (timeUsed == null) {
        return -3;
      }
    }

    // get an empty ItemCountable
    List<Map<String, Object?>> queryItemC = await db
        .rawQuery("SELECT $_id FROM $_tbNameIC WHERE $_used = ?", ["false"]);
    int? positionItemC;

    Map<String, String> map = itemCountable.toMapForDB();
    map[_deleteAfterCIC] = "false";
    map[_itemIDCIC] = positionItem.toString();

    // no raw available, have to add one
    if (queryItemC.isEmpty || !queryItemC.first.containsKey(_id)) {
      positionItemC = await db.insert(_tbNameIC, map);
    }
    // there an empty space
    else {
      await db.update(_tbNameIC, map,
          where: "$_id = ? AND $_used = ?",
          whereArgs: [queryItemC.first[_id], "false"]);
      positionItemC = int.tryParse(queryItemC.first[_id].toString());
      if (positionItemC == null) {
        return -4;
      }
    }

    List<Map<String, Object?>> querySL = await db.query(_tbNameSL,
        columns: [_itemCountableListCSL],
        where: "$_id = ? AND $_listNameCSL = ? AND $_used = ?",
        whereArgs: [shopList.id.toString(), shopList.name, "true"],
        limit: 1);

    if (querySL.isEmpty) {
      return -5;
    }

    String listIntItemID = querySL.first[_itemCountableListCSL].toString();
    if (listIntItemID.isEmpty) {
      listIntItemID = "$positionItemC,";
    } else {
      listIntItemID = "$listIntItemID$positionItemC,";
    }

    // update time used
    int ret = await db.update(
        _tbNameI, {_timeUsedCI: (timeUsed + 1).toString()},
        where: "$_id = ? AND $_used = ?",
        whereArgs: [positionItem.toString(), "true"]);
    if (ret == 0) {
      return -6;
    }

    // update shopList ItemC
    return (await db.update(_tbNameSL, {_itemCountableListCSL: listIntItemID},
                where: "$_id = ? AND $_used = ?",
                whereArgs: [shopList.id.toString(), "true"])) ==
            1
        ? 0
        : -7;
  }

  /// 0 => success,
  /// values on error =>
  /// {cannot get shoplist: -1,
  ///  cannot update shoplist: -2,
  ///  cannot update itemCountable => -3}
  Future<int> deleteItemInShopList(int itemCountableID, int listID) async {
    final db = await database;

    List<Map<String, Object?>> querySL = await db.query(_tbNameSL,
        columns: [_itemCountableListCSL],
        where: "$_used = ? AND $_id = ?",
        whereArgs: ["true", listID.toString()]);

    if (querySL.isEmpty) {
      return -1;
    }

    List<String> strList = <String>[];

    for (String id
        in querySL.first[_itemCountableListCSL].toString().split(",")) {
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
    }

    int ret = await db.update(_tbNameSL, {_itemCountableListCSL: idList},
        where: "$_id = ?", whereArgs: [listID.toString()]);
    if (ret != 1) {
      return -2;
    }
    return (await db.update(_tbNameIC, {_used: "false"},
                where: "$_used = ? AND $_id = ?",
                whereArgs: ["true", itemCountableID])) ==
            1
        ? 0
        : -3;
  }

  /// update the current [oldItem] into the [newItem], id of [oldItem] is used
  Future<int> updateItem(Item oldItem, Item newItem) async {
    return ((await (await database).update(_tbNameI, newItem.toMapForDB(),
                where: "$_id = ? AND $_used = ?",
                whereArgs: [oldItem.id, 'true'])) ==
            1
        ? 0
        : -1);
  }

/*Future<bool> restoreItemInShopList(String)*/
}
