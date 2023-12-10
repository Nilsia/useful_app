import 'package:flutter/material.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_composer_dialog.dart';
import 'package:useful_app/shop_list/models/widgets/listview_item_composer_builder.dart';
import 'package:useful_app/shop_list/utils/item_list_view_builder.dart';
import 'package:useful_app/utils/tools.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  DataBaseManager db = DataBaseManager();
  List<Item> itemList = [];

  @override
  void initState() {
    db.init().then((value) {
      db.getAllItem().then((value) {
        itemList = value;
        setState(() {});
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Tools.generateAppBar(const Text("Liste des éléments")),
      body: ItemListViewBuilder(itemList: itemList, callback: callback),
    );
  }

  Future<void> callback(Item item) async {
    List<String> keys = ["nam", "aff", "loc"];
    Map<String, ItemComposer> listIC = {
      "nam": ItemComposer("Nom : ", "Nom de l'élement",
          TextEditingController(text: item.name), "Nom : ",
          autofocus: false),
      "aff": ItemComposer("Appartenance : ", "Appartenance",
          TextEditingController(text: item.affiliation), "Apt : "),
      "loc": ItemComposer("Emplacement : ", "Emplacement",
          TextEditingController(text: item.location), "Emp : "),
    };
    return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Édition de l'élément."),
              content: SizedBox(
                  child: ListviewItemComposerBuilder(
                callback: (index) {},
                listIC: listIC,
                keys: keys,
              )),
              actions: [
                // DELETE button
                TextButton(
                    onPressed: () {
                      db.deleteItem(item).then((value) {
                        if (value <= -1) {
                          Tools.showNormalSnackBar(context,
                              "Une erreur est survenue, il est possible que l'élément n'ai pas été supprimé");
                        } else {
                          Tools.showNormalSnackBar(
                              context, "L'élément a été supprimé avec succès",
                              snackBarAction: SnackBarAction(
                                  label: "Restaurer",
                                  onPressed: () {
                                    db.addItem(item).then((value) {
                                      if (value <= -1) {
                                        Tools.showNormalSnackBar(context,
                                            "L'élément a été restauré avec succès");
                                      } else {
                                        Tools.showNormalSnackBar(context,
                                            "Une erreur est survenue, il se peut que votre élément ne soit pas restauré.");
                                      }
                                      setState(() {});
                                    });
                                  }));
                        }
                        setState(() {});
                      });
                    },
                    child: const Text("SUPPRIMER")),
                TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text("ANNULER")),
                TextButton(
                    onPressed: () {
                      if (listIC["name"]!.controller.text.trim().isEmpty) {
                        Tools.showNormalSnackBar(context,
                            "Vous ne poyvez pas fournir une nom d'élément vide.");
                        return;
                      }
                      db
                          .updateItem(
                              item,
                              item.clone(
                                  listIC["nam"]!.controller.text.trim(),
                                  listIC["loc"]!.controller.text.trim(),
                                  listIC["aff"]!.controller.text.trim(),
                                  null))
                          .then((value) {
                        if (value <= -1) {
                          Tools.showNormalSnackBar(context,
                              "Une erreur est survenue, il se peut que l'élément n'ai pas été édité.");
                        }
                        setState(() {});
                      });
                    },
                    child: const Text("CONFIRMER"))
              ],
            ));
  }
}
