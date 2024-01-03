import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/shop_list/models/shop_list_popup_return.dart';
import 'package:useful_app/shop_list/pages/shop_list_manager_page.dart';
import 'package:useful_app/shop_list/pages/settings_page.dart';
import 'package:useful_app/utils/popup_shower.dart';
import 'package:useful_app/utils/tools.dart';

class ShopListMain extends StatefulWidget {
  const ShopListMain({Key? key}) : super(key: key);

  @override
  State<ShopListMain> createState() => _ShopListState();
}

class _ShopListState extends State<ShopListMain> {
  late TextEditingController listNameController;
  bool goToEditShopList = true;

  DataBaseManager db = DataBaseManager();
  List<ShopList> allList = [];
  Offset _tapPosition = Offset.zero;
  ShopList shopListRemoved = ShopList.none();

  void updateAllLists() {
    db.init().then(
          (value) => db.getAllLists().then((value) => {
                allList = value,
                setState(() {}),
              }),
        );
  }

  @override
  void initState() {
    listNameController = TextEditingController();
    updateAllLists();
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Tools.generateAppBar(const Text("ShopList"), actions: [
        IconButton(
            onPressed: () => {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const ShopListSettings()))
                },
            icon: const Icon(Icons.settings))
      ]),
      body: ListView.builder(
        itemCount: allList.length,
        itemBuilder: (BuildContext context, int index) {
          ShopList curList = allList[index];
          final RenderObject? overlay =
              Overlay.of(context).context.findRenderObject();

          return Card(
            child: GestureDetector(
              onTapDown: _getTapPosition,
              child: ListTile(
                title: Text(curList.name),
                subtitle: Text(DateFormat("EEEE dd MMMM yyyy")
                    .format(curList.creationDate)),
                onTap: () => {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              ShopListManager(curList.name)))
                },
                onLongPress: () async {
                  final res = await showMenu(
                      context: context,
                      position: RelativeRect.fromRect(
                          Rect.fromLTWH(
                              _tapPosition.dx, _tapPosition.dy, 30, 30),
                          Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                              overlay.paintBounds.size.height)),
                      items: [
                        const PopupMenuItem(
                          value: "remove",
                          child: Text("Supprimer"),
                        ),
                        const PopupMenuItem(
                          value: "read",
                          child: Text("Lire"),
                        ),
                        const PopupMenuItem(
                          value: "edit_content",
                          child: Text("Modifier le contenu"),
                        ),
                        const PopupMenuItem(
                          value: "edit_list",
                          child: Text("Modifier la liste"),
                        )
                      ]);

                  switch (res) {
                    case "remove":
                      shopListRemoved = allList.removeAt(index);
                      db.deleteShopList(shopListRemoved.id).then((value) {
                        if (value <= -1) {
                          Tools.showNormalSnackBar(context,
                              "Une erreur est survenue il se peut que la liste ne soit pas supprimée.");
                        } else {
                          SnackBar snackBar = SnackBar(
                            content: const Text("Liste supprimée !"),
                            action: SnackBarAction(
                                label: "RESTAURER",
                                onPressed: () async {
                                  db.addList(shopListRemoved).then((v) {
                                    if (v <= -1) {
                                      Tools.showNormalSnackBar(context,
                                          "Une erreur est survenue lors de la restauration de votre liste.");
                                    } else {
                                      Tools.showNormalSnackBar(
                                          context, "Liste restaurée");
                                      updateAllLists();
                                    }
                                  });
                                }),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                        updateAllLists();
                      });

                      break;

                    case "read":
                      goToShopListManager(curList.name, false);
                      break;
                    case "edit_content":
                      goToShopListManager(curList.name, true);
                      break;
                    case "edit_list":
                      ShopListPopupReturn? ret = await openDialogShopList(
                          "", false, curList, PopupState.edit);
                      if (ret == null) {
                        return;
                      }

                      db.setShopListName(curList.name, ret.value).then((v) {
                        if (v <= -1) {
                          Tools.showNormalSnackBar(context,
                              "Une erreur est survenue de la modification de la liste.");
                        } else {
                          updateAllLists();
                        }
                      });
                      break;
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Ajouter une liste",
        onPressed: () async {
          listNameController.clear();
          int i = 1;
          String defaultListName = "liste + $i";
          bool nameListAvailable = false, nameListIsIn;
          while (!nameListAvailable) {
            defaultListName = "liste $i";
            nameListIsIn = false;
            for (ShopList shopList in allList) {
              if (shopList.name == defaultListName) {
                nameListIsIn = true;
                break;
              }
            }
            nameListAvailable = nameListIsIn == false;
            i++;
          }
          ShopListPopupReturn? popupRet = await openDialogShopList(
              defaultListName, true, null, PopupState.adding);

          if (popupRet == null) return;
          if (popupRet.value.isEmpty) {
            popupRet.value = defaultListName;
          }

          db
              .addList(ShopList(
                  0, popupRet.value, DateTime.now(), DateTime.now(), []))
              .then((id) {
            if (id <= -1) {
              Tools.showNormalSnackBar(context,
                  "Une erreur est survenue, il est impossible de créer la liste.");
            } else {
              if (popupRet.goToEdit) {
                goToShopListManager(popupRet.value, true);
              }
              // allList
              // .add(ShopList(id, name!, DateTime.now(), DateTime.now(), []));
              updateAllLists();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<ShopListPopupReturn?> openDialogShopList(
      String hintText, bool showCheckBox, ShopList? sl, PopupState state) {
    String validateText = "";
    switch (state) {
      case PopupState.adding:
        validateText = "AJOUTER";
        break;
      default:
        validateText = "CONFIRMER";
    }
    if (sl != null) {
      listNameController.text = sl.name;
      hintText = sl.name;
    }

    return showDialog<ShopListPopupReturn>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setS) => AlertDialog(
                title: const Text("Ajouter une liste de course"),
                content: Column(children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(hintText: hintText),
                    controller: listNameController,
                  ),
                  if (showCheckBox)
                    Row(
                      children: [
                        Checkbox(
                          value: goToEditShopList,
                          onChanged: (bool? v) {
                            setS(() {
                              if (v != null) {
                                goToEditShopList = v;
                              }
                            });
                          },
                        ),
                        const Expanded(
                            child: Text(
                          "Poursuivre la création de la liste vers la création du contenu",
                          maxLines: 5,
                        )),
                      ],
                    )
                ]),
                actions: [
                  TextButton(onPressed: dismiss, child: const Text("ANNULER")),
                  TextButton(onPressed: submit, child: Text(validateText))
                ],
              ),
            ));
  }

  void submit() {
    if (isShopListNameUsed(listNameController.text)) {
      SnackBar snackBar = const SnackBar(
        content: Text("Nom de liste déjà utilisé !!"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      Navigator.of(context)
          .pop(ShopListPopupReturn(listNameController.text, goToEditShopList));
    }
  }

  bool isShopListNameUsed(String name) {
    return allList.map((list) => list.name).contains(name);
  }

  void dismiss() {
    Navigator.of(context).pop(null);
  }

  void goToShopListManager(String name, bool editing) {
    print("ediing = $editing");
    Navigator.push(
        context,
        PageRouteBuilder(
            pageBuilder: (_, __, ___) => ShopListManager(
                  name,
                  editing: editing,
                )));
    return;
  }

  void _getTapPosition(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _tapPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }
}
