import 'package:flutter/material.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/shop_list/models/widgets/list_hidder.dart';
import 'package:useful_app/shop_list/pages/shop_list_manager/dismissible_manager.dart';
import 'package:useful_app/utils/popup_shower.dart';
import 'package:useful_app/utils/tools.dart';

const IconData iconEdition = Icons.edit;
const IconData iconRead = Icons.play_arrow;

const List<Widget> showValuesAdvanced = [
  Text("Tout"),
  Text("pris"),
  Text("non pris")
];

class ShopListManager extends StatefulWidget {
  final String listName;
  final bool editing = true;

  const ShopListManager(this.listName, {Key? key, bool editing = true})
      : super(key: key);

  @override
  State<ShopListManager> createState() => _ShopListManagerState();
}

enum DropdownItemsEnum { makeAllTaken, makeAllNotTaken, remove, none, advanced }

class DropDownItem {
  String text;
  DropdownItemsEnum dropdownItemsEnum;

  DropDownItem(this.text, this.dropdownItemsEnum);
}

class _ShopListManagerState extends State<ShopListManager> {
  final DataBaseManager db = DataBaseManager();
  ShopList currentShopList = ShopList.none();
  ItemCountable itemCChosen = ItemCountable.none(Item.none());
  List<Item> itemList = [];

  String currentWorking = "(édition)";

  List<ItemCountable> itemSelectedOnce = <ItemCountable>[];

  final List<DropDownItem> dropDownItemListSelection = <DropDownItem>[
    DropDownItem("Marquer comme pris", DropdownItemsEnum.makeAllTaken),
    DropDownItem("Marquer comme non pris", DropdownItemsEnum.makeAllNotTaken),
    DropDownItem("Supprimer", DropdownItemsEnum.remove),
  ];

  IconButton locker =
      const IconButton(icon: Icon(iconEdition), onPressed: null);

  late PopupMenuButton moreIconDropdown;

  Map<String, String> itemCContent = {};
  List<Widget> appbarActions = [];

  int nbSelected = 0;

  List<bool> showBAEditionSelected = [true, false, false];
  ItemCountableSelection iCSelectEdition = ItemCountableSelection.all;

  List<bool> showBAReadingSelected = [false, false, true];
  ItemCountableSelection iCSelectReading = ItemCountableSelection.notTaken;

  bool overwriteDisplay = false;
  List<bool> showBAGeneralSelected = [true, false, false];
  ItemCountableSelection iCSelectGeneral = ItemCountableSelection.all;

  Widget? backgroundTiles;

  /// update shoplist from Database, set CurrentItemCountable from local variables, then set state
  void updateShopList() {
    db.init().then((value) => {
          db.getShopListFromName(super.widget.listName).then((value) {
            currentShopList = value;
            updateCurrentItemCountableListFromLocal();
            setState(() {});
          }),
        });
  }

  void updateItemsList() {
    db.init().then((value) {
      db.getAllItem().then((value) {
        itemList = value;
        setState(() {});
      });
    });
  }

  void updateCurrentItemCountableListFromLocal(
      {ItemCountableSelection? selection}) {
    currentShopList.setCurrentItemCountableList(
        selection: overwriteDisplay
            ? iCSelectGeneral
            : (selection ??
                (isInEdition() ? iCSelectEdition : iCSelectReading)));
  }

