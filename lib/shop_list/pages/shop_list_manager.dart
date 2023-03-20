import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_composer_dialog.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/tools.dart';

class ShopListManager extends StatefulWidget {
  final String listName;
  final bool editing = true;

  const ShopListManager(this.listName, {Key? key, bool editing = true})
      : super(key: key);

  @override
  State<ShopListManager> createState() => _ShopListManagerState();
}

enum DropdownItemsEnum { makeAllTaken, makeAllNotTaken, remove }

class DropDownItem {
  String text;
  DropdownItemsEnum dropdownItemsEnum;

  DropDownItem(this.text, this.dropdownItemsEnum);
}

class _ShopListManagerState extends State<ShopListManager> {
  final DataBaseManager db = DataBaseManager();
  ShopList currentShopList = ShopList.none();
  bool hasInit = false;
  ItemCountable itemCChosen = ItemCountable.none(Item.none());

  String currentWorking = "(édition)";
  bool itemCountableSelected = false;

  List<ItemCountable> itemRemovedOnce = <ItemCountable>[];

  List<DropDownItem> dropDownItemList = <DropDownItem>[
    DropDownItem("Marquer comme pris", DropdownItemsEnum.makeAllTaken),
    DropDownItem("Marquer comme non pris", DropdownItemsEnum.makeAllNotTaken),
    DropDownItem("Supprimer", DropdownItemsEnum.remove),
  ];

  IconButton locker =
      const IconButton(icon: Icon(Icons.lock_open), onPressed: null);
  IconButton refresh =
      const IconButton(onPressed: null, icon: Icon(Icons.refresh));

  List<String> keys = ["nam", "amo", "aff", "loc"];
  Map<String, ItemComposerDialog> listICD = {
    "nam": ItemComposerDialog(
        "Nom : ", "Nom de l'élement", TextEditingController(), "Nom : "),
    "amo": ItemComposerDialog(
        "Quantité : ", "Quantité", TextEditingController(), "Qtd : "),
    "aff": ItemComposerDialog(
        "Appartenance : ", "Appartenance", TextEditingController(), "Apt : "),
    "loc": ItemComposerDialog(
        "Emplacement : ", "Emplacement", TextEditingController(), "Emp : "),
  };

  Map<String, String> itemCContent = {};
  List<Widget> appbarActions = [];

  @override
  void initState() {
    listICD.forEach((key, value) {
      listICD[key]?.controller = TextEditingController();
    });
    super.initState();
  }

