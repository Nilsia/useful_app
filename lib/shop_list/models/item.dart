import 'package:useful_app/shop_list/models/database_manager.dart';

class Item {
  int id = -1, timeUsed = 0;
  String name = "", location = "", affiliation = "";

  Item(this.id, this.name, this.location, this.affiliation, this.timeUsed);

  Item.none() {
    id = -1;
    name = "";
    location = "";
    affiliation = "";
    timeUsed = 0;
  }

  void setName(String name) {
    this.name = name;
  }

  void setLocation(String loc) {
    location = loc;
  }

  void setAffiliation(String aff) {
    affiliation = aff;
  }

  Item clone(
      String? name, String? affiliation, String? location, int? timeUsed) {
    return Item(id, name ?? this.name, location ?? this.location,
        affiliation ?? this.affiliation, timeUsed ?? this.timeUsed);
  }

  Future<int> setAffiliationDB(String newAff, DataBaseManager db) async {
    String oldAff = affiliation;
    setAffiliation(newAff);
    return await db.setAffiliationItem(this, oldAff);
  }

  Future<int> setLocationDB(String newLoc, DataBaseManager db) async {
    String oldLoc = location;
    setLocation(newLoc);
    return await db.setLocationItem(this, oldLoc);
  }

  Future<int> setNameDB(String newName, DataBaseManager db) async {
    String oldName = name;
    setName(newName);
    return await db.setNameItem(this, oldName);
  }

  Map<String, String> toMapForDB() {
    return {
      DataBaseManager.itemNameI: name,
      DataBaseManager.locationI: location,
      DataBaseManager.affiliationI: affiliation,
      DataBaseManager.timeUsedI: timeUsed.toString(),
    };
  }

  @override
  String toString() {
    return "Item(id: $id, ${DataBaseManager.itemNameI}: $name, ${DataBaseManager.locationI}: $location, ${DataBaseManager.affiliationI}: $affiliation, ${DataBaseManager.timeUsedI}: $timeUsed)";
  }

  static Item? fromMap(Map<String, Object?> map) {
    if (!map.containsKey(DataBaseManager.idI) ||
        !map.containsKey(DataBaseManager.itemNameI) ||
        !map.containsKey(DataBaseManager.locationI) ||
        !map.containsKey(DataBaseManager.affiliationI) ||
        !map.containsKey(DataBaseManager.timeUsedI)) {
      return null;
    }
    int? id = int.tryParse(map[DataBaseManager.idI].toString());
    String name = map[DataBaseManager.itemNameI].toString();
    String location = map[DataBaseManager.locationI].toString();
    String affiliation = map[DataBaseManager.affiliationI].toString();
    int? timeUsed = int.tryParse(map[DataBaseManager.timeUsedI].toString());

    return (timeUsed == null || id == null)
        ? null
        : Item(id, name, location, affiliation, timeUsed);
  }
}