  @override
  void initState() {
    setDropdownMore(states: []);
    updateShopList();
    updateItemsList();
    locker = IconButton(
        icon: const Icon(iconEdition),
        onPressed: () => {
              onLockerPressed(),
            });
    appbarActions = [moreIconDropdown, locker];
    setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          itemCount: currentShopList.getCurrentItemCountableList().length,
          itemBuilder: (BuildContext context, int index) {
            ItemCountable ic =
                currentShopList.getCurrentItemCountableList()[index];
            ShapeBorder? shapeBorder;
            Color? color;
            if (ic.selected) {
              /*shapeBorder = Border.all(
                  color: Colors.red, width: 1, strokeAlign: StrokeAlign.inside);*/
              color = Colors.indigoAccent;
            }
            return Dismissible(
              onUpdate: (details) => setState(() => backgroundTiles =
                  DismissibleManager.getDismissibleBackground(
                      details: details,
                      isInEdition: isInEdition(),
                      iCSelectEdition: iCSelectEdition,
                      iCSelectReading: iCSelectReading)),
              background: backgroundTiles,
              direction: DismissibleManager.getDismissDirection(
                  isInEdition: isInEdition(),
                  iCSelectEdition: iCSelectEdition,
                  iCSelectReading: iCSelectReading),
              onDismissed: (DismissDirection direction) =>
                  DismissibleManager.onDissmissed(
                      removeItemC: removeItemC,
                      direction: direction,
                      isInEdition: isInEdition(),
                      currentShopList: currentShopList,
                      ic: ic,
                      db: db,
                      updateShopList: updateShopList,
                      context: context,
                      iCSelectReading: iCSelectReading),
              key: Key(ic.id.toString()),
              child: Card(
                shape: shapeBorder,
                color: color,
                child: InkWell(
                  onTap: () async {
                    // modify itemC
                    if (isInEdition() && nbSelected == 0) {
                      itemCChosen = ic;
                      await PopupShower.openDialogItemCountable(
                          namesInList: currentShopList
                              .getCurrentItemCountableList()
                              .map((e) => e.item.name)
                              .toList(),
                          showItemListPopup: false,
                          itemList: itemList,
                          context,
                          ic,
                          callbackDialogIC,
                          canRemove: true,
                          editing: true,
                          title: "Édition d'un élément");
                    }
                    // add itemC to selection
                    else if (nbSelected != 0 && isInEdition()) {
                      nbSelected += ic.selected ? -1 : 1;
                      ic.selected = !ic.selected;
                      setDropdownMore(states: ["selection"]);
                      setState(() {});
                    }
                  },
                  onLongPress: () {
                    if (isInEdition()) {
                      nbSelected += ic.selected ? -1 : 1;
                      ic.selected = !ic.selected;
                      setDropdownMore(states: ["selection"]);
                      setState(() {});
                    }
                  },
                  child: SizedBox(
                    height: 50,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Row(children: buildItemListTile(ic))),
                  ),
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await PopupShower.openDialogItemCountable(
              namesInList: currentShopList
                  .getCurrentItemCountableList()
                  .map((e) => e.item.name)
                  .toList(),
              itemList: itemList,
              context,
              null,
              callbackDialogIC,
              canRemove: false,
              editing: false,
              showItemListPopup: true);
        },
        tooltip: "Ajouter un élément",
        child: const Icon(Icons.add),
      ),
      /* drawer: Drawer(
        child: Container(
          margin: const EdgeInsets.only(top: 50),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const BackButton(),
              TextButton(
                onPressed: () => {
                  Navigator.pop(context),
                },
                child: const Text("coucou"),
              ),
              const SizedBox(
                  height: 50,
                  child: DrawerHeader(
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text("Nom de la list")))
            ],
          ),
        ),
      ), */
    );
  }

  bool canRemove() {
    return isInEdition();
  }

