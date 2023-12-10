import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/shop_list/pages/shop_list_manager_page.dart';
import 'package:useful_app/shop_list/pages/settings_page.dart';
import 'package:useful_app/utils/tools.dart';

class ShopListMain extends StatefulWidget {
  const ShopListMain({Key? key}) : super(key: key);

  @override
  State<ShopListMain> createState() => _ShopListState();
}

class _ShopListState extends State<ShopListMain> {
  late TextEditingController listNameController;
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
                subtitle:
                    Text(DateFormat("EEEE dd MMMM yyyy").format(curList.creationDate)),
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
                          value: "edit",
                          child: Text("Modifier"),
                        )
                      ]);

                  switch (res) {
                    case "remove":
                      shopListRemoved = allList.removeAt(index);
                      db.deleteShopList(shopListRemoved.id).then((value) {
                        if (value <= -1) {
                          Tools.showNormalSnackBar(context,
                              "Une erreur est survenuen il se peut que la liste ne soit pas supprimée.");
                        } else {
                          SnackBar snackBar = SnackBar(
                            content: const Text("Liste supprimée !"),
                            action: SnackBarAction(
                                label: "RESTAURER",
                                onPressed: () async => {
                                      // TODO restore here is inexistenct
                                      // await db.restoreShopList(shopListRemoved),
                                    }),
                          );
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                        updateAllLists();
                        setState(() {});
                      });

                      break;

                    case "read":
                      goToShopListManager(curList.name, false);
                      break;
                    case "edit":
                      goToShopListManager(curList.name, true);
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
          String listName = "liste + $i";
          bool nameListAvailable = false, nameListIsIn;
          while (!nameListAvailable) {
            listName = "liste $i";
            nameListIsIn = false;
            for (ShopList shopList in allList) {
              if (shopList.name == listName) {
                nameListIsIn = true;
                break;
              }
            }
            nameListAvailable = nameListIsIn == false;
            i++;
          }
          String? name = await openDialogNewList(listName);

          if (name == null) return;
          if (name.isEmpty) {
            name = listName;
          }

          db
              .addList(ShopList(0, name, DateTime.now(), DateTime.now(), []))
              .then((id) {
            if (id <= -1) {
              Tools.showNormalSnackBar(context,
                  "Une erreur est survenue, il est impossible de créer la liste.");
            } else {
              allList
                  .add(ShopList(id, name!, DateTime.now(), DateTime.now(), []));
              goToShopListManager(name, true);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> openDialogNewList(String hintText) => showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text("Ajouter une liste de course"),
            content: TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: hintText),
              controller: listNameController,
            ),
            actions: [
              TextButton(onPressed: dismiss, child: const Text("ANNULER")),
              TextButton(onPressed: submit, child: const Text("AJOUTER"))
            ],
          ));

  void submit() {
    bool nameOfListUsed = false;
    for (ShopList shopList in allList) {
      if (shopList.name == listNameController.text) {
        nameOfListUsed = true;
        break;
      }
    }
    if (nameOfListUsed) {
      SnackBar snackBar = const SnackBar(
        content: Text("Nom de liste déjà utilisé !!"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      Navigator.of(context).pop(listNameController.text);
    }
  }

  void dismiss() {
    Navigator.of(context).pop(null);
  }

  void goToShopListManager(String name, bool editing) {
    Navigator.push(
        context,
        PageRouteBuilder(
            pageBuilder: (_, __, ___) => ShopListManager(
                  name,
                  editing: editing,
                )));
  }

  void _getTapPosition(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _tapPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }
}
