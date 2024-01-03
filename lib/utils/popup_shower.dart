import 'package:flutter/material.dart';
import 'package:useful_app/constants.dart' as constants;
import 'package:useful_app/shop_list/models/item.dart';
import 'package:useful_app/shop_list/models/item_composer_dialog.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/widgets/listview_item_composer_builder.dart';
import 'package:useful_app/shop_list/utils/item_list_view_builder.dart';
import 'package:useful_app/utils/tools.dart';

enum PopupState { edit, remove, adding }

class PopupShower {
  static Future<void> openDialogItemCountable(
      BuildContext context,
      ItemCountable? ic,
      Future<bool> Function(PopupAction, ItemCountable) callback,
      {String title = "Ajouter un élement",
      required bool canRemove,
      required bool editing,
      required List<Item> itemList,
      required showItemListPopup,
      required List<String> namesInList}) async {
    List<String> keys = ["nam", "amo", "aff", "loc"];
    Map<String, ItemComposer> listIC = {
      "nam": ItemComposer(
          "Nom : ", "Nom de l'élement", TextEditingController(), "Nom : ",
          autofocus: false),
      "amo": ItemComposer(
          "Quantité : ", "Quantité", TextEditingController(), "Qtd : ",
          autofocus: true),
      "aff": ItemComposer(
          "Appartenance : ", "Appartenance", TextEditingController(), "Apt : "),
      "loc": ItemComposer(
          "Emplacement : ", "Emplacement", TextEditingController(), "Emp : "),
    };
    return await showItemListChooserPopup(
            namesAlreadyInList: namesInList,
            preset: '',
            context: context,
            itemList: itemList,
            autoCancel: !showItemListPopup || editing)
        .then((value) async {
      if (value == null) {
        return;
      }
      // on add value is empty and as to show popup
      // if (value.isEmpty && showItemListPopup) {
      // print("coucou");
      // return;
      // }
      listIC[keys[0]]!.controller.text = value;
      if (ic != null) {
        Map<String, String> map = ic.toMapContent(strLen: 3);
        listIC.forEach((String key, ItemComposer value) {
          if (map.containsKey(key)) {
            value.controller.text = map[key] ?? "";
          }
        });
      }

      List<Widget> buttonList = <Widget>[];

      // add remove button if necessery
      if (canRemove && ic != null) {
        buttonList.add(TextButton(
            onPressed: () async => {
                  if (await callback(PopupAction.remove, ic))
                    {Navigator.of(context).pop()}
                },
            child: const Text(
              "SUPPRIMER",
              style: TextStyle(color: constants.removeButtonColor),
            )));
      }

      buttonList
          .add(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text(
              "ANNULER",
              style: TextStyle(color: constants.cancelButtonColor),
            )),
        TextButton(
            onPressed: () async {
              if (listIC['nam']!.controller.text.trim().isNotEmpty) {
                Item item = Item(
                    ic == null ? -1 : ic.item.id,
                    listIC['nam']!.controller.text.trim(),
                    listIC['loc']!.controller.text.trim(),
                    listIC['aff']!.controller.text.trim(),
                    ic == null ? 0 : ic.item.timeUsed);

                ItemCountable itemC = ItemCountable(
                    -1, false, listIC['amo']!.controller.text.trim(), item, -1);
                if (ic != null) {
                  itemC.id = ic.id;
                  itemC.setTaken(ic.taken);
                  itemC.setShopListRef(ic.shopListRef);
                }
                callback(editing ? PopupAction.edit : PopupAction.add, itemC)
                    .then((value) {
                  if (value) {
                    Navigator.of(context).pop();
                  }
                });
              }
            },
            child: const Text(
              "CONFIRMER",
              style: TextStyle(color: constants.confirmButtonColor),
            )),
      ]));

