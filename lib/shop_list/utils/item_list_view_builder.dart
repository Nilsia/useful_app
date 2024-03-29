import 'package:flutter/material.dart';
import 'package:useful_app/shop_list/models/item.dart';

class ItemListViewBuilder extends StatelessWidget {
  final List<Item> itemList;
  final List<String>? namesInList;
  final void Function(Item) callback;
  const ItemListViewBuilder(
      {super.key,
      required this.itemList,
      required this.callback,
      this.namesInList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: itemList.length,
        itemBuilder: (BuildContext context, int index) {
          Item item = itemList[index];
          double opacity = 1;
          bool enabled = true;
          if (namesInList?.contains(item.name) ?? false) {
            opacity = 0.5;
            enabled = false;
          }
          return InkWell(
            onTap: () => enabled ? callback(item) : null,
            child: Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey))),
                height: 50,
                child: Opacity(
                  opacity: opacity,
                  child: Row(
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(item.name)),
                      Expanded(
                          child: Column(
                        children: [Text(item.affiliation), Text(item.location)],
                      ))
                    ],
                  ),
                )),
          );
        });
  }
}
