import 'package:flutter/material.dart';
import 'package:useful_app/shop_list/models/item_composer_dialog.dart';

class ListviewItemComposerBuilder extends StatelessWidget {
  final List<String> keys;
  final Map<String, ItemComposer> listIC;
  final void Function(int index) callback;
  const ListviewItemComposerBuilder(
      {super.key,
      required this.keys,
      required this.listIC,
      required this.callback});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (BuildContext context, int i) {
        ItemComposer itemICD = listIC[keys[i]]!;

        return Card(
          child: Row(
            children: [
              Text(
                listIC[keys[i]]?.infoShort ?? "",
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(
                width: 170,
                child: TextField(
                  onTap: () => callback(i),
                  autofocus: itemICD.autofocus,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 16),
                  decoration:
                      InputDecoration(hintText: listIC[keys[i]]?.hint ?? ""),
                  controller: itemICD.controller,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
