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
      "itemName": name,
      "location": location,
      "affiliation": affiliation,
      "time_used": timeUsed.toString(),
      "used": "true",
    };
  }

  @override
  String toString() {
    return "Item(id: $id, itemName: $name, location: $location, affiliation: $affiliation, time_used: $timeUsed)";
  }

  static Item? fromMap(Map<String, Object?> map) {
    if (!map.containsKey("id") ||
        !map.containsKey("itemName") ||
        !map.containsKey("location") ||
        !map.containsKey("affiliation") ||
        !map.containsKey("time_used")) {
      return null;
    }
    int? id = int.tryParse(map["id"].toString());
    String name = map["itemName"].toString();
    String location = map["location"].toString();
    String affiliation = map["affiliation"].toString();
    int? timeUsed = int.tryParse(map["time_used"].toString());

    return (timeUsed == null || id == null)
        ? null
        : Item(id, name, location, affiliation, timeUsed);
  }
}
