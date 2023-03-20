import 'package:useful_app/shop_list/models/database_manager.dart';

class Item {
  int id = -1, timeUsed = 0;
  String name = "", location = "", affiliation = "";

  Item(this.id, this.name, this.location, this.affiliation, this.timeUsed);

  Item.fromMap(Map<String, Object?> map) {
    try {
      id = int.parse(map["id"].toString());
      name = map["itemName"].toString();
      location = map["location"].toString();
      affiliation = map["affiliation"].toString();
      timeUsed = int.parse(map["timeUsed"].toString());
    } catch (e) {
      Item.none();
    }
  }

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

  void setAffiliationDB(String newAff, DataBaseManager db) {
    String oldAff = affiliation;
    setAffiliation(newAff);
    db.setAffiliationItem(this, oldAff);
  }

  void setLocationDB(String newLoc, DataBaseManager db) {
    String oldLoc = location;
    setLocation(newLoc);
    db.setLocationItem(this, oldLoc);
  }

  void setNameDB(String newName, DataBaseManager db) {
    String oldName = name;
    setName(newName);
    db.setNameItem(this, oldName);
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
}
