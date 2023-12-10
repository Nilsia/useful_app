import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/utils/tools.dart';

// TODO
// set a description for ShopList at main page

class DataBaseManager {
  DataBaseManager({bool haveToInit = false}) {
    if (haveToInit) {
      init();
    }
  }

  static String tbNameSL = "ShopList";
  static String tbNameIC = "ItemCountable";
  static String tbNameI = "Item";

  // DB ShopList
  static String idSL = "shopListId";
  static String listNameSL = "listName";
  static String creationSL = "creation";
  static String expirySL = "expiry";

  // DB ItemCountable
  static String idIC = "itemCountableId";
  static String takenIC = "taken";
  static String amountIC = "amount";
  static String deleteAfterIC = "deleteAfter";
  static String itemRefIC = "itemRef";
  static String shopListRefIC = "shopListRef";

  // DB Item
  static String idI = "itemId";
  static String itemNameI = "itemName";
  static String locationI = "location";
  static String affiliationI = "affiliation";
  static String timeUsedI = "timeUsed";

  // late Future<Database> database;
  late Database db;
  bool hasInit = false;

  Future<DataBaseManager> init() async {
    if (hasInit) {
      return this;
    }

    db = await openDatabase(
      // database =  openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'shop_list.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) async => await createDb(db),
      version: 1,
    );
    hasInit = true;
    return this;
  }

  Future<void> createDb(Database db) async {
    String createTB = "CREATE TABLE IF NOT EXISTS";
    String idColDef = "INTEGER PRIMARY KEY AUTOINCREMENT";
    await db.execute('$createTB $tbNameSL($idSL $idColDef, '
        '$listNameSL TEXT, '
        '$creationSL TEXT, '
        '$expirySL TEXT);');
    await db.execute('$createTB $tbNameI($idI $idColDef, '
        '$itemNameI TEXT, '
        '$locationI TEXT, '
        '$affiliationI TEXT, '
        '$timeUsedI INTEGER);');
    await db.execute('$createTB $tbNameIC($idIC $idColDef, '
        '$takenIC TEXT, '
        '$amountIC TEXT, '
        '$deleteAfterIC INTEGER, '
        '$itemRefIC INTEGER ,'
        '$shopListRefIC INTEGER ,'
        'FOREIGN KEY ($itemRefIC) REFERENCES $tbNameI($idI) ON DELETE CASCADE,'
        'FOREIGN KEY ($shopListRefIC) REFERENCES $tbNameSL($idSL) ON DELETE CASCADE'
        ');');
  }

  void dropTables() async {
//    final Database db = await database;
    await db.execute("DROP TABLE IF EXISTS $tbNameIC");
    await db.execute("DROP TABLE IF EXISTS $tbNameSL");
    await db.execute("DROP TABLE IF EXISTS $tbNameI");
  }

  /// return 0 on success and -1 on failure
  Future<int> addList(ShopList shopList) async {
//    final Database db = await database;

    final values = shopList.toMapForDB();

    final int res = await db.insert(tbNameSL, values,
        conflictAlgorithm: ConflictAlgorithm.abort);

    // db.close();

    return res;
  }

  /// get all the list without there content
  Future<List<ShopList>> getAllLists() async {
    List<ShopList?> shopLists = [];
//    final Database db = await database;

    try {
      final List<Map<String, Object?>> res =
          await db.rawQuery("SELECT * FROM $tbNameSL");

      for (var o in res) {
        shopLists
            .add(await ShopList.fromMap(o, this, getItemCountableList: false));
      }
    } catch (e) {}
    return Tools.nullFilter(shopLists);
  }

  /// grab all the known item of the database
  Future<List<Item>> getAllItem() async {
    List<Item> itemList = <Item>[];
//    final Database db = await database;

    final List<Map<String, Object?>> res =
        await db.rawQuery("SELECT * FROM $tbNameI");

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
//    final Database db = await database;

    final List<Map<String, Object?>> res = await db
        .rawQuery("SELECT * FROM $tbNameSL WHERE $idSL = ?", [id.toString()]);
    if (res.isEmpty) {
      return ShopList.none();
    }

    return await ShopList.fromMap(res.first, this,
            getItemCountableList: true) ??
        ShopList.none();
  }

  Future<List<ItemCountable>> getItemCountableList(
      List<Map<String, Object?>>? mapList, int shopListId) async {
//    final Database db = await database;
    mapList = await db.rawQuery(
        "SELECT * FROM (SELECT * FROM $tbNameIC WHERE $shopListRefIC = ?) as ic JOIN $tbNameI as i ON i.$idI = ic.$itemRefIC ",
        [shopListId]);
    List<ItemCountable?> itemCountableList =
        List.generate(mapList.length, (index) => null);
    for (Map<String, Object?> map in mapList) {
      itemCountableList.add(await ItemCountable.fromMap(map, this));
    }
    return Tools.nullFilter(itemCountableList);
  }

  Future<Item?> getItem(int itemID) async {
//    final Database db = await database;
    return Item.fromMap(
        (await db.query(tbNameI, where: "$idI = ?", whereArgs: [itemID]))
            .first);
  }