      return await showDialog(
          context: context,
          builder: (context) =>
              StatefulBuilder(builder: (BuildContext context, setState) {
                return AlertDialog(
                  title: Text(title),
                  content: SizedBox(
                      width: 500,
                      height: 300,
                      child: ListView(
                        children: [
                          SizedBox(
                            width: 500,
                            height: 220,
                            child: ListviewItemComposerBuilder(
                                keys: keys,
                                listIC: listIC,
                                callback: (int index) {
                                  // get only the first FormFieldInput which point to the name of the ItemCountable
                                  if (index == 0 && !editing) {
                                    showItemListChooserPopup(
                                            namesAlreadyInList: namesInList,
                                            preset: listIC[keys[0]]!
                                                .controller
                                                .text,
                                            context: context,
                                            itemList: itemList,
                                            autoCancel: false)
                                        .then((value) => listIC[keys[0]]!
                                            .controller
                                            .text = value ?? "");
                                  }
                                }),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              children: buttonList,
                            ),
                          )
                        ],
                      )),
                );
              }));
    });
  }

  static Future<String?> showItemListChooserPopup(
      {required BuildContext context,
      required List<Item> itemList,
      required bool autoCancel,
      required String preset,
      required List<String> namesAlreadyInList}) async {
    if (autoCancel) {
      return '';
    }
    TextEditingController controller = TextEditingController(text: preset);
    itemList.sort((a, b) => a.name.compareTo(b.name));
    List<Item> showedItems = itemList;
    return await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: ((context, setState) {
              double height = 300;
              return AlertDialog(
                buttonPadding: EdgeInsets.zero,
                content: SizedBox(
                  height: height,
                  width: 500,
                  child: Column(
                    children: [
                      TextFormField(
                        autofocus: true,
                        onFieldSubmitted: (value) =>
                            Navigator.of(context).pop(controller.text.trim()),
                        controller: controller,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            showedItems = itemList;
                          } else {
                            showedItems = itemList
                                .where((e) => e.name.contains(value))
                                .toList();
                          }
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(hintText: "Nom de l'élément"),
                      ),
                      SizedBox(
                          height: height - 50,
                          child: ItemListViewBuilder(
                              callback: (Item item) =>
                                  Navigator.of(context).pop(item.name.trim()),
                              itemList: showedItems,
                              namesInList: namesAlreadyInList)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text("ANNULER")),
                  TextButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) {
                          Tools.showNormalSnackBar(context,
                              "Vous ne pouvez pas créer une élément vide.");
                        } else {
                          Navigator.of(context).pop(controller.text.trim());
                        }
                      },
                      child: const Text("AJOUTER"))
                ],
              );
            })));
  }

  static Future<bool?> buildSimpleAlertDialog(
      BuildContext context, String title, String content,
      {List<Widget>? actions}) {
    actions ??= [
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        style:
            ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
        child: const Text("OK"),
      )
    ];

    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: SizedBox(child: Text(content)),
              actions: actions,
            ));
  }

  static Future<bool?> buildConfirmAction(
      BuildContext context, String title, String content,
      {List<Widget>? actions}) {
    actions ??= [
      TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey)),
          child: const Text("ANNULER")),
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.green)),
        child: const Text("CONFIRMER"),
      )
    ];

    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: SizedBox(child: Text(content)),
              actions: actions,
            ));
  }

  static Future<void> openDialogItem(
      {required BuildContext context,
      required String title,
      required bool canRemove,
      required bool editing,
      required Item item,
      required bool Function(Item, PopupAction) callback}) async {
    List<Widget> buttonsList = [];
    if (canRemove) {
      buttonsList.add(TextButton(
          onPressed: () => callback(item, PopupAction.remove),
          child: const Text("SUPPRIMER")));
    }

    buttonsList.addAll([
      TextButton(
          onPressed: Navigator.of(context).pop, child: const Text("ANNULER")),
      TextButton(
          onPressed: () => callback(item, PopupAction.edit),
          child: const Text("CONFIRMER"))
    ]);

    return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              actions: buttonsList,
            ));
  }
}