  List<Widget> buildItemListTile(ItemCountable ic) {
    Widget leading;
    double imageSize = 40, opacity = 1.0;
    if (isInEdition()) {
      leading = InkWell(
        onTap: () {
          nbSelected += ic.selected ? -1 : 1;
          ic.selected = !ic.selected;
          setDropdownMore(states: ["selection"]);
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
            ic.setTakenDB(state!, db).then((value) {
              if (value <= -1) {
                Tools.showNormalSnackBar(context,
                    "Une erreur est survenue lors de l'édition de l'élément.");
              }
              updateShopList();
            });
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

  /// if true returned, dialog can be closed otherwise dialog stay open
  Future<bool> callbackDialogIC(
      PopupAction popupAction, ItemCountable itemCountable) async {
    switch (popupAction) {
      case PopupAction.add:
        if (currentShopList.containsItemCountable(itemCountable)) {
          Tools.showNormalSnackBar(context, "Élément déjà dans votre liste");
          return false;
        }
        return currentShopList
            .addItemCountable(itemCountable, db)
            .then((value) {
          if (value <= -1) {
            Tools.showNormalSnackBar(context,
                "Une erreur est survenue, il est possible que l'élément n'ai pas été ajouté.");
            updateShopList();
            updateItemsList();
            return false;
          }
          updateItemsList();
          updateShopList();
          return true;
        });
      case PopupAction.remove:
        return removeItemC(itemCountable);
      case PopupAction.edit:
        return currentShopList
            .updateItemCountable(itemCChosen, itemCountable, db)
            .then((value) {
          if (value <= -1) {
            Tools.showNormalSnackBar(context,
                "Une erreur est survenue, il se peut aue votre élément ne soit pas édité.");
            setState(() {});
            return false;
          }
          return true;
        });
    }
  }

  void onLockerPressed() {
    // pass to reading
    if (isInEdition()) {
      locker =
          IconButton(icon: const Icon(iconRead), onPressed: onLockerPressed);
      currentWorking = "(lecture)";
    }
    // pass to edition
    else {
      currentWorking = "(édition)";
      locker =
          IconButton(icon: const Icon(iconEdition), onPressed: onLockerPressed);
    }

    for (ItemCountable ic in currentShopList.getCurrentItemCountableList()) {
      ic.selected = false;
    }
    nbSelected = 0;
    appbarActions = [moreIconDropdown, locker];

    updateCurrentItemCountableListFromLocal();
    setState(() {});
  }

  /// check if the person is at a state where he can add items
  bool isInEdition() {
    return currentWorking == "(édition)";
  }

  /// callback for when a item of More Icon is selected
  Future<void> onMoreSelected(DropdownItemsEnum dPIESelected) async {
    switch (dPIESelected) {
      case DropdownItemsEnum.remove:
        setItemsCSelectedOnce();
        currentShopList
            .removeItemCountableList(itemSelectedOnce, db)
            .then((value) {
          if (value <= -1) {
            Tools.showNormalSnackBar(context,
                'Une erreur est survenue, il se peut que tous les éléments ne soient pas supprimés, value : $value');
          } else {
            if (itemSelectedOnce.isNotEmpty) {
              Tools.showNormalSnackBar(
                  context, "Tous les élements ont été supprimés !",
                  snackBarAction: SnackBarAction(
                      label: "RESTAURER",
                      onPressed: () async {
                        currentShopList
                            .restoreAll(itemSelectedOnce, db)
                            .then((value) => updateShopList());
                      }));
            }
          }
          setState(() {});
        });
        nbSelected = 0;
        break;
      case DropdownItemsEnum.makeAllTaken:
        setItemsCSelectedOnce();
        currentShopList
            .setTakenAll(
                db,
                itemSelectedOnce.isNotEmpty
                    ? itemSelectedOnce
                    : currentShopList.getCurrentItemCountableList(),
                true)
            .then((value) {
          if (value <= -1) {
            Tools.showNormalSnackBar(context,
                "Une errer est survenue, il se peut que tous les éléments ne soient pas marqués comme pris.");
          }
          unselectAll();
          setState(() {});
        });
        break;
      case DropdownItemsEnum.makeAllNotTaken:
        setItemsCSelectedOnce();
        currentShopList
            .setTakenAll(
                db,
                itemSelectedOnce.isNotEmpty
                    ? itemSelectedOnce
                    : currentShopList.getCurrentItemCountableList(),
                false)
            .then((value) {
          if (value <= -1) {
            Tools.showNormalSnackBar(context,
                "Une erreur est survenue, il se peut que tous les éléments ne soient pas marqués comme non pris.");
          }
          unselectAll();
          setState(() {});
        });

        break;
      case DropdownItemsEnum.advanced:
        showAdvancedPopup();
        break;
      case DropdownItemsEnum.none:
        break;
    }
  }

  Future<void> showAdvancedPopup() async {
    const double width = 80;
    showDialog(
        context: context,
        builder: ((context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text("Paramètres avancés"),
                content: SizedBox(
                  height: 500,
                  width: width,
                  child: ListView(
                    children: [
                      if (nbSelected != 0)
                        ListHidder(title: "Sélection", widgetList: [
                          ElevatedButton(
                              onPressed: () {
                                onMoreSelected(DropdownItemsEnum.remove);
                                Navigator.of(context).pop();
                              },
                              child: const Text("Supprimer la sélection")),
                          ElevatedButton(
                              onPressed: () {
                                onMoreSelected(DropdownItemsEnum.makeAllTaken);
                                Navigator.of(context).pop();
                              },
                              child: const Text("Marquer comme pris")),
                          ElevatedButton(
                              onPressed: () {
                                onMoreSelected(
                                    DropdownItemsEnum.makeAllNotTaken);
                                Navigator.of(context).pop();
                              },
                              child: const Text("Marquer comme non pris"))
                        ]),
                      ListHidder(
                        title: "En général",
                        widgetList: [
                          ElevatedButton(
                            child: const Text("Vider la liste"),
                            onPressed: () async {
                              bool? confirmation =
                                  await PopupShower.buildConfirmAction(
                                      context,
                                      "Suppression de tous les éléments",
                                      "Êtes-vous sûr de vouloir supprimer tous les élements de la liste ?");
                              if (confirmation != null && confirmation) {
                                currentShopList.purge(db).then((value) {
                                  if (value <= -1) {
                                    Tools.showNormalSnackBar(context,
                                        "Une erreur est survenue, il se peut que des éléments ne soient pas supprimés.");
                                  }
                                  updateShopList();
                                  Navigator.of(context).pop();
                                });
                              }
                            },
                          ),
                          ElevatedButton(
                            child: const Text("Supprimer tous les pris"),
                            onPressed: () async {
                              bool? confirmation =
                                  await PopupShower.buildConfirmAction(
                                      context,
                                      "Suppression de tous les pris",
                                      "Êtes-vous sûr de vouloir supprimer tous les pris ?");
                              if (confirmation != null && confirmation) {
                                currentShopList
                                    .removeTaken(true, db)
                                    .then((value) {
                                  if (value <= -1) {
                                    Tools.showNormalSnackBar(context,
                                        "Une erreur est survenue, il se peut que des élément ne soient pas supprimés.");
                                  }
                                  updateShopList();
                                  Navigator.of(context).pop();
                                });
                              }
                            },
                          ),
                          SizedBox(
                            height: 20,
                            child: Row(
                              children: [
                                const Text("Écraser "),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Switch(
                                        value: overwriteDisplay,
                                        onChanged: (bool v) => setState(() {
                                              overwriteDisplay = v;
                                              updateCurrentItemCountableListFromLocal();
                                            })),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...buildDisplay(showBAGeneralSelected, width,
                              (int i) {
                            {
                              setState(() {
                                for (int x = 0;
                                    x < showBAGeneralSelected.length;
                                    x++) {
                                  showBAGeneralSelected[x] = (x == i);
                                }
                              });
                              iCSelectGeneral =
                                  getICSCallbackDisplay(showBAGeneralSelected);

                              updateCurrentItemCountableListFromLocal(
                                  selection: iCSelectGeneral);
                            }
                          }, rightMore: null)
                        ],
                      ),
                      ListHidder(
                        title: "Lors de l'édition",
                        widgetList: [
                          ...buildDisplay(
                            showBAEditionSelected,
                            width,
                            (int i) {
                              {
                                setState(() {
                                  for (int x = 0;
                                      x < showBAEditionSelected.length;
                                      x++) {
                                    showBAEditionSelected[x] = (x == i);
                                  }
                                  iCSelectEdition = getICSCallbackDisplay(
                                      showBAEditionSelected);
                                  updateCurrentItemCountableListFromLocal(
                                      selection: iCSelectEdition);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      ListHidder(
                        title: "Lors de la lecture",
                        widgetList: [
                          ...buildDisplay(
                            showBAReadingSelected,
                            width,
                            (int i) {
                              {
                                setState(() {
                                  for (int x = 0;
                                      x < showBAReadingSelected.length;
                                      x++) {
                                    showBAReadingSelected[x] = (x == i);
                                  }
                                  iCSelectReading = getICSCallbackDisplay(
                                      showBAReadingSelected);
                                  updateCurrentItemCountableListFromLocal(
                                      selection: iCSelectReading);
                                });
                              }
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text("FERMER"))
                ],
              ),
            ))).then((value) => setState(() {}));
  }

  ItemCountableSelection getICSCallbackDisplay(List<bool> booList) {
    // all
    if (booList[0]) {
      return ItemCountableSelection.all;
    }
    // taken
    else if (booList[1]) {
      return ItemCountableSelection.taken;
    }
    // not taken
    else {
      return ItemCountableSelection.notTaken;
    }
  }

  List<Widget> buildDisplay(
      List<bool> boolList, double width, void Function(int) callback,
      {Widget? rightMore}) {
    return [
      SizedBox(
          height: 40,
          child: Row(
            children: [
              Text(
                "Affichage".toUpperCase(),
                style: const TextStyle(fontSize: 14),
              ),
              if (rightMore != null) Expanded(child: rightMore)
            ],
          )),
      ToggleButtons(
          constraints: BoxConstraints.expand(width: width - 10),
          direction: Axis.horizontal,
          isSelected: boolList,
          onPressed: callback,
          children: showValuesAdvanced)
    ];
  }

  void unselectAll() {
    for (ItemCountable ic in currentShopList.getCurrentItemCountableList()) {
      ic.selected = false;
    }
  }

  /// set IC from their selection because itemSelectedOnce is not upadadte outside of this function
  void setItemsCSelectedOnce() {
    itemSelectedOnce.clear();
    for (ItemCountable ic2 in currentShopList.getCurrentItemCountableList()) {
      if (ic2.selected) {
        itemSelectedOnce.add(ic2);
      }
    }
  }

  /// setup the more dropdown
  /// Different types available for [state] (selection)
  void setDropdownMore({required List<String> states}) {
    List<DropDownItem> moreList = [
      DropDownItem("Avancé", DropdownItemsEnum.advanced)
    ];
    if (states.contains("selection")) {
      moreList.addAll(dropDownItemListSelection);
    }
    moreIconDropdown = PopupMenuButton<DropdownItemsEnum>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) =>
          List<PopupMenuEntry<DropdownItemsEnum>>.generate(moreList.length,
              (index) {
        DropDownItem dropDownItem = moreList[index];
        return PopupMenuItem(
          value: dropDownItem.dropdownItemsEnum,
          child: Text(dropDownItem.text),
        );
      }),
      onSelected: (DropdownItemsEnum dPIESelected) async {
        onMoreSelected(dPIESelected);
      },
    );
    appbarActions = [moreIconDropdown, locker];
    setState(() {});
  }

  bool removeItemC(ItemCountable itemCountable) {
    if (!currentShopList.containsItemCountable(itemCountable)) {
      Tools.showNormalSnackBar(
        context,
        "Élément pas dans votre liste.",
      );
      return false;
    }

    currentShopList.removeItem(itemCountable, db).then((value) {
      if (value <= -1) {
        Tools.showNormalSnackBar(context,
            "Une erreur est survenue, il se peut que l'élément ne soit pas supprimé.");
      } else {
        updateShopList();
        Tools.showNormalSnackBar(
            context, "${itemCountable.item.name} supprimé !",
            snackBarAction: SnackBarAction(
                label: "RESTAURER",
                onPressed: () => {
                      currentShopList
                          .addItemCountable(itemCountable, db)
                          .then((value) {
                        if (value <= -1) {
                          Tools.showNormalSnackBar(context,
                              "Une erreur est survenue, il soit possible que l'élément ne soit pas restauré.");
                        }
                        updateShopList();
                      }),
                    }));
      }
    });
    setState(() {});
    return true;
  }
}