  Future<ShopList> getShopListFromName(String name) async {
//    final Database db = await database;

    final List<Map<String, Object?>> res = await db
        .rawQuery("SELECT * FROM $tbNameSL WHERE $listNameSL = ?", [name]);
    if (res.isEmpty) {
      return ShopList.none();
    }

    var s = await ShopList.fromMap(res.first, this, getItemCountableList: true);
    if (s == null) {
      return ShopList.none();
    }
    return s;
  }

  /// return -1 in error and 0 on success
  Future<int> deleteItem(Item item) async {
//    final Database db = await database;
    return await db.delete(tbNameI, where: "$idI = ?", whereArgs: [item.id]) ==
            1
        ? 0
        : -1;
  }

  void deleteAllLists() async {
//    final Database db = await database;

    await db.delete(tbNameSL);
  }

  /// return -1 in error and 0 in success
  Future<int> deleteShopList(int id) async {
//    final Database db = await database;
    // delete shoplist
    final res1 = await db.delete(tbNameSL, where: "$idSL = ?", whereArgs: [id]);
    // delete all the items countable
    await db.delete(tbNameIC, where: "$shopListRefIC = ?", whereArgs: [id]);

    return (res1 != 0) ? 0 : -1;
  }

  /// return -1 on failture and 0 on success
  Future<int> setShopListName(String oldName, String newName) async {
//    final Database db = await database;

    return (await db.update(tbNameSL, {listNameSL: newName},
                where: "$listNameSL = ?", whereArgs: [oldName])) ==
            1
        ? 0
        : -1;
  }

  /// the id of the new item or -1 on failure
  Future<int> addItem(Item item) async {
//    final Database db = await database;
    return db.insert(tbNameI, item.toMapForDB());
  }

  /// return -1 on failure and 0 on success
  Future<int> setTakenItemCountable(int id, bool newValue) async {
//    final Database db = await database;

    return (await db.update(tbNameIC, {takenIC: newValue.toString()},
                where: "$idIC = ?", whereArgs: [id.toString()])) ==
            1
        ? 0
        : -1;
  }

  /// return -1 on failure and 0 on success
  Future<int> setAmountItemCountable(int id, String newValue) async {
//    final Database db = await database;

    return (await db.update(tbNameIC, {amountIC: newValue},
                where: "$idIC = ?", whereArgs: [id.toString()])) ==
            1
        ? 0
        : -1;
  }

  /// return -1 on failure and 0 on success
  Future<int> setAffiliationItem(Item item, String oldAff) async {
//    final Database db = await database;

    return (await db.update(tbNameI, {affiliationI: item.affiliation},
                where: "$idI = ? ", whereArgs: [item.id.toString()])) ==
            1
        ? 0
        : -1;
  }

  /// return -1 on failure and 0 on success
  Future<int> setLocationItem(Item item, String oldLoc) async {
//    final Database db = await database;

    return (await db.update(tbNameI, {locationI: item.location},
                where: "$idI = ? ", whereArgs: [item.id.toString()])) ==
            1
        ? 0
        : -1;
  }

  Future<int> setNameItem(Item item, String oldName) async {
//    final Database db = await database;

    return (await db.update(tbNameI, {itemNameI: item.name},
                where: "$idI = ?", whereArgs: [item.id.toString()])) ==
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
    itemCountable.setShopListRef(shopList.id);
//    final Database db = await database;

    // verify that the Item is in the database
    List<Map<String, Object?>> queryItem = await db.rawQuery(
        "SELECT $idI,$timeUsedI FROM $tbNameI WHERE $itemNameI = ?",
        [itemCountable.item.name]);
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
      positionItem = int.tryParse(queryItem.first[idI].toString());
      timeUsed = int.tryParse(queryItem.first[timeUsedI].toString());
      if (positionItem == null) {
        return -2;
      } else if (timeUsed == null) {
        return -3;
      }
    }

    Map<String, String> map = itemCountable.toMapForDB();
    map[deleteAfterIC] = "false";
    map[itemRefIC] = positionItem.toString();

    await db.insert(tbNameIC, map);
    // update time used
    int ret = await db.update(tbNameI, {timeUsedI: (timeUsed + 1).toString()},
        where: "$idI = ? ", whereArgs: [positionItem.toString()]);
    if (ret == 0) {
      return -6;
    }

    return 0;
  }

  /// 0 => success,
  /// values on error =>
  /// {cannot get shoplist: -1,
  ///  cannot update shoplist: -2,
  ///  cannot update itemCountable => -3}
  Future<int> deleteItemInShopList(int itemCountableID, int listID) async {
//    final Database db = await database;
    // TODO handle delete after
    final int res = await db
        .delete(tbNameIC, where: "$idIC = ?", whereArgs: [itemCountableID]);
    return res == 1 ? 0 : -1;
  }

  /// update the current [oldItem] into the [newItem], id of [oldItem] is used
  Future<int> updateItem(Item oldItem, Item newItem) async {
//    final Database db = await database;
    return ((await db.update(tbNameI, newItem.toMapForDB(),
                where: "$idI = ? ", whereArgs: [oldItem.id])) ==
            1
        ? 0
        : -1);
  }

/*Future<bool> restoreItemInShopList(String)*/
}
