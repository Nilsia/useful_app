import 'package:flutter/material.dart';

class ListHidder extends StatefulWidget {
  final String title;
  final List<Widget> widgetList;
  const ListHidder({super.key, required this.title, required this.widgetList});

  @override
  State<ListHidder> createState() => _ListHidderState();
}

class _ListHidderState extends State<ListHidder> {
  static const Icon iconVisible = Icon(Icons.arrow_drop_down);
  static const Icon iconHidden = Icon(Icons.arrow_right);

  bool itemsVisible = true;
  Icon selectedIcon = iconVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            selectedIcon = itemsVisible ? iconHidden : iconVisible;
            itemsVisible = !itemsVisible;
            setState(() {});
          },
          child: Container(
            width: 900,
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey))),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(super.widget.title)),
                Expanded(
                  child: Align(
                      alignment: Alignment.centerRight, child: selectedIcon),
                ),
              ],
            ),
          ),
        ),
        if (itemsVisible)
          Column(
            children: buildWidgetList(),
          )
      ],
    );
  }

  List<Widget> buildWidgetList() {
    return super
        .widget
        .widgetList
        .map((e) => Align(
              alignment: Alignment.centerLeft,
              child: Padding(padding: const EdgeInsets.all(0), child: e),
            ))
        .toList();
  }
}