  @override
  void dispose() {
    for (var v in listICD.values) {
      listICD[v]?.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInit) {
      hasInit = true;

      locker = IconButton(
          icon: const Icon(Icons.lock_open),
          onPressed: () => {
                onLockerPressed(),
              });
      refresh = IconButton(
          onPressed: () => setState(() {}), icon: const Icon(Icons.refresh));
      appbarActions = [refresh, locker];

      updateShopList();
    }

    return Scaffold(
      appBar: Tools.generateAppBar(
          Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(super.widget.listName),
                Text(
                  currentWorking,
                  style: const TextStyle(fontSize: 10),
                )
              ]),
          actions: appbarActions),
      body: ListView.builder(
          itemCount: currentShopList.itemCountableList.length,
          itemBuilder: (BuildContext context, int index) {
            ItemCountable ic = currentShopList.itemCountableList[index];
            ShapeBorder? shapeBorder;
            Color? color;
            if (ic.selected) {
              /*shapeBorder = Border.all(
                  color: Colors.red, width: 1, strokeAlign: StrokeAlign.inside);*/
              color = Colors.indigoAccent;
            }
            return Card(
              shape: shapeBorder,
              color: color,
              child: InkWell(
                onTap: () {
                  // modify itemC
                  if (isInEdition() && !itemCountableSelected) {
                    clearListICD();
                    Map<String, String> map = ic.toMapContent(strLen: 3);
                    listICD.forEach((String key, ItemComposerDialog value) {
                      if (map.containsKey(key)) {
                        value.controller.text = map[key] ?? "";
                      }
                    });
                    itemCChosen = ic;
                    openDialogNewItemCountable(generateWidgetList(true),
                        title: "Édition d'un élément");
                  }
                  // add itemC to selection
                  else if (itemCountableSelected && isInEdition()) {
                    ic.selected = ic.selected ? false : true;
                    updateItemCountableSelected();
                    setState(() {});
                  }
                },
                onLongPress: () {
                  if (isInEdition()) {
                    ic.selected = true;
                    updateItemCountableSelected();
                    setState(() {});
                  }
                },
                child: SizedBox(
                  height: 50,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Row(children: getItemListTile(ic))),
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await openDialogNewItemCountable(generateWidgetList(false));
        },
        tooltip: "Ajouter un élément",
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: Container(
          margin: const EdgeInsets.only(top: 50),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const BackButton(),
              TextButton(
                onPressed: () => {
                  Navigator.pop(context),
                  Navigator.pop(context),
                },
                child: Text("coucou"),
              ),
              const SizedBox(
                  height: 50,
                  child: DrawerHeader(
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text("Nom de la list")))
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> getItemListTile(ItemCountable ic) {
    Widget leading;
    double imageSize = 40, opacity = 1.0;
    if (isInEdition()) {
      leading = InkWell(
        onTap: () {
          ic.selected = ic.selected ? false : true;
          updateItemCountableSelected();
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            "assets/images/fruit.png",
            width: imageSize,
            height: imageSize,
          ),
        ),
      );
    } else {
      leading = Checkbox(
          value: ic.isTaken(),
          onChanged: (bool? state) {
            ic.setTakenDB(state!, db);
            setState(() {});
          });
    }

    if (ic.isTaken()) {
      opacity = 0.5;
    }

    List<Widget> itemList = <Widget>[
      leading,
      Expanded(
        child: Opacity(
          opacity: opacity,
          child: Text(
            "${ic.amount} ${ic.item.name}",
          ),
        ),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Opacity(opacity: opacity, child: Text(ic.item.affiliation)),
          Opacity(opacity: opacity, child: Text(ic.item.location))
        ],
      ),
    ];
    return itemList;
  }

  Future<ItemCountable?> openDialogNewItemCountable(List<Widget> buttonList,
          {String title = "Ajouter un élement"}) =>
      showDialog<ItemCountable>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(title),
                content: SizedBox(
                  width: 200,
                  height: 200,
                  child: ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (BuildContext context, int i) {
                      ItemComposerDialog? itemICD = listICD[keys[i]];

                      return Card(
                        child: Row(
                          children: [
                            Text(
                              listICD[keys[i]]?.infoShort ?? "",
                              style: const TextStyle(fontSize: 16),
                            ),
                            SizedBox(
                              width: 170,
                              child: TextField(
                                autofocus: true,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                    hintText: listICD[keys[i]]?.hint ?? ""),
                                controller: itemICD?.controller,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                actions: buttonList,
              ));

  List<Widget> generateWidgetList(bool editing) {
    List<Widget> buttonList = <Widget>[];
    if (editing) {
      buttonList.add(TextButton(
          onPressed: () => {submitDialogIC(editing, rm: true)},
          child: const Text("SUPPRIMER")));
    }
    buttonList.addAll([
      TextButton(onPressed: cancelAddItemC, child: const Text("ANNULER")),
      TextButton(
          onPressed: () => {submitDialogIC(editing, confirm: true)},
          child: const Text("CONFIRMER")),
    ]);
    return buttonList;
  }

  void submitDialogIC(bool editing, {bool confirm = false, bool rm = false}) {
    print("ic = ${itemCChosen.id}");
    ItemCountable itemCountable = ItemCountable(
        itemCChosen.id,
        itemCChosen.taken,
        listICD["amo"]?.controller.text ?? "",
        Item(
            itemCChosen.item.id,
            listICD["nam"]?.controller.text ?? "",
            listICD["loc"]?.controller.text ?? "",
            listICD["aff"]?.controller.text ?? "",
            itemCChosen.item.timeUsed));

    if (confirm) {
      if ((listICD["nam"]?.controller.text ?? "").isEmpty) {
        SnackBar snackBar = const SnackBar(
            content: Text("Vous ne pouvez pas ajouter un élément vide"));
        showSnackBar(snackBar);
        return;
      }

      if (editing) {
        currentShopList.updateItemCountable(itemCChosen, itemCountable, db);
      } else {
        if (currentShopList.containsItemCountable(itemCountable)) {
          SnackBar snackBar =
              const SnackBar(content: Text("Élément déjà dans votre liste"));
          showSnackBar(snackBar);
          return;
        }
        print("dedans");
        currentShopList
            .addItemCountable(itemCountable, db)
            .then((value) => updateShopList());
      }
    } else if (rm) {
      print("élément à supprimer : $itemCountable");
      if (!currentShopList.containsItemCountable(itemCountable)) {
        SnackBar snackBar = const SnackBar(
          content: Text("Élément pas dans votre liste."),
        );
        showSnackBar(snackBar);
        return;
      }
      currentShopList.removeItem(itemCountable, db);
      SnackBar snackBar = SnackBar(
        content: Text("${itemCChosen.item.name} supprimé !"),
        action: SnackBarAction(
            label: "RESTAURER",
            onPressed: () => {
                  currentShopList.addItemCountable(itemCChosen, db),
                  setState(() {}),
                }),
      );
      showSnackBar(snackBar);
    }

    setState(() {});

    Navigator.of(context).pop(itemCountable);
    clearListICD();
  }

  void showSnackBar(SnackBar snackBar) {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void cancelAddItemC() {
    Navigator.of(context).pop(ItemCountable.none(Item.none()));
    clearListICD();
  }

  void clearListICD() {
    for (var o in listICD.keys) {
      listICD[o]?.controller.clear();
    }
  }

  void updateShopList() {
    db.init().then((value) =>
        db.getShopListFromName(super.widget.listName).then((value) async => {
              currentShopList = value,
              Future.delayed(const Duration(milliseconds: 50), () {})
                  .then((value) => setState(() {}))
            }));
  }

  void onLockerPressed() {
    appbarActions = [refresh, locker];
    if (isInEdition()) {
      locker =
          IconButton(icon: const Icon(Icons.lock), onPressed: onLockerPressed);
      currentWorking = "(lecture)";
    } else {
      currentWorking = "(édition)";
      locker = IconButton(
          icon: const Icon(Icons.lock_open), onPressed: onLockerPressed);
    }

    for (ItemCountable ic in currentShopList.itemCountableList) {
      ic.selected = false;
    }
    itemCountableSelected = false;

    setState(() {});
  }

  bool isInEdition() {
    return currentWorking == "(édition)";
  }

  void updateItemCountableSelected() {
    for (ItemCountable ic in currentShopList.itemCountableList) {
      if (ic.selected) {
        // another item selected previously
        if (appbarActions.length == 2) {
          appbarActions.insert(
              0,
              PopupMenuButton<DropdownItemsEnum>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) =>
                    List<PopupMenuEntry<DropdownItemsEnum>>.generate(
                        dropDownItemList.length, (index) {
                  DropDownItem dropDownItem = dropDownItemList[index];
                  return PopupMenuItem(
                    value: dropDownItem.dropdownItemsEnum,
                    child: Text(dropDownItem.text),
                  );
                }),
                onSelected: (DropdownItemsEnum dPIESelected) async {
                  switch (dPIESelected) {
                    case DropdownItemsEnum.remove:
                      itemRemovedOnce.clear();
                      for (ItemCountable ic2
                          in currentShopList.itemCountableList) {
                        if (ic2.selected) {
                          itemRemovedOnce.add(ic2);
                          print("Élémént à supprimer : ${ic2.item.name}");
                        }
                      }
                      print(itemRemovedOnce);
                      for (ItemCountable ic3 in itemRemovedOnce) {
                        await currentShopList.removeItem(ic3, db);
                      }
                      if (itemRemovedOnce.isNotEmpty) {
                        SnackBar snackBar = SnackBar(
                            content: const Text(
                                "Tous les élements ont été supprimés !"),
                            action: SnackBarAction(
                                label: "RESTAURER",
                                onPressed: () async {
                                  currentShopList
                                      .restoreAll(itemRemovedOnce, db)
                                      .then((value) => updateShopList());
                                }));
                        showSnackBar(snackBar);
                      }
                      itemCountableSelected = false;
                      setState(() {});
                      break;
                    case DropdownItemsEnum.makeAllTaken:
                      for (ItemCountable itemCountable
                          in currentShopList.itemCountableList) {
                        if (itemCountable.selected) {
                          itemCountable.setTakenDB(true, db);
                        }
                      }
                      setState(() {});
                      break;
                    case DropdownItemsEnum.makeAllNotTaken:
                      for (ItemCountable itemCountable
                          in currentShopList.itemCountableList) {
                        if (itemCountable.selected) {
                          itemCountable.setTakenDB(false, db);
                        }
                      }
                      setState(() {});
                      break;
                  }
                },
              ));
          /*appbarActions.insert(
              1,
              IconButton(
                  onPressed: () {
                    print("more");
                  },
                  icon: const Icon(Icons.more_vert)));*/
        }
        itemCountableSelected = true;

        return;
      }
    }
    // no more items selected
    appbarActions = [refresh, locker];
    itemCountableSelected = false;
  }
}
